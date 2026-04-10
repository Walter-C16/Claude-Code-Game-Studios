class_name GameStoreSettersTest
extends GdUnitTestSuite

# Unit tests for STORY-GS-002: GameStore Typed Getters and Setters
#
# Covers all Acceptance Criteria:
#   AC1 — spend_gold(30) with gold=50 returns true, gold becomes 20
#   AC2 — spend_gold(30) with gold=10 returns false, gold stays 10
#   AC3 — set_flag() is idempotent; has_flag() returns true
#   AC4 — set_trust() updates companion trust, readable via get_companion_state()
#   AC5 — every setter sets _dirty = true
#   AC6 — get_node_state() on unknown key returns empty String (not null/error)
#
# See: docs/architecture/adr-0001-gamestore-state.md

const GameStoreScript = preload("res://autoloads/game_store.gd")

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
# AC1 — spend_gold: sufficient funds → deducts and returns true
# ---------------------------------------------------------------------------

func test_game_store_spend_gold_sufficient_returns_true() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(50)

	# Act
	var result: bool = store.spend_gold(30)

	# Assert
	assert_bool(result).is_true()

func test_game_store_spend_gold_sufficient_deducts_correct_amount() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(50)

	# Act
	store.spend_gold(30)

	# Assert
	assert_int(store.get_gold()).is_equal(20)

# ---------------------------------------------------------------------------
# AC2 — spend_gold: insufficient funds → returns false, gold unchanged
# ---------------------------------------------------------------------------

func test_game_store_spend_gold_insufficient_returns_false() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(10)

	# Act
	var result: bool = store.spend_gold(30)

	# Assert
	assert_bool(result).is_false()

func test_game_store_spend_gold_insufficient_gold_unchanged() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(10)

	# Act
	store.spend_gold(30)

	# Assert
	assert_int(store.get_gold()).is_equal(10)

# ---------------------------------------------------------------------------
# AC3 — set_flag: idempotent, has_flag returns true, no duplicates
# ---------------------------------------------------------------------------

func test_game_store_set_flag_duplicate_call_no_extra_entry() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.set_flag("ch01_met_artemis")
	store.set_flag("ch01_met_artemis")

	# Assert — exactly one entry
	assert_int(store.get_story_flags().size()).is_equal(1)

func test_game_store_set_flag_has_flag_returns_true() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.set_flag("ch01_met_artemis")

	# Assert
	assert_bool(store.has_flag("ch01_met_artemis")).is_true()

func test_game_store_has_flag_absent_flag_returns_false() -> void:
	# Arrange
	var store = _make_store()

	# Act / Assert — nothing set yet
	assert_bool(store.has_flag("ch01_met_artemis")).is_false()

# ---------------------------------------------------------------------------
# AC4 — set_trust: companion trust updates, readable via get_companion_state
# ---------------------------------------------------------------------------

func test_game_store_set_trust_updates_companion_state() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.set_trust("artemis", 10)

	# Assert
	var state = store.get_companion_state("artemis")
	assert_int(state.get("trust", -1)).is_equal(10)

func test_game_store_set_trust_from_nonzero_baseline() -> void:
	# Arrange — trust starts at 5 via internal dict (tests internal default override)
	var store = _make_store()
	store.set_trust("artemis", 5)

	# Act
	store.set_trust("artemis", 10)

	# Assert
	var state = store.get_companion_state("artemis")
	assert_int(state.get("trust", -1)).is_equal(10)

func test_game_store_set_trust_unknown_companion_is_noop() -> void:
	# Arrange
	var store = _make_store()

	# Act — should not crash or create a new entry
	store.set_trust("unknown_companion", 99)

	# Assert — only the original 4 companions exist
	assert_int(store._companion_states.size()).is_equal(4)

# ---------------------------------------------------------------------------
# AC5 — every setter sets _dirty = true
# ---------------------------------------------------------------------------

func test_game_store_add_gold_sets_dirty() -> void:
	var store = _make_store()
	store.add_gold(10)
	assert_bool(store._dirty).is_true()

