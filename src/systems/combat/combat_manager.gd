class_name CombatManager
extends RefCounted

## Combat State Machine for Poker Combat (ADR-0007)
##
## Owns the full encounter lifecycle:
##   SETUP → DRAW → SELECT → RESOLVE / DISCARD_DRAW → VICTORY / DEFEAT
##
## CombatManager is a scene-local RefCounted. It is NOT an autoload.
## All mutable combat state lives here and is discarded when the object is freed.
## No in-progress combat state is ever written to GameStore.
##
## Outcomes are broadcast via EventBus.combat_completed signal.
## Social buff lifecycle (decrement on victory, retain on defeat) is applied
## against GameStore via the injected game_store reference.
##
## BlessingSystem is called as a pure black box. CombatManager does NOT inspect
## blessing internals — it receives {blessing_chips: int, blessing_mult: float}.
##
## See: docs/architecture/adr-0007-poker-combat.md
## Stories: STORY-COMBAT-008, STORY-COMBAT-009, STORY-COMBAT-010

# ── State Enum ────────────────────────────────────────────────────────────────

enum State { SETUP, DRAW, SELECT, RESOLVE, DISCARD_DRAW, VICTORY, DEFEAT }

# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted whenever the combat state machine transitions to a new state.
signal state_changed(new_state: int)

# ── Public State ──────────────────────────────────────────────────────────────

## Current state machine position. Read-only from outside — use actions to advance.
var state: int = State.SETUP

## Cards remaining in the draw pile.
var deck: Array[Dictionary] = []

## Cards currently in the player's hand.
var hand: Array[Dictionary] = []

## Running score accumulator. Resets to 0 at SETUP.
var current_score: int = 0

## Enemy score threshold for VICTORY.
var score_threshold: int = 0

## PLAY actions remaining before DEFEAT is triggered.
var hands_remaining: int = 4

## DISCARD actions remaining for this encounter.
var discards_remaining: int = 4

## Total PLAY actions used in this encounter (used in combat_completed payload).
var hands_used: int = 0

## Total DISCARD actions used this encounter. Used in BlessingSystem hand_context.
## Increments on each discard() call.
var discards_used: int = 0

## Allowed discards at combat start. Frozen at SETUP for hand_context.
var discards_allowed: int = 4

## History of per-hand raw chip scores for Artemis Slot 3 (Earth Memory).
## Each entry is the raw chip total scored that hand.
var _hands_chips_history: Array[int] = []

# ── Private Config ────────────────────────────────────────────────────────────

## Frozen snapshot of enemy configuration set at SETUP.
var _enemy_config: Dictionary = {}

## Frozen scoring context built at SETUP.
## Keys: captain_chip_bonus, captain_mult_modifier, captain_id,
##       social_buff_chips, social_buff_mult, romance_stages.
var _captain_context: Dictionary = {}

## Frozen romance_stages snapshot (keyed by companion_id → stage int).
## Populated at SETUP; never updated during combat (ADR-0007 AC5).
var _romance_stages: Dictionary = {}

## Reference to GameStore for social buff lifecycle (injected for testability).
## When null, CombatManager skips buff lifecycle (used in pure unit tests).
var _game_store: Object = null

## Reference to EventBus for combat_completed emission (injected for testability).
## When null, CombatManager skips signal emission (used in pure unit tests).
var _event_bus: Object = null

# ── Setup ─────────────────────────────────────────────────────────────────────

