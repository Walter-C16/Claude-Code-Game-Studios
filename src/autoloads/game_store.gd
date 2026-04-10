extends Node

# GameStore — Centralized Mutable Game State (ADR-0001)
#
# Single autoload that owns ALL mutable game state for Dark Olympus.
# Every gameplay system reads and writes state exclusively through this
# node's public API. No system maintains parallel persistent state.
#
# Boot order: Autoload #1. _ready() must NOT reference any other autoload.
#
# See: docs/architecture/adr-0001-gamestore-state.md

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted after any state mutation. `key` identifies which logical group
## changed (e.g. "companion", "gold", "flag", "combat_buff").
signal state_changed(key: String)

# ---------------------------------------------------------------------------
# Private State — Companion
# ---------------------------------------------------------------------------

## Per-companion state dictionaries keyed by companion ID.
## Schema per entry: relationship_level, trust, motivation, dates_completed,
## met, known_likes, known_dislikes, current_mood, mood_expiry_date.
var _companion_states: Dictionary = {}

# ---------------------------------------------------------------------------
# Private State — Story
# ---------------------------------------------------------------------------

## Write-once story flag strings. Checked with has_flag(). (ADR-0001)
var _story_flags: Array[String] = []

## Per-dialogue-node state strings. {node_id: state_string}
var _node_states: Dictionary = {}

## Active chapter identifier (e.g. "ch01").
var _current_chapter: String = ""

# ---------------------------------------------------------------------------
# Private State — Economy
# ---------------------------------------------------------------------------

var _player_gold: int = 0
var _player_xp: int = 0

# ---------------------------------------------------------------------------
# Private State — Romance / Tokens
# ---------------------------------------------------------------------------

var _daily_tokens_remaining: int = 0
var _current_streak: int = 0

## UTC date string of last companion interaction (YYYY-MM-DD). Empty = never.
var _last_interaction_date: String = ""

# ---------------------------------------------------------------------------
# Private State — Combat
# ---------------------------------------------------------------------------

## Active combat buff dict. Empty = no buff active.
## Expected keys: chips (int), mult (float), combats_remaining (int).
var _active_combat_buff: Dictionary = {}

# ---------------------------------------------------------------------------
# Private State — Captain
# ---------------------------------------------------------------------------

## Companion ID of the last-selected captain. Empty = none selected.
var _last_captain_id: String = ""

# ---------------------------------------------------------------------------
# Private State — Persistence (GS-003 will add deferred flush)
# ---------------------------------------------------------------------------

## True when state has been mutated since the last save flush.
var _dirty: bool = false

## True when a deferred _flush_save() call is already queued for this frame.
## Prevents duplicate call_deferred() calls when multiple setters fire in the
## same frame (ADR-0001, STORY-GS-003).
var _save_pending: bool = false

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Boot order rule: do NOT reference any other autoload here.
	_initialize_defaults()

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

## Resets all state to factory defaults.
## Called on fresh game start (no save file). Also used by tests.
func _initialize_defaults() -> void:
	for id: String in ["artemisa", "hipolita", "atenea", "nyx"]:
		_companion_states[id] = {
			"relationship_level": 0, "trust": 0, "motivation": 50,
			"dates_completed": 0, "met": false,
			"known_likes": [], "known_dislikes": [],
			"current_mood": 0, "mood_expiry_date": ""
		}
	_story_flags = []
	_node_states = {}
	_current_chapter = "ch01"
	_player_gold = 0
	_player_xp = 0
	_daily_tokens_remaining = 3
	_current_streak = 0
	_last_interaction_date = ""
	_active_combat_buff = {}
	_last_captain_id = ""

# ---------------------------------------------------------------------------
# Public Getters — Companion State
# ---------------------------------------------------------------------------

## Returns a shallow copy of the companion state dict for the given ID.
## Returns an empty Dictionary if `id` is not found.
func get_companion_state(id: String) -> Dictionary:
	if not _companion_states.has(id):
		return {}
	return _companion_states[id].duplicate()

## Returns the relationship_level for the given companion ID.
## Returns 0 if `id` is not found.
func get_relationship_level(id: String) -> int:
	if not _companion_states.has(id):
		return 0
	return _companion_states[id].get("relationship_level", 0)

## Sets the trust value for a companion and marks state dirty.
## No-op if `id` is not a known companion.
func set_trust(id: String, value: int) -> void:
	if not _companion_states.has(id):
		return
	_companion_states[id]["trust"] = value
	_mark_dirty()
	state_changed.emit("companion")

## Sets the met flag for a companion and marks state dirty.
## No-op if `id` is not a known companion.
func set_met(id: String, value: bool) -> void:
	if not _companion_states.has(id):
		return
	_companion_states[id]["met"] = value
	_mark_dirty()
	state_changed.emit("companion")

## Returns the current_mood for the given companion ID.
## Returns 0 if `id` is not found.
func get_mood(id: String) -> int:
	if not _companion_states.has(id):
		return 0
	return _companion_states[id].get("current_mood", 0)

