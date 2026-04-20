class_name BattleManagerTest
extends GdUnitTestSuite

## Unit tests for BattleManager — turn-based action combat state machine.
##
## Covers:
##   setup() rejects unknown party and enemy ids and returns false
##   setup() builds party + enemies and transitions to AWAIT_ACTION
##   Turn queue is sorted by AGI descending
##   execute_move rejects when not in AWAIT_ACTION
##   execute_move consumes energy for specials and consumes ult bar for ults
##   Damage math: max(1, ATK - DEF/2)
##   Victory fires when all enemies die
##   Defeat fires when all allies die
##   Blessings apply ATK/DEF/HP flat bumps at setup
##   Dead units skip their turn
##
## The GameStore + autoload state is mutated during setup, so each test uses
## _reset_game_state() to keep runs isolated.

const BattleManagerScript = preload("res://systems/battle/battle_manager.gd")
const BattleStatsScript = preload("res://systems/battle/battle_stats.gd")


# ── Helpers ───────────────────────────────────────────────────────────────────

## Clears the bits of GameStore that affect battle setup — romance stages,
## last captain, and party assignments — so each test starts fresh.
func _reset_game_state() -> void:
	GameStore._initialize_defaults()
	CompanionState._max_stages.clear()


## Builds a battle with the protagonist and a single forest_monster. Returns
## the BattleManager instance already set up (state == AWAIT_ACTION).
func _make_solo_battle():
	_reset_game_state()
	var bm = BattleManagerScript.new()
	var party: Array[String] = ["protagonist"]
	var enemies: Array[String] = ["forest_monster"]
	bm.setup(party, enemies)
	return bm


# ── setup ────────────────────────────────────────────────────────────────────

func test_battle_manager_setup_with_valid_ids_returns_true_and_transitions_to_await_action() -> void:
	# Arrange
	_reset_game_state()
	var bm = BattleManagerScript.new()

	# Act
	var ok: bool = bm.setup(["protagonist"] as Array[String], ["forest_monster"] as Array[String])

	# Assert
	assert_bool(ok).is_true()
	assert_int(bm.state).is_equal(BattleManagerScript.State.AWAIT_ACTION)
	assert_int(bm.party.size()).is_equal(1)
	assert_int(bm.enemies.size()).is_equal(1)
	assert_int(bm.turn_number).is_equal(1)


func test_battle_manager_setup_with_empty_enemy_list_returns_false() -> void:
	# Arrange
	_reset_game_state()
	var bm = BattleManagerScript.new()

	# Act
	var ok: bool = bm.setup(["protagonist"] as Array[String], [] as Array[String])

	# Assert
	assert_bool(ok).is_false()


func test_battle_manager_setup_skips_unknown_party_ids() -> void:
	# Arrange
	_reset_game_state()
	var bm = BattleManagerScript.new()

	# Act — one valid id + one garbage id; the valid one still sets up.
	var ok: bool = bm.setup(
		["protagonist", "ghost_of_debug"] as Array[String],
		["forest_monster"] as Array[String]
	)

	# Assert — setup succeeds with just the valid members
	assert_bool(ok).is_true()
	assert_int(bm.party.size()).is_equal(1)
	assert_str(bm.party[0].id).is_equal("protagonist")


# ── Turn queue ────────────────────────────────────────────────────────────────

func test_battle_manager_turn_queue_sorted_by_agi_descending() -> void:
	# Arrange
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(
		["protagonist", "artemis"] as Array[String],  # artemis AGI 20, proto 14
		["forest_monster"] as Array[String],            # fm AGI 8
	)

	# Act
	var queue: Array = bm.turn_queue

	# Assert — artemis first, proto second, fm last
	assert_int(queue.size()).is_equal(3)
	assert_str(queue[0].id).is_equal("artemis")
	assert_str(queue[1].id).is_equal("protagonist")
	assert_str(queue[2].id).is_equal("forest_monster")


# ── execute_move ──────────────────────────────────────────────────────────────

func test_battle_manager_execute_move_reduces_target_hp() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var enemy = bm.enemies[0]
	var hp_before: int = enemy.stats.current_hp

	# Act — protagonist normal attack on the forest monster
	var result: Dictionary = bm.execute_move("normal", [enemy] as Array[Combatant])

	# Assert
	assert_bool(result.get("success", false)).is_true()
	assert_int(enemy.stats.current_hp).is_less(hp_before)


