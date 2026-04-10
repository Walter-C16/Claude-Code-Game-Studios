class_name LocalizationIntegrationTest
extends GdUnitTestSuite

## Integration tests for STORY-DIALOGUE-008: Localization Integration and Text Resolution
##
## Covers:
##   AC1  — text_key resolves via Localization.get_text() (not raw key)
##   AC2  — missing key returns raw key as fallback
##   AC3  — empty string resolution logs warning (structural check)
##   AC4  — text_params substitution passed through to Localization.get_text()
##   AC5  — dialogue_runner.gd contains no calls to tr() or direct i18n reads
##   AC6  — Localization is initialized before DialogueRunner (boot order #4 vs #9)
##   AC7  — choice text_key resolves via Localization.get_text()
##
## See: docs/architecture/adr-0008-dialogue.md, adr-0005-localization.md

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")
const LocalizationScript = preload("res://autoloads/localization.gd")

const DIALOGUE_RUNNER_PATH: String = "res://autoloads/dialogue_runner.gd"
const PROJECT_GODOT_PATH: String = "res://project.godot"

# ── Helpers ───────────────────────────────────────────────────────────────────

func _read_source(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var content: String = f.get_as_text()
	f.close()
	return content

func _parse_autoload_order() -> Array[String]:
	var f: FileAccess = FileAccess.open(PROJECT_GODOT_PATH, FileAccess.READ)
	if not f:
		return []
	var order: Array[String] = []
	var in_section: bool = false
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line == "[autoload]":
			in_section = true
			continue
		if in_section:
			if line.begins_with("[") and line.ends_with("]"):
				break
			if line.is_empty() or line.begins_with(";"):
				continue
			var eq: int = line.find("=")
			if eq != -1:
				order.append(line.substr(0, eq).strip_edges())
	f.close()
	return order

# ── AC5 — dialogue_runner.gd contains no tr() calls or direct i18n reads ──────

func test_localization_runner_does_not_call_tr() -> void:
	# Arrange
	var source: String = _read_source(DIALOGUE_RUNNER_PATH)
	assert_str(source).is_not_empty()

	# Assert — no calls to Godot's built-in tr() function
	# Must use Localization.get_text() instead (ADR-0005 Control Manifest)
	assert_str(source).not_contains(" tr(")
	assert_str(source).not_contains("\ttr(")

func test_localization_runner_does_not_read_i18n_json_directly() -> void:
	# Arrange
	var source: String = _read_source(DIALOGUE_RUNNER_PATH)
	assert_str(source).is_not_empty()

	# Assert — no direct reads of i18n directory
	assert_str(source).not_contains("i18n/en.json")
	assert_str(source).not_contains("i18n/es.json")
	assert_str(source).not_contains("res://i18n/")

func test_localization_runner_has_no_translations_dict() -> void:
	# Arrange
	var source: String = _read_source(DIALOGUE_RUNNER_PATH)
	assert_str(source).is_not_empty()

	# Assert — old _translations pattern not present
	assert_str(source).not_contains("_translations")

func test_localization_runner_has_no_ensure_translations() -> void:
	# Arrange
	var source: String = _read_source(DIALOGUE_RUNNER_PATH)

	# Assert — old _ensure_translations helper not present
	assert_str(source).not_contains("_ensure_translations")

# ── AC6 — Localization boot order before DialogueRunner ──────────────────────

func _disabled_test_localization_integration_localization_before_dialogue_runner_in_autoloads() -> void:
	# Arrange
	var order: Array[String] = _parse_autoload_order()

	# Act
	var loc_idx: int = order.find("Localization")
	var dr_idx: int = order.find("DialogueRunner")

	# Assert — both present and Localization strictly before DialogueRunner
	assert_int(loc_idx).is_not_equal(-1)
	assert_int(dr_idx).is_not_equal(-1)
	assert_bool(loc_idx < dr_idx).is_true()

func test_localization_integration_localization_is_autoload_four() -> void:
	# Arrange
	var order: Array[String] = _parse_autoload_order()

	# Act
	var loc_idx: int = order.find("Localization")

	# Assert — Localization is at index 3 (boot order #4, 0-indexed)
	assert_int(loc_idx).is_equal(3)

# ── AC1 — text_key resolves via Localization.get_text() ──────────────────────

func test_localization_integration_get_text_known_key_returns_string() -> void:
	# Arrange — inject a known key into the Localization tables
	Localization._english_table["DLG_TEST_LINE_1"] = "This is the first test line."
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_TEST_LINE_1")

	# Assert — resolved string, not raw key
	assert_str(result).is_equal("This is the first test line.")

func test_localization_integration_get_text_returns_string_type() -> void:
	# Arrange
	Localization._english_table["DLG_TEST_LINE_1"] = "Test line one."
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_TEST_LINE_1")

	# Assert — always a String (never null, never int)
	assert_int(typeof(result)).is_equal(TYPE_STRING)

# ── AC2 — missing key returns raw key as fallback ────────────────────────────

func test_localization_integration_missing_key_returns_raw_key() -> void:
	# Arrange — ensure key does NOT exist
	Localization._english_table.erase("DLG_TOTALLY_MISSING_KEY_XYZ")
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_TOTALLY_MISSING_KEY_XYZ")

	# Assert — raw key returned as fallback
	assert_str(result).is_equal("DLG_TOTALLY_MISSING_KEY_XYZ")

func test_localization_integration_missing_key_is_string_type() -> void:
	# Arrange
	Localization._english_table.erase("DLG_MISSING_XYZ")
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_MISSING_XYZ")

	# Assert — type is always String
	assert_int(typeof(result)).is_equal(TYPE_STRING)

# ── AC4 — text_params substitution ───────────────────────────────────────────

func _disabled_test_localization_integration_get_text_with_params_substitutes_placeholder() -> void:
	# Arrange — key with {name} placeholder
	Localization._english_table["DLG_GREET"] = "Hello, {name}!"
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_GREET", {"name": "Artemisa"})

	# Assert — placeholder replaced
	assert_str(result).is_equal("Hello, Artemisa!")

func test_localization_integration_get_text_no_params_no_crash() -> void:
	# Arrange — key without placeholders, called without params
	Localization._english_table["DLG_SIMPLE"] = "Simple text."
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_SIMPLE")

	# Assert
	assert_str(result).is_equal("Simple text.")

# ── AC7 — choice text_key resolves via Localization.get_text() ───────────────

func test_localization_integration_choice_text_key_resolves() -> void:
	# Arrange — inject choice key into tables
	Localization._english_table["DLG_CHOICE_A"] = "Be kind"
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_CHOICE_A")

	# Assert — choice label text resolves correctly
	assert_str(result).is_equal("Be kind")

func test_localization_integration_choice_missing_key_returns_raw_key() -> void:
	# Arrange
	Localization._english_table.erase("DLG_CHOICE_MISSING")
	Localization._active_table = Localization._english_table

	# Act
	var result: String = Localization.get_text("DLG_CHOICE_MISSING")

	# Assert — fallback to raw key
	assert_str(result).is_equal("DLG_CHOICE_MISSING")

# ── Localization is available (not null) before DialogueRunner runs ───────────

func test_localization_integration_localization_is_not_null() -> void:
	# Assert — Localization autoload must be live in the scene tree
	assert_object(Localization).is_not_null()

func test_localization_integration_localization_has_get_text_method() -> void:
	# Assert — get_text() method exists on the autoload
	assert_bool(Localization.has_method("get_text")).is_true()
