class_name CompanionLevelTest
extends GdUnitTestSuite

## Unit tests for CompanionLevel — XP / Level / stat-bonus pure logic.
##
## Covers the entire acceptance criteria list from
## `design/quick-specs/companion-leveling.md` sections AC-LVL-01 through
## AC-LVL-07.

const CompanionLevelScript = preload("res://systems/companion_level.gd")
const BattleStatsScript = preload("res://systems/battle/battle_stats.gd")


# ── XP → Level ────────────────────────────────────────────────────────────────

func test_companion_level_xp_zero_returns_level_one() -> void:
	# Act
	var level: int = CompanionLevelScript.xp_to_level(0)

	# Assert
	assert_int(level).is_equal(1)


func test_companion_level_xp_negative_returns_level_one() -> void:
	# Act
	var level: int = CompanionLevelScript.xp_to_level(-100)

	# Assert
	assert_int(level).is_equal(1)


func test_companion_level_xp_exact_threshold_advances_level() -> void:
	# Arrange — 50 XP is the exact threshold for level 2
	# Act
	var level: int = CompanionLevelScript.xp_to_level(50)

	# Assert
	assert_int(level).is_equal(2)


func test_companion_level_xp_one_below_threshold_stays_at_previous() -> void:
	# Arrange — 49 XP is 1 below the level 2 threshold
	# Act
	var level: int = CompanionLevelScript.xp_to_level(49)

	# Assert
	assert_int(level).is_equal(1)


func test_companion_level_xp_far_past_cap_clamps_at_max() -> void:
	# Act — 10 million XP is well past any reasonable cap
	var level: int = CompanionLevelScript.xp_to_level(10000000)

	# Assert — clamped at LEVEL_CAP (110, SS rank max)
	assert_int(level).is_equal(CompanionLevelScript.LEVEL_CAP)


func test_companion_level_every_level_threshold_is_monotonic() -> void:
	# A sweep — the total XP for each level must be strictly greater than
	# the previous level, so xp_to_level never skips or stalls.
	var prev_total: int = -1
	for level: int in range(1, 21):
		var total: int = CompanionLevelScript.xp_total_for_level(level)
		assert_int(total).is_greater(prev_total)
		prev_total = total


func test_companion_level_xp_total_matches_design_spec() -> void:
	# Spot-check the published table from companion-leveling.md.
	assert_int(CompanionLevelScript.xp_total_for_level(1)).is_equal(0)
	assert_int(CompanionLevelScript.xp_total_for_level(2)).is_equal(50)
	assert_int(CompanionLevelScript.xp_total_for_level(5)).is_equal(500)
	assert_int(CompanionLevelScript.xp_total_for_level(10)).is_equal(2250)
	assert_int(CompanionLevelScript.xp_total_for_level(15)).is_equal(5250)
	assert_int(CompanionLevelScript.xp_total_for_level(20)).is_equal(9500)


# ── XP needed / into ─────────────────────────────────────────────────────────

func test_companion_level_xp_needed_for_next_drops_at_cap() -> void:
	# Act + Assert
	assert_int(CompanionLevelScript.xp_needed_for_next(CompanionLevelScript.LEVEL_CAP)).is_equal(0)


func test_companion_level_xp_needed_for_next_matches_expected_delta() -> void:
	# Lvl 1 → 2 = 50 XP (the first step)
	assert_int(CompanionLevelScript.xp_needed_for_next(1)).is_equal(50)
	# Lvl 5 → 6 = 250 XP
	assert_int(CompanionLevelScript.xp_needed_for_next(5)).is_equal(250)
	# Lvl 19 → 20 = 950 XP
	assert_int(CompanionLevelScript.xp_needed_for_next(19)).is_equal(950)


func test_companion_level_xp_into_current_level_at_partial_progress() -> void:
	# Player has 120 XP → level 2 (threshold 50) with 70 XP into level 2.
	var xp_into: int = CompanionLevelScript.xp_into_current_level(120)
	assert_int(xp_into).is_equal(70)


func test_companion_level_xp_into_current_level_returns_zero_at_cap() -> void:
	# Player well past the cap threshold — UI shows "MAX".
	var cap_xp: int = CompanionLevelScript.xp_total_for_level(CompanionLevelScript.LEVEL_CAP)
	var xp_into: int = CompanionLevelScript.xp_into_current_level(cap_xp + 100000)
	assert_int(xp_into).is_equal(0)


# ── Stat bonuses ─────────────────────────────────────────────────────────────

func test_companion_level_bonuses_are_zero_at_level_one() -> void:
	# Arrange + Act + Assert
	assert_int(CompanionLevelScript.hp_bonus_for_level(1)).is_equal(0)
	assert_int(CompanionLevelScript.atk_bonus_for_level(1)).is_equal(0)
	assert_int(CompanionLevelScript.def_bonus_for_level(1)).is_equal(0)
	assert_int(CompanionLevelScript.agi_bonus_for_level(1)).is_equal(0)
	assert_float(CompanionLevelScript.crit_chance_bonus_for_level(1)).is_equal_approx(0.0, 0.01)
	assert_float(CompanionLevelScript.crit_damage_bonus_for_level(1)).is_equal_approx(0.0, 0.01)


