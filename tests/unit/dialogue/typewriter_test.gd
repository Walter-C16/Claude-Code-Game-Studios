class_name TypewriterTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-002: Typewriter State Tracking
##
## Covers:
##   AC1 — _typewriter_complete starts false when a line is emitted
##   AC2 — complete_typewriter() sets flag to true and emits typewriter_complete
##   AC3 — advance() when incomplete calls complete_typewriter (tap-to-complete)
##   AC4 — advance() when complete moves to next line (not tap-to-complete)
##   AC5 — second advance() after complete emits second line_ready

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child_autofree(runner)
	return runner

# ── AC1 — typewriter_complete NOT emitted at line start ───────────────────────

func test_typewriter_complete_not_emitted_on_line_ready() -> void:
	# Arrange
	var runner = _make_runner()
	var complete_count: int = 0
	runner.typewriter_complete.connect(func() -> void: complete_count += 1)

	# Act
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Assert — complete should not fire just from loading a line
	assert_int(complete_count).is_equal(0)

# ── AC2 — complete_typewriter() sets internal flag and emits signal ───────────

func test_typewriter_complete_typewriter_emits_signal() -> void:
	# Arrange
	var runner = _make_runner()
	var complete_count: int = 0
	runner.typewriter_complete.connect(func() -> void: complete_count += 1)
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Act
	runner.complete_typewriter()

	# Assert
	assert_int(complete_count).is_equal(1)

func test_typewriter_complete_typewriter_idempotent_on_second_call() -> void:
	# Arrange
	var runner = _make_runner()
	var complete_count: int = 0
	runner.typewriter_complete.connect(func() -> void: complete_count += 1)
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()

	# Act — call again while still on same line
	runner.complete_typewriter()

	# Assert — second call still fires the signal (UI may reconnect); no crash
	assert_int(complete_count).is_equal(2)

# ── AC3 — advance() when typewriter incomplete calls complete_typewriter ───────

func test_typewriter_advance_when_incomplete_does_not_emit_second_line() -> void:
	# Arrange
	var runner = _make_runner()
	var lines_received: Array = []
	runner.line_ready.connect(func(d: Dictionary) -> void: lines_received.append(d))
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	var lines_before: int = lines_received.size()

	# Act — advance without completing typewriter first
	runner.advance()

	# Assert — tap-to-complete: no new line emitted, still on same line
	assert_int(lines_received.size()).is_equal(lines_before)

func test_typewriter_advance_when_incomplete_emits_typewriter_complete() -> void:
	# Arrange
	var runner = _make_runner()
	var complete_count: int = 0
	runner.typewriter_complete.connect(func() -> void: complete_count += 1)
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)

	# Act
	runner.advance()

	# Assert — tap-to-complete consumed the advance and fired typewriter_complete
	assert_int(complete_count).is_equal(1)

# ── AC4/AC5 — advance() when complete moves to next line ─────────────────────

func test_typewriter_advance_after_complete_emits_next_line() -> void:
	# Arrange
	var runner = _make_runner()
	var lines_received: Array = []
	runner.line_ready.connect(func(d: Dictionary) -> void: lines_received.append(d))
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()

	# Act
	runner.advance()

	# Assert — second line emitted
	assert_int(lines_received.size()).is_equal(2)
	assert_str(lines_received[1]["text_key"]).is_equal("DLG_TEST_LINE_2")