## Initialises a new combat encounter.
##
## Parameters:
##   enemy       — enemy config dict. Required keys:
##                   score_threshold (int), hands_allowed (int >= 1),
##                   discards_allowed (int >= 1), element (String).
##   captain_ctx — scoring context built by the caller. Expected keys:
##                   captain_chip_bonus (int), captain_mult_modifier (float),
##                   captain_id (String), social_buff_chips (int),
##                   social_buff_mult (float), romance_stages (Dictionary).
##   game_store  — optional GameStore reference for social buff lifecycle.
##                   Pass null to disable (pure unit tests).
##   event_bus   — optional EventBus reference for combat_completed emission.
##                   Pass null to disable (pure unit tests).
##
## Returns false and logs an error if enemy config fails validation.
func setup(
		enemy: Dictionary,
		captain_ctx: Dictionary,
		game_store: Object = null,
		event_bus: Object = null) -> bool:
	# Validate hands_allowed — must be >= 1 (AC10)
	var hands_allowed: int = enemy.get("hands_allowed", 4) as int
	if hands_allowed < 1:
		push_error(
			"CombatManager.setup(): enemy config hands_allowed=%d is invalid (must be >= 1). Combat not started."
			% hands_allowed)
		return false

	# Validate discards_allowed — must be >= 1
	var discards_allowed: int = enemy.get("discards_allowed", 4) as int
	if discards_allowed < 1:
		push_error(
			"CombatManager.setup(): enemy config discards_allowed=%d is invalid (must be >= 1). Combat not started."
			% discards_allowed)
		return false

	_enemy_config = enemy
	_captain_context = captain_ctx.duplicate(true)
	_game_store = game_store
	_event_bus = event_bus

	# Freeze romance_stages snapshot at SETUP (ADR-0007 AC5)
	_romance_stages = (captain_ctx.get("romance_stages", {}) as Dictionary).duplicate(true)

	score_threshold    = enemy.get("score_threshold", 40) as int
	hands_remaining    = hands_allowed
	discards_remaining = discards_allowed
	discards_allowed   = discards_allowed
	current_score      = 0
	hands_used         = 0
	discards_used      = 0
	_hands_chips_history.clear()

	deck = Deck.create_standard_deck()
	deck = Deck.shuffle_deck(deck)

	state = State.DRAW
	_draw_hand()
	return true


# ── Player Actions ────────────────────────────────────────────────────────────

## Plays the cards at the given indices from the current hand.
##
## selected_indices must be non-empty and state must be SELECT.
## Returns a result Dictionary on success, or an empty Dictionary on rejection.
##
## Result schema:
##   { rank: String, chips: int, mult: float, score: int, total: int }
func play_hand(selected_indices: Array[int]) -> Dictionary:
	if state != State.SELECT:
		return {}
	if selected_indices.is_empty():
		return {}
	if hands_remaining <= 0:
		return {}

	state = State.RESOLVE

	# Collect the played cards in selection order
	var played_cards: Array[Dictionary] = []
	for idx: int in selected_indices:
		if idx >= 0 and idx < hand.size():
			played_cards.append(hand[idx])

	if played_cards.is_empty():
		state = State.SELECT
		return {}

	# Call BlessingSystem if available (black-box — never inspect internals)
	var blessing_result: Dictionary = _compute_blessings(played_cards)

	# Build the per-hand scoring context by merging the frozen captain context
	# with blessing values returned from BlessingSystem.
	var context: Dictionary = _captain_context.duplicate(true)
	context["enemy_element"] = _enemy_config.get("element", "") as String
	context["blessing_chips"] = blessing_result.get("blessing_chips", 0) as int
	context["blessing_mult"]  = blessing_result.get("blessing_mult",  0.0) as float

	var hand_eval: Dictionary = HandEvaluator.evaluate(played_cards)
	var chips: int   = ScoreCalculator.calculate_chips(played_cards, hand_eval, context)
	var mult: float  = ScoreCalculator.calculate_mult(played_cards, hand_eval, context)
	var score: int   = ScoreCalculator.calculate_score(chips, mult)

	current_score += score
	hands_remaining -= 1
	hands_used += 1
	# Record chips for Artemis Slot 3 Earth Memory (prior_hands_scored trigger)
	_hands_chips_history.append(chips)

	# Remove played cards from hand (descending index order to avoid shift errors)
	var sorted_indices: Array[int] = selected_indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	for idx: int in sorted_indices:
		if idx >= 0 and idx < hand.size():
			hand.remove_at(idx)

	var result: Dictionary = {
		"rank":  hand_eval.get("rank", "") as String,
		"chips": chips,
		"mult":  mult,
		"score": score,
		"total": current_score,
	}

	# Victory check before defeat check (ADR-0007, AC6 of COMBAT-008)
	if current_score >= score_threshold:
		state = State.VICTORY
		_on_victory()
		return result

	# Defeat check: hands exhausted and score still below threshold (AC7)
	if hands_remaining <= 0:
		state = State.DEFEAT
		_on_defeat()
		return result

	# Still in play — draw new cards and return to SELECT
	state = State.DRAW
	_draw_hand()
	return result


