class_name GameStoreSerializationTest
extends GdUnitTestSuite

const GameStoreScript = preload("res://autoloads/game_store.gd")

# Unit tests for STORY-GS-004: GameStore to_dict / from_dict Serialization
#
# Covers all Acceptance Criteria:
#   AC1 — to_dict() returns a Dictionary with all 11 required top-level keys
#   AC2 — from_dict() with missing "player_xp" key → get_xp() returns 0 (default)
#   AC3 — from_dict() with "nyx" absent from companion_states → "nyx" gets defaults
#   AC4 — Full round-trip: all getter values match the original after to_dict/from_dict
#   AC5 — from_dict() leaves _dirty = false and _save_pending = false
#
# Additional edge cases:
#   — Empty Dictionary input to from_dict() initializes all fields to defaults
#   — Extra unknown keys in the Dictionary are silently ignored
#   — Round-trip for companion state (all 9 fields, including array fields)
#   — Round-trip for story flags and node states
#   — Round-trip for combat buff with real data
#   — from_dict() clears _save_pending even when store had pre-existing pending state
#
# See: docs/architecture/adr-0001-gamestore-state.md

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates a fresh GameStore instance with factory defaults.
## Each test gets its own instance — no shared mutable state between tests.
func _make_store():
	var store = GameStoreScript.new()
	store._initialize_defaults()
	return store

# ---------------------------------------------------------------------------
# AC1 — to_dict() contains all 11 required top-level keys
# ---------------------------------------------------------------------------

func test_game_store_serialization_to_dict_contains_companion_states_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("companion_states")).is_true()

func test_game_store_serialization_to_dict_contains_story_flags_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("story_flags")).is_true()

func test_game_store_serialization_to_dict_contains_node_states_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("node_states")).is_true()

func test_game_store_serialization_to_dict_contains_current_chapter_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("current_chapter")).is_true()

func test_game_store_serialization_to_dict_contains_player_gold_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("player_gold")).is_true()

func test_game_store_serialization_to_dict_contains_player_xp_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("player_xp")).is_true()

func test_game_store_serialization_to_dict_contains_daily_tokens_remaining_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("daily_tokens_remaining")).is_true()

func test_game_store_serialization_to_dict_contains_current_streak_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("current_streak")).is_true()

func test_game_store_serialization_to_dict_contains_last_interaction_date_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("last_interaction_date")).is_true()

func test_game_store_serialization_to_dict_contains_active_combat_buff_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("active_combat_buff")).is_true()

func test_game_store_serialization_to_dict_contains_last_captain_id_key() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert
	assert_bool(data.has("last_captain_id")).is_true()

func test_game_store_serialization_to_dict_has_exactly_eleven_top_level_keys() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()

	# Assert — exactly the 11 documented keys; no accidental extras
	assert_int(data.size()).is_equal(11)

# ---------------------------------------------------------------------------
# AC2 — from_dict() with missing "player_xp" → get_xp() returns 0 (default)
# ---------------------------------------------------------------------------

func test_game_store_serialization_from_dict_missing_player_xp_returns_zero() -> void:
	# Arrange — build a valid dict but omit "player_xp"
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	data.erase("player_xp")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_xp()).is_equal(0)

func test_game_store_serialization_from_dict_missing_player_gold_returns_zero() -> void:
	# Arrange
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	data.erase("player_gold")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_gold()).is_equal(0)

func test_game_store_serialization_from_dict_missing_current_chapter_returns_default() -> void:
	# Arrange — "ch01" is the documented default for current_chapter
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	data.erase("current_chapter")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_str(store2._current_chapter).is_equal("ch01")

func test_game_store_serialization_from_dict_missing_daily_tokens_returns_three() -> void:
	# Arrange
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	data.erase("daily_tokens_remaining")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_daily_tokens()).is_equal(3)

func test_game_store_serialization_from_dict_missing_last_captain_id_returns_empty() -> void:
	# Arrange
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	data.erase("last_captain_id")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_str(store2.get_last_captain_id()).is_equal("")

# ---------------------------------------------------------------------------
# AC3 — from_dict() with "nyx" absent → "nyx" initialized with default state
# ---------------------------------------------------------------------------

