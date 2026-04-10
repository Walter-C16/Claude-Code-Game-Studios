class_name InterpolationTest
extends GdUnitTestSuite

const _LocalizationScript = preload("res://autoloads/localization.gd")

## Unit tests for STORY-LOC-003: Parameter Interpolation
##
## Covers:
##   AC1 — "POKER_SCORE": "Score: {{score}}", get_text("POKER_SCORE", {"score": "150"})
##          → "Score: 150"
##   AC2 — "{{name}} attacks {{target}}" with {"name": "Artemisa", "target": "Beast"}
##          → "Artemisa attacks Beast"
##   AC3 — "{{name}} attacks" with {} (no "name" key) → placeholder remains in output
##   AC4 — String with no placeholders + non-empty params → returned unchanged
##   AC5 — _interpolate with empty params → text returned unchanged
##
## See: docs/architecture/adr-0005-localization.md

# ── Helpers ───────────────────────────────────────────────────────────────────

## Creates a Localization node without calling _ready().
## Manually populates _english_table and _active_table from the given dict
## so tests are fully isolated from the real en.json file on disk.
func _make_localization_with_table(table: Dictionary):
	var loc: Localization = _LocalizationScript.new()
	loc._english_table = table
	loc._active_table = table
	loc._active_locale = "en"
	return loc

# ── AC1 — POKER_SCORE key with single {{score}} param ────────────────────────

func test_interpolation_poker_score_single_param_returns_interpolated_string() -> void:
	# Arrange
	var table: Dictionary = {"POKER_SCORE": "Score: {{score}}"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("POKER_SCORE", {"score": "150"})

	# Assert
	assert_str(result).is_equal("Score: 150")
	loc.free()

func test_interpolation_poker_score_placeholder_fully_replaced() -> void:
	# Arrange — verify no leftover "{{score}}" in the result
	var table: Dictionary = {"POKER_SCORE": "Score: {{score}}"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("POKER_SCORE", {"score": "42"})

	# Assert
	assert_str(result).not_contains("{{score}}")
	loc.free()

# ── AC2 — Multiple placeholders all replaced ──────────────────────────────────

func test_interpolation_two_params_both_replaced() -> void:
	# Arrange
	var table: Dictionary = {"ATTACK_MSG": "{{name}} attacks {{target}}"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("ATTACK_MSG", {"name": "Artemisa", "target": "Beast"})

	# Assert
	assert_str(result).is_equal("Artemisa attacks Beast")
	loc.free()

func test_interpolation_two_params_no_leftover_placeholders() -> void:
	# Arrange
	var table: Dictionary = {"ATTACK_MSG": "{{name}} attacks {{target}}"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("ATTACK_MSG", {"name": "Artemisa", "target": "Beast"})

	# Assert — neither placeholder survives
	assert_str(result).not_contains("{{name}}")
	assert_str(result).not_contains("{{target}}")
	loc.free()

# ── AC3 — Placeholder present but key absent from params → placeholder remains ─

func test_interpolation_missing_param_key_leaves_placeholder_intact() -> void:
	# Arrange — params does not contain "name"
	var table: Dictionary = {"ATTACK_MSG": "{{name}} attacks"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("ATTACK_MSG", {"target": "Beast"})

	# Assert — {{name}} must survive unchanged
	assert_str(result).contains("{{name}}")
	loc.free()

func test_interpolation_missing_param_key_does_not_return_empty_string() -> void:
	# Arrange
	var table: Dictionary = {"MSG": "Hello {{name}}"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("MSG", {})

	# Assert — result is non-empty (the literal text still present)
	assert_str(result).is_not_empty()
	loc.free()

# ── AC4 — No placeholders in string, non-empty params → string unchanged ───────

func test_interpolation_no_placeholders_with_params_returns_original_text() -> void:
	# Arrange — value has no {{ }} tokens at all
	var table: Dictionary = {"UI_CONTINUE": "Continue"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("UI_CONTINUE", {"unused_key": "value"})

	# Assert — original value returned verbatim
	assert_str(result).is_equal("Continue")
	loc.free()

func test_interpolation_no_placeholders_result_is_exact_table_value() -> void:
	# Arrange
	var table: Dictionary = {"GREETING": "Welcome to Dark Olympus"}
	var loc: Localization = _make_localization_with_table(table)

	# Act
	var result: String = loc.get_text("GREETING", {"score": "100", "name": "Zeus"})

	# Assert
	assert_str(result).is_equal("Welcome to Dark Olympus")
	loc.free()

# ── AC5 — _interpolate with empty params returns text unchanged ───────────────

func test_interpolation_empty_params_returns_text_unchanged() -> void:
	# Arrange — call _interpolate directly; empty params must not alter text
	var loc: Localization = _LocalizationScript.new()
	var input: String = "Score: {{score}}"

	# Act
	var result: String = loc._interpolate(input, {})

	# Assert — placeholder survives, nothing mutated
	assert_str(result).is_equal("Score: {{score}}")
	loc.free()

func test_interpolation_empty_params_on_plain_text_returns_same_string() -> void:
	# Arrange
	var loc: Localization = _LocalizationScript.new()
	var input: String = "New Game"

	# Act
	var result: String = loc._interpolate(input, {})

	# Assert
	assert_str(result).is_equal("New Game")
	loc.free()
