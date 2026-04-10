class_name ChipsPipelineTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-003: Scoring Pipeline — Chips Calculation
##
## Covers:
##   AC1 — Pair of 7s (base=10, per-card 7+7+9+5+3=31) → total=41
##   AC2 — Flush with one Foil card → Foil contributes exactly +50
##   AC3 — Ace (value=14) → get_card_chips returns 11
##   AC4 — J(11), Q(12), K(13) → each returns 10
##   AC5 — Chips go negative due to element resistance → clamped to 1
##   AC6 — social_buff_chips=20 added at end of additive phase
##   AC7 — blessing_chips=30 included at correct pipeline position
##   AC8 — captain Hipolita (STR=20) → captain_chip_bonus = floor(20*0.5) = 10
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

# ── AC1 — Pair of 7s baseline ─────────────────────────────────────────────────

func test_chips_pipeline_pair_of_sevens_base_plus_per_card_equals_41() -> void:
	# Arrange — 7H(7) 7D(7) 9C(9) 5S(5) 3H(3) → per-card total = 31
	# Pair base = 10 → 10 + 31 = 41
	var cards: Array[Dictionary] = [
		_card(7,  0, "Fire"),
		_card(7,  1, "Water"),
		_card(9,  2, "Earth"),
		_card(5,  3, "Lightning"),
		_card(3,  0, "Fire"),
	]
	var hand_rank: Dictionary = HandEvaluatorScript.evaluate(cards)
	var context: Dictionary = {}

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_str(hand_rank["rank"]).is_equal("Pair")
	assert_int(total).is_equal(41)

# ── AC2 — Foil card adds exactly +50 ─────────────────────────────────────────

func test_chips_pipeline_foil_card_adds_50_chips() -> void:
	# Arrange — Flush (base=35). Cards: 2H 5H 9H JH KH, one Foil
	# Without Foil: 35 + (2+5+9+10+10) = 35+36 = 71
	# With Foil on 2H: 71 + 50 = 121
	var cards_no_foil: Array[Dictionary] = [
		_card(2,  0, "Fire"),
		_card(5,  0, "Fire"),
		_card(9,  0, "Fire"),
		_card(11, 0, "Fire"),
		_card(13, 0, "Fire"),
	]
	var cards_with_foil: Array[Dictionary] = [
		_card(2,  0, "Fire", "Foil"),
		_card(5,  0, "Fire"),
		_card(9,  0, "Fire"),
		_card(11, 0, "Fire"),
		_card(13, 0, "Fire"),
	]
	var hand_rank: Dictionary = HandEvaluatorScript.evaluate(cards_no_foil)
	var context: Dictionary = {}

	# Act
	var chips_no_foil: int = ScoreCalculatorScript.calculate_chips(
			cards_no_foil, hand_rank, context)
	var chips_with_foil: int = ScoreCalculatorScript.calculate_chips(
			cards_with_foil, hand_rank, context)

	# Assert
	assert_str(hand_rank["rank"]).is_equal("Flush")
	assert_int(chips_with_foil - chips_no_foil).is_equal(50)

# ── AC3 — Ace chip value = 11 ─────────────────────────────────────────────────

func test_chips_pipeline_ace_value_14_returns_11_chips() -> void:
	# Arrange / Act
	var chips: int = HandEvaluatorScript.get_card_chips(14)

	# Assert
	assert_int(chips).is_equal(11)

# ── AC4 — J/Q/K each return 10 chips ─────────────────────────────────────────

func test_chips_pipeline_jack_returns_10_chips() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(11)).is_equal(10)


func test_chips_pipeline_queen_returns_10_chips() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(12)).is_equal(10)


func test_chips_pipeline_king_returns_10_chips() -> void:
	assert_int(HandEvaluatorScript.get_card_chips(13)).is_equal(10)

# ── AC5 — Negative chips clamped to 1 ────────────────────────────────────────

func test_chips_pipeline_negative_chips_clamped_to_1() -> void:
	# Arrange — High Card base=5. One card value 2 (chip=2). Enemy element Earth.
	# 5 cards all Earth (resist) vs Earth enemy: each -15 chips.
	# base=5, per-card chips: 2+3+4+5+6=20, resist: 5*(-15)=-75
	# total = 5 + 20 - 75 = -50 → clamped to 1
	var cards: Array[Dictionary] = [
		_card(2,  2, "Earth"),
		_card(3,  2, "Earth"),
		_card(4,  2, "Earth"),
		_card(5,  2, "Earth"),
		_card(6,  2, "Earth"),
	]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — must be clamped to 1
	assert_int(total).is_equal(1)

# ── AC6 — social_buff_chips added at end of additive phase ───────────────────

