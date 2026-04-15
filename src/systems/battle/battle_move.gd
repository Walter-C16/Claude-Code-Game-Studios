class_name BattleMove
extends RefCounted

## BattleMove — Data class describing one combat action (attack / special / ultimate).
##
## Built from battle_movesets.json. Holds pure data — no combat logic lives
## here. BattleManager reads these fields to compute damage, targeting,
## energy spend, and side-effects.

# ── Identity ──────────────────────────────────────────────────────────────────

var id: String = ""
var name_key: String = ""
var move_type: String = "normal"  ## "normal", "special", or "ultimate"

# ── Targeting ─────────────────────────────────────────────────────────────────

## Target scope for this move. One of:
##   "single_enemy", "all_enemies", "single_ally", "all_allies", "self"
var target: String = "single_enemy"

# ── Damage ────────────────────────────────────────────────────────────────────

## Multiplier applied to attacker.ATK to compute raw damage before DEF / crit.
var damage_mult: float = 1.0

## Number of hits the move lands. Each hit rolls independently for crit and
## reaction. Used by multi-hit specials like Arrow Rain.
var hits: int = 1

## Element applied by this move. If "gun", the protagonist pulls the current
## blessed element from GameStore (for elemental reactions).
var element: String = ""
var element_source: String = ""  ## "gun" for protagonist or "" to use element

# ── Cost ──────────────────────────────────────────────────────────────────────

var energy_cost: int = 0

# ── Side-effect ──────────────────────────────────────────────────────────────

## Named effect applied on hit (or on cast for self/ally targets).
## BattleManager dispatches on this string to a handler function.
## Examples: "pierce_def", "guaranteed_crit_3_turns", "party_shield_30_percent".
var effect: String = ""


# ── Construction ──────────────────────────────────────────────────────────────

## Builds a BattleMove from a Dictionary + known move_type tag.
static func from_dict(data: Dictionary, move_type_tag: String) -> BattleMove:
	var move: BattleMove = BattleMove.new()
	move.id = data.get("id", "") as String
	move.name_key = data.get("name_key", "") as String
	move.move_type = move_type_tag
	move.target = data.get("target", "single_enemy") as String
	move.damage_mult = float(data.get("damage_mult", 1.0))
	move.hits = int(data.get("hits", 1))
	move.element = data.get("element", "") as String
	move.element_source = data.get("element_source", "") as String
	move.energy_cost = int(data.get("energy_cost", 0))
	move.effect = data.get("effect", "") as String
	return move


# ── Queries ───────────────────────────────────────────────────────────────────

func is_damaging() -> bool:
	return damage_mult > 0.0


func targets_enemies() -> bool:
	return target == "single_enemy" or target == "all_enemies"


func targets_allies() -> bool:
	return target == "single_ally" or target == "all_allies" or target == "self"


func targets_many() -> bool:
	return target == "all_enemies" or target == "all_allies"
