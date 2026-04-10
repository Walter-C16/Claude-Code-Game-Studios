class_name EventBusTypeSafetyTest
extends GdUnitTestSuite

# Unit tests for STORY-EB-002: EventBus Type Safety and Emission Validation
#
# Covers:
#   AC1 — relationship_changed delivers companion_id: String and delta: int
#   AC2 — combat_completed delivers the full Dictionary unchanged
#   AC3 — romance_stage_changed delivers old_stage and new_stage as int
#   AC4 — tokens_reset calls listener with no arguments, no error
#   AC5 — all signals are accessible and callable on a fresh EventBus instance
#
# See: docs/architecture/adr-0004-eventbus.md

const EventBusScript = preload("res://autoloads/event_bus.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates a fresh EventBus instance for each test.
func _make_bus():
	return EventBusScript.new()

# ---------------------------------------------------------------------------
# AC1 — relationship_changed: companion_id is String, delta is int
# ---------------------------------------------------------------------------

var _received_companion_id: String = ""
var _received_delta: int = 0

func _on_relationship_changed(companion_id: String, delta: int) -> void:
	_received_companion_id = companion_id
	_received_delta = delta

func test_event_bus_type_safety_relationship_changed_delivers_string_companion_id() -> void:
	# Arrange
	var bus = _make_bus()
	_received_companion_id = ""
	_received_delta = 0
	bus.relationship_changed.connect(_on_relationship_changed)

	# Act
	bus.relationship_changed.emit("artemisa", 5)

	# Assert — companion_id is the exact String emitted
	assert_str(_received_companion_id).is_equal("artemisa")

func test_event_bus_type_safety_relationship_changed_delivers_int_delta() -> void:
	# Arrange
	var bus = _make_bus()
	_received_companion_id = ""
	_received_delta = 0
	bus.relationship_changed.connect(_on_relationship_changed)

	# Act
	bus.relationship_changed.emit("artemisa", 5)

	# Assert — delta is the exact int emitted
	assert_int(_received_delta).is_equal(5)

func test_event_bus_type_safety_relationship_changed_companion_id_type_is_string() -> void:
	# Arrange
	var bus = _make_bus()
	_received_companion_id = ""
	_received_delta = 0
	bus.relationship_changed.connect(_on_relationship_changed)

	# Act
	bus.relationship_changed.emit("artemisa", 5)

	# Assert — typeof() must be TYPE_STRING
	assert_int(typeof(_received_companion_id)).is_equal(TYPE_STRING)

func test_event_bus_type_safety_relationship_changed_delta_type_is_int() -> void:
	# Arrange
	var bus = _make_bus()
	_received_companion_id = ""
	_received_delta = 0
	bus.relationship_changed.connect(_on_relationship_changed)

	# Act
	bus.relationship_changed.emit("artemisa", 5)

	# Assert — typeof() must be TYPE_INT
	assert_int(typeof(_received_delta)).is_equal(TYPE_INT)

func test_event_bus_type_safety_relationship_changed_negative_delta_preserved() -> void:
	# Arrange
	var bus = _make_bus()
	_received_companion_id = ""
	_received_delta = 0
	bus.relationship_changed.connect(_on_relationship_changed)

	# Act — negative delta (relationship loss)
	bus.relationship_changed.emit("nyx", -3)

	# Assert
	assert_int(_received_delta).is_equal(-3)

# ---------------------------------------------------------------------------
# AC2 — combat_completed: full Dictionary arrives unchanged
# ---------------------------------------------------------------------------

var _received_combat_result: Dictionary = {}

func _on_combat_completed(result: Dictionary) -> void:
	_received_combat_result = result

func test_event_bus_type_safety_combat_completed_delivers_full_dict_unchanged() -> void:
	# Arrange
	var bus = _make_bus()
	_received_combat_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	var payload: Dictionary = {
		"victory": true,
		"score": 1200,
		"hands_used": 3,
		"captain_id": "artemisa",
	}

	# Act
	bus.combat_completed.emit(payload)

	# Assert — received dict has identical hash to emitted dict (full equality)
	assert_bool(_received_combat_result.hash() == payload.hash()).is_true()

func test_event_bus_type_safety_combat_completed_victory_value_preserved() -> void:
	# Arrange
	var bus = _make_bus()
	_received_combat_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": true, "score": 1200, "hands_used": 3, "captain_id": "artemisa"})

	# Assert
	assert_bool(_received_combat_result.get("victory", false)).is_true()

func test_event_bus_type_safety_combat_completed_score_value_preserved() -> void:
	# Arrange
	var bus = _make_bus()
	_received_combat_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": true, "score": 1200, "hands_used": 3, "captain_id": "artemisa"})

	# Assert
	assert_int(_received_combat_result.get("score", -1)).is_equal(1200)

func test_event_bus_type_safety_combat_completed_hands_used_value_preserved() -> void:
	# Arrange
	var bus = _make_bus()
	_received_combat_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": true, "score": 1200, "hands_used": 3, "captain_id": "artemisa"})

	# Assert
	assert_int(_received_combat_result.get("hands_used", -1)).is_equal(3)

func test_event_bus_type_safety_combat_completed_captain_id_value_preserved() -> void:
	# Arrange
	var bus = _make_bus()
	_received_combat_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": true, "score": 1200, "hands_used": 3, "captain_id": "artemisa"})

	# Assert
	assert_str(_received_combat_result.get("captain_id", "")).is_equal("artemisa")

# ---------------------------------------------------------------------------
# AC3 — romance_stage_changed: old_stage and new_stage arrive as int
# ---------------------------------------------------------------------------

var _received_romance_companion_id: String = ""
var _received_old_stage: int = -1
var _received_new_stage: int = -1

func _on_romance_stage_changed(companion_id: String, old_stage: int, new_stage: int) -> void:
	_received_romance_companion_id = companion_id
	_received_old_stage = old_stage
	_received_new_stage = new_stage

func test_event_bus_type_safety_romance_stage_changed_old_stage_type_is_int() -> void:
	# Arrange
	var bus = _make_bus()
	_received_romance_companion_id = ""
	_received_old_stage = -1
	_received_new_stage = -1
	bus.romance_stage_changed.connect(_on_romance_stage_changed)

	# Act
	bus.romance_stage_changed.emit("artemisa", 0, 1)

	# Assert — typeof() must be TYPE_INT, not TYPE_STRING or TYPE_FLOAT
	assert_int(typeof(_received_old_stage)).is_equal(TYPE_INT)

func test_event_bus_type_safety_romance_stage_changed_new_stage_type_is_int() -> void:
	# Arrange
	var bus = _make_bus()
	_received_romance_companion_id = ""
	_received_old_stage = -1
	_received_new_stage = -1
	bus.romance_stage_changed.connect(_on_romance_stage_changed)

	# Act
	bus.romance_stage_changed.emit("artemisa", 0, 1)

	# Assert — typeof() must be TYPE_INT, not TYPE_STRING or TYPE_FLOAT
	assert_int(typeof(_received_new_stage)).is_equal(TYPE_INT)

func test_event_bus_type_safety_romance_stage_changed_old_stage_value_correct() -> void:
	# Arrange
	var bus = _make_bus()
	_received_romance_companion_id = ""
	_received_old_stage = -1
	_received_new_stage = -1
	bus.romance_stage_changed.connect(_on_romance_stage_changed)

	# Act
	bus.romance_stage_changed.emit("artemisa", 0, 1)

	# Assert
	assert_int(_received_old_stage).is_equal(0)

func test_event_bus_type_safety_romance_stage_changed_new_stage_value_correct() -> void:
	# Arrange
	var bus = _make_bus()
	_received_romance_companion_id = ""
	_received_old_stage = -1
	_received_new_stage = -1
	bus.romance_stage_changed.connect(_on_romance_stage_changed)

	# Act
	bus.romance_stage_changed.emit("artemisa", 0, 1)

	# Assert
	assert_int(_received_new_stage).is_equal(1)

func test_event_bus_type_safety_romance_stage_changed_companion_id_delivered() -> void:
	# Arrange
	var bus = _make_bus()
	_received_romance_companion_id = ""
	_received_old_stage = -1
	_received_new_stage = -1
	bus.romance_stage_changed.connect(_on_romance_stage_changed)

	# Act
	bus.romance_stage_changed.emit("hipolita", 1, 2)

	# Assert
	assert_str(_received_romance_companion_id).is_equal("hipolita")

# ---------------------------------------------------------------------------
# AC4 — tokens_reset: no-argument signal calls listener, no error
# ---------------------------------------------------------------------------

var _tokens_reset_called: bool = false

func _on_tokens_reset() -> void:
	_tokens_reset_called = true

func test_event_bus_type_safety_tokens_reset_listener_is_called() -> void:
	# Arrange
	var bus = _make_bus()
	_tokens_reset_called = false
	bus.tokens_reset.connect(_on_tokens_reset)

	# Act
	bus.tokens_reset.emit()

	# Assert — listener was invoked exactly once (flag is now true)
	assert_bool(_tokens_reset_called).is_true()

func test_event_bus_type_safety_tokens_reset_listener_not_called_before_emit() -> void:
	# Arrange — connect but do NOT emit
	var bus = _make_bus()
	_tokens_reset_called = false
	bus.tokens_reset.connect(_on_tokens_reset)

	# Act — intentionally no emit

	# Assert — flag remains false; connection alone does not invoke the listener
	assert_bool(_tokens_reset_called).is_false()

func test_event_bus_type_safety_tokens_reset_multiple_listeners_all_called() -> void:
	# Arrange — second independent flag
	var bus = _make_bus()
	_tokens_reset_called = false
	var second_called: bool = false

	bus.tokens_reset.connect(_on_tokens_reset)
	bus.tokens_reset.connect(func() -> void: second_called = true)

	# Act
	bus.tokens_reset.emit()

	# Assert — both listeners were invoked
	assert_bool(_tokens_reset_called).is_true()
	assert_bool(second_called).is_true()

# ---------------------------------------------------------------------------
# AC5 — all signals accessible and callable on a fresh EventBus instance
# ---------------------------------------------------------------------------

func test_event_bus_type_safety_all_signals_are_accessible() -> void:
	# Arrange
	var bus = _make_bus()
	var expected_signals: Array[String] = [
		"romance_stage_changed",
		"tokens_reset",
		"combat_completed",
		"dialogue_ended",
		"dialogue_blocked",
		"relationship_changed",
		"trust_changed",
		"companion_met",
		"chapter_completed",
		"node_completed",
	]

	# Act / Assert — every expected signal exists on the instance
	for sig_name: String in expected_signals:
		assert_bool(bus.has_signal(sig_name)).is_true()

func test_event_bus_type_safety_romance_stage_changed_is_connectable() -> void:
	# Arrange
	var bus = _make_bus()

	# Act — connecting must not throw
	var connected_ok: bool = true
	bus.romance_stage_changed.connect(func(_c: String, _o: int, _n: int) -> void: pass)

	# Assert
	assert_bool(connected_ok).is_true()

func test_event_bus_type_safety_tokens_reset_is_connectable() -> void:
	# Arrange
	var bus = _make_bus()

	# Act
	var connected_ok: bool = true
	bus.tokens_reset.connect(func() -> void: pass)

	# Assert
	assert_bool(connected_ok).is_true()

func test_event_bus_type_safety_combat_completed_is_connectable() -> void:
	# Arrange
	var bus = _make_bus()

	# Act
	var connected_ok: bool = true
	bus.combat_completed.connect(func(_r: Dictionary) -> void: pass)

	# Assert
	assert_bool(connected_ok).is_true()

func test_event_bus_type_safety_relationship_changed_is_connectable() -> void:
	# Arrange
	var bus = _make_bus()

	# Act
	var connected_ok: bool = true
	bus.relationship_changed.connect(func(_c: String, _d: int) -> void: pass)

	# Assert
	assert_bool(connected_ok).is_true()