## Sets the current_mood and mood_expiry_date for a companion.
## No-op if `id` is not a known companion.
func set_mood(id: String, mood: int, expiry: String) -> void:
	if not _companion_states.has(id):
		return
	_companion_states[id]["current_mood"] = mood
	_companion_states[id]["mood_expiry_date"] = expiry
	_mark_dirty()
	state_changed.emit("companion")

# ---------------------------------------------------------------------------
# Internal — Companion (CompanionState ADR-0009 only)
# ---------------------------------------------------------------------------

## Sets relationship_level directly. INTERNAL USE ONLY — CompanionState
## (ADR-0009) is the only permitted caller. Direct callers bypass stage
## derivation and romance_stage_changed signal emission. Do NOT make public.
func _set_relationship_level(id: String, value: int) -> void:
	if not _companion_states.has(id):
		return
	_companion_states[id]["relationship_level"] = value
	_mark_dirty()
	state_changed.emit("companion")

# ---------------------------------------------------------------------------
# Public Getters — Story State
# ---------------------------------------------------------------------------

## Returns a copy of the full story_flags array.
func get_story_flags() -> Array[String]:
	return _story_flags.duplicate()

## Returns true if the given flag string is present.
func has_flag(flag: String) -> bool:
	return _story_flags.has(flag)

## Adds a flag string to story_flags. Write-once and idempotent:
## calling with an already-present flag is a no-op (no duplicate added).
func set_flag(flag: String) -> void:
	if _story_flags.has(flag):
		return
	_story_flags.append(flag)
	_mark_dirty()
	state_changed.emit("flag")

## Removes a flag string from story_flags if present. No-op if absent.
## Used by dialogue effect type "flag_clear" (ADR-0008).
func clear_flag(flag: String) -> void:
	var idx: int = _story_flags.find(flag)
	if idx == -1:
		return
	_story_flags.remove_at(idx)
	_mark_dirty()
	state_changed.emit("flag")

## Returns the state string for a dialogue node. Returns an empty String
## (not null) if the node_id has never been written.
func get_node_state(node_id: String) -> String:
	return _node_states.get(node_id, "")

## Writes the state string for a dialogue node and marks state dirty.
func set_node_state(node_id: String, state: String) -> void:
	_node_states[node_id] = state
	_mark_dirty()
	state_changed.emit("node_state")

# ---------------------------------------------------------------------------
# Public Getters — Economy
# ---------------------------------------------------------------------------

## Returns the current player XP amount.
func get_xp() -> int:
	return _player_xp

## Adds `amount` to player XP and marks state dirty.
func add_xp(amount: int) -> void:
	_player_xp += amount
	_mark_dirty()
	state_changed.emit("xp")

## Returns the current player gold amount.
func get_gold() -> int:
	return _player_gold

## Adds `amount` to player gold and marks state dirty.
func add_gold(amount: int) -> void:
	_player_gold += amount
	_mark_dirty()
	state_changed.emit("gold")

## Deducts `amount` from player gold if sufficient funds exist.
## Returns true and deducts on success. Returns false and makes no change
## when `_player_gold < amount`.
func spend_gold(amount: int) -> bool:
	if _player_gold < amount:
		return false
	_player_gold -= amount
	_mark_dirty()
	state_changed.emit("gold")
	return true

# ---------------------------------------------------------------------------
# Public Getters — Combat Buff
# ---------------------------------------------------------------------------

## Returns the active combat buff. Returns an empty Dictionary when no buff
## is active (i.e. after fresh initialization or after clear_combat_buff()).
func get_combat_buff() -> Dictionary:
	return _active_combat_buff.duplicate()

## Sets the active combat buff and marks state dirty.
func set_combat_buff(buff: Dictionary) -> void:
	_active_combat_buff = buff.duplicate()
	_mark_dirty()
	state_changed.emit("combat_buff")

## Clears the active combat buff and marks state dirty.
func clear_combat_buff() -> void:
	_active_combat_buff = {}
	_mark_dirty()
	state_changed.emit("combat_buff")

# ---------------------------------------------------------------------------
# Public Getters — Romance / Tokens
# ---------------------------------------------------------------------------

## Returns the number of daily interaction tokens remaining.
func get_daily_tokens() -> int:
	return _daily_tokens_remaining

## Consumes one daily token. Clamps at 0 — never goes negative.
func spend_token() -> void:
	if _daily_tokens_remaining > 0:
		_daily_tokens_remaining -= 1
		_mark_dirty()
		state_changed.emit("romance")

## Resets daily tokens to the default pool of 3.
func reset_tokens() -> void:
	_daily_tokens_remaining = 3
	_mark_dirty()
	state_changed.emit("romance")

## Returns the current login streak in days.
func get_streak() -> int:
	return _current_streak

## Sets the login streak and marks state dirty.
func set_streak(days: int) -> void:
	_current_streak = days
	_mark_dirty()
	state_changed.emit("romance")

# ---------------------------------------------------------------------------
# Public Getters — Captain
# ---------------------------------------------------------------------------

## Returns the companion ID of the last-selected captain. Empty if none.
func get_last_captain_id() -> String:
	return _last_captain_id

