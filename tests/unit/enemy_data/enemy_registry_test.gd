class_name EnemyRegistryTest
extends GdUnitTestSuite

## Unit tests for STORY-ENEMY-001: EnemyRegistry Autoload — Static Profile Loading
##
## Covers all 8 Acceptance Criteria:
##   AC1 — All 4 Chapter 1 enemies load from enemies.json
##   AC2 — get_enemy("mountain_beast") returns correct full profile
##   AC3 — get_enemy("amazon_challenger") has element="Fire" and type="Duel"
##   AC4 — get_enemy("cronos") returns empty Dictionary (no crash)
##   AC5 — get_all_ids() returns Array[String] of all registered enemy IDs
##   AC6 — get_enemies_by_chapter("chapter_1") returns exactly 4 profiles
##   AC7 — get_enemy() completes within 1ms for any registered enemy
##   AC8 — type field stored as the type constant string value, not raw JSON literal
##
## Test pattern: preload script, Script.new() without _ready(), call _load_enemies()
## manually so tests control the data path and avoid autoload singletons.
##
## See: docs/architecture/adr-0016-enemy-registry.md

# ── Constants ─────────────────────────────────────────────────────────────────

const EnemyRegistryScript = preload("res://src/autoloads/enemy_registry.gd")

## Chapter 1 enemy IDs that must be present after loading enemies.json.
const CHAPTER_1_IDS: Array[String] = [
	"forest_monster",
	"mountain_beast",
	"amazon_challenger",
	"gaia_spirit"
]

# ── Helpers ───────────────────────────────────────────────────────────────────

## Creates a fresh EnemyRegistry node without running _ready().
## Callers must invoke _load_enemies() if they need the registry populated.
func _make_registry() -> Node:
	return EnemyRegistryScript.new()

## Creates a registry with enemies.json already loaded.
func _make_loaded_registry() -> Node:
	var registry = _make_registry()
	registry._load_enemies()
	return registry

# ── AC1 — All Chapter 1 enemies load ─────────────────────────────────────────

func test_enemy_registry_load_forest_monster_is_registered() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("forest_monster")

	# Assert
	assert_bool(profile.is_empty()).is_false()
	registry.free()

func test_enemy_registry_load_mountain_beast_is_registered() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_bool(profile.is_empty()).is_false()
	registry.free()

func test_enemy_registry_load_amazon_challenger_is_registered() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("amazon_challenger")

	# Assert
	assert_bool(profile.is_empty()).is_false()
	registry.free()

func test_enemy_registry_load_gaia_spirit_is_registered() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("gaia_spirit")

	# Assert
	assert_bool(profile.is_empty()).is_false()
	registry.free()

func test_enemy_registry_load_all_four_chapter1_enemies_present() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act / Assert — all 4 Chapter 1 IDs must be registered
	for id: String in CHAPTER_1_IDS:
		assert_bool(registry.has_enemy(id)).is_true()
	registry.free()

# ── AC2 — mountain_beast profile fields are correct ──────────────────────────

func test_enemy_registry_mountain_beast_id_is_correct() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_str(profile["id"]).is_equal("mountain_beast")
	registry.free()

func test_enemy_registry_mountain_beast_hp_is_80() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_int(profile["hp"]).is_equal(80)
	registry.free()

func test_enemy_registry_mountain_beast_score_threshold_is_50() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_int(profile["score_threshold"]).is_equal(50)
	registry.free()

func test_enemy_registry_mountain_beast_element_is_null() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_object(profile["element"]).is_null()
	registry.free()

func test_enemy_registry_mountain_beast_type_is_normal() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_str(profile["type"]).is_equal("Normal")
	registry.free()

func test_enemy_registry_mountain_beast_name_key_is_correct() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("mountain_beast")

	# Assert
	assert_str(profile["name_key"]).is_equal("ENEMY_MOUNTAIN_BEAST")
	registry.free()

# ── AC3 — amazon_challenger has element=Fire and type=Duel ───────────────────

func test_enemy_registry_amazon_challenger_element_is_fire() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("amazon_challenger")

	# Assert
	assert_str(profile["element"]).is_equal("Fire")
	registry.free()

func test_enemy_registry_amazon_challenger_type_is_duel() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("amazon_challenger")

	# Assert
	assert_str(profile["type"]).is_equal("Duel")
	registry.free()

# ── AC4 — Unknown enemy ID returns empty Dictionary without crash ─────────────

func test_enemy_registry_unknown_id_returns_empty_dict() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("cronos")

	# Assert
	assert_bool(profile.is_empty()).is_true()
	registry.free()

func test_enemy_registry_unknown_id_result_is_dictionary_type() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var result: Dictionary = registry.get_enemy("cronos")

	# Assert — return type is always Dictionary, never null
	assert_bool(result is Dictionary).is_true()
	registry.free()

func test_enemy_registry_unknown_id_does_not_crash() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act — must not throw or cause an error
	var _profile: Dictionary = registry.get_enemy("completely_unknown_id_xyz")

	# Assert — reaching this line means no crash occurred
	assert_bool(true).is_true()
	registry.free()

# ── AC5 — get_all_ids() returns Array[String] of all registered IDs ───────────

func test_enemy_registry_get_all_ids_returns_nonempty_array() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var ids: Array[String] = registry.get_all_ids()

	# Assert
	assert_array(ids).is_not_empty()
	registry.free()

func test_enemy_registry_get_all_ids_contains_forest_monster() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var ids: Array[String] = registry.get_all_ids()

	# Assert
	assert_array(ids).contains(["forest_monster"])
	registry.free()

