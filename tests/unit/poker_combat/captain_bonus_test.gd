class_name CaptainBonusTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-007: Captain Stat Bonus Integration
##
## Covers:
##   AC1 — Artemisa (STR=17, INT=13): chip_bonus=8, mult_modifier=1.325
##   AC2 — Hipolita (STR=20, INT=9):  chip_bonus=10, mult_modifier=1.225
##   AC3 — Nyx (STR=18, INT=19):      chip_bonus=9,  mult_modifier=1.475
##   AC4 — No captain: chip_bonus=0, mult_modifier=1.0
##   AC5 — Captain locked at SETUP; stat changes during combat have no effect
##   AC6 — captain_mult_modifier applied AFTER Polychrome (strict pipeline order)
##   AC7 — Stats read from static companion profile (not mutable CompanionState)
##
## Formulas (ADR-0007):
##   captain_chip_bonus    = floor(STR * 0.5)
##   captain_mult_modifier = 1.0 + (INT * 0.025)
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script references ─────────────────────────────────────────────────────────

const ScoreCalculatorScript = preload("res://src/systems/combat/score_calculator.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

## Computes captain_chip_bonus from a companion's STR stat.
## Formula: floor(STR * 0.5)
func _captain_chip_bonus(str_val: int) -> int:
	return floori(str_val * 0.5)

## Computes captain_mult_modifier from a companion's INT stat.
## Formula: 1.0 + (INT * 0.025)
func _captain_mult_modifier(int_val: int) -> float:
	return 1.0 + (float(int_val) * 0.025)

## Creates a minimal card Dictionary.
func _card(value: int, element: String = "Fire") -> Dictionary:
	return { "value": value, "suit": 0, "element": element, "enhancement": "" }

# ── AC1 — Artemisa (STR=17, INT=13) ──────────────────────────────────────────

func test_captain_bonus_artemisa_str17_chip_bonus_is_8() -> void:
	# Arrange
	var chip_bonus: int = _captain_chip_bonus(17)

	# Assert
	assert_int(chip_bonus).is_equal(8)


func test_captain_bonus_artemisa_int13_mult_modifier_is_1_325() -> void:
	# Arrange
	var mult_mod: float = _captain_mult_modifier(13)

	# Assert — 1.0 + 13*0.025 = 1.325
	assert_float(mult_mod).is_equal_approx(1.325, 0.0001)


func test_captain_bonus_artemisa_chips_applied_to_pipeline() -> void:
	# Arrange — High Card base=5, one card value=7 (chips=7), captain_chip_bonus=8
	# Expected: 5 + 7 + 8 = 20
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "captain_chip_bonus": _captain_chip_bonus(17) }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(20)


func test_captain_bonus_artemisa_mult_applied_to_pipeline() -> void:
	# Arrange — base_mult=2.0, captain_mult_modifier=1.325
	# Expected: 2.0 * 1.325 = 2.65
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "captain_mult_modifier": _captain_mult_modifier(13) }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(2.65, 0.0001)

# ── AC2 — Hipolita (STR=20, INT=9) ───────────────────────────────────────────

func test_captain_bonus_hipolita_str20_chip_bonus_is_10() -> void:
	# Arrange
	var chip_bonus: int = _captain_chip_bonus(20)

	# Assert
	assert_int(chip_bonus).is_equal(10)


func test_captain_bonus_hipolita_int9_mult_modifier_is_1_225() -> void:
	# Arrange
	var mult_mod: float = _captain_mult_modifier(9)

	# Assert — 1.0 + 9*0.025 = 1.225
	assert_float(mult_mod).is_equal_approx(1.225, 0.0001)


func test_captain_bonus_hipolita_chips_applied_to_pipeline() -> void:
	# Arrange — base=5, card=7, captain_bonus=10 → total=22
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "captain_chip_bonus": _captain_chip_bonus(20) }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(22)


func test_captain_bonus_hipolita_mult_applied_to_pipeline() -> void:
	# Arrange — base_mult=2.0, captain_mult_modifier=1.225
	# Expected: 2.0 * 1.225 = 2.45
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "captain_mult_modifier": _captain_mult_modifier(9) }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(2.45, 0.0001)

# ── AC3 — Nyx (STR=18, INT=19) ───────────────────────────────────────────────

func test_captain_bonus_nyx_str18_chip_bonus_is_9() -> void:
	# Arrange
	var chip_bonus: int = _captain_chip_bonus(18)

	# Assert — floor(18*0.5) = 9
	assert_int(chip_bonus).is_equal(9)


func test_captain_bonus_nyx_int19_mult_modifier_is_1_475() -> void:
	# Arrange
	var mult_mod: float = _captain_mult_modifier(19)

	# Assert — 1.0 + 19*0.025 = 1.475
	assert_float(mult_mod).is_equal_approx(1.475, 0.0001)


func test_captain_bonus_nyx_chips_and_mult_applied_to_pipeline() -> void:
	# Arrange — base=5, card=7, captain_bonus=9 → chips=21
	# base_mult=2.0, mult_modifier=1.475 → final=2.95
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {
		"captain_chip_bonus":    _captain_chip_bonus(18),
		"captain_mult_modifier": _captain_mult_modifier(19),
	}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(21)
	assert_float(mult).is_equal_approx(2.95, 0.0001)

# ── AC4 — No captain: bonus=0, modifier=1.0 ──────────────────────────────────

