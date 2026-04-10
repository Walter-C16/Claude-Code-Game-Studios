extends Control

## Dialogue scene — typewriter text, portrait, choices, background.

@onready var bg: TextureRect = %Background
@onready var portrait: TextureRect = %Portrait
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var continue_indicator: Label = %ContinueIndicator
@onready var dialogue_panel: PanelContainer = %DialoguePanel

# Typewriter state
var _full_text: String = ""
var _visible_chars: int = 0
var _typewriter_active: bool = false
var _chars_per_second: float = 40.0

func _ready() -> void:
	choices_container.visible = false
	continue_indicator.visible = false

	DialogueStore.line_changed.connect(_on_line_changed)
	DialogueStore.choices_presented.connect(_on_choices_presented)
	DialogueStore.dialogue_ended.connect(_on_dialogue_ended)

	# Show first line
	if DialogueStore.active:
		_show_current_line()

func _process(delta: float) -> void:
	if _typewriter_active:
		_visible_chars += int(_chars_per_second * SettingsStore.text_speed * delta)
		if _visible_chars >= _full_text.length():
			_visible_chars = _full_text.length()
			_typewriter_active = false
			_on_typewriter_complete()
		text_label.visible_characters = _visible_chars

func _input(event: InputEvent) -> void:
	if not DialogueStore.active:
		return
	if event is InputEventMouseButton and event.pressed:
		_handle_tap()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap()

func _handle_tap() -> void:
	if _typewriter_active:
		# Skip typewriter — show full text immediately
		_visible_chars = _full_text.length()
		text_label.visible_characters = _visible_chars
		_typewriter_active = false
		_on_typewriter_complete()
	elif not DialogueStore.is_choice_node:
		# Advance to next line
		var has_more := DialogueStore.advance_line()
		if not has_more and not DialogueStore.is_choice_node:
			# Dialogue/node ended, will be handled by dialogue_ended signal
			pass

# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

func _show_current_line() -> void:
	var line: Dictionary = DialogueStore.get_current_line()
	if line.is_empty():
		return

	# Speaker
	var speaker: String = line.get("speaker", "narrator")
	if speaker == "narrator":
		speaker_label.text = ""
	else:
		speaker_label.text = DialogueRunner.get_text("COMPANION_%s" % speaker.to_upper(), {})
		if speaker_label.text.begins_with("COMPANION_"):
			speaker_label.text = speaker.capitalize()

	# Portrait
	var mood_str: String = line.get("mood", "neutral") if line.get("mood") else "neutral"
	if speaker != "narrator" and speaker != "priestess":
		var path := Companions.get_portrait_path(speaker, mood_str)
		if ResourceLoader.exists(path):
			portrait.texture = load(path)
			portrait.visible = true
		else:
			portrait.visible = false
	else:
		portrait.visible = false

	# Text (typewriter)
	var text_key: String = line.get("text_key", "")
	_full_text = DialogueRunner.get_text(text_key)
	text_label.text = _full_text
	text_label.visible_characters = 0
	_visible_chars = 0
	_typewriter_active = true

	# Hide choices and continue indicator during typewriter
	choices_container.visible = false
	continue_indicator.visible = false

func _on_typewriter_complete() -> void:
	if DialogueStore.is_choice_node and DialogueStore.current_line_index >= DialogueStore.current_lines.size() - 1:
		# Show choices after last line of a choice node
		_show_choices()
	else:
		continue_indicator.visible = true

func _show_choices() -> void:
	# Clear old choice buttons
	for child in choices_container.get_children():
		child.queue_free()

	for i in range(DialogueStore.current_choices.size()):
		var choice: Dictionary = DialogueStore.current_choices[i]
		var btn := Button.new()
		btn.text = DialogueRunner.get_text(choice.get("text_key", ""))
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)

	choices_container.visible = true
	continue_indicator.visible = false

func _on_choice_selected(index: int) -> void:
	choices_container.visible = false
	DialogueStore.select_choice(index)

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_line_changed() -> void:
	_show_current_line()

func _on_choices_presented(_choices: Array) -> void:
	_show_choices()

func _on_dialogue_ended() -> void:
	# Check if this is part of the intro flow
	if StoryFlow.active:
		StoryFlow.advance_step()
	else:
		# Default: go back to hub
		SceneManager.change_scene(SceneManager.SceneId.HUB)
