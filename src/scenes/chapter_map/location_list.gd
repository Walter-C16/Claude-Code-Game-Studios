extends Control

## Location List — Free-roam exploration replacing the linear chapter map.
##
## Shows all discovered locations in the current area (Sardis for Ch1).
## Each location card displays: name, description, NPCs present at the
## current time of day, and available actions (Visit, Talk, Story node).
## The time-of-day header lets the player advance time to change who's
## around.
##
## Random encounters trigger on Visit based on the location's encounter
## table and the current time period.

# ── Private state ────────────────────────────────────────────────────────────

var _locations_data: Dictionary = {}
var _location_cards: Dictionary = {}  # {location_id: Control}
var _feedback_label: Label
var _feedback_tween: Tween
var _back_btn: Button
var _time_label: Label
var _advance_time_btn: Button
var _scroll: ScrollContainer
var _card_list: VBoxContainer

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/camp.ogg")
	_load_location_data()
	_build_layout()
	_refresh_all()
	GameStore.state_changed.connect(_on_state_changed)
	tree_exiting.connect(_disconnect_autoload_signals)


func _disconnect_autoload_signals() -> void:
	if GameStore.state_changed.is_connected(_on_state_changed):
		GameStore.state_changed.disconnect(_on_state_changed)
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()


func _load_location_data() -> void:
	var data: Dictionary = JsonLoader.load_dict("res://assets/data/locations.json")
	_locations_data = data.get("locations", {}) as Dictionary


# ── Layout ───────────────────────────────────────────────────────────────────

func _build_layout() -> void:
	# Dark background.
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 12.0
	root_vbox.offset_right = -12.0
	root_vbox.offset_top = 16.0
	root_vbox.offset_bottom = -16.0
	root_vbox.add_theme_constant_override("separation", 10)
	add_child(root_vbox)

	# Top bar — back + time display + advance button.
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(top_row)

	_back_btn = Button.new()
	_back_btn.text = "<"
	_back_btn.custom_minimum_size = Vector2(44.0, 44.0)
	_back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(_back_btn)

	var title: Label = Label.new()
	title.text = "Sardis"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title.add_theme_font_size_override("font_size", 22)
	top_row.add_child(title)

	_time_label = Label.new()
	_time_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	_time_label.add_theme_font_size_override("font_size", 16)
	top_row.add_child(_time_label)

	_advance_time_btn = Button.new()
	_advance_time_btn.text = Localization.get_text("LOCATION_ADVANCE_TIME")
	_advance_time_btn.custom_minimum_size = Vector2(80.0, 44.0)
	_advance_time_btn.add_theme_font_size_override("font_size", 13)
	_advance_time_btn.pressed.connect(_on_advance_time_pressed)
	top_row.add_child(_advance_time_btn)

	# Floating feedback label for talk/gift results.
	_feedback_label = Label.new()
	_feedback_label.visible = false
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_feedback_label.offset_top = -60.0
	_feedback_label.add_theme_color_override("font_color", UIConstants.STATUS_SUCCESS)
	_feedback_label.add_theme_font_size_override("font_size", 24)

	# Scrollable location card list.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_scroll)

	_card_list = VBoxContainer.new()
	_card_list.add_theme_constant_override("separation", 8)
	_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_list)


# ── Refresh ──────────────────────────────────────────────────────────────────

	add_child(_feedback_label)


func _refresh_all() -> void:
	_refresh_time_display()
	_rebuild_location_cards()


func _refresh_time_display() -> void:
	var time_name: String = GameStore.get_time_of_day_name()
	var time_key: String = "LOCATION_TIME_" + time_name.to_upper()
	_time_label.text = Localization.get_text(time_key)

	# Tint the time label to match the mood.
	match GameStore.get_time_of_day():
		GameStore.TIME_MORNING:
			_time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
		GameStore.TIME_AFTERNOON:
			_time_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1.0))
		GameStore.TIME_EVENING:
			_time_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4, 1.0))
		GameStore.TIME_NIGHT:
			_time_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.85, 1.0))


func _rebuild_location_cards() -> void:
	for child: Node in _card_list.get_children():
		child.queue_free()
	_location_cards.clear()

	var time_name: String = GameStore.get_time_of_day_name()

	for loc_id: Variant in _locations_data.keys():
		var loc: Dictionary = _locations_data[loc_id] as Dictionary
		var discover_flag: Variant = loc.get("discover_flag", null)

		# Locations with no discover_flag are always visible.
		# Locations with a flag require that flag to be set.
		if discover_flag is String and not (discover_flag as String).is_empty():
			if not GameStore.has_flag(discover_flag as String):
				continue

		var card: Control = _build_location_card(loc_id as String, loc, time_name)
		_card_list.add_child(card)
		_location_cards[loc_id] = card

	# Empty state — no locations yet (story hasn't started or just began).
	if _location_cards.is_empty():
		var hint: Label = Label.new()
		hint.text = Localization.get_text("LOCATION_EMPTY_HINT")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
		hint.add_theme_font_size_override("font_size", 14)
		hint.custom_minimum_size = Vector2(0.0, 80.0)
		_card_list.add_child(hint)

	# Entrance animation.
	await get_tree().process_frame
	Fx.stagger_children(_card_list, 0.04, 15.0)


