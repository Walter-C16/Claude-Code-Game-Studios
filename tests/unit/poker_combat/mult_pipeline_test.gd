class_name MultPipelineTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-004: Scoring Pipeline — Mult Calculation and Final Score
##
## Covers:
##   AC1 — Pair (base_mult=2.0), no enhancements, no captain → additive=2.0, final=2.0
##   AC2 — One Holographic card → +10 to additive mult
##   AC3 — Two Polychrome cards → 1.5 x 1.5 = 2.25 factor applied after additive clamp
##   AC4 — Captain Atenea (INT=19) → captain_mult_modifier = 1.0 + (19*0.025) = 1.475
##   AC5 — All additive sources sum to 0.5 (below minimum) → clamped to 1.0
##   AC6 — chips=258, mult=7.9625 → floor(258 * 7.9625) = 2054
##   AC7 — Very large score (chips=10000, mult=1000.0) → no overflow
##   AC8 — chips=41, final_mult=2.0 → score = 82
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script references ─────────────────────────────────────────────────────────

const ScoreCalculatorScript = preload("res://src/systems/combat/score_calculator.gd")
const HandEvaluatorScript   = preload("res://src/systems/combat/hand_evaluator.gd")

# ── Card factory ──────────────────────────────────────────────────────────────

## Creates a card with given value, suit, element, and optional enhancement.
func _card(value: int, suit: int, element: String, enhancement: String = "") -> Dictionary:
	return {
		"value":       value,
		"suit":        suit,
		"element":     element,
		"enhancement": enhancement,
	}

# ── AC1 — Pair baseline: no bonuses ──────────────────────────────────────────

func test_mult_pipeline_pair_no_bonuses_additive_and_final_equal_2() -> void:
	# Arrange — Pair base_mult=2.0, no enhancements, no captain, no buffs
	var cards: Array[Dictionary] = [
		_card(7, 0, "Fire"),
		_card(7, 1, "Water"),
		_card(9, 2, "Earth"),
		_card(5, 3, "Lightning"),
		_card(3, 0, "Fire"),
	]
	var hand_rank: Dictionary = HandEvaluatorScript.evaluate(cards)
	var context: Dictionary = {}

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_str(hand_rank["rank"]).is_equal("Pair")
	assert_float(final_mult).is_equal_approx(2.0, 0.0001)

# ── AC2 — Holographic card adds +10 to additive mult ─────────────────────────

