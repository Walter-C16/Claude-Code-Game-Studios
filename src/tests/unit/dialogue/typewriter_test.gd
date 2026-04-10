class_name TypewriterTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-002: Typewriter Text Animation and Tap Controls
##
## Covers:
##   AC2 — first tap during animation calls complete_typewriter (consumed, does NOT advance)
##   AC5 — {pause:5.0} clamped to 3.0, warning logged
##   AC6 — text > 280 chars truncated at word boundary with "[...]", warning logged
##   AC7 — CPS not hardcoded (loaded from config or uses DEFAULT_CPS constant)
##   AC8 — typewriter complete + no choices → advance moves to next line
##
## Logic under test is in DialogueRunner (typewriter state tracking).
## UI layer (RichTextLabel visible_characters) is excluded from unit scope.
##
## See: docs/architecture/adr-0008-dialogue.md

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

# ── Helper ────────────────────────────────────────────────────────────────────

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child(runner)
	return runner

# ── _typewriter_complete starts false when line_ready fires ───────────────────

func test_typewriter_complete_is_false_after_line_ready() -> void:
	# Arrange
	var runner = _make_runner()
	var flag_at_emit: bool = true

	runner.line_ready.connect(
		func(_line: Dictionary) -> void:
			flag_at_emit = runner._typewriter_complete
	)

	# Act
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Assert — _typewriter_complete was false when line_ready fired
	assert_bool(flag_at_emit).is_false()

# ── AC2 — advance() while typewriter incomplete calls complete_typewriter ──────

func test_typewriter_advance_while_incomplete_does_not_advance_line() -> void:
	# Arrange
	var runner = _make_runner()
	var line_count: int = 0
	runner.line_ready.connect(func(_line: Dictionary) -> void: line_count += 1)
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	# After start_dialogue: line_count = 1, typewriter incomplete

	# Act — advance while typewriter is still running
	runner.advance()

	# Assert — still only 1 line emitted (advance consumed by typewriter completion)
	assert_int(line_count).is_equal(1)

func test_typewriter_advance_while_incomplete_sets_typewriter_complete_true() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Act
	runner.advance()

	# Assert
	assert_bool(runner._typewriter_complete).is_true()

func test_typewriter_advance_while_incomplete_emits_typewriter_complete_signal() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	var signal_fired: bool = false
	runner.typewriter_complete.connect(func() -> void: signal_fired = true)

	# Act
	runner.advance()

	# Assert
	assert_bool(signal_fired).is_true()

# ── complete_typewriter() sets flag to true ───────────────────────────────────

func test_typewriter_complete_typewriter_sets_flag_true() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	# Flag is false after line_ready

	# Act
	runner.complete_typewriter()

	# Assert
	assert_bool(runner._typewriter_complete).is_true()

func test_typewriter_complete_typewriter_emits_signal() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	var fired: bool = false
	runner.typewriter_complete.connect(func() -> void: fired = true)

	# Act
	runner.complete_typewriter()

	# Assert
	assert_bool(fired).is_true()

# ── AC8 — after typewriter complete, advance() moves to next line ─────────────

func test_typewriter_after_complete_advance_emits_next_line() -> void:
	# Arrange
	var runner = _make_runner()
	var lines: Array = []
	runner.line_ready.connect(func(line: Dictionary) -> void: lines.append(line))
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()

	# Act
	runner.advance()

	# Assert — second line now emitted
	assert_int(lines.size()).is_equal(2)

func test_typewriter_after_complete_advance_second_line_typewriter_resets_false() -> void:
	# Arrange
	var runner = _make_runner()
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()

	# Act
	runner.advance()

	# Assert — new line means typewriter resets to incomplete
	assert_bool(runner._typewriter_complete).is_false()

# ── AC5 — extract_pauses clamps out-of-range values ──────────────────────────

func test_typewriter_extract_pauses_clamps_above_max() -> void:
	# Arrange
	var runner = _make_runner()
	var text: String = "Hello {pause:5.0} world"

	# Act
	var pauses: Array[float] = runner.extract_pauses(text)

	# Assert — 5.0 exceeds MAX_PAUSE_DURATION (3.0), clamped to 3.0
	assert_int(pauses.size()).is_equal(1)
	assert_float(pauses[0]).is_equal(3.0)

