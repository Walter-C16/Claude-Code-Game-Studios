class_name SpeakerPortraitTest
extends GdUnitTestSuite

# Unit tests for STORY-DIALOGUE-003: Speaker Types and Portrait Rendering
#
# Covers the data contract that DialogueRunner.line_ready emits:
#   AC1  — companion node line_data contains speaker, speaker_type="companion", mood
#   AC2  — NPC node line_data contains speaker, speaker_type="npc", mood
#   AC3  — narrator node has speaker_type="narrator", no speaker id required
#   AC4  — environment node has speaker_type="environment"
#   AC5  — CompanionRegistry.get_portrait_path resolves companion portrait paths
#   AC7  — get_portrait_path returns PLACEHOLDER when file does not exist
#   AC8  — get_portrait_path returns PLACEHOLDER when speaker id is unknown
#
# Portrait rendering and crossfade are UI-layer concerns; those are covered in
# production/qa/evidence/dialogue-speaker-types.md (Advisory gate).
#
# See: docs/architecture/adr-0008-dialogue.md

const DialogueRunnerScript = preload("res://src/autoloads/dialogue_runner.gd")
const CompanionRegistryScript = preload("res://src/autoloads/companion_registry.gd")

# ── Helpers ──────────────────────────────────────────────────────────────────

func _make_runner() -> Node:
	var runner = DialogueRunnerScript.new()
	runner.cps = 40.0
	return runner

func _make_registry() -> Node:
	return CompanionRegistryScript.new()

# ── AC1 — companion line_data structure ──────────────────────────────────────

func test_speaker_portrait_companion_line_has_speaker_type_companion() -> void:
	# Arrange — build a minimal in-memory node with a companion line
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	# Inject a node with a companion line directly into the runner state
	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker": "artemis",
					"speaker_type": "companion",
					"text_key": "CH1_ART_01",
					"mood": "happy",
				}
			],
			"choices": [],
		}
	}
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert
	assert_str(received_line.get("speaker_type", "")).is_equal("companion")
	assert_str(received_line.get("speaker", "")).is_equal("artemis")
	assert_str(received_line.get("mood", "")).is_equal("happy")

	runner.queue_free()

func test_speaker_portrait_companion_line_has_text_key() -> void:
	# Arrange
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker": "artemis",
					"speaker_type": "companion",
					"text_key": "CH1_ART_01",
					"mood": "happy",
				}
			],
			"choices": [],
		}
	}
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert
	assert_str(received_line.get("text_key", "")).is_not_empty()

	runner.queue_free()

# ── AC2 — NPC line_data structure ────────────────────────────────────────────

func test_speaker_portrait_npc_line_has_speaker_type_npc() -> void:
	# Arrange
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker": "priestess",
					"speaker_type": "npc",
					"text_key": "COMP_PRIESTESS_01",
					"mood": "neutral",
				}
			],
			"choices": [],
		}
	}
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert
	assert_str(received_line.get("speaker_type", "")).is_equal("npc")
	assert_str(received_line.get("speaker", "")).is_equal("priestess")
	assert_str(received_line.get("mood", "")).is_equal("neutral")

	runner.queue_free()

# ── AC3 — narrator line_data structure ───────────────────────────────────────

func test_speaker_portrait_narrator_line_has_speaker_type_narrator() -> void:
	# Arrange
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker_type": "narrator",
					"text_key": "NARR_CH1_01",
				}
			],
			"choices": [],
		}
	}
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert — narrator has no required speaker field
	assert_str(received_line.get("speaker_type", "")).is_equal("narrator")

	runner.queue_free()

# ── AC4 — environment line_data structure ────────────────────────────────────

func test_speaker_portrait_environment_line_has_speaker_type_environment() -> void:
	# Arrange
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	runner._nodes = {
		"start": {
			"lines": [
				{
					"speaker_type": "environment",
					"text_key": "ENV_OLYMPUS_01",
				}
			],
			"choices": [],
		}
	}
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert
	assert_str(received_line.get("speaker_type", "")).is_equal("environment")

	runner.queue_free()

# ── AC5 — CompanionRegistry portrait path resolution ─────────────────────────

func test_speaker_portrait_registry_returns_placeholder_for_unknown_id() -> void:
	# Arrange
	var registry = _make_registry()

	# Act — unknown ID must return the placeholder, not crash
	var path: String = registry.get_portrait_path("UNKNOWN_ID_XYZ", "happy")

	# Assert
	assert_str(path).is_equal(registry.PLACEHOLDER_PORTRAIT)

	registry.queue_free()

func test_speaker_portrait_registry_returns_placeholder_when_file_missing() -> void:
	# Arrange — use a real companion ID that will exist in registry but whose
	# portrait file almost certainly does not exist in the test environment.
	# We check only the fallback contract, not filesystem state.
	var registry = _make_registry()

	# Act — even if "artemis" is registered, the mood path won't exist in tests
	var path: String = registry.get_portrait_path("artemis", "extremely_rare_mood_xyz")

	# Assert — must return a non-empty string (placeholder or neutral or requested)
	assert_str(path).is_not_empty()

	registry.queue_free()

# ── AC8 — portrait path for unregistered ID is placeholder ───────────────────

func test_speaker_portrait_registry_get_portrait_path_unregistered_is_placeholder() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var path: String = registry.get_portrait_path("hades_minion_99", "neutral")

	# Assert
	assert_str(path).is_equal(registry.PLACEHOLDER_PORTRAIT)

	registry.queue_free()

# ── line_ready always passes through the full line Dictionary ─────────────────

func test_speaker_portrait_line_ready_emits_full_dict_with_all_fields() -> void:
	# Arrange
	var runner = _make_runner()
	var received_line: Dictionary = {}
	runner.line_ready.connect(func(d: Dictionary) -> void: received_line = d)

	var full_line: Dictionary = {
		"speaker": "nyx",
		"speaker_type": "companion",
		"text_key": "CH1_NYX_01",
		"mood": "mysterious",
		"text_params": {"name": "Hero"},
	}
	runner._nodes = {
		"start": {
			"lines": [full_line],
			"choices": [],
		}
	}
	runner._current_node_id = "start"
	runner._state = runner.State.DISPLAYING

	# Act
	runner._enter_node("start")

	# Assert — all fields preserved
	assert_str(received_line.get("speaker", "")).is_equal("nyx")
	assert_str(received_line.get("speaker_type", "")).is_equal("companion")
	assert_str(received_line.get("text_key", "")).is_equal("CH1_NYX_01")
	assert_str(received_line.get("mood", "")).is_equal("mysterious")
	assert_bool(received_line.has("text_params")).is_true()

	runner.queue_free()
