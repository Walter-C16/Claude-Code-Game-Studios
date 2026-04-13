class_name DeckManager
extends Node

## DeckManager — Captain Selection and Deck Builder (ADR-0014)
##
## Scene-local Node that manages captain selection state and builds the
## 52-card deck for combat. Emits `combat_configured` via EventBus when
## the player confirms a captain and triggers handoff.
##
## State Machine:
##   CAPTAIN_SELECT → COMPANION_HIGHLIGHTED → CAPTAIN_CONFIRMED
##                           ↕
##                      DECK_VIEWER (read-only overlay)
##                           ↓
##                     HANDOFF_EMITTED
##
## Card schema: {suit, value, element, enhancement, is_signature, companion_id}
## Suits: Hearts, Diamonds, Clubs, Spades (4 suits × 13 values = 52 cards).
## Deck shuffled once at handoff — never on Deck Viewer open.
##
## See: docs/architecture/adr-0014-deck-management.md

# ── State Machine ─────────────────────────────────────────────────────────────

enum CaptainSelectState {
	CAPTAIN_SELECT,
	COMPANION_HIGHLIGHTED,
	CAPTAIN_CONFIRMED,
	DECK_VIEWER,
	HANDOFF_EMITTED,
}

# ── Constants ─────────────────────────────────────────────────────────────────

## Multiplier applied to STR for chip bonus. Sourced from Poker Combat GDD.
const CHIP_BONUS_MULTIPLIER: float = 0.5

## Multiplier applied to INT for mult bonus. Sourced from Poker Combat GDD.
const MULT_BONUS_INCREMENT: float = 0.025

const SUITS: Array[String] = ["Hearts", "Diamonds", "Clubs", "Spades"]

## Value 1 is excluded; Ace = 14 to keep numeric comparison clean.
const VALUES: Array[int] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted locally in addition to EventBus.combat_configured.
signal combat_configured(config: Dictionary)

## Emitted when captain selection state changes.
signal state_changed(new_state: CaptainSelectState)

# ── Export Variables ──────────────────────────────────────────────────────────

## True in Story Mode (read-only deck, no edit controls). False = Abyss Mode.
@export var story_mode: bool = true

# ── Private State ─────────────────────────────────────────────────────────────

var _state: CaptainSelectState = CaptainSelectState.CAPTAIN_SELECT
var _selected_captain_id: String = ""

## The built, unshuffled deck. Populated by build_deck(). Shuffled at handoff.
var _deck: Array[Dictionary] = []

# ── Built-in Virtual Methods ──────────────────────────────────────────────────

func _ready() -> void:
	# Restore last captain from save if available.
	var saved_captain: String = GameStore.get_last_captain_id()
	if not saved_captain.is_empty():
		_selected_captain_id = saved_captain
		_set_state(CaptainSelectState.COMPANION_HIGHLIGHTED)

# ── Public API ────────────────────────────────────────────────────────────────

## Builds and returns an unshuffled 52-card deck sorted by suit-then-value.
## Each card is a Dictionary with 6 fields:
##   suit, value, element, enhancement, is_signature, companion_id.
## The captain's signature card has is_signature=true and companion_id set.
## Call handoff() to shuffle and emit the signal — do NOT shuffle here.
func build_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []

	# Build a (suit, value) → companion_id lookup from the player's deck assignments.
	# Each deck companion has chosen a card_value; their element maps to a suit.
	var signature_lookup: Dictionary = {}
	for cid: String in GameStore.get_deck_companions():
		var profile: Dictionary = CompanionRegistry.get_profile(cid)
		var element: String = profile.get("element", "") as String
		var suit: String = _suit_for_element(element)
		var value: int = GameStore.get_deck_companion_value(cid)
		if suit.is_empty() or value <= 0:
			continue
		signature_lookup[_slot_key(suit, value)] = cid

	for suit: String in SUITS:
		var element: String = CompanionRegistry.get_element_for_suit(suit)
		for value: int in VALUES:
			var key: String = _slot_key(suit, value)
			var companion_id: String = signature_lookup.get(key, "") as String
			var is_signature: bool = not companion_id.is_empty()

			deck.append({
				"suit": suit,
				"value": value,
				"element": element,
				"enhancement": "",
				"is_signature": is_signature,
				"companion_id": companion_id,
			})

	_deck = deck
	return deck


## Returns the canonical suit for a given element (inverse of get_element_for_suit).
func _suit_for_element(element: String) -> String:
	match element:
		"Fire": return "Hearts"
		"Water": return "Diamonds"
		"Earth": return "Clubs"
		"Lightning": return "Spades"
		_: return ""


## Builds a unique key for the (suit, value) slot lookup dictionary.
func _slot_key(suit: String, value: int) -> String:
	return "%s:%d" % [suit, value]