func test_companion_level_hp_bonus_at_cap_matches_spec() -> void:
	# Arrange — 19 levels above the base, 6 HP per level = +114
	# Act + Assert
	assert_int(CompanionLevelScript.hp_bonus_for_level(20)).is_equal(114)


func test_companion_level_atk_bonus_at_cap_matches_spec() -> void:
	# 19 levels * 1 ATK = +19
	assert_int(CompanionLevelScript.atk_bonus_for_level(20)).is_equal(19)


func test_companion_level_def_bonus_milestones() -> void:
	# DEF grows every 2 levels. Lvl 3 = +1, Lvl 5 = +2, Lvl 20 = +9.
	assert_int(CompanionLevelScript.def_bonus_for_level(2)).is_equal(0)
	assert_int(CompanionLevelScript.def_bonus_for_level(3)).is_equal(1)
	assert_int(CompanionLevelScript.def_bonus_for_level(5)).is_equal(2)
	assert_int(CompanionLevelScript.def_bonus_for_level(20)).is_equal(9)


func test_companion_level_agi_bonus_milestones() -> void:
	# AGI grows every 5 levels. Lvl 5 = 0 (4 / 5 = 0), Lvl 6 = +1, Lvl 20 = +3.
	assert_int(CompanionLevelScript.agi_bonus_for_level(5)).is_equal(0)
	assert_int(CompanionLevelScript.agi_bonus_for_level(6)).is_equal(1)
	assert_int(CompanionLevelScript.agi_bonus_for_level(20)).is_equal(3)


func test_companion_level_crit_chance_bonus_milestones() -> void:
	# +1% every 5 levels. Lvl 6 = +1, Lvl 11 = +2, Lvl 20 = +3.
	assert_float(CompanionLevelScript.crit_chance_bonus_for_level(6)).is_equal_approx(1.0, 0.01)
	assert_float(CompanionLevelScript.crit_chance_bonus_for_level(11)).is_equal_approx(2.0, 0.01)
	assert_float(CompanionLevelScript.crit_chance_bonus_for_level(20)).is_equal_approx(3.0, 0.01)


func test_companion_level_crit_damage_bonus_milestones() -> void:
	# +5% every 10 levels. Lvl 11 = +5, Lvl 20 = +5 still (only one milestone reached).
	assert_float(CompanionLevelScript.crit_damage_bonus_for_level(10)).is_equal_approx(0.0, 0.01)
	assert_float(CompanionLevelScript.crit_damage_bonus_for_level(11)).is_equal_approx(5.0, 0.01)
	assert_float(CompanionLevelScript.crit_damage_bonus_for_level(20)).is_equal_approx(5.0, 0.01)


# ── apply_to_stats ───────────────────────────────────────────────────────────

func test_companion_level_apply_to_stats_leaves_level_one_unchanged() -> void:
	# Arrange
	var stats: BattleStats = BattleStatsScript.from_dict({"hp": 100, "atk": 20, "def": 10, "agi": 15})
	var hp_before: int = stats.max_hp
	var atk_before: int = stats.atk

	# Act
	CompanionLevelScript.apply_to_stats(stats, 1)

	# Assert — no bonuses at level 1
	assert_int(stats.max_hp).is_equal(hp_before)
	assert_int(stats.atk).is_equal(atk_before)


func test_companion_level_apply_to_stats_at_cap_bumps_all_fields() -> void:
	# Arrange
	var stats: BattleStats = BattleStatsScript.from_dict({
		"hp": 95,
		"atk": 22,
		"def": 8,
		"agi": 20,
		"crit_chance": 10.0,
		"crit_damage": 170.0,
	})

	# Act
	CompanionLevelScript.apply_to_stats(stats, 20)

	# Assert — matches the published Artemis table in the design doc
	assert_int(stats.max_hp).is_equal(95 + 114)
	assert_int(stats.atk).is_equal(22 + 19)
	assert_int(stats.def_stat).is_equal(8 + 9)
	assert_int(stats.agi).is_equal(20 + 3)
	assert_float(stats.crit_chance).is_equal_approx(13.0, 0.01)
	assert_float(stats.crit_damage).is_equal_approx(175.0, 0.01)


func test_companion_level_apply_to_stats_snaps_current_hp_to_new_max() -> void:
	# Arrange
	var stats: BattleStats = BattleStatsScript.from_dict({"hp": 100})
	# Simulate a pre-battle wound — level-up should restore to full.
	stats.current_hp = 20

	# Act
	CompanionLevelScript.apply_to_stats(stats, 10)

	# Assert — new max = 100 + 54, current_hp snapped to it
	assert_int(stats.max_hp).is_equal(154)
	assert_int(stats.current_hp).is_equal(154)
