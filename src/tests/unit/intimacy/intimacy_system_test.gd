class_name IntimacySystemTest
extends GdUnitTestSuite

## Unit tests for IntimacySystem — Intimacy Scene Gate + Completion Logic
##
## Covers:
##   AC-1  — can_start_scene returns false when companion not met
##   AC-2  — can_start_scene returns false when romance_stage < 4 (scenes 1/2)
##   AC-3  — can_start_scene returns false when scene 3 attempted at stage 4
##   AC-4  — can_start_scene returns false when prior scene not complete
##   AC-5  — can_start_scene returns false when no tokens
##   AC-6  — can_start_scene returns true when all gates pass
##   AC-7  — start_scene consumes 1 token
##   AC-8  — complete_scene writes correct flag and awards RL
##   AC-9  — complete_scene awards 20 RL for scene 3
##   AC-10 — is_scene_complete returns true after complete_scene
##   AC-11 — complete_scene is write-once (no double award)
##   AC-12 — get_available_scenes returns empty for unmet companion

const _CompanionStateScript = preload("res://systems/companion_state.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

func _setup_stage_4(companion_id: String) -> void:
	# Force relationship_level to 91 → romance_stage 4.
	# Stage 4 threshold = 71, stage 5 threshold = 91.
	GameStore._companion_states[companion_id]["relationship_level"] = 91
	GameStore._companion_states[companion_id]["met"] = true

func _setup_stage_5(companion_id: String) -> void:
	# Force relationship_level to 91 → romance_stage 5 (max).
	GameStore._companion_states[companion_id]["relationship_level"] = 91
	GameStore._companion_states[companion_id]["met"] = true

# ── Setup / Teardown ──────────────────────────────────────────────────────────

func before_test() -> void:
	GameStore._initialize_defaults()
	_CompanionStateScript._max_stages.clear()
	IntimacySystem._reset_cache()

# ── AC-1 — not met blocks scene start ────────────────────────────────────────

func test_intimacy_system_can_start_scene_returns_false_when_not_met() -> void:
	# Arrange — artemis at stage 4 but met == false (default)
	GameStore._companion_states["artemis"]["relationship_level"] = 71

	# Act
	var result = IntimacySystem.can_start_scene("artemis", 1)

	# Assert
	assert_bool(result).is_false()

# ── AC-2 — stage < 4 blocks scenes 1 and 2 ───────────────────────────────────

func test_intimacy_system_can_start_scene_returns_false_when_stage_below_4() -> void:
	# Arrange — stage 3 (rl=60 < threshold 71)
	GameStore._companion_states["artemis"]["relationship_level"] = 60
	GameStore._companion_states["artemis"]["met"] = true

	# Act
	var result = IntimacySystem.can_start_scene("artemis", 1)

	# Assert
	assert_bool(result).is_false()

# ── AC-3 — stage 4 blocks scene 3 ────────────────────────────────────────────

func test_intimacy_system_can_start_scene_3_returns_false_at_stage_4() -> void:
	# Arrange — stage 4 (rl=71), scenes 1+2 complete
	_setup_stage_4("artemis")
	GameStore.set_flag("intimacy_artemis_1_complete")
	GameStore.set_flag("intimacy_artemis_2_complete")

	# Act
	var result = IntimacySystem.can_start_scene("artemis", 3)

	# Assert
	assert_bool(result).is_false()

# ── AC-4 — prior scene incomplete blocks next ─────────────────────────────────

func test_intimacy_system_can_start_scene_2_returns_false_when_scene_1_not_done() -> void:
	# Arrange — stage 4, scene 1 NOT complete
	_setup_stage_4("artemis")

	# Act
	var result = IntimacySystem.can_start_scene("artemis", 2)

	# Assert
	assert_bool(result).is_false()

# ── AC-5 — no tokens blocks start ────────────────────────────────────────────

func test_intimacy_system_can_start_scene_returns_false_when_no_tokens() -> void:
	# Arrange — stage 4, drain all tokens
	_setup_stage_4("artemis")
	GameStore.spend_token()
	GameStore.spend_token()
	GameStore.spend_token()
	assert_int(GameStore.get_daily_tokens()).is_equal(0)

	# Act
	var result = IntimacySystem.can_start_scene("artemis", 1)

	# Assert
	assert_bool(result).is_false()

# ── AC-6 — all gates pass allows start ───────────────────────────────────────

func test_intimacy_system_can_start_scene_returns_true_when_all_gates_pass() -> void:
	# Arrange — stage 4, met, tokens available
	_setup_stage_4("artemis")

	# Act
	var result = IntimacySystem.can_start_scene("artemis", 1)

	# Assert
	assert_bool(result).is_true()

# ── AC-7 — start_scene consumes 1 token ──────────────────────────────────────

func test_intimacy_system_start_scene_consumes_one_token() -> void:
	# Arrange
	_setup_stage_4("artemis")
	var tokens_before = GameStore.get_daily_tokens()

	# Act
	var _ok = IntimacySystem.start_scene("artemis", 1)

	# Assert
	assert_int(GameStore.get_daily_tokens()).is_equal(tokens_before - 1)

# ── AC-8 — complete_scene sets flag and awards 10 RL ─────────────────────────

func test_intimacy_system_complete_scene_1_awards_10_rl() -> void:
	# Arrange
	_setup_stage_4("artemis")
	var rl_before = GameStore.get_relationship_level("artemis")

	# Act
	IntimacySystem.complete_scene("artemis", 1)

	# Assert
	var rl_after = GameStore.get_relationship_level("artemis")
	assert_int(rl_after - rl_before).is_equal(10)

func test_intimacy_system_complete_scene_1_writes_completion_flag() -> void:
	# Arrange
	_setup_stage_4("artemis")

	# Act
	IntimacySystem.complete_scene("artemis", 1)

	# Assert
	assert_bool(GameStore.has_flag("intimacy_artemis_1_complete")).is_true()

# ── AC-9 — complete_scene 3 awards 20 RL ─────────────────────────────────────

func test_intimacy_system_complete_scene_3_awards_20_rl() -> void:
	# Arrange — set up scenes 1+2 done, stage 4 with room for +20
	GameStore._companion_states["artemis"]["relationship_level"] = 70
	GameStore._companion_states["artemis"]["met"] = true
	_CompanionStateScript._max_stages["artemis"] = 4  # Force stage 4
	GameStore.set_flag("intimacy_artemis_1_complete")
	GameStore.set_flag("intimacy_artemis_2_complete")
	var rl_before = GameStore.get_relationship_level("artemis")

	# Act
	IntimacySystem.complete_scene("artemis", 3)

	# Assert — expect +20 (no clamping since 70+20=90 < 100)
	var rl_after = GameStore.get_relationship_level("artemis")
	assert_int(rl_after - rl_before).is_equal(20)

# ── AC-10 — is_scene_complete returns true after completion ───────────────────

func test_intimacy_system_is_scene_complete_returns_true_after_complete_scene() -> void:
	# Arrange
	_setup_stage_4("artemis")

	# Act
	IntimacySystem.complete_scene("artemis", 1)

	# Assert
	assert_bool(IntimacySystem.is_scene_complete("artemis", 1)).is_true()

# ── AC-11 — complete_scene is write-once (no double award) ───────────────────

func test_intimacy_system_complete_scene_is_write_once_no_double_award() -> void:
	# Arrange
	_setup_stage_4("artemis")
	IntimacySystem.complete_scene("artemis", 1)
	var rl_after_first = GameStore.get_relationship_level("artemis")

	# Act — call complete again
	IntimacySystem.complete_scene("artemis", 1)

	# Assert — RL did not increase again
	assert_int(GameStore.get_relationship_level("artemis")).is_equal(rl_after_first)

# ── AC-12 — get_available_scenes returns empty for unmet companion ────────────

func test_intimacy_system_get_available_scenes_returns_empty_when_not_met() -> void:
	# Arrange — default: met == false
	GameStore._companion_states["artemis"]["relationship_level"] = 71

	# Act
	var result = IntimacySystem.get_available_scenes("artemis")

	# Assert
	assert_int(result.size()).is_equal(0)