func test_game_store_serialization_from_dict_absent_nyx_initializes_with_defaults() -> void:
	# Arrange — build data that has no "nyx" entry in companion_states
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	var companions: Dictionary = data["companion_states"] as Dictionary
	companions.erase("nyx")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — "nyx" must exist with factory default values
	var nyx_state: Dictionary = store2.get_companion_state("nyx")
	assert_bool(nyx_state.is_empty()).is_false()
	assert_int(nyx_state.get("relationship_level", -1)).is_equal(0)
	assert_int(nyx_state.get("trust", -1)).is_equal(0)
	assert_int(nyx_state.get("motivation", -1)).is_equal(50)
	assert_int(nyx_state.get("dates_completed", -1)).is_equal(0)
	assert_bool(nyx_state.get("met", true)).is_false()
	assert_int(nyx_state.get("current_mood", -1)).is_equal(0)
	assert_str(nyx_state.get("mood_expiry_date", "sentinel")).is_equal("")

func test_game_store_serialization_from_dict_absent_nyx_known_likes_is_empty_array() -> void:
	# Arrange
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	(data["companion_states"] as Dictionary).erase("nyx")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — array fields default to empty
	var nyx_state: Dictionary = store2.get_companion_state("nyx")
	var likes: Array = nyx_state.get("known_likes", null)
	assert_bool(likes != null).is_true()
	assert_int(likes.size()).is_equal(0)

func test_game_store_serialization_from_dict_absent_artemisa_initializes_with_defaults() -> void:
	# Arrange — same guard applies to all 4 known companions
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	(data["companion_states"] as Dictionary).erase("artemisa")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	var state: Dictionary = store2.get_companion_state("artemisa")
	assert_bool(state.is_empty()).is_false()
	assert_int(state.get("relationship_level", -1)).is_equal(0)

# ---------------------------------------------------------------------------
# AC4 — Full round-trip: all getter values match the original
# ---------------------------------------------------------------------------

func test_game_store_serialization_round_trip_player_gold_matches() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(250)

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_gold()).is_equal(store.get_gold())

func test_game_store_serialization_round_trip_player_xp_matches() -> void:
	# Arrange
	var store = _make_store()
	store.add_xp(500)

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_xp()).is_equal(store.get_xp())

func test_game_store_serialization_round_trip_current_chapter_matches() -> void:
	# Arrange
	var store = _make_store()
	store._current_chapter = "ch03"

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_str(store2._current_chapter).is_equal("ch03")

func test_game_store_serialization_round_trip_daily_tokens_matches() -> void:
	# Arrange — default is 3; spend one so the value is non-trivial
	var store = _make_store()
	store.spend_token()

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_daily_tokens()).is_equal(store.get_daily_tokens())

func test_game_store_serialization_round_trip_current_streak_matches() -> void:
	# Arrange
	var store = _make_store()
	store.set_streak(14)

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_streak()).is_equal(14)

func test_game_store_serialization_round_trip_last_interaction_date_matches() -> void:
	# Arrange
	var store = _make_store()
	store._last_interaction_date = "2026-04-10"

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_str(store2._last_interaction_date).is_equal("2026-04-10")

func test_game_store_serialization_round_trip_last_captain_id_matches() -> void:
	# Arrange
	var store = _make_store()
	store.set_last_captain_id("hipolita")

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_str(store2.get_last_captain_id()).is_equal("hipolita")

func test_game_store_serialization_round_trip_story_flags_match() -> void:
	# Arrange
	var store = _make_store()
	store.set_flag("ch01_met_artemisa")
	store.set_flag("ch02_boss_defeated")

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_bool(store2.has_flag("ch01_met_artemisa")).is_true()
	assert_bool(store2.has_flag("ch02_boss_defeated")).is_true()
	assert_int(store2.get_story_flags().size()).is_equal(2)

func test_game_store_serialization_round_trip_node_states_match() -> void:
	# Arrange
	var store = _make_store()
	store.set_node_state("intro_scene", "completed")
	store.set_node_state("market_npc", "greeted")

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_str(store2.get_node_state("intro_scene")).is_equal("completed")
	assert_str(store2.get_node_state("market_npc")).is_equal("greeted")

