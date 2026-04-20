extends Control

## Settings overlay.
##
## Wraps SettingsStore + SaveManager with a player-facing screen. The .tscn
## ships with three volume sliders (master, SFX, music) and a Close button;
## this script rebuilds the layout at runtime so it can inject the gameplay
## and data sections without edits to the .tscn.
##
## Sections (top to bottom):
##   AUDIO     — master, SFX, music volume sliders with inline % readouts
##   GAMEPLAY  — text-speed slider, combat-timer toggle, language selector,
##               reset-to-defaults button
##   DATA      — manual save, load, delete-save (two-tap confirm)
##   FOOTER    — version string
##   CLOSE     — sticky at the bottom of the panel

signal close_requested

@onready var title_label: Label = %Title
@onready var close_btn: Button = %CloseBtn
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider

# ── Runtime-built references ───────────────────────────────────────────────────

var _master_value_label: Label
var _sfx_value_label: Label
var _music_value_label: Label
var _text_speed_slider: HSlider
var _text_speed_value_label: Label
var _text_speed_preview: Label
var _combat_timers_checkbox: CheckBox
var _delete_save_btn: Button
var _delete_confirm_pending: bool = false
var _save_feedback_label: Label

# ── Constants ──────────────────────────────────────────────────────────────────

const VERSION_STRING: String = "Dark Olympus v0.0.1"
const SECTION_HEADER_COLOR: Color = Color(0.831, 0.659, 0.261, 1.0)  # ACCENT_GOLD
const DIVIDER_COLOR: Color = Color(0.831, 0.659, 0.261, 0.25)
const FOOTER_COLOR: Color = Color(0.4, 0.38, 0.35, 1.0)


func _ready() -> void:
	var panel: Node = get_node_or_null("Panel")
	var vbox: Node = get_node_or_null("Panel/VBox")
	if panel == null or vbox == null:
		push_error("settings.gd: missing Panel/VBox in scene — layout cannot initialize")
		return

	# Wrap VBox in a ScrollContainer so the panel scrolls on portrait phones.
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.remove_child(vbox)
	panel.add_child(scroll)
	scroll.add_child(vbox)
	(vbox as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(vbox as VBoxContainer).add_theme_constant_override("separation", 10)

	# Title.
	title_label.text = Localization.get_text("SETTINGS_TITLE").to_upper()
	title_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title_label.add_theme_font_size_override("font_size", 22)

	# Close button sticks at the bottom.
	close_btn.text = Localization.get_text("SETTINGS_CLOSE")
	close_btn.custom_minimum_size = Vector2(0.0, 48.0)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.pressed.connect(_on_close)

	# Restructure existing .tscn children (volume sliders) into inline-labeled
	# rows, then insert extra sections above the close button.
	_rebuild_audio_section(vbox as VBoxContainer)
	_install_gameplay_section(vbox as VBoxContainer)
	_install_data_section(vbox as VBoxContainer)
	_install_footer(vbox as VBoxContainer)

	_update_value_labels()


# ── Audio Section ─────────────────────────────────────────────────────────────

## Rebuilds the three volume rows so each slider sits in an HBox with its
## label on the left and a percentage readout on the right. The .tscn
## already has the slider nodes — we reparent them into fresh rows.
func _rebuild_audio_section(vbox: VBoxContainer) -> void:
	_insert_section_header(vbox, "SETTINGS_AUDIO_HEADER", Localization.get_text("SETTINGS_AUDIO_HEADER") if _has_key("SETTINGS_AUDIO_HEADER") else "AUDIO")

	_master_value_label = _rebuild_slider_row(
		vbox, master_slider, "MasterLabel", "SETTINGS_MASTER_VOL"
	)
	_sfx_value_label = _rebuild_slider_row(
		vbox, sfx_slider, "SfxLabel", "SETTINGS_SFX_VOL"
	)
	_music_value_label = _rebuild_slider_row(
		vbox, music_slider, "MusicLabel", "SETTINGS_MUSIC_VOL"
	)

	# Wire the sliders to the store.
	master_slider.value = SettingsStore.get_master_volume() * 100.0
	sfx_slider.value = SettingsStore.get_sfx_volume() * 100.0
	music_slider.value = SettingsStore.get_music_volume() * 100.0

	master_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_master_volume(v / 100.0)
		_update_value_labels())
	sfx_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_sfx_volume(v / 100.0)
		_update_value_labels())
	music_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_music_volume(v / 100.0)
		_update_value_labels())

	_insert_divider(vbox)


