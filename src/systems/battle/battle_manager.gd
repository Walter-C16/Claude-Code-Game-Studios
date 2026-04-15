class_name BattleManager
extends RefCounted

## BattleManager — Turn-based action combat state machine.
##
## Owns a battle from setup to victory/defeat. Holds the player party, enemy
## party, turn queue (sorted by AGI), and the current phase. The UI layer
## (battle.tscn) reads state via get_state() and drives actions through
## execute_move(). Pure data — no node operations here.
##
## State machine:
##   IDLE → READY → (loop: AWAIT_ACTION → RESOLVING → END_TURN) → VICTORY / DEFEAT
##
## All turn math is deterministic given the same RNG seed. Reactions and
## effects apply through ElementalReaction + BattleMove.effect dispatch.
##
## This class replaces the poker CombatManager for story and tournament
## combat. The old CombatManager remains in place for tavern poker games.

# ── Signals ───────────────────────────────────────────────────────────────────

signal state_changed(new_state: int)
signal turn_started(combatant: Combatant)
signal move_executed(actor: Combatant, move: BattleMove, targets: Array)
signal reaction_triggered(reaction_name: String, on: Combatant)
signal battle_ended(victory: bool)

# ── State enum ────────────────────────────────────────────────────────────────

enum State {
	IDLE,
	READY,
	AWAIT_ACTION,
	RESOLVING,
	END_TURN,
	VICTORY,
	DEFEAT,
}

# ── Public state ──────────────────────────────────────────────────────────────

var state: int = State.IDLE

## All allies in turn order. Slot 0 is always the protagonist.
var party: Array[Combatant] = []

## All enemies in turn order.
var enemies: Array[Combatant] = []

## Global turn queue sorted by AGI descending. Contains live combatants only;
## rebuilt between rounds.
var turn_queue: Array[Combatant] = []

## Index into turn_queue of the combatant whose turn it is.
var current_turn_index: int = 0

## Monotonic turn counter across the entire battle (1, 2, 3, ...).
var turn_number: int = 0

# ── Private config ───────────────────────────────────────────────────────────

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _energy_regen_per_turn: int = 15

# ── Setup ─────────────────────────────────────────────────────────────────────

## Starts a battle with the given rosters.
## [param party_ids] — up to 4 ally ids (index 0 should be "protagonist").
## [param enemy_ids] — 1-4 enemy ids matching character_battle_stats.json.
func setup(party_ids: Array[String], enemy_ids: Array[String]) -> bool:
	var data: Dictionary = JsonLoader.load_dict("res://assets/data/character_battle_stats.json")
	var movesets: Dictionary = JsonLoader.load_dict("res://assets/data/battle_movesets.json")
	if data.is_empty() or movesets.is_empty():
		push_error("BattleManager.setup: failed to load battle data files")
		return false

	_energy_regen_per_turn = int(data.get("config", {}).get("energy_regen_per_turn", 15))

	var char_rows: Dictionary = data.get("characters", {}) as Dictionary
	var enemy_rows: Dictionary = data.get("enemies", {}) as Dictionary

	party.clear()
	for pid: String in party_ids:
		var row: Dictionary = char_rows.get(pid, {}) as Dictionary
		if row.is_empty():
			push_warning("BattleManager.setup: unknown party id '%s' — skipping" % pid)
			continue
		var moveset: Dictionary = movesets.get(pid, {}) as Dictionary
		var is_proto: bool = pid == "protagonist"
		var name: String = _display_name_for(pid)
		party.append(Combatant.build(pid, name, false, is_proto, row, moveset))

	enemies.clear()
	for eid: String in enemy_ids:
		var row: Dictionary = enemy_rows.get(eid, {}) as Dictionary
		if row.is_empty():
			push_warning("BattleManager.setup: unknown enemy id '%s' — skipping" % eid)
			continue
		var moveset: Dictionary = movesets.get(eid, {}) as Dictionary
		var name: String = _enemy_display_name_for(eid)
		enemies.append(Combatant.build(eid, name, true, false, row, moveset))

	if party.is_empty() or enemies.is_empty():
		push_error("BattleManager.setup: empty roster after build")
		return false

	_rebuild_turn_queue()
	turn_number = 1
	current_turn_index = 0
	_set_state(State.READY)
	_set_state(State.AWAIT_ACTION)
	turn_started.emit(current_combatant())
	return true


# ── Queries ──────────────────────────────────────────────────────────────────

func current_combatant() -> Combatant:
	if current_turn_index < 0 or current_turn_index >= turn_queue.size():
		return null
	return turn_queue[current_turn_index]


func live_party() -> Array[Combatant]:
	var result: Array[Combatant] = []
	for c: Combatant in party:
		if c.is_alive():
			result.append(c)
	return result


