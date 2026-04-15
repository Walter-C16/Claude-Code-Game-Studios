class_name BattleManagerEffectsTest
extends GdUnitTestSuite

## Unit tests for BattleManager._apply_effect dispatch and _tick_effects_for.
##
## Covers each non-damaging / status move effect:
##   pierce_def              — halved DEF subtraction on the hit
##   dodge_next_attack       — consumes target's next incoming hit
##   guaranteed_crit_3_turns — forces crit on subsequent outgoing hits
##   apply_hunter_mark_2_turns — amplifies next hits against target
##   party_shield_30_percent — reduces incoming damage on allies
##   ignore_defense          — skips DEF subtraction for this hit
##   dispel_enemy_buffs      — clears buff-family keys, preserves DoTs
## Plus _tick_effects_for — turns_left decrement + DoT damage.

const BattleManagerScript = preload("res://systems/battle/battle_manager.gd")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _reset_game_state() -> void:
	GameStore._initialize_defaults()
	CompanionState._max_stages.clear()


func _make_solo_battle():
	_reset_game_state()
	var bm = BattleManagerScript.new()
	var party: Array[String] = ["protagonist"]
	var enemies: Array[String] = ["forest_monster"]
	bm.setup(party, enemies)
	return bm


## Installs a test move on the protagonist's "special" slot so tests can drive
## _apply_effect dispatch without pulling an exact move from battle_movesets.json.
func _install_effect_move(bm, effect: String, damage_mult: float, target_tag: String) -> void:
	var actor: Combatant = bm.party[0]
	var move: BattleMove = BattleMove.new()
	move.id = "test_" + effect
	move.name_key = "TEST"
	move.move_type = "special"
	move.target = target_tag
	move.damage_mult = damage_mult
	move.hits = 1
	move.element = "Neutral"
	move.element_source = ""
	move.energy_cost = 0
	move.effect = effect
	actor.moves["special"] = move


# ── Effect dispatch ──────────────────────────────────────────────────────────

func test_battle_manager_pierce_def_halves_def_subtraction() -> void:
	# Arrange — seed enemy DEF high enough that the halving matters.
	var bm = _make_solo_battle()
	bm.enemies[0].stats.def_stat = 20
	var enemy = bm.enemies[0]
	_install_effect_move(bm, "pierce_def", 1.0, "single_enemy")
	var proto = bm.party[0]
	proto.stats.crit_chance = 0.0

	# Act
	var hp_before: int = enemy.stats.current_hp
	bm.execute_move("special", [enemy] as Array[Combatant])
	var pierce_dmg: int = hp_before - enemy.stats.current_hp

	# Control — same raw power, no pierce_def
	var bm_c = _make_solo_battle()
	bm_c.enemies[0].stats.def_stat = 20
	var enemy_c = bm_c.enemies[0]
	_install_effect_move(bm_c, "", 1.0, "single_enemy")
	bm_c.party[0].stats.crit_chance = 0.0
	var hp_c_before: int = enemy_c.stats.current_hp
	bm_c.execute_move("special", [enemy_c] as Array[Combatant])
	var normal_dmg: int = hp_c_before - enemy_c.stats.current_hp

	# Assert — pierce_def deals more damage than the control
	assert_int(pierce_dmg).is_greater(normal_dmg)


func test_battle_manager_dodge_next_attack_consumes_incoming_hit() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	_install_effect_move(bm, "dodge_next_attack", 0.0, "single_enemy")
	bm.execute_move("special", [proto] as Array[Combatant])

	assert_bool(proto.stats.active_effects.has("dodge_next")).is_true()

	# Act — resolve an enemy hit directly
	var enemy = bm.enemies[0]
	var enemy_move: BattleMove = enemy.get_move("normal")
	var hp_before: int = proto.stats.current_hp
	var hit: Dictionary = bm._resolve_hit(enemy, proto, enemy_move)

	# Assert — dodged, no damage, buff consumed
	assert_bool(hit.get("dodged", false)).is_true()
	assert_int(proto.stats.current_hp).is_equal(hp_before)
	assert_bool(proto.stats.active_effects.has("dodge_next")).is_false()


func test_battle_manager_guaranteed_crit_forces_crit_on_next_hit() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	_install_effect_move(bm, "guaranteed_crit_3_turns", 0.0, "single_enemy")
	bm.execute_move("special", [proto] as Array[Combatant])

	assert_bool(proto.stats.active_effects.has("forced_crit")).is_true()

	# Act — zero base crit, but forced_crit should still fire
	proto.stats.crit_chance = 0.0
	var normal_move: BattleMove = proto.get_move("normal")
	var hit: Dictionary = bm._resolve_hit(proto, bm.enemies[0], normal_move)

	# Assert
	assert_bool(hit.get("crit", false)).is_true()