## Discards the cards at the given indices and draws replacements.
##
## selected_indices must be non-empty, state must be SELECT, and
## discards_remaining must be > 0. Silent no-op on any violation (AC8, AC9).
func discard(selected_indices: Array[int]) -> void:
	if state != State.SELECT:
		return
	if selected_indices.is_empty():
		return
	if discards_remaining <= 0:
		return

	state = State.DISCARD_DRAW
	discards_remaining -= 1
	discards_used += 1

	# Remove discarded cards (descending to avoid shift)
	var sorted_indices: Array[int] = selected_indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	for idx: int in sorted_indices:
		if idx >= 0 and idx < hand.size():
			hand.remove_at(idx)

	# Refill hand up to 5 cards from the remaining deck
	var need: int  = 5 - hand.size()
	var draw: int  = mini(need, deck.size())
	for _i: int in range(draw):
		hand.append(deck.pop_front())

	state = State.SELECT
	state_changed.emit(state)


# ── State Query ───────────────────────────────────────────────────────────────

## Returns a snapshot of the current combat state for UI consumption.
## Returned Dictionary is safe to mutate — it holds duplicated values.
func get_state() -> Dictionary:
	return {
		"state":             state,
		"current_score":     current_score,
		"score_threshold":   score_threshold,
		"hands_remaining":   hands_remaining,
		"discards_remaining": discards_remaining,
		"discards_allowed":  discards_allowed,
		"discards_used":     discards_used,
		"hands_used":        hands_used,
		"hand_cards":        hand.duplicate(true),
	}


# ── Private ───────────────────────────────────────────────────────────────────

## Draws cards from the deck into the hand up to 5.
## Triggers auto-defeat if the deck is empty (AC4).
func _draw_hand() -> void:
	hand.clear()
	var draw_count: int = mini(5, deck.size())

	# Deck exhausted with no cards — auto-defeat (AC4)
	if draw_count == 0:
		state = State.DEFEAT
		_on_defeat()
		return

	for _i: int in range(draw_count):
		hand.append(deck.pop_front())

	state = State.SELECT
	state_changed.emit(state)


## Called when VICTORY state is entered.
## Applies social buff lifecycle and emits combat_completed via EventBus.
func _on_victory() -> void:
	state_changed.emit(state)
	_consume_social_buff()
	_emit_combat_completed(true)


## Called when DEFEAT state is entered.
## Social buff is retained on defeat (ADR-0007, AC6 of COMBAT-009).
func _on_defeat() -> void:
	state_changed.emit(state)
	# Buff intentionally NOT consumed — retained for retry.
	_emit_combat_completed(false)


## Decrements social buff combats_remaining on VICTORY.
## Marks buff inactive when combats_remaining reaches 0 (AC7 of COMBAT-009).
## No-op if GameStore is not injected or buff is inactive.
func _consume_social_buff() -> void:
	if _game_store == null:
		return
	if not _game_store.has_method("get_combat_buff"):
		return

	var buff: Dictionary = _game_store.get_combat_buff() as Dictionary
	if buff.is_empty():
		return

	var remaining: int = buff.get("combats_remaining", 0) as int
	if remaining <= 0:
		return

	remaining -= 1
	if remaining <= 0:
		# Buff exhausted — mark inactive by clearing it (AC7)
		_game_store.clear_combat_buff()
	else:
		buff["combats_remaining"] = remaining
		_game_store.set_combat_buff(buff)


