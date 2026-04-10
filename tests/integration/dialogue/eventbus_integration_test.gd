class_name EventBusIntegrationTest
extends GdUnitTestSuite

## Integration tests for STORY-DIALOGUE-007: EventBus Signal Integration
##
## Covers:
##   AC1 — end_dialogue() emits EventBus.dialogue_ended with correct sequence_id
##   AC2 — dialogue_blocked propagates to EventBus.dialogue_blocked
##   AC3 — relationship effect from choice propagates through EventBus.relationship_changed

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child_autofree(runner)
	return runner

# ── AC1 — end_dialogue emits EventBus.dialogue_ended ─────────────────────────

func test_eventbus_integration_end_dialogue_emits_eventbus_dialogue_ended() -> void:
	# Arrange
	var runner = _make_runner()
	var ended_ids: Array = []
	EventBus.dialogue_ended.connect(func(id: String) -> void: ended_ids.append(id))
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Act
	runner.end_dialogue()

	# Assert
	assert_int(ended_ids.size()).is_equal(1)
	assert_str(ended_ids[0]).is_equal(FIXTURE_SEQ)

	EventBus.dialogue_ended.disconnect_all()

# ── AC2 — gate failure propagates to EventBus.dialogue_blocked ───────────────

func test_eventbus_integration_blocked_emits_eventbus_dialogue_blocked() -> void:
	# Arrange
	var runner = _make_runner()
	var blocked_events: Array = []
	EventBus.dialogue_blocked.connect(
		func(seq_id: String, reason: String) -> void:
			blocked_events.append({"seq": seq_id, "reason": reason})
	)

	# Act — missing file triggers blocked
	runner.start_dialogue("test", "nonexistent_sequence_xyz")

	# Assert
	assert_int(blocked_events.size()).is_equal(1)
	assert_str(blocked_events[0]["reason"]).is_equal("file_not_found")

	EventBus.dialogue_blocked.disconnect_all()

# ── AC3 — relationship effect propagates through EventBus ────────────────────

func test_eventbus_integration_relationship_effect_reaches_eventbus() -> void:
	# Arrange
	var runner = _make_runner()
	var rel_events: Array = []
	EventBus.relationship_changed.connect(
		func(companion: String, delta: int) -> void:
			rel_events.append({"companion": companion, "delta": delta})
	)

	# Navigate to choices and select choice A (relationship +5 on artemis)
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	runner.select_choice(0)

	# Assert — EventBus received the relationship_changed signal
	assert_int(rel_events.size()).is_equal(1)
	assert_str(rel_events[0]["companion"]).is_equal("artemis")
	assert_int(rel_events[0]["delta"]).is_equal(5)

	EventBus.relationship_changed.disconnect_all()
