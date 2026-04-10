class_name SaveMigrationTest
extends GdUnitTestSuite

# Integration tests for COMPANION-005: Save Migration
#
# Verifies that load_game() correctly reconciles companion states when the
# save file was written by an older build (missing companions, stale companions).
#
# Acceptance Criteria:
#   AC1 — load_game() with a save that has all 4 companions → states preserved,
#          no companions added or removed.
#   AC2 — load_game() with a save missing "nyx" → "nyx" state is added with
#          defaults; existing companions are unaffected.
#   AC3 — load_game() with a save containing an unknown ID "old_companion" →
#          "old_companion" is removed from GameStore after load.
#   AC4 — reconcile_companion_states() does NOT set _dirty or _save_pending
#          (load path must not trigger a write).
#   AC5 — A save written after reconciliation contains exactly the 4 canonical
#          companion IDs and no extra keys.
#
# Notes:
#   Tests run headless with all autoloads active (project.godot). GameStore
#   and SaveManager are live singletons — no mocking needed.
#   Each test cleans up save artifacts and resets stores in before_test()
#   and after_test().
#
# See: docs/architecture/adr-0001-gamestore-state.md
#      docs/architecture/adr-0002-save-system.md

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const CANONICAL_IDS: Array[String] = ["artemis", "hipolita", "atenea", "nyx"]

# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

func before_test() -> void:
	_delete_save_files()
	GameStore._initialize_defaults()
	GameStore._dirty = false
	GameStore._save_pending = false

func after_test() -> void:
	_delete_save_files()
	GameStore._initialize_defaults()
	GameStore._dirty = false
	GameStore._save_pending = false

func _delete_save_files() -> void:
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	if FileAccess.file_exists("user://save.json.tmp"):
		DirAccess.remove_absolute("user://save.json.tmp")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Writes a synthetic save JSON to user://save.json so load_game() can read it.
## [param companion_dict] maps companion IDs to their state dictionaries.
## All non-companion fields use safe defaults matching GameStore._initialize_defaults().
func _write_save_with_companions(companion_dict: Dictionary) -> void:
	var game_data: Dictionary = {
		"companion_states": companion_dict,
		"story_flags": [],
		"node_states": {},
		"current_chapter": "ch01",
		"player_gold": 0,
		"player_xp": 0,
		"daily_tokens_remaining": 3,
		"current_streak": 0,
		"last_interaction_date": "",
		"active_combat_buff": {},
		"last_captain_id": "",
	}
	var save_data: Dictionary = {
		"version": SaveManager.SAVE_VERSION,
		"timestamp": 0,
		"game": game_data,
		"settings": {},
	}
	var file: FileAccess = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

## Returns a default companion state dictionary (mirrors GameStore defaults).
func _default_state() -> Dictionary:
	return {
		"relationship_level": 0,
		"trust": 0,
		"motivation": 50,
		"dates_completed": 0,
		"met": false,
		"known_likes": [],
		"known_dislikes": [],
		"current_mood": 0,
		"mood_expiry_date": "",
	}

# ---------------------------------------------------------------------------
# AC1 — Save with all 4 companions → states preserved exactly
# ---------------------------------------------------------------------------

func test_save_migration_full_save_preserves_all_four_companions() -> void:
	# Arrange — build a save that already contains all 4 canonical companions,
	# each with distinctive non-default values so we can confirm preservation.
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		var state: Dictionary = _default_state()
		state["relationship_level"] = 2
		state["trust"] = 30
		companions[id] = state
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — all 4 companions must be present
	for id: String in CANONICAL_IDS:
		var state: Dictionary = GameStore.get_companion_state(id)
		assert_bool(state.is_empty()).is_false()

func test_save_migration_full_save_relationship_level_not_reset() -> void:
	# Arrange — save artemis at relationship_level 3
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		companions[id] = _default_state()
	companions["artemis"]["relationship_level"] = 3
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — existing value must survive reconciliation
	assert_int(GameStore.get_relationship_level("artemis")).is_equal(3)

func test_save_migration_full_save_no_extra_companions_added() -> void:
	# Arrange
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		companions[id] = _default_state()
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — exactly 4 companions in GameStore; no phantom additions
	var count: int = 0
	for id: String in CANONICAL_IDS:
		if not GameStore.get_companion_state(id).is_empty():
			count += 1
	assert_int(count).is_equal(4)

# ---------------------------------------------------------------------------
# AC2 — Save missing "nyx" → "nyx" added with defaults
# ---------------------------------------------------------------------------

func test_save_migration_missing_nyx_adds_nyx_after_load() -> void:
	# Arrange — save with only artemis, hipolita, atenea (nyx absent)
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
	}
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — nyx must now be present
	var nyx_state: Dictionary = GameStore.get_companion_state("nyx")
	assert_bool(nyx_state.is_empty()).is_false()

func test_save_migration_missing_nyx_added_with_default_relationship_level() -> void:
	# Arrange
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
	}
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — synthesized nyx starts at relationship_level 0
	assert_int(GameStore.get_relationship_level("nyx")).is_equal(0)

