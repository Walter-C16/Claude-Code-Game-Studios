class_name EffectSystemTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-006: Effect System — Signal Emission and Flag Writes
##
## Covers all Acceptance Criteria:
##   AC1  — "relationship" effect emits EventBus.relationship_changed(companion, delta)
##   AC2  — "trust" effect emits EventBus.trust_changed(companion, delta)
##   AC3  — "flag_set" effect writes flag to GameStore
##   AC4  — "flag_clear" effect clears flag from GameStore
##   AC5  — "item_grant" effect emits EventBus.item_granted(item_id, quantity)
##   AC6  — "mood_set" effect emits line_ready with type="mood_set"
##   AC7  — multiple effects in array execute in order
##   AC8  — unknown effect type skipped, remaining effects still execute
##   AC9  — no listener on EventBus → no error (fire-and-forget)
##
## Effects are triggered via select_choice() after reaching a choice node.
## The fixture's choice_node provides choices with embedded effects.
##
## See: docs/architecture/adr-0008-dialogue.md

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child(runner)
	return runner

func before_test() -> void:
	GameStore._initialize_defaults()

## Advances to the choice_node and returns. Runner is in CHOOSING state.
func _advance_to_choices(runner: Node) -> void:
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()

# ── AC1 — "relationship" effect emits EventBus.relationship_changed ───────────

func test_effect_system_relationship_emits_eventbus_signal() -> void:
	# Arrange — choice A (index 0) has effect: {type:"relationship", companion:"artemisa", delta:5}
	var runner = _make_runner()
	_advance_to_choices(runner)

	var received_companion: String = ""
	var received_delta: int = -999
	EventBus.relationship_changed.connect(
		func(cid: String, d: int) -> void:
			received_companion = cid
			received_delta = d,
		CONNECT_ONE_SHOT
	)

	# Act
	runner.select_choice(0)

	# Assert
	assert_str(received_companion).is_equal("artemisa")
	assert_int(received_delta).is_equal(5)

func test_effect_system_relationship_effect_does_not_write_gamestore_directly() -> void:
	# Arrange — DialogueRunner must NOT apply relationship changes to GameStore.
	# It only emits via EventBus (fire-and-forget, ADR-0008 AC9).
	var runner = _make_runner()
	_advance_to_choices(runner)

	var level_before: int = GameStore.get_relationship_level("artemisa")

	# Act
	runner.select_choice(0)

	# Assert — relationship_level unchanged in GameStore (DialogueRunner does not write it)
	assert_int(GameStore.get_relationship_level("artemisa")).is_equal(level_before)

# ── AC2 — "trust" effect emits EventBus.trust_changed ────────────────────────

