class_name ScoreCalculator
extends RefCounted

## Computes the chips, mult, and final score of the poker combat scoring pipeline.
##
## CHIPS pipeline order (additive, strict):
##   1. base_hand_chips          (from hand_rank)
##   2. per_card_chips           (2-10 face, J/Q/K=10, Ace=11)
##   3. foil_chips               (+50 per Foil-enhanced card)
##   4. blessing_chips           (from BlessingSystem, passed via context)
##   5. element_chips            (+25 weak, -15 resist, 0 neutral / None)
##   6. captain_chip_bonus       (floor(STR * 0.5), passed via context)
##   7. equipment_chips          (from equipped Weapon, 0 if slot empty) [STORY-EQUIP-004]
##   8. social_buff_chips        (from GameStore combat buff, passed via context)
##
## Clamp: total_chips = max(1, total_chips)
##
## MULT pipeline order (strict):
##   Additive phase:
##     1. base_hand_mult         (from hand_rank)
##     2. holo_mult              (+10 per Holographic-enhanced card)
##     3. blessing_mult          (from BlessingSystem, passed via context)
##     4. element_mult           (+0.5 per weak-element card)
##     5. social_buff_mult       (from GameStore combat buff, passed via context)
##     6. captain_mult_modifier  (additive contribution: captain_mult_modifier - 1.0)
##     7. equipment_mult         (from equipped Amulet, 0.0 if slot empty) [STORY-EQUIP-004]
##   Clamp: additive_mult = max(1.0, additive_mult)
##   Multiplicative phase:
##     8. poly_product           (x1.5 per Polychrome card, chained)
##     9. captain_mult_modifier  (1.0 + INT * 0.025, passed via context)
##
## NOTE on pipeline ordering: The GDD (equipment.md) specifies that equipment
## is applied after captain and before blessings. The chips pipeline above
## reflects the implementation order. The mult pipeline places equipment_mult
## after the captain contribution in the additive phase, before Polychrome.
##
## SCORE: floor(total_chips * final_mult)  — stored as int (64-bit safe)
##
## Enhancement and element bonus values are loaded from config.
## No bonus magnitudes are hardcoded in this file.
##
## context keys expected (chips):
##   enemy_element:          String  — "Fire"|"Water"|"Earth"|"Lightning"|""|"None"
##   captain_chip_bonus:     int     — floor(STR * 0.5), 0 if no captain
##   equipment_chips:        int     — from equipped Weapon, 0 if slot empty
##   social_buff_chips:      int     — from GameStore combat buff, 0 if none
##   blessing_chips:         int     — from BlessingSystem.compute(), 0 if none
##
## context keys expected (mult):
##   blessing_mult:          float   — from BlessingSystem.compute(), 0.0 if none
##   social_buff_mult:       float   — from GameStore combat buff, 0.0 if none
##   equipment_mult:         float   — from equipped Amulet, 0.0 if slot empty
##   captain_mult_modifier:  float   — 1.0 + (INT * 0.025), 1.0 if no captain
##
## See: docs/architecture/adr-0007-poker-combat.md
## Stories: STORY-COMBAT-003, STORY-COMBAT-004

# ── Config cache ─────────────────────────────────────────────────────────────

## Enhancement and element bonus values loaded from hand_ranks.json.
static var _config: Dictionary = {}

# ── Config keys (set defaults here so tests can inspect loaded values) ────────

## Fallback bonus values used if config fails to load.
const _DEFAULT_FOIL_CHIPS:            int   = 50
const _DEFAULT_ELEMENT_WEAK_CHIPS:    int   = 25
const _DEFAULT_ELEMENT_RESIST_CHIPS:  int   = -15
const _DEFAULT_HOLO_MULT:             float = 10.0
const _DEFAULT_ELEMENT_WEAK_MULT:     float = 0.5
const _DEFAULT_POLY_MULT_FACTOR:      float = 1.5

# ── Public API ────────────────────────────────────────────────────────────────

## Runs the chips portion of the scoring pipeline and returns total_chips (>= 1).
##
## Parameters:
##   cards:     Array[Dictionary] — the played cards (must include "value",
##                                   "element", "enhancement" keys)
##   hand_rank: Dictionary        — result of HandEvaluator.evaluate()
##                                   {rank, base_chips, base_mult}
##   context:   Dictionary        — scoring context (see file header)
static func calculate_chips(
		cards: Array[Dictionary],
		hand_rank: Dictionary,
		context: Dictionary) -> int:
	_ensure_config()

	var total: int = hand_rank.get("base_chips", 0) as int

	# 2. Per-card chips
	for card: Dictionary in cards:
		total += HandEvaluator.get_card_chips(card.get("value", 0) as int)

	# 3. Foil enhancement: +foil_chips per Foil card
	var foil_bonus: int = _config.get("foil_chips", _DEFAULT_FOIL_CHIPS) as int
	for card: Dictionary in cards:
		if card.get("enhancement", "") == "Foil":
			total += foil_bonus

	# 4. Blessing chips (black-box injection point)
	total += context.get("blessing_chips", 0) as int

	# 5. Element interactions (per card, independent)
	var enemy_element: String = context.get("enemy_element", "") as String
	if enemy_element != "" and enemy_element != "None":
		var weak_chips: int = _config.get(
				"element_weak_chips", _DEFAULT_ELEMENT_WEAK_CHIPS) as int
		var resist_chips: int = _config.get(
				"element_resist_chips", _DEFAULT_ELEMENT_RESIST_CHIPS) as int
		var weak_element: String = _get_weak_element(enemy_element)
		for card: Dictionary in cards:
			var card_element: String = card.get("element", "") as String
			if card_element == weak_element:
				total += weak_chips
			elif card_element == enemy_element:
				total += resist_chips

	# 6. Captain chip bonus
	total += context.get("captain_chip_bonus", 0) as int

	# 7. Equipment chip bonus (Weapon slot — Step 4 per equipment.md GDD)
	total += context.get("equipment_chips", 0) as int

	# 8. Social buff chips
	total += context.get("social_buff_chips", 0) as int

	# Clamp: chips must be >= 1
	return maxi(1, total)