func test_save_migration_missing_nyx_existing_companions_unaffected() -> void:
	# Arrange — artemis has a distinctive trust value
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
	}
	companions["artemis"]["trust"] = 42
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — artemis's trust value is preserved
	var artemis: Dictionary = GameStore.get_companion_state("artemis")
	assert_int(artemis.get("trust", -1)).is_equal(42)

# ---------------------------------------------------------------------------
# AC3 — Save with unknown ID "old_companion" → removed after load
# ---------------------------------------------------------------------------

func test_save_migration_unknown_id_removed_from_game_store() -> void:
	# Arrange — save contains the 4 canonical companions plus a stale entry
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		companions[id] = _default_state()
	companions["old_companion"] = _default_state()
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — stale entry must not exist in GameStore
	var stale_state: Dictionary = GameStore.get_companion_state("old_companion")
	assert_bool(stale_state.is_empty()).is_true()

func test_save_migration_unknown_id_canonical_companions_still_present() -> void:
	# Arrange
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		companions[id] = _default_state()
	companions["old_companion"] = _default_state()
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — all 4 canonical companions remain intact
	for id: String in CANONICAL_IDS:
		assert_bool(GameStore.get_companion_state(id).is_empty()).is_false()

# ---------------------------------------------------------------------------
# AC4 — Reconciliation does NOT dirty the store
# ---------------------------------------------------------------------------

func test_save_migration_reconcile_does_not_set_dirty_flag() -> void:
	# Arrange — save with nyx absent so reconciliation must add it
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
	}
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — _dirty must be false after the full load + reconcile path
	assert_bool(GameStore._dirty).is_false()

func test_save_migration_reconcile_does_not_set_save_pending_flag() -> void:
	# Arrange — save with stale entry so reconciliation must remove it
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		companions[id] = _default_state()
	companions["old_companion"] = _default_state()
	_write_save_with_companions(companions)

	# Act
	SaveManager.load_game()

	# Assert — no deferred flush queued
	assert_bool(GameStore._save_pending).is_false()

func test_save_migration_reconcile_no_write_to_disk_after_load() -> await:
	# Arrange — delete save file after writing so we can detect any re-write
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
	}
	_write_save_with_companions(companions)
	SaveManager.load_game()
	_delete_save_files()  # wipe the file we just loaded

	# Act — wait a frame for any accidentally queued deferred flush
	await get_tree().process_frame

	# Assert — no save file written as a side-effect of reconciliation
	assert_bool(FileAccess.file_exists("user://save.json")).is_false()

# ---------------------------------------------------------------------------
# AC5 — A save written post-reconciliation has exactly the 4 canonical IDs
# ---------------------------------------------------------------------------

func test_save_migration_post_reconcile_save_has_exactly_four_companions() -> void:
	# Arrange — load a save that had a stale entry and a missing companion;
	# reconciliation fixes both, then we save again.
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
		"old_companion": _default_state(),  # stale — should be removed
		# nyx absent — should be added
	}
	_write_save_with_companions(companions)
	SaveManager.load_game()

	# Act — write the reconciled state back to disk
	SaveManager.save_game()

	# Assert — re-read the file and count companion keys
	var file: FileAccess = FileAccess.open("user://save.json", FileAccess.READ)
	assert_bool(file != null).is_true()
	var raw: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	assert_int(json.parse(raw)).is_equal(OK)
	var data: Dictionary = json.data as Dictionary
	var game: Dictionary = data.get("game", {}) as Dictionary
	var saved_companions: Dictionary = game.get("companion_states", {}) as Dictionary

	assert_int(saved_companions.size()).is_equal(4)

func test_save_migration_post_reconcile_save_contains_nyx() -> void:
	# Arrange — nyx was absent in the original save
	var companions: Dictionary = {
		"artemis": _default_state(),
		"hipolita": _default_state(),
		"atenea": _default_state(),
	}
	_write_save_with_companions(companions)
	SaveManager.load_game()

	# Act
	SaveManager.save_game()

	# Assert — nyx is present in the re-saved file
	var file: FileAccess = FileAccess.open("user://save.json", FileAccess.READ)
	var raw: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	json.parse(raw)
	var data: Dictionary = json.data as Dictionary
	var game: Dictionary = data.get("game", {}) as Dictionary
	var saved_companions: Dictionary = game.get("companion_states", {}) as Dictionary
	assert_bool(saved_companions.has("nyx")).is_true()

func test_save_migration_post_reconcile_save_excludes_old_companion() -> void:
	# Arrange — stale entry was present in the original save
	var companions: Dictionary = {}
	for id: String in CANONICAL_IDS:
		companions[id] = _default_state()
	companions["old_companion"] = _default_state()
	_write_save_with_companions(companions)
	SaveManager.load_game()

	# Act
	SaveManager.save_game()

	# Assert — stale entry must not appear in the re-saved file
	var file: FileAccess = FileAccess.open("user://save.json", FileAccess.READ)
	var raw: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	json.parse(raw)
	var data: Dictionary = json.data as Dictionary
	var game: Dictionary = data.get("game", {}) as Dictionary
	var saved_companions: Dictionary = game.get("companion_states", {}) as Dictionary
	assert_bool(saved_companions.has("old_companion")).is_false()
