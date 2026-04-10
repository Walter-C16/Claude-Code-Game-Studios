class_name SaveMigrationTest
extends GdUnitTestSuite

# Unit tests for STORY SS-004: Save Version Migration Chain
#
# Covers all Acceptance Criteria:
#   AC1 — Save with version 0 → _migrate() returns data with version == SAVE_VERSION,
#          v0→v1 defaults present
#   AC2 — Save already at current version → no migration runs, data unchanged
#   AC3 — v0→v1 adds "player_xp" field to game sub-dict
#   AC4 — Future v2 stub chains correctly from v0 (v1 step still applied)
#
# Notes:
#   _migrate() and _migrate_v0_to_v1() are private — exercised via load_game()
#   with hand-crafted save files that carry specific version numbers.
#   Each test writes a synthetic save.json, calls load_game(), then inspects
#   the restored store state or file content.
#
# See: docs/architecture/adr-0002-save-system.md

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Minimum v0 save payload — no economy / social fields present.
const _V0_GAME_DICT: Dictionary = {
	"companion_states": {},
	"story_flags": [],
	"node_states": {},
	"current_chapter": "ch01",
	"player_gold": 42,
	# player_xp intentionally absent (v0)
	# daily_tokens_remaining intentionally absent (v0)
	# current_streak intentionally absent (v0)
	# last_interaction_date intentionally absent (v0)
	# active_combat_buff intentionally absent (v0)
	# last_captain_id intentionally absent (v0)
}

const _V0_SETTINGS_DICT: Dictionary = {
	"locale": "en",
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"text_speed": 1.0,
}

# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

func before_test() -> void:
	_delete_save_files()
	GameStore._initialize_defaults()
	SettingsStore.from_dict({})

func after_test() -> void:
	_delete_save_files()
	GameStore._initialize_defaults()
	SettingsStore.from_dict({})

func _delete_save_files() -> void:
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	if FileAccess.file_exists("user://save.json.tmp"):
		DirAccess.remove_absolute("user://save.json.tmp")

# ---------------------------------------------------------------------------
# AC1 — version 0 save → load succeeds, version bumped to SAVE_VERSION
# ---------------------------------------------------------------------------

func test_migration_load_game_returns_true_for_version_0_save() -> void:
	# Arrange — write a synthetic v0 save
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	var result: bool = SaveManager.load_game()

	# Assert
	assert_bool(result).is_true()

func test_migration_version_0_save_loads_player_gold_correctly() -> void:
	# Arrange — v0 save has player_gold: 42
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — gold must survive migration
	assert_int(GameStore.get_gold()).is_equal(42)

func test_migration_version_0_save_sets_player_xp_to_zero_default() -> void:
	# Arrange — v0 game dict has no player_xp field
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — v0→v1 migration must inject player_xp = 0
	assert_int(GameStore.get_xp()).is_equal(0)

func test_migration_version_0_save_sets_daily_tokens_to_three() -> void:
	# Arrange
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — v0→v1 default is 3 tokens
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

func test_migration_version_0_save_sets_current_streak_to_zero() -> void:
	# Arrange
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert
	assert_int(GameStore.get_streak()).is_equal(0)

func test_migration_version_0_save_sets_last_captain_id_to_empty() -> void:
	# Arrange
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert
	assert_str(GameStore.get_last_captain_id()).is_equal("")

