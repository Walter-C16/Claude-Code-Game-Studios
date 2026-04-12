class_name BlessingSystem
extends RefCounted

## BlessingSystem — Stateless Blessing Computation (ADR-0012)
##
## Pure function: inputs → {blessing_chips: int, blessing_mult: float}
## All 20 blessing definitions are loaded from res://assets/data/blessings.json.
## No hardcoded numeric values. No persistent state. No signals. Not an autoload.
##
## Evaluation order: slots 1-5 sequentially. Order is load-bearing because
## Nyx Slot 4 (Tidal Surge) depends on accumulated blessing_chips from prior slots.
##
## Stage → max slot mapping (Rule 2 from divine-blessings.md):
##   Stage 0 → 0 slots  (Stranger)
##   Stage 1 → 1 slot   (Acquaintance)
##   Stage 2 → 2 slots  (Friend)
##   Stage 3 → 4 slots  (Close — jumps from 2 to 4)
##   Stage 4 → 5 slots  (Devoted)
##
## hand_context required fields (DB-001 AC5):
##   cards_played          Array[Dictionary]  — played card dicts
##   hand_rank             String             — e.g. "Three of a Kind"
##   hand_rank_value       int                — numeric rank (0=High Card … 9=Royal Flush)
##   suit_counts           Dictionary         — { "Hearts": 3, "Clubs": 2, … }
##   current_score         int                — score accumulated before this hand
##   hands_played          int                — total PLAY actions used so far
##   discards_used         int                — total discards used this combat
##   discards_remaining    int                — discards remaining this combat
##   discards_allowed      int                — discards_allowed at combat start
##   signature_card_played bool               — true if captain's signature card is in cards_played
##   raw_hand_chips        int                — base hand chips before any bonuses
##   hands_scoring_above   Dictionary         — { threshold_int: count_of_hands } for Earth Memory
##
## See: docs/architecture/adr-0012-divine-blessings.md
## Stories: DB-001, DB-002, DB-003, DB-004, DB-006

# ── Hand rank constants (must match hand_ranks.json order) ───────────────────

const RANK_HIGH_CARD: int       = 0
const RANK_PAIR: int            = 1
const RANK_TWO_PAIR: int        = 2
const RANK_THREE_OF_A_KIND: int = 3
const RANK_STRAIGHT: int        = 4
const RANK_FLUSH: int           = 5
const RANK_FULL_HOUSE: int      = 6
const RANK_FOUR_OF_A_KIND: int  = 7
const RANK_STRAIGHT_FLUSH: int  = 8
const RANK_ROYAL_FLUSH: int     = 9

# ── Data cache ───────────────────────────────────────────────────────────────

## Loaded once on first compute() call. Keyed by captain_id → Array of blessing dicts.
## Static to persist across RefCounted instances (mirrors the ADR's "load once" intent).
static var _blessings_cache: Dictionary = {}
static var _cache_loaded: bool = false

# ── Public API ───────────────────────────────────────────────────────────────

## Computes the total blessing_chips and blessing_mult for the active captain's
## unlocked blessing slots given the current hand context.
##
## Parameters:
##   captain_id    — companion ID string (e.g. "artemis", "nyx")
##   romance_stage — the FROZEN stage snapshot from combat start (0-4)
##   hand_context  — dict with all 12 required fields (see class header)
##
## Returns: { blessing_chips: int, blessing_mult: float }
## Returns { 0, 0.0 } for stage 0 or unknown captain_id.
static func compute(
		captain_id: String,
		romance_stage: int,
		hand_context: Dictionary) -> Dictionary:
	_ensure_data()

	var max_slot: int = _max_slot_for_stage(romance_stage)
	if max_slot == 0:
		return { "blessing_chips": 0, "blessing_mult": 0.0 }

	var all_blessings: Array = _blessings_cache.get(captain_id, []) as Array
	if all_blessings.is_empty():
		return { "blessing_chips": 0, "blessing_mult": 0.0 }

	var blessing_chips: int   = 0
	var blessing_mult: float  = 0.0

	# Sequential evaluation 1-5. Order is load-bearing — do not reorder.
	for slot_num: int in range(1, max_slot + 1):
		var blessing: Dictionary = _find_slot(all_blessings, slot_num)
		if blessing.is_empty():
			continue

		if _evaluate_trigger(blessing, hand_context, blessing_chips):
			blessing_chips += _compute_chips(blessing, hand_context)
			blessing_mult  += _compute_mult(blessing, hand_context)

	return { "blessing_chips": blessing_chips, "blessing_mult": blessing_mult }


