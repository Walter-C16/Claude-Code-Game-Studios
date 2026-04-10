class_name CardEnhancementsTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-006: Card Enhancement Effects — Foil, Holo, Polychrome
##
## Covers:
##   AC1 — Foil: +50 chips per card (chips additive phase)
##   AC2 — Holographic: +10 additive mult per card
##   AC3 — Polychrome: x1.5 multiplicative per card (after additive clamp)
##   AC4 — 3 Polychrome cards → factor = 1.5^3 = 3.375
##   AC5 — No enhancement (null / "None") → no bonus applied
##   AC6 — One enhancement per card enforced (Foil card cannot have Holographic)
##   AC7 — Foil + Holo + Poly in same hand → each phase correct, independent
##
## Additional: 5 Polychrome = 1.5^5 = 7.59375 (ADR-0007 Risks section)
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script references ─────────────────────────────────────────────────────────

const ScoreCalculatorScript = preload("res://src/systems/combat/score_calculator.gd")

# ── Card factory ──────────────────────────────────────────────────────────────

## Creates a card with value, suit, element, and optional enhancement.
func _card(value: int, element: String = "Fire", enhancement: String = "") -> Dictionary:
	return {
		"value":       value,
		"suit":        0,
		"element":     element,
		"enhancement": enhancement,
	}

## A hand_rank with base_chips=5, base_mult=1.0 for isolation testing.
func _base_rank() -> Dictionary:
	return { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }

# ── AC1 — Foil adds exactly +50 chips per card ───────────────────────────────

