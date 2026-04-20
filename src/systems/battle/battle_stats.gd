class_name BattleStats
extends RefCounted

## BattleStats — Runtime combat stats for a single unit (ally or enemy).
##
## Built by BattleManager from character_battle_stats.json. Holds both the
## immutable "base" stats (atk, def, max_hp, etc.) and the mutable runtime
## state (current_hp, current_energy, current_ultimate, elemental_charge).
## Blessings and gear apply additive modifiers before battle starts — not
## during — to keep turn math deterministic.

# ── Immutable base stats ──────────────────────────────────────────────────────

var element: String = "Neutral"
var max_hp: int = 100
var atk: int = 10
var def_stat: int = 5  ## "def" is a Godot keyword so the field is named def_stat
var agi: int = 10
var crit_chance: float = 5.0     ## percentage 0..100
var crit_damage: float = 150.0   ## percentage (150 = 1.5x)
var max_energy: int = 100
var max_ultimate: int = 100

## Where ultimate charge comes from. One of:
##   "any_action", "turns_passed", "damage_dealt", "damage_taken", "reactions"
var ult_charge_source: String = "any_action"
var ult_charge_rate: int = 10

## AI personality profile — consumed by BattleAi.choose_action for enemies.
## One of: "aggressive", "tactical", "berserker", "defensive". Ignored for
## player-controlled combatants.
var ai_profile: String = "aggressive"

## Optional per-enemy turn timer in seconds. 0 means no timer.
## BattleManager.setup() takes the MAX across all enemies in the encounter
## and uses that as the player-side turn time limit (the player gets the most
## generous timer of any enemy on the field). Player units ignore this field.
var turn_timer_seconds: int = 0

# ── Runtime state ────────────────────────────────────────────────────────────

var current_hp: int = 100
var current_energy: int = 100
var current_ultimate: int = 0

## Elemental charge left on this unit from the last opposing-element hit.
## Empty string means no charge. When a second-element hit arrives,
## BattleManager fires the reaction using (charge_element, incoming_element).
var elemental_charge: String = ""

## Pending effects keyed by effect name. Each value is a Dictionary with
## fields like {turns_left, magnitude}. Cleared by BattleManager between turns.
var active_effects: Dictionary = {}

# ── Construction ──────────────────────────────────────────────────────────────

## Builds a BattleStats instance from a plain Dictionary (JSON row).
## Caller is responsible for supplying defaults — missing keys fall back to
## the class defaults above, never to null.
static func from_dict(data: Dictionary) -> BattleStats:
	var stats: BattleStats = BattleStats.new()
	stats.element = data.get("element", "Neutral") as String
	stats.max_hp = int(data.get("hp", 100))
	stats.atk = int(data.get("atk", 10))
	stats.def_stat = int(data.get("def", 5))
	stats.agi = int(data.get("agi", 10))
	stats.crit_chance = float(data.get("crit_chance", 5.0))
	stats.crit_damage = float(data.get("crit_damage", 150.0))
	stats.max_energy = int(data.get("max_energy", 100))
	stats.max_ultimate = int(data.get("max_ultimate", 100))
	stats.ult_charge_source = data.get("ult_charge_source", "any_action") as String
	stats.ult_charge_rate = int(data.get("ult_charge_rate", 10))
	stats.ai_profile = data.get("ai_profile", "aggressive") as String
	stats.turn_timer_seconds = int(data.get("turn_timer_seconds", 0))

	# Start battle at full HP, full energy, zero ultimate.
	stats.current_hp = stats.max_hp
	stats.current_energy = stats.max_energy
	stats.current_ultimate = 0
	return stats


# ── Queries ───────────────────────────────────────────────────────────────────

func is_alive() -> bool:
	return current_hp > 0


func hp_fraction() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)


func energy_fraction() -> float:
	if max_energy <= 0:
		return 0.0
	return float(current_energy) / float(max_energy)


func ultimate_fraction() -> float:
	if max_ultimate <= 0:
		return 0.0
	return float(current_ultimate) / float(max_ultimate)


func has_full_ultimate() -> bool:
	return current_ultimate >= max_ultimate


# ── Mutations ─────────────────────────────────────────────────────────────────

## Subtracts [param amount] from current_hp, clamped to [0, max_hp].
## Returns the actual damage applied (may be less than requested if HP was low).
func take_damage(amount: int) -> int:
	var before: int = current_hp
	current_hp = clampi(current_hp - amount, 0, max_hp)
	return before - current_hp


func heal(amount: int) -> int:
	var before: int = current_hp
	current_hp = clampi(current_hp + amount, 0, max_hp)
	return current_hp - before


## Spends energy if available. Returns true on success, false if insufficient.
func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false
	current_energy = maxi(0, current_energy - amount)
	return true


func add_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)


func add_ultimate(amount: int) -> void:
	current_ultimate = clampi(current_ultimate + amount, 0, max_ultimate)


func consume_ultimate() -> bool:
	if current_ultimate < max_ultimate:
		return false
	current_ultimate = 0
	return true