## Returns all 5 blessing dicts for a companion regardless of stage.
## Used by UI to render the blessing strip in the companion room.
## Returns empty Array if captain_id is not found.
static func get_blessing_info(captain_id: String) -> Array[Dictionary]:
	_ensure_data()
	var raw: Array = _blessings_cache.get(captain_id, []) as Array
	var result: Array[Dictionary] = []
	for b: Variant in raw:
		result.append(b as Dictionary)
	return result


## Returns the maximum active slot index for a given romance stage.
## Stage 3 jumps from slot 2 directly to slot 4 (unlocks slots 3 AND 4 together).
##   Stage 0 → 0, Stage 1 → 1, Stage 2 → 2, Stage 3 → 4, Stage 4 → 5
static func _max_slot_for_stage(stage: int) -> int:
	match stage:
		0: return 0
		1: return 1
		2: return 2
		3: return 4
		4: return 5
	return 0


# ── Trigger Evaluation ───────────────────────────────────────────────────────

## Returns true if the blessing's trigger condition is met for this hand.
## accumulated_chips is the sum of blessing_chips from all prior slots this hand.
## Required for Nyx Slot 4 (accumulated_chips_min trigger).
static func _evaluate_trigger(
		blessing: Dictionary,
		ctx: Dictionary,
		accumulated_chips: int) -> bool:
	var trigger_type: String = blessing.get("trigger_type", "") as String

	match trigger_type:
		"always":
			# Nyx Slot 5 — unconditional, fires every hand
			return true

		"per_card":
			# Per-card blessings always fire; chips/mult scaled by count in _compute_chips/_compute_mult
			return true

		"suit_count":
			# Fires if the played hand contains at least min_count cards of the given suit
			var suit: String = blessing.get("suit", "") as String
			var min_count: int = blessing.get("min_count", 1) as int
			var counts: Dictionary = ctx.get("suit_counts", {}) as Dictionary
			return (counts.get(suit, 0) as int) >= min_count

		"hand_rank_min":
			# Fires if hand_rank_value >= blessing.min_rank
			var min_rank: int = blessing.get("min_rank", 0) as int
			return (ctx.get("hand_rank_value", 0) as int) >= min_rank

		"cards_played_eq":
			# Fires if exactly blessing.count cards were played this hand
			var count: int = blessing.get("count", 5) as int
			var played: Array = ctx.get("cards_played", []) as Array
			return played.size() == count

		"hands_played_max":
			# Fires if hands_played <= blessing.max_hands (0-indexed before increment)
			var max_hands: int = blessing.get("max_hands", 2) as int
			return (ctx.get("hands_played", 0) as int) <= max_hands

		"discards_used_min":
			# Fires if discards_used >= blessing.min_discards
			var min_discards: int = blessing.get("min_discards", 1) as int
			return (ctx.get("discards_used", 0) as int) >= min_discards

		"discards_remaining_eq":
			# Fires if discards_remaining == discards_allowed (no discards used yet)
			var remaining: int = ctx.get("discards_remaining", 0) as int
			var allowed: int   = ctx.get("discards_allowed", 0) as int
			return remaining == allowed

		"signature_card":
			# Fires if the captain's signature card is among the played cards
			return ctx.get("signature_card_played", false) as bool

		"accumulated_chips_min":
			# Fires if chips accumulated from PRIOR slots this hand >= min_chips (Nyx Slot 4)
			var min_chips: int = blessing.get("min_chips", 0) as int
			return accumulated_chips >= min_chips

		"raw_chips_max":
			# Fires if the raw hand chips (before all bonuses) <= max_chips (Atenea Slot 5)
			var max_chips: int = blessing.get("max_chips", 40) as int
			return (ctx.get("raw_hand_chips", 0) as int) <= max_chips

		"current_score_gate":
			# Fires if current_score == 0 (first play) OR >= score_threshold (Atenea Slot 4)
			var threshold: int    = blessing.get("score_threshold", 150) as int
			var score: int        = ctx.get("current_score", 0) as int
			return score == 0 or score >= threshold

		"prior_hands_scored":
			# Fires if at least 1 prior hand scored >= blessing.threshold chips (Artemis Slot 3)
			# The count of qualifying hands drives _compute_chips via stacks.
			var threshold: int       = blessing.get("threshold", 60) as int
			var history: Dictionary  = ctx.get("hands_scoring_above", {}) as Dictionary
			return (history.get(threshold, 0) as int) >= 1

		"heart_flush":
			# Fires if hand_rank_value >= FLUSH AND all suit cards are Hearts (Hipolita Slot 5)
			var min_rank: int = blessing.get("min_rank", RANK_FLUSH) as int
			if (ctx.get("hand_rank_value", 0) as int) < min_rank:
				return false
			var counts: Dictionary = ctx.get("suit_counts", {}) as Dictionary
			var played: Array      = ctx.get("cards_played", []) as Array
			var total_played: int  = played.size()
			if total_played == 0:
				return false
			# All played cards must be Hearts
			return (counts.get("Hearts", 0) as int) == total_played

	# Unknown trigger type — safe default
	return false


