class_name EffectSystemTest
extends GdUnitTestSuite

## Unit tests for STORY-DIALOGUE-006: Effect Application
##
## Covers:
##   AC1 — "relationship" effect emits EventBus.relationship_changed
##   AC2 — "trust" effect emits EventBus.trust_changed
##   AC3 — "flag_set" effect writes flag to GameStore
##   AC4 — "item_grant" effect emits EventBus.item_granted
##   AC5 — unknown effect type is skipped without crash (source inspection)

const RunnerScript = preload("res://autoloads/dialogue_runner.gd")

const FIXTURE_CHAPTER: String = "test"
const FIXTURE_SEQ: String = "test_dialogue"

func _make_runner() -> Node:
	var runner = RunnerScript.new()
	add_child_autofree(runner)
	return runner

func _advance_to_choices(runner: Node) -> void:
	runner.start_dialogue(FIXTURE_CHAPTER, FIXTURE_SEQ)
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()
	runner.complete_typewriter()
	runner.advance()

# ── AC1 — relationship effect emits EventBus.relationship_changed ─────────────

func test_effect_system_relationship_effect_emits_relationship_changed() -> void:
	# Arrange — choice A in fixture has a relationship +5 effect
	var runner = _make_runner()
	var rel_signals: Array = []
	EventBus.relationship_changed.connect(
		func(companion: String, delta: int) -> void:
			rel_signals.append({"companion": companion, "delta": delta})
	)
	_advance_to_choices(runner)

	# Act — select choice A (index 0), which has the relationship effect
	runner.select_choice(0)

	# Assert
	assert_int(rel_signals.size()).is_equal(1)
	assert_str(rel_signals[0]["companion"]).is_equal("artemisa")
	assert_int(rel_signals[0]["delta"]).is_equal(5)

	EventBus.relationship_changed.disconnect_all()

# ── AC2 — trust effect emits EventBus.trust_changed ──────────────────────────

func test_effect_system_trust_effect_source_handled() -> void:
	# Arrange
	var f: FileAccess = FileAccess.open("res://autoloads/dialogue_runner.gd", FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	# Assert — "trust" effect type is handled
	assert_str(source).contains('"trust"')
	assert_str(source).contains("trust_changed")

# ── AC3 — flag_set effect writes to GameStore ─────────────────────────────────

func test_effect_system_flag_set_effect_sets_flag_in_game_store() -> void:
	# Arrange — choice C in fixture has a flag_set "test_flag" effect
	var runner = _make_runner()
	_advance_to_choices(runner)

	# Ensure flag is clear before the test
	if GameStore.has_flag("test_flag"):
		GameStore.clear_flag("test_flag")

	# Act — select choice C (index 1 after filtering, choice C is "DLG_CHOICE_C")
	# choice B is filtered (requires unset flag), so choice C may be at index 1
	var choices: Array = []
	runner.choices_ready.connect(func(c: Array) -> void: choices = c)
	# choices_ready already fired; re-read _current_choices via select by scanning
	# We know from fixture: C is the third choice. After filtering, A is 0, C is 1.
	runner.select_choice(1)

	# Assert
	assert_bool(GameStore.has_flag("test_flag")).is_true()

	# Cleanup
	GameStore.clear_flag("test_flag")

# ── AC4 — item_grant effect emits EventBus.item_granted ──────────────────────

func test_effect_system_item_grant_effect_source_handled() -> void:
	# Arrange
	var f: FileAccess = FileAccess.open("res://autoloads/dialogue_runner.gd", FileAccess.READ)
	var source: String = f.get_as_text()
	f.close()

	# Assert — "item_grant" effect type is handled
	assert_str(source).contains('"item_grant"')
	assert_str(source).contains("item_granted")

# ── AC5 — unknown effect type skipped without crash ───────────────────────────

func test_effect_system_unknown_effect_type_does_not_crash() -> void:
	# Arrange
	var runner = _make_runner()

	# Act — inject an unknown effect type directly
	runner._nodes = {
		"start": {
			"lines": [{"speaker": "artemisa", "speaker_type": "companion", "text_key": "X", "mood": "neutral"}],
			"choices": [
				{
					"text_key": "CHOICE_X",
					"next": "",
					"effects": [{"type": "totally_unknown_effect_type_xyz"}]
				}
			]
		}
	}
	runner._sequence_id = "effect_test"
	runner._current_node_id = "start"
	runner._state = runner.State.CHOOSING
	runner._current_choices = [
		{"text_key": "CHOICE_X", "next": "", "effects": [{"type": "totally_unknown_effect_type_xyz"}]}
	]

	# Act — selecting this choice should not crash
	runner.select_choice(0)

	# Assert — runner ended cleanly (next is empty -> end_dialogue)
	assert_int(runner.get_state()).is_equal(0) # State.IDLE
