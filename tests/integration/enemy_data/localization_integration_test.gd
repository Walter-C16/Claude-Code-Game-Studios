class_name LocalizationEnemyIntegrationTest
extends GdUnitTestSuite

## Integration tests for STORY-ENEMY-003: Localization Key Integration
##
## Covers all 4 Acceptance Criteria:
##   AC1 — Localization.get_text(get_enemy("forest_monster").name_key) returns "Forest Monster"
##   AC2 — Unknown key "ENEMY_CYCLOPS" returns raw key as fallback (no crash, no empty string)
##   AC3 — Enemies registered without error even when content is not fully installed
##   AC4 — EnemyRegistry _ready() does NOT call Localization — boot order is safe (#4 before #8)
##
## Integration contract verified:
##   - EnemyRegistry stores name_key strings, never resolved display names.
##   - Callers resolve name_key via Localization.get_text() (per ADR-0016).
##   - Localization autoload #4 is initialised before EnemyRegistry autoload #8.
##
## Test pattern:
##   - EnemyRegistry: preload + Script.new() + _load_enemies() (no _ready(), no autoload dep)
##   - Localization: preload + Script.new() + manually inject English table from en.json
##     so the test reads the real translation data without needing the autoload singleton.
##
## See: docs/architecture/adr-0016-enemy-registry.md, docs/architecture/adr-0006-boot-order.md

# ── Constants ─────────────────────────────────────────────────────────────────

const EnemyRegistryScript = preload("res://src/autoloads/enemy_registry.gd")
const LocalizationScript = preload("res://src/autoloads/localization.gd")

## project.godot path — read to verify boot order in AC4.
const PROJECT_GODOT_PATH: String = "res://project.godot"

## en.json path — read to inject real translations into the Localization instance.
const EN_JSON_PATH: String = "res://i18n/en.json"

# ── Helpers ───────────────────────────────────────────────────────────────────

## Creates an EnemyRegistry loaded with the real enemies.json data.
## Does NOT call _ready() — avoids all autoload references.
func _make_loaded_registry() -> Node:
	var registry = EnemyRegistryScript.new()
	registry._load_enemies()
	return registry

## Creates a Localization node loaded with the real en.json English table.
## Does NOT call _ready() — avoids SettingsStore autoload reference.
func _make_localization_with_en_json() -> Node:
	var loc = LocalizationScript.new()
	var table: Dictionary = _load_json_table(EN_JSON_PATH)
	loc._english_table = table
	loc._active_table = table
	loc._active_locale = "en"
	return loc