func test_card_enhancement_foil_adds_50_chips() -> void:
	# Arrange — one card with Foil vs one without
	# base=5, per-card=7 → without Foil: 12; with Foil: 62
	var cards_no_foil: Array[Dictionary] = [_card(7)]
	var cards_with_foil: Array[Dictionary] = [_card(7, "Fire", "Foil")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var chips_base: int = ScoreCalculatorScript.calculate_chips(
			cards_no_foil, hand_rank, context)
	var chips_foil: int = ScoreCalculatorScript.calculate_chips(
			cards_with_foil, hand_rank, context)

	# Assert — delta must be exactly 50
	assert_int(chips_foil - chips_base).is_equal(50)


func test_card_enhancement_foil_multiple_cards_stacks() -> void:
	# Arrange — 2 Foil cards → +100 chips total from Foil
	# base=5, per-card=7+7=14, foil=100 → total=119
	var cards: Array[Dictionary] = [
		_card(7, "Fire", "Foil"),
		_card(7, "Fire", "Foil"),
	]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(119)

# ── AC2 — Holographic adds +10 additive mult per card ───────────────────────

func test_card_enhancement_holographic_adds_10_mult() -> void:
	# Arrange — base_mult=1.0, one Holo card → additive = 1.0 + 10.0 = 11.0
	var cards: Array[Dictionary] = [_card(7, "Fire", "Holographic")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(11.0, 0.0001)


func test_card_enhancement_two_holographic_cards_add_20_mult() -> void:
	# Arrange — base_mult=2.0, two Holo cards → additive = 2.0 + 20.0 = 22.0
	var cards: Array[Dictionary] = [
		_card(7, "Fire", "Holographic"),
		_card(8, "Fire", "Holographic"),
	]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(22.0, 0.0001)

# ── AC3 — Polychrome: x1.5 after additive clamp ──────────────────────────────

func test_card_enhancement_polychrome_single_card_x15_factor() -> void:
	# Arrange — base_mult=2.0 (additive=2.0), one Poly → 2.0 * 1.5 = 3.0
	var cards: Array[Dictionary] = [_card(7, "Fire", "Polychrome")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(3.0, 0.0001)


func test_card_enhancement_polychrome_applied_after_additive_clamp() -> void:
	# Arrange — base_mult=0.5 (below min 1.0) → clamped to 1.0, then *1.5 = 1.5
	var cards: Array[Dictionary] = [_card(7, "Fire", "Polychrome")]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 0.5, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — clamp to 1.0 first, then multiply: 1.0 * 1.5 = 1.5
	assert_float(mult).is_equal_approx(1.5, 0.0001)

# ── AC4 — 3 Polychrome cards → 1.5^3 = 3.375 ────────────────────────────────

func test_card_enhancement_three_polychrome_factor_is_3_375() -> void:
	# Arrange — base_mult=1.0, 3 Poly cards → 1.0 * 1.5^3 = 3.375
	var cards: Array[Dictionary] = [
		_card(7, "Fire", "Polychrome"),
		_card(8, "Fire", "Polychrome"),
		_card(9, "Fire", "Polychrome"),
	]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — 1.5^3 = 3.375
	assert_float(mult).is_equal_approx(3.375, 0.0001)

# ── 5 Polychrome = 1.5^5 = 7.59375 (ADR-0007 risk note) ─────────────────────

func test_card_enhancement_five_polychrome_factor_is_7_59375() -> void:
	# Arrange — base_mult=1.0, 5 Poly cards → 1.0 * 1.5^5 = 7.59375
	var cards: Array[Dictionary] = [
		_card(7, "Fire", "Polychrome"),
		_card(8, "Fire", "Polychrome"),
		_card(9, "Fire", "Polychrome"),
		_card(10, "Fire", "Polychrome"),
		_card(11, "Fire", "Polychrome"),
	]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(7.59375, 0.0001)

# ── AC5 — No enhancement → no bonus ─────────────────────────────────────────

func test_card_enhancement_no_enhancement_empty_string_no_bonus_chips() -> void:
	# Arrange — card with enhancement="" → no bonus
	# base=5, per-card=7 → total=12
	var cards: Array[Dictionary] = [_card(7, "Fire", "")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(12)


func test_card_enhancement_no_enhancement_empty_string_no_bonus_mult() -> void:
	# Arrange — card with enhancement="" → base_mult=1.0 unchanged
	var cards: Array[Dictionary] = [_card(7, "Fire", "")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(1.0, 0.0001)


func test_card_enhancement_none_enhancement_no_bonus() -> void:
	# Arrange — card with enhancement="None" → treated as no enhancement
	var cards: Array[Dictionary] = [_card(7, "Fire", "None")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — no bonus applied
	assert_int(chips).is_equal(12)
	assert_float(mult).is_equal_approx(1.0, 0.0001)

# ── AC6 — One enhancement per card (schema enforcement) ──────────────────────

func test_card_enhancement_foil_card_cannot_have_holographic() -> void:
	# This tests the schema contract: a card carrying "Foil" applies only
	# the Foil chip bonus; it does NOT accidentally also apply Holographic.
	# We verify: Foil is in chips, Holo is in mult. A "Foil" card adds +50
	# chips but adds NO holo mult bonus.

	var foil_card: Array[Dictionary] = [_card(7, "Fire", "Foil")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(foil_card, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(foil_card, hand_rank, context)

	# Assert — Foil card contributes chips bonus (5+7+50=62) but NOT holo mult
	assert_int(chips).is_equal(62)
	# Mult = base 1.0 only (no holo, no poly)
	assert_float(mult).is_equal_approx(1.0, 0.0001)


func test_card_enhancement_holographic_card_adds_no_chip_bonus() -> void:
	# Holo card contributes to mult, not chips
	var holo_card: Array[Dictionary] = [_card(7, "Fire", "Holographic")]
	var hand_rank: Dictionary = _base_rank()
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(holo_card, hand_rank, context)

	# Assert — no extra chips from Holo (only foil adds chips; holo adds mult)
	assert_int(chips).is_equal(12)

# ── AC7 — Foil + Holo + Poly in same hand, each phase independent ────────────

func test_card_enhancement_foil_holo_poly_each_apply_at_correct_phase() -> void:
	# Arrange:
	#   Foil card (value=7):       chips += 50
	#   Holo card (value=8):       mult additive += 10
	#   Poly card (value=9):       mult multiplicative *= 1.5
	#
	# Chips: base=5, per-card=7+8+9=24, foil=+50 → total=79
	# Mult:  base_mult=2.0, holo=+10 → additive=12.0 → *1.5 (poly) = 18.0
	var cards: Array[Dictionary] = [
		_card(7, "Fire", "Foil"),
		_card(8, "Fire", "Holographic"),
		_card(9, "Fire", "Polychrome"),
	]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)
	var score: int = ScoreCalculatorScript.calculate_score(chips, mult)

	# Assert chips
	assert_int(chips).is_equal(79)
	# Assert mult — (2.0 + 10.0) * 1.5 = 18.0
	assert_float(mult).is_equal_approx(18.0, 0.0001)
	# Assert score — floor(79 * 18.0) = 1422
	assert_int(score).is_equal(1422)
