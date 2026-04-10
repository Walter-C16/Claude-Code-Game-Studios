class_name Enums

# ---------------------------------------------------------------------------
# Companion IDs (string constants for dictionary keys)
# ---------------------------------------------------------------------------
const COMPANION_ATENEA := "atenea"
const COMPANION_NYX := "nyx"
const COMPANION_HIPOLITA := "hipolita"
const COMPANION_ARTEMISA := "artemis"

const ALL_COMPANION_IDS: Array[String] = ["atenea", "nyx", "hipolita", "artemis"]

# ---------------------------------------------------------------------------
# Moods
# ---------------------------------------------------------------------------
enum Mood { NEUTRAL, HAPPY, SAD, ANGRY, SURPRISED, SEDUCTIVE }

const MOOD_NAMES: Dictionary = {
	Mood.NEUTRAL: "neutral",
	Mood.HAPPY: "happy",
	Mood.SAD: "sad",
	Mood.ANGRY: "angry",
	Mood.SURPRISED: "surprised",
	Mood.SEDUCTIVE: "seductive",
}

# ---------------------------------------------------------------------------
# Elements (index matches suit mapping: 0=fire, 1=water, 2=earth, 3=lightning)
# ---------------------------------------------------------------------------
enum Element { FIRE, WATER, EARTH, LIGHTNING }

const ELEMENT_NAMES: Dictionary = {
	Element.FIRE: "fire",
	Element.WATER: "water",
	Element.EARTH: "earth",
	Element.LIGHTNING: "lightning",
}

const ELEMENT_COLORS: Dictionary = {
	Element.FIRE: Color("#F24D26"),
	Element.WATER: Color("#338CF2"),
	Element.EARTH: Color("#73BF40"),
	Element.LIGHTNING: Color("#CCaa33"),
}

# ---------------------------------------------------------------------------
# Suits (mapped to elements: hearts→fire, diamonds→water, clubs→earth, spades→lightning)
# ---------------------------------------------------------------------------
enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES }

const SUIT_NAMES: Dictionary = {
	Suit.HEARTS: "hearts",
	Suit.DIAMONDS: "diamonds",
	Suit.CLUBS: "clubs",
	Suit.SPADES: "spades",
}

const SUIT_SYMBOLS: Dictionary = {
	Suit.HEARTS: "♥",
	Suit.DIAMONDS: "♦",
	Suit.CLUBS: "♣",
	Suit.SPADES: "♠",
}

const SUIT_TO_ELEMENT: Dictionary = {
	Suit.HEARTS: Element.FIRE,
	Suit.DIAMONDS: Element.WATER,
	Suit.CLUBS: Element.EARTH,
	Suit.SPADES: Element.LIGHTNING,
}

# ---------------------------------------------------------------------------
# Enhancements
# ---------------------------------------------------------------------------
enum Enhancement { NONE, FOIL, HOLOGRAPHIC, POLYCHROME }

# ---------------------------------------------------------------------------
# Combat phases
# ---------------------------------------------------------------------------
enum CombatPhase { DRAW, SELECT, RESOLVE, ENEMY_TURN, VICTORY, DEFEAT }

# ---------------------------------------------------------------------------
# Hand ranks (ascending strength)
# ---------------------------------------------------------------------------
enum HandRank {
	HIGH_CARD, PAIR, TWO_PAIR, THREE_KIND, STRAIGHT, FLUSH,
	FULL_HOUSE, FOUR_KIND, STRAIGHT_FLUSH, ROYAL_FLUSH, ULTIMATE
}

const HAND_RANK_NAMES: Dictionary = {
	HandRank.HIGH_CARD: "high_card",
	HandRank.PAIR: "pair",
	HandRank.TWO_PAIR: "two_pair",
	HandRank.THREE_KIND: "three_kind",
	HandRank.STRAIGHT: "straight",
	HandRank.FLUSH: "flush",
	HandRank.FULL_HOUSE: "full_house",
	HandRank.FOUR_KIND: "four_kind",
	HandRank.STRAIGHT_FLUSH: "straight_flush",
	HandRank.ROYAL_FLUSH: "royal_flush",
	HandRank.ULTIMATE: "ultimate",
}
