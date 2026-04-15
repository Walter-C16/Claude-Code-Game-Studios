class_name ElementalReactionTest
extends GdUnitTestSuite

## Unit tests for ElementalReaction — static resolver for 6 element combos.
##
## Covers:
##   All six valid pair combinations resolve to the correct reaction name
##   Symmetry: resolve(A, B) == resolve(B, A)
##   Same-element pair returns empty dict (no self-reaction)
##   Neutral element on either side returns empty dict
##   Empty string on either side returns empty dict
##   Resolved reactions include effect + magnitude + duration fields

const ElementalReactionScript = preload("res://systems/battle/elemental_reaction.gd")


# ── Happy-path combos ────────────────────────────────────────────────────────

func test_elemental_reaction_fire_water_resolves_to_oracle_mist() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Fire", "Water")

	# Assert
	assert_str(r.get("name", "")).is_equal("Oracle Mist")
	assert_str(r.get("effect", "")).is_equal("damage_buff_next")
	assert_float(r.get("magnitude", 0.0)).is_equal_approx(50.0, 0.01)


func test_elemental_reaction_earth_fire_resolves_to_cinder_bloom() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Earth", "Fire")

	# Assert
	assert_str(r.get("name", "")).is_equal("Cinder Bloom")
	assert_str(r.get("effect", "")).is_equal("dot_burn")
	assert_int(r.get("duration", 0)).is_equal(3)


func test_elemental_reaction_fire_lightning_resolves_to_solar_flare() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Fire", "Lightning")

	# Assert
	assert_str(r.get("name", "")).is_equal("Solar Flare")
	assert_str(r.get("effect", "")).is_equal("aoe_damage")


func test_elemental_reaction_earth_water_resolves_to_life_spring() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Earth", "Water")

	# Assert
	assert_str(r.get("name", "")).is_equal("Life Spring")
	assert_str(r.get("effect", "")).is_equal("party_heal")


func test_elemental_reaction_lightning_water_resolves_to_tidal_surge() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Lightning", "Water")

	# Assert
	assert_str(r.get("name", "")).is_equal("Tidal Surge")
	assert_str(r.get("effect", "")).is_equal("chain_damage")


func test_elemental_reaction_earth_lightning_resolves_to_stone_aegis() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Earth", "Lightning")

	# Assert
	assert_str(r.get("name", "")).is_equal("Stone Aegis")
	assert_str(r.get("effect", "")).is_equal("party_shield")


# ── Symmetry ──────────────────────────────────────────────────────────────────

func test_elemental_reaction_resolve_is_symmetric() -> void:
	# Arrange — every pair
	var pairs: Array = [
		["Fire", "Water"],
		["Earth", "Fire"],
		["Fire", "Lightning"],
		["Earth", "Water"],
		["Lightning", "Water"],
		["Earth", "Lightning"],
	]

	# Act + Assert — resolve(A,B).name == resolve(B,A).name
	for pair: Variant in pairs:
		var a: String = (pair as Array)[0]
		var b: String = (pair as Array)[1]
		var fwd: Dictionary = ElementalReactionScript.resolve(a, b)
		var rev: Dictionary = ElementalReactionScript.resolve(b, a)
		assert_str(fwd.get("name", "")).is_equal(rev.get("name", ""))


# ── Edge cases ────────────────────────────────────────────────────────────────

func test_elemental_reaction_same_element_returns_empty() -> void:
	# Act
	var r: Dictionary = ElementalReactionScript.resolve("Fire", "Fire")

	# Assert
	assert_bool(r.is_empty()).is_true()


func test_elemental_reaction_neutral_returns_empty() -> void:
	# Act + Assert — both sides
	assert_bool(ElementalReactionScript.resolve("Neutral", "Fire").is_empty()).is_true()
	assert_bool(ElementalReactionScript.resolve("Fire", "Neutral").is_empty()).is_true()


func test_elemental_reaction_empty_string_returns_empty() -> void:
	# Act + Assert
	assert_bool(ElementalReactionScript.resolve("", "Fire").is_empty()).is_true()
	assert_bool(ElementalReactionScript.resolve("Fire", "").is_empty()).is_true()
