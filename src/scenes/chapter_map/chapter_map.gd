extends Control

## ChapterMap — Two-level story navigation: chapter list → chapter detail with areas.
##
## Level 1: Shows available chapters as large tappable cards.
## Level 2: Shows a chapter's city/location header and story nodes grouped by area.
## Loads chapter data from res://assets/data/chapters/ch{nn}.json.

@onready var title_label: Label = %TitleLabel
@onready var chapter_list: VBoxContainer = %ChapterList
@onready var back_btn: Button = %BackBtn

## Tracks which chapter files exist on disk.
var _chapter_files: Array[String] = []

## Currently displayed chapter data (empty = showing chapter list).
var _active_chapter: Dictionary = {}

## Looping tweens for node button animations — killed on exit.
var _pulse_tweens: Array[Tween] = []
var _glow_tweens: Array[Tween] = []

func _ready() -> void:
	_discover_chapters()

	# If returning from a dialogue/combat inside a chapter, jump straight
	# back to that chapter's detail view instead of the top-level list.
	var ctx: Dictionary = SceneManager.get_arrival_context()
	var target_chapter: String = ctx.get("chapter_id", "") as String
	if not target_chapter.is_empty():
		var file_name: String = "%s.json" % target_chapter
		if _chapter_files.has(file_name):
			var data: Dictionary = _load_chapter_file(file_name)
			if not data.is_empty():
				_active_chapter = data
				_show_chapter_detail(data)
				return

	_show_chapter_list()
	await get_tree().process_frame
	_animate_entrance()


# ── Chapter Discovery ──────────────────────────────────────────────────────────

## Scans the chapters directory for ch{nn}.json files.
func _discover_chapters() -> void:
	_chapter_files.clear()
	var dir_path: String = "res://assets/data/chapters"
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("ch") and file_name.ends_with(".json"):
			_chapter_files.append(file_name)
		file_name = dir.get_next()
	_chapter_files.sort()


## Loads and parses a single chapter JSON file. Returns empty dict on failure.
func _load_chapter_file(file_name: String) -> Dictionary:
	return JsonLoader.load_dict("res://assets/data/chapters/%s" % file_name)


# ── Level 1: Chapter List ──────────────────────────────────────────────────────

## Shows the list of available chapters.
func _show_chapter_list() -> void:
	_active_chapter = {}
	_kill_tweens()
	title_label.text = "STORY"

	for child: Node in chapter_list.get_children():
		child.queue_free()

	for file_name: String in _chapter_files:
		var data: Dictionary = _load_chapter_file(file_name)
		if data.is_empty():
			continue
		var chapter_id: String = data.get("id", "")
		var card: Button = _make_chapter_card(data)
		chapter_list.add_child(card)
		card.pressed.connect(_on_chapter_selected.bind(chapter_id, file_name))

	await get_tree().process_frame
	_animate_entrance()


## Creates a large card button for a single chapter.
func _make_chapter_card(data: Dictionary) -> Button:
	var chapter_id: String = data.get("id", "")
	var title_key: String = data.get("title_key", "")
	var subtitle_key: String = data.get("subtitle_key", "")
	var title_text: String = Localization.get_text(title_key)
	if title_text == title_key:
		title_text = chapter_id.replace("ch", "Chapter ").capitalize()
	var subtitle_text: String = Localization.get_text(subtitle_key)
	if subtitle_text == subtitle_key:
		subtitle_text = ""

	# Check if chapter is accessible (ch01 always, others need completion flag).
	var accessible: bool = true
	if chapter_id != "ch01":
		var prev_num: int = int(chapter_id.replace("ch", "")) - 1
		var prev_flag: String = "ch%02d_complete" % prev_num
		accessible = GameStore.has_flag(prev_flag)

	# Check chapter completion.
	var completed: bool = GameStore.has_flag(chapter_id + "_complete")

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 100.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = not accessible

	# Build label content.
	var status: String = " ✓" if completed else ""
	if not accessible:
		btn.text = "??? — Locked"
	else:
		btn.text = "%s%s\n%s" % [title_text, status, subtitle_text]

	# Styling.
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	if completed:
		style.bg_color = UIConstants.BG_SECONDARY
		style.border_color = UIConstants.ACCENT_GOLD
		btn.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	elif accessible:
		style.bg_color = UIConstants.BG_SECONDARY
		style.border_color = UIConstants.ACCENT_GOLD_BRIGHT
		btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	else:
		style.bg_color = UIConstants.BG_PRIMARY
		style.border_color = UIConstants.TEXT_DISABLED
		btn.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 16)

	return btn