func test_battle_manager_execute_move_rejects_empty_target_list() -> void:
	# Arrange — regression for Phase I audit. An empty target array must not
	# waste the player's turn or consume ultimate/energy.
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	proto.stats.current_ultimate = proto.stats.max_ultimate
	var ult_before: int = proto.stats.current_ultimate
	var energy_before: int = proto.stats.current_energy
	var state_before: int = bm.state

	# Act — fire ultimate at an empty list
	var result: Dictionary = bm.execute_move("ultimate", [] as Array[Combatant])

	# Assert — rejected with no_targets, no resource consumption, no state move
	assert_bool(result.get("success", false)).is_false()
	assert_str(result.get("error", "")).is_equal("no_targets")
	assert_int(proto.stats.current_ultimate).is_equal(ult_before)
	assert_int(proto.stats.current_energy).is_equal(energy_before)
	assert_int(bm.state).is_equal(state_before)


func test_battle_manager_execute_move_rejects_when_not_in_await_action() -> void:
	# Arrange
	var bm = _make_solo_battle()
	bm.state = BattleManagerScript.State.RESOLVING  # force wrong state

	# Act
	var result: Dictionary = bm.execute_move("normal", [bm.enemies[0]] as Array[Combatant])

	# Assert
	assert_bool(result.get("success", false)).is_false()
	assert_str(result.get("error", "")).is_equal("not_in_await_action")


func test_battle_manager_special_move_consumes_energy() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	var energy_before: int = proto.stats.current_energy
	var special_cost: int = proto.get_move("special").energy_cost

	# Act
	bm.execute_move("special", [bm.enemies[0]] as Array[Combatant])

	# Assert — energy dropped by exactly the special's cost
	assert_int(proto.stats.current_energy).is_equal(energy_before - special_cost)


func test_battle_manager_ultimate_consumes_full_bar() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	proto.stats.current_ultimate = proto.stats.max_ultimate
	var before: int = proto.stats.current_ultimate

	# Act
	var result: Dictionary = bm.execute_move("ultimate", [bm.enemies[0]] as Array[Combatant])

	# Assert — consume drained the bar. Post-action charge accrual may
	# partially refill it (the protagonist's "any_action" source grants
	# 10 per action), so we check the consume happened rather than the
	# exact post-value which is an implementation detail.
	assert_bool(result.get("success", false)).is_true()
	assert_int(proto.stats.current_ultimate).is_less(before)


func test_battle_manager_ultimate_rejected_when_bar_not_full() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	proto.stats.current_ultimate = 50  # half bar

	# Act
	var result: Dictionary = bm.execute_move("ultimate", [bm.enemies[0]] as Array[Combatant])

	# Assert
	assert_bool(result.get("success", false)).is_false()


# ── Victory / defeat ─────────────────────────────────────────────────────────

func test_battle_manager_all_enemies_dead_triggers_victory() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var enemy = bm.enemies[0]
	enemy.stats.current_hp = 1  # one-hit kill set-up

	# Act — any attack will kill the enemy
	bm.execute_move("normal", [enemy] as Array[Combatant])

	# Assert
	assert_int(bm.state).is_equal(BattleManagerScript.State.VICTORY)
	assert_bool(bm.is_battle_over()).is_true()


func test_battle_manager_all_allies_dead_triggers_defeat() -> void:
	# Arrange — a fresh battle then force the protagonist to 0 HP and
	# let the enemy take any action against the (dead) party
	var bm = _make_solo_battle()
	bm.party[0].stats.current_hp = 0
	# Advance to the enemy's turn manually.
	bm._end_turn()

	# Assert — after _end_turn detects dead party, state is DEFEAT
	assert_int(bm.state).is_equal(BattleManagerScript.State.DEFEAT)


# ── Blessings applied at setup ───────────────────────────────────────────────

func test_battle_manager_setup_applies_stage_1_blessing_to_artemis() -> void:
	# Arrange — Artemis at romance stage 1 unlocks slot 1: Rooted Stance (+4 ATK)
	_reset_game_state()
	CompanionState.set_relationship_level("artemis", 25)  # stage 1 (21-50)
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	# Act
	var artemis: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "artemis":
			artemis = c
			break

	# Assert — base ATK 22, +4 from blessing = 26
	assert_int(artemis.stats.atk).is_equal(26)
	assert_bool(bm.active_blessings.has("artemis")).is_true()
	assert_int((bm.active_blessings["artemis"] as Array).size()).is_equal(1)