func _build_location_card(loc_id: String, loc: Dictionary, time_name: String) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 100.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	# Tint card background by time of day for atmosphere.
	var time_bg: Color = UIConstants.BG_SECONDARY
	match GameStore.get_time_of_day():
		GameStore.TIME_MORNING:
			time_bg = Color(0.18, 0.15, 0.10, 1.0)
		GameStore.TIME_AFTERNOON:
			time_bg = Color(0.17, 0.14, 0.10, 1.0)
		GameStore.TIME_EVENING:
			time_bg = Color(0.16, 0.11, 0.10, 1.0)
		GameStore.TIME_NIGHT:
			time_bg = Color(0.10, 0.10, 0.16, 1.0)
	style.bg_color = time_bg
	style.border_color = UIConstants.ACCENT_GOLD_DARK
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Location name.
	var name_label: Label = Label.new()
	name_label.text = Localization.get_text(loc.get("name_key", loc_id) as String)
	name_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Description.
	var desc_label: Label = Label.new()
	desc_label.text = Localization.get_text(loc.get("description_key", "") as String)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	desc_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_label)

	# NPCs present at this time — each gets a Talk button.
	var npcs: Array = loc.get("npcs", {}).get(time_name, []) as Array
	if not npcs.is_empty():
		var npc_header: Label = Label.new()
		npc_header.text = Localization.get_text("LOCATION_NPCS_HERE")
		npc_header.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
		npc_header.add_theme_font_size_override("font_size", 11)
		vbox.add_child(npc_header)

		for npc_id: Variant in npcs:
			var nid: String = str(npc_id)
			var profile: Dictionary = CompanionRegistry.get_profile(nid)
			var display: String = profile.get("display_name", nid.capitalize()) as String
			var npc_row: HBoxContainer = HBoxContainer.new()
			npc_row.add_theme_constant_override("separation", 6)
			vbox.add_child(npc_row)

			var npc_name: Label = Label.new()
			npc_name.text = display
			npc_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			npc_name.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
			npc_name.add_theme_font_size_override("font_size", 13)
			npc_row.add_child(npc_name)

			# Talk button — uses RomanceSocial.do_talk, same as Camp.
			var talk_btn: Button = Button.new()
			talk_btn.text = Localization.get_text("CAMP_TALK_BTN")
			talk_btn.custom_minimum_size = Vector2(60.0, 30.0)
			talk_btn.add_theme_font_size_override("font_size", 11)
			var has_tokens: bool = GameStore.get_daily_tokens() > 0
			talk_btn.disabled = not has_tokens
			talk_btn.pressed.connect(_on_npc_talk_pressed.bind(nid))
			npc_row.add_child(talk_btn)

			# Gift button.
			var gift_btn: Button = Button.new()
			gift_btn.text = Localization.get_text("CAMP_GIFT_BTN")
			gift_btn.custom_minimum_size = Vector2(60.0, 30.0)
			gift_btn.add_theme_font_size_override("font_size", 11)
			gift_btn.disabled = not has_tokens
			gift_btn.pressed.connect(_on_npc_gift_pressed.bind(nid))
			npc_row.add_child(gift_btn)
	else:
		var empty_label: Label = Label.new()
		empty_label.text = Localization.get_text("LOCATION_NO_NPCS")
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4, 1.0))
		empty_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(empty_label)

	# Thin separator between NPCs and action buttons.
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	# Action buttons row — Explore (triggers encounters/story) + Visit (just passes time).
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var explore_btn: Button = Button.new()
	explore_btn.text = Localization.get_text("LOCATION_EXPLORE")
	explore_btn.custom_minimum_size = Vector2(0.0, 36.0)
	explore_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explore_btn.add_theme_font_size_override("font_size", 13)
	explore_btn.pressed.connect(_on_visit_pressed.bind(loc_id))
	btn_row.add_child(explore_btn)

	return card


# ── Actions ──────────────────────────────────────────────────────────────────

func _on_npc_talk_pressed(npc_id: String) -> void:
	if GameStore.get_daily_tokens() <= 0:
		_show_feedback(Localization.get_text("CAMP_FEEDBACK_NO_TOKENS"))
		return
	# Ensure the NPC is "met" before talking (auto-meet side characters
	# on first interaction so the relationship system works).
	var state: Dictionary = GameStore.get_companion_state(npc_id)
	if not state.get("met", false):
		CompanionRegistry.meet_companion(npc_id)
	var result: Dictionary = RomanceSocial.do_talk(npc_id)
	if result.get("success", false):
		var rl: int = result.get("rl_gained", 0)
		_show_feedback("+%d RL" % rl)
	else:
		_show_feedback(Localization.get_text("CAMP_FEEDBACK_NO_TOKENS"))
	_rebuild_location_cards()


