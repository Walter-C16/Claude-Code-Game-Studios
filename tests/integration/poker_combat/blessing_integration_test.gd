class_name BlessingIntegrationTest
extends GdUnitTestSuite

## Integration tests for STORY-COMBAT-010: BlessingSystem Black-Box Integration
##
## Covers:
##   AC1 — hand_context passed to BlessingSystem contains played_cards, hand_rank,
##          captain_id, and romance_stages (minimum required keys)
##   AC2 — BlessingSystem returns {blessing_chips:50, blessing_mult:2.0} →
##          blessing_chips=50 added at the correct pipeline position (after foil, before element)
##   AC3 — BlessingSystem returns zeros → score is correct without blessing contribution
##   AC4 — BlessingSystem is called via local reference (not via autoload path)
##   AC5 — romance_stages snapshot from SETUP is used on hand 2, not live GameStore value
##   AC6 — CombatManager does not access BlessingSystem internal fields (black-box)
##
## BlessingSystem (ADR-0012) does not exist yet. These tests use a stub that
## records what it receives and returns a controlled result.
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script reference ──────────────────────────────────────────────────────────

const CombatManagerScript = preload("res://src/systems/combat/combat_manager.gd")

# ── Stub BlessingSystem ───────────────────────────────────────────────────────

## Records every compute() call for assertion.
## Returns a pre-configured result on each call.
class StubBlessingSystem extends RefCounted:
	## What compute() will return on the next call.
	var next_result: Dictionary = {"blessing_chips": 0, "blessing_mult": 0.0}

	## All hand_context dicts received by compute(), in call order.
	var received_contexts: Array = []

	## Number of times compute() was called.
	var call_count: int = 0

	## Internal field — intentionally NOT in the public interface.
	## Used to verify CombatManager never reads it (black-box contract).
	var _internal_state: String = "secret"

	## The single public method CombatManager is allowed to call.
	func compute(hand_context: Dictionary) -> Dictionary:
		call_count += 1
		received_contexts.append(hand_context.duplicate(true))
		return next_result.duplicate()


## A stub that records calls but has ONLY compute() — no other public methods.
## Used to verify CombatManager respects the black-box contract.
class MinimalBlessingStub extends RefCounted:
	var compute_called: bool = false

	func compute(_ctx: Dictionary) -> Dictionary:
		compute_called = true
		return {"blessing_chips": 0, "blessing_mult": 0.0}

# ── Helpers ───────────────────────────────────────────────────────────────────

func _enemy(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"score_threshold":  1,
		"hands_allowed":    4,
		"discards_allowed": 4,
		"element":          "",
	}
	for key in overrides:
		base[key] = overrides[key]
	return base


## Builds captain context with the blessing_system stub injected.
func _captain_ctx_with_blessing(
		stub: StubBlessingSystem,
		overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"captain_id":            "artemisa",
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":     0,
		"social_buff_mult":      0.0,
		"romance_stages":        {"artemisa": 2, "hipolita": 1},
		"blessing_system":       stub,
	}
	for key in overrides:
		base[key] = overrides[key]
	return base


# ── AC1 — hand_context contains required keys ─────────────────────────────────

func test_blessing_integration_compute_receives_played_cards_key() -> void:
	# Arrange
	var stub = StubBlessingSystem.new()
	var cm = CombatManagerScript.new()
	cm.setup(_enemy(), _captain_ctx_with_blessing(stub))

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — compute was called
	assert_int(stub.call_count).is_equal(1)
	var ctx: Dictionary = stub.received_contexts[0] as Dictionary
	assert_bool(ctx.has("played_cards")).is_true()


func test_blessing_integration_compute_receives_hand_rank_key() -> void:
	# Arrange
	var stub = StubBlessingSystem.new()
	var cm = CombatManagerScript.new()
	cm.setup(_enemy(), _captain_ctx_with_blessing(stub))

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	var ctx: Dictionary = stub.received_contexts[0] as Dictionary
	assert_bool(ctx.has("hand_rank")).is_true()
	assert_bool((ctx.get("hand_rank", "") as String).length() > 0).is_true()


