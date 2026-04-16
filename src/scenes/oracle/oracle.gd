extends Control

## Oracle of Delphi — Companion gacha UI.
##
## Reads tuning from [code]assets/data/oracle_pool.json[/code] via the
## [Oracle] pure-logic class and mutates GameStore shards / epithets /
## gold in response to player pulls. Layout is built at runtime in
## [method _ready] so the .tscn stays minimal.
##
## Flow:
##   1. Hub entry → tick_oracle_weekly_reset (may zero the counter)
##   2. Player taps Single or Ten pull → validate cost → deduct gold +
##      pulls counter → roll + apply result → show reveal overlay
##   3. Legendary (1%) single rolls pause in a "Choose your favour"
##      modal so the player picks which goddess receives the shards
##   4. Unlocks route through meet_companion (party auto-add)
##
## See design/quick-specs/oracle-gacha.md for the full system design.

const GODDESS_IDS: Array[String] = ["artemis", "hipolita", "atenea", "nyx"]

# ── Private state ───────────────────────────────────────────────────────────

var _oracle: Oracle
var _back_btn: Button
var _gold_label: Label
var _pulls_label: Label
var _shard_widgets: Dictionary = {}  # {goddess_id: {label, bar, tier}}
var _single_btn: Button
var _ten_btn: Button

## Modal overlay that blocks input while a reveal is on screen.
var _reveal_root: Control
var _reveal_panel: PanelContainer
var _reveal_text: RichTextLabel
var _reveal_continue_btn: Button

## Legendary player-pick modal.
var _pick_root: Control
var _pick_panel: PanelContainer
var _pending_legendary_result: Dictionary = {}


# ── Lifecycle ───────────────────────────────────────────────────────────────

func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/camp.ogg")

	# Tick the weekly reset before doing anything — this is a fresh session
	# entry point and the counter may have rolled over since the last visit.
	GameStore.tick_oracle_weekly_reset()

	# Build the pure-logic oracle first; the UI depends on its config for
	# cost display.
	_oracle = Oracle.new()

	_build_layout()
	_refresh_all()

	GameStore.state_changed.connect(_on_state_changed)
	tree_exiting.connect(_disconnect_autoload_signals)


func _disconnect_autoload_signals() -> void:
	if GameStore.state_changed.is_connected(_on_state_changed):
		GameStore.state_changed.disconnect(_on_state_changed)


# ── Layout builders ─────────────────────────────────────────────────────────

