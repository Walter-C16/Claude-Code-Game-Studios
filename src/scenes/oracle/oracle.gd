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
var _reveal_title: Label
var _reveal_text: RichTextLabel
var _reveal_continue_btn: Button
## Looping shimmer on the reveal title, killed when the player continues.
var _reveal_title_shimmer: Tween

## Legendary player-pick modal.
var _pick_root: Control
var _pick_panel: PanelContainer
var _pending_legendary_result: Dictionary = {}

## Epithet codex modal — lists all 6 tiers + their rewards per goddess.
var _codex_root: Control
var _codex_title: Label
var _codex_current: Label
var _codex_list: VBoxContainer
var _codex_hint: Label


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

	# First-visit tutorial explaining Bond Shards, Epithets, and the pull system.
	call_deferred("_show_tutorial")


func _show_tutorial() -> void:
	TutorialOverlay.show_once(self,
		"tutorial_oracle_shown",
		"TUTORIAL_ORACLE_TITLE",
		"TUTORIAL_ORACLE_BODY")


func _disconnect_autoload_signals() -> void:
	if GameStore.state_changed.is_connected(_on_state_changed):
		GameStore.state_changed.disconnect(_on_state_changed)
	_kill_reveal_title_shimmer()


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
	_build_codex_overlay()


func _build_shard_card(goddess_id: String) -> Control:
	# Wrap the card in a flat Button so the whole row is tappable. Tapping
	# opens the Epithet codex for that goddess.
	var card: Button = Button.new()
	card.flat = true
	card.custom_minimum_size = Vector2(0.0, 84.0)
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(_on_goddess_card_pressed.bind(goddess_id))

	# A PanelContainer behind the button's text gives us the bordered card
	# look. Button children are laid out inside the button's content box,
	# so we use a centered margin container to host the info vbox.
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.border_color = UIConstants.ACCENT_GOLD_DARK
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	card.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

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

	_reveal_title = Label.new()
	_reveal_title.text = Localization.get_text("ORACLE_REVEAL_TITLE")
	_reveal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	_reveal_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_reveal_title)

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


## Builds the Epithet codex — a modal that shows all 6 tiers for one
## goddess plus her current progress. Opened by tapping a goddess card.
func _build_codex_overlay() -> void:
	_codex_root = ColorRect.new()
	_codex_root.name = "CodexRoot"
	_codex_root.color = Color(0.0, 0.0, 0.0, 0.78)
	_codex_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_codex_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_codex_root.visible = false
	_codex_root.gui_input.connect(_on_codex_backdrop_input)
	add_child(_codex_root)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380.0, 540.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP  # don't leak clicks to backdrop
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.border_color = UIConstants.ACCENT_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", style)
	_codex_root.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	_codex_title = Label.new()
	_codex_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_codex_title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	_codex_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_codex_title)

	_codex_current = Label.new()
	_codex_current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_codex_current.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_codex_current.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_codex_current)

	_codex_hint = Label.new()
	_codex_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_codex_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codex_hint.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_codex_hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_codex_hint)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 340.0)
	vbox.add_child(scroll)

	_codex_list = VBoxContainer.new()
	_codex_list.add_theme_constant_override("separation", 6)
	_codex_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_codex_list)

	var close_btn: Button = Button.new()
	close_btn.text = Localization.get_text("ORACLE_CODEX_CLOSE")
	close_btn.custom_minimum_size = Vector2(0.0, 44.0)
	close_btn.pressed.connect(_close_codex)
	vbox.add_child(close_btn)


## Populates the codex panel for [param goddess_id] and shows it.
func _open_codex(goddess_id: String) -> void:
	var tier: int = GameStore.get_companion_epithet(goddess_id)
	_codex_title.text = Localization.get_text("ORACLE_CODEX_TITLE") % _goddess_display_name(goddess_id)
	if tier == 0:
		_codex_current.text = Localization.get_text("ORACLE_TIER_LOCKED")
		_codex_hint.text = Localization.get_text("ORACLE_CODEX_LOCKED_HINT")
	elif tier >= 6:
		_codex_current.text = Localization.get_text("ORACLE_TIER_MAX")
		_codex_hint.text = Localization.get_text("ORACLE_CODEX_MAX_HINT")
	else:
		_codex_current.text = Localization.get_text("ORACLE_CODEX_CURRENT") % tier
		_codex_hint.text = ""

	# Clear + rebuild the 6-row list.
	for child: Node in _codex_list.get_children():
		child.queue_free()

	for tier_index: int in range(1, 7):
		_codex_list.add_child(_build_codex_row(goddess_id, tier_index, tier))

	_codex_root.visible = true


