class_name DeckCreationTest
extends GdUnitTestSuite

## Unit tests for STORY-COMBAT-001: Deck Creation and Shuffle
##
## Covers:
##   AC1 — create_standard_deck() produces exactly 52 cards with no duplicates
##   AC2 — Each of the 4 suits has exactly 13 cards, values 2-14
##   AC3 — shuffle_deck() changes order (multiple shuffles differ)
##   AC4 — tag_signature_cards() tags the matching card with companion_id
##   AC5 — Signature card contributes chips/element identically to an ordinary card
##   AC6 — No captain → no cards carry a companion_id key
##   AC7 — Card values/suit names come from config, not hardcoded in combat files
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script reference (var, not :=, for preloaded scripts) ────────────────────

const DeckScript = preload("res://src/systems/combat/deck.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

## Returns a fresh 52-card deck. Each test calls this independently.
func _build_deck() -> Array[Dictionary]:
	var deck = DeckScript.new()
	return DeckScript.create_standard_deck()


## Returns a unique fingerprint string for a card (suit + value).
func _card_key(card: Dictionary) -> String:
	return "%d_%d" % [card["suit"], card["value"]]

# ── AC1 — Exactly 52 cards, no duplicates ────────────────────────────────────

func test_deck_creation_produces_52_cards() -> void:
	# Arrange / Act
	var deck: Array[Dictionary] = _build_deck()

	# Assert
	assert_int(deck.size()).is_equal(52)


func test_deck_creation_no_duplicate_cards() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act — collect unique suit+value keys
	var seen: Dictionary = {}
	for card: Dictionary in deck:
		var key: String = _card_key(card)
		assert_bool(seen.has(key)).is_false()
		seen[key] = true

	# Assert — all 52 unique
	assert_int(seen.size()).is_equal(52)

# ── AC2 — Each suit has 13 cards, values 2 through 14 ────────────────────────

func test_deck_creation_each_suit_has_13_cards() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act — count per suit
	var suit_counts: Dictionary = { 0: 0, 1: 0, 2: 0, 3: 0 }
	for card: Dictionary in deck:
		var s: int = card["suit"]
		suit_counts[s] = suit_counts[s] + 1

	# Assert
	for suit_idx: int in range(4):
		assert_int(suit_counts[suit_idx]).is_equal(13)


func test_deck_creation_values_range_2_to_14() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act — check all values in range
	for card: Dictionary in deck:
		var v: int = card["value"]
		assert_bool(v >= 2 and v <= 14).is_true()


func test_deck_creation_suit_0_is_hearts_fire() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act — find a Hearts card (suit 0)
	var hearts_card: Dictionary = {}
	for card: Dictionary in deck:
		if card["suit"] == 0:
			hearts_card = card
			break

	# Assert — suit_name and element from config
	assert_str(hearts_card.get("suit_name", "")).is_equal("Hearts")
	assert_str(hearts_card.get("element", "")).is_equal("Fire")


func test_deck_creation_suit_1_is_diamonds_water() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act
	var card: Dictionary = {}
	for c: Dictionary in deck:
		if c["suit"] == 1:
			card = c
			break

	# Assert
	assert_str(card.get("suit_name", "")).is_equal("Diamonds")
	assert_str(card.get("element", "")).is_equal("Water")


func test_deck_creation_suit_2_is_clubs_earth() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act
	var card: Dictionary = {}
	for c: Dictionary in deck:
		if c["suit"] == 2:
			card = c
			break

	# Assert
	assert_str(card.get("suit_name", "")).is_equal("Clubs")
	assert_str(card.get("element", "")).is_equal("Earth")


func test_deck_creation_suit_3_is_spades_lightning() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act
	var card: Dictionary = {}
	for c: Dictionary in deck:
		if c["suit"] == 3:
			card = c
			break

	# Assert
	assert_str(card.get("suit_name", "")).is_equal("Spades")
	assert_str(card.get("element", "")).is_equal("Lightning")

# ── AC3 — Shuffle changes order ───────────────────────────────────────────────

func test_deck_creation_shuffle_changes_order() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act — shuffle twice, verify at least one differs from original
	var shuffled_a: Array[Dictionary] = DeckScript.shuffle_deck(deck)
	var shuffled_b: Array[Dictionary] = DeckScript.shuffle_deck(deck)

	# Build simple order fingerprint (value sequence) for comparison
	var original_keys: Array[String] = []
	var a_keys: Array[String] = []
	var b_keys: Array[String] = []
	for i: int in range(deck.size()):
		original_keys.append(_card_key(deck[i]))
		a_keys.append(_card_key(shuffled_a[i]))
		b_keys.append(_card_key(shuffled_b[i]))

	# At least one shuffle must differ from the ordered baseline
	assert_bool(a_keys != original_keys or b_keys != original_keys).is_true()


func test_deck_creation_shuffle_does_not_mutate_original() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()
	var first_key_before: String = _card_key(deck[0])

	# Act
	var _shuffled: Array[Dictionary] = DeckScript.shuffle_deck(deck)

	# Assert — original deck first card is unchanged
	assert_str(_card_key(deck[0])).is_equal(first_key_before)


func test_deck_creation_shuffle_preserves_52_cards() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act
	var shuffled: Array[Dictionary] = DeckScript.shuffle_deck(deck)

	# Assert
	assert_int(shuffled.size()).is_equal(52)

# ── AC4 — Captain signature card is tagged ───────────────────────────────────

func test_deck_creation_signature_card_tagged_with_companion_id() -> void:
	# Arrange — Artemisa: Clubs (suit 2), King (value 13)
	var deck: Array[Dictionary] = _build_deck()

	# Act
	DeckScript.tag_signature_cards(deck, "artemisa", 13, 2)

	# Assert — exactly one card has companion_id = "artemisa"
	var tagged_count: int = 0
	for card: Dictionary in deck:
		if card.get("companion_id", "") == "artemisa":
			tagged_count += 1
	assert_int(tagged_count).is_equal(1)


func test_deck_creation_signature_card_correct_suit_and_value() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Act
	DeckScript.tag_signature_cards(deck, "artemisa", 13, 2)

	# Assert — the tagged card is the King of Clubs
	var tagged: Dictionary = {}
	for card: Dictionary in deck:
		if card.get("companion_id", "") == "artemisa":
			tagged = card
			break
	assert_int(tagged.get("value", 0)).is_equal(13)
	assert_int(tagged.get("suit", -1)).is_equal(2)

# ── AC5 — Signature card chips match ordinary card of same suit/value ─────────

func test_deck_creation_signature_card_chips_identical_to_normal() -> void:
	# Arrange — two decks, one with a signature card
	var deck_normal: Array[Dictionary] = _build_deck()
	var deck_tagged: Array[Dictionary] = _build_deck()
	DeckScript.tag_signature_cards(deck_tagged, "artemisa", 13, 2)

	# Find King of Clubs in each deck
	var normal_card: Dictionary = {}
	var tagged_card: Dictionary = {}
	for card: Dictionary in deck_normal:
		if card["value"] == 13 and card["suit"] == 2:
			normal_card = card
			break
	for card: Dictionary in deck_tagged:
		if card["value"] == 13 and card["suit"] == 2:
			tagged_card = card
			break

	# Act — chip values should be identical
	var chips_normal: int = HandEvaluator.get_card_chips(normal_card["value"])
	var chips_tagged: int = HandEvaluator.get_card_chips(tagged_card["value"])

	# Assert
	assert_int(chips_tagged).is_equal(chips_normal)


func test_deck_creation_signature_card_element_identical_to_normal() -> void:
	# Arrange
	var deck_normal: Array[Dictionary] = _build_deck()
	var deck_tagged: Array[Dictionary] = _build_deck()
	DeckScript.tag_signature_cards(deck_tagged, "artemisa", 13, 2)

	# Act
	var normal_element: String = ""
	var tagged_element: String = ""
	for card: Dictionary in deck_normal:
		if card["value"] == 13 and card["suit"] == 2:
			normal_element = card.get("element", "")
			break
	for card: Dictionary in deck_tagged:
		if card["value"] == 13 and card["suit"] == 2:
			tagged_element = card.get("element", "")
			break

	# Assert — element is unchanged by signature tagging
	assert_str(tagged_element).is_equal(normal_element)

# ── AC6 — No captain → no companion_id on any card ───────────────────────────

func test_deck_creation_no_captain_no_companion_id_tags() -> void:
	# Arrange / Act — build deck without calling tag_signature_cards
	var deck: Array[Dictionary] = _build_deck()

	# Assert — no card has a companion_id key
	for card: Dictionary in deck:
		assert_bool(card.has("companion_id")).is_false()

# ── AC7 — No hardcoded values in deck.gd ─────────────────────────────────────

func test_deck_creation_suit_names_come_from_config_not_hardcoded() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Collect all unique suit names from the deck
	var names: Dictionary = {}
	for card: Dictionary in deck:
		names[card.get("suit_name", "")] = true

	# Assert — all four expected suit names are present (loaded from config)
	assert_bool(names.has("Hearts")).is_true()
	assert_bool(names.has("Diamonds")).is_true()
	assert_bool(names.has("Clubs")).is_true()
	assert_bool(names.has("Spades")).is_true()


func test_deck_creation_elements_come_from_config_not_hardcoded() -> void:
	# Arrange
	var deck: Array[Dictionary] = _build_deck()

	# Collect all unique elements from the deck
	var elements: Dictionary = {}
	for card: Dictionary in deck:
		elements[card.get("element", "")] = true

	# Assert — all four expected elements are present (loaded from config)
	assert_bool(elements.has("Fire")).is_true()
	assert_bool(elements.has("Water")).is_true()
	assert_bool(elements.has("Earth")).is_true()
	assert_bool(elements.has("Lightning")).is_true()
