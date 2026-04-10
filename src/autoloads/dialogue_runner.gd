extends Node

const _CompanionStateScript = preload("res://systems/companion_state.gd")

## DialogueRunner — Dialogue Script Engine (ADR-0008)
##
## Autoload #9. Loads JSON dialogue sequences from
## res://assets/data/dialogue/{chapter_id}/{sequence_id}.json,
## checks root-level prerequisites, plays back lines with typewriter
## state tracking, handles branching choices, and applies effects via
## EventBus (relationship/trust/item) or directly to GameStore (flags).
##
## No class_name — autoload rule (ADR-0006). Tests preload this file.
## Stateless between sequences: no dialogue state persists after end_dialogue().
##
## Boot order: Autoload #9. May reference autoloads 1-8 in _ready().
##
## See: docs/architecture/adr-0008-dialogue.md

# ── State Machine ─────────────────────────────────────────────────────────────

enum State {
	IDLE,
	LOADING,
	DISPLAYING,
	WAITING,
	CHOOSING,
	RESOLVING,
	BLOCKED,
	ENDED,
}

# ── Constants ─────────────────────────────────────────────────────────────────

const DEFAULT_CPS: float = 40.0
const MAX_TEXT_LENGTH: int = 280
const MIN_PAUSE_DURATION: float = 0.1
const MAX_PAUSE_DURATION: float = 3.0
const CONFIG_PATH: String = "res://assets/data/config/dialogue_config.json"

# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted when a sequence begins (gates passed, first node entered).
signal dialogue_started(sequence_id: String)

## Emitted when a sequence ends normally (end node reached or force_end called).
signal dialogue_ended(sequence_id: String)

## Emitted when a sequence cannot start because a prerequisite gate failed.
signal dialogue_blocked(sequence_id: String, reason: String)

## Emitted when a new dialogue line is ready for display.
## line_data keys: speaker, speaker_type, text_key, mood, text_params (optional).
signal line_ready(line_data: Dictionary)

## Emitted when a node transitions to choice presentation.
## choices is Array of choice Dictionaries.
signal choices_ready(choices: Array)

## Emitted when the typewriter animation completes for the current line.
signal typewriter_complete

# ── Export / Config ───────────────────────────────────────────────────────────

## Characters per second for typewriter animation.
## Loaded from dialogue_config.json at _ready(). Never hardcoded.
var cps: float = DEFAULT_CPS

# ── Private State ─────────────────────────────────────────────────────────────

var _state: State = State.IDLE
var _sequence_id: String = ""
var _chapter_id: String = ""
var _nodes: Dictionary = {}
var _current_node_id: String = ""
var _current_line_index: int = 0
var _current_lines: Array = []
var _current_choices: Array = []

## True once the typewriter animation has completed for the current line.
var _typewriter_complete: bool = true

# ── Built-in Virtual Methods ──────────────────────────────────────────────────

func _ready() -> void:
	_load_config()

# ── Public API ────────────────────────────────────────────────────────────────

## Loads the dialogue JSON for [param chapter_id]/[param sequence_id],
## evaluates root-level gates, and begins playback from the "start" node.
##
## Returns true if the sequence was successfully started.
## Returns false if already active, the file is missing, or a gate fails.
## On gate failure emits both the local [signal dialogue_blocked] and
## [signal EventBus.dialogue_blocked].
func start_dialogue(chapter_id: String, sequence_id: String) -> bool:
	if _state != State.IDLE and _state != State.ENDED:
		push_warning(
			"[DialogueRunner] start_dialogue(%s) rejected — runner is in state %s." \
			% [sequence_id, State.keys()[_state]]
		)
		return false

	_state = State.LOADING
	_chapter_id = chapter_id
	_sequence_id = sequence_id

	var path: String = "res://assets/data/dialogue/%s/%s.json" % [chapter_id, sequence_id]

	if not FileAccess.file_exists(path):
		_emit_blocked(sequence_id, "file_not_found")
		return false

	var data: Dictionary = _load_json(path)
	if data.is_empty():
		_emit_blocked(sequence_id, "file_not_found")
		return false

	var nodes: Dictionary = data.get("nodes", {})
	if not nodes.has("start"):
		_emit_blocked(sequence_id, "missing_start_node")
		return false

	# Evaluate root-level gates
	var gate_result: String = _check_gates(data)
	if not gate_result.is_empty():
		_emit_blocked(sequence_id, gate_result)
		return false

	_nodes = nodes
	_current_node_id = "start"
	_state = State.DISPLAYING
	_enter_node("start")
	dialogue_started.emit(sequence_id)
	return true

