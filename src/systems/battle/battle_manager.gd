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

## Active battle blessings per ally id — populated during setup from
## battle_blessings.json, filtered by the companion's current romance
## stage. Exposed for the UI (HUD shows the count).
## Schema: {companion_id: Array[blessing_dict]}
var active_blessings: Dictionary = {}

## Player-side turn time limit in seconds. Computed in setup() as the max
## of `turn_timer_seconds` across all enemies. 0 means no timer (the
## encounter is untimed). The battle scene reads this once and instantiates
## a BattleTurnTimer if it's > 0.
var turn_time_limit: int = 0

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
	active_blessings.clear()
	var battle_blessings: Dictionary = JsonLoader.load_dict("res://assets/data/battle_blessings.json")
	for pid: String in party_ids:
		var row: Dictionary = char_rows.get(pid, {}) as Dictionary
		if row.is_empty():
			push_warning("BattleManager.setup: unknown party id '%s' — skipping" % pid)
			continue
		var moveset: Dictionary = movesets.get(pid, {}) as Dictionary
		var is_proto: bool = pid == "protagonist"
		var name: String = _display_name_for(pid)
		var combatant: Combatant = Combatant.build(pid, name, false, is_proto, row, moveset)

		# Apply passive blessings for this companion. Protagonist has none —
		# they come from the other companions' relationship stages.
		if not is_proto and battle_blessings.has(pid):
			var applied: Array[Dictionary] = _apply_blessings_to(combatant, battle_blessings[pid] as Array)
			if not applied.is_empty():
				active_blessings[pid] = applied

		party.append(combatant)

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

	# Level scaling — apply per-level stat bonuses after the party-build loop
	# above (which already inlined blessings). Blessings and level bonuses are
	# both purely additive so the order is mathematically equivalent; this
	# pass runs here for code clarity, not correctness. Protagonist scales
	# the same way under id "protagonist".
	for combatant: Combatant in party:
		var level: int = GameStore.get_companion_level(combatant.id)
		CompanionLevel.apply_to_stats(combatant.stats, level)

	# Gun element — the protagonist's gun fires whichever element the first
	# companion in the party supplies. Slot 0 is always the protagonist, so the
	# first non-proto ally at slot 1 is the source. If the party is proto-only
	# the gun stays on its default "Neutral" element.
	_apply_gun_element()

	# Encounter turn timer — pick the max declared timer across enemies. The
	# battle scene reads this and decides whether to instantiate a timer UI.
	turn_time_limit = 0
	for e: Combatant in enemies:
		var t: int = e.stats.turn_timer_seconds
		if t > turn_time_limit:
			turn_time_limit = t

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

	# An empty target list would waste the turn AND consume resources
	# (ultimate / energy are spent below). Reject early so the caller can
	# pick a valid target and try again — this previously caused an
	# invisible turn skip when BattleAi handed back [] for a degenerate
	# encounter.
	if targets.is_empty():
		return {"success": false, "error": "no_targets"}

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

			# repeat_on_crit (Hippolyta): keep striking while critting, cap 2 extra.
			if move.effect == "repeat_on_crit" and bool(hit.get("crit", false)):
				var repeats: int = 0
				while repeats < 2 and tgt.is_alive():
					var extra: Dictionary = _resolve_hit(actor, tgt, move)
					extra["repeat"] = true
					hit_results.append(extra)
					total_damage_dealt += int(extra.get("damage", 0))
					if not bool(extra.get("crit", false)):
						break
					repeats += 1

	# Ultimate charge accrual — actor gains ult for the turn based on source.
	_apply_ultimate_charge(actor, total_damage_dealt, hit_results.size())

	move_executed.emit(actor, move, targets)

	_end_turn()

	return {
		"success": true,
		"move": move,
		"hits": hit_results,
	}


