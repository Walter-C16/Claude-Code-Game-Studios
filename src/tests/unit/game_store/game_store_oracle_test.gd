class_name GameStoreOracleTest
extends GdUnitTestSuite

## Integration tests for the Oracle gacha data layer on GameStore.
##
## Covers the Phase I.a API added for the companion gacha runtime:
##   get/set/add_companion_shards
##   get/set_companion_epithet
##   get_oracle_pulls_this_week + add_oracle_pulls
##   get/set_week_start_unix
##   tick_oracle_weekly_reset (604800-second cycle)
##
## Save round-trip for all four new fields is also guarded here so
## Phase I.c UI work can't regress the persistence layer.

func _reset() -> void:
	GameStore._initialize_defaults()


# ── Shards ────────────────────────────────────────────────────────────────────

func test_game_store_get_companion_shards_defaults_to_zero() -> void:
	_reset()
	assert_int(GameStore.get_companion_shards("artemis")).is_equal(0)


func test_game_store_add_companion_shards_accumulates() -> void:
	_reset()
	GameStore.add_companion_shards("atenea", 3)
	GameStore.add_companion_shards("atenea", 2)
	assert_int(GameStore.get_companion_shards("atenea")).is_equal(5)


func test_game_store_add_companion_shards_rejects_non_positive() -> void:
	_reset()
	GameStore.add_companion_shards("nyx", 5)
	GameStore.add_companion_shards("nyx", -3)
	GameStore.add_companion_shards("nyx", 0)
	assert_int(GameStore.get_companion_shards("nyx")).is_equal(5)


func test_game_store_set_companion_shards_clamps_to_zero() -> void:
	_reset()
	GameStore.set_companion_shards("hipolita", -10)
	assert_int(GameStore.get_companion_shards("hipolita")).is_equal(0)


# ── Epithets ──────────────────────────────────────────────────────────────────

func test_game_store_get_companion_epithet_defaults_to_zero() -> void:
	_reset()
	assert_int(GameStore.get_companion_epithet("artemis")).is_equal(0)


func test_game_store_set_companion_epithet_clamps_to_valid_range() -> void:
	_reset()
	GameStore.set_companion_epithet("artemis", 10)
	assert_int(GameStore.get_companion_epithet("artemis")).is_equal(6)
	GameStore.set_companion_epithet("artemis", -3)
	assert_int(GameStore.get_companion_epithet("artemis")).is_equal(0)


func test_game_store_meet_companion_bumps_epithet_from_zero_to_one() -> void:
	_reset()
	# Companion starts at tier 0
	assert_int(GameStore.get_companion_epithet("artemis")).is_equal(0)

	# meet_companion is defined on CompanionRegistry; invoking it should
	# flip the Epithet to 1 via the Phase I integration we just added.
	CompanionRegistry.meet_companion("artemis")

	# Assert
	assert_int(GameStore.get_companion_epithet("artemis")).is_equal(1)


func test_game_store_meet_companion_preserves_higher_epithet() -> void:
	# Arrange — player already gacha-unlocked Nyx to tier 3
	_reset()
	GameStore.set_companion_epithet("nyx", 3)

	# Act — story meets her afterwards (canonical Chapter 3 sequence)
	CompanionRegistry.meet_companion("nyx")

	# Assert — tier stays at 3 (not bumped back to 1)
	assert_int(GameStore.get_companion_epithet("nyx")).is_equal(3)


# ── Weekly pull counter ─────────────────────────────────────────────────────

func test_game_store_add_oracle_pulls_accumulates() -> void:
	_reset()
	GameStore.add_oracle_pulls(1)
	GameStore.add_oracle_pulls(10)
	assert_int(GameStore.get_oracle_pulls_this_week()).is_equal(11)


func test_game_store_add_oracle_pulls_rejects_non_positive() -> void:
	_reset()
	GameStore.add_oracle_pulls(5)
	GameStore.add_oracle_pulls(-3)
	GameStore.add_oracle_pulls(0)
	assert_int(GameStore.get_oracle_pulls_this_week()).is_equal(5)


# ── Weekly reset (AC-ORACLE-06) ──────────────────────────────────────────────

func test_game_store_tick_oracle_weekly_reset_first_call_seeds_anchor() -> void:
	# Arrange — fresh store, week_start_unix == 0
	_reset()
	assert_int(GameStore.get_week_start_unix()).is_equal(0)

	# Act — first tick seeds the anchor without resetting the counter
	GameStore.add_oracle_pulls(5)
	var did_reset: bool = GameStore.tick_oracle_weekly_reset()

	# Assert — anchor set, counter preserved
	assert_bool(did_reset).is_false()
	assert_int(GameStore.get_week_start_unix()).is_greater(0)
	assert_int(GameStore.get_oracle_pulls_this_week()).is_equal(5)


func test_game_store_tick_oracle_weekly_reset_clears_counter_after_week() -> void:
	# Arrange — seed anchor 8 days in the past
	_reset()
	var now: int = int(Time.get_unix_time_from_system())
	var eight_days_ago: int = now - (8 * 86400)
	GameStore.set_week_start_unix(eight_days_ago)
	GameStore.add_oracle_pulls(25)

	# Act
	var did_reset: bool = GameStore.tick_oracle_weekly_reset()

	# Assert — counter cleared, anchor advanced to ~now
	assert_bool(did_reset).is_true()
	assert_int(GameStore.get_oracle_pulls_this_week()).is_equal(0)
	assert_int(GameStore.get_week_start_unix()).is_greater(eight_days_ago)


func test_game_store_tick_oracle_weekly_reset_noop_within_week() -> void:
	# Arrange — anchor 3 days in the past
	_reset()
	var now: int = int(Time.get_unix_time_from_system())
	var three_days_ago: int = now - (3 * 86400)
	GameStore.set_week_start_unix(three_days_ago)
	GameStore.add_oracle_pulls(10)

	# Act
	var did_reset: bool = GameStore.tick_oracle_weekly_reset()

	# Assert — counter preserved, anchor unchanged
	assert_bool(did_reset).is_false()
	assert_int(GameStore.get_oracle_pulls_this_week()).is_equal(10)
	assert_int(GameStore.get_week_start_unix()).is_equal(three_days_ago)


# ── Save round-trip (AC-ORACLE-07) ───────────────────────────────────────────

func test_game_store_oracle_fields_round_trip_through_save() -> void:
	# Arrange
	_reset()
	GameStore.add_companion_shards("artemis", 17)
	GameStore.add_companion_shards("nyx", 4)
	GameStore.set_companion_epithet("artemis", 3)
	GameStore.set_companion_epithet("atenea", 1)
	GameStore.add_oracle_pulls(12)
	GameStore.set_week_start_unix(1234567890)

	# Act — serialize, wipe, restore
	var snapshot: Dictionary = GameStore.to_dict()
	GameStore._initialize_defaults()
	GameStore.from_dict(snapshot)

	# Assert
	assert_int(GameStore.get_companion_shards("artemis")).is_equal(17)
	assert_int(GameStore.get_companion_shards("nyx")).is_equal(4)
	assert_int(GameStore.get_companion_epithet("artemis")).is_equal(3)
	assert_int(GameStore.get_companion_epithet("atenea")).is_equal(1)
	assert_int(GameStore.get_oracle_pulls_this_week()).is_equal(12)
	assert_int(GameStore.get_week_start_unix()).is_equal(1234567890)
