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

## Companions currently assigned to the combat deck, keyed by companion id.
## Value is the card_value (2–14) the player chose for that companion's
## signature slot. The (element, card_value) combination must be unique —
## adding a companion into an occupied slot requires replacement.
## Separate from the captain slot.
var _deck_companions: Dictionary = {}

# ---------------------------------------------------------------------------
# Private State — Equipment (STORY-EQUIP-002, STORY-EQUIP-003)
# ---------------------------------------------------------------------------

## Item ID of the currently equipped weapon. Empty string = slot empty.
var _equipped_weapon: String = ""

## Item ID of the currently equipped amulet. Empty string = slot empty.
var _equipped_amulet: String = ""

## Ordered list of item IDs awaiting player review. Max 5 items (cap enforced
## by EquipmentSystem). Using Array (not typed Array[String]) for JSON
## round-trip compatibility — values are always Strings at runtime.
var _pending_equipment: Array[String] = []

# ---------------------------------------------------------------------------
# Private State — Counters (Achievements, Stats tracking)
# ---------------------------------------------------------------------------

## Generic integer counters for achievement tracking and lifetime stats.
## Keys are String counter names (e.g. "combat_wins"). Values are int.
var _counters: Dictionary = {}

## Per-tavern last-played date tracking {tavern_id: "YYYY-MM-DD"} for the
## once-per-day tournament reward. Reset implicit via date comparison.
var _tavern_last_played: Dictionary = {}

# ---------------------------------------------------------------------------
# Private State — Exploration (STORY-EXPLORE-001..005)
# ---------------------------------------------------------------------------

## Active exploration mission state. Empty dict = no mission in progress.
## Expected keys: companion_id (String), mission_id (String),
##   start_utc (int), duration_seconds (float).
var _exploration_state: Dictionary = {}

## Per-companion XP pool keyed by companion ID. Decreases on level-up (XP
## is spent as a resource, not just a cumulative counter).
## Accumulated via exploration dispatch and combat victories.
var _companion_xp: Dictionary = {}

## Per-companion combat level keyed by companion ID. Stored explicitly
## (not derived) because level-ups are a player action — paying gold +
## spending banked XP — not an automatic threshold. Unset entries default
## to 1. See design/quick-specs/companion-leveling.md.
var _companion_levels: Dictionary = {}

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
	for id: String in ["artemis", "hipolita", "atenea", "nyx"]:
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
	_deck_companions = {}
	_equipped_weapon = ""
	_equipped_amulet = ""
	_pending_equipment = []
	_exploration_state = {}
	_companion_xp = {}
	_companion_levels = {}
	_counters = {}
	_tavern_last_played = {}

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


## Seeds the known_likes / known_dislikes arrays for a companion.
## Called by higher layers (e.g. StoryFlow after set_met) so GameStore
## stays free of cross-layer dependencies (ADR-0006).
func seed_companion_preferences(id: String, likes: Array, dislikes: Array) -> void:
	if not _companion_states.has(id):
		return
	_companion_states[id]["known_likes"] = likes.duplicate()
	_companion_states[id]["known_dislikes"] = dislikes.duplicate()
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

## Returns the last interaction date as a UTC date string (YYYY-MM-DD).
## Returns an empty String if no interaction has occurred yet.
func get_last_interaction_date() -> String:
	return _last_interaction_date

## Sets the last interaction date from a UTC date string (YYYY-MM-DD).
func set_last_interaction_date(date: String) -> void:
	_last_interaction_date = date
	_mark_dirty()
	state_changed.emit("romance")

## Returns the companion ID of the last-selected captain. Empty if none.
func get_last_captain_id() -> String:
	return _last_captain_id

## Sets the last-selected captain by companion ID and marks state dirty.
func set_last_captain_id(id: String) -> void:
	_last_captain_id = id
	_mark_dirty()
	state_changed.emit("captain")


## Returns a list of companion ids currently assigned to the deck.
func get_deck_companions() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in _deck_companions.keys():
		ids.append(str(key))
	return ids


## Returns true if [param id] is currently assigned to the deck.
func has_deck_companion(id: String) -> bool:
	return _deck_companions.has(id)


## Returns the chosen card value (2–14) for [param id], or 0 if not assigned.
func get_deck_companion_value(id: String) -> int:
	return int(_deck_companions.get(id, 0))


## Assigns [param id] to the deck at the given [param card_value] slot.
## Overwrites any prior assignment for this companion.
func add_deck_companion(id: String, card_value: int) -> void:
	_deck_companions[id] = card_value
	_mark_dirty()
	state_changed.emit("deck")


## Removes [param id] from the deck companion list (no-op if absent).
func remove_deck_companion(id: String) -> void:
	if not _deck_companions.has(id):
		return
	_deck_companions.erase(id)
	_mark_dirty()
	state_changed.emit("deck")


