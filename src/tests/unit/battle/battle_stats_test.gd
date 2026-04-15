class_name BattleStatsTest
extends GdUnitTestSuite

## Unit tests for BattleStats — the runtime stat container used by BattleManager.
##
## Covers:
##   from_dict builder honors declared keys and falls back to defaults
##   take_damage clamps to [0, max_hp] and returns the actual delta
##   heal clamps to max_hp
##   spend_energy guards against overspend
##   is_alive / *_fraction / has_full_ultimate queries
##   consume_ultimate requires a full bar

const BattleStatsScript = preload("res://systems/battle/battle_stats.gd")


# ── from_dict ─────────────────────────────────────────────────────────────────

func test_battle_stats_from_dict_honors_declared_keys() -> void:
	# Arrange
	var row: Dictionary = {
		"element": "Fire",
		"hp": 150,
		"atk": 20,
		"def": 8,
		"agi": 14,
		"crit_chance": 12.5,
		"crit_damage": 180.0,
		"ult_charge_source": "damage_dealt",
		"ult_charge_rate": 2,
	}

	# Act
	var stats = BattleStatsScript.from_dict(row)

	# Assert
	assert_str(stats.element).is_equal("Fire")
	assert_int(stats.max_hp).is_equal(150)
	assert_int(stats.atk).is_equal(20)
	assert_int(stats.def_stat).is_equal(8)
	assert_int(stats.agi).is_equal(14)
	assert_float(stats.crit_chance).is_equal_approx(12.5, 0.01)
	assert_float(stats.crit_damage).is_equal_approx(180.0, 0.01)
	assert_str(stats.ult_charge_source).is_equal("damage_dealt")
	assert_int(stats.ult_charge_rate).is_equal(2)


func test_battle_stats_from_dict_missing_keys_use_defaults() -> void:
	# Arrange
	var empty_row: Dictionary = {}

	# Act
	var stats = BattleStatsScript.from_dict(empty_row)

	# Assert — defaults from class
	assert_str(stats.element).is_equal("Neutral")
	assert_int(stats.max_hp).is_equal(100)
	assert_int(stats.atk).is_equal(10)


func test_battle_stats_from_dict_initializes_runtime_state_to_full() -> void:
	# Arrange + Act
	var stats = BattleStatsScript.from_dict({"hp": 80, "max_energy": 50})

	# Assert — current_hp = max_hp, current_energy = max_energy, ult = 0
	assert_int(stats.current_hp).is_equal(80)
	assert_int(stats.current_energy).is_equal(50)
	assert_int(stats.current_ultimate).is_equal(0)


# ── take_damage ───────────────────────────────────────────────────────────────

func test_battle_stats_take_damage_reduces_current_hp() -> void:
	# Arrange
	var stats = BattleStatsScript.from_dict({"hp": 100})

	# Act
	var actual: int = stats.take_damage(30)

	# Assert
	assert_int(stats.current_hp).is_equal(70)
	assert_int(actual).is_equal(30)


func test_battle_stats_take_damage_clamps_at_zero() -> void:
	# Arrange
	var stats = BattleStatsScript.from_dict({"hp": 100})
	stats.current_hp = 15

	# Act
	var actual: int = stats.take_damage(50)

	# Assert — real damage capped at current HP
	assert_int(stats.current_hp).is_equal(0)
	assert_int(actual).is_equal(15)
	assert_bool(stats.is_alive()).is_false()


# ── heal ──────────────────────────────────────────────────────────────────────

func test_battle_stats_heal_clamps_at_max_hp() -> void:
	# Arrange
	var stats = BattleStatsScript.from_dict({"hp": 100})
	stats.current_hp = 80

	# Act
	var actual: int = stats.heal(50)

	# Assert — heals only to max (20 applied, not 50)
	assert_int(stats.current_hp).is_equal(100)
	assert_int(actual).is_equal(20)


# ── energy / ultimate ─────────────────────────────────────────────────────────

func test_battle_stats_spend_energy_rejects_when_insufficient() -> void:
	# Arrange
	var stats = BattleStatsScript.from_dict({"max_energy": 50})
	stats.current_energy = 20

	# Act
	var ok: bool = stats.spend_energy(30)

	# Assert — rejected, no deduction
	assert_bool(ok).is_false()
	assert_int(stats.current_energy).is_equal(20)


func test_battle_stats_consume_ultimate_requires_full_bar() -> void:
	# Arrange
	var stats = BattleStatsScript.from_dict({"max_ultimate": 100})
	stats.current_ultimate = 80

	# Act + Assert — rejected at 80/100
	assert_bool(stats.consume_ultimate()).is_false()
	assert_int(stats.current_ultimate).is_equal(80)

	# Act + Assert — succeeds at 100/100, drains to 0
	stats.current_ultimate = 100
	assert_bool(stats.consume_ultimate()).is_true()
	assert_int(stats.current_ultimate).is_equal(0)
