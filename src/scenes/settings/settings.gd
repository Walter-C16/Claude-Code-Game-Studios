extends Control

## Settings overlay.
##
## Wraps SettingsStore with a player-facing screen. The .tscn ships with the
## three volume sliders (master, SFX, music) and a Close button; this script
## localizes all labels and appends two extra controls at runtime:
##
##   • Text Speed slider       — SettingsStore.set_text_speed
##   • Combat Timers toggle    — SettingsStore.set_combat_disable_timers
##                               (accessibility — see design/quick-specs/turn-timer.md)
##
## Runtime injection keeps the .tscn untouched so the scene file stays minimal.

signal close_requested

@onready var title_label: Label = %Title
@onready var close_btn: Button = %CloseBtn
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider

var _master_value_label: Label
var _sfx_value_label: Label
var _music_value_label: Label
var _text_speed_slider: HSlider
var _text_speed_value_label: Label
var _combat_timers_checkbox: CheckBox


func _ready() -> void:
	# Wrap the existing VBox in a ScrollContainer so the panel scrolls
	# when all injected controls exceed the viewport height on portrait
	# screens (430×932). The .tscn has Panel → VBox; we reparent to
	# Panel → ScrollContainer → VBox.
	var panel: Node = get_node_or_null("Panel")
	var vbox: Node = get_node_or_null("Panel/VBox")
	if panel != null and vbox != null:
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		panel.remove_child(vbox)
		panel.add_child(scroll)
		scroll.add_child(vbox)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Title and close button.
	title_label.text = Localization.get_text("SETTINGS_TITLE").to_upper()
	title_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title_label.add_theme_font_size_override("font_size", 22)

	close_btn.text = Localization.get_text("SETTINGS_CLOSE")
	close_btn.custom_minimum_size = Vector2(0.0, 48.0)
	close_btn.pressed.connect(_on_close)

	# Localize the existing volume labels from the .tscn. After the
	# ScrollContainer reparent above, VBox is no longer at Panel/VBox —
	# use the captured `vbox` variable instead of a path.
	if vbox != null:
		var master_lbl: Node = vbox.get_node_or_null("MasterLabel")
		if master_lbl is Label:
			(master_lbl as Label).text = Localization.get_text("SETTINGS_MASTER_VOL")
		var sfx_lbl: Node = vbox.get_node_or_null("SfxLabel")
		if sfx_lbl is Label:
			(sfx_lbl as Label).text = Localization.get_text("SETTINGS_SFX_VOL")
		var music_lbl: Node = vbox.get_node_or_null("MusicLabel")
		if music_lbl is Label:
			(music_lbl as Label).text = Localization.get_text("SETTINGS_MUSIC_VOL")

	# Volume sliders — state from SettingsStore.
	master_slider.value = SettingsStore.get_master_volume() * 100.0
	sfx_slider.value = SettingsStore.get_sfx_volume() * 100.0
	music_slider.value = SettingsStore.get_music_volume() * 100.0

	_master_value_label = _add_value_label(master_slider)
	_sfx_value_label = _add_value_label(sfx_slider)
	_music_value_label = _add_value_label(music_slider)

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

	# Append the extra gameplay controls that don't live in the .tscn.
	_install_extra_controls()

	_update_value_labels()

	# Style every plain label in the panel so section headers and slider
	# labels share a common look.
	var style_vbox: Node = vbox  # reuse the captured reference (may be reparented)
	if style_vbox != null:
		for child: Node in style_vbox.get_children():
			if child is Label and child != title_label:
				(child as Label).add_theme_color_override(
					"font_color", UIConstants.TEXT_SECONDARY
				)
				(child as Label).add_theme_font_size_override("font_size", 14)


