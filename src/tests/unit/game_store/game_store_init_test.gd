class_name GameStoreInitTest
extends GdUnitTestSuite

# Unit tests for STORY-GS-001: GameStore Schema + Default Initialization
#
# Covers:
#   AC1 — companion states initialized for all 4 IDs with correct defaults
#   AC2 — scalar fields initialized to spec values
#   AC3 — all state properties are private (underscore-prefixed)
#   AC4 — get_combat_buff() returns empty Dictionary on fresh init
#
# See: docs/architecture/adr-0001-gamestore-state.md

const GameStoreScript = preload("res://autoloads/game_store.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates a fresh GameStore instance with defaults initialized.
## Each test gets its own instance so there is no shared mutable state.
func _make_store():
	var store = GameStoreScript.new()
	store._initialize_defaults()
	return store

# ---------------------------------------------------------------------------
# AC1 — Companion states: all 4 IDs, correct field defaults
# ---------------------------------------------------------------------------

func test_game_store_init_all_companion_ids_present() -> void:
	# Arrange / Act
	var store = _make_store()
	var expected_ids: Array[String] = ["artemis", "hipolita", "atenea", "nyx"]

	# Assert
	for id: String in expected_ids:
		var state = store.get_companion_state(id)
		assert_bool(state.is_empty()).is_false()

func test_game_store_init_companion_relationship_level_is_zero() -> void:
	# Arrange / Act
	var store = _make_store()

	# Assert
	for id: String in ["artemis", "hipolita", "atenea", "nyx"]:
		var state = store.get_companion_state(id)
		assert_int(state.get("relationship_level", -1)).is_equal(0)

func test_game_store_init_companion_trust_is_zero() -> void:
	# Arrange / Act
	var store = _make_store()

	# Assert
	for id: String in ["artemis", "hipolita", "atenea", "nyx"]:
		var state = store.get_companion_state(id)
		assert_int(state.get("trust", -1)).is_equal(0)

func test_game_store_init_companion_motivation_is_fifty() -> void:
	# Arrange / Act
	var store = _make_store()

	# Assert
	for id: String in ["artemis", "hipolita", "atenea", "nyx"]:
		var state = store.get_companion_state(id)
		assert_int(state.get("motivation", -1)).is_equal(50)

func test_game_store_init_companion_met_is_false() -> void:
	# Arrange / Act
	var store = _make_store()

	# Assert
	for id: String in ["artemis", "hipolita", "atenea", "nyx"]:
		var state = store.get_companion_state(id)
		assert_bool(state.get("met", true)).is_false()

# ---------------------------------------------------------------------------
# AC2 — Scalar fields match spec defaults
# ---------------------------------------------------------------------------

func test_game_store_init_player_gold_is_zero() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var gold: int = store._player_gold

	# Assert
	assert_int(gold).is_equal(0)

func test_game_store_init_player_xp_is_zero() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var xp: int = store._player_xp

	# Assert
	assert_int(xp).is_equal(0)

func test_game_store_init_daily_tokens_remaining_is_three() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var tokens: int = store._daily_tokens_remaining

	# Assert
	assert_int(tokens).is_equal(3)

func test_game_store_init_current_streak_is_zero() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var streak: int = store._current_streak

	# Assert
	assert_int(streak).is_equal(0)

func test_game_store_init_current_chapter_is_ch01() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var chapter: String = store._current_chapter

	# Assert
	assert_str(chapter).is_equal("ch01")

func test_game_store_init_active_combat_buff_is_empty_dict() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var buff: Dictionary = store._active_combat_buff

	# Assert
	assert_bool(buff.is_empty()).is_true()

# ---------------------------------------------------------------------------
# AC3 — All state properties are private (underscore-prefixed)
#
# This test enumerates the known public property names from the legacy file
# and asserts they do NOT exist as plain (non-underscore) properties on the
# new GameStore. GDScript does not enforce access control, so we verify by
# checking get_property_list() for unintended public names.
# ---------------------------------------------------------------------------

func test_game_store_init_no_public_state_properties_exposed() -> void:
	# Arrange
	var store = _make_store()
	var forbidden_public_names: Array[String] = [
		"companions", "global_flags", "gold", "stars", "player_xp",
		"player_level", "player_name", "completed_chapters",
		"completed_chapter_nodes", "hub_team", "active_companion",
		"companion_states", "story_flags", "node_states",
		"current_chapter", "player_gold", "daily_tokens_remaining",
		"current_streak", "last_interaction_date", "active_combat_buff",
		"last_captain_id",
	]

	# Act — collect all script-defined property names
	var property_names: Array[String] = []
	for prop: Dictionary in store.get_property_list():
		# PROPERTY_USAGE_SCRIPT_VARIABLE = 8192; only care about script vars
		if prop.get("usage", 0) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			property_names.append(prop.get("name", ""))

	# Assert — none of the forbidden public names should appear
	for forbidden: String in forbidden_public_names:
		assert_bool(property_names.has(forbidden)).is_false()

# ---------------------------------------------------------------------------
# AC4 — get_combat_buff() returns empty Dictionary on fresh init
# ---------------------------------------------------------------------------

func test_game_store_init_get_combat_buff_returns_empty_dict() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var buff: Dictionary = store.get_combat_buff()

	# Assert
	assert_bool(buff.is_empty()).is_true()

func test_game_store_init_get_combat_buff_returns_copy_not_reference() -> void:
	# Arrange — mutating the returned dict must not affect internal state
	var store = _make_store()

	# Act
	var buff: Dictionary = store.get_combat_buff()
	buff["chips"] = 999

	# Assert — internal state is unchanged
	assert_bool(store._active_combat_buff.has("chips")).is_false()

# ---------------------------------------------------------------------------
# Additional edge cases
# ---------------------------------------------------------------------------

func test_game_store_init_get_companion_state_unknown_id_returns_empty() -> void:
	# Arrange
	var store = _make_store()

	# Act
	var state = store.get_companion_state("unknown_id")

	# Assert
	assert_bool(state.is_empty()).is_true()

func test_game_store_init_get_companion_state_returns_copy_not_reference() -> void:
	# Arrange — mutating the returned dict must not affect internal state
	var store = _make_store()

	# Act
	var state = store.get_companion_state("artemis")
	state["trust"] = 999

	# Assert — internal state is unchanged
	var fresh_state = store.get_companion_state("artemis")
	assert_int(fresh_state.get("trust", -1)).is_equal(0)

func test_game_store_init_exactly_four_companions_initialized() -> void:
	# Arrange / Act
	var store = _make_store()

	# Assert — no extra companions beyond the spec 4
	assert_int(store._companion_states.size()).is_equal(4)