# ── Level 2: Chapter Detail ───────────────────────────────────────────────────

## Shows the detail view for a selected chapter: location header + nodes by area.
func _on_chapter_selected(chapter_id: String, file_name: String) -> void:
	var data: Dictionary = _load_chapter_file(file_name)
	if data.is_empty():
		return
	_active_chapter = data
	_show_chapter_detail(data)


## Builds the chapter detail view with location header and area-grouped nodes.
func _show_chapter_detail(data: Dictionary) -> void:
	_kill_tweens()

	var title_key: String = data.get("title_key", "")
	var title_text: String = Localization.get_text(title_key)
	if title_text == title_key:
		title_text = data.get("id", "").capitalize()
	title_label.text = title_text

	for child: Node in chapter_list.get_children():
		child.queue_free()

	var nodes: Array = data.get("nodes", [])

	# Location header.
	var location_key: String = data.get("location_key", "")
	var subtitle_key: String = data.get("subtitle_key", "")
	if not location_key.is_empty():
		var loc_text: String = Localization.get_text(subtitle_key)
		var loc_desc: String = Localization.get_text(location_key)

		var header: VBoxContainer = VBoxContainer.new()
		header.add_theme_constant_override("separation", 6)
		chapter_list.add_child(header)

		var loc_lbl: Label = Label.new()
		loc_lbl.text = loc_text
		loc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loc_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
		loc_lbl.add_theme_font_size_override("font_size", 20)
		header.add_child(loc_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.text = loc_desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
		desc_lbl.add_theme_font_size_override("font_size", 12)
		header.add_child(desc_lbl)

		# Spacer.
		var spacer: Control = Control.new()
		spacer.custom_minimum_size = Vector2(0.0, 8.0)
		header.add_child(spacer)

		Fx.gold_shimmer(loc_lbl, 3.0)

	# Group nodes by area.
	var areas: Array[String] = []
	var area_nodes: Dictionary = {}
	for node_data: Variant in nodes:
		var nd: Dictionary = node_data as Dictionary
		var area: String = nd.get("area", "unknown")
		if not area_nodes.has(area):
			area_nodes[area] = []
			areas.append(area)
		area_nodes[area].append(nd)

	# Build area sections.
	for area: String in areas:
		_build_area_section(area, area_nodes[area])

	await get_tree().process_frame
	_animate_entrance()


## Builds a section header + node buttons for a single area.
func _build_area_section(area: String, nodes: Array) -> void:
	# Area header.
	var area_key: String = "AREA_%s" % area.to_upper()
	var area_name: String = Localization.get_text(area_key)
	if area_name == area_key:
		area_name = area.capitalize()

	var area_label: Label = Label.new()
	area_label.text = area_name
	area_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	area_label.add_theme_font_size_override("font_size", 14)
	area_label.custom_minimum_size = Vector2(0.0, 32.0)
	area_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	chapter_list.add_child(area_label)

	# Node buttons.
	for node_data: Variant in nodes:
		var nd: Dictionary = node_data as Dictionary
		var node_id: String = nd.get("id", "")
		var node_type: String = nd.get("type", "dialogue")
		var prereqs: Array = nd.get("prereqs", [])

		# Check prerequisites.
		var available: bool = true
		for prereq: Variant in prereqs:
			if not GameStore.has_flag(str(prereq)):
				available = false
				break

		# Check completion.
		var completed: bool = false
		var reward_flags: Array = nd.get("rewards", {}).get("flags", [])
		for flag: Variant in reward_flags:
			if GameStore.has_flag(str(flag)):
				completed = true
				break

		# Build button.
		var btn: Button = Button.new()
		var icon: String = "⚔" if node_type == "combat" else "💬"
		var status: String = " ✓" if completed else ""

		var name_key: String = "CHAPTER_NODE_%s" % node_id.to_upper()
		var display_name: String = Localization.get_text(name_key)
		if display_name == name_key:
			display_name = node_id.replace("ch01_", "").replace("_", " ").capitalize()

		btn.text = "%s  %s%s" % [icon, display_name, status]
		btn.custom_minimum_size = Vector2(0.0, 52.0)
		btn.disabled = not available or completed

		# Styling per state.
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0

		if completed:
			btn.modulate = Color(UIConstants.ACCENT_GOLD_DARK, 0.85)
			style.bg_color = UIConstants.BG_TERTIARY
			style.border_color = UIConstants.ACCENT_GOLD_DARK
			_start_gold_glow(btn)
		elif not available:
			btn.modulate = Color(UIConstants.TEXT_DISABLED, 0.5)
			style.bg_color = UIConstants.BG_PRIMARY
			style.border_color = UIConstants.TEXT_DISABLED
		else:
			style.bg_color = UIConstants.BG_SECONDARY
			style.border_color = UIConstants.ACCENT_GOLD
			btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
			_start_breathing_pulse(btn)

		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_font_size_override("font_size", 14)

		if available and not completed:
			var captured_data: Dictionary = nd
			btn.pressed.connect(func() -> void: _on_node_pressed(captured_data))

		chapter_list.add_child(btn)


# ── Animations ─────────────────────────────────────────────────────────────────

## Stagger all node buttons scaling from 0 to 1 with spring overshoot.
func _animate_entrance() -> void:
	var i: int = 0
	for child: Node in chapter_list.get_children():
		if child is Control:
			var ctrl: Control = child as Control
			ctrl.pivot_offset = ctrl.size * 0.5
			ctrl.scale = Vector2.ZERO
			var t: Tween = ctrl.create_tween()
			t.tween_property(ctrl, "scale", Vector2.ONE, 0.3) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
				.set_delay(i * 0.05)
			i += 1


## Gentle breathing scale loop for available (unlocked) nodes.
func _start_breathing_pulse(btn: Button) -> void:
	var t: Tween = btn.create_tween().set_loops()
	t.tween_property(btn, "scale", Vector2(1.02, 1.02), 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "scale", Vector2.ONE, 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tweens.append(t)


## Gold glow modulate pulse loop for completed nodes.
func _start_gold_glow(btn: Button) -> void:
	var t: Tween = btn.create_tween().set_loops()
	t.tween_property(btn, "modulate", Color(UIConstants.ACCENT_GOLD_BRIGHT, 0.95), 1.5) \
		.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(btn, "modulate", Color(UIConstants.ACCENT_GOLD_DARK, 0.75), 1.5) \
		.set_ease(Tween.EASE_IN_OUT)
	_glow_tweens.append(t)


## Kills all looping tweens to prevent orphan leaks.
func _kill_tweens() -> void:
	for t: Tween in _pulse_tweens:
		if t != null and t.is_valid():
			t.kill()
	for t: Tween in _glow_tweens:
		if t != null and t.is_valid():
			t.kill()
	_pulse_tweens.clear()
	_glow_tweens.clear()


# ── Node Interaction ───────────────────────────────────────────────────────────

func _on_node_pressed(node_data: Dictionary) -> void:
	var node_type: String = node_data.get("type", "dialogue") as String
	var node_id: String = node_data.get("id", "") as String

	# Apply meet effects before navigation.
	var effects: Array = node_data.get("effects", [])
	for fx: Variant in effects:
		var fx_dict: Dictionary = fx as Dictionary
		var fx_type: String = fx_dict.get("type", "") as String
		if fx_type == "meet":
			CompanionRegistry.meet_companion(fx_dict.get("companion", "") as String)

	if node_type == "combat":
		var enemy_id: String = node_data.get("enemy_id", "forest_monster") as String
		SceneManager.change_scene(
			SceneManager.SceneId.COMBAT,
			SceneManager.TransitionType.FADE,
			{"enemy_id": enemy_id, "captain_id": GameStore.get_last_captain_id(), "story_node": node_id}
		)
	else:
		var sequence: String = node_data.get("sequence", "") as String
		SceneManager.change_scene(
			SceneManager.SceneId.DIALOGUE,
			SceneManager.TransitionType.FADE,
			{"chapter_id": "ch01", "sequence_id": sequence, "story_node": node_id}
		)


# ── Navigation ─────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	if not _active_chapter.is_empty():
		# Go back to chapter list from chapter detail.
		_show_chapter_list()
	else:
		# Go back to hub from chapter list.
		SceneManager.change_scene(SceneManager.SceneId.HUB)
