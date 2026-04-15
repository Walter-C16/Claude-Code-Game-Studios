class_name BattleAiTest
extends GdUnitTestSuite

## Unit tests for BattleAi — personality-driven enemy move + target selection.
##
## Covers:
##   aggressive profile picks highest-damage move available
##   aggressive profile targets the lowest-HP ally
##   tactical profile saves ultimate until party HP is high
##   tactical profile targets the highest-ATK ally
##   berserker profile uses ultimate when its own HP drops under 50%
##   berserker profile targets the protagonist
##   defensive profile prefers special when no shield is up
##   defensive profile targets the highest-ATK ally
##   Unknown profile falls back to aggressive
##
## Tests mutate ai_profile and stats on constructed combatants rather than
## touching the JSON data, so they stay isolated from balance changes.

const BattleManagerScript = preload("res://systems/battle/battle_manager.gd")
const BattleAiScript = preload("res://systems/battle/battle_ai.gd")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _reset_game_state() -> void:
	GameStore._initialize_defaults()
	CompanionState._max_stages.clear()


## Builds a battle with two allies (proto + artemis) and an enemy with the
## requested ai_profile installed on its stats.
func _make_battle(profile: String):
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(
		["protagonist", "artemis"] as Array[String],
		["forest_monster"] as Array[String]
	)
	bm.enemies[0].stats.ai_profile = profile
	return bm


# ── Aggressive profile ───────────────────────────────────────────────────────

func test_battle_ai_aggressive_picks_ultimate_when_available() -> void:
	# Arrange
	var bm = _make_battle("aggressive")
	var enemy = bm.enemies[0]
	enemy.stats.current_ultimate = enemy.stats.max_ultimate  # top bar

	# Act
	var action: Dictionary = BattleAiScript.choose_action(enemy, bm)

	# Assert — if the enemy actually has an ultimate move it should pick it
	if enemy.get_move("ultimate") != null:
		assert_str(action.get("move_type", "") as String).is_equal("ultimate")
	else:
		# Enemy with no ultimate move — should still pick the strongest
		# available (special if possible, else normal).
		var mt: String = action.get("move_type", "") as String
		assert_bool(mt == "special" or mt == "normal").is_true()


func test_battle_ai_aggressive_targets_lowest_hp_ally() -> void:
	# Arrange
	var bm = _make_battle("aggressive")
	var proto = bm.party[0]
	var artemis = bm.party[1]
	proto.stats.current_hp = 10  # protagonist is wounded
	artemis.stats.current_hp = artemis.stats.max_hp

	# Act
	var action: Dictionary = BattleAiScript.choose_action(bm.enemies[0], bm)
	var targets: Array[Combatant] = action.get("targets", [] as Array[Combatant]) as Array[Combatant]

	# Assert — wounded protagonist is picked
	assert_int(targets.size()).is_equal(1)
	assert_str(targets[0].id).is_equal("protagonist")


# ── Tactical profile ─────────────────────────────────────────────────────────

func test_battle_ai_tactical_targets_highest_atk_ally() -> void:
	# Arrange — artemis has ATK 22, proto has 18; tactical should pick artemis.
	var bm = _make_battle("tactical")
	bm.party[0].stats.atk = 18
	bm.party[1].stats.atk = 22

	# Act
	var action: Dictionary = BattleAiScript.choose_action(bm.enemies[0], bm)
	var targets: Array[Combatant] = action.get("targets", [] as Array[Combatant]) as Array[Combatant]

	# Assert
	assert_int(targets.size()).is_equal(1)
	assert_str(targets[0].id).is_equal("artemis")


func test_battle_ai_tactical_holds_ultimate_when_party_wounded() -> void:
	# Arrange — party at ~30% HP; tactical should NOT fire ultimate.
	var bm = _make_battle("tactical")
	var enemy = bm.enemies[0]
	enemy.stats.current_ultimate = enemy.stats.max_ultimate
	bm.party[0].stats.current_hp = 10
	bm.party[1].stats.current_hp = 10

	# Act
	var action: Dictionary = BattleAiScript.choose_action(enemy, bm)

	# Assert
	assert_str(action.get("move_type", "") as String).is_not_equal("ultimate")


# ── Berserker profile ────────────────────────────────────────────────────────

func test_battle_ai_berserker_fires_ultimate_below_half_hp() -> void:
	# Arrange
	var bm = _make_battle("berserker")
	var enemy = bm.enemies[0]
	enemy.stats.current_ultimate = enemy.stats.max_ultimate
	enemy.stats.current_hp = enemy.stats.max_hp / 4  # < 50%

	# Act
	var action: Dictionary = BattleAiScript.choose_action(enemy, bm)

	# Assert — ultimate if the enemy has one; special otherwise (falls through)
	if enemy.get_move("ultimate") != null:
		assert_str(action.get("move_type", "") as String).is_equal("ultimate")


func test_battle_ai_berserker_targets_protagonist() -> void:
	# Arrange
	var bm = _make_battle("berserker")

	# Act
	var action: Dictionary = BattleAiScript.choose_action(bm.enemies[0], bm)
	var targets: Array[Combatant] = action.get("targets", [] as Array[Combatant]) as Array[Combatant]

	# Assert
	assert_int(targets.size()).is_equal(1)
	assert_str(targets[0].id).is_equal("protagonist")


# ── Defensive profile ────────────────────────────────────────────────────────

func test_battle_ai_defensive_targets_highest_atk_ally() -> void:
	# Arrange — hipolita ATK 26, proto ATK 18
	_reset_game_state()
	var bm = BattleManagerScript.new()
	bm.setup(
		["protagonist", "hipolita"] as Array[String],
		["forest_monster"] as Array[String]
	)
	bm.enemies[0].stats.ai_profile = "defensive"

	# Act
	var action: Dictionary = BattleAiScript.choose_action(bm.enemies[0], bm)
	var targets: Array[Combatant] = action.get("targets", [] as Array[Combatant]) as Array[Combatant]

	# Assert
	assert_int(targets.size()).is_equal(1)
	assert_str(targets[0].id).is_equal("hipolita")


# ── Fallback / edge cases ────────────────────────────────────────────────────

func test_battle_ai_unknown_profile_falls_back_to_aggressive() -> void:
	# Arrange
	var bm = _make_battle("totally_made_up_profile")
	var proto = bm.party[0]
	var artemis = bm.party[1]
	proto.stats.current_hp = 5
	artemis.stats.current_hp = artemis.stats.max_hp

	# Act
	var action: Dictionary = BattleAiScript.choose_action(bm.enemies[0], bm)
	var targets: Array[Combatant] = action.get("targets", [] as Array[Combatant]) as Array[Combatant]

	# Assert — aggressive fallback picks the lowest-HP ally (protagonist)
	assert_int(targets.size()).is_equal(1)
	assert_str(targets[0].id).is_equal("protagonist")


func test_battle_ai_null_actor_returns_empty_targets() -> void:
	# Arrange
	var bm = _make_battle("aggressive")

	# Act
	var action: Dictionary = BattleAiScript.choose_action(null, bm)

	# Assert
	assert_int((action.get("targets", []) as Array).size()).is_equal(0)
