class_name CompanionStateTest
extends GdUnitTestSuite

const CompanionState = preload("res://systems/companion_state.gd")

## Unit tests for STORY-COMPANION-003: CompanionState — Romance Stage Derivation
##
## Covers all Acceptance Criteria:
##   AC1 — get_state() returns dict with all 8 mutable state fields including romance_stage
##   AC2 — relationship_level=55 → romance_stage=2
##   AC3 — relationship_level=0  → romance_stage=0
##   AC4 — relationship_level=91 → romance_stage=4
##   AC5 — Stage never decreases (monotonic non-decrease constraint)
##   AC6 — set_relationship_level(id, 105) clamps to 100 in GameStore
##   AC7 — romance_stage_changed signal emitted on stage transition
##   AC8 — No spurious romance_stage_changed signal when stage does not change
##
## See: docs/architecture/adr-0009-companion-data.md

# ── Setup / Teardown ──────────────────────────────────────────────────────────

func before_test() -> void:
	# Reset all GameStore state to factory defaults before every test.
	GameStore._initialize_defaults()
	# Clear the static max-stage cache so tests are fully independent.
	CompanionState._max_stages.clear()

# ── AC1 — get_state() returns all 8 mutable fields ───────────────────────────

func test_companion_state_get_state_returns_relationship_level_key() -> void:
	# Arrange — factory default for artemisa has relationship_level=0
	# Act
	var state: Dictionary = CompanionState.get_state("artemisa")

	# Assert
	assert_bool(state.has("relationship_level")).is_true()

func test_companion_state_get_state_returns_trust_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("trust")).is_true()

func test_companion_state_get_state_returns_motivation_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("motivation")).is_true()

func test_companion_state_get_state_returns_romance_stage_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("romance_stage")).is_true()

func test_companion_state_get_state_returns_dates_completed_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("dates_completed")).is_true()

func test_companion_state_get_state_returns_met_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("met")).is_true()

func test_companion_state_get_state_returns_known_likes_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("known_likes")).is_true()

func test_companion_state_get_state_returns_known_dislikes_key() -> void:
	var state: Dictionary = CompanionState.get_state("artemisa")
	assert_bool(state.has("known_dislikes")).is_true()

func test_companion_state_get_state_unknown_id_returns_empty_dict() -> void:
	# Arrange / Act
	var state: Dictionary = CompanionState.get_state("zeus")

	# Assert
	assert_bool(state.is_empty()).is_true()

# ── AC2 — relationship_level=55 → romance_stage=2 ────────────────────────────

func test_companion_state_get_romance_stage_level_55_returns_stage_2() -> void:
	# Arrange
	GameStore._set_relationship_level("artemisa", 55)

	# Act
	var stage: int = CompanionState.get_romance_stage("artemisa")

	# Assert — thresholds [0,21,51,71,91]: 55 >= 51 but < 71 → stage 2
	assert_int(stage).is_equal(2)

func test_companion_state_get_state_level_55_includes_romance_stage_2() -> void:
	# Arrange
	GameStore._set_relationship_level("artemisa", 55)

	# Act
	var state: Dictionary = CompanionState.get_state("artemisa")

	# Assert
	assert_int(state.get("romance_stage", -1)).is_equal(2)

# ── AC3 — relationship_level=0 → romance_stage=0 ─────────────────────────────

func test_companion_state_get_romance_stage_level_0_returns_stage_0() -> void:
	# Arrange — factory default is 0
	# Act
	var stage: int = CompanionState.get_romance_stage("artemisa")

	# Assert
	assert_int(stage).is_equal(0)

# ── AC4 — relationship_level=91 → romance_stage=4 ────────────────────────────

func test_companion_state_get_romance_stage_level_91_returns_stage_4() -> void:
	# Arrange
	GameStore._set_relationship_level("artemisa", 91)

	# Act
	var stage: int = CompanionState.get_romance_stage("artemisa")

	# Assert — 91 >= 91 → stage 4 (max)
	assert_int(stage).is_equal(4)

func test_companion_state_get_romance_stage_level_100_returns_stage_4() -> void:
	# Arrange
	GameStore._set_relationship_level("artemisa", 100)

	# Act
	var stage: int = CompanionState.get_romance_stage("artemisa")

	# Assert
	assert_int(stage).is_equal(4)

# ── AC5 — Stage never decreases (monotonic non-decrease) ─────────────────────

