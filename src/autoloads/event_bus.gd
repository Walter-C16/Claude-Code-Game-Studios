extends Node

## EventBus — Cross-System Signal Relay (ADR-0004)
##
## Pure relay node. Declares all cross-layer signals. No state, no logic.
## Emitters: EventBus.[signal].emit(). Listeners: EventBus.[signal].connect().
## Boot order: Autoload #3 (after GameStore, SettingsStore).
##
## See: docs/architecture/adr-0004-eventbus.md

# ── Romance Signals ──────────────────────────────────────────────────────────
# Emitted by: CompanionState (via RomanceSocial)
# Listeners:  BlessingSystem, UI layer

## Fired when a companion's romance stage transitions (relationship thresholds).
## old_stage and new_stage are RomanceSocial stage indices (0 = stranger).
signal romance_stage_changed(companion_id: String, old_stage: int, new_stage: int)

## Fired when daily interaction tokens are reset at the midnight UTC day boundary.
## Listeners should call GameStore.reset_tokens() or refresh their token UI.
signal tokens_reset

# ── Combat Signals ───────────────────────────────────────────────────────────
# Emitted by: CombatSystem
# Listeners:  StoryFlow, BlessingSystem, UI layer

## Fired when a combat encounter ends (victory or defeat).
## result dict schema: {victory: bool, score: int, hands_used: int, captain_id: String}
signal combat_completed(result: Dictionary)

# ── Dialogue Signals ─────────────────────────────────────────────────────────
# Emitted by: DialogueRunner
# Listeners:  StoryFlow, RomanceSocial, UI layer

## Fired when a dialogue sequence finishes normally (reached an end node).
signal dialogue_ended(sequence_id: String)

## Fired when a dialogue sequence cannot start because prerequisites are not met.
## reason is a human-readable string for debug logging (e.g. "flag_missing:met_artemis").
signal dialogue_blocked(sequence_id: String, reason: String)

## Fired when a dialogue effect applies a relationship delta to a companion.
## delta is signed: positive = gain, negative = loss.
signal relationship_changed(companion_id: String, delta: int)

## Fired when a dialogue effect applies a trust delta to a companion.
## delta is signed: positive = gain, negative = loss.
signal trust_changed(companion_id: String, delta: int)

## Fired when a companion is encountered for the first time via a dialogue effect.
signal companion_met(companion_id: String)

## Fired when a dialogue effect grants an item to the player.
## quantity is the number of items granted (always >= 1).
signal item_granted(item_id: String, quantity: int)

# ── Story Signals ────────────────────────────────────────────────────────────
# Emitted by: StoryFlow
# Listeners:  UI layer, SaveManager (deferred flush trigger)

## Fired when a story chapter reaches its terminal node and is marked complete.
signal chapter_completed(chapter_id: String)

## Fired when any individual story node transitions to the "complete" state.
signal node_completed(node_id: String)

# ── Deck Management Signals ──────────────────────────────────────────────────
# Emitted by: DeckManager
# Listeners:  CombatSystem

## Fired when captain selection is confirmed and the deck is shuffled.
## config dict schema: {captain_id: String, captain_chip_bonus: int,
##   captain_mult_bonus: float, deck: Array[Dictionary]}
signal combat_configured(config: Dictionary)

# ── Boss / Music Signals ──────────────────────────────────────────────────────
# Emitted by: StoryFlow (boss node entry)
# Listeners:  AudioManager, UI layer

## Fired when a boss node is entered to trigger boss music and HP bar.
signal boss_encounter_started(enemy_id: String)

## Fired when a companion is revealed / met for the first time.
signal companion_unlocked(companion_id: String)

## Fired when midnight UTC day boundary resets tokens.
signal midnight_reset
