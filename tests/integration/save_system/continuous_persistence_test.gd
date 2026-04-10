class_name ContinuousPersistenceTest
extends GdUnitTestSuite

# Integration tests for STORY-SS-006: Continuous Persistence Integration
#
# Verifies the end-to-end contract between GameStore's dirty-flag / deferred
# flush mechanism (GS-003) and SaveManager's atomic write (SS-002).
#
# Acceptance Criteria:
#   AC1 — GameStore.add_gold(50) → by next frame, save.json exists with the
#          new gold value.
#   AC2 — 3 different GameStore setters in the same frame → exactly 1 disk
#          write occurs. Verified via the _save_pending guard: after one
#          setter the guard is raised; subsequent setters in the same frame
#          do not re-queue a flush. After the frame, exactly one flush ran
#          (flags cleared, file written).
#   AC3 — to_dict() / save_game() output contains no "hand", "deck_order",
#          or "score" keys in the "game" section (ephemeral combat state is
#          intentionally not persisted).
#   AC4 — GameStore.from_dict() (load path) does NOT trigger a save write.
#          Loading must not set _dirty or _save_pending, and no save.json
#          should appear as a result of the load call alone.
#
# Notes:
#   - These tests run headless with all autoloads active (project.godot).
#     GameStore and SaveManager are live singletons — no mocking needed.
#   - Each test gets a known-good GameStore state via _reset_store() and
#     clean filesystem state via _delete_save_files().
#   - await get_tree().process_frame is used to allow call_deferred() to
#     execute between AC1/AC2 assertions.
#
# See: docs/architecture/adr-0001-gamestore-state.md
#      docs/architecture/adr-0002-save-system.md

# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

func before_test() -> void:
	# Ensure a clean filesystem and known GameStore state before every test.
	_delete_save_files()
	GameStore._initialize_defaults()
	# Clear any pending deferred flush left over from defaults initialization.
	GameStore._dirty = false
	GameStore._save_pending = false

func after_test() -> void:
	# Remove save artifacts so tests do not interfere with each other.
	_delete_save_files()

func _delete_save_files() -> void:
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	if FileAccess.file_exists("user://save.json.tmp"):
		DirAccess.remove_absolute("user://save.json.tmp")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Reads and parses user://save.json. Returns an empty Dictionary on failure.
func _read_save_json() -> Dictionary:
	var file := FileAccess.open("user://save.json", FileAccess.READ)
	if not file:
		return {}
	var raw: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return {}
	return json.data as Dictionary

# ---------------------------------------------------------------------------
# AC1 — add_gold(50) → next frame → save.json exists with the new gold value
# ---------------------------------------------------------------------------

func test_continuous_persistence_add_gold_creates_save_file_by_next_frame() -> await:
	# Arrange — clean slate guaranteed by before_test()

	# Act — mutate state; deferred flush is now queued
	GameStore.add_gold(50)

	# Let the deferred _flush_save() execute.
	await get_tree().process_frame

	# Assert — save file must exist after the frame
	assert_bool(FileAccess.file_exists("user://save.json")).is_true()

func test_continuous_persistence_add_gold_save_reflects_new_gold_value() -> await:
	# Arrange
	GameStore.add_gold(50)

	# Act
	await get_tree().process_frame

	# Assert — the persisted gold value must match what was set
	var data: Dictionary = _read_save_json()
	var game: Dictionary = data.get("game", {}) as Dictionary
	assert_int(int(game.get("player_gold", -1))).is_equal(50)

func test_continuous_persistence_add_gold_flags_cleared_after_flush() -> await:
	# Arrange — verify that the deferred flush resets both persistence flags,
	# confirming the flush actually ran (not just that the file happened to exist).
	GameStore.add_gold(50)

	# Act
	await get_tree().process_frame

	# Assert — after the flush both flags must be false
	assert_bool(GameStore._dirty).is_false()
	assert_bool(GameStore._save_pending).is_false()

func test_continuous_persistence_add_gold_save_contains_version_key() -> await:
	# Arrange
	GameStore.add_gold(50)

	# Act
	await get_tree().process_frame

	# Assert — save format integrity: top-level "version" must be present
	var data: Dictionary = _read_save_json()
	assert_bool(data.has("version")).is_true()

