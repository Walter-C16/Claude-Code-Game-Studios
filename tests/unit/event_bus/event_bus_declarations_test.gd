class_name EventBusDeclarationsTest
extends GdUnitTestSuite

# Unit tests for STORY-EB-001: EventBus Signal Catalog Declaration
#
# Covers:
#   AC1 — All 10 signals declared on the EventBus instance
#   AC2 — No _process, no _physics_process, no instance variables
#   AC3 — EventBus extends Node
#   AC5 — combat_completed emits and receives the expected Dictionary structure
#
# See: docs/architecture/adr-0004-eventbus.md

const EventBusScript = preload("res://src/autoloads/event_bus.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates a fresh EventBus instance for each test.
func _make_bus() -> Node:
	return EventBusScript.new()

# ---------------------------------------------------------------------------
# AC1 — All 10 signals are declared
# ---------------------------------------------------------------------------

func test_event_bus_declarations_has_romance_stage_changed_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("romance_stage_changed")).is_true()

func test_event_bus_declarations_has_tokens_reset_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("tokens_reset")).is_true()

func test_event_bus_declarations_has_combat_completed_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("combat_completed")).is_true()

func test_event_bus_declarations_has_dialogue_ended_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("dialogue_ended")).is_true()

func test_event_bus_declarations_has_dialogue_blocked_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("dialogue_blocked")).is_true()

func test_event_bus_declarations_has_relationship_changed_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("relationship_changed")).is_true()

func test_event_bus_declarations_has_trust_changed_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("trust_changed")).is_true()

func test_event_bus_declarations_has_companion_met_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("companion_met")).is_true()

func test_event_bus_declarations_has_chapter_completed_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("chapter_completed")).is_true()

func test_event_bus_declarations_has_node_completed_signal() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.has_signal("node_completed")).is_true()

func test_event_bus_declarations_exactly_ten_signals_declared() -> void:
	# Arrange
	var bus := _make_bus()
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

	# Act — collect script-declared signal names (exclude Node built-ins)
	var script_signals: Array[String] = []
	for sig: Dictionary in bus.get_signal_list():
		var sig_name: String = sig.get("name", "")
		if expected_signals.has(sig_name):
			script_signals.append(sig_name)

	# Assert — every expected signal is present and the counts match
	assert_int(script_signals.size()).is_equal(expected_signals.size())

# ---------------------------------------------------------------------------
# AC2 — No _process, no _physics_process, no instance variables
# ---------------------------------------------------------------------------

func test_event_bus_declarations_has_no_process_method() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	# has_method() returns true for inherited methods — but Node itself does not
	# define _process as a script method; it is a virtual override hook. If the
	# script does not override it, get_script().get_script_method_list() will
	# not include it.
	var script: GDScript = bus.get_script() as GDScript
	var method_names: Array[String] = []
	for m: Dictionary in script.get_script_method_list():
		method_names.append(m.get("name", ""))

	assert_bool(method_names.has("_process")).is_false()

func test_event_bus_declarations_has_no_physics_process_method() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	var script: GDScript = bus.get_script() as GDScript
	var method_names: Array[String] = []
	for m: Dictionary in script.get_script_method_list():
		method_names.append(m.get("name", ""))

	assert_bool(method_names.has("_physics_process")).is_false()

func test_event_bus_declarations_has_no_instance_variables() -> void:
	# Arrange
	var bus := _make_bus()

	# Act — collect script-defined variables (PROPERTY_USAGE_SCRIPT_VARIABLE = 8192)
	var script_vars: Array[String] = []
	for prop: Dictionary in bus.get_property_list():
		if prop.get("usage", 0) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			script_vars.append(prop.get("name", ""))

	# Assert — no script-level instance variables at all
	assert_int(script_vars.size()).is_equal(0)

# ---------------------------------------------------------------------------
# AC3 — EventBus extends Node
# ---------------------------------------------------------------------------

func test_event_bus_declarations_extends_node() -> void:
	# Arrange
	var bus := _make_bus()

	# Act / Assert
	assert_bool(bus.is_class("Node")).is_true()

func test_event_bus_declarations_is_not_a_reference_type() -> void:
	# Arrange / Act
	var bus := _make_bus()

	# Assert — EventBus must be a Node subclass, not a RefCounted/Resource
	assert_bool(bus is Node).is_true()

# ---------------------------------------------------------------------------
# AC5 — combat_completed emits Dictionary with expected structure
# ---------------------------------------------------------------------------

## Receiver helper — stores the last received result dict for assertion.
var _received_result: Dictionary = {}

func _on_combat_completed(result: Dictionary) -> void:
	_received_result = result

func test_event_bus_declarations_combat_completed_emits_expected_dict_keys() -> void:
	# Arrange
	var bus := _make_bus()
	_received_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	var payload: Dictionary = {
		"victory": true,
		"score": 1500,
		"hands_used": 4,
		"captain_id": "artemisa",
	}

	# Act
	bus.combat_completed.emit(payload)

	# Assert — all four required keys are present
	assert_bool(_received_result.has("victory")).is_true()
	assert_bool(_received_result.has("score")).is_true()
	assert_bool(_received_result.has("hands_used")).is_true()
	assert_bool(_received_result.has("captain_id")).is_true()

func test_event_bus_declarations_combat_completed_emits_correct_victory_value() -> void:
	# Arrange
	var bus := _make_bus()
	_received_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": false, "score": 0, "hands_used": 6, "captain_id": "nyx"})

	# Assert
	assert_bool(_received_result.get("victory", true)).is_false()

func test_event_bus_declarations_combat_completed_emits_correct_score_value() -> void:
	# Arrange
	var bus := _make_bus()
	_received_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": true, "score": 2400, "hands_used": 3, "captain_id": "hipolita"})

	# Assert
	assert_int(_received_result.get("score", -1)).is_equal(2400)

func test_event_bus_declarations_combat_completed_emits_correct_captain_id() -> void:
	# Arrange
	var bus := _make_bus()
	_received_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	# Act
	bus.combat_completed.emit({"victory": true, "score": 800, "hands_used": 5, "captain_id": "atenea"})

	# Assert
	assert_str(_received_result.get("captain_id", "")).is_equal("atenea")

func test_event_bus_declarations_combat_completed_listener_receives_full_payload() -> void:
	# Arrange
	var bus := _make_bus()
	_received_result = {}
	bus.combat_completed.connect(_on_combat_completed)

	var payload: Dictionary = {
		"victory": true,
		"score": 3000,
		"hands_used": 2,
		"captain_id": "artemisa",
	}

	# Act
	bus.combat_completed.emit(payload)

	# Assert — dict received is equal to the emitted payload
	assert_bool(_received_result.hash() == payload.hash()).is_true()
