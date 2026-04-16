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

	# Scrollable location card list.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_scroll)

	_card_list = VBoxContainer.new()
	_card_list.add_theme_constant_override("separation", 8)
	_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_list)


# ── Refresh ──────────────────────────────────────────────────────────────────

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

	# Entrance animation.
	await get_tree().process_frame
	Fx.stagger_children(_card_list, 0.04, 15.0)


func _build_location_card(loc_id: String, loc: Dictionary, time_name: String) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 100.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
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

	# NPCs present at this time.
	var npcs: Array = loc.get("npcs", {}).get(time_name, []) as Array
	if not npcs.is_empty():
		var npc_names: Array[String] = []
		for npc_id: Variant in npcs:
			var profile: Dictionary = CompanionRegistry.get_profile(str(npc_id))
			npc_names.append(profile.get("display_name", str(npc_id).capitalize()) as String)
		var npc_label: Label = Label.new()
		npc_label.text = "%s: %s" % [Localization.get_text("LOCATION_NPCS_HERE"), ", ".join(npc_names)]
		npc_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
		npc_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(npc_label)
	else:
		var empty_label: Label = Label.new()
		empty_label.text = Localization.get_text("LOCATION_NO_NPCS")
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4, 1.0))
		empty_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(empty_label)

	# Visit button.
	var visit_btn: Button = Button.new()
	visit_btn.text = Localization.get_text("LOCATION_VISIT")
	visit_btn.custom_minimum_size = Vector2(0.0, 36.0)
	visit_btn.add_theme_font_size_override("font_size", 13)
	visit_btn.pressed.connect(_on_visit_pressed.bind(loc_id))
	vbox.add_child(visit_btn)

	return card


# ── Actions ──────────────────────────────────────────────────────────────────

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
