class_name BattleAi
extends RefCounted

## BattleAi — Personality-driven enemy move selection.
##
## Pure function: given a combatant and the current BattleManager state, pick
## the move_type + targets the enemy will use on their turn. The UI layer
## (battle.gd::_run_enemy_ai) calls choose_action and then passes the result
## to BattleManager.execute_move.
##
## Profiles are read from Combatant.stats.ai_profile — one of:
##
##   aggressive — spam the highest-damage move available; finish wounded
##                allies first (target lowest-HP ally).
##   tactical   — favor specials with effects; save ultimate for topped-up
##                parties; target the highest-ATK ally to blunt damage.
##   berserker  — scales with own HP loss; goes all-in (ult → special → basic)
##                as HP drops; always targets the protagonist.
##   defensive  — prefers self-buffing specials (party_shield, dodge) when
##                available; otherwise plinks with normal attacks; targets
##                the highest-ATK ally (neutralize threat).
##
## Any unknown profile falls back to "aggressive".
##
## Random choices are made through a local RNG seeded from the engine so
## tests can override via BattleAi.rng if they need determinism.

static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Picks the move + targets for [param actor] against the given battle state.
## Returns a Dictionary of shape:
##   {"move_type": String, "targets": Array[Combatant]}
## If the actor has no valid move (all null or target list empty) returns
## {"move_type": "normal", "targets": []} — caller should skip the turn.
static func choose_action(actor: Combatant, battle: BattleManager) -> Dictionary:
	if actor == null or battle == null:
		return {"move_type": "normal", "targets": [] as Array[Combatant]}

	var profile: String = actor.stats.ai_profile if actor.stats != null else "aggressive"
	var move_type: String = ""
	match profile:
		"tactical":
			move_type = _pick_tactical(actor, battle)
		"berserker":
			move_type = _pick_berserker(actor, battle)
		"defensive":
			move_type = _pick_defensive(actor, battle)
		_:
			move_type = _pick_aggressive(actor, battle)

	# Resolve to an actual move object, downgrading if the picked type is
	# unavailable (no resources, no move in slot, etc.).
	var move: BattleMove = actor.get_move(move_type)
	if move == null or not actor.can_cast(move_type):
		move_type = "special" if actor.can_cast("special") else "normal"
		move = actor.get_move(move_type)
	if move == null:
		move = actor.get_move("normal")
		move_type = "normal"
	if move == null:
		return {"move_type": "normal", "targets": [] as Array[Combatant]}

	var targets: Array[Combatant] = _pick_targets(actor, battle, move, profile)
	return {"move_type": move_type, "targets": targets}


# ── Move selection per profile ───────────────────────────────────────────────

## Aggressive — always reach for the biggest hammer. Ult > special > normal,
## with zero finesse. Random tie-breaking is irrelevant because we always
## prefer bigger moves when resource-available.
static func _pick_aggressive(actor: Combatant, _battle: BattleManager) -> String:
	if actor.can_cast("ultimate"):
		return "ultimate"
	if actor.can_cast("special"):
		return "special"
	return "normal"


## Tactical — saves the ult for when the player party is healthy enough to
## make the payout worthwhile. Otherwise picks the special about 70% of the
## time, falling through to normal.
static func _pick_tactical(actor: Combatant, battle: BattleManager) -> String:
	var party_hp_frac: float = _party_hp_fraction(battle)
	if actor.can_cast("ultimate") and party_hp_frac > 0.75:
		return "ultimate"
	if actor.can_cast("special") and rng.randf() < 0.7:
		return "special"
	return "normal"


## Berserker — aggression scales with own HP loss. Under 50% HP always dumps
## the ult; under 25% always uses special (if no ult); otherwise a middling
## mix. Classic "cornered animal" pattern.
static func _pick_berserker(actor: Combatant, _battle: BattleManager) -> String:
	var hp_frac: float = actor.stats.hp_fraction()
	if actor.can_cast("ultimate") and hp_frac < 0.5:
		return "ultimate"
	if actor.can_cast("special") and hp_frac < 0.75:
		return "special"
	if actor.can_cast("special") and rng.randf() < 0.3:
		return "special"
	return "normal"


## Defensive — prefers a self-buff / party-shield special when available and
## the enemy isn't already protected. Falls back to normal attacks. Never
## bothers with its ultimate bar (rare trade-off baked into the profile).
static func _pick_defensive(actor: Combatant, _battle: BattleManager) -> String:
	if actor.can_cast("special"):
		var has_shield: bool = actor.stats.active_effects.has("shield")
		if not has_shield and rng.randf() < 0.6:
			return "special"
	return "normal"


# ── Target selection ─────────────────────────────────────────────────────────

## Resolves a target list for [param move] cast by [param actor] according
## to the move's target field (single_enemy, all_enemies, self, etc.) and the
## actor's AI profile for single-target picks.
static func _pick_targets(actor: Combatant, battle: BattleManager, move: BattleMove, profile: String) -> Array[Combatant]:
	# From the enemy's perspective "enemies" are the player party.
	var player_side: Array[Combatant] = battle.live_party()
	var enemy_side: Array[Combatant] = battle.live_enemies()

	# Self-target / party buffs target the caster's own side.
	if move.target == "self":
		return [actor] as Array[Combatant]
	if move.target == "all_allies":
		return enemy_side

	# Multi-target damage moves hit the whole player side.
	if move.targets_many():
		return player_side

	if player_side.is_empty():
		return [] as Array[Combatant]

	# Single-target picks vary by profile.
	var choice: Combatant = null
	match profile:
		"aggressive":
			choice = _lowest_hp(player_side)
		"tactical", "defensive":
			choice = _highest_atk(player_side)
		"berserker":
			choice = _find_protagonist(player_side)
			if choice == null:
				choice = player_side[0]
		_:
			choice = player_side[0]

	if choice == null:
		choice = player_side[0]
	return [choice] as Array[Combatant]


# ── Helpers ──────────────────────────────────────────────────────────────────

static func _party_hp_fraction(battle: BattleManager) -> float:
	var total: int = 0
	var current: int = 0
	for c: Combatant in battle.party:
		total += c.stats.max_hp
		current += c.stats.current_hp
	if total <= 0:
		return 1.0
	return float(current) / float(total)


static func _lowest_hp(candidates: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for c: Combatant in candidates:
		if best == null or c.stats.current_hp < best.stats.current_hp:
			best = c
	return best


static func _highest_atk(candidates: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for c: Combatant in candidates:
		if best == null or c.stats.atk > best.stats.atk:
			best = c
	return best


static func _find_protagonist(candidates: Array[Combatant]) -> Combatant:
	for c: Combatant in candidates:
		if c.is_protagonist:
			return c
	return null