## Reparents an existing slider from VBox into a labeled HBox row:
##   [Label (left, flex)]  [Slider (stretch)]  [% readout (right)]
## Returns the percentage-readout label so the caller can update it.
func _rebuild_slider_row(
	vbox: VBoxContainer, slider: HSlider, old_label_name: String, text_key: String
) -> Label:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	# Move the slider into our row; drop its sibling label.
	var old_label: Node = vbox.get_node_or_null(old_label_name)
	if old_label != null:
		old_label.queue_free()
	if slider.get_parent() != null:
		slider.get_parent().remove_child(slider)

	var lbl: Label = Label.new()
	lbl.text = Localization.get_text(text_key)
	lbl.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.custom_minimum_size = Vector2(110.0, 0.0)
	row.add_child(lbl)

	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0.0, 36.0)
	row.add_child(slider)

	var value_lbl: Label = Label.new()
	value_lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	value_lbl.add_theme_font_size_override("font_size", 13)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.custom_minimum_size = Vector2(48.0, 0.0)
	row.add_child(value_lbl)

	return value_lbl


# ── Gameplay Section ──────────────────────────────────────────────────────────

func _install_gameplay_section(vbox: VBoxContainer) -> void:
	_insert_section_header(vbox, "SETTINGS_GAMEPLAY_HEADER", "GAMEPLAY")

	# Text speed slider with inline % readout, preview below.
	var ts_row: HBoxContainer = HBoxContainer.new()
	ts_row.add_theme_constant_override("separation", 10)
	_insert_before_close(vbox, ts_row)

	var ts_label: Label = Label.new()
	ts_label.text = Localization.get_text("SETTINGS_TEXT_SPEED")
	ts_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	ts_label.add_theme_font_size_override("font_size", 14)
	ts_label.custom_minimum_size = Vector2(110.0, 0.0)
	ts_row.add_child(ts_label)

	_text_speed_slider = HSlider.new()
	_text_speed_slider.min_value = 10.0
	_text_speed_slider.max_value = 300.0
	_text_speed_slider.step = 10.0
	_text_speed_slider.value = SettingsStore.get_text_speed() * 100.0
	_text_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_speed_slider.custom_minimum_size = Vector2(0.0, 36.0)
	ts_row.add_child(_text_speed_slider)

	_text_speed_value_label = Label.new()
	_text_speed_value_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_text_speed_value_label.add_theme_font_size_override("font_size", 13)
	_text_speed_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_text_speed_value_label.custom_minimum_size = Vector2(48.0, 0.0)
	ts_row.add_child(_text_speed_value_label)

	_text_speed_slider.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_text_speed(v / 100.0)
		_update_value_labels())

	# Combat timer toggle.
	_combat_timers_checkbox = CheckBox.new()
	_combat_timers_checkbox.text = Localization.get_text("SETTINGS_DISABLE_TIMERS")
	_combat_timers_checkbox.button_pressed = SettingsStore.combat_disable_timers
	_combat_timers_checkbox.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_combat_timers_checkbox.add_theme_font_size_override("font_size", 14)
	_combat_timers_checkbox.custom_minimum_size = Vector2(0.0, 36.0)
	_combat_timers_checkbox.toggled.connect(func(pressed: bool) -> void:
		SettingsStore.set_combat_disable_timers(pressed))
	_insert_before_close(vbox, _combat_timers_checkbox)

	# Language selector (0.0.1: English only, future-proofed).
	var lang_row: HBoxContainer = HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 10)
	_insert_before_close(vbox, lang_row)

	var lang_label: Label = Label.new()
	lang_label.text = Localization.get_text("SETTINGS_LANGUAGE")
	lang_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	lang_label.add_theme_font_size_override("font_size", 14)
	lang_label.custom_minimum_size = Vector2(110.0, 0.0)
	lang_row.add_child(lang_label)

	var lang_option: OptionButton = OptionButton.new()
	lang_option.add_item("English", 0)
	lang_option.selected = 0
	lang_option.disabled = true
	lang_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_option.custom_minimum_size = Vector2(0.0, 36.0)
	lang_option.tooltip_text = Localization.get_text("SETTINGS_LANGUAGE_COMING_SOON")
	lang_row.add_child(lang_option)

	# Reset-to-defaults button.
	var reset_btn: Button = Button.new()
	reset_btn.text = Localization.get_text("SETTINGS_RESET_DEFAULTS")
	reset_btn.custom_minimum_size = Vector2(0.0, 40.0)
	reset_btn.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.pressed.connect(_on_reset_defaults_pressed)
	_insert_before_close(vbox, reset_btn)

	_insert_divider(vbox)


