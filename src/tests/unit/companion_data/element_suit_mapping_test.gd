class_name ElementSuitMappingTest
extends GdUnitTestSuite

## Unit tests for STORY-COMPANION-002: Element Enum and Suit Mapping
##
## Covers all Acceptance Criteria:
##   AC1 — CompanionElement enum values are accessible without importing a scene node
##   AC2 — get_element_for_suit("Hearts") returns "Fire"
##   AC3 — get_element_for_suit("Diamonds") returns "Water"
##   AC4 — get_element_for_suit("Clubs") returns "Earth"
##   AC5 — get_element_for_suit("Spades") returns "Lightning"
##   AC6 — get_element_for_suit("Joker") returns "" with no crash
##   AC7 — All 4 companions have unique elements (no two share an element)
##
## See: docs/architecture/adr-0009-companion-data.md

const RegistryScript = preload("res://autoloads/companion_registry.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_registry():
	var registry = RegistryScript.new()
	registry._ready()
	return registry

# ── AC1 — CompanionElement enum is accessible without a scene node ────────────

func test_element_suit_mapping_companion_element_fire_is_accessible() -> void:
	# Arrange / Act — access via the script constant, no scene node needed
	var fire_value = RegistryScript.CompanionElement.FIRE

	# Assert — enum value is a valid int (not null, not a String)
	assert_bool(fire_value is int).is_true()

func test_element_suit_mapping_companion_element_water_is_accessible() -> void:
	var water_value = RegistryScript.CompanionElement.WATER
	assert_bool(water_value is int).is_true()

func test_element_suit_mapping_companion_element_earth_is_accessible() -> void:
	var earth_value = RegistryScript.CompanionElement.EARTH
	assert_bool(earth_value is int).is_true()

func test_element_suit_mapping_companion_element_lightning_is_accessible() -> void:
	var lightning_value = RegistryScript.CompanionElement.LIGHTNING
	assert_bool(lightning_value is int).is_true()

func test_element_suit_mapping_all_four_enum_values_are_distinct() -> void:
	# Arrange
	var fire = RegistryScript.CompanionElement.FIRE
	var water = RegistryScript.CompanionElement.WATER
	var earth = RegistryScript.CompanionElement.EARTH
	var lightning = RegistryScript.CompanionElement.LIGHTNING

	# Assert — no two values are equal
	assert_bool(fire == water).is_false()
	assert_bool(fire == earth).is_false()
	assert_bool(fire == lightning).is_false()
	assert_bool(water == earth).is_false()
	assert_bool(water == lightning).is_false()
	assert_bool(earth == lightning).is_false()

# ── AC2 — Hearts → Fire ───────────────────────────────────────────────────────

func test_element_suit_mapping_hearts_returns_fire() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var result: String = registry.get_element_for_suit("Hearts")

	# Assert
	assert_str(result).is_equal("Fire")

# ── AC3 — Diamonds → Water ───────────────────────────────────────────────────

func test_element_suit_mapping_diamonds_returns_water() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var result: String = registry.get_element_for_suit("Diamonds")

	# Assert
	assert_str(result).is_equal("Water")

# ── AC4 — Clubs → Earth ──────────────────────────────────────────────────────

func test_element_suit_mapping_clubs_returns_earth() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var result: String = registry.get_element_for_suit("Clubs")

	# Assert
	assert_str(result).is_equal("Earth")

# ── AC5 — Spades → Lightning ─────────────────────────────────────────────────

func test_element_suit_mapping_spades_returns_lightning() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var result: String = registry.get_element_for_suit("Spades")

	# Assert
	assert_str(result).is_equal("Lightning")

# ── AC6 — Unknown suit returns "" with no crash ───────────────────────────────

func test_element_suit_mapping_unknown_suit_returns_empty_string() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var result: String = registry.get_element_for_suit("Joker")

	# Assert
	assert_str(result).is_equal("")

func test_element_suit_mapping_empty_string_suit_returns_empty_string() -> void:
	# Arrange
	var registry = _make_registry()

	# Act
	var result: String = registry.get_element_for_suit("")

	# Assert
	assert_str(result).is_equal("")

# ── AC7 — All 4 companions have unique elements ───────────────────────────────

func test_element_suit_mapping_companion_elements_are_all_unique() -> void:
	# Arrange
	var registry = _make_registry()
	var companion_ids: Array[String] = ["artemis", "hipolita", "atenea", "nyx"]
	var elements: Dictionary = {}

	# Act — collect each companion's element field
	for id: String in companion_ids:
		var profile: Dictionary = registry.get_profile(id)
		var element: String = profile.get("element", "")
		assert_bool(element.is_empty()).is_false()
		elements[element] = true

	# Assert — 4 companions, 4 distinct elements
	assert_int(elements.size()).is_equal(4)