func test_game_store_spend_gold_success_sets_dirty() -> void:
	var store = _make_store()
	store.add_gold(50)
	store._dirty = false
	store.spend_gold(10)
	assert_bool(store._dirty).is_true()

func test_game_store_spend_gold_failure_does_not_set_dirty() -> void:
	# Insufficient funds — no mutation occurred, so _dirty must stay false.
	var store = _make_store()
	store._dirty = false
	store.spend_gold(9999)
	assert_bool(store._dirty).is_false()

func test_game_store_set_flag_sets_dirty() -> void:
	var store = _make_store()
	store.set_flag("test_flag")
	assert_bool(store._dirty).is_true()

func test_game_store_set_flag_idempotent_does_not_set_dirty() -> void:
	# Already-present flag is a no-op — dirty must not be set.
	var store = _make_store()
	store.set_flag("test_flag")
	store._dirty = false
	store.set_flag("test_flag")
	assert_bool(store._dirty).is_false()

func test_game_store_set_trust_sets_dirty() -> void:
	var store = _make_store()
	store.set_trust("artemis", 5)
	assert_bool(store._dirty).is_true()

func test_game_store_set_met_sets_dirty() -> void:
	var store = _make_store()
	store.set_met("hipolita", true)
	assert_bool(store._dirty).is_true()

func test_game_store_set_node_state_sets_dirty() -> void:
	var store = _make_store()
	store.set_node_state("node_42", "visited")
	assert_bool(store._dirty).is_true()

func test_game_store_set_combat_buff_sets_dirty() -> void:
	var store = _make_store()
	store.set_combat_buff({"chips": 100, "mult": 1.5, "combats_remaining": 2})
	assert_bool(store._dirty).is_true()

func test_game_store_clear_combat_buff_sets_dirty() -> void:
	var store = _make_store()
	store._dirty = false
	store.clear_combat_buff()
	assert_bool(store._dirty).is_true()

func test_game_store_spend_token_sets_dirty() -> void:
	var store = _make_store()
	store.spend_token()
	assert_bool(store._dirty).is_true()

func test_game_store_reset_tokens_sets_dirty() -> void:
	var store = _make_store()
	store._dirty = false
	store.reset_tokens()
	assert_bool(store._dirty).is_true()

func test_game_store_set_streak_sets_dirty() -> void:
	var store = _make_store()
	store.set_streak(7)
	assert_bool(store._dirty).is_true()

func test_game_store_set_last_captain_id_sets_dirty() -> void:
	var store = _make_store()
	store.set_last_captain_id("atenea")
	assert_bool(store._dirty).is_true()

func test_game_store_set_mood_sets_dirty() -> void:
	var store = _make_store()
	store.set_mood("nyx", 2, "2026-05-01")
	assert_bool(store._dirty).is_true()

# ---------------------------------------------------------------------------
# AC6 — get_node_state: missing key returns empty String, not null/error
# ---------------------------------------------------------------------------

func test_game_store_get_node_state_unknown_key_returns_empty_string() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var result: String = store.get_node_state("node_42")

	# Assert — must be an empty String (not null, not error)
	assert_str(result).is_equal("")

func test_game_store_get_node_state_after_set_returns_correct_value() -> void:
	# Arrange
	var store = _make_store()
	store.set_node_state("node_42", "completed")

	# Act
	var result: String = store.get_node_state("node_42")

	# Assert
	assert_str(result).is_equal("completed")

# ---------------------------------------------------------------------------
# Additional edge cases — economy
# ---------------------------------------------------------------------------

func test_game_store_spend_gold_zero_returns_true() -> void:
	# Spending 0 gold is always valid (gold >= 0 >= 0).
	var store = _make_store()
	var result: bool = store.spend_gold(0)
	assert_bool(result).is_true()

func test_game_store_spend_gold_zero_gold_unchanged() -> void:
	var store = _make_store()
	store.spend_gold(0)
	assert_int(store.get_gold()).is_equal(0)

