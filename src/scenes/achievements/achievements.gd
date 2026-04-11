extends Control

## Achievements — Styled achievement list with progress and unlock states.

@onready var title_label: Label = %Title
@onready var back_btn: Button = %BackBtn
@onready var list: VBoxContainer = %List

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	title_label.text = "ACHIEVEMENTS"
	title_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title_label.add_theme_font_size_override("font_size", 22)

	_load_achievements()
	await get_tree().process_frame
	Fx.stagger_children(list, 0.04, 16.0)


func _load_achievements() -> void:
	for child: Node in list.get_children():
		child.queue_free()

	var all: Array = Achievements.get_all()
	for ach: Variant in all:
		var data: Dictionary = ach as Dictionary
		var card: PanelContainer = _make_card(data)
		list.add_child(card)


func _make_card(data: Dictionary) -> PanelContainer:
	var unlocked: bool = data.get("unlocked", false)
	var title_key: String = data.get("title_key", data.get("id", ""))
	var desc_key: String = data.get("description_key", "")

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 72.0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	if unlocked:
		style.bg_color = UIConstants.BG_SECONDARY
		style.border_color = UIConstants.ACCENT_GOLD
	else:
		style.bg_color = UIConstants.BG_PRIMARY
		style.border_color = UIConstants.TEXT_DISABLED

	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Status icon.
	var icon: Label = Label.new()
	icon.custom_minimum_size = Vector2(32.0, 0.0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 20)
	if unlocked:
		icon.text = "★"
		icon.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	else:
		icon.text = "○"
		icon.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
	hbox.add_child(icon)

	# Text column.
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	hbox.add_child(text_col)

	var title_lbl: Label = Label.new()
	title_lbl.text = Localization.get_text(title_key)
	title_lbl.add_theme_font_size_override("font_size", 15)
	if unlocked:
		title_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
		Fx.gold_shimmer(title_lbl, 3.0)
	else:
		title_lbl.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
	text_col.add_child(title_lbl)

	if not desc_key.is_empty():
		var desc_lbl: Label = Label.new()
		desc_lbl.text = Localization.get_text(desc_key)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		if unlocked:
			desc_lbl.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
		else:
			desc_lbl.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		text_col.add_child(desc_lbl)

	return panel


func _on_back() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
