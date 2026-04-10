class_name VictoryDefeatTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-009: Victory, Defeat, and Social Buff Lifecycle
##
## Covers:
##   AC1 — VICTORY emits EventBus.combat_completed with victory=true, score, hands_used
##   AC2 — DEFEAT emits EventBus.combat_completed with victory=false, score, hands_used
##   AC3 — Victory on hand 2 of 4: hands_used=2 in payload (forfeited hands not counted)
##   AC4 — Social buff captured from captain_ctx at SETUP: chips/mult used in scoring
##   AC5 — Active buff with combats_remaining=3, player WINS → decremented to 2
##   AC6 — Active buff with combats_remaining=3, player LOSES → remains 3
##   AC7 — combats_remaining reaches 0 on victory → buff marked inactive (cleared)
##   AC8 — No active buff at SETUP → social_buff_chips=0, social_buff_mult=0.0, no crash
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script reference ──────────────────────────────────────────────────────────

const CombatManagerScript = preload("res://src/systems/combat/combat_manager.gd")

# ── Mock EventBus ─────────────────────────────────────────────────────────────

## Minimal EventBus stand-in that records combat_completed payloads.
## Implements the duck-typed interface used by CombatManager._emit_combat_completed().
class MockEventBus extends RefCounted:
	signal combat_completed(result: Dictionary)
	var captured_payload: Dictionary = {}
	var emit_count: int = 0

	func _init() -> void:
		combat_completed.connect(_record)

	func _record(result: Dictionary) -> void:
		captured_payload = result.duplicate()
		emit_count += 1

# ── Mock GameStore ────────────────────────────────────────────────────────────

## Minimal GameStore stand-in that tracks combat buff lifecycle.
## Implements get_combat_buff / set_combat_buff / clear_combat_buff.
class MockGameStore extends RefCounted:
	var _buff: Dictionary = {}

	func get_combat_buff() -> Dictionary:
		return _buff.duplicate()

	func set_combat_buff(buff: Dictionary) -> void:
		_buff = buff.duplicate()

	func clear_combat_buff() -> void:
		_buff = {}

	func is_buff_active() -> bool:
		return not _buff.is_empty()

	func get_combats_remaining() -> int:
		return _buff.get("combats_remaining", 0) as int

# ── Helpers ───────────────────────────────────────────────────────────────────

func _enemy(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"score_threshold":  40,
		"hands_allowed":    4,
		"discards_allowed": 4,
		"element":          "",
	}
	for key in overrides:
		base[key] = overrides[key]
	return base


func _captain_ctx(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"captain_id":            "",
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":     0,
		"social_buff_mult":      0.0,
		"romance_stages":        {},
	}
	for key in overrides:
		base[key] = overrides[key]
	return base


## Creates a CombatManager wired to mock EventBus and GameStore.
func _make_wired_manager(
		enemy: Dictionary,
		captain_ctx: Dictionary,
		game_store: MockGameStore,
		event_bus: MockEventBus) -> CombatManagerScript:
	var cm = CombatManagerScript.new()
	cm.setup(enemy, captain_ctx, game_store, event_bus)
	return cm


# ── AC1 — VICTORY emits combat_completed with victory=true ───────────────────

func test_victory_defeat_victory_emits_combat_completed_victory_true() -> void:
	# Arrange — score_threshold=1 so any play wins
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)
	assert_int(eb.emit_count).is_equal(1)
	assert_bool(eb.captured_payload.get("victory", false) as bool).is_true()


func test_victory_defeat_victory_payload_contains_score() -> void:
	# Arrange
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — score in payload matches current_score
	assert_int(eb.captured_payload.get("score", -1) as int).is_equal(cm.current_score)


func test_victory_defeat_victory_payload_contains_hands_used() -> void:
	# Arrange
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	assert_int(eb.captured_payload.get("hands_used", -1) as int).is_equal(1)


# ── AC2 — DEFEAT emits combat_completed with victory=false ───────────────────

func test_victory_defeat_defeat_emits_combat_completed_victory_false() -> void:
	# Arrange — threshold impossibly high, only 1 hand
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 999999, "hands_allowed": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	assert_int(cm.state).is_equal(CombatManagerScript.State.DEFEAT)
	assert_int(eb.emit_count).is_equal(1)
	assert_bool(eb.captured_payload.get("victory", true) as bool).is_false()


func test_victory_defeat_defeat_payload_contains_correct_score() -> void:
	# Arrange
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 999999, "hands_allowed": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — score in payload matches what was accumulated
	assert_int(eb.captured_payload.get("score", -1) as int).is_equal(cm.current_score)


# ── AC3 — hands_used reflects only hands actually played ──────────────────────

func test_victory_defeat_victory_on_hand_2_reports_hands_used_2() -> void:
	# Arrange — threshold large enough that one hand can't win but two might.
	# We force a win by setting threshold low enough for hand 2.
	# Use score_threshold=1 with hands_allowed=4 — first play already wins,
	# so we use threshold that forces two plays first.
	# Strategy: play first hand intentionally getting 0 score is impossible
	# (min score = 1 after clamp). Instead, set threshold so hand 2 crosses it.
	# We'll set threshold=999999 and manually set current_score before act.
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 999999, "hands_allowed": 4}), _captain_ctx(), gs, eb)

	# Simulate hand 1 already played (didn't win)
	cm.hands_used = 1
	cm.hands_remaining = 3
	# Now set score just below threshold so next play will cross it
	cm.current_score = 999990
	cm.score_threshold = 999991

	# Act — play hand 2 (this is the "second" play from caller's perspective)
	cm.play_hand([0] as Array[int])

	# Assert — victory, hands_used=2
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)
	assert_int(eb.captured_payload.get("hands_used", -1) as int).is_equal(2)


