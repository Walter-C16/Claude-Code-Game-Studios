class_name HapticManagerTest
extends GdUnitTestSuite

# Unit tests for STORY UT-006: Haptic Feedback System
#
# Covers:
#   AC1 — LIGHT_MS constant is 15
#   AC2 — MEDIUM_MS constant is 30
#   AC3 — HEAVY_MS constant is 50
#   AC4 — Static methods are callable without error on all platforms
#
# Note: Actual device vibration cannot be verified in headless CI.
# These tests confirm constants match spec and methods do not throw errors.

# ---------------------------------------------------------------------------
# AC1 — LIGHT_MS constant equals 15
# ---------------------------------------------------------------------------

func test_haptic_manager_light_ms_constant_is_15() -> void:
	# Arrange / Act
	var value: int = HapticManager.LIGHT_MS

	# Assert
	assert_int(value).is_equal(15)

# ---------------------------------------------------------------------------
# AC2 — MEDIUM_MS constant equals 30
# ---------------------------------------------------------------------------

func test_haptic_manager_medium_ms_constant_is_30() -> void:
	# Arrange / Act
	var value: int = HapticManager.MEDIUM_MS

	# Assert
	assert_int(value).is_equal(30)

# ---------------------------------------------------------------------------
# AC3 — HEAVY_MS constant equals 50
# ---------------------------------------------------------------------------

func test_haptic_manager_heavy_ms_constant_is_50() -> void:
	# Arrange / Act
	var value: int = HapticManager.HEAVY_MS

	# Assert
	assert_int(value).is_equal(50)

# ---------------------------------------------------------------------------
# AC4 — Static methods callable without error (platform-agnostic)
# ---------------------------------------------------------------------------

func test_haptic_manager_light_callable_without_error() -> void:
	# Arrange — confirm method exists
	# Static method — callable directly

	# Act — must not raise an error on any platform including headless CI
	HapticManager.light()

	# Assert — reaching this line means no crash or script error occurred
	assert_bool(true).is_true()

func test_haptic_manager_medium_callable_without_error() -> void:
	# Arrange
	# Static method — callable directly

	# Act
	HapticManager.medium()

	# Assert
	assert_bool(true).is_true()

func test_haptic_manager_heavy_callable_without_error() -> void:
	# Arrange
	# Static method — callable directly

	# Act
	HapticManager.heavy()

	# Assert
	assert_bool(true).is_true()

# ---------------------------------------------------------------------------
# Constant ordering sanity check
# ---------------------------------------------------------------------------

func test_haptic_manager_constants_ordered_light_lt_medium_lt_heavy() -> void:
	# Assert — durations must be in strictly ascending order
	assert_bool(HapticManager.LIGHT_MS < HapticManager.MEDIUM_MS).is_true()
	assert_bool(HapticManager.MEDIUM_MS < HapticManager.HEAVY_MS).is_true()