## Returns the chip (flat) bonus for a given STR stat value.
## Formula: floor(STR * CHIP_BONUS_MULTIPLIER). Sourced from Poker Combat GDD.
func get_captain_chip_bonus(str_val: int) -> int:
	return floori(float(str_val) * CHIP_BONUS_MULTIPLIER)

## Returns the mult (multiplier) bonus for a given INT stat value.
## Formula: 1.0 + (INT * MULT_BONUS_INCREMENT). Sourced from Poker Combat GDD.
func get_captain_mult_bonus(int_val: int) -> float:
	return 1.0 + (float(int_val) * MULT_BONUS_INCREMENT)

## Returns the current captain selection state.
func get_state() -> CaptainSelectState:
	return _state

## Returns the currently highlighted/confirmed captain ID. Empty if none.
func get_selected_captain_id() -> String:
	return _selected_captain_id

## Called when the player taps a companion card on the selection grid.
## Only transitions if the companion is met. Unmet companions are silently ignored.
func select_companion(companion_id: String) -> void:
	if _state == CaptainSelectState.HANDOFF_EMITTED:
		return
	var profile: Dictionary = CompanionRegistry.get_profile(companion_id)
	if profile.is_empty():
		return
	var companion_state: Dictionary = GameStore.get_companion_state(companion_id)
	if not companion_state.get("met", false):
		# Unmet companion — no state change, no highlight.
		return
	_selected_captain_id = companion_id
	_set_state(CaptainSelectState.COMPANION_HIGHLIGHTED)

## Confirms the highlighted companion as captain. No-op if no companion highlighted.
func confirm_captain() -> void:
	if _state != CaptainSelectState.COMPANION_HIGHLIGHTED:
		return
	_set_state(CaptainSelectState.CAPTAIN_CONFIRMED)

## Cancels the current selection and returns to CAPTAIN_SELECT.
## Does NOT emit combat_configured.
func cancel_selection() -> void:
	if _state == CaptainSelectState.HANDOFF_EMITTED:
		return
	_selected_captain_id = ""
	_set_state(CaptainSelectState.CAPTAIN_SELECT)

## Opens the deck viewer overlay (requires CAPTAIN_CONFIRMED state).
func open_deck_viewer() -> void:
	if _state != CaptainSelectState.CAPTAIN_CONFIRMED:
		return
	_set_state(CaptainSelectState.DECK_VIEWER)

## Closes the deck viewer and returns to CAPTAIN_CONFIRMED state.
func close_deck_viewer() -> void:
	if _state != CaptainSelectState.DECK_VIEWER:
		return
	_set_state(CaptainSelectState.CAPTAIN_CONFIRMED)

## Builds the deck, shuffles it, persists the captain, and emits combat_configured
## via both the local signal and EventBus.
## Only valid in CAPTAIN_CONFIRMED state.
func handoff() -> void:
	if _state != CaptainSelectState.CAPTAIN_CONFIRMED:
		push_warning("[DeckManager] handoff() called in invalid state %s" % CaptainSelectState.keys()[_state])
		return

	# Build deck if not already built.
	if _deck.is_empty():
		build_deck()

	# Shuffle exactly once at handoff.
	_deck.shuffle()

	# Persist captain BEFORE emitting signal (AC3 DM-004).
	GameStore.set_last_captain_id(_selected_captain_id)

	# Compute bonuses from captain's stats.
	var captain_profile: Dictionary = CompanionRegistry.get_profile(_selected_captain_id)
	var str_val: int = captain_profile.get("str", 0)
	var int_val: int = captain_profile.get("int", 0)

	var config: Dictionary = {
		"captain_id": _selected_captain_id,
		"captain_chip_bonus": get_captain_chip_bonus(str_val),
		"captain_mult_bonus": get_captain_mult_bonus(int_val),
		"deck": _deck.duplicate(),
	}

	_set_state(CaptainSelectState.HANDOFF_EMITTED)
	combat_configured.emit(config)
	EventBus.combat_configured.emit(config)

## Returns true when edit controls (add/remove/enhance) should be visible.
## Always false in Story Mode. True in Abyss Mode (stub).
func are_edit_controls_visible() -> bool:
	return not story_mode

# ── Private Methods ───────────────────────────────────────────────────────────

func _set_state(new_state: CaptainSelectState) -> void:
	_state = new_state
	state_changed.emit(new_state)

## Returns the companion ID whose suit matches [param suit] in CompanionRegistry.
## Returns "" if no companion claims that suit.
func _get_companion_for_suit(suit: String) -> String:
	for companion_id: String in CompanionRegistry.get_all_ids():
		var profile: Dictionary = CompanionRegistry.get_profile(companion_id)
		if profile.get("suit", "") == suit:
			return companion_id
	return ""