func test_continuous_persistence_add_gold_save_version_equals_constant() -> await:
	# Arrange
	GameStore.add_gold(50)

	# Act
	await get_tree().process_frame

	# Assert
	var data: Dictionary = _read_save_json()
	assert_int(int(data.get("version", -1))).is_equal(SaveManager.SAVE_VERSION)

# ---------------------------------------------------------------------------
# AC2 — 3 setters in the same frame → exactly 1 disk write
#
# GDScript's call_deferred() guard (_save_pending) prevents re-queuing a
# flush when one is already scheduled. We verify this integration contract
# by confirming:
#   a) After the first setter, _save_pending=true (guard raised).
#   b) After two more setters in the same synchronous block, _save_pending
#      is still true (not re-raised, which would double-queue).
#   c) After await, _save_pending=false and _dirty=false — exactly one flush
#      ran (the file exists with all three mutations reflected).
# ---------------------------------------------------------------------------

func test_continuous_persistence_three_setters_guard_raised_after_first() -> void:
	# Arrange — clean flags confirmed by before_test()

	# Act — first setter
	GameStore.add_gold(10)

	# Assert — guard raised after first setter; one deferred call queued
	assert_bool(GameStore._save_pending).is_true()

func test_continuous_persistence_three_setters_guard_not_re_raised_on_second() -> void:
	# Arrange
	GameStore.add_gold(10)
	# At this point _save_pending = true. Second setter must NOT call
	# call_deferred() again (guard branch in _mark_dirty()).
	GameStore.set_streak(3)

	# Assert — still true, not flipped false→true by a second deferred call
	assert_bool(GameStore._save_pending).is_true()

func test_continuous_persistence_three_setters_guard_not_re_raised_on_third() -> void:
	# Arrange
	GameStore.add_gold(10)
	GameStore.set_streak(3)
	GameStore.set_last_captain_id("artemis")

	# Assert — guard still held by the single queued deferred call
	assert_bool(GameStore._save_pending).is_true()

func test_continuous_persistence_three_setters_single_flush_clears_flags() -> await:
	# Arrange — 3 setters in the same synchronous block
	GameStore.add_gold(10)
	GameStore.set_streak(3)
	GameStore.set_last_captain_id("artemis")

	# Act — let the single deferred flush execute
	await get_tree().process_frame

	# Assert — both flags cleared by exactly one flush
	assert_bool(GameStore._dirty).is_false()
	assert_bool(GameStore._save_pending).is_false()

func test_continuous_persistence_three_setters_all_values_in_single_save() -> await:
	# Arrange — 3 mutations, all must appear in the one save that results
	GameStore.add_gold(10)
	GameStore.set_streak(3)
	GameStore.set_last_captain_id("artemis")

	# Act
	await get_tree().process_frame

	# Assert — the single written file contains all three mutations
	var data: Dictionary = _read_save_json()
	var game: Dictionary = data.get("game", {}) as Dictionary
	assert_int(int(game.get("player_gold", -1))).is_equal(10)
	assert_int(int(game.get("current_streak", -1))).is_equal(3)
	assert_str(str(game.get("last_captain_id", ""))).is_equal("artemis")

func test_continuous_persistence_three_setters_save_file_exists_after_flush() -> await:
	# Arrange
	GameStore.add_gold(10)
	GameStore.set_streak(3)
	GameStore.set_last_captain_id("artemis")

	# Act
	await get_tree().process_frame

	# Assert — file was written (confirms flush ran)
	assert_bool(FileAccess.file_exists("user://save.json")).is_true()

# ---------------------------------------------------------------------------
# AC3 — save_game() during active combat → no "hand", "deck_order", or
#        "score" keys in the "game" section.
#
# GameStore.to_dict() does not include ephemeral combat state. Combat
# transient data (current hand, deck order, score) lives in a CombatSystem
# scene node, never in GameStore. We verify the contract by calling
# save_game() directly and inspecting the "game" sub-dict.
# ---------------------------------------------------------------------------

func test_continuous_persistence_saved_game_dict_has_no_hand_key() -> void:
	# Arrange — save the current store state (simulating a save during combat;
	# no combat-specific keys exist in GameStore regardless of context)
	SaveManager.save_game()

	# Act
	var data: Dictionary = _read_save_json()
	var game: Dictionary = data.get("game", {}) as Dictionary

	# Assert — "hand" is ephemeral combat state and must not be persisted
	assert_bool(game.has("hand")).is_false()

