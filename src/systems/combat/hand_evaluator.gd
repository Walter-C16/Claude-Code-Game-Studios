class_name HandEvaluator
extends RefCounted

## Evaluates 1-5 poker cards into a hand rank with base chips and mult.
##
## Hand rank data is loaded from res://assets/data/hand_ranks.json.
## No base chip or mult values are hardcoded in this file.
##
## Flush and Straight require exactly 5 cards.
## Ace-low straight (A-2-3-4-5) is recognized as a valid Straight.
## Royal Flush is distinguished from Straight Flush by the 10-J-Q-K-A card set.
##
## See: docs/architecture/adr-0007-poker-combat.md
## Story: STORY-COMBAT-002

# ── Config cache ─────────────────────────────────────────────────────────────

## Hand rank lookup loaded from hand_ranks.json.
## Keys are rank name strings (e.g. "Pair"), values are {base_chips, base_mult}.
static var _hand_ranks_config: Dictionary = {}

# ── Constants ─────────────────────────────────────────────────────────────────

## Rank name strings in ascending strength order (used internally).
const RANK_HIGH_CARD:       String = "High Card"
const RANK_PAIR:            String = "Pair"
const RANK_TWO_PAIR:        String = "Two Pair"
const RANK_THREE_OF_A_KIND: String = "Three of a Kind"
const RANK_STRAIGHT:        String = "Straight"
const RANK_FLUSH:           String = "Flush"
const RANK_FULL_HOUSE:      String = "Full House"
const RANK_FOUR_OF_A_KIND:  String = "Four of a Kind"
const RANK_STRAIGHT_FLUSH:  String = "Straight Flush"
const RANK_ROYAL_FLUSH:     String = "Royal Flush"

# ── Public API ────────────────────────────────────────────────────────────────

## Evaluates an array of 1-5 card Dictionaries and returns:
##   { rank: String, base_chips: int, base_mult: float }
## base_chips and base_mult come from config, not from hardcoded values.
static func evaluate(cards: Array[Dictionary]) -> Dictionary:
	_ensure_config()

	if cards.is_empty():
		return _make_result(RANK_HIGH_CARD)

	var count: int = cards.size()

	# --- value frequency map ---
	var freq: Dictionary = {}
	for card: Dictionary in cards:
		var v: int = card["value"]
		freq[v] = freq.get(v, 0) + 1

	var freqs: Array = freq.values()
	freqs.sort()
	freqs.reverse()  # highest frequency first

	# --- flush: requires exactly 5 cards, all same suit ---
	var is_flush: bool = false
	if count == 5:
		var first_suit: int = cards[0]["suit"]
		is_flush = true
		for card: Dictionary in cards:
			if card["suit"] != first_suit:
				is_flush = false
				break

	# --- straight: requires exactly 5 cards ---
	var is_straight: bool = false
	var is_wheel: bool = false  # A-2-3-4-5
	if count == 5:
		var vals: Array[int] = []
		for card: Dictionary in cards:
			vals.append(card["value"])
		vals.sort()

		is_straight = true
		for i: int in range(1, vals.size()):
			if vals[i] != vals[i - 1] + 1:
				is_straight = false
				break

		# Ace-low wheel: A=14 treated as 1
		if not is_straight and vals == [2, 3, 4, 5, 14]:
			is_straight = true
			is_wheel = true

	# --- royal flush check: 10-J-Q-K-A ---
	var is_royal: bool = false
	if is_flush and is_straight and not is_wheel:
		var vals_r: Array[int] = []
		for card: Dictionary in cards:
			vals_r.append(card["value"])
		vals_r.sort()
		is_royal = (vals_r == [10, 11, 12, 13, 14])

	# --- classify ---
	var rank: String
	if is_flush and is_straight:
		rank = RANK_ROYAL_FLUSH if is_royal else RANK_STRAIGHT_FLUSH
	elif freqs.size() >= 1 and freqs[0] == 4:
		rank = RANK_FOUR_OF_A_KIND
	elif freqs.size() >= 2 and freqs[0] == 3 and freqs[1] == 2:
		rank = RANK_FULL_HOUSE
	elif is_flush:
		rank = RANK_FLUSH
	elif is_straight:
		rank = RANK_STRAIGHT
	elif freqs.size() >= 1 and freqs[0] == 3:
		rank = RANK_THREE_OF_A_KIND
	elif freqs.size() >= 2 and freqs[0] == 2 and freqs[1] == 2:
		rank = RANK_TWO_PAIR
	elif freqs.size() >= 1 and freqs[0] == 2:
		rank = RANK_PAIR
	else:
		rank = RANK_HIGH_CARD

	return _make_result(rank)


## Returns the chip value of a single card by face value.
## 2-10 → face value. J(11)/Q(12)/K(13) → 10. Ace(14) → 11.
static func get_card_chips(value: int) -> int:
	if value == 14:
		return 11
	if value >= 11:
		return 10
	return value

# ── Private ───────────────────────────────────────────────────────────────────

## Builds a result Dictionary using config-loaded values for the given rank.
static func _make_result(rank: String) -> Dictionary:
	var data: Dictionary = _hand_ranks_config.get(rank, {})
	return {
		"rank":       rank,
		"base_chips": data.get("base_chips", 5) as int,
		"base_mult":  data.get("base_mult",  1.0) as float,
	}


## Loads hand rank data from hand_ranks.json on first use.
static func _ensure_config() -> void:
	if not _hand_ranks_config.is_empty():
		return
	var file: FileAccess = FileAccess.open(
		"res://assets/data/hand_ranks.json", FileAccess.READ)
	if file == null:
		push_error("HandEvaluator: failed to open res://assets/data/hand_ranks.json")
		return
	var json_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("HandEvaluator: failed to parse hand_ranks.json")
		return
	var root: Dictionary = parsed as Dictionary
	_hand_ranks_config = root.get("hand_ranks", {}) as Dictionary