## Advances dialogue: completes typewriter if in progress, otherwise moves
## to the next line or node. Call this on player tap/advance input.
func advance() -> void:
	if _state == State.DISPLAYING:
		# Tap-to-complete: consume tap, complete typewriter animation.
		if not _typewriter_complete:
			complete_typewriter()
			return
		# Typewriter already complete — advance to next line or node.
		_advance_line()
		return
	if _state == State.WAITING:
		_advance_line()

## Selects a choice by index. Only valid in CHOOSING state.
func select_choice(index: int) -> void:
	if _state != State.CHOOSING:
		return
	if index < 0 or index >= _current_choices.size():
		return
	_state = State.RESOLVING
	var choice: Dictionary = _current_choices[index]
	if choice.has("effects"):
		_apply_effects(choice["effects"])
	var next_id: String = choice.get("next", "")
	if next_id.is_empty():
		end_dialogue()
	else:
		_current_node_id = next_id
		_enter_node(next_id)

## Marks the typewriter animation complete for the current line.
## Called by the UI layer when visible_characters reaches the target.
## Also called internally by advance() on first tap during animation.
func complete_typewriter() -> void:
	_typewriter_complete = true
	typewriter_complete.emit()

## Ends the active dialogue sequence, resets state to IDLE, and emits
## [signal EventBus.dialogue_ended]. Safe to call at any time.
func end_dialogue() -> void:
	var id: String = _sequence_id
	_reset_state()
	dialogue_ended.emit(id)
	EventBus.dialogue_ended.emit(id)

## Forces the active sequence to end immediately, discarding any in-flight
## effects. Emits dialogue_ended normally. (ADR-0008 AC6 STORY-007)
func force_end() -> void:
	end_dialogue()

## Returns true when a dialogue sequence is currently active.
func is_active() -> bool:
	return _state != State.IDLE and _state != State.ENDED and _state != State.BLOCKED

## Returns the current state enum value.
func get_state() -> State:
	return _state

# ── Text Utilities ────────────────────────────────────────────────────────────

## Strips {pause:N} markers from [param raw_text] and returns clean display text.
## Pause markers are extracted separately for the UI layer via extract_pauses().
func strip_pause_markers(raw_text: String) -> String:
	var result: String = raw_text
	var regex := RegEx.new()
	regex.compile("\\{pause:[0-9]*\\.?[0-9]+\\}")
	result = regex.sub(result, "", true)
	return result

## Extracts {pause:N} marker values from [param raw_text] as an Array[float].
## Values are clamped to [MIN_PAUSE_DURATION, MAX_PAUSE_DURATION].
## Out-of-range values are clamped and a content warning is logged.
func extract_pauses(raw_text: String) -> Array[float]:
	var pauses: Array[float] = []
	var regex := RegEx.new()
	regex.compile("\\{pause:([0-9]*\\.?[0-9]+)\\}")
	for result: RegExMatch in regex.search_all(raw_text):
		var raw_value: float = float(result.get_string(1))
		var clamped: float = clampf(raw_value, MIN_PAUSE_DURATION, MAX_PAUSE_DURATION)
		if not is_equal_approx(raw_value, clamped):
			push_warning(
				"[DialogueRunner] {pause:%s} out of range [%s, %s] — clamped to %s." \
				% [raw_value, MIN_PAUSE_DURATION, MAX_PAUSE_DURATION, clamped]
			)
		pauses.append(clamped)
	return pauses

## Truncates [param text] to at most [MAX_TEXT_LENGTH] characters at a word
## boundary and appends "[...]". Logs a content warning if truncation occurs.
func truncate_text(text: String) -> String:
	if text.length() <= MAX_TEXT_LENGTH:
		return text
	push_warning(
		"[DialogueRunner] Text length %d exceeds limit %d — truncating." \
		% [text.length(), MAX_TEXT_LENGTH]
	)
	var truncated: String = text.substr(0, MAX_TEXT_LENGTH)
	var last_space: int = truncated.rfind(" ")
	if last_space > 0:
		truncated = truncated.substr(0, last_space)
	return truncated + "[...]"

# ── Private — Navigation ──────────────────────────────────────────────────────