func live_enemies() -> Array[Combatant]:
	var result: Array[Combatant] = []
	for c: Combatant in enemies:
		if c.is_alive():
			result.append(c)
	return result


func is_battle_over() -> bool:
	return state == State.VICTORY or state == State.DEFEAT


# ── Action execution ─────────────────────────────────────────────────────────

## The caller (player UI or enemy AI) picks a move and targets. This routine
## validates, rolls damage + crit, applies effects, and advances the turn.
## [param move_type_tag] — "normal", "special", or "ultimate"
## [param targets] — Array[Combatant] to hit; for single-target moves pass
##                   a single-element array; for AoE pass the full live list.
## Returns a result Dictionary for animation/logging:
##   {success, move, hits: Array[{target, damage, crit, reaction}]}
func execute_move(move_type_tag: String, targets: Array[Combatant]) -> Dictionary:
	if state != State.AWAIT_ACTION:
		return {"success": false, "error": "not_in_await_action"}

	var actor: Combatant = current_combatant()
	if actor == null or not actor.is_alive():
		return {"success": false, "error": "actor_dead"}

	var move: BattleMove = actor.get_move(move_type_tag)
	if move == null:
		return {"success": false, "error": "unknown_move"}

	if not actor.can_cast(move_type_tag):
		return {"success": false, "error": "insufficient_resource"}

	_set_state(State.RESOLVING)

	# Spend resources up front.
	if move_type_tag == "ultimate":
		actor.stats.consume_ultimate()
	else:
		actor.stats.spend_energy(move.energy_cost)

	# Resolve each hit.
	var hit_results: Array[Dictionary] = []
	var total_damage_dealt: int = 0
	for hit_idx: int in range(move.hits):
		for tgt: Combatant in targets:
			if not tgt.is_alive():
				continue
			var hit: Dictionary = _resolve_hit(actor, tgt, move)
			hit_results.append(hit)
			total_damage_dealt += int(hit.get("damage", 0))

	# Ultimate charge accrual — actor gains ult for the turn based on source.
	_apply_ultimate_charge(actor, total_damage_dealt, hit_results.size())

	move_executed.emit(actor, move, targets)

	_end_turn()

	return {
		"success": true,
		"move": move,
		"hits": hit_results,
	}


# ── Hit resolution ───────────────────────────────────────────────────────────

## Resolves a single hit of a move against a single target.
## Handles damage math, crit roll, elemental charge application, and reactions.
func _resolve_hit(actor: Combatant, target: Combatant, move: BattleMove) -> Dictionary:
	var result: Dictionary = {
		"target": target,
		"damage": 0,
		"crit": false,
		"reaction": "",
	}

	if not move.is_damaging():
		# Non-damaging move (buff/heal/shield). Effect dispatch happens below.
		_apply_effect(actor, target, move)
		return result

	# Raw damage.
	var raw: float = float(actor.stats.atk) * move.damage_mult
	var base_dmg: int = maxi(1, int(raw) - int(target.stats.def_stat / 2))

	# Crit roll.
	var crit_roll: float = _rng.randf() * 100.0
	var is_crit: bool = crit_roll < actor.stats.crit_chance
	if is_crit:
		base_dmg = int(float(base_dmg) * (actor.stats.crit_damage / 100.0))
	result["crit"] = is_crit

	# Elemental reaction check.
	var move_element: String = _resolve_move_element(actor, move)
	var incoming_charge: String = target.stats.elemental_charge
	if not incoming_charge.is_empty() and incoming_charge != move_element and move_element != "Neutral":
		var reaction: Dictionary = ElementalReaction.resolve(incoming_charge, move_element)
		if not reaction.is_empty():
			result["reaction"] = reaction.get("name", "") as String
			_apply_reaction(actor, target, reaction)
			target.stats.elemental_charge = ""  # consumed
			reaction_triggered.emit(result["reaction"], target)
		else:
			target.stats.elemental_charge = move_element
	elif not move_element.is_empty() and move_element != "Neutral":
		target.stats.elemental_charge = move_element

	# Apply damage to the target.
	var actual: int = target.stats.take_damage(base_dmg)
	result["damage"] = actual

	# Apply secondary move effect (e.g. pierce_def, DoTs).
	if not move.effect.is_empty():
		_apply_effect(actor, target, move)

	return result


## Handles the protagonist's "gun" element pull — Artemis etc. have a fixed
## element on their moves. Returns the final element for this move instance.
func _resolve_move_element(actor: Combatant, move: BattleMove) -> String:
	if move.element_source == "gun":
		# Protagonist's gun element comes from the most recently active
		# blessing. For now, fall back to actor.stats.element.
		return actor.stats.element
	if not move.element.is_empty():
		return move.element
	return actor.stats.element


