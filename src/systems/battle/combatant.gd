class_name Combatant
extends RefCounted

## Combatant — One unit in an active battle (ally or enemy).
##
## Thin container that groups: identity (id, display_name), team, a BattleStats
## runtime instance, and a map of BattleMove objects (normal/special/ultimate).
## Owned by BattleManager for the duration of a battle.

# ── Identity ──────────────────────────────────────────────────────────────────

var id: String = ""
var display_name: String = ""
var is_enemy: bool = false
var is_protagonist: bool = false

# ── Stats + moves ────────────────────────────────────────────────────────────

var stats: BattleStats
var moves: Dictionary = {}  ## move_type_tag → BattleMove

# ── Construction ──────────────────────────────────────────────────────────────

## Builds a Combatant from the two JSON data files.
##
## [param stats_row] — row from character_battle_stats.json
## [param moveset] — row from battle_movesets.json for this id (may contain
##                   "normal", "special", and optionally "ultimate")
static func build(
		p_id: String,
		p_display_name: String,
		p_is_enemy: bool,
		p_is_protagonist: bool,
		stats_row: Dictionary,
		moveset: Dictionary) -> Combatant:
	var c: Combatant = Combatant.new()
	c.id = p_id
	c.display_name = p_display_name
	c.is_enemy = p_is_enemy
	c.is_protagonist = p_is_protagonist
	c.stats = BattleStats.from_dict(stats_row)

	# Parse each move type that's present.
	for tag: String in ["normal", "special", "ultimate"]:
		if moveset.has(tag):
			c.moves[tag] = BattleMove.from_dict(moveset[tag] as Dictionary, tag)
	return c


# ── Queries ───────────────────────────────────────────────────────────────────

func is_alive() -> bool:
	return stats != null and stats.is_alive()


func get_move(move_type_tag: String) -> BattleMove:
	return moves.get(move_type_tag, null) as BattleMove


func has_move(move_type_tag: String) -> bool:
	return moves.has(move_type_tag)


## Returns true if this combatant can cast the given move right now
## (enough energy / full ultimate bar / move exists).
func can_cast(move_type_tag: String) -> bool:
	var move: BattleMove = get_move(move_type_tag)
	if move == null:
		return false
	if not is_alive():
		return false
	if move_type_tag == "ultimate":
		return stats.has_full_ultimate()
	return stats.current_energy >= move.energy_cost