func test_game_store_serialization_round_trip_combat_buff_matches() -> void:
	# Arrange
	var store = _make_store()
	store.set_combat_buff({"chips": 150, "mult": 2.0, "combats_remaining": 3})

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	var buff: Dictionary = store2.get_combat_buff()
	assert_bool(buff.is_empty()).is_false()
	assert_int(buff.get("chips", -1)).is_equal(150)
	assert_float(buff.get("mult", -1.0)).is_equal(2.0)
	assert_int(buff.get("combats_remaining", -1)).is_equal(3)

func test_game_store_serialization_round_trip_companion_all_fields_match() -> void:
	# Arrange — mutate every field of one companion to non-default values
	var store = _make_store()
	store.set_trust("atenea", 75)
	store.set_met("atenea", true)
	store.set_mood("atenea", 2, "2026-05-01")
	store._set_relationship_level("atenea", 3)
	store._companion_states["atenea"]["motivation"] = 80
	store._companion_states["atenea"]["dates_completed"] = 4
	store._companion_states["atenea"]["known_likes"] = ["poetry", "strategy"]
	store._companion_states["atenea"]["known_dislikes"] = ["chaos"]

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — every field on the companion round-trips correctly
	var state: Dictionary = store2.get_companion_state("atenea")
	assert_int(state.get("trust", -1)).is_equal(75)
	assert_bool(state.get("met", false)).is_true()
	assert_int(state.get("current_mood", -1)).is_equal(2)
	assert_str(state.get("mood_expiry_date", "")).is_equal("2026-05-01")
	assert_int(state.get("relationship_level", -1)).is_equal(3)
	assert_int(state.get("motivation", -1)).is_equal(80)
	assert_int(state.get("dates_completed", -1)).is_equal(4)

func test_game_store_serialization_round_trip_companion_known_likes_match() -> void:
	# Arrange
	var store = _make_store()
	store._companion_states["nyx"]["known_likes"] = ["moonlight", "riddles"]

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	var state: Dictionary = store2.get_companion_state("nyx")
	var likes: Array = state.get("known_likes", [])
	assert_int(likes.size()).is_equal(2)
	assert_bool(likes.has("moonlight")).is_true()
	assert_bool(likes.has("riddles")).is_true()

func test_game_store_serialization_round_trip_companion_known_dislikes_match() -> void:
	# Arrange
	var store = _make_store()
	store._companion_states["hipolita"]["known_dislikes"] = ["deception"]

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	var state: Dictionary = store2.get_companion_state("hipolita")
	var dislikes: Array = state.get("known_dislikes", [])
	assert_int(dislikes.size()).is_equal(1)
	assert_bool(dislikes.has("deception")).is_true()

func test_game_store_serialization_round_trip_all_four_companions_present() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var data: Dictionary = store.to_dict()
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — all 4 companions survive the round-trip
	for id: String in ["artemisa", "hipolita", "atenea", "nyx"]:
		var state: Dictionary = store2.get_companion_state(id)
		assert_bool(state.is_empty()).is_false()

# ---------------------------------------------------------------------------
# AC5 — from_dict() leaves _dirty = false and _save_pending = false
# ---------------------------------------------------------------------------

func test_game_store_serialization_from_dict_leaves_dirty_false() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(100)
	var data: Dictionary = store.to_dict()

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — loading is not a mutation
	assert_bool(store2._dirty).is_false()

func test_game_store_serialization_from_dict_leaves_save_pending_false() -> void:
	# Arrange
	var store = _make_store()
	store.set_flag("any_flag")
	var data: Dictionary = store.to_dict()

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — no deferred flush should be scheduled after a load
	assert_bool(store2._save_pending).is_false()

func test_game_store_serialization_from_dict_clears_preexisting_dirty() -> void:
	# Arrange — the target store was already dirty before from_dict() is called
	var store = _make_store()
	store.add_gold(50)
	var data: Dictionary = store.to_dict()

	var store2 = _make_store()
	store2._dirty = true
	store2._save_pending = true

	# Act
	store2.from_dict(data)

	# Assert — from_dict() must clear both flags regardless of prior state
	assert_bool(store2._dirty).is_false()
	assert_bool(store2._save_pending).is_false()

# ---------------------------------------------------------------------------
# Edge case — Empty Dictionary input to from_dict()
# ---------------------------------------------------------------------------