func test_mult_pipeline_holographic_card_adds_10_additive_mult() -> void:
	# Arrange — High Card base_mult=1.0, one Holo card → additive = 1.0 + 10.0 = 11.0
	# No Poly, no captain → final = 11.0
	var cards_no_holo: Array[Dictionary] = [_card(7, 0, "Fire")]
	var cards_with_holo: Array[Dictionary] = [_card(7, 0, "Fire", "Holographic")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var mult_no_holo: float = ScoreCalculatorScript.calculate_mult(
			cards_no_holo, hand_rank, context)
	var mult_with_holo: float = ScoreCalculatorScript.calculate_mult(
			cards_with_holo, hand_rank, context)

	# Assert — difference must be exactly 10.0
	assert_float(mult_with_holo - mult_no_holo).is_equal_approx(10.0, 0.0001)


func test_mult_pipeline_holographic_card_total_is_11() -> void:
	# Arrange — base_mult=1.0, one Holo → additive = 11.0, final = 11.0
	var cards: Array[Dictionary] = [_card(7, 0, "Fire", "Holographic")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(final_mult).is_equal_approx(11.0, 0.0001)

# ── AC3 — Two Polychrome cards: 1.5 x 1.5 = 2.25 factor ─────────────────────

func test_mult_pipeline_two_polychrome_cards_apply_225_factor() -> void:
	# Arrange — High Card base_mult=1.0 (additive = 1.0 after clamp)
	# Two Poly cards → 1.0 * 1.5 * 1.5 = 2.25
	var cards: Array[Dictionary] = [
		_card(7, 0, "Fire", "Polychrome"),
		_card(8, 1, "Water", "Polychrome"),
	]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — 1.0 * 2.25 = 2.25
	assert_float(final_mult).is_equal_approx(2.25, 0.0001)


func test_mult_pipeline_two_polychrome_factor_applied_after_additive_clamp() -> void:
	# Arrange — base_mult=2.0, two Poly cards → 2.0 * 1.5 * 1.5 = 4.5
	var cards: Array[Dictionary] = [
		_card(7, 0, "Fire", "Polychrome"),
		_card(7, 1, "Water", "Polychrome"),
	]
	var hand_rank: Dictionary = { "base_chips": 10, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {}

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(final_mult).is_equal_approx(4.5, 0.0001)

# ── AC4 — Captain Atenea (INT=19): captain_mult_modifier = 1.475 ──────────────

func test_mult_pipeline_captain_atenea_int19_modifier_is_1_475() -> void:
	# Arrange — High Card base_mult=1.0, captain_mult_modifier=1.475
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var captain_mult: float = 1.0 + (19.0 * 0.025)  # = 1.475
	var context: Dictionary = { "captain_mult_modifier": captain_mult }

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — 1.0 (additive) * 1.0 (no poly) * 1.475 = 1.475
	assert_float(captain_mult).is_equal_approx(1.475, 0.0001)
	assert_float(final_mult).is_equal_approx(1.475, 0.0001)

# ── AC5 — Additive mult below 1.0 clamped to 1.0 ─────────────────────────────

func test_mult_pipeline_additive_below_minimum_clamped_to_1() -> void:
	# Arrange — inject hand_rank with base_mult=0.3 (below minimum of 1.0)
	# No other sources → additive = 0.3, clamped to 1.0 → final = 1.0
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 0.3, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(final_mult).is_equal_approx(1.0, 0.0001)


func test_mult_pipeline_additive_zero_clamped_to_1() -> void:
	# Arrange — base_mult=0.0 → clamped to 1.0
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 0.0, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var final_mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(final_mult).is_equal_approx(1.0, 0.0001)

# ── AC6 — floor(258 * 7.9625) = 2054 ─────────────────────────────────────────

func test_mult_pipeline_final_score_floor_258_chips_7_9625_mult() -> void:
	# Arrange — score from chips and mult
	var chips: int = 258
	var mult: float = 7.9625

	# Act
	var score: int = ScoreCalculatorScript.calculate_score(chips, mult)

	# Assert — floor(258 * 7.9625) = floor(2054.325) = 2054
	assert_int(score).is_equal(2054)

# ── AC7 — Large score does not overflow ───────────────────────────────────────

func test_mult_pipeline_large_score_no_overflow() -> void:
	# Arrange — chips=10000, mult=1000.0 → score=10_000_000
	var chips: int = 10000
	var mult: float = 1000.0

	# Act
	var score: int = ScoreCalculatorScript.calculate_score(chips, mult)

	# Assert — result must be exactly 10_000_000 (no overflow or truncation)
	assert_int(score).is_equal(10000000)


func test_mult_pipeline_very_large_score_no_overflow() -> void:
	# Arrange — near the top of typical Abyss scores: chips=50000, mult=5000.0
	# Expected: floor(50000 * 5000.0) = 250_000_000
	var chips: int = 50000
	var mult: float = 5000.0

	# Act
	var score: int = ScoreCalculatorScript.calculate_score(chips, mult)

	# Assert
	assert_int(score).is_equal(250000000)

# ── AC8 — Pair of 7s: chips=41, mult=2.0 → score=82 ─────────────────────────

func test_mult_pipeline_pair_of_sevens_chips41_mult2_score_is_82() -> void:
	# Arrange — Pair of 7s (chips=41 from COMBAT-003 baseline, mult=2.0)
	var chips: int = 41
	var mult: float = 2.0

	# Act
	var score: int = ScoreCalculatorScript.calculate_score(chips, mult)

	# Assert
	assert_int(score).is_equal(82)

# ── Integration: calculate_mult + calculate_score round-trip ─────────────────

func test_mult_pipeline_full_round_trip_pair_no_bonuses() -> void:
	# Arrange — Pair of 7s, no bonuses
	# chips=41 (from COMBAT-003), mult pipeline = 2.0 → score = 82
	var cards: Array[Dictionary] = [
		_card(7, 0, "Fire"),
		_card(7, 1, "Water"),
		_card(9, 2, "Earth"),
		_card(5, 3, "Lightning"),
		_card(3, 0, "Fire"),
	]
	var hand_rank: Dictionary = HandEvaluatorScript.evaluate(cards)
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)
	var score: int = ScoreCalculatorScript.calculate_score(chips, mult)

	# Assert
	assert_int(chips).is_equal(41)
	assert_float(mult).is_equal_approx(2.0, 0.0001)
	assert_int(score).is_equal(82)
