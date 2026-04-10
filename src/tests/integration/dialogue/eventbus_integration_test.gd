class_name EventBusIntegrationTest
extends GdUnitTestSuite

## Integration tests for STORY-DIALOGUE-007: Sequence End and EventBus Signal Integration
##
## Covers:
##   AC1  — end node reached → EventBus.dialogue_ended emitted, runner returns to Idle
##   AC2  — gate fails during Loading → EventBus.dialogue_blocked emitted, state = Idle
##   AC4  — mock StoryFlow listener connected to EventBus.dialogue_ended receives signal
##   AC5  — after Ended state, start_dialogue for new sequence accepted
##   AC6  — force_end() emits dialogue_ended, runner returns to Idle
##   AC7  — after end, no dialogue session state persists (stateless between sequences)
##
## See: docs/architecture/adr-0008-dialogue.md

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

const STATE_IDLE: int = 0
const STATE_ENDED: int = 7

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child(runner)
	return runner

func before_test() -> void:
	GameStore._initialize_defaults()

## Runs the fixture sequence to completion by selecting choice A then advancing
## through the end_node line until the sequence ends.
func _run_to_completion(runner: Node) -> void:
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance() # → choices_ready
	runner.select_choice(0) # choice A → end_node
	runner.complete_typewriter()
	runner.advance() # advance past end_node line → end_dialogue()

# ── AC1 — end node → EventBus.dialogue_ended emitted ────────────────────────

func test_eventbus_integration_dialogue_ended_emits_local_signal() -> void:
	# Arrange
	var runner = _make_runner()
	var local_ended: Array = []
	runner.dialogue_ended.connect(func(id: String) -> void: local_ended.append(id))

	# Act
	_run_to_completion(runner)

	# Assert — local signal on runner
	assert_int(local_ended.size()).is_equal(1)
	assert_str(local_ended[0]).is_equal(FIXTURE_SEQ)

func test_eventbus_integration_dialogue_ended_emits_eventbus_signal() -> void:
	# Arrange
	var runner = _make_runner()
	var bus_ended: Array = []
	EventBus.dialogue_ended.connect(
		func(id: String) -> void: bus_ended.append(id),
		CONNECT_ONE_SHOT
	)

	# Act
	_run_to_completion(runner)

	# Assert — EventBus signal fired
	assert_int(bus_ended.size()).is_equal(1)
	assert_str(bus_ended[0]).is_equal(FIXTURE_SEQ)

func test_eventbus_integration_dialogue_ended_sequence_id_correct() -> void:
	# Arrange
	var runner = _make_runner()
	var received_id: String = ""
	EventBus.dialogue_ended.connect(
		func(id: String) -> void: received_id = id,
		CONNECT_ONE_SHOT
	)

	# Act
	_run_to_completion(runner)

	# Assert
	assert_str(received_id).is_equal(FIXTURE_SEQ)

func test_eventbus_integration_runner_returns_to_idle_after_end() -> void:
	# Arrange
	var runner = _make_runner()

	# Act
	_run_to_completion(runner)

	# Assert — IDLE = 0
	assert_int(runner.get_state()).is_equal(STATE_IDLE)

# ── AC2 — gate fails → EventBus.dialogue_blocked emitted ─────────────────────

func test_eventbus_integration_missing_file_emits_eventbus_blocked() -> void:
	# Arrange
	var runner = _make_runner()
	var bus_blocked: Array = []
	EventBus.dialogue_blocked.connect(
		func(id: String, reason: String) -> void: bus_blocked.append({"id": id, "reason": reason}),
		CONNECT_ONE_SHOT
	)

	# Act
	runner.start_dialogue("test", "nonexistent_xyz")

	# Assert — EventBus.dialogue_blocked fired
	assert_int(bus_blocked.size()).is_equal(1)
	assert_str(bus_blocked[0]["reason"]).is_equal("file_not_found")

func test_eventbus_integration_gate_fail_state_returns_to_idle() -> void:
	# Arrange
	var runner = _make_runner()

	# Act
	runner.start_dialogue("test", "nonexistent_xyz")

	# Assert
	assert_int(runner.get_state()).is_equal(STATE_IDLE)

# ── AC4 — mock StoryFlow listener receives dialogue_ended ────────────────────

