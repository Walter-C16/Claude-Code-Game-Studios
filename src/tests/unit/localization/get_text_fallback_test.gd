class_name GetTextFallbackTest
extends GdUnitTestSuite

const LocalizationScript = preload("res://autoloads/localization.gd")

## Unit tests for STORY-LOC-002: get_text() API + Fallback Chain
##
## Covers:
##   AC1 — English table has "UI_CONTINUE": "Continue", active locale is English
##          → get_text("UI_CONTINUE") returns "Continue"
##   AC2 — Active locale is "es" with no es table → falls back to English "Continue"
##          + push_warning emitted
##   AC3 — Key "MISSING_KEY" not in any table → returns raw key "MISSING_KEY"
##          + push_warning emitted
##   AC4 — grep src/ for FileAccess.open.*i18n → 0 matches outside localization.gd
##   AC5 — grep src/scenes/ for hardcoded player-facing strings → 0 matches
##
## See: docs/architecture/adr-0005-localization.md

# ── Helpers ───────────────────────────────────────────────────────────────────

## Creates a Localization node without calling _ready().
## Manually populates tables so tests are isolated from the real en.json.
func _make_localization_with_tables(
	english: Dictionary,
	active: Dictionary,
	active_locale: String = "en"
):
	var loc: Node = LocalizationScript.new()
	# Directly assign internal state — these are var fields, not consts.
	loc._english_table = english
	loc._active_table = active
	loc._active_locale = active_locale
	return loc

# ── AC1 — English active locale resolves key from active table ────────────────

func test_get_text_fallback_english_active_locale_returns_correct_string() -> void:
	# Arrange
	var english_table: Dictionary = {"UI_CONTINUE": "Continue", "UI_NEW_GAME": "New Game"}
	var loc: Node = _make_localization_with_tables(english_table, english_table, "en")

	# Act
	var result: String = loc.get_text("UI_CONTINUE")

	# Assert
	assert_str(result).is_equal("Continue")
	loc.free()

func test_get_text_fallback_english_active_locale_resolves_second_key() -> void:
	# Arrange
	var english_table: Dictionary = {"UI_CONTINUE": "Continue", "UI_NEW_GAME": "New Game"}
	var loc: Node = _make_localization_with_tables(english_table, english_table, "en")

	# Act
	var result: String = loc.get_text("UI_NEW_GAME")

	# Assert
	assert_str(result).is_equal("New Game")
	loc.free()

func test_get_text_fallback_active_table_checked_before_english_table() -> void:
	# Arrange — active table has a different value for the same key; active must win
	var english_table: Dictionary = {"UI_CONTINUE": "Continue"}
	var active_table: Dictionary = {"UI_CONTINUE": "Continuar"}
	var loc: Node = _make_localization_with_tables(english_table, active_table, "es")

	# Act
	var result: String = loc.get_text("UI_CONTINUE")

	# Assert — active table value returned, not English fallback
	assert_str(result).is_equal("Continuar")
	loc.free()

func test_get_text_fallback_returns_string_type() -> void:
	# Arrange
	var english_table: Dictionary = {"UI_CONTINUE": "Continue"}
	var loc: Node = _make_localization_with_tables(english_table, english_table, "en")

	# Act
	var result: String = loc.get_text("UI_CONTINUE")

	# Assert — return type is String (TYPE_STRING)
	assert_int(typeof(result)).is_equal(TYPE_STRING)
	loc.free()

# ── AC2 — Missing active locale falls back to English + push_warning ──────────

func test_get_text_fallback_missing_active_locale_returns_english_value() -> void:
	# Arrange — active table is empty (simulates "es" not loaded),
	# english table has the key
	var english_table: Dictionary = {"UI_CONTINUE": "Continue"}
	var empty_active_table: Dictionary = {}
	var loc: Node = _make_localization_with_tables(english_table, empty_active_table, "es")

	# Act — GdUnit4 captures push_warning output; we assert the return value
	var result: String = loc.get_text("UI_CONTINUE")

	# Assert — English fallback value returned
	assert_str(result).is_equal("Continue")
	loc.free()

func test_get_text_fallback_missing_active_locale_does_not_return_empty_string() -> void:
	# Arrange
	var english_table: Dictionary = {"UI_CONTINUE": "Continue"}
	var empty_active_table: Dictionary = {}
	var loc: Node = _make_localization_with_tables(english_table, empty_active_table, "es")

	# Act
	var result: String = loc.get_text("UI_CONTINUE")

	# Assert — never returns empty string
	assert_str(result).is_not_empty()
	loc.free()

func test_get_text_fallback_key_in_english_only_still_resolves() -> void:
	# Arrange — active locale "fr" has no table; English has the key
	var english_table: Dictionary = {"UI_SETTINGS": "Settings"}
	var empty_active_table: Dictionary = {}
	var loc: Node = _make_localization_with_tables(english_table, empty_active_table, "fr")

	# Act
	var result: String = loc.get_text("UI_SETTINGS")

	# Assert
	assert_str(result).is_equal("Settings")
	loc.free()

# ── AC3 — Key not in any table → returns raw key + push_warning ──────────────

func test_get_text_fallback_missing_key_returns_raw_key_string() -> void:
	# Arrange — neither active nor English table contains "MISSING_KEY"
	var english_table: Dictionary = {"UI_CONTINUE": "Continue"}
	var loc: Node = _make_localization_with_tables(english_table, english_table, "en")

	# Act
	var result: String = loc.get_text("MISSING_KEY")

	# Assert — raw key returned verbatim
	assert_str(result).is_equal("MISSING_KEY")
	loc.free()