# ── Value Computation ────────────────────────────────────────────────────────

## Computes the blessing_chips contribution for a triggered blessing.
static func _compute_chips(blessing: Dictionary, ctx: Dictionary) -> int:
	var trigger_type: String = blessing.get("trigger_type", "") as String

	if trigger_type == "per_card":
		# Chips scale by number of matching-suit cards played
		var suit: String  = blessing.get("suit", "") as String
		var per_card: int = blessing.get("chips_per_card", 0) as int
		var counts: Dictionary = ctx.get("suit_counts", {}) as Dictionary
		return per_card * (counts.get(suit, 0) as int)

	if trigger_type == "prior_hands_scored":
		# Chips scale by number of qualifying prior hands, capped at max_stacks
		var threshold: int    = blessing.get("threshold", 60) as int
		var per_stack: int    = blessing.get("chips_per_stack", 12) as int
		var max_stacks: int   = blessing.get("max_stacks", 3) as int
		var history: Dictionary = ctx.get("hands_scoring_above", {}) as Dictionary
		var stacks: int = mini(history.get(threshold, 0) as int, max_stacks)
		return per_stack * stacks

	return blessing.get("chips_flat", 0) as int


## Computes the blessing_mult contribution for a triggered blessing.
static func _compute_mult(blessing: Dictionary, ctx: Dictionary) -> float:
	var trigger_type: String = blessing.get("trigger_type", "") as String

	if trigger_type == "per_card":
		# Mult scales by number of matching-suit cards played
		var suit: String      = blessing.get("suit", "") as String
		var per_card: float   = blessing.get("mult_per_card", 0.0) as float
		var counts: Dictionary = ctx.get("suit_counts", {}) as Dictionary
		return per_card * (counts.get(suit, 0) as int)

	return blessing.get("mult_flat", 0.0) as float


# ── Data Loading ─────────────────────────────────────────────────────────────

## Loads blessings.json on first call. Subsequent calls are no-ops.
## Indexes blessings by captain_id → sorted Array of blessing dicts.
static func _ensure_data() -> void:
	if _cache_loaded:
		return

	var path: String = "res://assets/data/blessings.json"
	var raw: Dictionary = JsonLoader.load_dict(path)
	_cache_loaded = true
	if raw.is_empty():
		return

	for captain_id: String in raw.keys():
		var blessings: Array = raw[captain_id] as Array
		# Sort by slot number — BlessingSystem iterates slots in order 1..5
		# and stops at the first inactive slot (stage-gated). Order is
		# load-bearing: if slots aren't pre-sorted, unlocks can skip valid
		# blessings at lower slots.
		blessings.sort_custom(_compare_slots)
		_blessings_cache[captain_id] = blessings


## Compares two blessing dictionaries by their slot number (ascending).
static func _compare_slots(a: Dictionary, b: Dictionary) -> bool:
	return (a.get("slot", 0) as int) < (b.get("slot", 0) as int)


## Returns the blessing dict for a specific slot number, or empty dict if not found.
static func _find_slot(blessings: Array, slot_num: int) -> Dictionary:
	for b: Variant in blessings:
		var blessing: Dictionary = b as Dictionary
		if (blessing.get("slot", -1) as int) == slot_num:
			return blessing
	return {}
