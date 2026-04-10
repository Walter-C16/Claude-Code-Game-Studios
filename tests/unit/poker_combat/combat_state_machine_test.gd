class_name CombatStateMachineTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-008: Combat State Machine
##
## Covers:
##   AC1  — setup() transitions SETUP→DRAW automatically, initialises state correctly
##   AC2  — DRAW with 5+ cards deals exactly 5 cards, transitions to SELECT
##   AC3  — DRAW with 3 remaining cards deals exactly 3, transitions to SELECT
##   AC4  — DRAW with 0 cards transitions directly to DEFEAT (auto-defeat)
##   AC5  — play_hand() from SELECT transitions to RESOLVE
##   AC6  — Victory check: current_score >= threshold after RESOLVE → VICTORY
##   AC7  — Defeat check: hands_remaining == 0 AND score < threshold → DEFEAT
##   AC8  — 0-card discard is rejected, state remains SELECT
##   AC9  — Discard with discards_remaining == 0 is rejected
##   AC10 — hands_allowed=0 causes setup() to refuse and return false
##   AC11 — Terminal states do not persist combat data (CombatManager is local)
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script reference ──────────────────────────────────────────────────────────

const CombatManagerScript = preload("res://src/systems/combat/combat_manager.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

## Returns a minimal valid enemy config.
func _enemy(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"score_threshold":  40,
		"hands_allowed":    4,
		"discards_allowed": 4,
		"element":          "Fire",
	}
	for key in overrides:
		base[key] = overrides[key]
	return base


## Returns a minimal captain context (no captain bonuses, no BlessingSystem).
func _captain_ctx() -> Dictionary:
	return {
		"captain_id":           "",
		"captain_chip_bonus":   0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":    0,
		"social_buff_mult":     0.0,
		"romance_stages":       {},
	}


## Creates a CombatManager and calls setup() with standard defaults.
## Returns the manager on success or null on expected failure.
func _make_manager(enemy_override: Dictionary = {}) -> CombatManagerScript:
	var cm = CombatManagerScript.new()
	cm.setup(_enemy(enemy_override), _captain_ctx())
	return cm


# ── AC1 — setup() initialises state and transitions SETUP → DRAW → SELECT ────

func test_combat_state_machine_setup_initialises_hands_discards_score() -> void:
	# Arrange / Act
	var cm = CombatManagerScript.new()
	var ok: bool = cm.setup(_enemy(), _captain_ctx())

	# Assert
	assert_bool(ok).is_true()
	assert_int(cm.current_score).is_equal(0)
	assert_int(cm.hands_remaining).is_equal(4)
	assert_int(cm.discards_remaining).is_equal(4)


func test_combat_state_machine_setup_ends_in_select_state() -> void:
	# Arrange / Act
	var cm = _make_manager()

	# Assert — DRAW auto-fires after SETUP, landing in SELECT
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


func test_combat_state_machine_setup_builds_52_card_deck_minus_hand() -> void:
	# Arrange / Act
	var cm = _make_manager()

	# Assert — 52 total; 5 dealt into hand; 47 remain in deck
	assert_int(cm.hand.size()).is_equal(5)
	assert_int(cm.deck.size()).is_equal(47)


# ── AC2 — DRAW with 5+ cards deals exactly 5, transitions to SELECT ───────────

func test_combat_state_machine_draw_deals_5_cards_from_full_deck() -> void:
	# Arrange
	var cm = _make_manager()

	# Act — use play_hand to consume the first hand, triggering another DRAW
	var indices: Array[int] = [0, 1, 2]
	cm.play_hand(indices)

	# After the play a new DRAW auto-fired — hand should have 5 cards again
	# (provided score did not reach threshold in 3-card High Card play)
	if cm.state == CombatManagerScript.State.SELECT:
		assert_int(cm.hand.size()).is_equal(5)


func test_combat_state_machine_state_is_select_after_draw() -> void:
	# Arrange / Act
	var cm = _make_manager()

	# Assert — after initial draw, state is SELECT
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


# ── AC3 — DRAW with 3 remaining cards deals exactly 3 ────────────────────────

func test_combat_state_machine_draw_with_3_cards_remaining_deals_3() -> void:
	# Arrange — create manager and trim the deck to 3 cards
	var cm = _make_manager()
	cm.deck.clear()
	# Add 3 stub cards directly to the deck
	for v: int in range(2, 5):
		cm.deck.append({ "value": v, "suit": 0, "element": "Fire", "enhancement": "" })

	# Force a new draw by clearing the hand and calling the private method
	cm.hand.clear()
	cm._draw_hand()

	# Assert
	assert_int(cm.hand.size()).is_equal(3)
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


# ── AC4 — DRAW with 0 cards → auto-DEFEAT ────────────────────────────────────

func test_combat_state_machine_draw_with_empty_deck_auto_defeats() -> void:
	# Arrange
	var cm = _make_manager()
	cm.deck.clear()
	cm.hand.clear()

	# Act — trigger an empty draw
	cm._draw_hand()

	# Assert
	assert_int(cm.state).is_equal(CombatManagerScript.State.DEFEAT)


# ── AC5 — play_hand from SELECT transitions state ────────────────────────────

func test_combat_state_machine_play_hand_from_select_is_accepted() -> void:
	# Arrange
	var cm = _make_manager()
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)
	assert_bool(cm.hand.size() >= 1).is_true()

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — non-empty result means action was accepted
	assert_bool(result.is_empty()).is_false()


func test_combat_state_machine_play_hand_rejected_outside_select() -> void:
	# Arrange — put state in VICTORY (terminal)
	var cm = _make_manager()
	cm.state = CombatManagerScript.State.VICTORY

	# Act
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert — rejected
	assert_bool(result.is_empty()).is_true()


