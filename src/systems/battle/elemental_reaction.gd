class_name ElementalReaction
extends RefCounted

## ElementalReaction — Static table of two-element combat reactions.
##
## When a combatant with an existing elemental_charge takes a hit from a
## different element, the two charges consume each other and fire a reaction.
## BattleManager calls resolve() with (charged_element, incoming_element) and
## applies the returned effect dict.
##
## Reactions are symmetric: Fire+Water gives the same result as Water+Fire.
##
## Effect types the caller must handle:
##   "damage_buff_next"   — attacker gains +mult% damage on next attack (magnitude, duration)
##   "dot_burn"           — target takes damage each turn (magnitude, duration)
##   "aoe_damage"         — immediate AoE damage to all enemies (magnitude)
##   "party_heal"         — heal whole ally party (magnitude % of max_hp)
##   "chain_damage"       — damage chains to 2 other enemies (magnitude)
##   "party_shield"       — all allies gain shield of N HP (magnitude, duration)

# ── Names ─────────────────────────────────────────────────────────────────────

const REACTION_ORACLE_MIST: String   = "Oracle Mist"       ## Fire + Water
const REACTION_CINDER_BLOOM: String  = "Cinder Bloom"      ## Fire + Earth
const REACTION_SOLAR_FLARE: String   = "Solar Flare"       ## Fire + Lightning
const REACTION_LIFE_SPRING: String   = "Life Spring"       ## Water + Earth
const REACTION_TIDAL_SURGE: String   = "Tidal Surge"       ## Water + Lightning
const REACTION_STONE_AEGIS: String   = "Stone Aegis"       ## Earth + Lightning

# ── Public API ────────────────────────────────────────────────────────────────

## Returns a reaction dict for the given element pair, or empty dict if the
## pair is identical / invalid / Neutral.
##
## Return schema:
##   {name, effect, magnitude, duration}
static func resolve(charged: String, incoming: String) -> Dictionary:
	if charged.is_empty() or incoming.is_empty():
		return {}
	if charged == "Neutral" or incoming == "Neutral":
		return {}
	if charged == incoming:
		return {}

	var pair: String = _pair_key(charged, incoming)
	match pair:
		"Fire|Water":
			return {
				"name": REACTION_ORACLE_MIST,
				"effect": "damage_buff_next",
				"magnitude": 50.0,    ## +50% on next attack
				"duration": 1,
			}
		"Earth|Fire":
			return {
				"name": REACTION_CINDER_BLOOM,
				"effect": "dot_burn",
				"magnitude": 0.25,    ## 25% of attacker ATK per turn
				"duration": 3,
			}
		"Fire|Lightning":
			return {
				"name": REACTION_SOLAR_FLARE,
				"effect": "aoe_damage",
				"magnitude": 1.5,     ## 150% of attacker ATK to all enemies
				"duration": 0,
			}
		"Earth|Water":
			return {
				"name": REACTION_LIFE_SPRING,
				"effect": "party_heal",
				"magnitude": 0.20,    ## heal 20% of max_hp per ally
				"duration": 0,
			}
		"Lightning|Water":
			return {
				"name": REACTION_TIDAL_SURGE,
				"effect": "chain_damage",
				"magnitude": 0.75,    ## 75% of attacker ATK to 2 other enemies
				"duration": 0,
			}
		"Earth|Lightning":
			return {
				"name": REACTION_STONE_AEGIS,
				"effect": "party_shield",
				"magnitude": 30,      ## flat 30 HP shield
				"duration": 2,
			}
		_:
			return {}


# ── Private ───────────────────────────────────────────────────────────────────

## Returns a canonical sorted "A|B" key so Fire+Water and Water+Fire collapse
## to the same lookup string.
static func _pair_key(a: String, b: String) -> String:
	if a < b:
		return "%s|%s" % [a, b]
	return "%s|%s" % [b, a]
