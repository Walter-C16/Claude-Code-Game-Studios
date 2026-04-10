class_name DeleteSaveTest
extends GdUnitTestSuite

# Unit tests for STORY SS-005: Delete Save + New Game Confirmation Guard
#
# Covers all unit-testable Acceptance Criteria:
#   AC1 — Save file exists → delete_save() → has_save() returns false
#   AC2 — delete_save() resets GameStore and SettingsStore to defaults
#   AC3 — No save file → delete_save() completes without error (idempotent)
#   AC4 — Splash UI shows confirmation dialog (integration scope — manual verification)
#
# Notes:
#   Tests run headless with all autoloads active. GameStore and SettingsStore
#   are live singletons. After each test, stores are reset to avoid leaking
#   state mutations into subsequent tests.
#
# See: docs/architecture/adr-0002-save-system.md

# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

func before_test() -> void:
	_delete_save_files()
	# Reset both stores to defaults before each test.
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
# AC1 — Save file exists → delete_save() → has_save() returns false
# ---------------------------------------------------------------------------

func test_delete_save_has_save_returns_false_after_delete() -> void:
	# Arrange — write a real save file first
	SaveManager.save_game()
	assert_bool(SaveManager.has_save()).is_true()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_bool(SaveManager.has_save()).is_false()

func test_delete_save_save_json_file_does_not_exist_after_delete() -> void:
	# Arrange
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_bool(FileAccess.file_exists("user://save.json")).is_false()

func test_delete_save_also_removes_tmp_file_if_present() -> void:
	# Arrange — create a lingering .tmp file (simulates a mid-write crash)
	var file := FileAccess.open("user://save.json.tmp", FileAccess.WRITE)
	if file:
		file.store_string("{}")
		file.close()
	assert_bool(FileAccess.file_exists("user://save.json.tmp")).is_true()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_bool(FileAccess.file_exists("user://save.json.tmp")).is_false()

# ---------------------------------------------------------------------------
# AC2 — delete_save() resets GameStore and SettingsStore to defaults
# ---------------------------------------------------------------------------

func test_delete_save_resets_game_store_gold_to_zero() -> void:
	# Arrange — mutate GameStore state, save, then delete
	GameStore.add_gold(500)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert — GameStore back to factory defaults
	assert_int(GameStore.get_gold()).is_equal(0)

func test_delete_save_resets_game_store_xp_to_zero() -> void:
	# Arrange
	GameStore.add_xp(999)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_int(GameStore.get_xp()).is_equal(0)

func test_delete_save_resets_game_store_daily_tokens_to_three() -> void:
	# Arrange — spend all tokens
	GameStore.spend_token()
	GameStore.spend_token()
	GameStore.spend_token()
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert — default token pool is 3
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

func test_delete_save_resets_game_store_streak_to_zero() -> void:
	# Arrange
	GameStore.set_streak(14)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_int(GameStore.get_streak()).is_equal(0)

func test_delete_save_resets_game_store_story_flags_to_empty() -> void:
	# Arrange
	GameStore.set_flag("ch01_met_artemis")
	GameStore.set_flag("ch02_boss_defeated")
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_int(GameStore.get_story_flags().size()).is_equal(0)

func test_delete_save_resets_game_store_last_captain_id_to_empty() -> void:
	# Arrange
	GameStore.set_last_captain_id("hipolita")
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_str(GameStore.get_last_captain_id()).is_equal("")

func test_delete_save_resets_game_store_combat_buff_to_empty() -> void:
	# Arrange
	GameStore.set_combat_buff({"chips": 100, "mult": 2.0, "combats_remaining": 3})
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_bool(GameStore.get_combat_buff().is_empty()).is_true()

func test_delete_save_resets_settings_store_locale_to_en() -> void:
	# Arrange — change locale then delete
	SettingsStore.set_locale("es")
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert — default locale is "en"
	assert_str(SettingsStore.get_locale()).is_equal("en")

func test_delete_save_resets_settings_store_master_volume_to_one() -> void:
	# Arrange
	SettingsStore.set_master_volume(0.3)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_float(SettingsStore.get_master_volume()).is_equal(1.0)

func test_delete_save_resets_settings_store_sfx_volume_to_one() -> void:
	# Arrange
	SettingsStore.set_sfx_volume(0.5)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_float(SettingsStore.get_sfx_volume()).is_equal(1.0)

func test_delete_save_resets_settings_store_music_volume_to_one() -> void:
	# Arrange
	SettingsStore.set_music_volume(0.2)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_float(SettingsStore.get_music_volume()).is_equal(1.0)

func test_delete_save_resets_settings_store_text_speed_to_one() -> void:
	# Arrange
	SettingsStore.set_text_speed(2.5)
	SaveManager.save_game()

	# Act
	SaveManager.delete_save()

	# Assert
	assert_float(SettingsStore.get_text_speed()).is_equal(1.0)

# ---------------------------------------------------------------------------
# AC3 — No save file → delete_save() completes without error (idempotent)
# ---------------------------------------------------------------------------

func test_delete_save_idempotent_no_file_does_not_crash() -> void:
	# Arrange — before_test() already removed all save files
	assert_bool(SaveManager.has_save()).is_false()

	# Act — must not throw or produce an error
	SaveManager.delete_save()

	# Assert — still no save file, no exception
	assert_bool(SaveManager.has_save()).is_false()

func test_delete_save_idempotent_called_twice_does_not_crash() -> void:
	# Arrange — create then delete once
	SaveManager.save_game()
	SaveManager.delete_save()
	assert_bool(SaveManager.has_save()).is_false()

	# Act — second delete on already-absent file
	SaveManager.delete_save()

	# Assert — still absent, no error
	assert_bool(SaveManager.has_save()).is_false()

func test_delete_save_idempotent_game_store_still_at_defaults_when_no_file() -> void:
	# Arrange — no save file, store already at defaults (from before_test)

	# Act
	SaveManager.delete_save()

	# Assert — defaults are preserved even when there was nothing to delete
	assert_int(GameStore.get_gold()).is_equal(0)
	assert_int(GameStore.get_xp()).is_equal(0)
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

# ---------------------------------------------------------------------------
# AC4 — Splash UI confirmation dialog (integration / manual scope)
#
# This AC requires a UI node to display a ConfirmationDialog before invoking
# delete_save(). It cannot be automated as a pure unit test because it depends
# on a running scene with a Control node hierarchy. Manual verification steps:
#
#   1. Launch the game to the Splash screen.
#   2. Trigger the "Delete Save" action from the Settings screen.
#   3. Confirm that a modal dialog appears asking for confirmation.
#   4. Press "Cancel" — verify that has_save() is still true.
#   5. Press "Confirm" — verify that has_save() is false and game state resets.
#
# Evidence location: production/qa/evidence/ss-005-delete-confirmation.png
# ---------------------------------------------------------------------------