func _enter_node(node_id: String) -> void:
	if not _nodes.has(node_id):
		end_dialogue()
		return

	var node: Dictionary = _nodes[node_id]
	_current_lines = node.get("lines", [])
	# Filter choices through condition evaluation at render time (STORY-DIALOGUE-005).
	_current_choices = _filter_choices(node.get("choices", []))
	_current_line_index = 0

	# Warn if both choices and next are populated (AC9 STORY-001).
	if _current_choices.size() > 0 and node.has("next"):
		push_warning(
			"[DialogueRunner] Node '%s' has both choices and next — choices take priority." \
			% node_id
		)

	if node_id == "END":
		end_dialogue()
		return

	if _current_lines.size() > 0:
		_emit_line(_current_lines[0])
	elif _current_choices.size() > 0:
		_state = State.CHOOSING
		choices_ready.emit(_current_choices)
	else:
		# Empty node — follow next link or end.
		var next_id: String = node.get("next", "")
		if next_id.is_empty():
			end_dialogue()
		else:
			_current_node_id = next_id
			_enter_node(next_id)

func _advance_line() -> void:
	_current_line_index += 1
	if _current_line_index < _current_lines.size():
		_emit_line(_current_lines[_current_line_index])
	elif _current_choices.size() > 0:
		_state = State.CHOOSING
		# Re-emit the already-filtered list (filtered in _enter_node).
		choices_ready.emit(_current_choices)
	else:
		var next_id: String = _nodes.get(_current_node_id, {}).get("next", "")
		if next_id.is_empty() or next_id == "END":
			end_dialogue()
		else:
			_current_node_id = next_id
			_enter_node(next_id)

func _emit_line(line_data: Dictionary) -> void:
	_state = State.DISPLAYING
	_typewriter_complete = false
	line_ready.emit(line_data)

# ── Private — Effect Application ──────────────────────────────────────────────

## Applies an array of effects in order (AC7 STORY-006).
## relationship/trust/item_grant → emitted via EventBus (fire-and-forget).
## flag_set/flag_clear → written directly to GameStore (Foundation layer, allowed).
## mood_set → emits local signal for UI layer to handle portrait update.
## Unknown types → skipped with warning (AC8 STORY-006).
func _apply_effects(effects: Array) -> void:
	for effect: Variant in effects:
		if effect is not Dictionary:
			push_warning("[DialogueRunner] Effect entry is not a Dictionary — skipping.")
			continue
		var fx: Dictionary = effect as Dictionary
		match fx.get("type", ""):
			"relationship":
				var companion_id: String = fx.get("companion", "")
				var delta: int = fx.get("delta", 0)
				EventBus.relationship_changed.emit(companion_id, delta)
			"trust":
				var companion_id: String = fx.get("companion", "")
				var delta: int = fx.get("delta", 0)
				EventBus.trust_changed.emit(companion_id, delta)
			"flag_set":
				var flag: String = fx.get("flag", "")
				if not flag.is_empty():
					GameStore.set_flag(flag)
			"flag_clear":
				var flag: String = fx.get("flag", "")
				if not flag.is_empty():
					# GameStore.set_flag is write-once/idempotent append.
					# flag_clear removes the flag from _story_flags via clear_flag().
					GameStore.clear_flag(flag)
			"item_grant":
				var item_id: String = fx.get("item_id", "")
				var quantity: int = fx.get("quantity", 1)
				EventBus.item_granted.emit(item_id, quantity)
			"mood_set":
				var companion_id: String = fx.get("companion", "")
				var mood: String = fx.get("mood", "neutral")
				# Signal the UI layer directly — portrait update before next node.
				line_ready.emit({
					"type": "mood_set",
					"companion": companion_id,
					"mood": mood,
				})
			_:
				push_warning(
					"[DialogueRunner] Unknown effect type '%s' — skipping." \
					% fx.get("type", "")
				)

# ── Private — Choice Condition Filtering (STORY-DIALOGUE-005) ────────────────

## Filters [param choices] to only those whose conditions all pass at render time.
## Insight-tier choices with failing conditions are completely removed (no "locked" UI).
## All-fail result: returns empty array; caller (see _enter_node / _advance_line)
## handles the all-fail case (AC6 STORY-004 — log warning + emit dialogue_ended).
## A choice with no "conditions" field always passes (AC9 STORY-005).
func _filter_choices(choices: Array) -> Array:
	var result: Array = []
	for choice: Variant in choices:
		if choice is not Dictionary:
			continue
		var cond_list: Array = (choice as Dictionary).get("conditions", [])
		if _check_conditions(cond_list):
			result.append(choice)
	if result.is_empty() and choices.size() > 0:
		push_warning(
			"[DialogueRunner] All choices on node '%s' failed conditions — ending dialogue." \
			% _current_node_id
		)
		end_dialogue()
	return result