func test_companion_state_romance_stage_does_not_decrease_when_level_drops() -> void:
	# Arrange — bring to stage 3 (needs rl >= 71)
	GameStore._set_relationship_level("artemisa", 75)
	var stage_before: int = CompanionState.get_romance_stage("artemisa")
	assert_int(stage_before).is_equal(3)

	# Act — drop below stage-3 threshold (71)
	GameStore._set_relationship_level("artemisa", 65)

	# Assert — stage stays at 3
	var stage_after: int = CompanionState.get_romance_stage("artemisa")
	assert_int(stage_after).is_equal(3)

func test_companion_state_romance_stage_stays_at_max_after_level_reset_to_zero() -> void:
	# Arrange — reach stage 2
	GameStore._set_relationship_level("hipolita", 55)
	var _primed: int = CompanionState.get_romance_stage("hipolita")

	# Act — drop to 0
	GameStore._set_relationship_level("hipolita", 0)

	# Assert — stays at 2 (monotonic)
	var stage: int = CompanionState.get_romance_stage("hipolita")
	assert_int(stage).is_equal(2)

# ── AC6 — set_relationship_level clamps to [0, 100] ──────────────────────────

func test_companion_state_set_relationship_level_clamps_above_100() -> void:
	# Arrange / Act
	CompanionState.set_relationship_level("artemisa", 105)

	# Assert — GameStore stores 100
	var stored: int = GameStore.get_relationship_level("artemisa")
	assert_int(stored).is_equal(100)

func test_companion_state_set_relationship_level_clamps_below_zero() -> void:
	# Arrange / Act
	CompanionState.set_relationship_level("artemisa", -10)

	# Assert — GameStore stores 0
	var stored: int = GameStore.get_relationship_level("artemisa")
	assert_int(stored).is_equal(0)

func test_companion_state_set_relationship_level_stores_valid_value_unmodified() -> void:
	# Arrange / Act
	CompanionState.set_relationship_level("hipolita", 50)

	# Assert
	var stored: int = GameStore.get_relationship_level("hipolita")
	assert_int(stored).is_equal(50)

# ── AC7 — romance_stage_changed signal emitted on stage transition ────────────

func test_companion_state_set_relationship_level_emits_romance_stage_changed_on_transition() -> void:
	# Arrange — signal monitor via GdUnit4
	var signal_collector = monitor_signals(EventBus)
	# Ensure starting at stage 0 (factory default)
	GameStore._set_relationship_level("atenea", 0)
	CompanionState._max_stages.erase("atenea")

	# Act — cross the stage-1 threshold (21)
	CompanionState.set_relationship_level("atenea", 25)

	# Assert — signal was emitted once with correct args
	await assert_signal(signal_collector).was_emitted("romance_stage_changed")

func test_companion_state_romance_stage_changed_carries_correct_old_and_new_stage() -> void:
	# Arrange — start at stage 0
	GameStore._set_relationship_level("nyx", 0)
	CompanionState._max_stages.erase("nyx")
	var signal_collector = monitor_signals(EventBus)

	# Act — jump straight to stage 2 (rl=55, crosses both stage 1 and 2)
	CompanionState.set_relationship_level("nyx", 55)

	# Assert — emitted with old=0, new=2
	await assert_signal(signal_collector).was_emitted_with_args(
		"romance_stage_changed", ["nyx", 0, 2]
	)

# ── AC8 — No spurious romance_stage_changed when stage does not change ────────

func test_companion_state_set_relationship_level_no_signal_when_stage_unchanged() -> void:
	# Arrange — reach stage 4 (max)
	GameStore._set_relationship_level("artemisa", 100)
	var _primed: int = CompanionState.get_romance_stage("artemisa")
	var signal_collector = monitor_signals(EventBus)

	# Act — write again at 100; stage is already 4, cannot go higher
	CompanionState.set_relationship_level("artemisa", 100)

	# Assert — signal NOT emitted
	await assert_signal(signal_collector).was_not_emitted("romance_stage_changed")

func test_companion_state_set_relationship_level_no_signal_when_level_increases_within_same_stage() -> void:
	# Arrange — stage 1 requires rl >= 21; stay within stage 1 (21..50)
	GameStore._set_relationship_level("hipolita", 21)
	var _primed: int = CompanionState.get_romance_stage("hipolita")
	var signal_collector = monitor_signals(EventBus)

	# Act — move from 21 to 30 (still stage 1)
	CompanionState.set_relationship_level("hipolita", 30)

	# Assert — no signal (stage did not change)
	await assert_signal(signal_collector).was_not_emitted("romance_stage_changed")
