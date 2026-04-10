class_name ElementSystemTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-005: Element Weakness and Resistance System
##
## Covers:
##   AC1 — Earth enemy, Heart/Fire card → +25 chips, +0.5 mult
##   AC2 — Earth enemy, Club/Earth card → -15 chips, 0 mult
##   AC3 — Earth enemy, Diamond/Water card → 0 chips, 0 mult (neutral)
##   AC4 — enemy element "None" → all interactions disabled
##   AC5 — 5 Heart cards vs Earth enemy → +125 chips, +2.5 mult
##   AC6 — 5 Club cards vs Earth enemy → -75 chips, 0 mult
##   AC7 — Full element cycle: Fire weak to Water, Water weak to Lightning,
##          Lightning weak to Earth, Earth weak to Fire
##   AC8 — Bonus values come from config (not hardcoded)
##
## Element cycle: Fire > Earth > Lightning > Water > Fire
## Suit mapping: Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script references ─────────────────────────────────────────────────────────

const ScoreCalculatorScript = preload("res://src/systems/combat/score_calculator.gd")

# ── Card factory ──────────────────────────────────────────────────────────────

## Creates a minimal card Dictionary for element testing.
func _card(element: String, value: int = 7, enhancement: String = "") -> Dictionary:
	return {
		"value":       value,
		"suit":        0,
		"element":     element,
		"enhancement": enhancement,
	}

## Creates a hand_rank stub with zero base values to isolate element effects.
func _empty_rank() -> Dictionary:
	return { "base_chips": 0, "base_mult": 0.0, "rank": "High Card" }

# ── AC1 — Earth enemy, Fire card → +25 chips, +0.5 mult ──────────────────────

