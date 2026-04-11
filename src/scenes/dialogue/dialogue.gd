extends Control

## Dialogue scene — typewriter text, portrait, choices, background.
##
## Drives visual presentation only. All dialogue state lives in DialogueRunner
## (autoload #9). This scene connects to DialogueRunner signals and calls
## DialogueRunner.advance() / complete_typewriter() / select_choice() for input.
##
## Signal wiring (all in _ready, code-side):
##   DialogueRunner.line_ready      → _on_line_ready(line_data)
##   DialogueRunner.choices_ready   → _on_choices_ready(choices)
##   DialogueRunner.dialogue_ended  → _on_dialogue_ended(sequence_id)
##   DialogueRunner.typewriter_complete → _on_typewriter_complete()

# ── Node References ────────────────────────────────────────────────────────────

@onready var bg: TextureRect = %Background
@onready var portrait: TextureRect = %Portrait
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var continue_indicator: Label = %ContinueIndicator
@onready var dialogue_panel: PanelContainer = %DialoguePanel

# ── Private State ──────────────────────────────────────────────────────────────

## Full text for the current line, used by the local typewriter animation.
var _full_text: String = ""

## Current visible character count driven by _process.
var _visible_chars: int = 0

## True while the local typewriter animation is running.
var _typewriter_active: bool = false

## Characters per second for the typewriter animation.
## Sourced from DialogueRunner.cps so both share the same config value.
var _chars_per_second: float = 40.0

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	choices_container.visible = false
	continue_indicator.visible = false

	# Sync CPS from the runner's loaded config value.
	_chars_per_second = DialogueRunner.cps

	# Wire DialogueRunner signals — code connections, not editor connections.
	DialogueRunner.line_ready.connect(_on_line_ready)
	DialogueRunner.choices_ready.connect(_on_choices_ready)
	DialogueRunner.dialogue_ended.connect(_on_dialogue_ended)
	DialogueRunner.typewriter_complete.connect(_on_typewriter_complete)

	# If the runner is already mid-sequence (scene loaded mid-dialogue), nothing
	# extra is needed here — the next line_ready signal will update the display.

## Drives the visual typewriter animation each frame.
## When complete, calls DialogueRunner.complete_typewriter() to sync runner state.
func _process(delta: float) -> void:
	if not _typewriter_active:
		return
	_visible_chars += int(_chars_per_second * delta)
	if _visible_chars >= _full_text.length():
		_visible_chars = _full_text.length()
		_typewriter_active = false
		text_label.visible_characters = _visible_chars
		# Notify the runner that the visual animation is done.
		DialogueRunner.complete_typewriter()
		return
	text_label.visible_characters = _visible_chars

func _input(event: InputEvent) -> void:
	if not DialogueRunner.is_active():
		return
	if event is InputEventMouseButton and event.pressed:
		_handle_tap()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap()

# ── Input Handling ─────────────────────────────────────────────────────────────

func _handle_tap() -> void:
	# advance() handles both tap-to-complete and tap-to-advance internally.
	DialogueRunner.advance()

# ── Signal Callbacks ───────────────────────────────────────────────────────────

## Called when the runner has a new line ready for display.
## line_data keys: speaker, speaker_type, text_key, mood, text_params (optional).
func _on_line_ready(line_data: Dictionary) -> void:
	_display_line(line_data)

## Called when the runner has entered a choice node and choices are ready.
func _on_choices_ready(choices: Array) -> void:
	_show_choices(choices)

## Called when the active dialogue sequence ends.
## StoryFlow is the orchestrator and handles its own sequencing via EventBus.
## This scene only acts when StoryFlow is NOT active (standalone/dev dialogue).
func _on_dialogue_ended(_sequence_id: String) -> void:
	if not StoryFlow.is_active():
		SceneManager.change_scene(SceneManager.SceneId.HUB)

## Called when the visual typewriter animation signals completion from the runner.
## Used here only to show the continue indicator (choices are shown via choices_ready).
func _on_typewriter_complete() -> void:
	continue_indicator.visible = true

# ── Display ────────────────────────────────────────────────────────────────────

## Renders a single dialogue line: speaker label, portrait, and typewriter text.
func _display_line(line_data: Dictionary) -> void:
	var speaker: String = line_data.get("speaker", "narrator")

	# Speaker label — blank for narrator.
	if speaker == "narrator":
		speaker_label.text = ""
	else:
		speaker_label.text = speaker.capitalize()

	# Portrait — companions and named characters only; narrator/priestess have none.
	var mood: String = line_data.get("mood", "neutral") if line_data.get("mood") else "neutral"
	if speaker != "narrator" and speaker != "priestess":
		var path: String = CompanionRegistry.get_portrait_path(speaker, mood)
		if ResourceLoader.exists(path):
			portrait.texture = load(path)
			portrait.visible = true
		else:
			portrait.visible = false
	else:
		portrait.visible = false

	# Text — start typewriter animation.
	var raw_text: String = line_data.get("text", line_data.get("text_key", ""))
	_full_text = raw_text
	text_label.text = _full_text
	text_label.visible_characters = 0
	_visible_chars = 0
	_typewriter_active = true

	# Reset UI state for new line.
	choices_container.visible = false
	continue_indicator.visible = false

## Populates and shows the choice buttons for a branching node.
func _show_choices(choices: Array) -> void:
	# Remove previous choice buttons.
	for child: Node in choices_container.get_children():
		child.queue_free()

	for i: int in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", choice.get("text_key", ""))
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)

	choices_container.visible = true
	continue_indicator.visible = false

func _on_choice_selected(index: int) -> void:
	choices_container.visible = false
	DialogueRunner.select_choice(index)
