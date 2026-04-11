class_name ExplorationSystem
extends RefCounted

## ExplorationSystem — Real-Time Mission Dispatch (STORY-EXPLORE-001..005)
##
## Stateless utility class. All mutable state lives in GameStore._exploration_state.
## Companions are dispatched on timed real-world missions. Only one mission runs
## at a time. Duration is based on UTC wall-clock time so missions persist across
## app close/open.
##
## AGI reduces effective mission duration:
##   actual_seconds = base_hours * 3600 * (1.0 - AGI * agi_speed_factor)
##   clamped to minimum of 60 seconds.
##
## Item chance: base item_chance + INT * int_rarity_factor, capped at 0.95.
##
## Public API:
##   dispatch(companion_id, mission_id)       → Dictionary {ok, error}
##   is_dispatched()                          → bool
##   get_active_mission()                     → Dictionary or {}
##   get_time_remaining()                     → float seconds (0.0 when done)
##   is_complete()                            → bool
##   collect()                                → Dictionary {gold, xp, item_id} or {error}
##   cancel()                                 → void
##
## See: design/gdd/exploration.md
## Stories: STORY-EXPLORE-001, STORY-EXPLORE-002, STORY-EXPLORE-003,
##          STORY-EXPLORE-004, STORY-EXPLORE-005

# ── Constants ─────────────────────────────────────────────────────────────────

const DATA_PATH: String = "res://assets/data/exploration_missions.json"
const COMPANIONS_PATH: String = "res://assets/data/companions.json"
const MIN_DURATION_SECONDS: float = 60.0
const MAX_ITEM_CHANCE: float = 0.95

# ── Static data cache ─────────────────────────────────────────────────────────

## Mission definitions keyed by mission_id. Loaded once.
static var _missions: Dictionary = {}

## Global tuning knobs loaded from JSON.
static var _agi_speed_factor: float = 0.05
static var _int_rarity_factor: float = 0.03

static var _data_loaded: bool = false

## Companion stat data keyed by companion_id. Loaded once.
static var _companion_data: Dictionary = {}
static var _companions_loaded: bool = false

# ── Public API ────────────────────────────────────────────────────────────────

## Attempts to dispatch [param companion_id] on [param mission_id].
## Returns {ok: true} on success, or {ok: false, error: String} on failure.
## Fails if: another mission is active, companion not met, mission_id unknown,
## or data failed to load.
static func dispatch(companion_id: String, mission_id: String) -> Dictionary:
	_ensure_mission_data()
	_ensure_companion_data()

	# Guard — only one active mission allowed
	if is_dispatched():
		return {
			"ok": false,
			"error": "A companion is already on a mission"
		}

	# Guard — companion must be met
	var companion_state: Dictionary = GameStore.get_companion_state(companion_id)
	if companion_state.is_empty() or not companion_state.get("met", false):
		return {
			"ok": false,
			"error": "Companion not available for dispatch"
		}

	# Guard — mission must exist
	if not _missions.has(mission_id):
		return {
			"ok": false,
			"error": "Unknown mission id: %s" % mission_id
		}

	var mission: Dictionary = _missions[mission_id] as Dictionary
	var base_hours: float = float(mission.get("duration_hours", 1))
	var agi: int = _get_companion_stat(companion_id, "AGI")
	var duration_seconds: float = _compute_duration(base_hours, agi)

	var start_utc: int = int(Time.get_unix_time_from_system())

	GameStore.set_exploration_state({
		"companion_id": companion_id,
		"mission_id": mission_id,
		"start_utc": start_utc,
		"duration_seconds": duration_seconds,
	})

	return {"ok": true}


## Returns true if a mission is currently active.
static func is_dispatched() -> bool:
	var state: Dictionary = GameStore.get_exploration_state()
	return not state.is_empty() and state.get("companion_id", "") != ""


## Returns the active mission state dict, or an empty dict if none is active.
## Keys: companion_id (String), mission_id (String), start_utc (int),
##       duration_seconds (float).
static func get_active_mission() -> Dictionary:
	if not is_dispatched():
		return {}
	return GameStore.get_exploration_state().duplicate()


## Returns seconds remaining in the active mission. Returns 0.0 if none active
## or mission already complete. Clamped to minimum 0.0 (clock-rollback safe).
static func get_time_remaining() -> float:
	var state: Dictionary = GameStore.get_exploration_state()
	if state.is_empty():
		return 0.0

	var start_utc: int = int(state.get("start_utc", 0))
	var duration_seconds: float = float(state.get("duration_seconds", 0.0))
	var now_utc: int = int(Time.get_unix_time_from_system())

	# Clock-rollback guard: elapsed is never negative (EC-2)
	var elapsed: float = maxf(0.0, float(now_utc - start_utc))
	return maxf(0.0, duration_seconds - elapsed)


## Returns true when the active mission has completed (time remaining == 0).
## Returns false if no mission is active.
static func is_complete() -> bool:
	if not is_dispatched():
		return false
	return get_time_remaining() <= 0.0


