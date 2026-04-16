class_name OracleTest
extends GdUnitTestSuite

## Unit tests for Oracle — companion gacha pure logic.
##
## Covers AC-ORACLE-01 through AC-ORACLE-09 from
## design/quick-specs/oracle-gacha.md. UI coverage (AC-10) is deferred
## to the Oracle scene tests in a later phase.

const OracleScript = preload("res://systems/gacha/oracle.gd")


# ── Helpers ──────────────────────────────────────────────────────────────────

func _make_oracle_with_seed(seed_value: int) -> Oracle:
	var oracle: Oracle = OracleScript.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	oracle.set_rng(rng)
	return oracle


func _empty_epithets() -> Dictionary:
	return {"artemis": 0, "hipolita": 0, "atenea": 0, "nyx": 0}


func _empty_shards() -> Dictionary:
	return {"artemis": 0, "hipolita": 0, "atenea": 0, "nyx": 0}


# ── Cost validation (AC-ORACLE-02 + AC-ORACLE-03) ────────────────────────────

func test_oracle_can_single_pull_requires_gold_and_cap_headroom() -> void:
	# Arrange
	var oracle: Oracle = _make_oracle_with_seed(1)

	# Act + Assert — happy path
	assert_bool(oracle.can_single_pull(25, 0)).is_true()
	# Insufficient gold
	assert_bool(oracle.can_single_pull(24, 0)).is_false()
	# Weekly cap exhausted
	assert_bool(oracle.can_single_pull(999, 30)).is_false()


func test_oracle_can_ten_pull_is_atomic_on_cap_boundary() -> void:
	# Arrange
	var oracle: Oracle = _make_oracle_with_seed(1)

	# Act + Assert — 20 pulls used leaves 10 headroom, exactly enough
	assert_bool(oracle.can_ten_pull(220, 20)).is_true()
	# 21 used leaves only 9 — rejected
	assert_bool(oracle.can_ten_pull(220, 21)).is_false()
	# Gold short — rejected
	assert_bool(oracle.can_ten_pull(219, 0)).is_false()


# ── Roll outcome (AC-ORACLE-01 + AC-ORACLE-08) ───────────────────────────────

func test_oracle_roll_single_returns_at_least_one_shard() -> void:
	# Arrange
	var oracle: Oracle = _make_oracle_with_seed(42)

	# Act
	var result: Dictionary = oracle.roll_single(_empty_epithets())

	# Assert — every roll grants a positive count
	assert_int(int(result.get("shards", 0))).is_greater(0)
	# goddess field is set unless the legendary player_pick rolled
	var player_pick: bool = bool(result.get("player_pick", false))
	if not player_pick:
		assert_str(result.get("goddess", "") as String).is_not_equal("")


func test_oracle_roll_single_distribution_matches_config_within_tolerance() -> void:
	# Arrange — 1000 rolls with a seeded RNG
	var oracle: Oracle = _make_oracle_with_seed(12345)
	var shard_counts: Dictionary = {1: 0, 2: 0, 3: 0, 5: 0}

	# Act
	for i: int in range(1000):
		var result: Dictionary = oracle.roll_single(_empty_epithets())
		var count: int = int(result.get("shards", 0))
		shard_counts[count] = int(shard_counts.get(count, 0)) + 1

	# Assert — within ±5% of the 60/30/9/1 outcome table
	var c1: float = float(shard_counts[1]) / 1000.0
	var c2: float = float(shard_counts[2]) / 1000.0
	var c3: float = float(shard_counts[3]) / 1000.0
	var c5: float = float(shard_counts[5]) / 1000.0
	assert_float(c1).is_between(0.55, 0.65)
	assert_float(c2).is_between(0.25, 0.35)
	assert_float(c3).is_between(0.04, 0.14)
	assert_float(c5).is_between(0.0, 0.03)


# ── Weighted goddess pick (AC-ORACLE-09) ─────────────────────────────────────

func test_oracle_weighted_pick_favors_lowest_epithet_goddess() -> void:
	# Arrange — Atenea at tier 0, all others at tier 5. With weights
	# [4, 3, 3, 2, 2, 1, 0.25], Atenea has weight 4 and the others each
	# have weight 1. Over 500 rolls Atenea should land ~80% of the time.
	var oracle: Oracle = _make_oracle_with_seed(77)
	var epithets: Dictionary = {
		"artemis": 5, "hipolita": 5, "atenea": 0, "nyx": 5,
	}
	var counts: Dictionary = {}

	# Act
	for i: int in range(500):
		var result: Dictionary = oracle.roll_single(epithets)
		if bool(result.get("player_pick", false)):
			continue  # skip legendary rows for this test
		var id: String = result.get("goddess", "") as String
		counts[id] = int(counts.get(id, 0)) + 1

	# Assert — Atenea should be the majority pick by a wide margin.
	# 4 / (4+1+1+1) = 57% expected, but with RNG variance we only need
	# Atenea to have more picks than any other goddess.
	var atenea_count: int = int(counts.get("atenea", 0))
	var max_other: int = 0
	for id: String in ["artemis", "hipolita", "nyx"]:
		max_other = maxi(max_other, int(counts.get(id, 0)))
	assert_int(atenea_count).is_greater(max_other)


