class_name GameStoreLevelUpTest
extends GdUnitTestSuite

## Integration tests for the manual companion level-up flow on GameStore.
##
## Covers the API added in Phase H:
##   get_companion_level        — stored, not derived
##   get_level_up_xp_cost       — CompanionLevel.xp_needed_for_next
##   get_level_up_gold_cost     — 25 × current_level
##   can_level_up               — checks XP + gold + cap
##   level_up_companion         — atomic: spends both resources, bumps level
##
## Uses the real autoload GameStore. Each test calls _initialize_defaults
## first so the ordering is isolated.


# ── Helpers ──────────────────────────────────────────────────────────────────

func _reset() -> void:
	GameStore._initialize_defaults()


# ── can_level_up preconditions ───────────────────────────────────────────────

func test_game_store_can_level_up_false_with_zero_xp_and_gold() -> void:
	# Arrange
	_reset()

	# Act + Assert — fresh companion, no XP, no gold, cannot level
	assert_bool(GameStore.can_level_up("artemis")).is_false()


func test_game_store_can_level_up_false_with_enough_xp_but_no_gold() -> void:
	# Arrange
	_reset()
	GameStore.add_companion_xp("artemis", 100)  # way more than the 50 needed for 1→2
	# Gold stays at 0

	# Act + Assert
	assert_bool(GameStore.can_level_up("artemis")).is_false()


func test_game_store_can_level_up_false_with_enough_gold_but_no_xp() -> void:
	# Arrange
	_reset()
	GameStore.add_gold(500)

	# Act + Assert
	assert_bool(GameStore.can_level_up("artemis")).is_false()


func test_game_store_can_level_up_true_when_both_resources_available() -> void:
	# Arrange
	_reset()
	GameStore.add_companion_xp("artemis", 50)  # exact XP threshold for lvl 1→2
	GameStore.add_gold(25)                     # exact gold threshold for lvl 1→2

	# Act + Assert
	assert_bool(GameStore.can_level_up("artemis")).is_true()


# ── level_up_companion execution ─────────────────────────────────────────────

func test_game_store_level_up_companion_consumes_xp_and_gold() -> void:
	# Arrange
	_reset()
	GameStore.add_companion_xp("artemis", 80)
	GameStore.add_gold(100)

	# Act
	var ok: bool = GameStore.level_up_companion("artemis")

	# Assert
	assert_bool(ok).is_true()
	assert_int(GameStore.get_companion_level("artemis")).is_equal(2)
	assert_int(GameStore.get_companion_xp("artemis")).is_equal(30)  # 80 - 50
	assert_int(GameStore.get_gold()).is_equal(75)                   # 100 - 25


func test_game_store_level_up_companion_fails_when_insufficient() -> void:
	# Arrange
	_reset()
	GameStore.add_companion_xp("artemis", 49)  # 1 below the 50 needed
	GameStore.add_gold(100)

	# Act
	var ok: bool = GameStore.level_up_companion("artemis")

	# Assert — rejected, no state mutation
	assert_bool(ok).is_false()
	assert_int(GameStore.get_companion_level("artemis")).is_equal(1)
	assert_int(GameStore.get_companion_xp("artemis")).is_equal(49)
	assert_int(GameStore.get_gold()).is_equal(100)


func test_game_store_level_up_companion_rejects_at_level_cap() -> void:
	# Arrange
	_reset()
	GameStore._companion_levels["artemis"] = 20  # direct poke — already at cap
	GameStore.add_companion_xp("artemis", 100000)
	GameStore.add_gold(100000)

	# Act
	var ok: bool = GameStore.level_up_companion("artemis")

	# Assert
	assert_bool(ok).is_false()
	assert_int(GameStore.get_companion_level("artemis")).is_equal(20)
	assert_int(GameStore.get_level_up_xp_cost("artemis")).is_equal(0)
	assert_int(GameStore.get_level_up_gold_cost("artemis")).is_equal(0)


# ── Cost scaling ─────────────────────────────────────────────────────────────

func test_game_store_level_up_gold_cost_scales_linearly_with_level() -> void:
	# Arrange
	_reset()

	# Act + Assert — 25 × current_level at a few sample levels
	GameStore._companion_levels["artemis"] = 1
	assert_int(GameStore.get_level_up_gold_cost("artemis")).is_equal(25)
	GameStore._companion_levels["artemis"] = 5
	assert_int(GameStore.get_level_up_gold_cost("artemis")).is_equal(125)
	GameStore._companion_levels["artemis"] = 10
	assert_int(GameStore.get_level_up_gold_cost("artemis")).is_equal(250)
	GameStore._companion_levels["artemis"] = 19
	assert_int(GameStore.get_level_up_gold_cost("artemis")).is_equal(475)


func test_game_store_level_up_xp_cost_matches_companion_level_formula() -> void:
	# Arrange
	_reset()

	# Act + Assert — XP cost mirrors CompanionLevel.xp_needed_for_next
	GameStore._companion_levels["artemis"] = 1
	assert_int(GameStore.get_level_up_xp_cost("artemis")) \
		.is_equal(CompanionLevel.xp_needed_for_next(1))
	GameStore._companion_levels["artemis"] = 10
	assert_int(GameStore.get_level_up_xp_cost("artemis")) \
		.is_equal(CompanionLevel.xp_needed_for_next(10))


# ── Save round-trip ──────────────────────────────────────────────────────────

func test_game_store_level_and_xp_round_trip_through_to_dict_from_dict() -> void:
	# Arrange — set up some state
	_reset()
	GameStore.add_companion_xp("artemis", 275)
	GameStore.add_gold(500)
	GameStore.add_companion_xp("hipolita", 100)
	GameStore._companion_levels["hipolita"] = 3

	# Act — serialize then wipe then restore
	var snapshot: Dictionary = GameStore.to_dict()
	GameStore._initialize_defaults()
	GameStore.from_dict(snapshot)

	# Assert — values survive the trip
	assert_int(GameStore.get_companion_xp("artemis")).is_equal(275)
	assert_int(GameStore.get_companion_level("artemis")).is_equal(1)  # default
	assert_int(GameStore.get_companion_xp("hipolita")).is_equal(100)
	assert_int(GameStore.get_companion_level("hipolita")).is_equal(3)