## Returns true if the player can play the given tavern's daily tournament
## today. A tavern can be played once per local calendar day.
func can_play_tavern_today(tavern_id: String) -> bool:
	var last: String = str(_tavern_last_played.get(tavern_id, ""))
	return last != _today_date_string()


## Records that the given tavern was played today and marks state dirty.
func mark_tavern_played(tavern_id: String) -> void:
	_tavern_last_played[tavern_id] = _today_date_string()
	_mark_dirty()
	state_changed.emit("tavern")


## Returns "YYYY-MM-DD" for today's local calendar date.
func _today_date_string() -> String:
	var dt: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt.get("year", 0), dt.get("month", 0), dt.get("day", 0)]

# ---------------------------------------------------------------------------
# Public Getters — Equipment (STORY-EQUIP-002, STORY-EQUIP-003)
# ---------------------------------------------------------------------------

## Returns the item ID of the currently equipped weapon. Empty string if none.
func get_equipped_weapon() -> String:
	return _equipped_weapon

## Sets the equipped weapon by item ID. Pass "" to clear the slot.
func set_equipped_weapon(item_id: String) -> void:
	_equipped_weapon = item_id
	_mark_dirty()
	state_changed.emit("equipment")

## Returns the item ID of the currently equipped amulet. Empty string if none.
func get_equipped_amulet() -> String:
	return _equipped_amulet

## Sets the equipped amulet by item ID. Pass "" to clear the slot.
func set_equipped_amulet(item_id: String) -> void:
	_equipped_amulet = item_id
	_mark_dirty()
	state_changed.emit("equipment")

## Returns a copy of the pending equipment item ID list.
## Values are always Strings. Maximum 5 items (cap enforced by EquipmentSystem).
func get_pending_equipment() -> Array[String]:
	var result: Array[String] = []
	for entry: Variant in _pending_equipment:
		result.append(str(entry))
	return result

## Appends [param item_id] to the pending_equipment list.
## The caller (EquipmentSystem) is responsible for enforcing the cap.
func add_pending_equipment(item_id: String) -> void:
	_pending_equipment.append(item_id)
	_mark_dirty()
	state_changed.emit("equipment")

## Removes the entry at [param index] from pending_equipment.
## No-op if index is out of range.
func remove_pending_equipment(index: int) -> void:
	if index < 0 or index >= _pending_equipment.size():
		return
	_pending_equipment.remove_at(index)
	_mark_dirty()
	state_changed.emit("equipment")

# ---------------------------------------------------------------------------
# Public Getters — Exploration State (STORY-EXPLORE-001..005)
# ---------------------------------------------------------------------------

## Returns a shallow copy of the active exploration mission state.
## Returns an empty Dictionary when no mission is in progress.
## Keys: companion_id (String), mission_id (String),
##   start_utc (int), duration_seconds (float).
func get_exploration_state() -> Dictionary:
	return _exploration_state.duplicate()

## Writes the active exploration mission state and marks state dirty.
## Pass a dict with keys: companion_id, mission_id, start_utc, duration_seconds.
func set_exploration_state(state: Dictionary) -> void:
	_exploration_state = state.duplicate()
	_mark_dirty()
	state_changed.emit("exploration")

## Clears the active exploration mission state and marks state dirty.
## Called on collect() or cancel().
func clear_exploration_state() -> void:
	_exploration_state = {}
	_mark_dirty()
	state_changed.emit("exploration")

# ---------------------------------------------------------------------------
# Public Getters — Companion XP (STORY-EXPLORE-005)
# ---------------------------------------------------------------------------

## Returns the accumulated XP for [param companion_id]. Returns 0 if unknown.
func get_companion_xp(companion_id: String) -> int:
	return int(_companion_xp.get(companion_id, 0))