## Sets the last-selected captain by companion ID and marks state dirty.
func set_last_captain_id(id: String) -> void:
	_last_captain_id = id
	_mark_dirty()
	state_changed.emit("captain")

# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes all mutable game state to a flat Dictionary for JSON save.
## Companion known_likes and known_dislikes arrays are duplicated to avoid
## reference sharing between the serialized snapshot and live state.
func to_dict() -> Dictionary:
	var companions: Dictionary = {}
	for id: String in _companion_states:
		var cs: Dictionary = _companion_states[id].duplicate()
		cs["known_likes"] = (_companion_states[id].get("known_likes", []) as Array).duplicate()
		cs["known_dislikes"] = (_companion_states[id].get("known_dislikes", []) as Array).duplicate()
		companions[id] = cs

	return {
		"companion_states": companions,
		"story_flags": _story_flags.duplicate(),
		"node_states": _node_states.duplicate(),
		"current_chapter": _current_chapter,
		"player_gold": _player_gold,
		"player_xp": _player_xp,
		"daily_tokens_remaining": _daily_tokens_remaining,
		"current_streak": _current_streak,
		"last_interaction_date": _last_interaction_date,
		"active_combat_buff": _active_combat_buff.duplicate(),
		"last_captain_id": _last_captain_id,
	}

## Restores mutable game state from a previously serialized Dictionary.
## Does NOT set _dirty — loading a save is not a mutation.
## Uses .get(key, default) throughout for forward compatibility with
## older saves that may not have newer fields.
## Companion reconciliation (add missing / remove unknown IDs) is
## intentionally NOT done here — call SaveManager._reconcile_companions()
## after from_dict() to keep that policy out of the data layer.
func from_dict(data: Dictionary) -> void:
	var saved_companions: Dictionary = data.get("companion_states", {})
	_companion_states.clear()

	for id: Variant in saved_companions:
		var sc: Dictionary = saved_companions[id] as Dictionary
		_companion_states[str(id)] = {
			"relationship_level": sc.get("relationship_level", 0),
			"trust": sc.get("trust", 0),
			"motivation": sc.get("motivation", 50),
			"dates_completed": sc.get("dates_completed", 0),
			"met": sc.get("met", false),
			"known_likes": (sc.get("known_likes", []) as Array).duplicate(),
			"known_dislikes": (sc.get("known_dislikes", []) as Array).duplicate(),
			"current_mood": sc.get("current_mood", 0),
			"mood_expiry_date": sc.get("mood_expiry_date", ""),
		}

	var raw_flags: Array = data.get("story_flags", [])
	_story_flags.clear()
	for flag: Variant in raw_flags:
		_story_flags.append(str(flag))

	_node_states = data.get("node_states", {}).duplicate()
	_current_chapter = data.get("current_chapter", "ch01")
	_player_gold = data.get("player_gold", 0)
	_player_xp = data.get("player_xp", 0)
	_daily_tokens_remaining = data.get("daily_tokens_remaining", 3)
	_current_streak = data.get("current_streak", 0)
	_last_interaction_date = data.get("last_interaction_date", "")
	_active_combat_buff = data.get("active_combat_buff", {}).duplicate()
	_last_captain_id = data.get("last_captain_id", "")
	# Explicitly clear both flags — loading is not a mutation and must not
	# trigger a save flush even if the store had prior dirty state (AC5).
	_dirty = false
	_save_pending = false

## Reconciles _companion_states against the authoritative list of companion IDs.
## For each id in [param known_ids] absent from _companion_states, a default
## state entry is added. For each id in _companion_states absent from
## [param known_ids], that entry is removed.
## Does NOT set _dirty — called on the load path only.
func reconcile_companion_states(known_ids: Array[String]) -> void:
	# Add missing companions.
	for id: String in known_ids:
		if not _companion_states.has(id):
			_companion_states[id] = {
				"relationship_level": 0, "trust": 0, "motivation": 50,
				"dates_completed": 0, "met": false,
				"known_likes": [], "known_dislikes": [],
				"current_mood": 0, "mood_expiry_date": ""
			}

	# Remove companions no longer in the authoritative list.
	var ids_to_remove: Array[String] = []
	for id: String in _companion_states:
		if not known_ids.has(id):
			ids_to_remove.append(id)
	for id: String in ids_to_remove:
		_companion_states.erase(id)

# ---------------------------------------------------------------------------
# Internal — Persistence (GS-003)
# ---------------------------------------------------------------------------

## Marks state as dirty and schedules a deferred save flush if one is not
## already pending. Called by every setter that mutates game state.
## Safe to call multiple times in the same frame — only one flush is queued.
func _mark_dirty() -> void:
	_dirty = true
	if not _save_pending:
		_save_pending = true
		call_deferred("_flush_save")

## Deferred save flush — runs at the end of the frame in which a setter fired.
## Calls SaveManager.save_game() exactly once per frame regardless of how many
## setters were called. Resets both flags after flushing.
func _flush_save() -> void:
	if not _dirty:
		_save_pending = false
		return
	SaveManager.save_game()
	_dirty = false
	_save_pending = false