func test_game_store_add_gold_accumulates() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.add_gold(25)
	store.add_gold(25)

	# Assert
	assert_int(store.get_gold()).is_equal(50)

# ---------------------------------------------------------------------------
# Additional edge cases — story flags
# ---------------------------------------------------------------------------

func test_game_store_get_story_flags_returns_copy_not_reference() -> void:
	# Arrange — mutating the returned array must not affect internal state.
	var store = _make_store()
	store.set_flag("ch01_met_artemis")

	# Act
	var flags: Array[String] = store.get_story_flags()
	flags.append("injected_flag")

	# Assert — internal state unchanged
	assert_int(store.get_story_flags().size()).is_equal(1)

# ---------------------------------------------------------------------------
# Additional edge cases — companion getters
# ---------------------------------------------------------------------------

func test_game_store_get_relationship_level_default_is_zero() -> void:
	var store = _make_store()
	assert_int(store.get_relationship_level("artemis")).is_equal(0)

func test_game_store_get_relationship_level_unknown_id_returns_zero() -> void:
	var store = _make_store()
	assert_int(store.get_relationship_level("nobody")).is_equal(0)

func test_game_store_set_relationship_level_internal_updates_value() -> void:
	# Arrange
	var store = _make_store()

	# Act — _set_relationship_level is internal but callable from tests
	store._set_relationship_level("artemis", 5)

	# Assert
	assert_int(store.get_relationship_level("artemis")).is_equal(5)

func test_game_store_set_relationship_level_internal_sets_dirty() -> void:
	var store = _make_store()
	store._set_relationship_level("artemis", 3)
	assert_bool(store._dirty).is_true()

func test_game_store_set_met_updates_companion_state() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.set_met("hipolita", true)

	# Assert
	var state = store.get_companion_state("hipolita")
	assert_bool(state.get("met", false)).is_true()

func test_game_store_get_mood_default_is_zero() -> void:
	var store = _make_store()
	assert_int(store.get_mood("nyx")).is_equal(0)

func test_game_store_set_mood_updates_mood_and_expiry() -> void:
	# Arrange
	var store = _make_store()

	# Act
	store.set_mood("nyx", 3, "2026-12-31")

	# Assert
	assert_int(store.get_mood("nyx")).is_equal(3)
	var state = store.get_companion_state("nyx")
	assert_str(state.get("mood_expiry_date", "")).is_equal("2026-12-31")

# ---------------------------------------------------------------------------
# Additional edge cases — romance / tokens
# ---------------------------------------------------------------------------

func test_game_store_get_daily_tokens_default_is_three() -> void:
	var store = _make_store()
	assert_int(store.get_daily_tokens()).is_equal(3)

func test_game_store_spend_token_decrements_by_one() -> void:
	var store = _make_store()
	store.spend_token()
	assert_int(store.get_daily_tokens()).is_equal(2)

func test_game_store_spend_token_clamps_at_zero() -> void:
	# Arrange — exhaust all 3 tokens, then try to spend a 4th.
	var store = _make_store()
	store.spend_token()
	store.spend_token()
	store.spend_token()
	store._dirty = false

	# Act
	store.spend_token()

	# Assert — stays at 0, no negative
	assert_int(store.get_daily_tokens()).is_equal(0)
	# No mutation occurred, so _dirty should remain false.
	assert_bool(store._dirty).is_false()

func test_game_store_reset_tokens_restores_to_three() -> void:
	# Arrange — spend down to 1
	var store = _make_store()
	store.spend_token()
	store.spend_token()

	# Act
	store.reset_tokens()

	# Assert
	assert_int(store.get_daily_tokens()).is_equal(3)

func test_game_store_get_streak_default_is_zero() -> void:
	var store = _make_store()
	assert_int(store.get_streak()).is_equal(0)

func test_game_store_set_streak_updates_value() -> void:
	var store = _make_store()
	store.set_streak(14)
	assert_int(store.get_streak()).is_equal(14)

# ---------------------------------------------------------------------------
# Additional edge cases — captain
# ---------------------------------------------------------------------------

