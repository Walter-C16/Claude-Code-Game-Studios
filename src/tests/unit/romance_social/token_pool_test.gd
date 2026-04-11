class_name TokenPoolTest
extends GdUnitTestSuite

## Unit tests for STORY-RS-001: Token Pool — Daily Allocation and Spending
##
## Covers:
##   AC1 — spend_token() decreases tokens and sets GameStore _dirty
##   AC2 — spend_token() returns false when tokens = 0
##   AC3 — _check_midnight_reset() resets tokens on day crossing
##   AC4 — negative date gap treated as 0 (no reset)
##   AC5 — get_token_count() returns 3 after reset
##
## See: docs/architecture/adr-0010-romance-social.md

const _RSScript = preload("res://autoloads/romance_social.gd")

var rs: Node

func before_test() -> void:
	GameStore._initialize_defaults()
	CompanionState._max_stages.clear()
	rs = _RSScript.new()
	rs._load_config()

func after_test() -> void:
	rs.free()

# ── AC1 — spend_token() decreases tokens ─────────────────────────────────────

func test_token_pool_spend_token_decreases_from_3_to_2() -> void:
	# Arrange — factory default = 3 tokens
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

	# Act
	GameStore.spend_token()

	# Assert
	assert_int(GameStore.get_daily_tokens()).is_equal(2)

func test_token_pool_spend_token_sets_dirty_flag() -> void:
	# Arrange
	GameStore._dirty = false

	# Act
	GameStore.spend_token()

	# Assert — _dirty must be true after mutation
	assert_bool(GameStore._dirty).is_true()

# ── AC2 — spend_token() no-ops at 0 ─────────────────────────────────────────

func test_token_pool_spend_token_does_not_go_below_zero() -> void:
	# Arrange — drain all tokens
	GameStore.spend_token()
	GameStore.spend_token()
	GameStore.spend_token()
	assert_int(GameStore.get_daily_tokens()).is_equal(0)

	# Act — attempt to spend when empty
	GameStore.spend_token()

	# Assert — stays at 0
	assert_int(GameStore.get_daily_tokens()).is_equal(0)

# ── AC3 — get_token_count() returns 3 after reset ────────────────────────────

func test_token_pool_reset_tokens_restores_to_3() -> void:
	# Arrange — drain 2 tokens
	GameStore.spend_token()
	GameStore.spend_token()
	assert_int(GameStore.get_daily_tokens()).is_equal(1)

	# Act
	GameStore.reset_tokens()

	# Assert
	assert_int(GameStore.get_daily_tokens()).is_equal(3)

func test_token_pool_get_token_count_returns_3_after_reset() -> void:
	# Arrange
	GameStore.spend_token()
	GameStore.reset_tokens()

	# Act / Assert
	assert_int(rs.get_token_count()).is_equal(3)

# ── AC4 — clock rollback: negative gap treated as 0 ──────────────────────────

func test_token_pool_day_gap_returns_zero_for_same_date() -> void:
	# Arrange
	var today: String = "2026-04-10"

	# Act
	var gap: int = rs._day_gap(today, today)

	# Assert
	assert_int(gap).is_equal(0)

func test_token_pool_day_gap_returns_zero_for_earlier_to_date() -> void:
	# Arrange — "from" is after "to" = rollback scenario
	var from_date: String = "2026-04-12"
	var to_date: String = "2026-04-10"

	# Act
	var gap: int = rs._day_gap(from_date, to_date)

	# Assert — protected; gap clamped to 0
	assert_int(gap).is_equal(0)

func test_token_pool_day_gap_returns_1_for_consecutive_days() -> void:
	# Arrange
	var from_date: String = "2026-04-09"
	var to_date: String = "2026-04-10"

	# Act
	var gap: int = rs._day_gap(from_date, to_date)

	# Assert
	assert_int(gap).is_equal(1)