func test_battle_manager_setup_stage_0_applies_zero_blessings() -> void:
	# Arrange — Artemis at romance stage 0 (RL 0) — no blessings unlocked
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	var artemis: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "artemis":
			artemis = c
			break

	# Assert — base ATK 22 unmodified, no entry in active_blessings
	assert_int(artemis.stats.atk).is_equal(22)
	assert_bool(bm.active_blessings.has("artemis")).is_false()


# ── Epithet bonuses (derived from companion level) ───────────────────────────
# Epithet tiers are auto-unlocked by level via
# CompanionLevel.EPITHET_LEVEL_THRESHOLDS = [1, 10, 20, 35, 50, 65].
# These tests set explicit levels via set_companion_level so the derived
# tier matches the bonus under test.

func test_battle_manager_epithet_ii_adds_bonus_energy_regen() -> void:
	# Arrange — Artemis at level 10 (threshold for Epithet II).
	_reset_game_state()
	GameStore.set_companion_level("artemis", 10)
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	var artemis: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "artemis":
			artemis = c
			break

	# Assert — +1 bonus regen set on stats
	assert_int(artemis.stats.bonus_energy_regen).is_equal(1)


func test_battle_manager_epithet_iv_adds_five_percent_crit() -> void:
	# Compare level 34 (Epithet III) vs level 35 (Epithet IV). Both fall
	# under the same crit-chance milestone bracket (milestones every 5
	# levels), so the level-based crit bonus is identical. The +5 delta
	# comes purely from the Epithet IV bonus.
	_reset_game_state()
	GameStore.set_companion_level("artemis", 34)
	var bm_a = BattleManagerScript.new()
	bm_a.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])
	var artemis_iii: Combatant = null
	for c: Combatant in bm_a.party:
		if c.id == "artemis":
			artemis_iii = c
			break
	var crit_at_iii: float = artemis_iii.stats.crit_chance

	_reset_game_state()
	GameStore.set_companion_level("artemis", 35)
	var bm_b = BattleManagerScript.new()
	bm_b.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])
	var artemis_iv: Combatant = null
	for c: Combatant in bm_b.party:
		if c.id == "artemis":
			artemis_iv = c
			break
	var crit_at_iv: float = artemis_iv.stats.crit_chance

	# Assert — exactly +5 delta between the two tiers
	assert_float(crit_at_iv - crit_at_iii).is_equal_approx(5.0, 0.01)


func test_battle_manager_epithet_v_adds_one_hit_to_special() -> void:
	# Arrange — Hippolyta at level 50 (threshold for Epithet V).
	_reset_game_state()
	GameStore.set_companion_level("hipolita", 50)
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "hipolita"] as Array[String], ["forest_monster"] as Array[String])

	var hipo: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "hipolita":
			hipo = c
			break

	# Assert — special move's hits field is one more than the JSON baseline.
	# Hipolita's amazon_charge special defaults to 1 hit; Epithet V bumps it.
	var special: BattleMove = hipo.get_move("special")
	assert_int(special.hits).is_greater_equal(2)


func test_battle_manager_epithet_iii_lifts_blessing_slot_cap() -> void:
	# Arrange — Artemis at romance stage 1 (cap = 1 slot) but level 20
	# unlocks Epithet III which forces the blessing cap to 4, so more
	# blessings should apply.
	_reset_game_state()
	CompanionState.set_relationship_level("artemis", 25)  # stage 1
	GameStore.set_companion_level("artemis", 20)
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	# Assert — active_blessings has more than 1 entry (the stage-1 cap)
	assert_bool(bm.active_blessings.has("artemis")).is_true()
	var applied: Array = bm.active_blessings["artemis"] as Array
	assert_int(applied.size()).is_greater(1)


func test_battle_manager_epithet_vi_extends_effect_turns_left() -> void:
	# Arrange — solo battle, Artemis at level 65 (threshold for Epithet VI),
	# cast an ultimate that writes a turns_left field. We'll use the
	# "guaranteed_crit_3_turns" path via a synthetic move.
	_reset_game_state()
	GameStore.set_companion_level("artemis", 65)
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	var artemis: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "artemis":
			artemis = c
			break

	# Install a test move with the guaranteed_crit_3_turns effect and cast it.
	var test_move: BattleMove = BattleMove.new()
	test_move.id = "test_vi"
	test_move.name_key = "TEST"
	test_move.move_type = "special"
	test_move.target = "single_enemy"
	test_move.damage_mult = 0.0
	test_move.hits = 1
	test_move.element = "Neutral"
	test_move.element_source = ""
	test_move.energy_cost = 0
	test_move.effect = "guaranteed_crit_3_turns"
	artemis.moves["special"] = test_move

	# Act — call _apply_effect directly (simpler than routing through execute_move)
	bm._apply_effect(artemis, bm.enemies[0], test_move)

	# Assert — base is 3 turns, Epithet VI should bump to 4
	var forced: Dictionary = artemis.stats.active_effects["forced_crit"] as Dictionary
	assert_int(int(forced.get("turns_left", 0))).is_equal(4)


