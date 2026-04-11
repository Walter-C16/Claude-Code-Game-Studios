class_name AbyssRun
extends RefCounted

## AbyssRun — Manages a single roguelike run through 8 antes.
##
## Owns the run state machine: LOBBY → ANTE_COMBAT → SHOP → COMPLETE / DEFEAT.
## Run state is ephemeral — NOT written to GameStore mid-ante (only between antes).
## Gold, deck mutations, and buffs are all run-scoped and lost on run end.
##
## AbyssRun reads all tuning values from AbyssConfig (injected at construction).
## No gameplay constants are hardcoded here.
##
## Design contract:
##   - ante_current is 1-indexed (1 = Ante 1, 8 = Ante 8 final)
##   - start_run() transitions LOBBY → ANTE_COMBAT and sets ante_current = 1
##   - complete_ante() awards gold and advances state
##   - defeat() ends the run immediately
##   - get_enemy_config() provides the full config dict for CombatManager
##
## See: design/gdd/abyss-mode.md
## Stories: STORY-ABYSS-002, STORY-ABYSS-004, STORY-ABYSS-005

# ── State Enum ────────────────────────────────────────────────────────────────

enum RunState { LOBBY, ANTE_COMBAT, SHOP, COMPLETE, DEFEAT }

# ── Private Constants ─────────────────────────────────────────────────────────

## Ante elements cycle for enemy flavor. No gameplay effect without a modifier.
const _ANTE_ELEMENTS: Array[String] = ["Fire", "Water", "Earth", "Lightning"]

# ── Public State ──────────────────────────────────────────────────────────────

## Current state machine position.
var state: int = RunState.LOBBY

## Current ante (1-indexed). 0 means the run has not started yet.
var ante_current: int = 0

## Gold accumulated during this run. Never negative. Not carried to main game.
var run_gold: int = 0

## Mutable deck copy for this run. Removals and enhancements mutate this array.
## Does not affect the player's persistent deck.
var deck: Array[Dictionary] = []

## Indices of cards that have been removed from the run deck.
## Accumulated across antes — removals persist within the run.
var removed_cards: Array[int] = []

## Active run buffs. Each entry: { "buff_id": String, "effect": String, "value": Variant }
## Cleared when the run ends.
var run_buffs: Array[Dictionary] = []

## Weekly modifier ID active for this run. Set at start_run(); never changes mid-run.
var modifier_id: String = ""

## Total gold earned across the entire run (for summary — run_gold may be spent down).
var total_gold_earned: int = 0

## Best (highest) score achieved in a single ante during this run.
var best_score: int = 0

# ── Private State ─────────────────────────────────────────────────────────────

## Injected config — never access JSON values directly.
var _config: AbyssConfig = null

# ── Construction ──────────────────────────────────────────────────────────────

## Creates an AbyssRun with the provided config.
## [param config] — AbyssConfig instance. Must not be null.
func _init(config: AbyssConfig) -> void:
	_config = config

# ── Public API — Lifecycle ────────────────────────────────────────────────────

## Starts a new run from LOBBY (or from any terminal state for repeat runs).
##
## Resets all run-scoped state: gold, buffs, removals, ante counter.
## Copies [param starting_deck] so the persistent deck is never mutated.
## [param weekly_modifier] is stored; rotation mid-run does NOT change it.
func start_run(starting_deck: Array[Dictionary], weekly_modifier: String = "") -> void:
	state = RunState.ANTE_COMBAT
	ante_current = 1
	run_gold = 0
	total_gold_earned = 0
	best_score = 0
	deck = starting_deck.duplicate(true)
	run_buffs.clear()
	removed_cards.clear()
	modifier_id = weekly_modifier

## Resolves a completed ante after the player meets the score threshold.
##
## Awards gold based on hands used and ante completion bonus.
## Golden Hand buff (hand_gold_bonus effect) stacks onto base per-hand gold.
## Advances state to SHOP (or COMPLETE if this was ante 8).
##
## [param hands_used] — actual hands played this ante (payload from CombatManager).
## [param score_achieved] — best score for this ante (updates best_score if higher).
func complete_ante(hands_used: int, score_achieved: int = 0) -> void:
	var hand_gold: int = _get_hand_gold_per_play()
	var ante_gold: int = (hands_used * hand_gold) + _config.get_ante_completion_bonus()
	run_gold += ante_gold
	total_gold_earned += ante_gold

	if score_achieved > best_score:
		best_score = score_achieved

	if ante_current >= _config.get_ante_count():
		state = RunState.COMPLETE
	else:
		state = RunState.SHOP

## Ends the run with a defeat result. Transitions to DEFEAT state.
func defeat(score_achieved: int = 0) -> void:
	if score_achieved > best_score:
		best_score = score_achieved
	state = RunState.DEFEAT

## Transitions from SHOP to ANTE_COMBAT for the next ante.
## Increments ante_current. No-op if not in SHOP state.
func enter_next_ante() -> void:
	if state != RunState.SHOP:
		return
	ante_current += 1
	state = RunState.ANTE_COMBAT

# ── Public API — Score / Threshold Queries ────────────────────────────────────

## Returns the score threshold for the current ante.
## Returns -1 if ante_current is out of bounds.
func get_current_threshold() -> int:
	return _config.get_threshold(ante_current)

# ── Public API — Enemy Config ─────────────────────────────────────────────────

## Builds the enemy config dict required by CombatManager.setup().
##
## Incorporates run buff effects (Last Gambit → +hands_allowed, Clear Mind → +discards).
## Element cycles through ANTE_ELEMENTS; modifier element overrides are handled
## in AbyssModifiers before the run begins, not here.
func get_enemy_config() -> Dictionary:
	var base_hands: int = _config.get_hands_per_ante() + _get_buff_bonus("hands_allowed_bonus")
	var base_discards: int = _config.get_discards_per_ante() + _get_buff_bonus("discards_allowed_bonus")
	return {
		"name_key": "ENEMY_ABYSS_ANTE_%d" % ante_current,
		"hp": get_current_threshold(),
		"score_threshold": get_current_threshold(),
		"element": _ANTE_ELEMENTS[(ante_current - 1) % _ANTE_ELEMENTS.size()],
		"hands_allowed": base_hands,
		"discards_allowed": base_discards,
		"type": "Abyss",
	}

# ── Public API — Summary ──────────────────────────────────────────────────────

## Builds the post-run summary dict.
## [param saved_highscore] — the current highscore from SaveManager.
## Updates best_score internally; caller is responsible for persisting it.
func build_run_summary(saved_highscore: int) -> Dictionary:
	var antes_completed: int = 0
	if state == RunState.COMPLETE:
		antes_completed = _config.get_ante_count()
	elif state == RunState.DEFEAT:
		antes_completed = ante_current - 1
	else:
		antes_completed = ante_current

	var is_new_highscore: bool = best_score > saved_highscore
	return {
		"antes_completed": antes_completed,
		"total_gold_earned": total_gold_earned,
		"best_score": best_score,
		"is_new_highscore": is_new_highscore,
	}

# ── Private Helpers ───────────────────────────────────────────────────────────

## Returns gold per hand play, including Golden Hand buff stacking.
func _get_hand_gold_per_play() -> int:
	return _config.get_base_hand_gold() + _get_buff_bonus("hand_gold_bonus")

## Sums all run_buffs that match [param effect_key].
## Returns 0 if no matching buffs are active.
func _get_buff_bonus(effect_key: String) -> int:
	var total: int = 0
	for buff: Dictionary in run_buffs:
		if buff.get("effect", "") == effect_key:
			total += buff.get("value", 0) as int
	return total