# ── Data Section ──────────────────────────────────────────────────────────────

func _install_data_section(vbox: VBoxContainer) -> void:
	_insert_section_header(vbox, "SETTINGS_DATA_HEADER", "DATA")

	# Save + Load in one row.
	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 10)
	_insert_before_close(vbox, save_row)

	var save_btn: Button = _make_data_button("SETTINGS_SAVE", UIConstants.TEXT_PRIMARY)
	save_btn.pressed.connect(_on_save_pressed)
	save_row.add_child(save_btn)

	var load_btn: Button = _make_data_button("SETTINGS_LOAD", UIConstants.TEXT_PRIMARY)
	load_btn.disabled = not SaveManager.has_save()
	load_btn.pressed.connect(_on_load_pressed)
	save_row.add_child(load_btn)

	# Delete-save button stands alone (two-tap confirmation to prevent
	# accidental progress loss — no modal overhead).
	_delete_save_btn = Button.new()
	_delete_save_btn.text = Localization.get_text("SETTINGS_DELETE_SAVE")
	_delete_save_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_delete_save_btn.add_theme_color_override("font_color", UIConstants.STATUS_DANGER)
	_delete_save_btn.add_theme_font_size_override("font_size", 13)
	_delete_save_btn.disabled = not SaveManager.has_save()
	_delete_save_btn.pressed.connect(_on_delete_save_pressed)
	_insert_before_close(vbox, _delete_save_btn)

	# Reserved slot for save feedback toasts. Kept as a fixed-height label so
	# the layout doesn't shift when a toast appears.
	_save_feedback_label = Label.new()
	_save_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_feedback_label.add_theme_font_size_override("font_size", 13)
	_save_feedback_label.custom_minimum_size = Vector2(0.0, 22.0)
	_save_feedback_label.modulate.a = 0.0
	_insert_before_close(vbox, _save_feedback_label)

	_insert_divider(vbox)


# ── Footer ────────────────────────────────────────────────────────────────────

func _install_footer(vbox: VBoxContainer) -> void:
	var version_lbl: Label = Label.new()
	version_lbl.text = VERSION_STRING
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_lbl.add_theme_color_override("font_color", FOOTER_COLOR)
	version_lbl.add_theme_font_size_override("font_size", 10)
	_insert_before_close(vbox, version_lbl)


# ── Button actions ────────────────────────────────────────────────────────────

func _on_close() -> void:
	close_requested.emit()


func _on_save_pressed() -> void:
	var ok: bool = SaveManager.save_game()
	if ok:
		_show_save_feedback(Localization.get_text("SETTINGS_SAVE_OK"), UIConstants.STATUS_SUCCESS)
		# Refresh Load + Delete buttons — they may have been disabled before
		# the first save was written.
		if _delete_save_btn != null:
			_delete_save_btn.disabled = false
	else:
		_show_save_feedback(Localization.get_text("SETTINGS_SAVE_FAIL"), UIConstants.STATUS_DANGER)


func _on_load_pressed() -> void:
	if not SaveManager.has_save():
		return
	SaveManager.load_game()
	close_requested.emit()
	SceneManager.change_scene(SceneManager.SceneId.HUB)


## Two-tap confirmation for destructive save deletion. First tap flips the
## button into a confirm state with a countdown-style "Tap again" label; if
## the player doesn't confirm within 3 seconds, it reverts. Second tap
## inside the window wipes the save and returns to the splash.
func _on_delete_save_pressed() -> void:
	if not _delete_confirm_pending:
		_delete_confirm_pending = true
		_delete_save_btn.text = Localization.get_text("SETTINGS_DELETE_SAVE_CONFIRM")
		_delete_save_btn.add_theme_color_override("font_color", UIConstants.STATUS_DANGER)
		var timer: SceneTreeTimer = get_tree().create_timer(3.0)
		timer.timeout.connect(func() -> void:
			if _delete_confirm_pending and _delete_save_btn != null:
				_delete_confirm_pending = false
				_delete_save_btn.text = Localization.get_text("SETTINGS_DELETE_SAVE"))
		return

	# Confirmed — wipe and reset.
	_delete_confirm_pending = false
	SaveManager.delete_save()
	_show_save_feedback(Localization.get_text("SETTINGS_DELETE_SAVE_OK"), UIConstants.STATUS_SUCCESS)
	_delete_save_btn.disabled = true
	_delete_save_btn.text = Localization.get_text("SETTINGS_DELETE_SAVE")
	# Send the player back to splash so a fresh state loads on New Game.
	await get_tree().create_timer(1.0).timeout
	SceneManager.change_scene(SceneManager.SceneId.SPLASH)