func _build_layout() -> void:
	# Dark temple backdrop.
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vertical spine.
	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 16.0
	root_vbox.offset_right = -16.0
	root_vbox.offset_top = 20.0
	root_vbox.offset_bottom = -20.0
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	# Top bar — back button + gold balance + weekly pulls remaining.
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(top_row)

	_back_btn = Button.new()
	_back_btn.text = "<"
	_back_btn.custom_minimum_size = Vector2(44.0, 44.0)
	_back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(_back_btn)

	var top_spacer: Control = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	_gold_label.add_theme_font_size_override("font_size", 18)
	top_row.add_child(_gold_label)

	var top_sep: Control = Control.new()
	top_sep.custom_minimum_size = Vector2(16.0, 0.0)
	top_row.add_child(top_sep)

	_pulls_label = Label.new()
	_pulls_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_pulls_label.add_theme_font_size_override("font_size", 14)
	top_row.add_child(_pulls_label)

	# Title.
	var title: Label = Label.new()
	title.text = Localization.get_text("ORACLE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title.add_theme_font_size_override("font_size", 26)
	root_vbox.add_child(title)

	# Subtitle — priestess flavour text.
	var subtitle: Label = Label.new()
	subtitle.text = Localization.get_text("ORACLE_SUBTITLE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	subtitle.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(subtitle)

	# Shard cards — one per goddess, stacked vertically so each shows
	# plenty of room on portrait mobile.
	var cards_vbox: VBoxContainer = VBoxContainer.new()
	cards_vbox.add_theme_constant_override("separation", 8)
	cards_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(cards_vbox)

	for gid: String in GODDESS_IDS:
		cards_vbox.add_child(_build_shard_card(gid))

	# Pull buttons row.
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(btn_row)

	_single_btn = _make_pull_button(
		Localization.get_text("ORACLE_PULL_SINGLE") % _oracle.single_cost
	)
	_single_btn.pressed.connect(_on_single_pull_pressed)
	btn_row.add_child(_single_btn)

	_ten_btn = _make_pull_button(
		Localization.get_text("ORACLE_PULL_TEN") % _oracle.ten_cost
	)
	_ten_btn.pressed.connect(_on_ten_pull_pressed)
	btn_row.add_child(_ten_btn)

	# Overlays — built once, hidden until needed.
	_build_reveal_overlay()
	_build_pick_overlay()


func _build_shard_card(goddess_id: String) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 80.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.border_color = UIConstants.ACCENT_GOLD_DARK
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Row 1 — goddess name + tier badge.
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var name_label: Label = Label.new()
	name_label.text = _goddess_display_name(goddess_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 16)
	header_row.add_child(name_label)

	var tier_label: Label = Label.new()
	tier_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(tier_label)

	# Row 2 — progress text.
	var shard_text: Label = Label.new()
	shard_text.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	shard_text.add_theme_font_size_override("font_size", 12)
	vbox.add_child(shard_text)

	# Row 3 — shard progress bar.
	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.custom_minimum_size = Vector2(0.0, 6.0)
	bar.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = UIConstants.ACCENT_GOLD
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
	bar_bg.bg_color = UIConstants.BG_TERTIARY
	bar_bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bar_bg)
	vbox.add_child(bar)

	_shard_widgets[goddess_id] = {
		"tier_label": tier_label,
		"shard_text": shard_text,
		"bar": bar,
	}
	return card


func _make_pull_button(label_text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0.0, 56.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	btn.add_theme_font_size_override("font_size", 16)
	return btn


func _build_reveal_overlay() -> void:
	_reveal_root = ColorRect.new()
	_reveal_root.name = "RevealRoot"
	_reveal_root.color = Color(0.0, 0.0, 0.0, 0.75)
	_reveal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal_root.visible = false
	add_child(_reveal_root)

	_reveal_panel = PanelContainer.new()
	_reveal_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_reveal_panel.custom_minimum_size = Vector2(360.0, 420.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.border_color = UIConstants.ACCENT_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	_reveal_panel.add_theme_stylebox_override("panel", style)
	_reveal_root.add_child(_reveal_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_reveal_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = Localization.get_text("ORACLE_REVEAL_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_reveal_text = RichTextLabel.new()
	_reveal_text.bbcode_enabled = true
	_reveal_text.fit_content = true
	_reveal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reveal_text.custom_minimum_size = Vector2(0.0, 280.0)
	_reveal_text.add_theme_color_override("default_color", UIConstants.TEXT_PRIMARY)
	_reveal_text.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_reveal_text)

	_reveal_continue_btn = Button.new()
	_reveal_continue_btn.text = Localization.get_text("ORACLE_REVEAL_CONTINUE")
	_reveal_continue_btn.custom_minimum_size = Vector2(0.0, 48.0)
	_reveal_continue_btn.pressed.connect(_on_reveal_continue)
	vbox.add_child(_reveal_continue_btn)


func _build_pick_overlay() -> void:
	_pick_root = ColorRect.new()
	_pick_root.name = "PickRoot"
	_pick_root.color = Color(0.0, 0.0, 0.0, 0.75)
	_pick_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pick_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_pick_root.visible = false
	add_child(_pick_root)

	_pick_panel = PanelContainer.new()
	_pick_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pick_panel.custom_minimum_size = Vector2(340.0, 420.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.border_color = UIConstants.ACCENT_GOLD_BRIGHT
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	_pick_panel.add_theme_stylebox_override("panel", style)
	_pick_root.add_child(_pick_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_pick_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = Localization.get_text("ORACLE_PICK_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var body: Label = Label.new()
	body.text = Localization.get_text("ORACLE_PICK_BODY")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	body.add_theme_font_size_override("font_size", 13)
	vbox.add_child(body)

	for gid: String in GODDESS_IDS:
		var btn: Button = Button.new()
		btn.text = _goddess_display_name(gid)
		btn.custom_minimum_size = Vector2(0.0, 44.0)
		btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_legendary_goddess_picked.bind(gid))
		vbox.add_child(btn)


# ── Refresh ──────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_header()
	for gid: String in GODDESS_IDS:
		_refresh_shard_card(gid)
	_refresh_pull_buttons()


func _refresh_header() -> void:
	_gold_label.text = "%s %d" % [Localization.get_text("ORACLE_GOLD_LABEL"), GameStore.get_gold()]
	_pulls_label.text = Localization.get_text("ORACLE_PULLS_LABEL") % [
		GameStore.get_oracle_pulls_this_week(),
		_oracle.weekly_cap,
	]


func _refresh_shard_card(goddess_id: String) -> void:
	var widgets: Dictionary = _shard_widgets[goddess_id]
	var tier: int = GameStore.get_companion_epithet(goddess_id)
	var shards: int = GameStore.get_companion_shards(goddess_id)
	var next_cost: int = 0
	if tier < 6:
		next_cost = _oracle.epithet_costs[tier]

	var tier_label: Label = widgets["tier_label"] as Label
	var shard_text: Label = widgets["shard_text"] as Label
	var bar: ProgressBar = widgets["bar"] as ProgressBar

	if tier == 0:
		tier_label.text = Localization.get_text("ORACLE_TIER_LOCKED")
	elif tier >= 6:
		tier_label.text = Localization.get_text("ORACLE_TIER_MAX")
	else:
		tier_label.text = Localization.get_text("ORACLE_TIER_LABEL") % tier

	if tier >= 6:
		shard_text.text = Localization.get_text("ORACLE_TIER_MAX_HINT")
		bar.value = 1.0
	else:
		shard_text.text = "%d / %d %s" % [
			shards,
			next_cost,
			Localization.get_text("ORACLE_SHARDS_SUFFIX"),
		]
		bar.value = clampf(float(shards) / float(next_cost), 0.0, 1.0)


func _refresh_pull_buttons() -> void:
	var gold: int = GameStore.get_gold()
	var pulls: int = GameStore.get_oracle_pulls_this_week()
	_single_btn.disabled = not _oracle.can_single_pull(gold, pulls)
	_ten_btn.disabled = not _oracle.can_ten_pull(gold, pulls)


# ── Pull handlers ────────────────────────────────────────────────────────────

func _on_single_pull_pressed() -> void:
	var gold: int = GameStore.get_gold()
	var pulls: int = GameStore.get_oracle_pulls_this_week()
	if not _oracle.can_single_pull(gold, pulls):
		return

	# Charge cost + pull counter up front.
	GameStore.spend_gold(_oracle.single_cost)
	GameStore.add_oracle_pulls(1)

	var epithets: Dictionary = _snapshot_epithets()
	var result: Dictionary = _oracle.roll_single(epithets)

	# Legendary pulls force the player to pick a goddess before we can
	# apply the shards — park the result and pop the picker modal.
	if bool(result.get("player_pick", false)):
		_pending_legendary_result = result
		_pick_root.visible = true
		return

	var diff: Dictionary = _oracle.apply_result(
		result,
		_snapshot_shards(),
		epithets
	)
	_commit_diff_and_reveal(diff, [result])


func _on_ten_pull_pressed() -> void:
	var gold: int = GameStore.get_gold()
	var pulls: int = GameStore.get_oracle_pulls_this_week()
	if not _oracle.can_ten_pull(gold, pulls):
		return

	GameStore.spend_gold(_oracle.ten_cost)
	GameStore.add_oracle_pulls(10)

	var working_shards: Dictionary = _snapshot_shards()
	var working_epithets: Dictionary = _snapshot_epithets()
	var rolls: Array[Dictionary] = _oracle.roll_ten(working_epithets)

	# Walk each roll in order and chain apply_result so later rolls see
	# the updated epithet tiers (needed so a single big session can cascade
	# from tier 0 to several tiers). Legendary rolls inside a ten-pull are
	# auto-resolved to the lowest-tier goddess for simplicity — the picker
	# only appears for single pulls.
	var total_refund: int = 0
	var all_unlocked: Array[String] = []
	var all_promoted: Array[Dictionary] = []
	for roll: Dictionary in rolls:
		var roll_copy: Dictionary = roll.duplicate()
		if bool(roll_copy.get("player_pick", false)):
			roll_copy["goddess"] = _lowest_tier_goddess(working_epithets)
		if (roll_copy.get("goddess", "") as String).is_empty():
			continue
		var diff: Dictionary = _oracle.apply_result(
			roll_copy, working_shards, working_epithets
		)
		working_shards = diff["shards"] as Dictionary
		working_epithets = diff["epithets"] as Dictionary
		total_refund += int(diff.get("refund_gold", 0))
		for uid: Variant in (diff["unlocked"] as Array):
			all_unlocked.append(str(uid))
		for promo: Variant in (diff["promoted"] as Array):
			all_promoted.append(promo as Dictionary)

	var final_diff: Dictionary = {
		"shards": working_shards,
		"epithets": working_epithets,
		"refund_gold": total_refund,
		"unlocked": all_unlocked,
		"promoted": all_promoted,
	}
	_commit_diff_and_reveal(final_diff, rolls)


func _on_legendary_goddess_picked(goddess_id: String) -> void:
	_pick_root.visible = false
	if _pending_legendary_result.is_empty():
		return
	var diff: Dictionary = _oracle.apply_result(
		_pending_legendary_result,
		_snapshot_shards(),
		_snapshot_epithets(),
		goddess_id
	)
	# Stamp the goddess into the result so the reveal text reads correctly.
	var pending_copy: Dictionary = _pending_legendary_result.duplicate()
	pending_copy["goddess"] = goddess_id
	_pending_legendary_result = {}
	_commit_diff_and_reveal(diff, [pending_copy])


# ── Diff application + reveal ────────────────────────────────────────────────

func _commit_diff_and_reveal(diff: Dictionary, rolls: Array) -> void:
	# Apply shards + epithets to GameStore. Unlocks route through
	# meet_companion so the party auto-adds + Epithet 0→1 hook fires.
	var new_shards: Dictionary = diff["shards"] as Dictionary
	var new_epithets: Dictionary = diff["epithets"] as Dictionary
	for gid: String in GODDESS_IDS:
		GameStore.set_companion_shards(gid, int(new_shards.get(gid, 0)))
		var prev_tier: int = GameStore.get_companion_epithet(gid)
		var next_tier: int = int(new_epithets.get(gid, prev_tier))
		if next_tier != prev_tier:
			GameStore.set_companion_epithet(gid, next_tier)
			if prev_tier == 0 and next_tier >= 1:
				# meet_companion handles party add + romance seeding.
				CompanionRegistry.meet_companion(gid)

	var refund: int = int(diff.get("refund_gold", 0))
	if refund > 0:
		GameStore.add_gold(refund)

	_reveal_text.text = _format_reveal(rolls, diff)
	_reveal_root.visible = true
	_refresh_all()


func _on_reveal_continue() -> void:
	_reveal_root.visible = false


func _format_reveal(rolls: Array, diff: Dictionary) -> String:
	var lines: Array[String] = []
	var total_shards: Dictionary = {}

	for entry: Variant in rolls:
		var roll: Dictionary = entry as Dictionary
		var goddess: String = roll.get("goddess", "") as String
		var count: int = int(roll.get("shards", 0))
		if goddess.is_empty() or count <= 0:
			continue
		total_shards[goddess] = int(total_shards.get(goddess, 0)) + count

	for gid: String in GODDESS_IDS:
		if not total_shards.has(gid):
			continue
		lines.append("[b]%s[/b]: +%d %s" % [
			_goddess_display_name(gid),
			int(total_shards[gid]),
			Localization.get_text("ORACLE_SHARDS_SUFFIX"),
		])

	var unlocked: Array = diff["unlocked"] as Array
	if not unlocked.is_empty():
		lines.append("")
		for uid: Variant in unlocked:
			lines.append("[color=gold]★ %s[/color]" % Localization.get_text("ORACLE_UNLOCKED") % _goddess_display_name(uid as String))

	var promoted: Array = diff["promoted"] as Array
	var tier_promos: Array[String] = []
	for entry: Variant in promoted:
		var promo: Dictionary = entry as Dictionary
		var from: int = int(promo.get("from", 0))
		var to: int = int(promo.get("to", 0))
		if from >= 1:  # unlocks are already listed above
			tier_promos.append("%s → Epithet %d" % [
				_goddess_display_name(promo.get("id", "") as String),
				to,
			])
	if not tier_promos.is_empty():
		lines.append("")
		for p: String in tier_promos:
			lines.append("[color=gold]▲ %s[/color]" % p)

	var refund: int = int(diff.get("refund_gold", 0))
	if refund > 0:
		lines.append("")
		lines.append("[color=gold]+%d %s[/color]" % [
			refund,
			Localization.get_text("ORACLE_GOLD_LABEL"),
		])

	if lines.is_empty():
		return Localization.get_text("ORACLE_REVEAL_EMPTY")
	return "\n".join(lines)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _snapshot_shards() -> Dictionary:
	var out: Dictionary = {}
	for gid: String in GODDESS_IDS:
		out[gid] = GameStore.get_companion_shards(gid)
	return out


func _snapshot_epithets() -> Dictionary:
	var out: Dictionary = {}
	for gid: String in GODDESS_IDS:
		out[gid] = GameStore.get_companion_epithet(gid)
	return out


func _lowest_tier_goddess(epithets: Dictionary) -> String:
	var best: String = GODDESS_IDS[0]
	var best_tier: int = 999
	for gid: String in GODDESS_IDS:
		var tier: int = int(epithets.get(gid, 0))
		if tier < best_tier:
			best_tier = tier
			best = gid
	return best


func _goddess_display_name(goddess_id: String) -> String:
	var profile: Dictionary = CompanionRegistry.get_profile(goddess_id)
	return profile.get("display_name", goddess_id.capitalize()) as String


# ── Navigation + signals ─────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


func _on_state_changed(_key: String) -> void:
	_refresh_header()
	_refresh_pull_buttons()
