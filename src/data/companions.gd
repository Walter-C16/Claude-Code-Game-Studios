class_name Companions

const DATA: Dictionary = {
	"atenea": {
		"id": "atenea",
		"display_name": "Atenea",
		"role": "Goddess of Wisdom",
		"base_strength": 13,
		"base_intelligence": 19,
		"base_agility": 12,
		"card_element": Enums.Element.LIGHTNING,
		"card_value": 14,
		"starting_location": "ruined_temple",
	},
	"nyx": {
		"id": "nyx",
		"display_name": "Nyx",
		"role": "Primordial Goddess of Night",
		"base_strength": 18,
		"base_intelligence": 19,
		"base_agility": 8,
		"card_element": Enums.Element.WATER,
		"card_value": 14,
		"starting_location": "shadow_realm",
	},
	"hipolita": {
		"id": "hipolita",
		"display_name": "Hipólita",
		"role": "Queen of the Amazons",
		"base_strength": 20,
		"base_intelligence": 9,
		"base_agility": 18,
		"card_element": Enums.Element.FIRE,
		"card_value": 14,
		"starting_location": "amazon_camp",
	},
	"artemis": {
		"id": "artemis",
		"display_name": "Artemis",
		"role": "Goddess of the Hunt",
		"base_strength": 17,
		"base_intelligence": 13,
		"base_agility": 20,
		"card_element": Enums.Element.EARTH,
		"card_value": 13,
		"starting_location": "base_camp",
	},
}

const ALL_IDS: Array[String] = ["atenea", "nyx", "hipolita", "artemis"]

const DEFAULT_STATE: Dictionary = {
	"relationship_level": 0,
	"trust": 0,
	"motivation": 50,
	"romance_stage": 0,
	"dates_completed": 0,
	"met": false,
	"known_likes": [],
	"known_dislikes": [],
}

static func get_companion(id: String) -> Dictionary:
	return DATA.get(id, {})

static func get_portrait_path(id: String, mood: String = "neutral") -> String:
	return "res://assets/images/companions/%s/%s_%s.png" % [id, id, mood]

static func create_default_state() -> Dictionary:
	return DEFAULT_STATE.duplicate(true)