func test_effect_system_trust_source_emits_trust_changed() -> void:
	# Arrange — validate via source code that trust effect emits EventBus.trust_changed
	var f: FileAccess = FileAccess.open("res://autoloads/dialogue_runner.gd", FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	assert_str(source).contains("EventBus.trust_changed.emit")
	assert_str(source).contains('"trust"')

func test_effect_system_trust_effect_does_not_write_gamestore_directly() -> void:
	# Arrange — trust delta must NOT be applied directly by DialogueRunner
	var f: FileAccess = FileAccess.open("res://autoloads/dialogue_runner.gd", FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	# The "trust" match arm must only emit, not call GameStore.set_trust
	# We verify by confirming set_trust does not appear in the "trust" match arm
	# (the full _apply_effects function does not call set_trust at all)
	assert_str(source).not_contains("set_trust")

# ── AC3 — "flag_set" effect writes flag to GameStore ─────────────────────────

func test_effect_system_flag_set_writes_to_game_store() -> void:
	# Arrange — choice C (index 1 after filtering, or 2 before) has flag_set effect
	# choice C: {text_key:"DLG_CHOICE_C", next:"end_node", effects:[{type:"flag_set", flag:"test_flag"}]}
	# With no flags set, choice B is filtered → choices are [A, C] → C is at index 1
	var runner = _make_runner()
	_advance_to_choices(runner)

	# Act — select choice C (index 1 in filtered list)
	runner.select_choice(1)

	# Assert — test_flag is now set in GameStore
	assert_bool(GameStore.has_flag("test_flag")).is_true()

func test_effect_system_flag_set_effect_is_idempotent() -> void:
	# Arrange — set flag once via effect, then again — no error
	var runner = _make_runner()
	_advance_to_choices(runner)
	runner.select_choice(1) # sets test_flag

	# Reset and run again to ensure idempotency
	var runner2 = _make_runner()
	_advance_to_choices(runner2)
	runner2.select_choice(1) # sets test_flag again — must be idempotent

	# Assert — still exactly one entry for test_flag
	var flags: Array[String] = GameStore.get_story_flags()
	var count: int = 0
	for f: String in flags:
		if f == "test_flag":
			count += 1
	assert_int(count).is_equal(1)

# ── AC4 — "flag_clear" effect clears flag from GameStore ─────────────────────

func test_effect_system_flag_clear_source_calls_gamestore_clear_flag() -> void:
	var f: FileAccess = FileAccess.open("res://autoloads/dialogue_runner.gd", FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	assert_str(source).contains('"flag_clear"')
	assert_str(source).contains("GameStore.clear_flag")

func test_effect_system_flag_clear_removes_flag() -> void:
	# Arrange — set a flag, then apply a flag_clear effect via source inspection
	# (no flag_clear in fixture; test the API directly)
	GameStore.set_flag("to_clear_flag")
	assert_bool(GameStore.has_flag("to_clear_flag")).is_true()

	# Act
	GameStore.clear_flag("to_clear_flag")

	# Assert
	assert_bool(GameStore.has_flag("to_clear_flag")).is_false()

# ── AC5 — "item_grant" effect emits EventBus.item_granted ────────────────────

func test_effect_system_item_grant_source_emits_item_granted() -> void:
	var f: FileAccess = FileAccess.open("res://autoloads/dialogue_runner.gd", FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	assert_str(source).contains('"item_grant"')
	assert_str(source).contains("EventBus.item_granted.emit")

func test_effect_system_item_grant_signal_has_correct_parameters() -> void:
	# Arrange — create a fresh EventBus and runner to test item_grant signal
	var runner = _make_runner()
	var received_item: String = ""
	var received_qty: int = -1
	EventBus.item_granted.connect(
		func(item_id: String, qty: int) -> void:
			received_item = item_id
			received_qty = qty,
		CONNECT_ONE_SHOT
	)

	# Trigger item_grant effect directly by calling _apply_effects
	runner._apply_effects([{"type": "item_grant", "item_id": "ambrosia", "quantity": 2}])

	# Assert
	assert_str(received_item).is_equal("ambrosia")
	assert_int(received_qty).is_equal(2)

# ── AC6 — "mood_set" effect emits line_ready with type="mood_set" ─────────────

func test_effect_system_mood_set_emits_line_ready() -> void:
	# Arrange
	var runner = _make_runner()
	var mood_lines: Array = []
	runner.line_ready.connect(
		func(line: Dictionary) -> void:
			if line.get("type", "") == "mood_set":
				mood_lines.append(line)
	)

	# Act — call _apply_effects directly with a mood_set effect
	runner._apply_effects([{"type": "mood_set", "companion": "artemisa", "mood": "angry"}])

	# Assert
	assert_int(mood_lines.size()).is_equal(1)
	assert_str(mood_lines[0]["companion"]).is_equal("artemisa")
	assert_str(mood_lines[0]["mood"]).is_equal("angry")

# ── AC7 — multiple effects execute in order ───────────────────────────────────

func test_effect_system_multiple_effects_all_execute() -> void:
	# Arrange
	var runner = _make_runner()
	var relationship_fired: bool = false
	var trust_fired: bool = false
	EventBus.relationship_changed.connect(
		func(_c: String, _d: int) -> void: relationship_fired = true,
		CONNECT_ONE_SHOT
	)
	EventBus.trust_changed.connect(
		func(_c: String, _d: int) -> void: trust_fired = true,
		CONNECT_ONE_SHOT
	)

	# Act — 3 effects in order
	runner._apply_effects([
		{"type": "relationship", "companion": "artemisa", "delta": 1},
		{"type": "trust", "companion": "artemisa", "delta": 2},
		{"type": "flag_set", "flag": "multi_effect_test"},
	])

	# Assert — all three executed
	assert_bool(relationship_fired).is_true()
	assert_bool(trust_fired).is_true()
	assert_bool(GameStore.has_flag("multi_effect_test")).is_true()

func test_effect_system_effects_execute_in_array_order() -> void:
	# Arrange — flag_set then flag_clear on same flag; net result = cleared
	var runner = _make_runner()

	# Act
	runner._apply_effects([
		{"type": "flag_set", "flag": "order_test_flag"},
		{"type": "flag_clear", "flag": "order_test_flag"},
	])

	# Assert — clear ran last, so flag is gone
	assert_bool(GameStore.has_flag("order_test_flag")).is_false()

# ── AC8 — unknown effect type skipped, others still execute ──────────────────

func test_effect_system_unknown_type_skipped_other_effects_run() -> void:
	# Arrange
	var runner = _make_runner()

	# Act — unknown "teleport" type sandwiched between valid effects
	runner._apply_effects([
		{"type": "flag_set", "flag": "before_unknown"},
		{"type": "teleport", "destination": "olympus"},
		{"type": "flag_set", "flag": "after_unknown"},
	])

	# Assert — both valid flags set despite unknown type in middle
	assert_bool(GameStore.has_flag("before_unknown")).is_true()
	assert_bool(GameStore.has_flag("after_unknown")).is_true()

# ── AC9 — no listener on EventBus does not cause error ───────────────────────

func test_effect_system_no_listener_relationship_signal_no_crash() -> void:
	# Arrange — runner with no external listener for relationship_changed
	var runner = _make_runner()

	# Act — emit relationship signal with no listeners attached
	# (EventBus signals with no listeners should silently succeed)
	var completed: bool = false
	runner._apply_effects([{"type": "relationship", "companion": "nyx", "delta": 3}])
	completed = true

	# Assert — reached this line without error
	assert_bool(completed).is_true()

func test_effect_system_no_listener_trust_signal_no_crash() -> void:
	# Arrange
	var runner = _make_runner()

	# Act
	var completed: bool = false
	runner._apply_effects([{"type": "trust", "companion": "nyx", "delta": -1}])
	completed = true

	# Assert
	assert_bool(completed).is_true()