## Applies an elemental reaction effect to the target / party / enemies.
## Reaction effects are a small fixed set — BattleManager owns dispatch here
## rather than in ElementalReaction to keep the data class pure.
func _apply_reaction(actor: Combatant, target: Combatant, reaction: Dictionary) -> void:
	var effect: String = reaction.get("effect", "") as String
	var mag: float = float(reaction.get("magnitude", 0.0))
	var dur: int = int(reaction.get("duration", 0))

	match effect:
		"damage_buff_next":
			actor.stats.active_effects["damage_buff_next"] = {
				"magnitude": mag,
				"turns_left": dur,
			}
		"dot_burn":
			target.stats.active_effects["dot_burn"] = {
				"magnitude": mag * float(actor.stats.atk),
				"turns_left": dur,
			}
		"aoe_damage":
			var aoe_dmg: int = int(float(actor.stats.atk) * mag)
			for e: Combatant in live_enemies():
				e.stats.take_damage(aoe_dmg)
		"party_heal":
			for a: Combatant in live_party():
				a.stats.heal(int(float(a.stats.max_hp) * mag))
		"chain_damage":
			var chain_dmg: int = int(float(actor.stats.atk) * mag)
			var chained: int = 0
			for e: Combatant in live_enemies():
				if e == target:
					continue
				if chained >= 2:
					break
				e.stats.take_damage(chain_dmg)
				chained += 1
		"party_shield":
			for a: Combatant in live_party():
				a.stats.active_effects["shield"] = {
					"magnitude": mag,
					"turns_left": dur,
				}


## Dispatches move-level side effects (distinct from reactions).
func _apply_effect(_actor: Combatant, _target: Combatant, _move: BattleMove) -> void:
	# Placeholder — specific effects will be added alongside the battle scene.
	pass


# ── Ultimate charge ──────────────────────────────────────────────────────────

## Grants ultimate bar to [param actor] after their action based on stats.ult_charge_source.
func _apply_ultimate_charge(actor: Combatant, damage_dealt: int, actions_taken: int) -> void:
	var src: String = actor.stats.ult_charge_source
	var rate: int = actor.stats.ult_charge_rate
	match src:
		"any_action":
			if actions_taken > 0:
				actor.stats.add_ultimate(rate)
		"turns_passed":
			actor.stats.add_ultimate(rate)
		"damage_dealt":
			actor.stats.add_ultimate(rate * int(float(damage_dealt) / 10.0))
		"damage_taken":
			pass  # handled when taking damage (see _on_damage_taken)
		"reactions":
			pass  # handled by reaction_triggered listener (to be wired)


# ── Turn flow ────────────────────────────────────────────────────────────────

func _end_turn() -> void:
	_set_state(State.END_TURN)

	# Victory / defeat check.
	if live_enemies().is_empty():
		_set_state(State.VICTORY)
		battle_ended.emit(true)
		return
	if live_party().is_empty():
		_set_state(State.DEFEAT)
		battle_ended.emit(false)
		return

	# Advance to next living combatant in the queue.
	_advance_turn_pointer()

	# Regen energy for the unit whose turn is starting.
	var next: Combatant = current_combatant()
	if next != null and next.is_alive():
		next.stats.add_energy(_energy_regen_per_turn)

	_set_state(State.AWAIT_ACTION)
	if next != null:
		turn_started.emit(next)


func _advance_turn_pointer() -> void:
	var attempts: int = 0
	var max_attempts: int = turn_queue.size() * 2
	while attempts < max_attempts:
		current_turn_index += 1
		if current_turn_index >= turn_queue.size():
			current_turn_index = 0
			turn_number += 1
			_rebuild_turn_queue()
		var cand: Combatant = current_combatant()
		if cand != null and cand.is_alive():
			return
		attempts += 1


func _rebuild_turn_queue() -> void:
	var all: Array[Combatant] = []
	for c: Combatant in party:
		if c.is_alive():
			all.append(c)
	for c: Combatant in enemies:
		if c.is_alive():
			all.append(c)
	all.sort_custom(func(a: Combatant, b: Combatant) -> bool:
		return a.stats.agi > b.stats.agi
	)
	turn_queue = all
	current_turn_index = 0


func _set_state(new_state: int) -> void:
	state = new_state
	state_changed.emit(new_state)


# ── Display name helpers ─────────────────────────────────────────────────────

func _display_name_for(companion_id: String) -> String:
	if companion_id == "protagonist":
		return "Hero"
	var profile: Dictionary = CompanionRegistry.get_profile(companion_id)
	return profile.get("display_name", companion_id.capitalize()) as String


func _enemy_display_name_for(enemy_id: String) -> String:
	var row: Dictionary = EnemyRegistry.get_enemy(enemy_id)
	var name_key: String = row.get("name_key", "") as String
	if name_key.is_empty():
		return enemy_id.replace("_", " ").capitalize()
	return Localization.get_text(name_key)
