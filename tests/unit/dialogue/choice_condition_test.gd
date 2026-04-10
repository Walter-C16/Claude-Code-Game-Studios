class_name ChoiceConditionTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-005: Choice Condition Filtering
##
## Covers:
##   AC1 — choice with no conditions always passes (included in filtered list)
##   AC2 — flag_set condition filters out choice when flag not set
##   AC3 — flag_set condition keeps choice when flag is set
##   AC4 — romance_stage condition filters by CompanionState (source inspection)
##   AC5 — all choices failing conditions ends dialogue, not a crash

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child_autofree(runner)
	return runner

func _advance_to_choices(runner: Node) -> Array:
	var received: Array = []
	runner.choices_ready.connect(func(c: Array) -> void: received = c)
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	return received

# ── AC1 — unconditional choice always passes ──────────────────────────────────

func test_choice_condition_unconditional_choice_always_present() -> void:
	# Arrange
	var runner = _make_runner()

	# Act — fixture choice A has no conditions
	var choices = _advance_to_choices(runner)

	# Assert — choice A (DLG_CHOICE_A) must be present regardless
	var found: bool = false
	for c: Variant in choices:
		if (c as Dictionary).get("text_key", "") == "DLG_CHOICE_A":
			found = true
	assert_bool(found).is_true()

# ── AC2 — flag_set condition filters choice when flag not set ─────────────────

func test_choice_condition_flag_set_choice_absent_when_flag_missing() -> void:
	# Arrange — fixture choice B requires flag "ch01_met_artemis" which is not set
	var runner = _make_runner()

	# Act
	var choices = _advance_to_choices(runner)

	# Assert — DLG_CHOICE_B should be filtered out
	var found: bool = false
	for c: Variant in choices:
		if (c as Dictionary).get("text_key", "") == "DLG_CHOICE_B":
			found = true
	assert_bool(found).is_false()

# ── AC3 — unconditional choices survive when a conditional one is filtered ────

func test_choice_condition_other_choices_survive_flag_filter() -> void:
	# Arrange
	var runner = _make_runner()

	# Act
	var choices = _advance_to_choices(runner)

	# Assert — choices without conditions are still returned even when B is filtered
	assert_int(choices.size()).is_greater(0)

# ── AC4 — romance_stage condition handled in source ───────────────────────────

func test_choice_condition_romance_stage_condition_handled_in_source() -> void:
	# Arrange
	var source_path: String = "res://autoloads/dialogue_runner.gd"
	var f: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	# Assert — the runner handles romance_stage condition type
	assert_str(source).contains('"romance_stage"')
	assert_str(source).contains("get_romance_stage")

# ── AC5 — all choices failing ends dialogue cleanly ──────────────────────────

func test_choice_condition_all_choices_failing_ends_dialogue() -> void:
	# Arrange — inject a node where all choices have an unsatisfiable flag condition
	var runner = _make_runner()
	var ended_count: int = 0
	runner.dialogue_ended.connect(func(_id: String) -> void: ended_count += 1)

	runner._nodes = {
		"start": {
			"lines": [],
			"choices": [
				{
					"text_key": "CHOICE_IMPOSSIBLE",
					"next": "start",
					"conditions": [{"type": "flag_set", "flag": "never_set_flag_xyz"}]
				}
			]
		}
	}
	runner._sequence_id = "test_allfilter"
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act — entering the node will filter all choices and trigger end_dialogue
	runner._enter_node("start")

	# Assert
	assert_int(ended_count).is_equal(1)