func test_element_system_fire_card_vs_earth_enemy_adds_25_chips() -> void:
	# Arrange — one Fire card, Earth enemy (weak to Fire)
	# base=0, per-card chips = 7, element_chips = +25 → total = 32
	var cards: Array[Dictionary] = [_card("Fire", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 0.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — 0 (base) + 7 (card) + 25 (weak) = 32
	assert_int(chips).is_equal(32)


func test_element_system_fire_card_vs_earth_enemy_adds_05_mult() -> void:
	# Arrange — one Fire card, Earth enemy → +0.5 element_mult
	# base_mult=1.0 (min clamp), element adds 0.5 → additive = 1.5
	var cards: Array[Dictionary] = [_card("Fire", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — 1.0 + 0.5 = 1.5
	assert_float(mult).is_equal_approx(1.5, 0.0001)

# ── AC2 — Earth enemy, Earth card → -15 chips, 0 mult ────────────────────────

func test_element_system_earth_card_vs_earth_enemy_subtracts_15_chips() -> void:
	# Arrange — one Earth card, Earth enemy (resist)
	# base=0, per-card=7, resist=-15 → total=-8 → clamped to 1
	var cards: Array[Dictionary] = [_card("Earth", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — 0+7-15=-8, clamped to 1
	assert_int(chips).is_equal(1)


func test_element_system_earth_card_vs_earth_enemy_zero_mult_bonus() -> void:
	# Arrange — Earth card vs Earth enemy → no element_mult added
	# base_mult=2.0, no element_mult → final = 2.0
	var cards: Array[Dictionary] = [_card("Earth", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — no element mult bonus for resist card
	assert_float(mult).is_equal_approx(2.0, 0.0001)

# ── AC3 — Earth enemy, Water card → neutral (0 chips, 0 mult) ────────────────

func test_element_system_water_card_vs_earth_enemy_is_neutral_chips() -> void:
	# Arrange — one Water card, Earth enemy (neutral)
	# base=5, per-card=7 → total=12 (no element bonus)
	var cards: Array[Dictionary] = [_card("Water", 7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(12)


func test_element_system_water_card_vs_earth_enemy_is_neutral_mult() -> void:
	# Arrange — Water card vs Earth → no element_mult bonus
	var cards: Array[Dictionary] = [_card("Water", 7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — unaffected
	assert_float(mult).is_equal_approx(2.0, 0.0001)

# ── AC4 — Enemy element "None" disables all interactions ─────────────────────

func test_element_system_enemy_none_disables_chips_bonus() -> void:
	# Arrange — Fire card vs None enemy → no element bonus
	# base=5, per-card=7 → total=12
	var cards: Array[Dictionary] = [_card("Fire", 7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "None" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(12)


func test_element_system_enemy_none_disables_mult_bonus() -> void:
	# Arrange — Fire card vs None → no element_mult
	var cards: Array[Dictionary] = [_card("Fire", 7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "enemy_element": "None" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(2.0, 0.0001)


func test_element_system_enemy_empty_string_disables_interactions() -> void:
	# Arrange — empty string treated same as None
	var cards: Array[Dictionary] = [_card("Fire", 7)]
	var hand_rank: Dictionary = { "base_chips": 5, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "enemy_element": "" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — no element effects
	assert_int(chips).is_equal(12)
	assert_float(mult).is_equal_approx(2.0, 0.0001)

# ── AC5 — 5 Fire cards vs Earth: +125 chips, +2.5 mult ───────────────────────

func test_element_system_five_fire_cards_vs_earth_total_chips_plus_125() -> void:
	# Arrange — base=0, 5 Fire cards (value=7 each → per-card=35), 5x(+25)=+125
	# total = 0 + 35 + 125 = 160
	var cards: Array[Dictionary] = [
		_card("Fire", 7),
		_card("Fire", 7),
		_card("Fire", 7),
		_card("Fire", 7),
		_card("Fire", 7),
	]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 0.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — element_chips = 5 * 25 = 125; per-card = 35; base = 0 → 160
	assert_int(chips).is_equal(160)


func test_element_system_five_fire_cards_vs_earth_total_mult_plus_25() -> void:
	# Arrange — base_mult=1.0, 5 Fire cards × 0.5 = +2.5 → additive = 3.5
	var cards: Array[Dictionary] = [
		_card("Fire", 7),
		_card("Fire", 7),
		_card("Fire", 7),
		_card("Fire", 7),
		_card("Fire", 7),
	]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — 1.0 + 2.5 = 3.5
	assert_float(mult).is_equal_approx(3.5, 0.0001)

# ── AC6 — 5 Earth cards vs Earth: -75 chips, 0 mult ──────────────────────────

func test_element_system_five_earth_cards_vs_earth_chips_clamped_to_1() -> void:
	# Arrange — base=0, 5 Earth cards (value=7 → per-card=35), 5x(-15)=-75
	# total = 0 + 35 - 75 = -40 → clamped to 1
	var cards: Array[Dictionary] = [
		_card("Earth", 7),
		_card("Earth", 7),
		_card("Earth", 7),
		_card("Earth", 7),
		_card("Earth", 7),
	]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 0.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert — element resist penalty drives total negative; clamped to 1
	assert_int(chips).is_equal(1)


func test_element_system_five_earth_cards_vs_earth_no_mult_bonus() -> void:
	# Arrange — resist cards add no element mult → base only
	var cards: Array[Dictionary] = [
		_card("Earth", 7),
		_card("Earth", 7),
		_card("Earth", 7),
		_card("Earth", 7),
		_card("Earth", 7),
	]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 2.0, "rank": "Pair" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert — no element_mult from resist cards
	assert_float(mult).is_equal_approx(2.0, 0.0001)

# ── AC7 — Full element cycle ─────────────────────────────────────────────────

func test_element_system_cycle_fire_is_weak_to_water() -> void:
	# Arrange — Water card vs Fire enemy → Water beats Fire (+25 chips)
	# base=0, per-card=7, element=+25 → 32
	var cards: Array[Dictionary] = [_card("Water", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Fire" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(32)


func test_element_system_cycle_water_is_weak_to_lightning() -> void:
	# Arrange — Lightning card vs Water enemy → Lightning beats Water (+25 chips)
	var cards: Array[Dictionary] = [_card("Lightning", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Water" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(32)


func test_element_system_cycle_lightning_is_weak_to_earth() -> void:
	# Arrange — Earth card vs Lightning enemy → Earth beats Lightning (+25 chips)
	var cards: Array[Dictionary] = [_card("Earth", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Lightning" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(32)


func test_element_system_cycle_earth_is_weak_to_fire() -> void:
	# Arrange — Fire card vs Earth enemy → Fire beats Earth (+25 chips)
	var cards: Array[Dictionary] = [_card("Fire", 7)]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(32)

# ── AC8 — Config-driven values (weak=+25, resist=-15, weak_mult=+0.5) ─────────

func test_element_system_config_values_match_adr_spec() -> void:
	# Arrange — verify the default constants match ADR-0007 spec values
	# This ensures no magic numbers leaked into the pipeline

	# Weak chip bonus (per ADR: +25)
	var weak_chips: int = ScoreCalculatorScript._DEFAULT_ELEMENT_WEAK_CHIPS
	var resist_chips: int = ScoreCalculatorScript._DEFAULT_ELEMENT_RESIST_CHIPS
	var weak_mult: float = ScoreCalculatorScript._DEFAULT_ELEMENT_WEAK_MULT

	# Assert — values match ADR-0007 spec
	assert_int(weak_chips).is_equal(25)
	assert_int(resist_chips).is_equal(-15)
	assert_float(weak_mult).is_equal_approx(0.5, 0.0001)

# ── Mixed hand: weak + resist + neutral ──────────────────────────────────────

func test_element_system_mixed_hand_weak_resist_neutral_chips() -> void:
	# Arrange — vs Earth enemy:
	#   Fire card (value=7):  weak  → +25 chips
	#   Earth card (value=7): resist → -15 chips
	#   Water card (value=7): neutral → 0
	# base=0, per-card=7+7+7=21, element=25-15+0=+10 → total=31
	var cards: Array[Dictionary] = [
		_card("Fire",  7),
		_card("Earth", 7),
		_card("Water", 7),
	]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var chips: int = ScoreCalculatorScript.calculate_chips(cards, hand_rank, context)

	# Assert
	assert_int(chips).is_equal(31)


func test_element_system_mixed_hand_weak_resist_neutral_mult() -> void:
	# Arrange — vs Earth enemy:
	#   Fire card: weak → +0.5 mult
	#   Earth card: resist → 0 mult (no bonus)
	#   Water card: neutral → 0 mult
	# base_mult=1.0, element_mult = +0.5 → additive = 1.5
	var cards: Array[Dictionary] = [
		_card("Fire",  7),
		_card("Earth", 7),
		_card("Water", 7),
	]
	var hand_rank: Dictionary = { "base_chips": 0, "base_mult": 1.0, "rank": "High Card" }
	var context: Dictionary = { "enemy_element": "Earth" }

	# Act
	var mult: float = ScoreCalculatorScript.calculate_mult(cards, hand_rank, context)

	# Assert
	assert_float(mult).is_equal_approx(1.5, 0.0001)