## Resets audio + gameplay settings to stock. Does NOT touch save data.
func _on_reset_defaults_pressed() -> void:
	SettingsStore.set_master_volume(1.0)
	SettingsStore.set_sfx_volume(1.0)
	SettingsStore.set_music_volume(1.0)
	SettingsStore.set_text_speed(1.0)
	SettingsStore.set_combat_disable_timers(false)

	master_slider.value = 100.0
	sfx_slider.value = 100.0
	music_slider.value = 100.0
	if _text_speed_slider != null:
		_text_speed_slider.value = 100.0
	if _combat_timers_checkbox != null:
		_combat_timers_checkbox.button_pressed = false

	_update_value_labels()
	_show_save_feedback(Localization.get_text("SETTINGS_RESET_OK"), UIConstants.STATUS_SUCCESS)


# ── Helpers ───────────────────────────────────────────────────────────────────

## Inserts [param node] right above CloseBtn in the VBox. Keeps the close
## button as the last child so the layout stays stable.
func _insert_before_close(vbox: VBoxContainer, node: Control) -> void:
	vbox.add_child(node)
	if close_btn != null and close_btn.get_parent() == vbox:
		vbox.move_child(node, close_btn.get_index())


## Small spacer + gold hairline that separates visual sections.
func _insert_divider(vbox: VBoxContainer) -> void:
	var top_space: Control = Control.new()
	top_space.custom_minimum_size = Vector2(0.0, 6.0)
	_insert_before_close(vbox, top_space)

	var line: ColorRect = ColorRect.new()
	line.custom_minimum_size = Vector2(0.0, 1.0)
	line.color = DIVIDER_COLOR
	_insert_before_close(vbox, line)

	var bot_space: Control = Control.new()
	bot_space.custom_minimum_size = Vector2(0.0, 6.0)
	_insert_before_close(vbox, bot_space)


## Inserts a styled section header (all-caps, gold accent).
func _insert_section_header(vbox: VBoxContainer, key: String, fallback: String) -> void:
	var header: Label = Label.new()
	var text: String = Localization.get_text(key) if _has_key(key) else fallback
	header.text = text.to_upper()
	header.add_theme_color_override("font_color", SECTION_HEADER_COLOR)
	header.add_theme_font_size_override("font_size", 13)
	_insert_before_close(vbox, header)


## Builds a data-section button (Save / Load) with consistent styling.
func _make_data_button(text_key: String, color: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = Localization.get_text(text_key)
	btn.custom_minimum_size = Vector2(0.0, 44.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 14)
	return btn


## Shows brief inline feedback in the reserved feedback slot. Fades out.
func _show_save_feedback(text: String, color: Color) -> void:
	if _save_feedback_label == null:
		return
	_save_feedback_label.text = text
	_save_feedback_label.add_theme_color_override("font_color", color)
	_save_feedback_label.modulate.a = 1.0
	var tween: Tween = _save_feedback_label.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_save_feedback_label, "modulate:a", 0.0, 0.5)


func _update_value_labels() -> void:
	if _master_value_label != null:
		_master_value_label.text = "%d%%" % int(master_slider.value)
	if _sfx_value_label != null:
		_sfx_value_label.text = "%d%%" % int(sfx_slider.value)
	if _music_value_label != null:
		_music_value_label.text = "%d%%" % int(music_slider.value)
	if _text_speed_value_label != null and _text_speed_slider != null:
		_text_speed_value_label.text = "%d%%" % int(_text_speed_slider.value)


## Returns true if the i18n key resolves to something other than itself —
## Localization.get_text returns the raw key when it's missing, which would
## show up as an ugly all-caps placeholder in the header.
func _has_key(key: String) -> bool:
	return Localization.get_text(key) != key