## Adds [param amount] XP to [param companion_id]'s pool and marks state dirty.
## No-op for unknown companion IDs (pool is created lazily). Negative values
## are clamped to 0 so XP is monotonic.
func add_companion_xp(companion_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var current: int = int(_companion_xp.get(companion_id, 0))
	_companion_xp[companion_id] = current + amount
	_mark_dirty()
	state_changed.emit("companion_xp")

## Returns the stored combat level for [param companion_id]. Unset entries
## default to 1. Level is NOT derived from XP — the player manually spends
## XP + gold to level up via `level_up_companion`.
func get_companion_level(companion_id: String) -> int:
	return int(_companion_levels.get(companion_id, 1))

## Returns the XP cost to buy the next level for [param companion_id], or 0
## if already at the cap. Matches CompanionLevel.xp_needed_for_next so the
## curve stays authoritative in one place.
func get_level_up_xp_cost(companion_id: String) -> int:
	var level: int = get_companion_level(companion_id)
	return CompanionLevel.xp_needed_for_next(level)

## Returns the gold cost to buy the next level. Linear: 25 × current_level.
## Total across levels 1→20 is ~5000 gold per companion.
func get_level_up_gold_cost(companion_id: String) -> int:
	var level: int = get_companion_level(companion_id)
	if level >= CompanionLevel.LEVEL_CAP:
		return 0
	return 25 * level

## True if the player can afford the next level-up right now — enough XP
## banked, enough gold on hand, and not yet at the level cap.
func can_level_up(companion_id: String) -> bool:
	var level: int = get_companion_level(companion_id)
	if level >= CompanionLevel.LEVEL_CAP:
		return false
	var xp: int = get_companion_xp(companion_id)
	if xp < get_level_up_xp_cost(companion_id):
		return false
	if _player_gold < get_level_up_gold_cost(companion_id):
		return false
	return true

## Executes the level-up: spends XP + gold, increments the stored level,
## marks state dirty. Returns true on success. Returns false (with no
## state change) if preconditions aren't met.
func level_up_companion(companion_id: String) -> bool:
	if not can_level_up(companion_id):
		return false
	var xp_cost: int = get_level_up_xp_cost(companion_id)
	var gold_cost: int = get_level_up_gold_cost(companion_id)
	var current_xp: int = int(_companion_xp.get(companion_id, 0))
	_companion_xp[companion_id] = current_xp - xp_cost
	_player_gold -= gold_cost
	var current_level: int = int(_companion_levels.get(companion_id, 1))
	_companion_levels[companion_id] = current_level + 1
	_mark_dirty()
	state_changed.emit("gold")
	state_changed.emit("companion_xp")
	state_changed.emit("companion_level")
	return true

# ---------------------------------------------------------------------------
# Public Getters — Counters (Achievements / Lifetime Stats)
# ---------------------------------------------------------------------------

## Returns the current value of the named counter.
## Returns 0 if the counter has never been set or incremented.
func get_counter(counter_name: String) -> int:
	return int(_counters.get(counter_name, 0))

## Increments the named counter by [param amount] (default 1) and marks dirty.
## Creates the counter at 0 before incrementing if it does not yet exist.
func increment_counter(counter_name: String, amount: int = 1) -> void:
	var current: int = int(_counters.get(counter_name, 0))
	_counters[counter_name] = current + amount
	_mark_dirty()
	state_changed.emit("counter")

## Sets the named counter to an exact value and marks dirty.
## Useful for restoring counter state from a save file.
func set_counter(counter_name: String, value: int) -> void:
	_counters[counter_name] = value
	_mark_dirty()
	state_changed.emit("counter")

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
		"deck_companions": _deck_companions.duplicate(),
		"tavern_last_played": _tavern_last_played.duplicate(),
		"equipped_weapon": _equipped_weapon,
		"equipped_amulet": _equipped_amulet,
		"pending_equipment": _pending_equipment.duplicate(),
		"exploration_state": _exploration_state.duplicate(),
		"companion_xp": _companion_xp.duplicate(),
		"companion_levels": _companion_levels.duplicate(),
		"counters": _counters.duplicate(),
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
	_tavern_last_played = {}
	var saved_tavern: Dictionary = data.get("tavern_last_played", {})
	for key: Variant in saved_tavern.keys():
		_tavern_last_played[str(key)] = str(saved_tavern[key])
	_deck_companions = {}
	var saved_deck: Variant = data.get("deck_companions", {})
	if saved_deck is Dictionary:
		for key: Variant in (saved_deck as Dictionary).keys():
			_deck_companions[str(key)] = int((saved_deck as Dictionary)[key])
	elif saved_deck is Array:
		# Legacy saves stored an Array[String] with no card_value;
		# fall back to each companion's default card_value from CompanionRegistry.
		for entry: Variant in saved_deck as Array:
			var cid: String = str(entry)
			var profile: Dictionary = CompanionRegistry.get_profile(cid)
			_deck_companions[cid] = int(profile.get("card_value", 0))
	_equipped_weapon = data.get("equipped_weapon", "")
	_equipped_amulet = data.get("equipped_amulet", "")
	var raw_pending: Array = data.get("pending_equipment", []) as Array
	_pending_equipment.clear()
	for entry: Variant in raw_pending:
		_pending_equipment.append(str(entry))
	_counters = {}
	var raw_counters: Dictionary = data.get("counters", {})
	for key: Variant in raw_counters:
		_counters[str(key)] = int(raw_counters[key])

	# Companion XP + levels. Both default to empty dicts — any missing entry
	# falls through to XP 0 / level 1 via the getters. Pre-Phase H saves
	# had no companion_levels key at all; that's fine.
	_companion_xp = {}
	var raw_xp: Dictionary = data.get("companion_xp", {})
	for key: Variant in raw_xp:
		_companion_xp[str(key)] = int(raw_xp[key])
	_companion_levels = {}
	var raw_levels: Dictionary = data.get("companion_levels", {})
	for key: Variant in raw_levels:
		_companion_levels[str(key)] = int(raw_levels[key])

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
