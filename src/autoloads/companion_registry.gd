extends Node

## CompanionRegistry — Static Companion Profile Data (ADR-0009)
##
## Autoload #7. Read-only registry of companion profiles loaded once at boot.
## No writes. No signals. No mutable state. Pure data lookup.
##
## Boot order constraint: may only reference autoloads #1–#6 during _ready().
## This registry depends on nothing — safe at position #7.
##
## Public API:
##   get_profile(id)           → Dictionary (copy) or {} if unknown
##   get_all_ids()             → Array[String] of all loaded IDs
##   get_portrait_path(id, mood) → String path to portrait asset
##   get_element_for_suit(suit)  → String element name or "" if unknown
##
## See: docs/architecture/adr-0009-companion-data.md

# ── Constants ─────────────────────────────────────────────────────────────────

const DATA_PATH: String = "res://assets/data/companions.json"
const PLACEHOLDER_PORTRAIT: String = "res://assets/images/companions/placeholder.png"

## Element enum shared across Combat and Companion systems (ADR-0009, COMPANION-002).
## Accessible as CompanionRegistry.CompanionElement.FIRE etc. from any script
## without importing a scene node.
enum CompanionElement { FIRE = 0, WATER = 1, EARTH = 2, LIGHTNING = 3 }

## Suit-to-element mapping (Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning).
const SUIT_ELEMENT_MAP: Dictionary = {
	"Hearts": "Fire",
	"Diamonds": "Water",
	"Clubs": "Earth",
	"Spades": "Lightning",
}

# ── Private State ─────────────────────────────────────────────────────────────

var _profiles: Dictionary = {}

# ── Built-in Virtual Methods ──────────────────────────────────────────────────

func _ready() -> void:
	_profiles = _load_profiles()

# ── Public Methods ────────────────────────────────────────────────────────────

## Marks a companion as met AND seeds their default known_likes/dislikes
## in GameStore. Also drops them straight into the active party if there's
## an open slot — meeting a companion is the moment they join the journey,
## so the player shouldn't have to open the Deck screen to start using her.
## A full party (4 slots) silently skips the auto-add; the player can swap
## her in manually from the Deck screen.
func meet_companion(id: String) -> void:
	GameStore.set_met(id, true)
	var profile: Dictionary = get_profile(id)
	var likes: Array = profile.get("likes", []) as Array
	var dislikes: Array = profile.get("dislikes", []) as Array
	GameStore.seed_companion_preferences(id, likes, dislikes)

	var ctype: String = profile.get("type", "companion") as String
	var is_battle: bool = ctype == "companion"
	# Quest companions become battle-ready only after their quest_complete flag.
	if ctype == "quest_companion":
		var unlock_flag: String = profile.get("unlock_flag", id + "_quest_complete") as String
		is_battle = GameStore.has_flag(unlock_flag)

	# Auto-join the active party if there's room — ONLY for battle
	# companions (including quest_companions whose quest is done).
	if is_battle:
		if not GameStore.has_deck_companion(id):
			var current: Array[String] = GameStore.get_deck_companions()
			if current.size() < 4:
				var card_value: int = int(profile.get("card_value", 0))
				GameStore.add_deck_companion(id, card_value)


## Returns a defensive copy of the profile dictionary for [param id].
## Returns an empty Dictionary if the ID is not registered (no crash, no error push).
func get_profile(id: String) -> Dictionary:
	if not _profiles.has(id):
		return {}
	return _profiles[id].duplicate()

## Returns an Array[String] containing every loaded companion ID.
## Includes the priestess NPC. Order is not guaranteed.
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in _profiles:
		ids.append(key)
	return ids

## Returns the portrait asset path for [param id] at [param mood].
## Fallback order: requested mood → neutral → PLACEHOLDER_PORTRAIT.
## 1. Build requested mood path; return it if the file exists.
## 2. Build neutral path; return it if the file exists.
## 3. Return PLACEHOLDER_PORTRAIT.
## Falls back immediately to PLACEHOLDER_PORTRAIT if the ID is not registered
## or the profile has no portrait_path_base.
func get_portrait_path(id: String, mood: String = "neutral") -> String:
	if not _profiles.has(id):
		return PLACEHOLDER_PORTRAIT
	var base: String = _profiles[id].get("portrait_path_base", "")
	if base.is_empty():
		return PLACEHOLDER_PORTRAIT

	var requested_path: String = base + "_" + mood + ".png"
	if FileAccess.file_exists(requested_path):
		return requested_path

	var neutral_path: String = base + "_neutral.png"
	if FileAccess.file_exists(neutral_path):
		return neutral_path

	return PLACEHOLDER_PORTRAIT

## Returns the element name for a poker suit string.
## Mapping: Hearts→Fire, Diamonds→Water, Clubs→Earth, Spades→Lightning.
## Returns "" for unknown suits (no crash).
func get_element_for_suit(suit: String) -> String:
	return SUIT_ELEMENT_MAP.get(suit, "")

# ── Private Methods ───────────────────────────────────────────────────────────

## Loads and parses companions.json from DATA_PATH.
## Returns the parsed profiles Dictionary, or {} on any load/parse failure.
func _load_profiles() -> Dictionary:
	return JsonLoader.load_dict(DATA_PATH)