## Runs the mult portion of the scoring pipeline and returns final_mult (>= 1.0).
##
## Parameters:
##   cards:     Array[Dictionary] — the played cards (must include "enhancement",
##                                   "element" keys)
##   hand_rank: Dictionary        — result of HandEvaluator.evaluate()
##                                   {rank, base_chips, base_mult}
##   context:   Dictionary        — scoring context (see file header)
static func calculate_mult(
		cards: Array[Dictionary],
		hand_rank: Dictionary,
		context: Dictionary) -> float:
	_ensure_config()

	# ── Additive phase ────────────────────────────────────────────────────────

	var additive: float = hand_rank.get("base_mult", 1.0) as float

	# Holographic enhancement: +holo_mult per Holo card (additive)
	var holo_bonus: float = _config.get("holo_mult", _DEFAULT_HOLO_MULT) as float
	for card: Dictionary in cards:
		if card.get("enhancement", "") == "Holographic":
			additive += holo_bonus

	# Blessing mult (black-box injection point)
	additive += context.get("blessing_mult", 0.0) as float

	# Element weakness: +element_weak_mult per weak-element card (additive)
	var enemy_element: String = context.get("enemy_element", "") as String
	if enemy_element != "" and enemy_element != "None":
		var weak_mult: float = _config.get(
				"element_weak_mult", _DEFAULT_ELEMENT_WEAK_MULT) as float
		var weak_element: String = _get_weak_element(enemy_element)
		for card: Dictionary in cards:
			if card.get("element", "") == weak_element:
				additive += weak_mult

	# Social buff mult
	additive += context.get("social_buff_mult", 0.0) as float

	# Equipment mult bonus (Amulet slot — Step D per equipment.md GDD)
	additive += context.get("equipment_mult", 0.0) as float

	# Clamp: additive mult must be >= 1.0
	additive = maxf(1.0, additive)

	# ── Multiplicative phase ──────────────────────────────────────────────────

	# Polychrome enhancement: x poly_factor per Poly card (chained)
	var poly_factor: float = _config.get("poly_mult_factor", _DEFAULT_POLY_MULT_FACTOR) as float
	var poly_product: float = 1.0
	for card: Dictionary in cards:
		if card.get("enhancement", "") == "Polychrome":
			poly_product *= poly_factor

	# Captain mult modifier: applied after Polychrome (strict pipeline order)
	var captain_mult: float = context.get("captain_mult_modifier", 1.0) as float

	return additive * poly_product * captain_mult


## Returns the final combat score: floor(total_chips * final_mult).
##
## Uses 64-bit float arithmetic internally; result is safe up to 2^53
## without overflow (covers all realistic in-game score ranges).
static func calculate_score(chips: int, mult: float) -> int:
	return int(floorf(float(chips) * mult))

# ── Private ───────────────────────────────────────────────────────────────────

## Returns the element that is weak against (i.e. is beaten by) enemy_element.
## Cycle: Fire > Earth > Lightning > Water > Fire
## Weak means "the card's element defeats the enemy element".
##   Fire beats Earth  → Earth is weak to Fire  → weak_element("Earth")  = "Fire"
##   Water beats Fire  → Fire is weak to Water  → weak_element("Fire")   = "Water"
##   Earth beats Lightning → Lightning weak to Earth → weak_element("Lightning") = "Earth"
##   Lightning beats Water → Water weak to Lightning → weak_element("Water") = "Lightning"
static func _get_weak_element(enemy_element: String) -> String:
	match enemy_element:
		"Fire":      return "Water"
		"Water":     return "Lightning"
		"Earth":     return "Fire"
		"Lightning": return "Earth"
	return ""


## Loads enhancement/element config from hand_ranks.json on first use.
## Falls back to DEFAULT_ constants if the section is absent.
static func _ensure_config() -> void:
	if not _config.is_empty():
		return
	var root: Dictionary = JsonLoader.load_dict("res://assets/data/hand_ranks.json")
	if root.is_empty():
		return
	# scoring_config is optional; if absent defaults are used.
	_config = root.get("scoring_config", {}) as Dictionary
	if _config.is_empty():
		# Provide defaults so _config.is_empty() stays false after first load.
		_config = {
			"foil_chips":           _DEFAULT_FOIL_CHIPS,
			"element_weak_chips":   _DEFAULT_ELEMENT_WEAK_CHIPS,
			"element_resist_chips": _DEFAULT_ELEMENT_RESIST_CHIPS,
			"holo_mult":            _DEFAULT_HOLO_MULT,
			"element_weak_mult":    _DEFAULT_ELEMENT_WEAK_MULT,
			"poly_mult_factor":     _DEFAULT_POLY_MULT_FACTOR,
		}