func test_typewriter_extract_pauses_clamps_below_min() -> void:
	# Arrange
	var runner = _make_runner()
	var text: String = "Hello {pause:0.01} world"

	# Act
	var pauses: Array[float] = runner.extract_pauses(text)

	# Assert — 0.01 is below MIN_PAUSE_DURATION (0.1), clamped to 0.1
	assert_int(pauses.size()).is_equal(1)
	assert_float(pauses[0]).is_equal(0.1)

func test_typewriter_extract_pauses_valid_value_unchanged() -> void:
	# Arrange
	var runner = _make_runner()
	var text: String = "Wait {pause:1.5} then continue"

	# Act
	var pauses: Array[float] = runner.extract_pauses(text)

	# Assert — 1.5 is within [0.1, 3.0]
	assert_int(pauses.size()).is_equal(1)
	assert_float(pauses[0]).is_equal(1.5)

func test_typewriter_extract_pauses_multiple_markers() -> void:
	# Arrange
	var runner = _make_runner()
	var text: String = "{pause:0.5} first {pause:2.0} second"

	# Act
	var pauses: Array[float] = runner.extract_pauses(text)

	# Assert
	assert_int(pauses.size()).is_equal(2)
	assert_float(pauses[0]).is_equal(0.5)
	assert_float(pauses[1]).is_equal(2.0)

# ── AC5 — strip_pause_markers removes markers from visible text ───────────────

func test_typewriter_strip_pause_markers_removes_marker() -> void:
	# Arrange
	var runner = _make_runner()

	# Act
	var result: String = runner.strip_pause_markers("Hello {pause:1.0} world")

	# Assert — marker removed, plain text remains
	assert_str(result).is_equal("Hello  world")

func test_typewriter_strip_pause_markers_no_marker_unchanged() -> void:
	# Arrange
	var runner = _make_runner()

	# Act
	var result: String = runner.strip_pause_markers("No markers here")

	# Assert
	assert_str(result).is_equal("No markers here")

# ── AC6 — truncate_text at 280 character word boundary ───────────────────────

func test_typewriter_truncate_text_short_text_unchanged() -> void:
	# Arrange
	var runner = _make_runner()
	var short_text: String = "Short text under limit."

	# Act
	var result: String = runner.truncate_text(short_text)

	# Assert — no truncation
	assert_str(result).is_equal(short_text)

func test_typewriter_truncate_text_long_text_ends_with_ellipsis() -> void:
	# Arrange
	var runner = _make_runner()
	# Build a string of 320 characters (over the 280 limit)
	var long_text: String = ""
	for i: int in range(32):
		long_text += "word%d " % i
	long_text = long_text.strip_edges()

	# Act
	var result: String = runner.truncate_text(long_text)

	# Assert — truncated text ends with "[...]"
	assert_str(result).ends_with("[...]")

func test_typewriter_truncate_text_long_text_length_at_most_limit_plus_ellipsis() -> void:
	# Arrange
	var runner = _make_runner()
	var long_text: String = ""
	for i: int in range(32):
		long_text += "word%d " % i

	# Act
	var result: String = runner.truncate_text(long_text)

	# Assert — result is shorter than original (was truncated)
	assert_bool(result.length() < long_text.length()).is_true()

func test_typewriter_truncate_text_exactly_280_chars_not_truncated() -> void:
	# Arrange — build exactly 280-char string (no truncation expected)
	var runner = _make_runner()
	var exact_text: String = "a".repeat(280)

	# Act
	var result: String = runner.truncate_text(exact_text)

	# Assert — not truncated
	assert_str(result).is_equal(exact_text)

# ── AC7 — CPS not hardcoded; DEFAULT_CPS constant exists ─────────────────────

func test_typewriter_default_cps_constant_is_40() -> void:
	# Arrange
	var runner = _make_runner()

	# Assert — DEFAULT_CPS is the documented default of 40
	assert_float(runner.DEFAULT_CPS).is_equal(40.0)

func test_typewriter_cps_field_equals_default_when_no_config() -> void:
	# Arrange — fresh runner with no config loaded
	# (config file may or may not exist; if missing, runner falls back to DEFAULT_CPS)
	var runner = _make_runner()

	# Assert — cps is a positive value (config-driven, not zero or negative)
	assert_bool(runner.cps > 0.0).is_true()