# ── Apply result — Epithet unlocks (AC-ORACLE-04) ────────────────────────────

func test_oracle_apply_result_unlocks_epithet_one_at_five_shards() -> void:
	# Arrange
	var oracle: Oracle = _make_oracle_with_seed(1)
	var shards: Dictionary = _empty_shards()
	var epithets: Dictionary = _empty_epithets()
	var roll: Dictionary = {"shards": 5, "player_pick": false, "goddess": "atenea"}

	# Act
	var diff: Dictionary = oracle.apply_result(roll, shards, epithets)

	# Assert
	var new_shards: Dictionary = diff["shards"] as Dictionary
	var new_epithets: Dictionary = diff["epithets"] as Dictionary
	assert_int(int(new_shards.get("atenea", -1))).is_equal(0)  # 5 spent on unlock
	assert_int(int(new_epithets.get("atenea", -1))).is_equal(1)
	var unlocked: Array = diff["unlocked"] as Array
	assert_int(unlocked.size()).is_equal(1)
	assert_str(unlocked[0] as String).is_equal("atenea")


func test_oracle_apply_result_cascades_multiple_tiers_on_big_grant() -> void:
	# Arrange — 20 shards is exactly the cumulative cost for tier 4
	# (5 + 3 + 5 + 7 = 20). A single massive grant should cascade all
	# four tiers in one apply.
	var oracle: Oracle = _make_oracle_with_seed(1)
	var shards: Dictionary = _empty_shards()
	var epithets: Dictionary = _empty_epithets()
	var roll: Dictionary = {"shards": 20, "player_pick": false, "goddess": "artemis"}

	# Act
	var diff: Dictionary = oracle.apply_result(roll, shards, epithets)

	# Assert
	var new_epithets: Dictionary = diff["epithets"] as Dictionary
	assert_int(int(new_epithets.get("artemis", -1))).is_equal(4)
	var promoted: Array = diff["promoted"] as Array
	assert_int(promoted.size()).is_equal(4)


# ── Apply result — Epithet VI refund (AC-ORACLE-05) ──────────────────────────

func test_oracle_apply_result_refunds_gold_after_epithet_vi() -> void:
	# Arrange — goddess already at tier 6, player rolls a 3-shard result
	var oracle: Oracle = _make_oracle_with_seed(1)
	var shards: Dictionary = _empty_shards()
	var epithets: Dictionary = {"artemis": 0, "hipolita": 0, "atenea": 0, "nyx": 6}
	var roll: Dictionary = {"shards": 3, "player_pick": false, "goddess": "nyx"}

	# Act
	var diff: Dictionary = oracle.apply_result(roll, shards, epithets)

	# Assert — shards zeroed, tier still 6, refund = 3 × 15 = 45 gold
	var new_shards: Dictionary = diff["shards"] as Dictionary
	var new_epithets: Dictionary = diff["epithets"] as Dictionary
	assert_int(int(new_shards.get("nyx", -1))).is_equal(0)
	assert_int(int(new_epithets.get("nyx", -1))).is_equal(6)
	assert_int(int(diff.get("refund_gold", 0))).is_equal(45)


func test_oracle_apply_result_partial_progress_accumulates() -> void:
	# Arrange — 3 shards is below the 5-shard unlock threshold, so they
	# just accumulate toward Epithet I without promoting.
	var oracle: Oracle = _make_oracle_with_seed(1)
	var shards: Dictionary = _empty_shards()
	var epithets: Dictionary = _empty_epithets()
	var roll: Dictionary = {"shards": 3, "player_pick": false, "goddess": "hipolita"}

	# Act
	var diff: Dictionary = oracle.apply_result(roll, shards, epithets)

	# Assert
	assert_int(int((diff["shards"] as Dictionary).get("hipolita", -1))).is_equal(3)
	assert_int(int((diff["epithets"] as Dictionary).get("hipolita", -1))).is_equal(0)
	assert_int((diff["unlocked"] as Array).size()).is_equal(0)


# ── Player pick override ─────────────────────────────────────────────────────

func test_oracle_apply_result_honors_override_goddess_for_player_pick() -> void:
	# Arrange — legendary row leaves goddess empty, UI picks Nyx
	var oracle: Oracle = _make_oracle_with_seed(1)
	var roll: Dictionary = {"shards": 5, "player_pick": true, "goddess": ""}

	# Act
	var diff: Dictionary = oracle.apply_result(
		roll, _empty_shards(), _empty_epithets(), "nyx"
	)

	# Assert
	assert_int(int((diff["epithets"] as Dictionary).get("nyx", -1))).is_equal(1)


# ── Ten-pull bonus ───────────────────────────────────────────────────────────

func test_oracle_roll_ten_returns_eleven_results_with_bonus() -> void:
	# Arrange
	var oracle: Oracle = _make_oracle_with_seed(99)

	# Act
	var results: Array[Dictionary] = oracle.roll_ten(_empty_epithets())

	# Assert — 10 rolls + 1 guaranteed bonus
	assert_int(results.size()).is_equal(11)
	# Last entry is the bonus (rarity_index == -1)
	var bonus: Dictionary = results[10]
	assert_int(int(bonus.get("rarity_index", 0))).is_equal(-1)
	assert_int(int(bonus.get("shards", 0))).is_equal(1)