## Collects rewards from a completed mission. Returns a reward dict:
##   {gold: int, xp: int, item_id: String or null}
## Returns {error: String} if mission is not yet complete or no mission is active.
## Clears mission state and dispatched flag on success.
static func collect() -> Dictionary:
	if not is_dispatched():
		return {"error": "No active mission"}

	if not is_complete():
		return {"error": "Mission not yet complete"}

	_ensure_mission_data()
	_ensure_companion_data()

	var state: Dictionary = GameStore.get_exploration_state()
	var companion_id: String = str(state.get("companion_id", ""))
	var mission_id: String = str(state.get("mission_id", ""))

	var mission: Dictionary = _missions.get(mission_id, {}) as Dictionary
	if mission.is_empty():
		push_error("ExplorationSystem.collect: unknown mission_id '%s' in save state." % mission_id)
		GameStore.clear_exploration_state()
		return {"gold": 0, "xp": 0, "item_id": null}

	var base_gold: int = int(mission.get("base_gold", 0))
	var base_xp: int = int(mission.get("base_xp", 0))
	var base_item_chance: float = float(mission.get("item_chance", 0.0))

	var agi: int = _get_companion_stat(companion_id, "AGI")
	var int_stat: int = _get_companion_stat(companion_id, "INT")

	# Gold and XP are awarded at base amounts (no random variance in this schema)
	var gold: int = base_gold
	var xp: int = base_xp

	# Item chance with INT bonus
	var item_chance: float = minf(base_item_chance + float(int_stat) * _int_rarity_factor, MAX_ITEM_CHANCE)
	var item_id: Variant = null

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() < item_chance:
		item_id = mission_id + "_item"

	GameStore.add_gold(gold)
	GameStore.add_companion_xp(companion_id, xp)
	GameStore.clear_exploration_state()

	return {
		"gold": gold,
		"xp": xp,
		"item_id": item_id,
	}


## Returns all mission definitions as an Array[Dictionary].
static func get_all_missions() -> Array[Dictionary]:
	_ensure_mission_data()
	var result: Array[Dictionary] = []
	for m: Variant in _missions.values():
		result.append(m as Dictionary)
	return result


## Cancels the active mission immediately. Companion returns with no rewards.
## No-op if no mission is active.
static func cancel() -> void:
	if not is_dispatched():
		return
	GameStore.clear_exploration_state()


# ── Private helpers ───────────────────────────────────────────────────────────

## Returns the effective mission duration in seconds, reduced by companion AGI.
## actual_seconds = base_hours * 3600 * (1.0 - AGI * agi_speed_factor)
## Clamped to MIN_DURATION_SECONDS.
static func _compute_duration(base_hours: float, agi: int) -> float:
	var reduction: float = float(agi) * _agi_speed_factor
	var factor: float = maxf(0.0, 1.0 - reduction)
	var seconds: float = base_hours * 3600.0 * factor
	return maxf(MIN_DURATION_SECONDS, seconds)


## Returns the integer stat value for [param stat_key] (e.g. "AGI", "INT")
## from the static companion data cache. Returns 0 if companion or stat not found.
static func _get_companion_stat(companion_id: String, stat_key: String) -> int:
	var profile: Dictionary = _companion_data.get(companion_id, {}) as Dictionary
	return int(profile.get(stat_key, 0))


## Loads exploration_missions.json on first call. Subsequent calls are no-ops.
static func _ensure_mission_data() -> void:
	if _data_loaded:
		return

	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("ExplorationSystem: cannot open %s — mission data unavailable." % DATA_PATH)
		_data_loaded = true
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("ExplorationSystem: failed to parse %s as JSON." % DATA_PATH)
		_data_loaded = true
		return

	var root: Dictionary = parsed as Dictionary

	var missions_array: Array = root.get("missions", []) as Array
	for entry: Variant in missions_array:
		var m: Dictionary = entry as Dictionary
		var mid: String = str(m.get("id", ""))
		if mid != "":
			_missions[mid] = m

	_agi_speed_factor = float(root.get("agi_speed_factor", 0.05))
	_int_rarity_factor = float(root.get("int_rarity_factor", 0.03))
	_data_loaded = true


## Loads companions.json on first call. Subsequent calls are no-ops.
static func _ensure_companion_data() -> void:
	if _companions_loaded:
		return

	var file: FileAccess = FileAccess.open(COMPANIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("ExplorationSystem: cannot open %s — companion stats unavailable." % COMPANIONS_PATH)
		_companions_loaded = true
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("ExplorationSystem: failed to parse %s as JSON." % COMPANIONS_PATH)
		_companions_loaded = true
		return

	_companion_data = parsed as Dictionary
	_companions_loaded = true


## Resets the static data cache. Called by tests to allow re-injection.
static func _reset_cache_for_tests() -> void:
	_missions.clear()
	_companion_data.clear()
	_agi_speed_factor = 0.05
	_int_rarity_factor = 0.03
	_data_loaded = false
	_companions_loaded = false