func _on_npc_gift_pressed(npc_id: String) -> void:
	# For now, gift interactions redirect to the Companion Room where the
	# full gift modal lives. In a future pass this could be an inline
	# gift picker at the location.
	var state: Dictionary = GameStore.get_companion_state(npc_id)
	if not state.get("met", false):
		CompanionRegistry.meet_companion(npc_id)
	SceneManager.change_scene(SceneManager.SceneId.COMPANION_ROOM)


func _show_feedback(text: String) -> void:
	_feedback_label.text = text
	_feedback_label.visible = true
	_feedback_label.modulate.a = 1.0
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(1.0)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.4)
	_feedback_tween.tween_callback(func() -> void: _feedback_label.visible = false)


func _on_visit_pressed(loc_id: String) -> void:
	var loc: Dictionary = _locations_data.get(loc_id, {}) as Dictionary
	if loc.is_empty():
		return

	# Check for random encounter at this location + time.
	var time_name: String = GameStore.get_time_of_day_name()
	var encounters: Array = loc.get("encounters", []) as Array
	for enc: Variant in encounters:
		var enc_dict: Dictionary = enc as Dictionary
		var times: Array = enc_dict.get("time", []) as Array
		if not times.has(time_name):
			continue
		var chance: float = float(enc_dict.get("chance", 0.0))
		if randf() < chance:
			var enemy_id: String = enc_dict.get("enemy_id", "") as String
			if not enemy_id.is_empty():
				SceneManager.change_scene(
					SceneManager.SceneId.BATTLE,
					SceneManager.TransitionType.FADE,
					{"enemy_ids": [enemy_id], "story_node": ""}
				)
				return

	# Check for available story nodes at this location.
	var story_nodes: Array = loc.get("story_nodes", []) as Array
	for node_id: Variant in story_nodes:
		var nid: String = str(node_id)
		# Find matching node in ch01.json and check prereqs.
		if _is_story_node_available(nid):
			_launch_story_node(nid)
			return

	# No encounter, no story — just advance time (you spent time here).
	GameStore.advance_time()
	_refresh_all()


func _on_advance_time_pressed() -> void:
	GameStore.advance_time()
	_refresh_all()


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


func _on_state_changed(_key: String) -> void:
	_refresh_time_display()


# ── Story node helpers ───────────────────────────────────────────────────────

## Checks if a story node from ch01.json is available (prereqs met, not
## already completed). Loads the chapter data on first call and caches it.
var _chapter_nodes: Array = []

func _get_chapter_nodes() -> Array:
	if _chapter_nodes.is_empty():
		var data: Dictionary = JsonLoader.load_dict("res://assets/data/chapters/ch01.json")
		_chapter_nodes = data.get("nodes", []) as Array
	return _chapter_nodes


func _is_story_node_available(node_id: String) -> bool:
	for node: Variant in _get_chapter_nodes():
		var nd: Dictionary = node as Dictionary
		if nd.get("id", "") != node_id:
			continue
		# Already completed — check if a flag from its rewards was set.
		var reward_flags: Array = nd.get("rewards", {}).get("flags", []) as Array
		for flag: Variant in reward_flags:
			if GameStore.has_flag(str(flag)):
				return false  # already done
		# Check prereqs.
		for prereq: Variant in nd.get("prereqs", []):
			if not GameStore.has_flag(str(prereq)):
				return false
		return true
	return false


func _launch_story_node(node_id: String) -> void:
	for node: Variant in _get_chapter_nodes():
		var nd: Dictionary = node as Dictionary
		if nd.get("id", "") != node_id:
			continue
		var node_type: String = nd.get("type", "dialogue") as String

		# Apply meet effects before navigation.
		for fx: Variant in nd.get("effects", []):
			var fx_dict: Dictionary = fx as Dictionary
			if (fx_dict.get("type", "") as String) == "meet":
				CompanionRegistry.meet_companion(fx_dict.get("companion", "") as String)

		if node_type == "combat":
			var enemy_id: String = nd.get("enemy_id", "forest_monster") as String
			SceneManager.change_scene(
				SceneManager.SceneId.BATTLE,
				SceneManager.TransitionType.FADE,
				{"enemy_ids": [enemy_id], "story_node": node_id}
			)
		else:
			var sequence: String = nd.get("sequence", "") as String
			SceneManager.change_scene(
				SceneManager.SceneId.DIALOGUE,
				SceneManager.TransitionType.FADE,
				{"chapter_id": "ch01", "sequence_id": sequence, "story_node": node_id}
			)
		return