## Returns true if every condition in [param conditions] passes, false on first failure.
## Supported condition types (ADR-0008, STORY-DIALOGUE-005 AC1–AC9):
##   romance_stage  — companion romance stage >= min
##   met            — companion has met == true in GameStore
##   flag_set       — flag exists in GameStore story flags
##   flag_not_set   — flag does NOT exist in GameStore story flags
##   trust_min      — companion trust >= value (read from GameStore companion state)
## Unknown condition types log a warning and are treated as passing (permissive default).
func _check_conditions(conditions: Array) -> bool:
	for cond: Variant in conditions:
		if cond is not Dictionary:
			continue
		var c: Dictionary = cond as Dictionary
		match c.get("type", ""):
			"romance_stage":
				var companion_id: String = c.get("companion", "")
				var min_stage: int = c.get("min", 0)
				if _CompanionStateScript.get_romance_stage(companion_id) < min_stage:
					return false
			"met":
				var companion_id: String = c.get("companion", "")
				var state: Dictionary = GameStore.get_companion_state(companion_id)
				if not state.get("met", false):
					return false
			"flag_set":
				var flag: String = c.get("flag", "")
				if not flag.is_empty() and not GameStore.has_flag(flag):
					return false
			"flag_not_set":
				var flag: String = c.get("flag", "")
				if not flag.is_empty() and GameStore.has_flag(flag):
					return false
			"trust_min":
				var companion_id: String = c.get("companion", "")
				var min_trust: int = c.get("value", 0)
				var state: Dictionary = GameStore.get_companion_state(companion_id)
				var trust: int = state.get("trust", 0)
				if trust < min_trust:
					return false
			_:
				push_warning(
					"[DialogueRunner] Unknown condition type '%s' — treating as passing." \
					% c.get("type", "")
				)
	return true

# ── Private — Gate Checks ─────────────────────────────────────────────────────

## Checks all root-level prerequisite gates in [param data].
## Returns an empty String if all gates pass.
## Returns the gate reason string on first failure.
func _check_gates(data: Dictionary) -> String:
	# requires_met: companion must have met == true in GameStore.
	var requires_met: String = data.get("requires_met", "")
	if not requires_met.is_empty():
		var state: Dictionary = GameStore.get_companion_state(requires_met)
		if state.is_empty() or not state.get("met", false):
			return "requires_met"

	# requires_romance_stage: companion must be at or above min stage.
	var req_stage: Variant = data.get("requires_romance_stage", null)
	if req_stage != null and req_stage is Dictionary:
		var companion_id: String = (req_stage as Dictionary).get("companion", "")
		var min_stage: int = (req_stage as Dictionary).get("min", 0)
		if _CompanionStateScript.get_romance_stage(companion_id) < min_stage:
			return "requires_romance_stage"

	# requires_flag: story flag must be set in GameStore.
	var required_flag: String = data.get("requires_flag", "")
	if not required_flag.is_empty():
		if not GameStore.has_flag(required_flag):
			return "requires_flag"

	return ""

# ── Private — Helpers ─────────────────────────────────────────────────────────

func _emit_blocked(sequence_id: String, reason: String) -> void:
	_reset_state()
	push_warning("[DialogueRunner] dialogue_blocked(%s): %s" % [sequence_id, reason])
	dialogue_blocked.emit(sequence_id, reason)
	EventBus.dialogue_blocked.emit(sequence_id, reason)

func _reset_state() -> void:
	_state = State.IDLE
	_sequence_id = ""
	_chapter_id = ""
	_nodes.clear()
	_current_lines.clear()
	_current_choices.clear()
	_current_node_id = ""
	_current_line_index = 0
	_typewriter_complete = true

func _load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("[DialogueRunner] JSON parse error in '%s': %s" % [path, json.get_error_message()])
		return {}
	if json.data is not Dictionary:
		return {}
	return json.data as Dictionary

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("[DialogueRunner] Config not found at '%s' — using defaults." % CONFIG_PATH)
		return
	var data: Dictionary = _load_json(CONFIG_PATH)
	if data.has("cps"):
		cps = float(data["cps"])