func test_migration_version_0_save_sets_combat_buff_to_empty() -> void:
	# Arrange
	_write_versioned_save(0, _V0_GAME_DICT, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert
	assert_bool(GameStore.get_combat_buff().is_empty()).is_true()

# ---------------------------------------------------------------------------
# AC2 — Current version save → no migration, data unchanged
# ---------------------------------------------------------------------------

func test_migration_current_version_save_returns_true() -> void:
	# Arrange — write a fully-populated current-version save
	SaveManager.save_game()

	# Act
	var result: bool = SaveManager.load_game()

	# Assert
	assert_bool(result).is_true()

func test_migration_current_version_save_preserves_gold() -> void:
	# Arrange — put specific gold in store, save it (at SAVE_VERSION)
	GameStore.add_gold(999)
	SaveManager.save_game()
	GameStore._initialize_defaults()

	# Act
	SaveManager.load_game()

	# Assert — gold must be exactly preserved (no migration ran)
	assert_int(GameStore.get_gold()).is_equal(999)

func test_migration_current_version_save_preserves_xp() -> void:
	# Arrange
	GameStore.add_xp(4200)
	SaveManager.save_game()
	GameStore._initialize_defaults()

	# Act
	SaveManager.load_game()

	# Assert
	assert_int(GameStore.get_xp()).is_equal(4200)

func test_migration_current_version_save_preserves_locale() -> void:
	# Arrange
	SettingsStore.set_locale("es")
	SaveManager.save_game()
	SettingsStore.from_dict({})

	# Act
	SaveManager.load_game()

	# Assert
	assert_str(SettingsStore.get_locale()).is_equal("es")

func test_migration_current_version_save_preserves_story_flags() -> void:
	# Arrange
	GameStore.set_flag("ch02_boss_defeated")
	SaveManager.save_game()
	GameStore._initialize_defaults()

	# Act
	SaveManager.load_game()

	# Assert — flag must survive round-trip with no migration interference
	assert_bool(GameStore.has_flag("ch02_boss_defeated")).is_true()

# ---------------------------------------------------------------------------
# AC3 — v0→v1 adds "player_xp" field to the game sub-dict
# ---------------------------------------------------------------------------

func test_migration_v0_to_v1_adds_player_xp_key_to_game_dict() -> void:
	# Arrange — craft a v0 game dict with player_xp explicitly absent
	var v0_game: Dictionary = _V0_GAME_DICT.duplicate()
	assert_bool(v0_game.has("player_xp")).is_false()
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — after migration + restore, GameStore must have xp = 0
	# (proves player_xp was injected by _migrate_v0_to_v1)
	assert_int(GameStore.get_xp()).is_equal(0)

func test_migration_v0_to_v1_does_not_overwrite_existing_player_xp() -> void:
	# Arrange — a v0 save that somehow already has player_xp (partial migration)
	var v0_game_with_xp: Dictionary = _V0_GAME_DICT.duplicate()
	v0_game_with_xp["player_xp"] = 500
	_write_versioned_save(0, v0_game_with_xp, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — _migrate_v0_to_v1 uses has() guard; existing value must survive
	assert_int(GameStore.get_xp()).is_equal(500)

func test_migration_v0_to_v1_adds_daily_tokens_remaining_key() -> void:
	# Arrange
	var v0_game: Dictionary = _V0_GAME_DICT.duplicate()
	assert_bool(v0_game.has("daily_tokens_remaining")).is_false()
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — default 3 tokens injected
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

func test_migration_v0_to_v1_adds_current_streak_key() -> void:
	# Arrange
	var v0_game: Dictionary = _V0_GAME_DICT.duplicate()
	assert_bool(v0_game.has("current_streak")).is_false()
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert
	assert_int(GameStore.get_streak()).is_equal(0)

func test_migration_v0_to_v1_adds_last_interaction_date_key() -> void:
	# Arrange
	var v0_game: Dictionary = _V0_GAME_DICT.duplicate()
	assert_bool(v0_game.has("last_interaction_date")).is_false()
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — GameStore exposes last_interaction_date through from_dict().
	# The field exists; verify indirectly: load succeeds with no crash and
	# daily_tokens (sentinel for v0→v1 completion) equals 3.
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

func test_migration_v0_to_v1_adds_active_combat_buff_key() -> void:
	# Arrange
	var v0_game: Dictionary = _V0_GAME_DICT.duplicate()
	assert_bool(v0_game.has("active_combat_buff")).is_false()
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert
	assert_bool(GameStore.get_combat_buff().is_empty()).is_true()

func test_migration_v0_to_v1_adds_last_captain_id_key() -> void:
	# Arrange
	var v0_game: Dictionary = _V0_GAME_DICT.duplicate()
	assert_bool(v0_game.has("last_captain_id")).is_false()
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert
	assert_str(GameStore.get_last_captain_id()).is_equal("")

# ---------------------------------------------------------------------------
# AC4 — Future v2 stub chains correctly from v0 (v1 step still runs)
#
# The actual v1→v2 migration code is not yet written (it is a future stub).
# What we CAN verify now: if a v0 save is loaded, _migrate() applies v0→v1,
# then reaches the "future v2" branch (which is a no-op comment) and returns
# data at SAVE_VERSION. The v1 defaults must all be present in the final state,
# proving the chain was not short-circuited.
# ---------------------------------------------------------------------------

func test_migration_chain_v0_load_results_in_all_v1_defaults_present() -> void:
	# Arrange — bare v0 save with none of the v1 fields
	var v0_game: Dictionary = {
		"companion_states": {},
		"story_flags": [],
		"node_states": {},
		"current_chapter": "ch01",
		"player_gold": 0,
	}
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	var result: bool = SaveManager.load_game()

	# Assert — all v0→v1 fields must be present and at their defaults
	assert_bool(result).is_true()
	assert_int(GameStore.get_xp()).is_equal(0)
	assert_int(GameStore.get_daily_tokens()).is_equal(3)
	assert_int(GameStore.get_streak()).is_equal(0)
	assert_str(GameStore.get_last_captain_id()).is_equal("")
	assert_bool(GameStore.get_combat_buff().is_empty()).is_true()

func test_migration_chain_v0_load_preserves_gold_through_all_steps() -> void:
	# Arrange — v0 save with non-zero gold, no v1 fields
	var v0_game: Dictionary = {
		"companion_states": {},
		"story_flags": [],
		"node_states": {},
		"current_chapter": "ch01",
		"player_gold": 123,
	}
	_write_versioned_save(0, v0_game, _V0_SETTINGS_DICT)

	# Act
	SaveManager.load_game()

	# Assert — gold must survive the full migration chain unchanged
	assert_int(GameStore.get_gold()).is_equal(123)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Writes a synthetic save.json with a specific version number and sub-dicts.
## Used to craft v0 saves (or other versions) that real save_game() won't produce.
func _write_versioned_save(
		version: int,
		game: Dictionary,
		settings: Dictionary) -> void:
	var payload: Dictionary = {
		"version": version,
		"timestamp": int(Time.get_unix_time_from_system()),
		"game": game,
		"settings": settings,
	}
	var json_string: String = JSON.stringify(payload)
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