## Emits combat_completed on EventBus (if injected).
## Payload schema: { victory: bool, score: int, hands_used: int, captain_id: String }
func _emit_combat_completed(victory: bool) -> void:
	if _event_bus == null:
		return
	if not _event_bus.has_signal("combat_completed"):
		return

	var payload: Dictionary = {
		"victory":    victory,
		"score":      current_score,
		"hands_used": hands_used,
		"captain_id": _captain_context.get("captain_id", "") as String,
	}
	_event_bus.combat_completed.emit(payload)


## Calls BlessingSystem.compute() as a black box (ADR-0007, ADR-0012, DB-006).
##
## Builds the full 12-field hand_context required by BlessingSystem (DB-001 AC5):
##   cards_played, hand_rank, hand_rank_value, suit_counts, current_score,
##   hands_played, discards_used, discards_remaining, discards_allowed,
##   signature_card_played, raw_hand_chips, hands_scoring_above.
##
## Resolves the frozen romance_stage for the captain from _romance_stages.
## CombatManager does NOT access any BlessingSystem internal fields — it only
## calls compute() and reads the two returned values (blessing_chips, blessing_mult).
##
## Returns { blessing_chips: int, blessing_mult: float } or zeros if unavailable.
func _compute_blessings(played_cards: Array[Dictionary]) -> Dictionary:
	var captain_id: String  = _captain_context.get("captain_id", "") as String
	var romance_stage: int  = (_romance_stages.get(captain_id, 0) as int)

	# Evaluate hand rank for context building (lightweight, no side effects)
	var hand_eval: Dictionary = HandEvaluator.evaluate(played_cards)

	# Build suit_counts from played cards
	var suit_counts: Dictionary = {}
	for card: Dictionary in played_cards:
		var suit: String = card.get("suit", "") as String
		if suit.is_empty():
			continue
		suit_counts[suit] = (suit_counts.get(suit, 0) as int) + 1

	# Determine raw hand chips (base_hand_chips only, before bonuses)
	var raw_hand_chips: int = hand_eval.get("base_chips", 0) as int

	# Build hands_scoring_above for Artemis Slot 3 (Earth Memory).
	# Counts how many prior hands scored >= 60 chips (threshold is from the blessing).
	var hands_scoring_above: Dictionary = {}
	for prior_chips: int in _hands_chips_history:
		for threshold: int in [60]:  # thresholds used by Earth Memory
			if prior_chips >= threshold:
				hands_scoring_above[threshold] = (hands_scoring_above.get(threshold, 0) as int) + 1

	# Determine if captain's signature card is among played cards.
	# Signature card is identified by card_value (from companions.json).
	var signature_card_played: bool = false
	var captain_card_value: int = _captain_context.get("captain_card_value", -1) as int
	if captain_card_value >= 0:
		for card: Dictionary in played_cards:
			if (card.get("value", -1) as int) == captain_card_value:
				signature_card_played = true
				break

	# Build complete 12-field hand_context (DB-001 AC5, DB-006 AC3)
	var hand_context: Dictionary = {
		"cards_played":          played_cards,
		"hand_rank":             hand_eval.get("rank", "") as String,
		"hand_rank_value":       hand_eval.get("rank_value", 0) as int,
		"suit_counts":           suit_counts,
		"current_score":         current_score,
		"hands_played":          hands_used,  # count before this hand increments
		"discards_used":         discards_used,
		"discards_remaining":    discards_remaining,
		"discards_allowed":      discards_allowed,
		"signature_card_played": signature_card_played,
		"raw_hand_chips":        raw_hand_chips,
		"hands_scoring_above":   hands_scoring_above,
	}

	# BlessingSystem is called as a static class — no injection needed.
	# Black-box contract: only read the two declared output keys.
	var result: Dictionary = BlessingSystem.compute(captain_id, romance_stage, hand_context)
	return {
		"blessing_chips": result.get("blessing_chips", 0) as int,
		"blessing_mult":  result.get("blessing_mult",  0.0) as float,
	}
