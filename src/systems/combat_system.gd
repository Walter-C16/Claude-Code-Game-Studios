class_name CombatSystem

# ---------------------------------------------------------------------------
# Card creation
# ---------------------------------------------------------------------------

const SUITS := ["hearts", "diamonds", "clubs", "spades"]
const SUIT_ELEMENT_MAP := { "hearts": 0, "diamonds": 1, "clubs": 2, "spades": 3 }

static func create_card(suit: String, value: int) -> Dictionary:
	return {
		"id": "%s_%d" % [suit, value],
		"suit": suit,
		"value": value,
		"element": SUIT_ELEMENT_MAP.get(suit, 0),
		"enhancement": "none",
		"companion_id": "",
	}

static func create_standard_deck() -> Array:
	var deck: Array = []
	for suit in SUITS:
		for value in range(2, 15):  # 2-14 (Ace = 14)
			deck.append(create_card(suit, value))
	return deck

static func create_enemy(name_key: String, score_target: int) -> Dictionary:
	return {
		"id": name_key.to_lower().replace(" ", "_"),
		"name_key": name_key,
		"hp": score_target,
		"max_hp": score_target,
		"attack": int(score_target * 0.1),
		"element": randi() % 4,
	}

static func shuffle_array(arr: Array) -> Array:
	var copy := arr.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy

# ---------------------------------------------------------------------------
# Hand evaluation
# ---------------------------------------------------------------------------

static func evaluate_hand(cards: Array) -> Dictionary:
	"""Evaluate 1-5 cards into a poker hand rank with base chips/mult."""
	if cards.is_empty():
		return { "rank": Enums.HandRank.HIGH_CARD, "chips": 0, "mult": 0.0 }

	var size := cards.size()

	# Value frequency count
	var counts: Dictionary = {}
	for card in cards:
		var v: int = card["value"]
		counts[v] = counts.get(v, 0) + 1

	var freq_values: Array = counts.values()
	freq_values.sort()
	freq_values.reverse()

	# Check flush (all same suit, need 5 cards)
	var is_flush := false
	if size == 5:
		var first_suit: String = cards[0]["suit"]
		is_flush = true
		for card in cards:
			if card["suit"] != first_suit:
				is_flush = false
				break

	# Check straight (consecutive values, need 5 cards)
	var is_straight := false
	if size == 5:
		var values: Array[int] = []
		for card in cards:
			values.append(card["value"])
		values.sort()

		# Normal straight: consecutive
		is_straight = true
		for i in range(1, values.size()):
			if values[i] != values[i - 1] + 1:
				is_straight = false
				break

		# Wheel: A-2-3-4-5 (Ace acts as 1)
		if not is_straight and values == [2, 3, 4, 5, 14]:
			is_straight = true

	# Classify hand
	var rank: int

	if is_flush and is_straight:
		# Check for royal (10, J, Q, K, A)
		var vals: Array[int] = []
		for card in cards:
			vals.append(card["value"])
		vals.sort()
		if vals == [10, 11, 12, 13, 14]:
			rank = Enums.HandRank.ROYAL_FLUSH
		else:
			rank = Enums.HandRank.STRAIGHT_FLUSH
	elif freq_values.size() >= 1 and freq_values[0] == 4:
		rank = Enums.HandRank.FOUR_KIND
	elif freq_values.size() >= 2 and freq_values[0] == 3 and freq_values[1] == 2:
		rank = Enums.HandRank.FULL_HOUSE
	elif is_flush:
		rank = Enums.HandRank.FLUSH
	elif is_straight:
		rank = Enums.HandRank.STRAIGHT
	elif freq_values.size() >= 1 and freq_values[0] == 3:
		rank = Enums.HandRank.THREE_KIND
	elif freq_values.size() >= 2 and freq_values[0] == 2 and freq_values[1] == 2:
		rank = Enums.HandRank.TWO_PAIR
	elif freq_values.size() >= 1 and freq_values[0] == 2:
		rank = Enums.HandRank.PAIR
	else:
		rank = Enums.HandRank.HIGH_CARD

	var base: Dictionary = Balance.HAND_SCORES.get(rank, { "chips": 5, "mult": 1.0 })
	return { "rank": rank, "chips": base["chips"], "mult": base["mult"] }

# ---------------------------------------------------------------------------
# Per-card chip value
# ---------------------------------------------------------------------------

static func get_card_chips(card: Dictionary) -> int:
	var v: int = card.get("value", 0)
	if v == 14:
		return 11  # Ace
	elif v >= 11:
		return 10  # J, Q, K
	return v

# ---------------------------------------------------------------------------
# Full scoring pipeline
# ---------------------------------------------------------------------------

static func calculate_score(cards: Array, _companion_id: String = "") -> Dictionary:
	var result := evaluate_hand(cards)
	var chips: int = result["chips"]
	var mult: float = result["mult"]

	# Add per-card chips
	for card in cards:
		chips += get_card_chips(card)

	# Enhancement bonuses
	for card in cards:
		match card.get("enhancement", "none"):
			"foil":
				chips += 50
			"holographic":
				mult += 10.0
			"polychrome":
				mult *= 1.5

	var score := int(chips * mult)
	return {
		"rank": result["rank"],
		"chips": chips,
		"mult": mult,
		"score": score,
	}