func test_enemy_registry_get_all_ids_contains_all_chapter1_ids() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var ids: Array[String] = registry.get_all_ids()

	# Assert — all 4 Chapter 1 IDs must be in the result
	for id: String in CHAPTER_1_IDS:
		assert_array(ids).contains([id])
	registry.free()

func test_enemy_registry_get_all_ids_returns_string_elements() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var ids: Array[String] = registry.get_all_ids()

	# Assert — every element is a non-empty String
	for id: String in ids:
		assert_str(id).is_not_empty()
	registry.free()

# ── AC6 — get_enemies_by_chapter("chapter_1") returns exactly 4 profiles ──────

func test_enemy_registry_chapter1_returns_exactly_four_profiles() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profiles: Array[Dictionary] = registry.get_enemies_by_chapter("chapter_1")

	# Assert
	assert_int(profiles.size()).is_equal(4)
	registry.free()

func test_enemy_registry_chapter1_all_profiles_have_correct_chapter_field() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profiles: Array[Dictionary] = registry.get_enemies_by_chapter("chapter_1")

	# Assert — every returned profile must have chapter="chapter_1"
	for profile: Dictionary in profiles:
		assert_str(profile.get("chapter", "")).is_equal("chapter_1")
	registry.free()

func test_enemy_registry_unknown_chapter_returns_empty_array() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profiles: Array[Dictionary] = registry.get_enemies_by_chapter("chapter_99")

	# Assert
	assert_array(profiles).is_empty()
	registry.free()

func test_enemy_registry_chapter1_contains_gaia_spirit() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profiles: Array[Dictionary] = registry.get_enemies_by_chapter("chapter_1")
	var ids: Array[String] = []
	for p: Dictionary in profiles:
		ids.append(p.get("id", ""))

	# Assert
	assert_array(ids).contains(["gaia_spirit"])
	registry.free()

# ── AC7 — get_enemy() completes within 1ms for any registered enemy ───────────

func test_enemy_registry_get_enemy_forest_monster_completes_within_1ms() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var start_us: int = Time.get_ticks_usec()

	# Act
	var _result: Dictionary = registry.get_enemy("forest_monster")

	# Assert — 1ms = 1000 microseconds
	var elapsed_us: int = Time.get_ticks_usec() - start_us
	assert_int(elapsed_us).is_less_equal(1000)
	registry.free()

func test_enemy_registry_get_enemy_gaia_spirit_completes_within_1ms() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var start_us: int = Time.get_ticks_usec()

	# Act
	var _result: Dictionary = registry.get_enemy("gaia_spirit")

	# Assert
	var elapsed_us: int = Time.get_ticks_usec() - start_us
	assert_int(elapsed_us).is_less_equal(1000)
	registry.free()

func test_enemy_registry_get_enemy_unknown_id_completes_within_1ms() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var start_us: int = Time.get_ticks_usec()

	# Act
	var _result: Dictionary = registry.get_enemy("cronos")

	# Assert
	var elapsed_us: int = Time.get_ticks_usec() - start_us
	assert_int(elapsed_us).is_less_equal(1000)
	registry.free()

# ── AC8 — type field is stored as type constant value, not raw JSON string ────
##
## Per ADR-0016, EnemyRegistry uses string constants (TYPE_NORMAL = "Normal" etc.)
## rather than a GDScript enum. AC8 is satisfied when the stored value equals the
## corresponding constant — proving type validation ran and the value is canonical.

func test_enemy_registry_forest_monster_type_equals_type_normal_constant() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("forest_monster")

	# Assert — type value equals the TYPE_NORMAL constant defined on the registry
	assert_str(profile["type"]).is_equal(registry.TYPE_NORMAL)
	registry.free()

func test_enemy_registry_gaia_spirit_type_equals_type_boss_constant() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("gaia_spirit")

	# Assert — type value equals TYPE_BOSS
	assert_str(profile["type"]).is_equal(registry.TYPE_BOSS)
	registry.free()

func test_enemy_registry_amazon_challenger_type_equals_type_duel_constant() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act
	var profile: Dictionary = registry.get_enemy("amazon_challenger")

	# Assert — type value equals TYPE_DUEL
	assert_str(profile["type"]).is_equal(registry.TYPE_DUEL)
	registry.free()

func test_enemy_registry_type_constants_match_valid_types_list() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act / Assert — each TYPE_* constant must be in VALID_TYPES
	assert_array(registry.VALID_TYPES).contains([registry.TYPE_NORMAL])
	assert_array(registry.VALID_TYPES).contains([registry.TYPE_BOSS])
	assert_array(registry.VALID_TYPES).contains([registry.TYPE_DUEL])
	assert_array(registry.VALID_TYPES).contains([registry.TYPE_ABYSS])
	registry.free()

# ── Defensive copy tests ──────────────────────────────────────────────────────

func test_enemy_registry_get_enemy_returns_defensive_copy() -> void:
	# Arrange
	var registry = _make_loaded_registry()
	var profile_a: Dictionary = registry.get_enemy("mountain_beast")

	# Act — mutate the returned dictionary
	profile_a["hp"] = 9999

	# Assert — a second call returns the original value, not the mutated one
	var profile_b: Dictionary = registry.get_enemy("mountain_beast")
	assert_int(profile_b["hp"]).is_equal(80)
	registry.free()

# ── has_enemy() tests ─────────────────────────────────────────────────────────

func test_enemy_registry_has_enemy_returns_true_for_registered_id() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act / Assert
	assert_bool(registry.has_enemy("forest_monster")).is_true()
	registry.free()

func test_enemy_registry_has_enemy_returns_false_for_unknown_id() -> void:
	# Arrange
	var registry = _make_loaded_registry()

	# Act / Assert
	assert_bool(registry.has_enemy("cronos")).is_false()
	registry.free()