## Adds the new text-speed slider and combat-timer toggle. Inserted just above
## the CloseBtn so the button stays the last element in the VBox.
func _install_extra_controls() -> void:
	var vbox: VBoxContainer = get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return

	# Spacer between audio and gameplay sections.
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 12.0)
	_insert_before_close(vbox, spacer)

	# Gameplay header.
	var header: Label = Label.new()
	header.text = Localization.get_text("SETTINGS_GAMEPLAY_HEADER")
	header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	header.add_theme_font_size_override("font_size", 15)
	_insert_before_close(vbox, header)

	# Text speed label.
	var ts_label: Label = Label.new()
	ts_label.text = Localization.get_text("SETTINGS_TEXT_SPEED")
	ts_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	ts_label.add_theme_font_size_override("font_size", 14)
	_insert_before_close(vbox, ts_label)

	# Text speed slider (0.1x to 3.0x, displayed as 10%–300%).
	_text_speed_slider = HSlider.new()
	_text_speed_slider.min_value = 10.0
	_text_speed_slider.max_value = 300.0
	_text_speed_slider.step = 10.0
	_text_speed_slider.value = SettingsStore.get_text_speed() * 100.0
	_insert_before_close(vbox, _text_speed_slider)
	_text_speed_value_label = _add_value_label(_text_speed_slider)
	_text_speed_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_text_speed(v / 100.0)
		_update_value_labels()
	)

	# Combat timers toggle.
	_combat_timers_checkbox = CheckBox.new()
	_combat_timers_checkbox.text = Localization.get_text("SETTINGS_DISABLE_TIMERS")
	_combat_timers_checkbox.button_pressed = SettingsStore.combat_disable_timers
	_combat_timers_checkbox.add_theme_color_override(
		"font_color", UIConstants.TEXT_PRIMARY
	)
	_combat_timers_checkbox.add_theme_font_size_override("font_size", 14)
	_combat_timers_checkbox.toggled.connect(func(pressed: bool) -> void:
		SettingsStore.set_combat_disable_timers(pressed)
	)
	_insert_before_close(vbox, _combat_timers_checkbox)

	# Save / Load section — manual save triggers an immediate flush to disk;
	# load reloads the last flush (which is also the auto-save checkpoint).
	var save_spacer: Control = Control.new()
	save_spacer.custom_minimum_size = Vector2(0.0, 12.0)
	_insert_before_close(vbox, save_spacer)

	var save_header: Label = Label.new()
	save_header.text = Localization.get_text("SETTINGS_DATA_HEADER")
	save_header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	save_header.add_theme_font_size_override("font_size", 15)
	_insert_before_close(vbox, save_header)

	var save_btn_row: HBoxContainer = HBoxContainer.new()
	save_btn_row.add_theme_constant_override("separation", 12)
	_insert_before_close(vbox, save_btn_row)

	# Version label at the very bottom.
	var version_label: Label = Label.new()
	version_label.text = "Dark Olympus v0.1.0"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.35, 1.0))
	version_label.add_theme_font_size_override("font_size", 10)
	_insert_before_close(vbox, version_label)

	var save_btn: Button = Button.new()
	save_btn.text = Localization.get_text("SETTINGS_SAVE")
	save_btn.custom_minimum_size = Vector2(0.0, 44.0)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	save_btn.add_theme_font_size_override("font_size", 14)
	save_btn.pressed.connect(_on_save_pressed)
	save_btn_row.add_child(save_btn)

	var load_btn: Button = Button.new()
	load_btn.text = Localization.get_text("SETTINGS_LOAD")
	load_btn.custom_minimum_size = Vector2(0.0, 44.0)
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	load_btn.add_theme_font_size_override("font_size", 14)
	load_btn.disabled = not SaveManager.has_save()
	load_btn.pressed.connect(_on_load_pressed)
	save_btn_row.add_child(load_btn)


## Inserts [param node] right above CloseBtn in the VBox. Keeps the close
## button as the last child so the layout remains stable.
func _insert_before_close(vbox: VBoxContainer, node: Control) -> void:
	vbox.add_child(node)
	if close_btn != null and close_btn.get_parent() == vbox:
		vbox.move_child(node, close_btn.get_index())


func _on_close() -> void:
	close_requested.emit()


func _on_save_pressed() -> void:
	var ok: bool = SaveManager.save_game()
	if ok:
		_show_save_feedback(Localization.get_text("SETTINGS_SAVE_OK"))
	else:
		_show_save_feedback(Localization.get_text("SETTINGS_SAVE_FAIL"))


func _on_load_pressed() -> void:
	if not SaveManager.has_save():
		return
	SaveManager.load_game()
	close_requested.emit()
	SceneManager.change_scene(SceneManager.SceneId.HUB)


## Brief feedback toast after save. Creates a temporary label that fades.
func _show_save_feedback(text: String) -> void:
	var vbox: Node = get_node_or_null("Panel/VBox")
	if vbox == null:
		return
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", UIConstants.STATUS_SUCCESS)
	lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl)
	# Fade out after 1.5s and remove.
	var tween: Tween = lbl.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tween.tween_callback(lbl.queue_free)


func _set_label_text(node_path: String, key: String) -> void:
	var node: Node = get_node_or_null(node_path)
	if node is Label:
		(node as Label).text = Localization.get_text(key)


func _add_value_label(slider: HSlider) -> Label:
	var lbl: Label = Label.new()
	lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	if _text_speed_value_label != null and _text_speed_slider != null:
		_text_speed_value_label.text = "%d%%" % int(_text_speed_slider.value)
