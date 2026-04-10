class_name BootOrderTest
extends GdUnitTestSuite

const GameStoreScript = preload("res://autoloads/game_store.gd")

# Integration tests for STORY-GS-006: GameStore + SettingsStore Boot Order Wiring
#
# Covers:
#   AC1 — project.godot autoload order: GameStore < SettingsStore < EventBus
#   AC3 — GameStore._ready() references no other autoload by name
#   AC4 — SettingsStore._ready() references no other autoload by name
#   AC5 — GameStore.state_changed signal is connectable by external callers
#
# AC2 (no "autoload not ready" errors on fresh launch) is a manual playtest
# criterion verified during QA, not automatable headlessly.
#
# See: docs/architecture/adr-0006-boot-order.md

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Path to the Godot project configuration file (res:// = src/).
const PROJECT_GODOT_PATH: String = "res://project.godot"

## Known autoload names that must NOT appear in _ready() of GameStore or
## SettingsStore. Covers all autoloads defined in ADR-0006.
const KNOWN_AUTOLOADS: Array[String] = [
	"SettingsStore",
	"EventBus",
	"Localization",
	"SaveManager",
	"SceneManager",
	"CompanionRegistry",
	"EnemyRegistry",
	"DialogueRunner",
	"RomanceSocial",
	"StoryFlow",
	# GameStore itself is also listed for SettingsStore's check
	"GameStore",
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Reads project.godot and returns the lines of the [autoload] section as an
## ordered Array[String]. Returns an empty array if the section is absent.
func _read_autoload_section() -> Array[String]:
	var file := FileAccess.open(PROJECT_GODOT_PATH, FileAccess.READ)
	assert_object(file).is_not_null()

	var lines: Array[String] = []
	var in_section: bool = false

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line == "[autoload]":
			in_section = true
			continue
		if in_section:
			# A new [section] header ends the autoload block
			if line.begins_with("[") and line.ends_with("]"):
				break
			# Skip blank lines and comments
			if line.is_empty() or line.begins_with(";"):
				continue
			lines.append(line)

	file.close()
	return lines

## Returns the index of the first autoload line whose key matches `name`.
## Returns -1 if not found.
func _find_autoload_index(lines: Array[String], name: String) -> int:
	for i: int in range(lines.size()):
		# Line format: KeyName="*res://..."  or  KeyName="res://..."
		if lines[i].begins_with(name + "="):
			return i
	return -1

## Reads a GDScript source file and extracts the lines belonging to _ready().
## Returns the raw content of the body between func _ready() and the next func
## declaration (or end of file). Returns an empty String if not found.
func _read_ready_body(script_path: String) -> String:
	var file := FileAccess.open(script_path, FileAccess.READ)
	assert_object(file).is_not_null()

	var full_source: String = file.get_as_text()
	file.close()

	# Find the _ready() function
	var ready_start: int = full_source.find("func _ready()")
	if ready_start == -1:
		return ""

	# Find the next top-level func declaration after _ready
	var search_from: int = ready_start + len("func _ready()")
	var next_func: int = full_source.find("\nfunc ", search_from)

	if next_func == -1:
		return full_source.substr(ready_start)
	return full_source.substr(ready_start, next_func - ready_start)

# ---------------------------------------------------------------------------
# AC1 — Autoload order in project.godot
# ---------------------------------------------------------------------------

func test_boot_order_game_store_appears_before_settings_store() -> void:
	# Arrange
	var lines := _read_autoload_section()

	# Act
	var gs_index: int = _find_autoload_index(lines, "GameStore")
	var ss_index: int = _find_autoload_index(lines, "SettingsStore")

	# Assert — both must be present and GameStore must come first
	assert_int(gs_index).is_not_equal(-1)
	assert_int(ss_index).is_not_equal(-1)
	assert_int(gs_index).is_less(ss_index)

func test_boot_order_settings_store_appears_before_event_bus() -> void:
	# Arrange
	var lines := _read_autoload_section()

	# Act
	var ss_index: int = _find_autoload_index(lines, "SettingsStore")
	var eb_index: int = _find_autoload_index(lines, "EventBus")

	# Assert — both must be present and SettingsStore must come first
	assert_int(ss_index).is_not_equal(-1)
	assert_int(eb_index).is_not_equal(-1)
	assert_int(ss_index).is_less(eb_index)

func test_boot_order_game_store_appears_before_event_bus() -> void:
	# Arrange
	var lines := _read_autoload_section()

	# Act
	var gs_index: int = _find_autoload_index(lines, "GameStore")
	var eb_index: int = _find_autoload_index(lines, "EventBus")

	# Assert
	assert_int(gs_index).is_not_equal(-1)
	assert_int(eb_index).is_not_equal(-1)
	assert_int(gs_index).is_less(eb_index)

# ---------------------------------------------------------------------------
# AC3 — GameStore._ready() references no other autoload by name
# ---------------------------------------------------------------------------

func test_boot_order_game_store_ready_does_not_reference_settings_store() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/game_store.gd")

	# Act / Assert — SettingsStore must not appear in GameStore._ready()
	assert_str(ready_body).not_contains("SettingsStore")

func test_boot_order_game_store_ready_does_not_reference_event_bus() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/game_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("EventBus")

func test_boot_order_game_store_ready_does_not_reference_save_manager() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/game_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("SaveManager")

func test_boot_order_game_store_ready_does_not_reference_scene_manager() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/game_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("SceneManager")

func test_boot_order_game_store_ready_does_not_reference_localization() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/game_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("Localization")

# ---------------------------------------------------------------------------
# AC4 — SettingsStore._ready() references no other autoload by name
# ---------------------------------------------------------------------------

func test_boot_order_settings_store_ready_does_not_reference_game_store() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/settings_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("GameStore")

func test_boot_order_settings_store_ready_does_not_reference_event_bus() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/settings_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("EventBus")

func test_boot_order_settings_store_ready_does_not_reference_save_manager() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/settings_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("SaveManager")

func test_boot_order_settings_store_ready_does_not_reference_scene_manager() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/settings_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("SceneManager")

func test_boot_order_settings_store_ready_does_not_reference_localization() -> void:
	# Arrange
	var ready_body: String = _read_ready_body("res://autoloads/settings_store.gd")

	# Act / Assert
	assert_str(ready_body).not_contains("Localization")

# ---------------------------------------------------------------------------
# AC5 — GameStore.state_changed signal is connectable
# ---------------------------------------------------------------------------

## Verifies that GameStore.state_changed exists as a declared signal and that
## an external caller can connect to it without error.
func test_boot_order_game_store_state_changed_signal_exists() -> void:
	# Arrange
	var store = GameStoreScript.new()
	add_child(store)

	# Act — verify signal is in the signal list
	var signal_names: Array[String] = []
	for sig: Dictionary in store.get_signal_list():
		signal_names.append(sig.get("name", ""))

	# Assert
	assert_bool(signal_names.has("state_changed")).is_true()

	# Cleanup
	store.queue_free()

func test_boot_order_game_store_state_changed_is_connectable() -> void:
	# Arrange — simulate a "later autoload" connecting after GameStore loaded
	var store = GameStoreScript.new()
	add_child(store)

	var received_keys: Array[String] = []
	var callable := func(key: String) -> void:
		received_keys.append(key)

	# Act — connect and trigger
	store.state_changed.connect(callable)
	store.add_gold(10)

	# Assert — signal was received with correct key
	assert_int(received_keys.size()).is_equal(1)
	assert_str(received_keys[0]).is_equal("gold")

	# Cleanup
	store.state_changed.disconnect(callable)
	store.queue_free()

func test_boot_order_game_store_state_changed_signal_has_key_parameter() -> void:
	# Arrange — verify the signal has exactly one String parameter named "key"
	var store = GameStoreScript.new()
	add_child(store)

	# Act
	var signal_info: Dictionary = {}
	for sig: Dictionary in store.get_signal_list():
		if sig.get("name", "") == "state_changed":
			signal_info = sig
			break

	# Assert — signal found and has one argument
	assert_bool(signal_info.is_empty()).is_false()
	var args: Array = signal_info.get("args", [])
	assert_int(args.size()).is_equal(1)
	assert_str(args[0].get("name", "")).is_equal("key")

	# Cleanup
	store.queue_free()