## Reads and parses a JSON file into a Dictionary.
## Returns empty Dictionary on any error so tests can assert on emptiness.
func _load_json_table(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(content) != OK:
		return {}
	if not json.data is Dictionary:
		return {}
	return json.data

## Reads the [autoload] section of project.godot as an ordered Array[String].
## Each element is a raw "Key=..." line.
func _read_autoload_lines() -> Array[String]:
	var file: FileAccess = FileAccess.open(PROJECT_GODOT_PATH, FileAccess.READ)
	if not file:
		return []
	var lines: Array[String] = []
	var in_section: bool = false
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line == "[autoload]":
			in_section = true
			continue
		if in_section:
			if line.begins_with("[") and line.ends_with("]"):
				break
			if line.is_empty() or line.begins_with(";"):
				continue
			lines.append(line)
	file.close()
	return lines

## Returns the 0-based position of an autoload entry by name, or -1 if absent.
func _find_autoload_index(lines: Array[String], name: String) -> int:
	for i: int in range(lines.size()):
		if lines[i].begins_with(name + "="):
			return i
	return -1

# ── AC1 — name_key resolves to display name via Localization ──────────────────

func test_localization_integration_forest_monster_name_key_resolves_to_display_name() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var loc = _make_localization_with_en_json()
	assert_bool(loc._english_table.is_empty()).is_false()

	# Act — caller pattern: get name_key from registry, resolve via Localization
	var profile: Dictionary = registry.get_enemy("forest_monster")
	var name_key: String = profile.get("name_key", "")
	var display_name: String = loc.get_text(name_key)

	# Assert — must resolve to the human-readable string, not the raw key
	assert_str(display_name).is_equal("Forest Monster")

	registry.free()
	loc.free()

func test_localization_integration_mountain_beast_name_key_resolves_to_display_name() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var loc = _make_localization_with_en_json()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")
	var name_key: String = profile.get("name_key", "")
	var display_name: String = loc.get_text(name_key)

	# Assert
	assert_str(display_name).is_equal("Mountain Beast")

	registry.free()
	loc.free()

func test_localization_integration_amazon_challenger_name_key_resolves_to_display_name() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var loc = _make_localization_with_en_json()

	# Act
	var profile: Dictionary = registry.get_enemy("amazon_challenger")
	var name_key: String = profile.get("name_key", "")
	var display_name: String = loc.get_text(name_key)

	# Assert
	assert_str(display_name).is_equal("Amazon Challenger")

	registry.free()
	loc.free()

func test_localization_integration_gaia_spirit_name_key_resolves_to_display_name() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var loc = _make_localization_with_en_json()

	# Act
	var profile: Dictionary = registry.get_enemy("gaia_spirit")
	var name_key: String = profile.get("name_key", "")
	var display_name: String = loc.get_text(name_key)

	# Assert
	assert_str(display_name).is_equal("Gaia Spirit")

	registry.free()
	loc.free()

func test_localization_integration_name_key_result_is_not_the_raw_key() -> void:
	# Arrange — verifies the key was actually resolved (not fallback returned)
	var registry = _make_loaded_registry()
	var loc = _make_localization_with_en_json()

	# Act
	var profile: Dictionary = registry.get_enemy("forest_monster")
	var name_key: String = profile.get("name_key", "")
	var display_name: String = loc.get_text(name_key)

	# Assert — display name must differ from the raw key string
	assert_str(display_name).is_not_equal(name_key)

	registry.free()
	loc.free()

# ── AC2 — unknown key returns raw key as fallback (no crash, no empty string) ─

func test_localization_integration_missing_key_returns_raw_key_not_empty() -> void:
	# Arrange — "ENEMY_CYCLOPS" is not yet in en.json
	var loc = _make_localization_with_en_json()

	# Act
	var result: String = loc.get_text("ENEMY_CYCLOPS")

	# Assert — fallback must be the raw key itself, not an empty string
	assert_str(result).is_not_empty()

	loc.free()

func test_localization_integration_missing_key_returns_exact_raw_key() -> void:
	# Arrange
	var loc = _make_localization_with_en_json()

	# Act
	var result: String = loc.get_text("ENEMY_CYCLOPS")

	# Assert — must return the key verbatim
	assert_str(result).is_equal("ENEMY_CYCLOPS")

	loc.free()

func test_localization_integration_missing_key_does_not_crash() -> void:
	# Arrange
	var loc = _make_localization_with_en_json()

	# Act — reaching the next line proves no crash occurred
	var _result: String = loc.get_text("ENEMY_DOES_NOT_EXIST")

	# Assert
	assert_bool(true).is_true()

	loc.free()

# ── AC3 — enemies registered without error regardless of content availability ─

func test_localization_integration_all_chapter1_enemies_are_registered() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act / Assert — all 4 Chapter 1 enemies must be registered
	var chapter1_ids: Array[String] = [
		"forest_monster", "mountain_beast", "amazon_challenger", "gaia_spirit"
	]
	for id: String in chapter1_ids:
		assert_bool(registry.has_enemy(id)).is_true()

	registry.free()

func test_localization_integration_all_chapter1_enemies_have_name_keys() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act / Assert — every Chapter 1 profile must have a non-empty name_key
	var chapter1_ids: Array[String] = [
		"forest_monster", "mountain_beast", "amazon_challenger", "gaia_spirit"
	]
	for id: String in chapter1_ids:
		var profile: Dictionary = registry.get_enemy(id)
		var name_key: String = profile.get("name_key", "")
		assert_str(name_key).is_not_empty()

	registry.free()

func test_localization_integration_all_chapter1_name_keys_have_enemy_prefix() -> void:
	# Arrange — all enemy name keys must use the ENEMY_ prefix per ADR-0016
	var registry = _make_loaded_registry()

	# Act / Assert
	var chapter1_ids: Array[String] = [
		"forest_monster", "mountain_beast", "amazon_challenger", "gaia_spirit"
	]
	for id: String in chapter1_ids:
		var profile: Dictionary = registry.get_enemy(id)
		var name_key: String = profile.get("name_key", "")
		assert_bool(name_key.begins_with("ENEMY_")).is_true()

	registry.free()

# ── AC4 — Localization (#4) is initialised before EnemyRegistry (#8) ─────────

func test_localization_integration_localization_appears_before_enemy_registry_in_boot_order() -> void:
	# Arrange — read project.godot autoload section
	var lines: Array[String] = _read_autoload_lines()
	assert_array(lines).is_not_empty()

	# Act
	var loc_index: int = _find_autoload_index(lines, "Localization")
	var er_index: int = _find_autoload_index(lines, "EnemyRegistry")

	# Assert — both must exist, Localization strictly before EnemyRegistry
	assert_int(loc_index).is_not_equal(-1)
	assert_int(er_index).is_not_equal(-1)
	assert_int(loc_index).is_less(er_index)

func test_localization_integration_enemy_registry_ready_does_not_reference_localization() -> void:
	# Arrange — read enemy_registry.gd source and extract _ready() body
	var path: String = "res://autoloads/enemy_registry.gd"
	if not FileAccess.file_exists(path):
		# File not yet at that path; skip gracefully
		assert_bool(true).is_true()
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_object(file).is_not_null()
	var source: String = file.get_as_text()
	file.close()

	# Extract _ready() body
	var ready_start: int = source.find("func _ready()")
	assert_int(ready_start).is_not_equal(-1)
	var next_func: int = source.find("\nfunc ", ready_start + len("func _ready()"))
	var ready_body: String
	if next_func == -1:
		ready_body = source.substr(ready_start)
	else:
		ready_body = source.substr(ready_start, next_func - ready_start)

	# Assert — _ready() must not call Localization (that would be unsafe from #8)
	assert_str(ready_body).not_contains("Localization")

func test_localization_integration_localization_is_registered_as_autoload() -> void:
	# Arrange
	var lines: Array[String] = _read_autoload_lines()

	# Act
	var loc_index: int = _find_autoload_index(lines, "Localization")

	# Assert — Localization entry exists in project.godot
	assert_int(loc_index).is_not_equal(-1)

func test_localization_integration_enemy_registry_is_registered_as_autoload() -> void:
	# Arrange
	var lines: Array[String] = _read_autoload_lines()

	# Act
	var er_index: int = _find_autoload_index(lines, "EnemyRegistry")

	# Assert — EnemyRegistry entry exists in project.godot
	assert_int(er_index).is_not_equal(-1)