func test_battle_manager_hunter_mark_amplifies_next_hit() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	_install_effect_move(bm, "apply_hunter_mark_2_turns", 0.0, "single_enemy")
	bm.execute_move("special", [bm.enemies[0]] as Array[Combatant])

	var enemy = bm.enemies[0]
	assert_bool(enemy.stats.active_effects.has("hunter_mark")).is_true()

	# Act — marked hit (no crit) vs unmarked hit (no crit)
	proto.stats.crit_chance = 0.0
	var normal_move: BattleMove = proto.get_move("normal")
	var hp_before: int = enemy.stats.current_hp
	bm._resolve_hit(proto, enemy, normal_move)
	var mark_dmg: int = hp_before - enemy.stats.current_hp

	var bm_c = _make_solo_battle()
	var enemy_c = bm_c.enemies[0]
	bm_c.party[0].stats.crit_chance = 0.0
	var hp_c_before: int = enemy_c.stats.current_hp
	bm_c._resolve_hit(bm_c.party[0], enemy_c, bm_c.party[0].get_move("normal"))
	var control_dmg: int = hp_c_before - enemy_c.stats.current_hp

	# Assert
	assert_int(mark_dmg).is_greater(control_dmg)


func test_battle_manager_party_shield_reduces_incoming_damage() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	_install_effect_move(bm, "party_shield_30_percent", 0.0, "single_enemy")
	bm.execute_move("special", [proto] as Array[Combatant])

	assert_bool(proto.stats.active_effects.has("shield")).is_true()

	# Act
	var enemy = bm.enemies[0]
	var enemy_move: BattleMove = enemy.get_move("normal")
	proto.stats.crit_chance = 0.0
	enemy.stats.crit_chance = 0.0
	var hp_before: int = proto.stats.current_hp
	bm._resolve_hit(enemy, proto, enemy_move)
	var shielded_dmg: int = hp_before - proto.stats.current_hp

	# Control
	var bm_c = _make_solo_battle()
	var proto_c = bm_c.party[0]
	var enemy_c = bm_c.enemies[0]
	proto_c.stats.crit_chance = 0.0
	enemy_c.stats.crit_chance = 0.0
	var hp_c_before: int = proto_c.stats.current_hp
	bm_c._resolve_hit(enemy_c, proto_c, enemy_c.get_move("normal"))
	var control_dmg: int = hp_c_before - proto_c.stats.current_hp

	# Assert
	assert_int(shielded_dmg).is_less(control_dmg)


func test_battle_manager_ignore_defense_bypasses_def_subtraction() -> void:
	# Arrange — high DEF so ignore_defense matters
	var bm = _make_solo_battle()
	bm.enemies[0].stats.def_stat = 20
	var enemy = bm.enemies[0]
	_install_effect_move(bm, "ignore_defense", 1.0, "single_enemy")
	bm.party[0].stats.crit_chance = 0.0
	var hp_before: int = enemy.stats.current_hp
	bm.execute_move("special", [enemy] as Array[Combatant])
	var ignored_dmg: int = hp_before - enemy.stats.current_hp

	# Control
	var bm_c = _make_solo_battle()
	bm_c.enemies[0].stats.def_stat = 20
	var enemy_c = bm_c.enemies[0]
	_install_effect_move(bm_c, "", 1.0, "single_enemy")
	bm_c.party[0].stats.crit_chance = 0.0
	var hp_c_before: int = enemy_c.stats.current_hp
	bm_c.execute_move("special", [enemy_c] as Array[Combatant])
	var normal_dmg: int = hp_c_before - enemy_c.stats.current_hp

	# Assert
	assert_int(ignored_dmg).is_greater(normal_dmg)


func test_battle_manager_dispel_clears_buffs_preserves_dots() -> void:
	# Arrange — seed an enemy with both buffs and a DoT
	var bm = _make_solo_battle()
	var enemy = bm.enemies[0]
	enemy.stats.active_effects["shield"] = {"magnitude": 0.30, "turns_left": 2}
	enemy.stats.active_effects["forced_crit"] = {"turns_left": 3}
	enemy.stats.active_effects["dot_burn"] = {"magnitude": 5.0, "turns_left": 2}

	_install_effect_move(bm, "dispel_enemy_buffs", 0.0, "single_enemy")
	bm.execute_move("special", [enemy] as Array[Combatant])

	# Assert — buffs cleared, DoT preserved
	assert_bool(enemy.stats.active_effects.has("shield")).is_false()
	assert_bool(enemy.stats.active_effects.has("forced_crit")).is_false()
	assert_bool(enemy.stats.active_effects.has("dot_burn")).is_true()


# ── Tick effects ─────────────────────────────────────────────────────────────

func test_battle_manager_tick_effects_decrements_turns_left() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	proto.stats.active_effects["shield"] = {"magnitude": 0.30, "turns_left": 2}

	# Act — tick once
	bm._tick_effects_for(proto)

	# Assert — still present, counter down to 1
	assert_bool(proto.stats.active_effects.has("shield")).is_true()
	assert_int(int((proto.stats.active_effects["shield"] as Dictionary).get("turns_left", 0))).is_equal(1)

	# Act — tick again
	bm._tick_effects_for(proto)

	# Assert — expired and removed
	assert_bool(proto.stats.active_effects.has("shield")).is_false()


func test_battle_manager_tick_effects_applies_dot_damage() -> void:
	# Arrange
	var bm = _make_solo_battle()
	var proto = bm.party[0]
	proto.stats.active_effects["dot_burn"] = {"magnitude": 10.0, "turns_left": 2}
	var hp_before: int = proto.stats.current_hp

	# Act
	bm._tick_effects_for(proto)

	# Assert — damage applied, counter decremented to 1
	assert_int(proto.stats.current_hp).is_equal(hp_before - 10)
	assert_int(int((proto.stats.active_effects["dot_burn"] as Dictionary).get("turns_left", 0))).is_equal(1)