func test_chips_pipeline_social_buff_chips_added_to_total() -> void:
	# Arrange — Pair of 7s (base=10, per-card=31 → no-buff total=41)
	var cards: Array[Dictionary] = [
		_card(7, 0, "Fire"),
		_card(7, 1, "Water"),
		_card(9, 2, "Earth"),
		_card(5, 3, "Lightning"),
		_card(3, 0, "Fire"),
	]
	var hand_rank: Dictionary = HandEvaluatorScript.evaluate(cards)
	var context_no_buff: Dictionary = {}
	var context_with_buff: Dictionary = { "social_buff_chips": 20 }

	# Act
	var chips_no_buff: int = ScoreCalculatorScript.calculate_chips(
			cards, hand_rank, context_no_buff)
	var chips_with_buff: int = ScoreCalculatorScript.calculate_chips(
			cards, hand_rank, context_with_buff)

	# Assert — difference must be exactly 20
	assert_int(chips_with_buff - chips_no_buff).is_equal(20)


func test_chips_pipeline_social_buff_chips_20_from_game_store() -> void:
	# Arrange — simple High Card, social_buff_chips=20
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "social_buff_chips": 20 }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — 5 (base) + 7 (card) + 20 (social) = 32
	assert_int(total).is_equal(32)

# ── AC7 — blessing_chips included at correct pipeline position ────────────────

func test_chips_pipeline_blessing_chips_30_added_to_total() -> void:
	# Arrange — High Card base=5, one card value=7 (chips=7), blessing_chips=30
	# Expected: 5 + 7 + 30 = 42
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "blessing_chips": 30 }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(total).is_equal(42)


func test_chips_pipeline_blessing_chips_zero_does_not_change_total() -> void:
	# Arrange — Pair of 7s, blessing_chips=0 → should equal baseline of 41
	var cards: Array[Dictionary] = [
		_card(7, 0, "Fire"),
		_card(7, 1, "Water"),
		_card(9, 2, "Earth"),
		_card(5, 3, "Lightning"),
		_card(3, 0, "Fire"),
	]
	var hand_rank: Dictionary = HandEvaluatorScript.evaluate(cards)
	var context: Dictionary = { "blessing_chips": 0 }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(total).is_equal(41)

# ── AC8 — Captain chip bonus: floor(STR * 0.5) ───────────────────────────────

func test_chips_pipeline_captain_hipolita_str20_bonus_is_10() -> void:
	# Arrange — Hipolita STR=20 → floor(20 * 0.5) = 10
	# High Card base=5, one card value=7 (chips=7), captain_chip_bonus=10
	# Expected: 5 + 7 + 10 = 22
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = {
		"captain_chip_bonus": floori(20.0 * 0.5),  # = 10
	}

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(context["captain_chip_bonus"]).is_equal(10)
	assert_int(total).is_equal(22)


func test_chips_pipeline_captain_chip_bonus_floor_formula() -> void:
	# Arrange — validate floor(STR * 0.5) for several STR values
	var cases: Array = [
		[17, 8],   # floor(17*0.5) = 8 (Artemisa)
		[20, 10],  # floor(20*0.5) = 10 (Hipolita)
		[18, 9],   # floor(18*0.5) = 9 (Nyx)
		[19, 9],   # floor(19*0.5) = 9
		[0,  0],   # no captain
	]
	for c in cases:
		var str_val: int = c[0]
		var expected: int = c[1]
		var bonus: int = floori(str_val * 0.5)
		assert_int(bonus).is_equal(expected)

# ── Combined pipeline example ─────────────────────────────────────────────────

func test_chips_pipeline_all_sources_combined() -> void:
	# Arrange — verify all sources sum correctly in one call
	# High Card base=5, one Fire card value=7 (chips=7)
	# Enemy=Earth, Fire beats Earth → +25
	# Foil on card → +50
	# blessing=10, captain_bonus=5, social=3
	# Total before clamp: 5 + 7 + 50 + 10 + 25 + 5 + 3 = 105
	var cards: Array[Dictionary] = [_card(7, 0, "Fire", "Foil")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = {
		"enemy_element":     "Earth",
		"blessing_chips":    10,
		"captain_chip_bonus": 5,
		"social_buff_chips":  3,
	}

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(total).is_equal(105)

# ── Element interactions ──────────────────────────────────────────────────────

func test_chips_pipeline_element_none_disables_interactions() -> void:
	# Arrange — Fire card, enemy element = "None" → no bonus
	# base=5, card chips=7 → 12 with no element bonus
	var cards: Array[Dictionary] = [_card(7, 0, "Fire")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "None" }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(total).is_equal(12)


func test_chips_pipeline_element_weak_adds_25_per_card() -> void:
	# Arrange — 3 Fire cards vs Earth enemy (weak to Fire) → +25 each = +75
	# base=5 (High Card), per-card: 2+3+4=9, element: +75 → total=89
	var cards: Array[Dictionary] = [
		_card(2, 0, "Fire"),
		_card(3, 0, "Fire"),
		_card(4, 0, "Fire"),
	]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(total).is_equal(89)


func test_chips_pipeline_element_resist_subtracts_15_per_card() -> void:
	# Arrange — 2 Earth cards vs Earth enemy (resist) → -15 each = -30
	# base=5, per-card: 2+3=5, resist: -30 → total=-20 → clamped to 1
	var cards: Array[Dictionary] = [
		_card(2, 2, "Earth"),
		_card(3, 2, "Earth"),
	]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var total: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — 5+5-30 = -20, clamped to 1
	assert_int(total).is_equal(1)
