class_name HandEvaluationTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-002: Hand Evaluation — All 10 Poker Ranks
##
## Covers:
##   AC1  — Pair of 7s → rank "Pair", base_chips=10, base_mult=2
##   AC2  — Three of a Kind → rank "Three of a Kind", base_chips=30, base_mult=3
##   AC3  — Royal Flush (A-K-Q-J-10 suited) → base_chips=100, base_mult=8
##   AC4  — Wheel Straight Flush (A-2-3-4-5 suited) → "Straight Flush"
##   AC5  — Wheel Straight (A-2-3-4-5 off-suit) → "Straight"
##   AC6  — 4-card Three of a Kind → "Three of a Kind" (no flush/straight with 4 cards)
##   AC7  — 4 cards same suit → NOT a Flush (requires exactly 5)
##   AC8  — All 10 ranks: canonical examples return correct rank, chips, mult
##   AC9  — No rank base values hardcoded in hand_evaluator.gd (loaded from config)
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script reference ──────────────────────────────────────────────────────────

const HandEvaluatorScript = preload("res://src/systems/combat/hand_evaluator.gd")

# ── Card factory ──────────────────────────────────────────────────────────────

## Creates a minimal card Dictionary.
## suit: 0=Hearts(Fire), 1=Diamonds(Water), 2=Clubs(Earth), 3=Spades(Lightning)
func _card(value: int, suit: int) -> Dictionary:
	return { "value": value, "suit": suit, "element": "", "enhancement": "" }