func test_game_store_get_last_captain_id_default_is_empty() -> void:
	var store = _make_store()
	assert_str(store.get_last_captain_id()).is_equal("")

func test_game_store_set_last_captain_id_updates_value() -> void:
	var store = _make_store()
	store.set_last_captain_id("atenea")
	assert_str(store.get_last_captain_id()).is_equal("atenea")

# ---------------------------------------------------------------------------
# Additional edge cases — combat buff
# ---------------------------------------------------------------------------

func test_game_store_set_combat_buff_readable_via_get() -> void:
	# Arrange
	var store = _make_store()
	var buff: Dictionary = {"chips": 200, "mult": 2.0, "combats_remaining": 3}

	# Act
	store.set_combat_buff(buff)

	# Assert
	var retrieved: Dictionary = store.get_combat_buff()
	assert_int(retrieved.get("chips", 0)).is_equal(200)
	assert_float(retrieved.get("mult", 0.0)).is_equal(2.0)
	assert_int(retrieved.get("combats_remaining", 0)).is_equal(3)

func test_game_store_clear_combat_buff_returns_empty_dict() -> void:
	# Arrange
	var store = _make_store()
	store.set_combat_buff({"chips": 100, "mult": 1.5, "combats_remaining": 1})

	# Act
	store.clear_combat_buff()

	# Assert
	assert_bool(store.get_combat_buff().is_empty()).is_true()

# ---------------------------------------------------------------------------
# Serialization — to_dict / from_dict
# ---------------------------------------------------------------------------

func test_game_store_to_dict_from_dict_round_trip_gold() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(123)
	var data: Dictionary = store.to_dict()

	# Act — fresh store loaded from dict
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_gold()).is_equal(123)

func test_game_store_from_dict_does_not_set_dirty() -> void:
	# Arrange
	var store = _make_store()
	store.add_gold(50)
	var data: Dictionary = store.to_dict()

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert — loading is NOT a mutation
	assert_bool(store2._dirty).is_false()

func test_game_store_from_dict_story_flags_restored() -> void:
	# Arrange
	var store = _make_store()
	store.set_flag("ch01_met_artemis")
	store.set_flag("ch01_first_combat")
	var data: Dictionary = store.to_dict()

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_bool(store2.has_flag("ch01_met_artemis")).is_true()
	assert_bool(store2.has_flag("ch01_first_combat")).is_true()
	assert_int(store2.get_story_flags().size()).is_equal(2)

func test_game_store_from_dict_companion_trust_restored() -> void:
	# Arrange
	var store = _make_store()
	store.set_trust("artemis", 7)
	var data: Dictionary = store.to_dict()

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	var state = store2.get_companion_state("artemis")
	assert_int(state.get("trust", -1)).is_equal(7)

func test_game_store_from_dict_missing_companion_gets_default_state() -> void:
	# Simulate an old save that has no "nyx" entry (new companion added in update).
	var store = _make_store()
	var data: Dictionary = store.to_dict()

	# Remove nyx from the saved data to simulate old save format.
	(data["companion_states"] as Dictionary).erase("nyx")

	# Act — from_dict loads only what's in save; reconcile adds missing
	var store2 = _make_store()
	store2.from_dict(data)
	store2.reconcile_companion_states(["artemis", "hipolita", "atenea", "nyx"] as Array[String])

	# Assert — nyx exists with defaults
	var state = store2.get_companion_state("nyx")
	assert_bool(state.is_empty()).is_false()
	assert_int(state.get("relationship_level", -1)).is_equal(0)
	assert_int(state.get("trust", -1)).is_equal(0)

func test_game_store_from_dict_missing_gold_field_defaults_to_zero() -> void:
	# Simulate a save dict that predates the gold field.
	var store = _make_store()
	var data: Dictionary = store.to_dict()
	data.erase("player_gold")

	# Act
	var store2 = _make_store()
	store2.from_dict(data)

	# Assert
	assert_int(store2.get_gold()).is_equal(0)