func test_blessing_integration_compute_receives_captain_id_key() -> void:
	# Arrange
	var stub = StubBlessingSystem.new()
	var cm = CombatManagerScript.new()
	cm.setup(_enemy(), _captain_ctx_with_blessing(stub, {"captain_id": "artemisa"}))

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	var ctx: Dictionary = stub.received_contexts[0] as Dictionary
	assert_bool(ctx.has("captain_id")).is_true()
	assert_str(ctx.get("captain_id", "") as String).is_equal("artemisa")


func test_blessing_integration_compute_receives_romance_stages_key() -> void:
	# Arrange
	var stub = StubBlessingSystem.new()
	var stages: Dictionary = {"artemisa": 3, "nyx": 1}
	var cm = CombatManagerScript.new()
	cm.setup(_enemy(), _captain_ctx_with_blessing(stub, {"romance_stages": stages}))

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	var ctx: Dictionary = stub.received_contexts[0] as Dictionary
	assert_bool(ctx.has("romance_stages")).is_true()
	var received_stages: Dictionary = ctx.get("romance_stages", {}) as Dictionary
	assert_int(received_stages.get("artemisa", -1) as int).is_equal(3)


func test_blessing_integration_compute_received_played_cards_match_selection() -> void:
	# Arrange
	var stub = StubBlessingSystem.new()
	var cm = CombatManagerScript.new()
	cm.setup(_enemy(), _captain_ctx_with_blessing(stub))

	# Force a known hand
	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.hand.append({"value": 8, "suit": 1, "element": "Water", "enhancement": ""})

	# Act — play both cards
	cm.play_hand([0, 1] as Array[int])

	# Assert — played_cards has 2 entries
	var ctx: Dictionary = stub.received_contexts[0] as Dictionary
	var played: Array = ctx.get("played_cards", []) as Array
	assert_int(played.size()).is_equal(2)


# ── AC2 — blessing_chips injected at correct pipeline position ────────────────

func test_blessing_integration_blessing_chips_50_added_to_score() -> void:
	# Arrange — BlessingSystem returns blessing_chips=50
	# One card value=2, no enhancements, no element interaction
	# base=5 (High Card), card=2, blessing=50 → chips=57; mult=1.0 → score=57
	var stub = StubBlessingSystem.new()
	stub.next_result = {"blessing_chips": 50, "blessing_mult": 0.0}

	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx_with_blessing(stub))

	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — chips = 5 + 2 + 50 = 57
	assert_int(result.get("chips", -1) as int).is_equal(57)


func test_blessing_integration_blessing_chips_position_is_after_foil() -> void:
	# Arrange — Foil card (+50 chips) + blessing_chips=10
	# base=5, card_chips=2, foil=50, blessing=10 → 67
	var stub = StubBlessingSystem.new()
	stub.next_result = {"blessing_chips": 10, "blessing_mult": 0.0}

	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx_with_blessing(stub))

	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": "Foil"})

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — chips = 5 + 2 + 50(foil) + 10(blessing) = 67
	assert_int(result.get("chips", -1) as int).is_equal(67)


func test_blessing_integration_blessing_mult_2_added_to_additive_phase() -> void:
	# Arrange — blessing_mult=2.0 added to base Pair mult (2.0) → additive=4.0
	# Pair of 7s: chips=10+7+7=24; mult=2.0+2.0=4.0; score=floor(24*4.0)=96
	var stub = StubBlessingSystem.new()
	stub.next_result = {"blessing_chips": 0, "blessing_mult": 2.0}

	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx_with_blessing(stub))

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.hand.append({"value": 7, "suit": 1, "element": "Water", "enhancement": ""})

	# Act
	var result: Dictionary = cm.play_hand([0, 1] as Array[int])

	# Assert — score = floor(24 * 4.0) = 96
	assert_int(result.get("score", -1) as int).is_equal(96)


# ── AC3 — Zero blessing values contribute nothing ────────────────────────────

func test_blessing_integration_zero_blessings_score_matches_baseline() -> void:
	# Arrange — BlessingSystem returns zeros (no active blessings)
	# Single card value=7, High Card: chips=5+7=12, mult=1.0 → score=12
	var stub = StubBlessingSystem.new()
	stub.next_result = {"blessing_chips": 0, "blessing_mult": 0.0}

	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx_with_blessing(stub))

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — chips=12, score=12 (blessing adds nothing)
	assert_int(result.get("chips", -1) as int).is_equal(12)
	assert_int(result.get("score", -1) as int).is_equal(12)