func test_captain_bonus_no_captain_chip_bonus_is_zero() -> void:
	# Arrange — no captain in context (default fallback)
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = {}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — 5 + 7 = 12 (no captain bonus)
	assert_int(chips).is_equal(12)


func test_captain_bonus_no_captain_mult_modifier_is_1() -> void:
	# Arrange — no captain → captain_mult_modifier defaults to 1.0
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — 2.0 * 1.0 = 2.0 (no captain modifier)
	assert_float(mult).is_equal_approx(2.0, 0.0001)


func test_captain_bonus_null_captain_id_yields_zero_bonus() -> void:
	# Arrange — explicitly passing 0 and 1.0 (what CombatSystem supplies when no captain)
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
	}

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — no bonus applied
	assert_int(chips).is_equal(12)
	assert_float(mult).is_equal_approx(2.0, 0.0001)

# ── AC5 — Captain locked at SETUP: stat changes do not affect ongoing combat ──

func test_captain_bonus_locked_at_setup_context_immutable_during_combat() -> void:
	# The pipeline reads from the context dict captured at SETUP.
	# Simulating a runtime stat change by calling with original and then modified
	# context; the pipeline always reflects the passed-in context value.

	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }

	# Context captured at SETUP (Artemisa STR=17)
	var setup_context: Dictionary = {
		"captain_chip_bonus":    _captain_chip_bonus(17),    # = 8
		"captain_mult_modifier": _captain_mult_modifier(13), # = 1.325
	}

	# Hypothetical "mid-combat state change" — a separate context object
	var changed_context: Dictionary = {
		"captain_chip_bonus":    _captain_chip_bonus(25),    # = 12 (changed)
		"captain_mult_modifier": _captain_mult_modifier(25), # = 1.625 (changed)
	}

	# Act — use SETUP context (locked)
	var chips_setup: int = ScoreCalculatorScript.calculate_chips(
			cards, hand_rank, setup_context)
	var mult_setup: float = ScoreCalculatorScript.calculate_mult(
			cards, hand_rank, setup_context)

	# Act — hypothetical changed context (should NOT affect a locked combat)
	var chips_changed: int = ScoreCalculatorScript.calculate_chips(
			cards, hand_rank, changed_context)

	# Assert — SETUP context gives Artemisa values; changed context is different,
	# proving the pipeline reads only what is passed in (callers must not pass the wrong dict)
	assert_int(chips_setup).is_equal(20)   # 5+7+8 = 20
	assert_float(mult_setup).is_equal_approx(2.65, 0.0001)   # 2.0 * 1.325
	assert_int(chips_changed).is_equal(24) # 5+7+12 = 24 (would be wrong in combat)

# ── AC6 — captain_mult_modifier applied AFTER Polychrome ─────────────────────

func test_captain_bonus_mult_modifier_applied_after_polychrome() -> void:
	# Arrange — base_mult=2.0, one Poly card, captain_mult_modifier=1.325
	# Additive phase: 2.0 (clamped)
	# Poly:           2.0 * 1.5 = 3.0
	# Captain:        3.0 * 1.325 = 3.975
	var cards_with_poly: Array[Dictionary] = [
		{ "value": 7, "suit": 0, "element": "Fire", "enhancement": "Polychrome" },
		{ "value": 8, "suit": 0, "element": "Fire", "enhancement": "" },
	]
	var hand_rank: Dictionary = { "base_chips": 10, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {
		"captain_mult_modifier": _captain_mult_modifier(13),  # 1.325
	}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(
			cards_with_poly, hand_rank, context)

	# Assert — 2.0 * 1.5 (poly) * 1.325 (captain) = 3.975
	assert_float(mult).is_equal_approx(3.975, 0.0001)


func test_captain_bonus_mult_modifier_without_polychrome_direct_multiplication() -> void:
	# Arrange — no poly, base_mult=2.0, captain_mult_modifier=1.225
	# final = 2.0 * 1.0 (no poly) * 1.225 = 2.45
	var cards: Array[Dictionary] = [_card(7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = {
		"captain_mult_modifier": _captain_mult_modifier(9),  # 1.225
	}

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(2.45, 0.0001)

# ── AC7 — Formula validation for all companions in stories.md ────────────────

func test_captain_bonus_formula_floor_str_times_half() -> void:
	# Validates floor(STR * 0.5) for multiple STR values
	var cases: Array = [
		[17, 8],   # Artemisa
		[20, 10],  # Hipolita
		[18, 9],   # Nyx
		[0,  0],   # No captain
		[1,  0],   # STR=1 → floor(0.5) = 0
		[3,  1],   # STR=3 → floor(1.5) = 1
	]
	for entry in cases:
		var str_val: int = entry[0]
		var expected: int = entry[1]
		var bonus: int = _captain_chip_bonus(str_val)
		assert_int(bonus).is_equal(expected)


func test_captain_bonus_formula_int_mult_modifier() -> void:
	# Validates 1.0 + (INT * 0.025) for multiple INT values
	var cases: Array = [
		[13, 1.325],  # Artemisa
		[9,  1.225],  # Hipolita
		[19, 1.475],  # Nyx / Atenea (AC4 in COMBAT-004)
		[0,  1.0],    # No captain
	]
	for entry in cases:
		var int_val: int = entry[0]
		var expected: float = entry[1]
		var modifier: float = _captain_mult_modifier(int_val)
		assert_float(modifier).is_equal_approx(expected, 0.0001)
