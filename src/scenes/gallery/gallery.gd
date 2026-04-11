extends Control

## Gallery — CG collection grid. Unlocked scenes are viewable; locked show "?".

@onready var title_label: Label = %Title
@onready var back_btn: Button = %BackBtn
@onready var grid: GridContainer = %Grid

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	title_label.text = "GALLERY"
	title_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title_label.add_theme_font_size_override("font_size", 22)

	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	_load_gallery()
	await get_tree().process_frame
	Fx.stagger_children(grid, 0.04, 16.0)


func _load_gallery() -> void:
	for child: Node in grid.get_children():
		child.queue_free()

	var entries: Array[Dictionary] = Gallery.get_all_entries()
	for entry: Dictionary in entries:
		var cell: PanelContainer = _make_cell(entry)
		grid.add_child(cell)


func _make_cell(entry: Dictionary) -> PanelContainer:
	var unlocked: bool = entry.get("unlocked", false)
	var title_key: String = entry.get("title_key", "???")
	var cg_path: String = entry.get("cg_path", "")

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120.0, 140.0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0

	if unlocked:
		style.bg_color = UIConstants.BG_SECONDARY
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = UIConstants.ACCENT_GOLD
	else:
		style.bg_color = UIConstants.BG_PRIMARY
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = UIConstants.TEXT_DISABLED

	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Thumbnail or placeholder.
	var thumb: TextureRect = TextureRect.new()
	thumb.custom_minimum_size = Vector2(100.0, 80.0)
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.expand_mode = TextureRect.EXPAND_FIT_WIDTH

	if unlocked and ResourceLoader.exists(cg_path):
		thumb.texture = load(cg_path)
	else:
		thumb.modulate = Color(0.15, 0.12, 0.1, 1.0) if not unlocked else Color(0.3, 0.25, 0.2, 1.0)
	vbox.add_child(thumb)

	# Label.
	var lbl: Label = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)

	if unlocked:
		lbl.text = Localization.get_text(title_key)
		lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	else:
		lbl.text = "???"
		lbl.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
	vbox.add_child(lbl)

	# Tap to replay (unlocked only).
	if unlocked:
		var btn: Button = Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		var entry_copy: Dictionary = entry.duplicate()
		btn.pressed.connect(func() -> void: _on_entry_tapped(entry_copy))
		panel.add_child(btn)

	return panel


func _on_entry_tapped(entry: Dictionary) -> void:
	# Parse companion_id and scene_num from entry id (format: "artemis_scene_1").
	var entry_id: String = entry.get("id", "")
	var entry_type: String = entry.get("type", "")
	if entry_type != "intimacy":
		return

	var parts: PackedStringArray = entry_id.split("_scene_")
	if parts.size() != 2:
		return
	var companion_id: String = parts[0]
	var scene_num: int = int(parts[1])

	SceneManager.change_scene(
		SceneManager.SceneId.INTIMACY,
		SceneManager.TransitionType.FADE,
		{"companion_id": companion_id, "scene_num": scene_num, "gallery_replay": true}
	)


func _on_back() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