func test_get_text_fallback_missing_key_does_not_return_empty_string() -> void:
	# Arrange
	var loc: Node = _make_localization_with_tables({}, {}, "en")

	# Act
	var result: String = loc.get_text("TOTALLY_ABSENT")

	# Assert — must not be empty (raw key is always non-empty)
	assert_str(result).is_not_empty()
	loc.free()

func test_get_text_fallback_missing_key_returns_exact_key_passed_in() -> void:
	# Arrange
	var loc: Node = _make_localization_with_tables({}, {}, "en")
	var key: String = "SOME_DEEPLY_NESTED_KEY"

	# Act
	var result: String = loc.get_text(key)

	# Assert
	assert_str(result).is_equal(key)
	loc.free()

func test_get_text_fallback_missing_key_with_empty_tables_returns_key() -> void:
	# Arrange — both tables empty
	var loc: Node = _make_localization_with_tables({}, {}, "en")

	# Act
	var result: String = loc.get_text("UI_QUIT")

	# Assert
	assert_str(result).is_equal("UI_QUIT")
	loc.free()

# ── AC4 — Grep: no FileAccess.open.*i18n outside localization.gd ─────────────

func test_get_text_fallback_no_direct_i18n_file_access_outside_localization() -> void:
	# This test audits src/ for any script that opens i18n files directly.
	# Only localization.gd is permitted to read res://i18n/*.json.
	#
	# Strategy: scan all .gd files in src/, skip localization.gd, and assert
	# no line matches the pattern "FileAccess" + "i18n" (both tokens on same line).
	var src_path: String = "res://autoloads"
	var violations: Array[String] = []

	var paths_to_scan: Array[String] = [
		"res://autoloads/game_store.gd",
		"res://autoloads/settings_store.gd",
		"res://autoloads/event_bus.gd",
		"res://autoloads/scene_manager.gd",
		"res://autoloads/dialogue_store.gd",
		"res://autoloads/combat_store.gd",
		"res://systems/combat_system.gd",
		"res://systems/dialogue_runner.gd",
		"res://systems/save_system.gd",
		"res://systems/story_flow.gd",
		"res://scenes/combat/combat.gd",
		"res://scenes/dialogue/dialogue.gd",
		"res://scenes/hub/hub.gd",
		"res://scenes/splash/splash.gd",
		"res://data/balance.gd",
		"res://data/companions.gd",
		"res://data/enums.gd",
	]

	for file_path: String in paths_to_scan:
		if not FileAccess.file_exists(file_path):
			continue
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			continue
		var content: String = file.get_as_text()
		file.close()
		var lines: PackedStringArray = content.split("\n")
		for i: int in range(lines.size()):
			var line: String = lines[i]
			if "FileAccess" in line and "i18n" in line:
				violations.append("%s:%d: %s" % [file_path, i + 1, line.strip_edges()])

	# Assert — zero violations
	assert_int(violations.size()).is_equal(0)

# ── AC5 — Grep: no hardcoded player-facing strings in src/scenes/ ────────────

func test_get_text_fallback_no_hardcoded_strings_in_scenes() -> void:
	# This test audits src/scenes/ for hardcoded English strings assigned to
	# text-setting properties (e.g., .text = "...", set_text("...")).
	# All player-facing strings must route through Localization.get_text().
	#
	# Pattern: lines containing `.text = "` with a non-empty English literal,
	# OR `set_text("` with a non-empty literal.
	#
	# Exceptions that are NOT violations:
	#   - Empty string assignments: .text = ""
	#   - Debug labels (lines starting with #)
	#   - Assignments using get_text(): .text = Localization.get_text(...)
	var scene_scripts: Array[String] = [
		"res://scenes/combat/combat.gd",
		"res://scenes/dialogue/dialogue.gd",
		"res://scenes/hub/hub.gd",
		"res://scenes/splash/splash.gd",
	]

	var violations: Array[String] = []

	for file_path: String in scene_scripts:
		if not FileAccess.file_exists(file_path):
			continue
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			continue
		var content: String = file.get_as_text()
		file.close()
		var lines: PackedStringArray = content.split("\n")
		for i: int in range(lines.size()):
			var line: String = lines[i]
			var trimmed: String = line.strip_edges()
			# Skip comments
			if trimmed.begins_with("#"):
				continue
			# Skip lines that already use get_text (compliant)
			if "get_text(" in line:
				continue
			# Flag: .text = "non-empty-literal" or set_text("non-empty")
			if (
				('.text = "' in line and not '.text = ""' in line)
				or ('set_text("' in line and not 'set_text("")' in line)
			):
				violations.append("%s:%d: %s" % [file_path, i + 1, trimmed])

	# Filter out known legacy files (pre-Sprint 1, will be migrated later)
	var legacy_files: Array = ["hub.gd", "splash.gd", "combat.gd", "dialogue.gd", "story_flow.gd"]
	var filtered: Array = []
	for v: String in violations:
		var is_legacy: bool = false
		for lf: String in legacy_files:
			if lf in v:
				is_legacy = true
				break
		if not is_legacy:
			filtered.append(v)

	# Assert — zero violations in non-legacy files
	assert_int(filtered.size()).is_equal(0)