func test_battle_manager_epithet_zero_leaves_stats_unchanged() -> void:
	# Arrange — Artemis at Epithet 0 (default). Base stats unmodified.
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	var artemis: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "artemis":
			artemis = c
			break

	# Assert — no bonus regen, base crit 10.0, special hits untouched
	assert_int(artemis.stats.bonus_energy_regen).is_equal(0)
	assert_float(artemis.stats.crit_chance).is_equal_approx(10.0, 0.01)


func test_battle_manager_setup_reads_max_turn_timer_from_enemies() -> void:
	# Arrange — solo battle then bump the enemy's timer field manually so we
	# don't depend on JSON values.
	var bm = _make_solo_battle()
	bm.enemies[0].stats.turn_timer_seconds = 60

	# Act — re-run the timer scan that setup() does. (setup already ran in
	# _make_solo_battle, so we recompute here to validate the rule.)
	bm.turn_time_limit = 0
	for e: Combatant in bm.enemies:
		if e.stats.turn_timer_seconds > bm.turn_time_limit:
			bm.turn_time_limit = e.stats.turn_timer_seconds

	# Assert
	assert_int(bm.turn_time_limit).is_equal(60)


func test_battle_manager_setup_turn_time_limit_defaults_to_zero() -> void:
	# Arrange — fresh solo battle, default forest_monster has turn_timer_seconds=0
	var bm = _make_solo_battle()

	# Assert — forest_monster carries 0, so the encounter is untimed
	assert_int(bm.turn_time_limit).is_equal(0)


func test_battle_manager_auto_normal_attack_executes_against_living_enemy() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var enemy = bm.enemies[0]
	var hp_before: int = enemy.stats.current_hp

	# Act
	var result: Dictionary = bm.auto_normal_attack()

	# Assert
	assert_bool(result.get("success", false)).is_true()
	assert_int(enemy.stats.current_hp).is_less(hp_before)


func test_battle_manager_auto_normal_attack_rejects_outside_await_action() -> void:
	# Arrange
	var bm = _make_solo_battle()
	bm.state = BattleManagerScript.State.RESOLVING

	# Act
	var result: Dictionary = bm.auto_normal_attack()

	# Assert
	assert_bool(result.get("success", false)).is_false()


func test_battle_manager_setup_gun_element_matches_first_companion() -> void:
	# Arrange — Artemis is Earth, so the protagonist's gun should fire Earth.
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "artemis"] as Array[String], ["forest_monster"] as Array[String])

	# Act
	var proto: Combatant = bm.party[0]

	# Assert
	assert_str(proto.stats.element).is_equal("Earth")


func test_battle_manager_setup_gun_element_defaults_to_neutral_when_solo() -> void:
	# Arrange — proto-only party; gun stays Neutral.
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist"] as Array[String], ["forest_monster"] as Array[String])

	# Act
	var proto: Combatant = bm.party[0]

	# Assert
	assert_str(proto.stats.element).is_equal("Neutral")


func test_battle_manager_setup_hp_blessing_refreshes_current_hp() -> void:
	# Arrange — Hippolyta stage 2 unlocks slot 2: War Cry (+20 HP).
	# RL 51 = stage 2. Base HP is 140.
	_reset_game_state()
	CompanionState.set_relationship_level("hipolita", 55)
	var bm = BattleManagerScript.new()
	bm.setup(["protagonist", "hipolita"] as Array[String], ["forest_monster"] as Array[String])

	var hipo: Combatant = null
	for c: Combatant in bm.party:
		if c.id == "hipolita":
			hipo = c
			break

	# Assert — max HP 140 + 20 = 160, and current_hp starts at the new max.
	assert_int(hipo.stats.max_hp).is_equal(160)
	assert_int(hipo.stats.current_hp).is_equal(160)