## Auto-cast a normal attack on a random living enemy. Used by the battle
## scene when the player turn timer expires — drives the battle forward
## with a sensible default action so a distracted player still plays the
## game. Uses the same execute_move path as a manual cast, so all energy /
## charge / blessing / animation logic runs identically.
func auto_normal_attack() -> Dictionary:
	if state != State.AWAIT_ACTION:
		return {"success": false, "error": "not_in_await_action"}
	var actor: Combatant = current_combatant()
	if actor == null or actor.is_enemy:
		return {"success": false, "error": "not_a_player_turn"}
	var living: Array[Combatant] = live_enemies()
	if living.is_empty():
		return {"success": false, "error": "no_living_enemies"}
	var target: Combatant = living[_rng.randi() % living.size()]
	return execute_move("normal", [target] as Array[Combatant])


# ── Hit resolution ───────────────────────────────────────────────────────────

## Resolves a single hit of a move against a single target.
## Handles damage math, crit roll, elemental charge application, and reactions.
func _resolve_hit(actor: Combatant, target: Combatant, move: BattleMove) -> Dictionary:
	var result: Dictionary = {
		"target": target,
		"damage": 0,
		"crit": false,
		"reaction": "",
		"dodged": false,
		"effect": move.effect,
	}

	if not move.is_damaging():
		# Non-damaging move (buff/heal/shield). Effect dispatch only.
		_apply_effect(actor, target, move)
		return result

	# Dodge — consume target's "dodge_next" if present and skip the hit.
	if target.stats.active_effects.has("dodge_next"):
		target.stats.active_effects.erase("dodge_next")
		result["dodged"] = true
		return result

	# Defense subtraction — reduced or skipped by pierce/ignore effects.
	var def_divisor: int = 2
	if move.effect == "pierce_def":
		def_divisor = 4  # half the usual DEF
	var def_subtract: int = int(target.stats.def_stat / def_divisor)
	if move.effect == "ignore_defense":
		def_subtract = 0

	# Raw damage.
	var raw: float = float(actor.stats.atk) * move.damage_mult
	var base_dmg: int = maxi(1, int(raw) - def_subtract)

	# Crit roll (forced_crit buff overrides the random roll).
	var is_crit: bool = false
	if actor.stats.active_effects.has("forced_crit"):
		is_crit = true
	else:
		var crit_roll: float = _rng.randf() * 100.0
		is_crit = crit_roll < actor.stats.crit_chance
	if is_crit:
		base_dmg = int(float(base_dmg) * (actor.stats.crit_damage / 100.0))
	result["crit"] = is_crit

	# Hunter mark — target takes amplified damage.
	if target.stats.active_effects.has("hunter_mark"):
		var hm: Dictionary = target.stats.active_effects["hunter_mark"] as Dictionary
		var hm_amp: float = 1.0 + float(hm.get("magnitude", 0.5))
		base_dmg = int(float(base_dmg) * hm_amp)

	# damage_buff_next (Oracle Mist reaction buff) — consumed on this hit.
	if actor.stats.active_effects.has("damage_buff_next"):
		var db: Dictionary = actor.stats.active_effects["damage_buff_next"] as Dictionary
		var db_pct: float = float(db.get("magnitude", 50.0)) / 100.0
		base_dmg = int(float(base_dmg) * (1.0 + db_pct))
		actor.stats.active_effects.erase("damage_buff_next")

	# Shield — target absorbs a fraction of the incoming damage.
	if target.stats.active_effects.has("shield"):
		var sh: Dictionary = target.stats.active_effects["shield"] as Dictionary
		var sh_pct: float = float(sh.get("magnitude", 0.3))
		base_dmg = maxi(1, int(float(base_dmg) * (1.0 - sh_pct)))

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

	# Apply secondary move effect (e.g. hunter_mark application, DoTs).
	if not move.effect.is_empty():
		_apply_effect(actor, target, move)

	return result