## Builds an Array[Dictionary] of cards from compact (value, suit) pairs.
func _hand(pairs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pair in pairs:
		result.append(_card(pair[0], pair[1]))
	return result

# ── AC1 — Pair of 7s ──────────────────────────────────────────────────────────

func test_hand_evaluation_pair_of_sevens_returns_pair() -> void:
	# Arrange — 7H 7D 9C 5S 3H
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[9,2],[5,3],[3,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Pair")
	assert_int(result["base_chips"]).is_equal(10)
	assert_float(result["base_mult"]).is_equal(2.0)

# ── AC2 — Three of a Kind ─────────────────────────────────────────────────────

func test_hand_evaluation_three_of_a_kind_returns_correct_rank() -> void:
	# Arrange — 7H 7D 7C 5S 3H
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[7,2],[5,3],[3,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Three of a Kind")
	assert_int(result["base_chips"]).is_equal(30)
	assert_float(result["base_mult"]).is_equal(3.0)

# ── AC3 — Royal Flush ─────────────────────────────────────────────────────────

func test_hand_evaluation_royal_flush_ace_high_same_suit() -> void:
	# Arrange — AH KH QH JH 10H  (all Hearts, suit 0)
	var cards: Array[Dictionary] = _hand([[14,0],[13,0],[12,0],[11,0],[10,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Royal Flush")
	assert_int(result["base_chips"]).is_equal(100)
	assert_float(result["base_mult"]).is_equal(8.0)

# ── AC4 — Wheel Straight Flush (A-2-3-4-5 same suit) ─────────────────────────

func test_hand_evaluation_wheel_straight_flush_is_straight_flush() -> void:
	# Arrange — AH 2H 3H 4H 5H  (all Hearts, suit 0)
	var cards: Array[Dictionary] = _hand([[14,0],[2,0],[3,0],[4,0],[5,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert — wheel SF is Straight Flush, NOT Royal Flush
	assert_str(result["rank"]).is_equal("Straight Flush")
	assert_int(result["base_chips"]).is_equal(100)
	assert_float(result["base_mult"]).is_equal(8.0)

# ── AC5 — Wheel Straight off-suit (A-2-3-4-5) ────────────────────────────────

func test_hand_evaluation_wheel_straight_off_suit_is_straight() -> void:
	# Arrange — AH 2D 3C 4S 5H  (mixed suits)
	var cards: Array[Dictionary] = _hand([[14,0],[2,1],[3,2],[4,3],[5,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Straight")
	assert_int(result["base_chips"]).is_equal(30)
	assert_float(result["base_mult"]).is_equal(4.0)

# ── AC6 — 4-card Three of a Kind (no flush/straight) ─────────────────────────

func test_hand_evaluation_four_cards_three_of_a_kind_not_flush() -> void:
	# Arrange — 7H 7D 7C 5S  (only 4 cards — no flush or straight possible)
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[7,2],[5,3]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Three of a Kind")

# ── AC7 — 4 same-suit cards are NOT a Flush ───────────────────────────────────

func test_hand_evaluation_four_same_suit_is_not_flush() -> void:
	# Arrange — 7H 9H KH 2H  (4 Hearts, not 5)
	var cards: Array[Dictionary] = _hand([[7,0],[9,0],[13,0],[2,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert — must NOT be Flush
	assert_str(result["rank"]).is_not_equal("Flush")

# ── AC8 — All 10 ranks: canonical examples ────────────────────────────────────

func test_hand_evaluation_high_card_canonical() -> void:
	# Arrange — 2H 5D 9C JH KS  (no pattern)
	var cards: Array[Dictionary] = _hand([[2,0],[5,1],[9,2],[11,0],[13,3]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("High Card")
	assert_int(result["base_chips"]).is_equal(5)
	assert_float(result["base_mult"]).is_equal(1.0)


func test_hand_evaluation_two_pair_canonical() -> void:
	# Arrange — 7H 7D 9C 9S 3H
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[9,2],[9,3],[3,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Two Pair")
	assert_int(result["base_chips"]).is_equal(20)
	assert_float(result["base_mult"]).is_equal(2.0)


func test_hand_evaluation_straight_canonical() -> void:
	# Arrange — 5H 6D 7C 8S 9H  (off-suit straight)
	var cards: Array[Dictionary] = _hand([[5,0],[6,1],[7,2],[8,3],[9,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Straight")
	assert_int(result["base_chips"]).is_equal(30)
	assert_float(result["base_mult"]).is_equal(4.0)


func test_hand_evaluation_flush_canonical() -> void:
	# Arrange — 2H 5H 9H JH KH  (all Hearts, no straight)
	var cards: Array[Dictionary] = _hand([[2,0],[5,0],[9,0],[11,0],[13,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Flush")
	assert_int(result["base_chips"]).is_equal(35)
	assert_float(result["base_mult"]).is_equal(4.0)


func test_hand_evaluation_full_house_canonical() -> void:
	# Arrange — 7H 7D 7C 9S 9H
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[7,2],[9,3],[9,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Full House")
	assert_int(result["base_chips"]).is_equal(40)
	assert_float(result["base_mult"]).is_equal(4.0)


func test_hand_evaluation_four_of_a_kind_canonical() -> void:
	# Arrange — 7H 7D 7C 7S 9H
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[7,2],[7,3],[9,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Four of a Kind")
	assert_int(result["base_chips"]).is_equal(60)
	assert_float(result["base_mult"]).is_equal(7.0)


func test_hand_evaluation_straight_flush_canonical() -> void:
	# Arrange — 5H 6H 7H 8H 9H  (all Hearts, consecutive)
	var cards: Array[Dictionary] = _hand([[5,0],[6,0],[7,0],[8,0],[9,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("Straight Flush")
	assert_int(result["base_chips"]).is_equal(100)
	assert_float(result["base_mult"]).is_equal(8.0)

# ── AC9 — Config-driven: evaluate() uses loaded values ───────────────────────

func test_hand_evaluation_base_values_loaded_from_config_not_hardcoded() -> void:
	# Arrange — call evaluate to trigger config load, then check cached config
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[9,2],[5,3],[3,0]])
	HandEvaluatorScript.evaluate(cards)

	# Assert — config dictionary is non-empty (was loaded from file)
	assert_bool(HandEvaluatorScript._hand_ranks_config.is_empty()).is_false()


func test_hand_evaluation_pair_base_chips_from_config_equals_10() -> void:
	# Arrange — force config load
	var cards: Array[Dictionary] = _hand([[7,0],[7,1],[9,2],[5,3],[3,0]])
	HandEvaluatorScript.evaluate(cards)

	# Act — read Pair entry directly from loaded config
	var pair_data: Dictionary = HandEvaluatorScript._hand_ranks_config.get("Pair", {})

	# Assert — confirms config was loaded and value matches ADR spec
	assert_int(pair_data.get("base_chips", -1)).is_equal(10)

# ── Edge cases ────────────────────────────────────────────────────────────────

func test_hand_evaluation_empty_hand_returns_high_card() -> void:
	# Arrange
	var cards: Array[Dictionary] = []

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("High Card")


func test_hand_evaluation_single_card_returns_high_card() -> void:
	# Arrange
	var cards: Array[Dictionary] = _hand([[14,0]])  # Ace of Hearts

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert
	assert_str(result["rank"]).is_equal("High Card")


func test_hand_evaluation_four_of_a_kind_not_full_house_or_pair() -> void:
	# Arrange — four 9s + one 5
	var cards: Array[Dictionary] = _hand([[9,0],[9,1],[9,2],[9,3],[5,0]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert — must be Four of a Kind, not Full House
	assert_str(result["rank"]).is_equal("Four of a Kind")


func test_hand_evaluation_royal_flush_not_classified_as_straight_flush() -> void:
	# Arrange — Royal: 10-J-Q-K-A all Spades
	var cards: Array[Dictionary] = _hand([[10,3],[11,3],[12,3],[13,3],[14,3]])

	# Act
	var result: Dictionary = HandEvaluatorScript.evaluate(cards)

	# Assert — must be Royal Flush specifically
	assert_str(result["rank"]).is_equal("Royal Flush")

# ── get_card_chips ────────────────────────────────────────────────────────────

func test_hand_evaluation_card_chips_ace_returns_11() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(14)).is_equal(11)


func test_hand_evaluation_card_chips_jack_returns_10() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(11)).is_equal(10)


func test_hand_evaluation_card_chips_queen_returns_10() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(12)).is_equal(10)


func test_hand_evaluation_card_chips_king_returns_10() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(13)).is_equal(10)


func test_hand_evaluation_card_chips_two_through_ten_equals_face() -> void:
	for v: int in range(2, 11):
		assert_int(HandEvaluatorScript.get_card_chips(v)).is_equal(v)
