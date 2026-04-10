# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does chips x mult poker combat feel satisfying on 430x932 touch?
# Date: 2026-04-10

class_name PokerLogic
extends RefCounted

enum Element { NONE, FIRE, WATER, EARTH, LIGHTNING }
enum Enhancement { NONE, FOIL, HOLOGRAPHIC, POLYCHROME }

const SUIT_NAMES := ["Hearts", "Diamonds", "Clubs", "Spades"]
const SUIT_ELEMENTS := [Element.FIRE, Element.WATER, Element.EARTH, Element.LIGHTNING]
const SUIT_SYMBOLS := ["♥", "♦", "♣", "♠"]
const SUIT_COLORS := [Color("#F24D26"), Color("#338CF2"), Color("#73BF40"), Color("#CCaa33")]

const VALUE_NAMES := {
	2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8",
	9: "9", 10: "10", 11: "J", 12: "Q", 13: "K", 14: "A"
}

# Element weakness cycle: Fire > Earth > Lightning > Water > Fire
const WEAKNESS_MAP := {
	Element.FIRE: Element.WATER,
	Element.WATER: Element.LIGHTNING,
	Element.EARTH: Element.FIRE,
	Element.LIGHTNING: Element.EARTH,
}

# Hand rank data: [name, base_chips, base_mult]
const HAND_RANKS := {
	"Royal Flush": [100, 8.0],
	"Straight Flush": [100, 8.0],
	"Four of a Kind": [60, 7.0],
	"Full House": [40, 4.0],
	"Flush": [35, 4.0],
	"Straight": [30, 4.0],
	"Three of a Kind": [30, 3.0],
	"Two Pair": [20, 2.0],
	"Pair": [10, 2.0],
	"High Card": [5, 1.0],
}


# --- Card ---
class Card:
	var value: int  # 2-14 (14=Ace)
	var suit: int   # 0=Hearts, 1=Diamonds, 2=Clubs, 3=Spades
	var enhancement: int = Enhancement.NONE

	func _init(v: int, s: int) -> void:
		value = v
		suit = s

	func get_element() -> int:
		return SUIT_ELEMENTS[suit]

	func get_chips() -> int:
		if value == 14:
			return 11
		elif value >= 11:
			return 10
		else:
			return value

	func get_display_name() -> String:
		return VALUE_NAMES[value] + SUIT_SYMBOLS[suit]

	func get_color() -> Color:
		return SUIT_COLORS[suit]


# --- Deck ---
static func create_deck() -> Array[Card]:
	var deck: Array[Card] = []
	for suit in range(4):
		for value in range(2, 15):
			deck.append(Card.new(value, suit))
	deck.shuffle()
	return deck


# --- Hand Evaluation ---
static func evaluate_hand(cards: Array[Card]) -> Dictionary:
	if cards.is_empty():
		return {"rank": "High Card", "base_chips": 5, "base_mult": 1.0}

	var values := []
	var suits := []
	for c in cards:
		values.append(c.value)
		suits.append(c.suit)

	values.sort()
	var count := cards.size()

	# Count value frequencies
	var freq := {}
	for v in values:
		freq[v] = freq.get(v, 0) + 1
	var freq_values: Array = freq.values()
	freq_values.sort()

	var is_flush := count == 5 and suits.count(suits[0]) == 5
	var is_straight := _check_straight(values) and count == 5

	var rank_name := "High Card"

	if is_flush and is_straight:
		if values == [10, 11, 12, 13, 14]:
			rank_name = "Royal Flush"
		else:
			rank_name = "Straight Flush"
	elif freq_values == [1, 4]:
		rank_name = "Four of a Kind"
	elif freq_values == [2, 3]:
		rank_name = "Full House"
	elif is_flush:
		rank_name = "Flush"
	elif is_straight:
		rank_name = "Straight"
	elif 3 in freq_values:
		rank_name = "Three of a Kind"
	elif freq_values.count(2) == 2:
		rank_name = "Two Pair"
	elif 2 in freq_values:
		rank_name = "Pair"

	var rank_data: Array = HAND_RANKS[rank_name]
	return {
		"rank": rank_name,
		"base_chips": rank_data[0],
		"base_mult": rank_data[1],
	}


static func _check_straight(sorted_values: Array) -> bool:
	if sorted_values.size() != 5:
		return false
	# Normal straight
	var is_normal := true
	for i in range(1, 5):
		if sorted_values[i] != sorted_values[i - 1] + 1:
			is_normal = false
			break
	if is_normal:
		return true
	# Wheel: A-2-3-4-5
	if sorted_values == [2, 3, 4, 5, 14]:
		return true
	return false


# --- Scoring Pipeline ---
static func calculate_score(cards: Array[Card], enemy_element: int, captain_str: int, captain_int: int) -> Dictionary:
	var hand := evaluate_hand(cards)

	# Chips
	var total_chips: int = hand["base_chips"]
	var per_card_chips := 0
	var element_chips := 0
	var element_details := []

	var enemy_weak: int = WEAKNESS_MAP.get(enemy_element, Element.NONE)

	for c in cards:
		per_card_chips += c.get_chips()

		if enemy_element != Element.NONE:
			var card_elem := c.get_element()
			if card_elem == enemy_weak:
				element_chips += 25
				element_details.append({"card": c.get_display_name(), "type": "weak", "chips": 25})
			elif card_elem == enemy_element:
				element_chips -= 15
				element_details.append({"card": c.get_display_name(), "type": "resist", "chips": -15})

	var captain_chip_bonus: int = floori(captain_str * 0.5)
	total_chips += per_card_chips + element_chips + captain_chip_bonus
	total_chips = maxi(1, total_chips)

	# Mult
	var additive_mult: float = hand["base_mult"]
	var element_mult := 0.0
	if enemy_element != Element.NONE:
		for c in cards:
			if c.get_element() == enemy_weak:
				element_mult += 0.5
	additive_mult += element_mult
	additive_mult = maxf(1.0, additive_mult)

	var captain_mult_mod: float = 1.0 + (captain_int * 0.025)
	var final_mult: float = additive_mult * captain_mult_mod

	var score: int = floori(total_chips * final_mult)

	return {
		"rank": hand["rank"],
		"base_chips": hand["base_chips"],
		"per_card_chips": per_card_chips,
		"element_chips": element_chips,
		"element_details": element_details,
		"captain_chip_bonus": captain_chip_bonus,
		"total_chips": total_chips,
		"base_mult": hand["base_mult"],
		"element_mult": element_mult,
		"additive_mult": additive_mult,
		"captain_mult_mod": captain_mult_mod,
		"final_mult": final_mult,
		"score": score,
	}