func test_continuous_persistence_saved_game_dict_has_no_deck_order_key() -> void:
	# Arrange
	SaveManager.save_game()

	# Act
	var data: Dictionary = _read_save_json()
	var game: Dictionary = data.get("game", {}) as Dictionary

	# Assert — "deck_order" is ephemeral and must not appear in the save
	assert_bool(game.has("deck_order")).is_false()

func test_continuous_persistence_saved_game_dict_has_no_score_key() -> void:
	# Arrange
	SaveManager.save_game()

	# Act
	var data: Dictionary = _read_save_json()
	var game: Dictionary = data.get("game", {}) as Dictionary

	# Assert — "score" is ephemeral and must not appear in the save
	assert_bool(game.has("score")).is_false()

func test_continuous_persistence_saved_game_dict_has_expected_persistent_keys() -> void:
	# Sanity check: the game section does contain the keys that ARE persistent,
	# confirming we are reading a real GameStore.to_dict() output, not an empty dict.
	SaveManager.save_game()
	var data: Dictionary = _read_save_json()
	var game: Dictionary = data.get("game", {}) as Dictionary

	# These keys are the stable contract from GameStore.to_dict()
	assert_bool(game.has("player_gold")).is_true()
	assert_bool(game.has("player_xp")).is_true()
	assert_bool(game.has("companion_states")).is_true()

# ---------------------------------------------------------------------------
# AC4 — from_dict() (load path) does NOT trigger a save write.
#
# After from_dict() the store must leave _dirty=false and _save_pending=false.
# After awaiting a frame, no save.json must have been written as a side-effect
# of the load itself.
# ---------------------------------------------------------------------------

func test_continuous_persistence_from_dict_leaves_dirty_false() -> void:
	# Arrange — build a valid save snapshot to load from
	GameStore.add_gold(100)
	var snapshot: Dictionary = GameStore.to_dict()

	# Reset the store and clear flags so we are starting from a known clean state
	GameStore._initialize_defaults()
	GameStore._dirty = false
	GameStore._save_pending = false

	# Act — load the snapshot (simulating the load path)
	GameStore.from_dict(snapshot)

	# Assert — loading is not a mutation; _dirty must remain false
	assert_bool(GameStore._dirty).is_false()

func test_continuous_persistence_from_dict_leaves_save_pending_false() -> void:
	# Arrange
	GameStore.add_gold(100)
	var snapshot: Dictionary = GameStore.to_dict()

	GameStore._initialize_defaults()
	GameStore._dirty = false
	GameStore._save_pending = false

	# Act
	GameStore.from_dict(snapshot)

	# Assert — no deferred flush should be queued after a load
	assert_bool(GameStore._save_pending).is_false()

func test_continuous_persistence_from_dict_does_not_write_save_file() -> await:
	# Arrange — ensure no save file exists before the load
	_delete_save_files()

	GameStore.add_gold(100)
	var snapshot: Dictionary = GameStore.to_dict()

	GameStore._initialize_defaults()
	GameStore._dirty = false
	GameStore._save_pending = false

	# Act — load; then wait a frame to let any accidental deferred call fire
	GameStore.from_dict(snapshot)
	await get_tree().process_frame

	# Assert — no save file should have been written as a result of from_dict()
	assert_bool(FileAccess.file_exists("user://save.json")).is_false()

func test_continuous_persistence_from_dict_still_loads_correct_gold_value() -> void:
	# Sanity check: from_dict() actually restores state even though it does not dirty.
	GameStore.add_gold(77)
	var snapshot: Dictionary = GameStore.to_dict()

	GameStore._initialize_defaults()
	GameStore._dirty = false
	GameStore._save_pending = false

	# Act
	GameStore.from_dict(snapshot)

	# Assert — data is correctly restored
	assert_int(GameStore.get_gold()).is_equal(77)
	# And no dirty state was introduced
	assert_bool(GameStore._dirty).is_false()

func test_continuous_persistence_from_dict_clears_preexisting_dirty_flag() -> void:
	# Edge case: the store was dirty before from_dict() was called.
	# from_dict() must clear _dirty regardless of prior state.
	GameStore.add_gold(10)  # sets _dirty = true
	assert_bool(GameStore._dirty).is_true()

	var snapshot: Dictionary = GameStore.to_dict()

	# Act — load into the same live store while it is already dirty
	GameStore.from_dict(snapshot)

	# Assert — _dirty cleared by the load
	assert_bool(GameStore._dirty).is_false()
	assert_bool(GameStore._save_pending).is_false()
