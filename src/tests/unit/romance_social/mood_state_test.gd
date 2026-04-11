class_name MoodStateTest
extends GdUnitTestSuite

## Unit tests for STORY-RS-004: Mood State Machine — Transitions, Priority, and Expiry
##
## Covers:
##   AC1 — Content + Talk succeeds → mood transitions to Happy
##   AC2 — mood_expiry_date in the past → decays to Content
##   AC3 — priority resolution: Excited > Happy > Annoyed > Lonely > Content
##   AC4 — mood durations come from config, not hardcoded
##   AC5 — get_mood(id) returns the current mood enum value
##
## See: docs/architecture/adr-0010-romance-social.md

const _RSScript = preload("res://autoloads/romance_social.gd")

var rs: Node

func before_test() -> void:
	GameStore._initialize_defaults()
	CompanionState._max_stages.clear()
	rs = _RSScript.new()
	rs._load_config()
	# Mark artemis as met so interactions work.
	GameStore.set_met("artemis", true)

func after_test() -> void:
	rs.free()

# ── AC1 — Content + successful Talk → Happy ───────────────────────────────────

func test_mood_state_talk_from_content_transitions_to_happy() -> void:
	# Arrange — mood = Content (0), tokens available
	GameStore.set_mood("artemis", rs.Mood.CONTENT, "")
	assert_int(GameStore.get_mood("artemis")).is_equal(rs.Mood.CONTENT)

	# Act
	var result: Dictionary = rs.do_talk("artemis")

	# Assert — success and new mood is Happy
	assert_bool(result.get("success", false)).is_true()
	assert_int(GameStore.get_mood("artemis")).is_equal(rs.Mood.HAPPY)

# ── AC2 — expired mood decays to Content ─────────────────────────────────────

func test_mood_state_expired_mood_decays_to_content() -> void:
	# Arrange — set Happy mood with past expiry
	GameStore.set_mood("artemis", rs.Mood.HAPPY, "2020-01-01")

	# Act — get_mood triggers decay check
	var mood: int = rs.get_mood("artemis")

	# Assert
	assert_int(mood).is_equal(rs.Mood.CONTENT)

func test_mood_state_non_expired_mood_is_retained() -> void:
	# Arrange — set Happy mood with future expiry
	GameStore.set_mood("artemis", rs.Mood.HAPPY, "2099-12-31")

	# Act
	var mood: int = rs.get_mood("artemis")

	# Assert
	assert_int(mood).is_equal(rs.Mood.HAPPY)

# ── AC3 — priority resolution ────────────────────────────────────────────────

func test_mood_state_priority_excited_beats_happy() -> void:
	# Arrange
	var moods: Array[int] = [rs.Mood.HAPPY, rs.Mood.EXCITED]

	# Act
	var winner: int = rs._resolve_mood_priority(moods)

	# Assert
	assert_int(winner).is_equal(rs.Mood.EXCITED)

func test_mood_state_priority_annoyed_beats_lonely() -> void:
	# Arrange
	var moods: Array[int] = [rs.Mood.LONELY, rs.Mood.ANNOYED]

	# Act
	var winner: int = rs._resolve_mood_priority(moods)

	# Assert
	assert_int(winner).is_equal(rs.Mood.ANNOYED)

func test_mood_state_priority_happy_beats_annoyed() -> void:
	# Arrange
	var moods: Array[int] = [rs.Mood.ANNOYED, rs.Mood.HAPPY]

	# Act
	var winner: int = rs._resolve_mood_priority(moods)

	# Assert
	assert_int(winner).is_equal(rs.Mood.HAPPY)

# ── AC4 — durations from config ──────────────────────────────────────────────

func test_mood_state_config_contains_mood_durations() -> void:
	# Arrange / Act
	var durations: Dictionary = rs._config.get("mood_durations_days", {})

	# Assert — config loaded and has entries
	assert_bool(durations.is_empty()).is_false()

# ── AC5 — get_mood returns current enum value ─────────────────────────────────

func test_mood_state_get_mood_returns_correct_enum_value() -> void:
	# Arrange — set Excited mood with future expiry
	GameStore.set_mood("artemis", rs.Mood.EXCITED, "2099-12-31")

	# Act
	var mood: int = rs.get_mood("artemis")

	# Assert
	assert_int(mood).is_equal(rs.Mood.EXCITED)
