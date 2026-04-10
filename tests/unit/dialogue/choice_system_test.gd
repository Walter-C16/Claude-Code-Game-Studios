class_name ChoiceSystemTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-004: Choice Presentation and Navigation
##
## Covers:
##   AC1 — choices_ready fires with the full choices array after final line
##   AC2 — choices_ready payload contains expected text_key fields
##   AC3 — select_choice() navigates to the choice's next node
##   AC4 — select_choice() with out-of-range index is ignored (no crash)
##   AC5 — select_choice() outside CHOOSING state is ignored (no crash)

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child_autofree(runner)
	return runner

func _advance_to_choices(runner: Node) -> void:
	# Start dialogue, complete typewriter on line 1, advance to line 2,
	# complete typewriter on line 2, advance — lands on choice_node prompt line.
	# Then complete typewriter and advance once more to trigger choices_ready.
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()
	runner.advance()          # line 1 -> line 2
	runner.complete_typewriter()
	runner.advance()          # line 2 -> choice_node (emits line 3 prompt)
	runner.complete_typewriter()
	runner.advance()          # choice prompt done -> choices_ready

# ── AC1 — choices_ready fires ─────────────────────────────────────────────────

func test_choice_system_choices_ready_fires_after_final_line() -> void:
	# Arrange
	var runner = _make_runner()
	var choices_received: Array = []
	runner.choices_ready.connect(func(c: Array) -> void: choices_received.append(c))

	# Act
	_advance_to_choices(runner)

	# Assert
	assert_int(choices_received.size()).is_equal(1)

func test_choice_system_choices_ready_array_is_not_empty() -> void:
	# Arrange
	var runner = _make_runner()
	var choices_received: Array = []
	runner.choices_ready.connect(func(c: Array) -> void: choices_received.append(c))

	# Act
	_advance_to_choices(runner)

	# Assert
	assert_int(choices_received[0].size()).is_greater(0)

# ── AC2 — choices_ready payload has text_key fields ───────────────────────────

func test_choice_system_choices_ready_entries_have_text_key() -> void:
	# Arrange
	var runner = _make_runner()
	var received_choices: Array = []
	runner.choices_ready.connect(func(c: Array) -> void: received_choices = c)

	# Act
	_advance_to_choices(runner)

	# Assert — every choice in the array has a text_key
	for choice: Variant in received_choices:
		assert_bool((choice as Dictionary).has("text_key")).is_true()

# ── AC3 — select_choice() navigates to next node ─────────────────────────────

func test_choice_system_select_choice_navigates_to_next_node() -> void:
	# Arrange
	var runner = _make_runner()
	var lines_received: Array = []
	runner.line_ready.connect(func(d: Dictionary) -> void: lines_received.append(d))
	_advance_to_choices(runner)

	# Act — select first choice (navigates to end_node)
	runner.select_choice(0)

	# Assert — end_node line emitted
	var last_line: Dictionary = lines_received.back()
	assert_str(last_line["text_key"]).is_equal("DLG_TEST_END")

# ── AC4 — select_choice() out-of-range index ignored ─────────────────────────

func test_choice_system_select_choice_out_of_range_does_not_crash() -> void:
	# Arrange
	var runner = _make_runner()
	_advance_to_choices(runner)

	# Act — index 99 is way out of range
	runner.select_choice(99)

	# Assert — state is still CHOOSING (no crash, no navigation)
	assert_int(runner.get_state()).is_equal(5) # State.CHOOSING

# ── AC5 — select_choice() outside CHOOSING state ignored ─────────────────────

func test_choice_system_select_choice_when_not_choosing_is_ignored() -> void:
	# Arrange — runner is in DISPLAYING after start, not CHOOSING
	var runner = _make_runner()
	var lines_received: Array = []
	runner.line_ready.connect(func(d: Dictionary) -> void: lines_received.append(d))
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	var lines_before: int = lines_received.size()

	# Act — try to select a choice while displaying a line
	runner.select_choice(0)

	# Assert — no navigation occurred, line count unchanged
	assert_int(lines_received.size()).is_equal(lines_before)