## Handles the protagonist's "gun" element pull — the gun element is assigned
## at setup time based on the first companion in the party (see
## _apply_gun_element). Returns the final element for this move instance.
func _resolve_move_element(actor: Combatant, move: BattleMove) -> String:
	if move.element_source == "gun":
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
##
## Effects fall into three families:
##   1) Inline damage modifiers ("pierce_def", "ignore_defense", "repeat_on_crit")
##      are applied in _resolve_hit / execute_move and are no-ops here.
##   2) Buffs / debuffs write to active_effects with either turns_left or a
##      one-shot consumable flag. These are ticked by _tick_effects_for().
##   3) DoTs write to active_effects with turns_left + magnitude and apply
##      damage in _tick_effects_for() at the victim's turn boundary.
func _apply_effect(actor: Combatant, target: Combatant, move: BattleMove) -> void:
	match move.effect:
		"pierce_def", "ignore_defense", "repeat_on_crit":
			pass  # handled inline in _resolve_hit / execute_move

		"apply_hunter_mark_2_turns":
			# Artemis ult — mark target; next hits against them do +50%.
			target.stats.active_effects["hunter_mark"] = {
				"magnitude": 0.5,
				"turns_left": 2,
			}

		"guaranteed_crit_3_turns":
			# Hippolyta ult — self-buff; all outgoing hits auto-crit for 3 turns.
			actor.stats.active_effects["forced_crit"] = {
				"turns_left": 3,
			}

		"party_shield_30_percent":
			# Atenea special — all allies absorb 30% incoming damage for 2 turns.
			# Ally dispatch: a player caster's "allies" are the party, an enemy
			# caster's "allies" are the enemies. The obsidian_guardian enemy
			# relies on this branch to buff its fellow enemies in the encounter.
			var allies: Array[Combatant] = live_enemies() if actor.is_enemy else live_party()
			for a: Combatant in allies:
				a.stats.active_effects["shield"] = {
					"magnitude": 0.30,
					"turns_left": 2,
				}

		"dodge_next_attack":
			# Nyx special — self-buff that dodges the next incoming hit.
			actor.stats.active_effects["dodge_next"] = {
				"magnitude": 1.0,
			}

		"dispel_enemy_buffs":
			# Nyx ult — clear buff-family effects from all enemies of the actor.
			var buff_keys: Array[String] = [
				"shield", "forced_crit", "damage_buff_next", "dodge_next",
			]
			var foes: Array[Combatant] = live_enemies() if not actor.is_enemy else live_party()
			for e: Combatant in foes:
				for key: String in buff_keys:
					if e.stats.active_effects.has(key):
						e.stats.active_effects.erase(key)

		"corrupted_bloom":
			# Gaia boss ult — DoT on every enemy of the caster. Actor-side
			# dispatch mirrors dispel_enemy_buffs above so the two effects
			# read the same way.
			var poison_dmg: float = float(actor.stats.atk) * 0.25
			var victims: Array[Combatant] = live_party() if actor.is_enemy else live_enemies()
			for v: Combatant in victims:
				v.stats.active_effects["corrupted_bloom"] = {
					"magnitude": poison_dmg,
					"turns_left": 3,
				}

		_:
			if not move.effect.is_empty():
				push_warning("BattleManager: unknown move effect '%s'" % move.effect)


## Ticks down per-turn effects on a single combatant and applies any DoTs.
## Called in _end_turn for the actor whose turn just ended — that way a
## 3-turn buff applied at the start of turn N lasts through turn N+2 of the
## same unit. DoT damage is applied on tick then the counter decrements.
func _tick_effects_for(combatant: Combatant) -> void:
	if combatant == null or combatant.stats == null:
		return
	var effects: Dictionary = combatant.stats.active_effects
	if effects.is_empty():
		return

	# Apply DoT damage first so an expiring DoT still deals its final tick.
	if effects.has("dot_burn"):
		var burn: Dictionary = effects["dot_burn"] as Dictionary
		var burn_mag: int = maxi(1, int(float(burn.get("magnitude", 0.0))))
		combatant.stats.take_damage(burn_mag)
	if effects.has("corrupted_bloom"):
		var cb: Dictionary = effects["corrupted_bloom"] as Dictionary
		var cb_mag: int = maxi(1, int(float(cb.get("magnitude", 0.0))))
		combatant.stats.take_damage(cb_mag)

	# Decrement turns_left on every duration-based effect and drop expired.
	var to_remove: Array[String] = []
	for key_variant: Variant in effects.keys():
		var key: String = key_variant as String
		var entry_variant: Variant = effects[key]
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant as Dictionary
		if not entry.has("turns_left"):
			continue
		var remaining: int = int(entry["turns_left"]) - 1
		if remaining <= 0:
			to_remove.append(key)
		else:
			entry["turns_left"] = remaining
	for key: String in to_remove:
		effects.erase(key)


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

	# Tick duration effects on the actor whose turn just ended. Buffs the actor
	# cast on themselves (forced_crit, shield, etc.) count down here. DoTs on
	# the actor also tick — an enemy poisoned by a DoT will take damage at the
	# close of their own turn.
	var ending_actor: Combatant = current_combatant()
	if ending_actor != null:
		_tick_effects_for(ending_actor)

	# Victory / defeat check (DoT ticks above may have killed someone).
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