func test_eventbus_integration_mock_story_flow_receives_ended_signal() -> void:
	# Arrange — mock StoryFlow: connects to EventBus.dialogue_ended
	var story_flow_received: Array = []
	var mock_story_flow_handler: Callable = func(id: String) -> void:
		story_flow_received.append(id)
	EventBus.dialogue_ended.connect(mock_story_flow_handler, CONNECT_ONE_SHOT)

	var runner = _make_runner()

	# Act
	_run_to_completion(runner)

	# Assert
	assert_int(story_flow_received.size()).is_equal(1)
	assert_str(story_flow_received[0]).is_equal(FIXTURE_SEQ)

func test_eventbus_integration_mock_story_flow_receives_correct_sequence_id() -> void:
	# Arrange
	var received_id: String = ""
	EventBus.dialogue_ended.connect(
		func(id: String) -> void: received_id = id,
		CONNECT_ONE_SHOT
	)

	var runner = _make_runner()

	# Act
	_run_to_completion(runner)

	# Assert
	assert_str(received_id).is_equal(FIXTURE_SEQ)

# ── AC5 — after Ended state, new sequence accepted ────────────────────────────

func test_eventbus_integration_ended_state_accepts_new_sequence() -> void:
	# Arrange — complete one sequence
	var runner = _make_runner()
	_run_to_completion(runner)

	# Act — immediately start a new sequence
	var result: bool = runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Assert
	assert_bool(result).is_true()

func test_eventbus_integration_second_sequence_emits_dialogue_started() -> void:
	# Arrange
	var runner = _make_runner()
	_run_to_completion(runner)

	var started_ids: Array = []
	runner.dialogue_started.connect(func(id: String) -> void: started_ids.append(id))

	# Act
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Assert — started signal fires for second sequence
	assert_int(started_ids.size()).is_equal(1)

# ── AC6 — force_end() emits dialogue_ended ───────────────────────────────────

func test_eventbus_integration_force_end_emits_local_dialogue_ended() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	var local_ended: Array = []
	runner.dialogue_ended.connect(func(id: String) -> void: local_ended.append(id))

	# Act
	runner.force_end()

	# Assert
	assert_int(local_ended.size()).is_equal(1)

func test_eventbus_integration_force_end_emits_eventbus_dialogue_ended() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	var bus_ended: Array = []
	EventBus.dialogue_ended.connect(
		func(id: String) -> void: bus_ended.append(id),
		CONNECT_ONE_SHOT
	)

	# Act
	runner.force_end()

	# Assert
	assert_int(bus_ended.size()).is_equal(1)

func test_eventbus_integration_force_end_returns_runner_to_idle() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Act
	runner.force_end()

	# Assert
	assert_int(runner.get_state()).is_equal(STATE_IDLE)

# ── AC7 — no session state persists after end ─────────────────────────────────

func test_eventbus_integration_no_sequence_id_persists_after_end() -> void:
	# Arrange
	var runner = _make_runner()
	_run_to_completion(runner)

	# Assert — _sequence_id cleared
	assert_str(runner._sequence_id).is_equal("")

func test_eventbus_integration_no_nodes_persist_after_end() -> void:
	# Arrange
	var runner = _make_runner()
	_run_to_completion(runner)

	# Assert — _nodes cleared
	assert_bool(runner._nodes.is_empty()).is_true()

func test_eventbus_integration_no_current_node_id_persists_after_end() -> void:
	# Arrange
	var runner = _make_runner()
	_run_to_completion(runner)

	# Assert — _current_node_id cleared
	assert_str(runner._current_node_id).is_equal("")

func test_eventbus_integration_is_active_returns_false_after_end() -> void:
	# Arrange
	var runner = _make_runner()
	_run_to_completion(runner)

	# Assert
	assert_bool(runner.is_active()).is_false()

# ── Local + EventBus both fire on same end_dialogue call ──────────────────────

func test_eventbus_integration_both_signals_fire_on_end_dialogue() -> void:
	# Arrange
	var runner = _make_runner()
	var local_count: int = 0
	var bus_count: int = 0
	runner.dialogue_ended.connect(func(_id: String) -> void: local_count += 1)
	EventBus.dialogue_ended.connect(
		func(_id: String) -> void: bus_count += 1,
		CONNECT_ONE_SHOT
	)

	# Act
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.end_dialogue()

	# Assert — both signals fire exactly once per end_dialogue call
	assert_int(local_count).is_equal(1)
	assert_int(bus_count).is_equal(1)
