extends Control

## Settings overlay — Volume sliders + language display.

signal close_requested

@onready var title_label: Label = %Title
@onready var close_btn: Button = %CloseBtn
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider

var _master_value_label: Label
var _sfx_value_label: Label
var _music_value_label: Label

func _ready() -> void:
	# Style the title.
	title_label.text = "SETTINGS"
	title_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title_label.add_theme_font_size_override("font_size", 22)

	# Style close button.
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(48.0, 48.0)
	close_btn.pressed.connect(_on_close)

	# Initialize sliders from SettingsStore.
	master_slider.value = SettingsStore.get_master_volume() * 100.0
	sfx_slider.value = SettingsStore.get_sfx_volume() * 100.0
	music_slider.value = SettingsStore.get_music_volume() * 100.0

	# Add percentage labels next to sliders.
	_master_value_label = _add_value_label(master_slider)
	_sfx_value_label = _add_value_label(sfx_slider)
	_music_value_label = _add_value_label(music_slider)

	_update_value_labels()

	# Wire slider changes.
	master_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_master_volume(v / 100.0)
		_update_value_labels()
	)
	sfx_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_sfx_volume(v / 100.0)
		_update_value_labels()
	)
	music_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_music_volume(v / 100.0)
		_update_value_labels()
	)

	# Style all labels in the panel.
	var panel: Node = get_node_or_null("Panel/VBox")
	if panel != null:
		for child: Node in panel.get_children():
			if child is Label and child != title_label:
				child.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
				child.add_theme_font_size_override("font_size", 14)


func _on_close() -> void:
	close_requested.emit()


func _add_value_label(slider: HSlider) -> Label:
	var lbl: Label = Label.new()
	lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Insert after the slider in its parent.
	var parent: Node = slider.get_parent()
	if parent != null:
		var idx: int = slider.get_index()
		parent.add_child(lbl)
		parent.move_child(lbl, idx + 1)
	return lbl


func _update_value_labels() -> void:
	if _master_value_label != null:
		_master_value_label.text = "%d%%" % int(master_slider.value)
	if _sfx_value_label != null:
		_sfx_value_label.text = "%d%%" % int(sfx_slider.value)
	if _music_value_label != null:
		_music_value_label.text = "%d%%" % int(music_slider.value)
