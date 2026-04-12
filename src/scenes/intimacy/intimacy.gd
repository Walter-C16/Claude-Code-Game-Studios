extends Control

## Intimacy — Companion intimate scene: CG image + dialogue + RL reward.
##
## Reads arrival context: companion_id, scene_num, gallery_replay (optional).
## Plays CG over fullscreen, runs dialogue via DialogueRunner, awards RL on end.

@onready var title_label: Label = %TitleLabel
@onready var content_area: Control = %ContentArea
@onready var back_btn: Button = %BackBtn

# ── Private State ──────────────────────────────────────────────────────────────

var _companion_id: String = ""
var _scene_num: int = 0
var _is_replay: bool = false
var _scene_data: Dictionary = {}
var _cg_rect: TextureRect
var _dialogue_panel: PanelContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _reward_popup: PanelContainer

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	var ctx: Dictionary = SceneManager.get_arrival_context()
	_companion_id = ctx.get("companion_id", "") as String
	_scene_num = ctx.get("scene_num", 1) as int
	_is_replay = ctx.get("gallery_replay", false)

	AudioManager.play_bgm("res://assets/audio/bgm/intimacy.ogg")

	if _companion_id.is_empty():
		title_label.text = "No scene data"
		return

	var profile: Dictionary = CompanionRegistry.get_profile(_companion_id)
	title_label.text = "%s — Scene %d" % [profile.get("display_name", _companion_id.capitalize()), _scene_num]

	# Get scene data from IntimacySystem.
	var entries: Array[Dictionary] = IntimacySystem.get_gallery_entries(_companion_id)
	for entry: Dictionary in entries:
		if entry.get("scene", 0) == _scene_num:
			_scene_data = entry
			break

	if _scene_data.is_empty():
		title_label.text = "Scene not found"
		return

	# Start the scene (consumes token if not replay).
	if not _is_replay:
		if not IntimacySystem.start_scene(_companion_id, _scene_num):
			title_label.text = "Cannot start scene"
			return

	_build_ui()
	back_btn.visible = false

	# Start dialogue after one frame.
	await get_tree().process_frame
	var dialogue_seq: String = _scene_data.get("dialogue_seq", "")
	if not dialogue_seq.is_empty():
		DialogueRunner.line_ready.connect(_on_line_ready)
		DialogueRunner.dialogue_ended.connect(_on_dialogue_ended)
		DialogueRunner.start_dialogue("intimacy", dialogue_seq)
	else:
		_finish_scene()


func _input(event: InputEvent) -> void:
	if not DialogueRunner.is_active():
		return
	if event is InputEventMouseButton and event.pressed:
		DialogueRunner.advance()
	elif event is InputEventScreenTouch and event.pressed:
		DialogueRunner.advance()


func _on_back_pressed() -> void:
	if DialogueRunner.is_active():
		DialogueRunner.force_end()
	SceneManager.change_scene(SceneManager.SceneId.COMPANION_ROOM)


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# CG display — fullscreen.
	_cg_rect = TextureRect.new()
	_cg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_cg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var cg_path: String = _scene_data.get("cg_path", "")
	if ResourceLoader.exists(cg_path):
		_cg_rect.texture = load(cg_path)
	else:
		# Placeholder: gradient colored rect.
		_cg_rect.modulate = Color(0.2, 0.15, 0.25, 1.0)
	content_area.add_child(_cg_rect)

	# Dark overlay for readability.
	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.4)
	content_area.add_child(overlay)

	# Dialogue panel at bottom.
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.offset_top = -200.0
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_bottom = 12.0
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	content_area.add_child(_dialogue_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_dialogue_panel.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	_speaker_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.custom_minimum_size = Vector2(0.0, 60.0)
	_text_label.add_theme_color_override("default_color", UIConstants.TEXT_PRIMARY)
	_text_label.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_text_label)


# ── Dialogue Callbacks ─────────────────────────────────────────────────────────

func _on_line_ready(line_data: Dictionary) -> void:
	var speaker: String = line_data.get("speaker", "narrator")
	if speaker == "narrator":
		_speaker_label.text = ""
	else:
		_speaker_label.text = speaker.capitalize()

	var text: String = line_data.get("text", line_data.get("text_key", ""))
	_text_label.text = text
	Fx.slide_in(_dialogue_panel, Vector2(0.0, 12.0), 0.2)


func _on_dialogue_ended(_sequence_id: String) -> void:
	DialogueRunner.line_ready.disconnect(_on_line_ready)
	DialogueRunner.dialogue_ended.disconnect(_on_dialogue_ended)
	_finish_scene()


# ── Scene Completion ───────────────────────────────────────────────────────────

func _finish_scene() -> void:
	if not _is_replay and not IntimacySystem.is_scene_complete(_companion_id, _scene_num):
		IntimacySystem.complete_scene(_companion_id, _scene_num)
		_show_reward_popup()
	else:
		back_btn.visible = true


func _show_reward_popup() -> void:
	var rl: int = 10 if _scene_num < 3 else 20

	_reward_popup = PanelContainer.new()
	_reward_popup.anchor_left = 0.5
	_reward_popup.anchor_right = 0.5
	_reward_popup.anchor_top = 0.5
	_reward_popup.anchor_bottom = 0.5
	_reward_popup.offset_left = -140.0
	_reward_popup.offset_right = 140.0
	_reward_popup.offset_top = -80.0
	_reward_popup.offset_bottom = 80.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = UIConstants.ACCENT_GOLD
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	_reward_popup.add_theme_stylebox_override("panel", style)
	add_child(_reward_popup)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_reward_popup.add_child(vbox)

	var reward_lbl: Label = Label.new()
	reward_lbl.text = "+%d Relationship" % rl
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	reward_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(reward_lbl)
	Fx.pop_scale(reward_lbl)

	var gallery_lbl: Label = Label.new()
	gallery_lbl.text = "Unlocked in Gallery"
	gallery_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gallery_lbl.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	gallery_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(gallery_lbl)

	var ok_btn: Button = Button.new()
	ok_btn.text = "Continue"
	ok_btn.custom_minimum_size = Vector2(0.0, 48.0)
	ok_btn.pressed.connect(func() -> void:
		SceneManager.change_scene(SceneManager.SceneId.COMPANION_ROOM)
	)
	vbox.add_child(ok_btn)

	Fx.slide_in(_reward_popup, Vector2(0.0, 30.0), 0.3)