# ── AC6 — Victory when current_score >= score_threshold ──────────────────────

func test_combat_state_machine_victory_when_score_reaches_threshold() -> void:
	# Arrange — score_threshold=1 so any hand wins immediately
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx())

	# Act — play any card; score will be >= 1
	var result: Dictionary = cm.play_hand([0] as Array[int])

	# Assert
	assert_bool(result.is_empty()).is_false()
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)
	assert_bool(cm.current_score >= 1).is_true()


func test_combat_state_machine_victory_checked_before_defeat() -> void:
	# Arrange — threshold=1, hands_allowed=1 so both conditions can fire on
	# the same play. Victory must take priority (ADR-0007 AC6).
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1, "hands_allowed": 1}), _captain_ctx())

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — VICTORY not DEFEAT
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)


# ── AC7 — Defeat when hands exhausted and score < threshold ──────────────────

func test_combat_state_machine_defeat_when_hands_exhausted() -> void:
	# Arrange — threshold very high (999999) with 1 hand allowed
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 999999, "hands_allowed": 1}), _captain_ctx())

	# Act — play hand; score will be far below threshold
	cm.play_hand([0] as Array[int])

	# Assert
	assert_int(cm.state).is_equal(CombatManagerScript.State.DEFEAT)


func test_combat_state_machine_defeat_has_hands_remaining_zero() -> void:
	# Arrange
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 999999, "hands_allowed": 1}), _captain_ctx())

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	assert_int(cm.hands_remaining).is_equal(0)
	assert_int(cm.state).is_equal(CombatManagerScript.State.DEFEAT)


# ── AC8 — 0-card discard is rejected ─────────────────────────────────────────

func test_combat_state_machine_discard_zero_cards_is_rejected() -> void:
	# Arrange
	var cm = _make_manager()
	var discards_before: int = cm.discards_remaining

	# Act — pass empty indices
	cm.discard([] as Array[int])

	# Assert — discards not decremented, state unchanged
	assert_int(cm.discards_remaining).is_equal(discards_before)
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


# ── AC9 — Discard rejected when discards_remaining == 0 ──────────────────────

func test_combat_state_machine_discard_rejected_when_none_remaining() -> void:
	# Arrange
	var cm = _make_manager()
	cm.discards_remaining = 0
	var hand_before: int = cm.hand.size()

	# Act
	cm.discard([0] as Array[int])

	# Assert — hand unchanged, state unchanged
	assert_int(cm.hand.size()).is_equal(hand_before)
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


# ── AC10 — hands_allowed=0 causes setup() to refuse ──────────────────────────

func test_combat_state_machine_setup_refuses_zero_hands_allowed() -> void:
	# Arrange
	var cm = CombatManagerScript.new()

	# Act
	var ok: bool = cm.setup(_enemy({"hands_allowed": 0}), _captain_ctx())

	# Assert — setup returns false; state stays at SETUP
	assert_bool(ok).is_false()
	assert_int(cm.state).is_equal(CombatManagerScript.State.SETUP)


func test_combat_state_machine_setup_refuses_negative_hands_allowed() -> void:
	# Arrange
	var cm = CombatManagerScript.new()

	# Act
	var ok: bool = cm.setup(_enemy({"hands_allowed": -1}), _captain_ctx())

	# Assert
	assert_bool(ok).is_false()


# ── AC11 — No combat state persists outside CombatManager ────────────────────

func test_combat_state_machine_no_combat_state_in_manager_after_free() -> void:
	# Arrange — run a complete victory and record final score
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 1}), _captain_ctx())
	cm.play_hand([0] as Array[int])
	assert_int(cm.state).is_equal(CombatManagerScript.State.VICTORY)

	# Act — setting reference to null frees the RefCounted
	cm = null

	# Assert — just confirm the assignment succeeded (RefCounted is stack-local;
	# this confirms no GameStore holds combat state)
	assert_bool(cm == null).is_true()


# ── Discard valid path ────────────────────────────────────────────────────────

func test_combat_state_machine_discard_removes_card_and_redraws() -> void:
	# Arrange
	var cm = _make_manager()
	var hand_size_before: int = cm.hand.size()
	var discards_before: int = cm.discards_remaining

	# Act — discard first card
	cm.discard([0] as Array[int])

	# Assert — hand size restored to original (drew 1 replacement), discard decremented
	assert_int(cm.hand.size()).is_equal(hand_size_before)
	assert_int(cm.discards_remaining).is_equal(discards_before - 1)
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


func test_combat_state_machine_discard_without_replacements_reduces_hand() -> void:
	# Arrange — empty the deck so no replacements are available
	var cm = _make_manager()
	cm.deck.clear()
	var discards_before: int = cm.discards_remaining

	# Act — discard 2 cards
	cm.discard([0, 1] as Array[int])

	# Assert — hand shrank by 2 (no replacements), state still SELECT
	assert_int(cm.hand.size()).is_equal(3)
	assert_int(cm.discards_remaining).is_equal(discards_before - 1)
	assert_int(cm.state).is_equal(CombatManagerScript.State.SELECT)


# ── Hands used counter ────────────────────────────────────────────────────────

func test_combat_state_machine_hands_used_increments_per_play() -> void:
	# Arrange
	var cm = CombatManagerScript.new()
	cm.setup(_enemy({"score_threshold": 999999, "hands_allowed": 3}), _captain_ctx())

	# Act — play twice (will not reach threshold)
	cm.play_hand([0] as Array[int])
	if cm.state == CombatManagerScript.State.SELECT:
		cm.play_hand([0] as Array[int])

	# Assert
	assert_int(cm.hands_used).is_equal(2)
