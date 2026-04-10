class_name EnemyValidationTest
extends GdUnitTestSuite

## Unit tests for STORY-ENEMY-002: Attack Derivation and Data Validation
##
## Covers all 7 Acceptance Criteria:
##   AC1 — gaia_spirit (hp=250, ratio=0.1) → attack = floor(250 * 0.1) = 25
##   AC2 — forest_monster (hp=40, ratio=0.1) → attack = floor(40 * 0.1) = 4
##   AC3 — _attack_ratio=0.15 overrides default, attack derived with 0.15
##   AC4 — score_threshold > hp is clamped to hp + push_warning
##   AC5 — hp <= 0 logs error + sets instant_victory = true
##   AC6 — invalid element defaults to null + push_warning
##   AC7 — valid score_threshold <= hp is NOT modified
##
## Test pattern: preload script, Script.new() without _ready().
## Call _validate_enemy(profile) directly after setting _attack_ratio on the
## instance — this avoids all file I/O and any dependency on enemies.json layout.
##
## See: docs/architecture/adr-0016-enemy-registry.md

# ── Constants ─────────────────────────────────────────────────────────────────

const EnemyRegistryScript = preload("res://src/autoloads/enemy_registry.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

## Creates a fresh EnemyRegistry node without running _ready().
## Callers set _attack_ratio manually before invoking _validate_enemy().
func _make_registry() -> Node:
	return EnemyRegistryScript.new()

## Returns a minimal profile Dictionary for use as _validate_enemy() input.
## All fields are caller-supplied so each test controls exactly what it needs.
func _make_profile(
	id: String,
	hp: int,
	score_threshold: int,
	element: Variant,
	enemy_type: String = "Normal"
) -> Dictionary:
	return {
		"id": id,
		"name_key": "ENEMY_" + id.to_upper(),
		"hp": hp,
		"score_threshold": score_threshold,
		"element": element,
		"type": enemy_type,
		"chapter": "chapter_test",
	}

# ── AC1 — gaia_spirit hp=250, ratio=0.1 → attack = 25 ───────────────────────

func test_enemy_validation_attack_derived_from_hp_250_with_default_ratio() -> void:
	# Arrange — hp=250, _attack_ratio=0.1, floor(250 * 0.1) = 25
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("gaia_spirit", 250, 130, "Earth", "Boss")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_int(result["attack"]).is_equal(25)

	registry.free()

func test_enemy_validation_attack_field_is_present_after_validation() -> void:
	# Arrange
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("gaia_spirit", 250, 130, "Earth", "Boss")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — attack key must exist on the validated profile
	assert_bool(result.has("attack")).is_true()

	registry.free()

func test_enemy_validation_attack_is_integer_type() -> void:
	# Arrange
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("gaia_spirit", 250, 130, "Earth", "Boss")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — floor() + int() cast produces TYPE_INT
	assert_int(typeof(result["attack"])).is_equal(TYPE_INT)

	registry.free()

# ── AC2 — forest_monster hp=40, ratio=0.1 → attack = 4 ──────────────────────

func test_enemy_validation_attack_derived_from_hp_40_with_default_ratio() -> void:
	# Arrange — hp=40, _attack_ratio=0.1, floor(40 * 0.1) = 4
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("forest_monster", 40, 40, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_int(result["attack"]).is_equal(4)

	registry.free()

func test_enemy_validation_attack_zero_for_hp_zero_with_default_ratio() -> void:
	# Arrange — hp=0 is data error; attack derivation still runs (floor(0 * 0.1) = 0)
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("bad_enemy", 0, 0, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — attack is 0 (hp is 0, instant_victory is set separately)
	assert_int(result["attack"]).is_equal(0)

	registry.free()

# ── AC3 — _attack_ratio=0.15 overrides default 0.1 ──────────────────────────

func test_enemy_validation_custom_ratio_0_15_applied_to_hp_100() -> void:
	# Arrange — hp=100, ratio=0.15, floor(100 * 0.15) = 15
	var registry = _make_registry()
	registry._attack_ratio = 0.15
	var profile: Dictionary = _make_profile("test_enemy", 100, 80, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — 15, not the default-ratio result of 10
	assert_int(result["attack"]).is_equal(15)

	registry.free()

func test_enemy_validation_custom_ratio_result_differs_from_default_ratio_result() -> void:
	# Arrange — with ratio=0.1, hp=100 → attack=10; with ratio=0.15 → attack=15
	var registry = _make_registry()
	registry._attack_ratio = 0.15
	var profile: Dictionary = _make_profile("test_enemy", 100, 80, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — must NOT equal the default-ratio result
	assert_int(result["attack"]).is_not_equal(10)

	registry.free()

func test_enemy_validation_custom_ratio_0_20_applied_to_hp_250() -> void:
	# Arrange — hp=250, ratio=0.20, floor(250 * 0.20) = 50
	var registry = _make_registry()
	registry._attack_ratio = 0.20
	var profile: Dictionary = _make_profile("gaia_spirit", 250, 130, "Earth", "Boss")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_int(result["attack"]).is_equal(50)

	registry.free()

# ── AC4 — score_threshold > hp is clamped to hp ──────────────────────────────

func test_enemy_validation_score_threshold_clamped_when_exceeds_hp() -> void:
	# Arrange — score_threshold=300 > hp=250, expect clamp to 250
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("gaia_spirit", 250, 300, "Earth", "Boss")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_int(result["score_threshold"]).is_equal(250)

	registry.free()

func test_enemy_validation_score_threshold_far_above_hp_clamped_to_hp() -> void:
	# Arrange — pathological: score_threshold=9999 >> hp=80
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("test_enemy", 80, 9999, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — clamped value must equal hp exactly
	assert_int(result["score_threshold"]).is_equal(80)

	registry.free()

func test_enemy_validation_clamped_score_threshold_does_not_exceed_hp() -> void:
	# Arrange
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("test_enemy", 100, 500, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — invariant: stored threshold must always be <= hp
	assert_bool(result["score_threshold"] <= result["hp"]).is_true()

	registry.free()

# ── AC5 — hp <= 0 logs error + instant_victory = true ────────────────────────

func test_enemy_validation_hp_zero_sets_instant_victory_true() -> void:
	# Arrange — hp=0 is a data error
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("bad_enemy", 0, 0, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_bool(result["instant_victory"]).is_true()

	registry.free()

func test_enemy_validation_hp_negative_sets_instant_victory_true() -> void:
	# Arrange — hp=-10 is also a data error
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	# Build profile manually since _make_profile takes int; negative is valid GDScript
	var profile: Dictionary = {
		"id": "bad_enemy",
		"name_key": "ENEMY_BAD_ENEMY",
		"hp": -10,
		"score_threshold": 0,
		"element": null,
		"type": "Normal",
		"chapter": "chapter_test",
	}

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_bool(result["instant_victory"]).is_true()

	registry.free()

func test_enemy_validation_positive_hp_does_not_set_instant_victory() -> void:
	# Arrange — valid hp=100
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("good_enemy", 100, 80, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_bool(result["instant_victory"]).is_false()

	registry.free()

func test_enemy_validation_instant_victory_field_always_present() -> void:
	# Arrange — verify the field is set on every validated profile, not just error ones
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("good_enemy", 100, 80, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_bool(result.has("instant_victory")).is_true()

	registry.free()

# ── AC6 — invalid element defaults to null ────────────────────────────────────

func test_enemy_validation_invalid_element_string_defaults_to_null() -> void:
	# Arrange — "InvalidElement" is not in VALID_ELEMENTS
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("test_enemy", 100, 80, "InvalidElement", "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_object(result["element"]).is_null()

	registry.free()

func test_enemy_validation_arbitrary_bad_element_defaults_to_null() -> void:
	# Arrange — "Plasma" is not a valid element
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("test_enemy", 100, 80, "Plasma", "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_object(result["element"]).is_null()

	registry.free()

func test_enemy_validation_valid_element_fire_is_preserved() -> void:
	# Arrange — "Fire" is a member of VALID_ELEMENTS
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("test_enemy", 100, 80, "Fire", "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — valid element must not be nullified
	assert_str(result["element"]).is_equal("Fire")

	registry.free()

func test_enemy_validation_null_element_is_preserved_as_null() -> void:
	# Arrange — null is the explicit "no element" value and must not be changed
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("mountain_beast", 80, 50, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_object(result["element"]).is_null()

	registry.free()

# ── AC7 — valid score_threshold <= hp is NOT modified ────────────────────────

func test_enemy_validation_score_threshold_below_hp_is_unchanged() -> void:
	# Arrange — score_threshold=50 < hp=80: no clamp should occur
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("mountain_beast", 80, 50, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — stored value must remain 50, unchanged
	assert_int(result["score_threshold"]).is_equal(50)

	registry.free()

func test_enemy_validation_score_threshold_equal_to_hp_is_unchanged() -> void:
	# Arrange — score_threshold=250 == hp=250: boundary value, not an error
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("gaia_spirit", 250, 250, "Earth", "Boss")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert — equal-to-hp is valid, must not be altered
	assert_int(result["score_threshold"]).is_equal(250)

	registry.free()

func test_enemy_validation_score_threshold_zero_is_valid_and_unchanged() -> void:
	# Arrange — score_threshold=0 < hp=100: valid edge case (no threshold required)
	var registry = _make_registry()
	registry._attack_ratio = 0.1
	var profile: Dictionary = _make_profile("test_enemy", 100, 0, null, "Normal")

	# Act
	var result: Dictionary = registry._validate_enemy(profile)

	# Assert
	assert_int(result["score_threshold"]).is_equal(0)

	registry.free()