func test_game_store_serialization_from_dict_empty_dict_gold_is_zero() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert — every field falls back to its documented default
	assert_int(store.get_gold()).is_equal(0)

func test_game_store_serialization_from_dict_empty_dict_xp_is_zero() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert
	assert_int(store.get_xp()).is_equal(0)

func test_game_store_serialization_from_dict_empty_dict_chapter_is_ch01() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert
	assert_str(store._current_chapter).is_equal("ch01")

func test_game_store_serialization_from_dict_empty_dict_tokens_is_three() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert
	assert_int(store.get_daily_tokens()).is_equal(3)

func test_game_store_serialization_from_dict_empty_dict_all_companions_present() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert — all 4 known companions initialized with defaults even with empty input
	for id: String in ["artemisa", "hipolita", "atenea", "nyx"]:
		var state: Dictionary = store.get_companion_state(id)
		assert_bool(state.is_empty()).is_false()

func test_game_store_serialization_from_dict_empty_dict_story_flags_empty() -> void:
	# Arrange
	var store = _make_store()
	store.set_flag("prior_flag")  # dirty the store before loading

	# Act
	store.from_dict({})

	# Assert — flags cleared when input has no story_flags key
	assert_int(store.get_story_flags().size()).is_equal(0)

func test_game_store_serialization_from_dict_empty_dict_combat_buff_empty() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert
	assert_bool(store.get_combat_buff().is_empty()).is_true()

func test_game_store_serialization_from_dict_empty_dict_leaves_dirty_false() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.from_dict({})

	# Assert
	assert_bool(store._dirty).is_false()

# ---------------------------------------------------------------------------
# Edge case — Extra unknown keys in from_dict() are silently ignored
# ---------------------------------------------------------------------------

func test_game_store_serialization_from_dict_extra_keys_ignored_gold_intact() -> void:
	# Arrange — inject unknown keys alongside valid ones
	var store = _make_store()
	store.add_gold(99)
	var data: Dictionary = store.to_dict()
	data["unknown_future_key"] = "some_value"
	data["another_extra"] = 42

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — known values are loaded correctly; extras cause no error
	assert_int(store2.get_gold()).is_equal(99)

func test_game_store_serialization_from_dict_extra_keys_ignored_flags_intact() -> void:
	# Arrange
	var store = _make_store()
	store.set_flag("valid_flag")
	var data: Dictionary = store.to_dict()
	data["obsolete_key"] = true

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_bool(store2.has_flag("valid_flag")).is_true()

# ---------------------------------------------------------------------------
# Edge case — to_dict() returns copies, not live references
# ---------------------------------------------------------------------------

func test_game_store_serialization_to_dict_story_flags_is_a_copy() -> void:
	# Arrange
	var store = _make_store()
	store.set_flag("original_flag")

	# Act — mutate the returned array
	var data: Dictionary = store.to_dict()
	var flags: Array = data["story_flags"] as Array
	flags.append("injected_flag")

	# Assert — internal state is unaffected
	assert_bool(store.has_flag("injected_flag")).is_false()

func test_game_store_serialization_to_dict_companion_known_likes_is_a_copy() -> void:
	# Arrange
	var store = _make_store()
	store._companion_states["artemisa"]["known_likes"] = ["hunting"]

	# Act — mutate the nested array in the returned dict
	var data: Dictionary = store.to_dict()
	var companions: Dictionary = data["companion_states"] as Dictionary
	var artemisa: Dictionary = companions["artemisa"] as Dictionary
	(artemisa["known_likes"] as Array).append("injected")

	# Assert — internal state is unaffected
	assert_int(store._companion_states["artemisa"]["known_likes"].size()).is_equal(1)

func test_game_store_serialization_to_dict_combat_buff_is_a_copy() -> void:
	# Arrange
	var store = _make_store()
	store.set_combat_buff({"chips": 50, "mult": 1.5, "combats_remaining": 2})

	# Act — mutate the returned buff dict
	var data: Dictionary = store.to_dict()
	var buff: Dictionary = data["active_combat_buff"] as Dictionary
	buff["chips"] = 9999

	# Assert — internal state is unaffected
	assert_int(store._active_combat_buff.get("chips", -1)).is_equal(50)