func _build_codex_row(goddess_id: String, tier_index: int, current_tier: int) -> Control:
	var row_panel: PanelContainer = PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0.0, 64.0)

	var state: int = 0  # 0 = locked, 1 = next goal, 2 = unlocked
	if tier_index <= current_tier:
		state = 2
	elif tier_index == current_tier + 1:
		state = 1

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_TERTIARY
	match state:
		2:
			style.border_color = UIConstants.ACCENT_GOLD
		1:
			style.border_color = UIConstants.ACCENT_GOLD_DARK
		_:
			style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	row_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	row_panel.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	var name_label: Label = Label.new()
	name_label.text = _epithet_name(tier_index)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_color: Color = UIConstants.TEXT_PRIMARY if state > 0 else UIConstants.TEXT_SECONDARY
	name_label.add_theme_color_override("font_color", name_color)
	name_label.add_theme_font_size_override("font_size", 14)
	header.add_child(name_label)

	var state_label: Label = Label.new()
	state_label.text = _epithet_state_text(state)
	var state_color: Color = UIConstants.ACCENT_GOLD_BRIGHT if state == 2 else (
		UIConstants.ACCENT_GOLD if state == 1 else UIConstants.TEXT_SECONDARY
	)
	state_label.add_theme_color_override("font_color", state_color)
	state_label.add_theme_font_size_override("font_size", 11)
	header.add_child(state_label)

	var desc_label: Label = Label.new()
	desc_label.text = _epithet_description(tier_index)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	desc_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_label)

	# Cost hint for the next goal only.
	if state == 1:
		var cost_label: Label = Label.new()
		var cost: int = _oracle.epithet_costs[tier_index - 1]
		cost_label.text = Localization.get_text("EPITHET_COST_SHARDS") % cost
		cost_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
		cost_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(cost_label)

	return row_panel


func _close_codex() -> void:
	_codex_root.visible = false


func _on_codex_backdrop_input(event: InputEvent) -> void:
	# Tap outside the panel dismisses. The inner panel has MOUSE_FILTER_STOP
	# so its clicks never reach here — safe.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close_codex()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_close_codex()


func _on_goddess_card_pressed(goddess_id: String) -> void:
	_open_codex(goddess_id)


func _epithet_name(tier: int) -> String:
	match tier:
		1: return Localization.get_text("EPITHET_1_AWAKENING")
		2: return Localization.get_text("EPITHET_2_DEVOTION")
		3: return Localization.get_text("EPITHET_3_VIGIL")
		4: return Localization.get_text("EPITHET_4_APOTHEOSIS")
		5: return Localization.get_text("EPITHET_5_COMMUNION")
		6: return Localization.get_text("EPITHET_6_ETERNAL")
	return ""


func _epithet_description(tier: int) -> String:
	match tier:
		1: return Localization.get_text("EPITHET_1_DESC")
		2: return Localization.get_text("EPITHET_2_DESC")
		3: return Localization.get_text("EPITHET_3_DESC")
		4: return Localization.get_text("EPITHET_4_DESC")
		5: return Localization.get_text("EPITHET_5_DESC")
		6: return Localization.get_text("EPITHET_6_DESC")
	return ""


func _epithet_state_text(state: int) -> String:
	match state:
		2: return Localization.get_text("EPITHET_STATE_UNLOCKED")
		1: return Localization.get_text("EPITHET_STATE_NEXT")
		_: return Localization.get_text("EPITHET_STATE_LOCKED")


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

	# Press-feedback pop on the button.
	_single_btn.pivot_offset = _single_btn.size * 0.5
	Fx.pop_scale(_single_btn, 1.08, 0.25)

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

	# Press-feedback pop on the button.
	_ten_btn.pivot_offset = _ten_btn.size * 0.5
	Fx.pop_scale(_ten_btn, 1.08, 0.25)

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
	_animate_reveal_entrance((diff["unlocked"] as Array).size() > 0)
	_refresh_all()


## Plays the entrance animation for the reveal overlay. Scale-pops the
## panel from 85% → 100% with spring, fades its modulate in, fades the
## text body in with a small delay for a "panel opens, then writing
## appears" rhythm. If the pull produced any new Epithet I unlock, the
## title also gets a looping gold shimmer for extra drama.
func _animate_reveal_entrance(has_unlock: bool) -> void:
	if _reveal_panel == null:
		return
	_reveal_panel.pivot_offset = _reveal_panel.size * 0.5
	_reveal_panel.scale = Vector2(0.85, 0.85)
	_reveal_panel.modulate.a = 0.0
	_reveal_text.modulate.a = 0.0

	var tween: Tween = _reveal_panel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(_reveal_panel, "scale", Vector2.ONE, 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_reveal_panel, "modulate:a", 1.0, 0.2) \
		.set_ease(Tween.EASE_OUT)

	# Text fades in after a short delay so the panel has visual focus
	# before the reader's eye lands on the contents.
	var text_tween: Tween = _reveal_text.create_tween()
	text_tween.tween_interval(0.18)
	text_tween.tween_property(_reveal_text, "modulate:a", 1.0, 0.25) \
		.set_ease(Tween.EASE_OUT)

	# Gold shimmer on the title — loops until the player taps Continue.
	_kill_reveal_title_shimmer()
	if has_unlock:
		_reveal_title_shimmer = Fx.gold_shimmer(_reveal_title, 1.4)


func _kill_reveal_title_shimmer() -> void:
	if _reveal_title_shimmer != null and _reveal_title_shimmer.is_valid():
		_reveal_title_shimmer.kill()
	_reveal_title_shimmer = null


func _on_reveal_continue() -> void:
	_kill_reveal_title_shimmer()
	# Restore the title modulate in case a shimmer left it off-tone.
	if _reveal_title != null:
		_reveal_title.modulate = Color.WHITE
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