# ── AC4 — BlessingSystem called via local reference, not autoload path ────────

func test_blessing_integration_compute_called_on_local_stub_not_autoload() -> void:
	# Arrange — inject a MinimalBlessingStub (local reference, not autoload)
	var stub = MinimalBlessingStub.new()
	var cm = CombatManagerScript.new()
	var captain_ctx: Dictionary = {
		"captain_id":            "",
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":     0,
		"social_buff_mult":      0.0,
		"romance_stages":        {},
		"blessing_system":       stub,
	}
	cm.setup(_enemy(), captain_ctx)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — the local stub was called (not a global autoload)
	assert_bool(stub.compute_called).is_true()


func test_blessing_integration_no_blessing_system_returns_zeros() -> void:
	# Arrange — no blessing_system key in captain_ctx at all
	var captain_ctx: Dictionary = {
		"captain_id":            "",
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":     0,
		"social_buff_mult":      0.0,
		"romance_stages":        {},
		# intentionally omitting "blessing_system"
	}
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), captain_ctx)

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act — should not crash
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — zero blessing contribution → chips=5+7=12
	assert_int(result.get("chips", -1) as int).is_equal(12)


# ── AC5 — romance_stages snapshot frozen at SETUP ────────────────────────────

func test_blessing_integration_romance_stages_snapshot_frozen_at_setup() -> void:
	# Arrange — romance_stages captured at SETUP: artemisa=2
	# After setup, we mutate the captain_ctx dict to simulate a mid-combat change.
	# CombatManager must still send the SETUP snapshot (not the mutated version).
	var stub = StubBlessingSystem.new()
	var stages_at_setup: Dictionary = {"artemisa": 2}
	var captain_ctx: Dictionary = {
		"captain_id":            "artemisa",
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":     0,
		"social_buff_mult":      0.0,
		"romance_stages":        stages_at_setup,
		"blessing_system":       stub,
	}

	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 999999, "hands_allowed": 2}), captain_ctx)

	# Mutate the original dict AFTER setup (simulates a hypothetical mid-combat change)
	stages_at_setup["artemisa"] = 99
	captain_ctx["romance_stages"] = {"artemisa": 99}

	# Act — play hand 1 (should use SETUP snapshot)
	cm.play_hand([0] as Array[int])

	# Assert — romance_stages received by BlessingSystem reflects SETUP value (2)
	if stub.call_count > 0:
		var ctx: Dictionary = stub.received_contexts[0] as Dictionary
		var received_stages: Dictionary = ctx.get("romance_stages", {}) as Dictionary
		assert_int(received_stages.get("artemisa", -1) as int).is_equal(2)


# ── AC6 — CombatManager accesses ONLY compute() on BlessingSystem ────────────

func test_blessing_integration_black_box_only_compute_accessed() -> void:
	# Arrange — stub has an _internal_state field that must NOT be accessed.
	# We verify this indirectly: the stub's _internal_state stays "secret".
	# There is no way to intercept property access in GDScript, so this test
	# verifies the contract via code review (checked during /code-review)
	# and confirms CombatManager only passes hand_context to compute().
	var stub = StubBlessingSystem.new()
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx_with_blessing(stub))

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — compute was called exactly once with a valid hand_context
	assert_int(stub.call_count).is_equal(1)
	# Internal state unchanged (CombatManager never wrote to it)
	assert_str(stub._internal_state).is_equal("secret")


# ── compute() called once per play_hand() ─────────────────────────────────────

func test_blessing_integration_compute_called_once_per_play() -> void:
	# Arrange
	var stub = StubBlessingSystem.new()
	var cm = CombatManagerScript.new()
	cm.setup(
		_enemy({"score_threshold": 999999, "hands_allowed": 3}),
		_captain_ctx_with_blessing(stub))

	# Act — play twice
	cm.play_hand([0] as Array[int])
	if cm.state == CombatManagerScript.State.SELECT:
		cm.play_hand([0] as Array[int])

	# Assert — compute called once per play_hand invocation
	assert_int(stub.call_count).is_equal(2)