# ── AC4 — Social buff chips/mult captured at SETUP and used in scoring ────────

func test_victory_defeat_social_buff_chips_from_ctx_used_in_scoring() -> void:
	# Arrange — inject social_buff_chips=20 in captain context
	# High Card one card (value=2): base=5, card=2, social=20 → chips=27
	# mult=1.0 → score=27 (> threshold=1 → victory)
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}),
		_captain_ctx({"social_buff_chips": 20}),
		gs, eb)

	# Force a single low-value card so we can verify the score maths
	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — chips must include social_buff_chips=20
	# base=5, card=2, social=20 → total_chips=27; mult=1.0 → score=27
	assert_int(result.get("chips", -1) as int).is_equal(27)


func test_victory_defeat_social_buff_mult_from_ctx_used_in_scoring() -> void:
	# Arrange — social_buff_mult=1.0 on top of base Pair mult=2.0 → additive=3.0
	# This test verifies the mult context flows through the pipeline
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}),
		_captain_ctx({"social_buff_mult": 1.0}),
		gs, eb)

	# Two matching cards for Pair (value=7)
	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.hand.append({"value": 7, "suit": 1, "element": "Water", "enhancement": ""})

	# Act
	var result: Dictionary = cm.play_hand([0, 1] as Array[int])

	# Assert — Pair base_mult=2.0 + social_buff_mult=1.0 = 3.0 additive
	# chips = 10(base) + 7+7(cards) = 24; score = floor(24*3.0) = 72
	assert_int(result.get("score", -1) as int).is_equal(72)


# ── AC5 — Victory decrements social buff combats_remaining ───────────────────

func test_victory_defeat_victory_decrements_combats_remaining() -> void:
	# Arrange — GameStore has active buff with combats_remaining=3
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	gs.set_combat_buff({"chips": 20, "mult": 1.5, "combats_remaining": 3})

	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — VICTORY, combats_remaining decremented from 3 to 2
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)
	assert_int(gs.get_combats_remaining()).is_equal(2)


# ── AC6 — Defeat retains social buff (combats_remaining unchanged) ────────────

func test_victory_defeat_defeat_retains_combats_remaining() -> void:
	# Arrange
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	gs.set_combat_buff({"chips": 20, "mult": 1.5, "combats_remaining": 3})

	var cm = _make_wired_manager(
		_enemy({"score_threshold": 999999, "hands_allowed": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — DEFEAT, combats_remaining unchanged at 3
	assert_int(cm.state).is_equal(CombatManagerScript.State.DEFEAT)
	assert_int(gs.get_combats_remaining()).is_equal(3)


# ── AC7 — combats_remaining reaches 0 → buff cleared ─────────────────────────

func test_victory_defeat_buff_cleared_when_combats_remaining_reaches_0() -> void:
	# Arrange — buff with only 1 combat remaining
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	gs.set_combat_buff({"chips": 20, "mult": 1.5, "combats_remaining": 1})

	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act — win (victory consumes the last combat remaining)
	cm.play_hand([0] as Array[int])

	# Assert — buff is cleared (inactive), not set to combats_remaining=0
	assert_bool(gs.is_buff_active()).is_false()


func test_victory_defeat_buff_not_set_to_negative_combats_remaining() -> void:
	# Arrange — same as AC7: buff with 1 remaining, win
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	gs.set_combat_buff({"chips": 20, "mult": 1.5, "combats_remaining": 1})

	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — combats_remaining is 0 (cleared buff) not -1
	assert_int(gs.get_combats_remaining()).is_equal(0)


# ── AC8 — No active buff → no crash, zero buff values ────────────────────────

func test_victory_defeat_no_buff_does_not_crash_on_victory() -> void:
	# Arrange — GameStore has no buff
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	# No call to set_combat_buff — buff remains empty

	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)

	# Act — should not throw
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — victory reached, no error
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)
	assert_bool(result.is_empty()).is_false()


func test_victory_defeat_no_buff_social_chips_zero() -> void:
	# Arrange — no social buff in context
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}),
		_captain_ctx(),  # social_buff_chips=0 by default
		gs, eb)

	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — chips = base(5) + card(2) = 7 (no social contribution)
	assert_int(result.get("chips", -1) as int).is_equal(7)


# ── Terminal state guard ──────────────────────────────────────────────────────

func test_victory_defeat_play_rejected_after_victory() -> void:
	# Arrange
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 1}), _captain_ctx(), gs, eb)
	cm.play_hand([0] as Array[int])
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)

	# Act — attempt second play in terminal state
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — rejected, emit_count stays at 1
	assert_bool(result.is_empty()).is_true()
	assert_int(eb.emit_count).is_equal(1)


func test_victory_defeat_play_rejected_after_defeat() -> void:
	# Arrange
	var eb = MockEventBus.new()
	var gs = MockGameStore.new()
	var cm = _make_wired_manager(
		_enemy({"score_threshold": 999999, "hands_allowed": 1}), _captain_ctx(), gs, eb)
	cm.play_hand([0] as Array[int])
	assert_int(cm.state).is_equal(CombatManagerScript.State.DEFEAT)

	# Act — attempt second play in terminal state
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert
	assert_bool(result.is_empty()).is_true()
	assert_int(eb.emit_count).is_equal(1)