# ── Passive blessings (Phase E) ──────────────────────────────────────────────

## Applies all unlocked blessings for [param combatant] from the companion's
## 5-slot list in battle_blessings.json. Filters by the companion's current
## romance stage via CompanionState.get_romance_stage. Mutates combatant.stats
## in place (base values, not runtime state — current_hp also bumps to the
## new max_hp so the companion starts at full HP).
## Returns the Array of blessing dicts that were actually applied.
func _apply_blessings_to(combatant: Combatant, all_blessings: Array) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	var stage: int = CompanionState.get_romance_stage(combatant.id)
	var max_slot: int = _max_slot_for_stage(stage)
	if max_slot == 0:
		return applied

	for entry: Variant in all_blessings:
		var b: Dictionary = entry as Dictionary
		var slot: int = int(b.get("slot", 0))
		if slot <= 0 or slot > max_slot:
			continue
		_apply_blessing_effect(combatant.stats, b)
		applied.append(b)

	# Starting HP follows any hp_flat bump.
	combatant.stats.current_hp = combatant.stats.max_hp
	return applied


## Dispatches on the blessing's "effect" field and mutates the BattleStats.
func _apply_blessing_effect(stats: BattleStats, blessing: Dictionary) -> void:
	var effect: String = blessing.get("effect", "") as String
	var magnitude: float = float(blessing.get("magnitude", 0))
	match effect:
		"atk_flat":
			stats.atk += int(magnitude)
		"def_flat":
			stats.def_stat += int(magnitude)
		"hp_flat":
			stats.max_hp += int(magnitude)
		"crit_chance":
			stats.crit_chance += magnitude
		"crit_damage":
			stats.crit_damage += magnitude
		"agi_flat":
			stats.agi += int(magnitude)
		"ult_charge_bonus":
			stats.ult_charge_rate += int(magnitude)
		_:
			push_warning("BattleManager: unknown blessing effect '%s'" % effect)


## Mirrors the ADR-0012 stage-to-max-slot table used by the poker
## BlessingSystem. Keeping the lookup local avoids a dependency on that
## class and lets battle blessings diverge if the design needs to later.
func _max_slot_for_stage(stage: int) -> int:
	match stage:
		0: return 0
		1: return 1
		2: return 2
		3: return 4
		4: return 5
		_: return 0


# ── Gun element ──────────────────────────────────────────────────────────────

## Sets the protagonist's effective element from the first companion in the
## party. Narrative hook: each goddess imprints her element on Hero's gun when
## she joins the party. Called once at the end of setup(); no-op if the party
## has no companions or no protagonist slot.
func _apply_gun_element() -> void:
	if party.is_empty():
		return
	var proto: Combatant = null
	for c: Combatant in party:
		if c.is_protagonist:
			proto = c
			break
	if proto == null:
		return

	# First non-protagonist ally in party order is the gun source.
	for c: Combatant in party:
		if c.is_protagonist:
			continue
		if c.stats == null:
			continue
		var companion_element: String = c.stats.element
		if companion_element.is_empty() or companion_element == "Neutral":
			continue
		proto.stats.element = companion_element
		return


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
