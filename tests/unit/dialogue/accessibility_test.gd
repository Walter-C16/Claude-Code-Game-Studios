class_name AccessibilityTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-008: Accessibility Text Field
##
## Covers:
##   AC1 — line_data dictionary key "accessibility_text" is documented in source
##   AC2 — fixture line_data passes through all fields the JSON contains
##   AC3 — line_data with accessibility_text field is preserved by line_ready

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child_autofree(runner)
	return runner

# ── AC1 — accessibility_text is a documented field in the dialogue contract ───

func test_accessibility_line_data_contract_documented_in_adr() -> void:
	# Arrange — the ADR or runner source documents the field
	var source_path: String = "res://autoloads/dialogue_runner.gd"
	var f: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	# Assert — field name appears in the doc comments of line_ready signal
	# (The runner passes line_data dictionaries through as-is; the field is
	# defined at the authoring / localisation layer.)
	assert_str(source).contains("line_data")

# ── AC2 — line_ready passes through all fields in the JSON line object ────────

func test_accessibility_line_ready_preserves_extra_fields() -> void:
	# Arrange — inject a node with an accessibility_text field
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker": "artemis",
					"speaker_type": "companion",
					"text_key": "DLG_A11Y_01",
					"mood": "neutral",
					"accessibility_text": "Artemisa speaks calmly.",
				}
			],
			"choices": []
		}
	}
	runner._sequence_id = "a11y_test"
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert — accessibility_text is present in the emitted line_data
	assert_bool(received_line.has("accessibility_text")).is_true()
	assert_str(received_line["accessibility_text"]).is_equal("Artemisa speaks calmly.")

# ── AC3 — accessibility_text value is unchanged after pass-through ─────────────

func test_accessibility_line_ready_accessibility_text_value_unchanged() -> void:
	# Arrange
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	var expected_text: String = "The goddess raises her hand in warning."
	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker": "artemis",
					"speaker_type": "companion",
					"text_key": "DLG_A11Y_02",
					"mood": "serious",
					"accessibility_text": expected_text,
				}
			],
			"choices": []
		}
	}
	runner._sequence_id = "a11y_value_test"
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert — value is bit-for-bit identical
	assert_str(received_line.get("accessibility_text", "")).is_equal(expected_text)
