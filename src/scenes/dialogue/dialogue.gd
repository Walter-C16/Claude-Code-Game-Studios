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

## Current visible character progress (float accumulator for sub-frame precision).
var _visible_chars_float: float = 0.0

## True while the local typewriter animation is running.
var _typewriter_active: bool = false

## Characters per second for the typewriter animation.
## Sourced from DialogueRunner.cps so both share the same config value.
var _chars_per_second: float = 40.0

## Speaker from the previous line — used to detect speaker changes.
var _last_speaker: String = ""

## Story node id this dialogue was launched for — used to apply rewards on end.
var _story_node: String = ""

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	choices_container.visible = false
	continue_indicator.visible = false

	AudioManager.play_bgm("res://assets/audio/bgm/dialogue.ogg")
	# Sync CPS from the runner's loaded config value.
	_chars_per_second = DialogueRunner.cps

	# Wire DialogueRunner signals — code connections, not editor connections.
	DialogueRunner.line_ready.connect(_on_line_ready)
	DialogueRunner.choices_ready.connect(_on_choices_ready)
	DialogueRunner.dialogue_ended.connect(_on_dialogue_ended)
	DialogueRunner.typewriter_complete.connect(_on_typewriter_complete)

	# Read arrival context to start the correct dialogue sequence.
	var ctx: Dictionary = SceneManager.get_arrival_context()
	var chapter_id: String = ctx.get("chapter_id", "")
	var sequence_id: String = ctx.get("sequence_id", "")
	_story_node = ctx.get("story_node", "") as String
	if not chapter_id.is_empty() and not sequence_id.is_empty():
		DialogueRunner.start_dialogue(chapter_id, sequence_id)


## Drives the visual typewriter animation each frame.
## When complete, calls DialogueRunner.complete_typewriter() to sync runner state.
func _process(delta: float) -> void:
	if not _typewriter_active:
		return
	_visible_chars_float += _chars_per_second * delta
	var chars_to_show: int = int(_visible_chars_float)
	if chars_to_show >= _full_text.length():
		chars_to_show = _full_text.length()
		_typewriter_active = false
		text_label.visible_characters = chars_to_show
		# Notify the runner that the visual animation is done.
		DialogueRunner.complete_typewriter()
		return
	text_label.visible_characters = chars_to_show


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
	# Apply any story node rewards (gold, xp, flags) before navigating.
	if not _story_node.is_empty():
		_apply_story_rewards(_story_node)

	# After prologue, go to tutorial combat.
	if _sequence_id == "prologue":
		GameStore.set_flag("prologue_done")
		SceneManager.change_scene(
			SceneManager.SceneId.COMBAT,
			SceneManager.TransitionType.FADE,
			{"enemy_id": "forest_monster", "captain_id": "", "story_node": "ch01_n00"}
		)
		return
	# After crash rescue cutscene, go to Hub (simulating waking up in Artemis's house).
	if _sequence_id == "crash_rescue":
		GameStore.set_flag("ch01_crash_rescue_done")
		CompanionRegistry.meet_companion("artemis")
		SceneManager.change_scene(SceneManager.SceneId.HUB)
		return
	# For all other dialogues, go back to chapter map.
	SceneManager.change_scene(SceneManager.SceneId.CHAPTER_MAP)


## Looks up and applies rewards (gold, xp, flags, meet effects) from ch01.json.
func _apply_story_rewards(node_id: String) -> void:
	var path: String = "res://assets/data/chapters/ch01.json"
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var nodes: Array = json.data.get("nodes", [])
	for node: Variant in nodes:
		var nd: Dictionary = node as Dictionary
		if nd.get("id", "") == node_id:
			var rewards: Dictionary = nd.get("rewards", {})
			var gold: int = int(rewards.get("gold", 0))
			var xp: int = int(rewards.get("xp", 0))
			if gold > 0:
				GameStore.add_gold(gold)
			if xp > 0:
				GameStore.add_xp(xp)
			for flag: Variant in rewards.get("flags", []):
				GameStore.set_flag(str(flag))
			for fx: Variant in nd.get("effects", []):
				var fx_dict: Dictionary = fx as Dictionary
				if fx_dict.get("type", "") == "meet":
					CompanionRegistry.meet_companion(fx_dict.get("companion", "") as String)
			break


## Called when the visual typewriter animation signals completion from the runner.
## Used here only to show the continue indicator (choices are shown via choices_ready).
func _on_typewriter_complete() -> void:
	continue_indicator.visible = true


# ── Display ────────────────────────────────────────────────────────────────────

## Renders a single dialogue line: speaker label, portrait, and typewriter text.
func _display_line(line_data: Dictionary) -> void:
	var speaker: String = line_data.get("speaker", "narrator")
	var speaker_changed: bool = (speaker != _last_speaker)
	_last_speaker = speaker

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
			# Slide portrait in from left whenever the speaker changes.
			if speaker_changed:
				Fx.slide_in(portrait, Vector2(-60.0, 0.0), 0.35)
		else:
			portrait.visible = false
	else:
		portrait.visible = false

	# Subtle panel slide-up for each new line.
	Fx.slide_in(dialogue_panel, Vector2(0.0, 18.0), 0.25)

	# Shake on dramatic lines: text_key must contain "SHAKE" in all-caps.
	var text_key: String = line_data.get("text_key", "")
	if "SHAKE" in text_key:
		Fx.shake(self, 5.0, 0.25)

	# Text — start typewriter animation.
	var raw_text: String = line_data.get("text", line_data.get("text_key", ""))
	_full_text = raw_text
	text_label.text = _full_text
	text_label.visible_characters = 0
	_visible_chars_float = 0.0
	_typewriter_active = true

	# Reset UI state for new line.
	choices_container.visible = false
	continue_indicator.visible = false


## Populates and shows the choice buttons for a branching node, staggered.
func _show_choices(choices: Array) -> void:
	# Remove previous choice buttons.
	for child: Node in choices_container.get_children():
		child.queue_free()

	for i: int in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", choice.get("text_key", ""))
		btn.custom_minimum_size = Vector2(0, 44)
		btn.modulate.a = 0.0  # start invisible; stagger_children will fade them in
		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)

	choices_container.visible = true
	continue_indicator.visible = false

	# Stagger choices fading in from the bottom (100 ms between each).
	await get_tree().process_frame
	Fx.stagger_children(choices_container, 0.1, 16.0)


func _on_choice_selected(index: int) -> void:
	choices_container.visible = false
	DialogueRunner.select_choice(index)
