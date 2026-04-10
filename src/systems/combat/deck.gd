class_name Deck
extends RefCounted

## Creates and manages a standard 52-card deck for poker combat.
##
## Card schema:
##   value:     int (2-14, Ace=14)
##   suit:      int (0=Hearts, 1=Diamonds, 2=Clubs, 3=Spades)
##   suit_name: String
##   element:   String (Fire, Water, Earth, Lightning)
##   enhancement: String ("" = no enhancement)
##   [companion_id: String] — present only on signature cards
##
## All suit/element mappings are loaded from res://assets/data/hand_ranks.json.
## No card data is hardcoded in this file.
##
## See: docs/architecture/adr-0007-poker-combat.md
## Story: STORY-COMBAT-001

# ── Config cache ─────────────────────────────────────────────────────────────

## Suit config loaded from hand_ranks.json:
## { "0": { "name": ..., "element": ... }, ... }
static var _suits_config: Dictionary = {}

# ── Public API ────────────────────────────────────────────────────────────────

## Builds a standard 52-card deck (4 suits x 13 values, 2 through Ace).
## Suit and element data are loaded from config; no values are hardcoded.
## Returns Array[Dictionary], one entry per card.
static func create_standard_deck() -> Array[Dictionary]:
	_ensure_config()
	var deck: Array[Dictionary] = []
	for suit_idx: int in range(4):
		var suit_data: Dictionary = _suits_config.get(str(suit_idx), {})
		var suit_name: String = suit_data.get("name", "Unknown")
		var element: String = suit_data.get("element", "")
		for value: int in range(2, 15):
			deck.append({
				"value":       value,
				"suit":        suit_idx,
				"suit_name":   suit_name,
				"element":     element,
				"enhancement": "",
			})
	return deck


## Returns a new shuffled copy of deck. Uses Godot's built-in Array.shuffle()
## (Fisher-Yates). The original array is not mutated.
static func shuffle_deck(deck: Array[Dictionary]) -> Array[Dictionary]:
	var shuffled: Array[Dictionary] = deck.duplicate()
	shuffled.shuffle()
	return shuffled


## Tags the card matching card_value + suit_idx with companion_id.
## Called once at deck build time when a captain is active.
## No-op if no matching card is found.
## Mutates deck in place; returns nothing.
static func tag_signature_cards(
		deck: Array[Dictionary],
		companion_id: String,
		card_value: int,
		suit_idx: int) -> void:
	for card: Dictionary in deck:
		if card["value"] == card_value and card["suit"] == suit_idx:
			card["companion_id"] = companion_id

# ── Private ───────────────────────────────────────────────────────────────────

## Loads suit config from hand_ranks.json on first use.
static func _ensure_config() -> void:
	if not _suits_config.is_empty():
		return
	var file: FileAccess = FileAccess.open(
		"res://assets/data/hand_ranks.json", FileAccess.READ)
	if file == null:
		push_error("Deck: failed to open res://assets/data/hand_ranks.json")
		return
	var json_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("Deck: failed to parse hand_ranks.json")
		return
	var root: Dictionary = parsed as Dictionary
	_suits_config = root.get("suits", {}) as Dictionary
