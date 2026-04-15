class_name BattleTurnTimerTest
extends GdUnitTestSuite

## Unit tests for BattleTurnTimer — pure-logic per-turn countdown.
##
## Covers:
##   start(seconds) arms the timer and sets time_remaining
##   start(0) and start(negative) leave the timer disabled
##   tick(delta) decrements time_remaining while enabled
##   tick is a no-op when disabled
##   tick is a no-op for a non-positive delta
##   expired signal fires exactly once when time reaches zero
##   reset() clears state and re-arms with start()
##   is_expired returns true after expiry, false after reset

const BattleTurnTimerScript = preload("res://systems/battle/battle_turn_timer.gd")


# ── start ────────────────────────────────────────────────────────────────────

func test_battle_turn_timer_start_arms_timer_with_positive_seconds() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()

	# Act
	t.start(60.0)

	# Assert
	assert_bool(t.enabled).is_true()
	assert_float(t.time_remaining).is_equal_approx(60.0, 0.01)


func test_battle_turn_timer_start_with_zero_leaves_disabled() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()

	# Act
	t.start(0.0)

	# Assert
	assert_bool(t.enabled).is_false()
	assert_float(t.time_remaining).is_equal_approx(0.0, 0.01)


func test_battle_turn_timer_start_with_negative_seconds_leaves_disabled() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()

	# Act
	t.start(-5.0)

	# Assert
	assert_bool(t.enabled).is_false()
	assert_float(t.time_remaining).is_equal_approx(0.0, 0.01)


# ── tick ─────────────────────────────────────────────────────────────────────

func test_battle_turn_timer_tick_decrements_time_remaining() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()
	t.start(10.0)

	# Act
	t.tick(2.5)

	# Assert
	assert_float(t.time_remaining).is_equal_approx(7.5, 0.01)
	assert_bool(t.enabled).is_true()


func test_battle_turn_timer_tick_when_disabled_is_noop() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()
	# Don't call start — timer stays disabled.

	# Act
	t.tick(5.0)

	# Assert
	assert_float(t.time_remaining).is_equal_approx(0.0, 0.01)
	assert_bool(t.enabled).is_false()


func test_battle_turn_timer_tick_with_non_positive_delta_is_noop() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()
	t.start(10.0)

	# Act
	t.tick(0.0)
	t.tick(-1.0)

	# Assert
	assert_float(t.time_remaining).is_equal_approx(10.0, 0.01)


# ── expiry ───────────────────────────────────────────────────────────────────

func test_battle_turn_timer_expired_signal_fires_once_on_timeout() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()
	t.start(2.0)
	var fire_count: Array = [0]
	t.expired.connect(func() -> void: fire_count[0] += 1)

	# Act — tick past zero in two steps, then tick again to confirm latch
	t.tick(1.5)
	t.tick(0.6)  # crosses zero
	t.tick(1.0)  # should NOT fire again

	# Assert
	assert_int(fire_count[0]).is_equal(1)
	assert_bool(t.enabled).is_false()
	assert_float(t.time_remaining).is_equal_approx(0.0, 0.01)


func test_battle_turn_timer_is_expired_returns_true_after_timeout() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()
	t.start(1.0)

	# Act
	t.tick(1.5)

	# Assert
	assert_bool(t.is_expired()).is_true()


# ── reset ────────────────────────────────────────────────────────────────────

func test_battle_turn_timer_reset_clears_state() -> void:
	# Arrange
	var t = BattleTurnTimerScript.new()
	t.start(30.0)
	t.tick(5.0)

	# Act
	t.reset()

	# Assert
	assert_bool(t.enabled).is_false()
	assert_float(t.time_remaining).is_equal_approx(0.0, 0.01)


func test_battle_turn_timer_reset_then_start_re_arms() -> void:
	# Arrange — fully expire the timer first
	var t = BattleTurnTimerScript.new()
	t.start(1.0)
	t.tick(2.0)
	assert_bool(t.is_expired()).is_true()

	# Act
	t.reset()
	t.start(15.0)

	# Assert
	assert_bool(t.enabled).is_true()
	assert_float(t.time_remaining).is_equal_approx(15.0, 0.01)
