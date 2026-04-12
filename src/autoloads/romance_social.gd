extends Node

## RomanceSocial — Companion Interaction Engine (ADR-0010)
##
## Autoload #9. Manages all companion social interactions: daily token pool,
## streak multipliers, mood state machine, talk/gift/date interactions,
## combat buff generation, and dialogue delta reception.
##
## IMPORTANT: This file has NO class_name — it is an autoload singleton.
## Tests preload it with: const Script = preload("res://autoloads/romance_social.gd")
##
## All persistent state reads and writes go through GameStore typed setters.
## This autoload is the sole writer of companion relationship state.
## Dialogue deltas (from EventBus.relationship_changed) are applied flat,
## with NO streak multiplier.
##
## Boot order: Must only reference autoloads 1-8 in _ready().
## Autoload order: GameStore(1), SettingsStore(2), EventBus(3), Localization(4),
##   SaveManager(5), SceneManager(6), CompanionRegistry(7), EnemyRegistry(8).
##
## See: docs/architecture/adr-0010-romance-social.md

# ── Mood Enum ─────────────────────────────────────────────────────────────────

## The 5 companion moods. Values match mood_priority order for comparisons.
enum Mood {
	CONTENT  = 0,
	LONELY   = 1,
	ANNOYED  = 2,
	HAPPY    = 3,
	EXCITED  = 4,
}

# ── Private State ─────────────────────────────────────────────────────────────

## Loaded from romance_config.json. All tuning values live here.
var _config: Dictionary = {}

## True while a dialogue sequence is active. Pending stage signals queue here.
var _dialogue_active: bool = false

## Queued romance_stage_changed signals: Array[{id, old, new}]
var _pending_stage_signals: Array[Dictionary] = []

## Active date session state. Empty when no date is in progress.
var _date_session: Dictionary = {}

# ── Built-in Virtual Methods ──────────────────────────────────────────────────

func _ready() -> void:
	_load_config()
	_connect_eventbus()
	_evaluate_all_stages()

# ── Initialization ────────────────────────────────────────────────────────────

## Loads romance_config.json from the data directory.
## All tuning values must come from this file — no hardcoded literals.
func _load_config() -> void:
	_config = JsonLoader.load_dict("res://assets/data/romance_config.json")

## Connects EventBus signals. Only references autoloads 1-8 (boot order safe).
func _connect_eventbus() -> void:
	EventBus.relationship_changed.connect(_on_relationship_changed)
	EventBus.trust_changed.connect(_on_trust_changed)
	EventBus.combat_completed.connect(_on_combat_completed)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)

## Re-evaluates romance_stage for all known companions.
## Called on boot to correct any desync between RL and cached stage.
func _evaluate_all_stages() -> void:
	var ids: Array[String] = ["artemis", "hipolita", "atenea", "nyx"]
	for id: String in ids:
		var state: Dictionary = CompanionState.get_state(id)
		if state.is_empty():
			continue
		# get_romance_stage internally updates the monotonic max-stage cache.
		var _stage: int = CompanionState.get_romance_stage(id)

# ── Public Query Methods ──────────────────────────────────────────────────────

## Returns the number of daily interaction tokens remaining.
func get_token_count() -> int:
	return GameStore.get_daily_tokens()

## Returns the current consecutive-day interaction streak.
func get_streak() -> int:
	return GameStore.get_streak()

## Returns the streak multiplier for the current streak value.
## Tier lookup from config: index is clamped to array bounds.
func get_streak_multiplier() -> float:
	var multipliers: Array = _config.get("streak_multipliers", [1.0, 1.0, 1.1, 1.25, 1.4, 1.5])
	var streak: int = GameStore.get_streak()
	var idx: int = clampi(streak, 0, multipliers.size() - 1)
	return float(multipliers[idx])

## Returns the current mood enum value for the given companion.
## Returns Mood.CONTENT (0) if the companion is unknown.
func get_mood(companion_id: String) -> int:
	_decay_mood_if_expired(companion_id)
	return GameStore.get_mood(companion_id)

# ── Token Pool ────────────────────────────────────────────────────────────────

## Checks whether a UTC midnight crossing has occurred and resets tokens/streak.
## Should be called by a timer or from _process at appropriate intervals.
func _check_midnight_reset() -> void:
	var today: String = _get_today_utc()
	var last: String = GameStore.get_last_interaction_date()

	if last.is_empty():
		# First ever session — do not reset, just note the day.
		return

	var gap: int = _day_gap(last, today)
	if gap <= 0:
		# Same day or clock rollback — treat as 0, do nothing.
		return

	# A day has crossed — reset tokens.
	GameStore.reset_tokens()
	EventBus.tokens_reset.emit()

	# Streak update on day boundary.
	if gap == 1:
		GameStore.set_streak(GameStore.get_streak() + 1)
	elif gap >= 2:
		GameStore.set_streak(1)

## Returns the current UTC date as a YYYY-MM-DD string.
func _get_today_utc() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

## Computes the calendar-day gap between two YYYY-MM-DD strings.
## Returns 0 for same-day or negative gaps (clock rollback protection).
func _day_gap(from_date: String, to_date: String) -> int:
	if from_date.is_empty():
		return 0
	var from_unix: int = _date_to_unix(from_date)
	var to_unix: int = _date_to_unix(to_date)
	var raw: int = (to_unix - from_unix) / 86400
	return maxi(raw, 0)

## Converts a YYYY-MM-DD string to a Unix timestamp (start of day UTC).
func _date_to_unix(date_str: String) -> int:
	var parts: PackedStringArray = date_str.split("-")
	if parts.size() < 3:
		return 0
	var dt: Dictionary = {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
		"hour": 0,
		"minute": 0,
		"second": 0,
	}
	return Time.get_unix_time_from_datetime_dict(dt)

# ── Streak Update (Camp Interactions) ─────────────────────────────────────────

## Updates the streak and last_interaction_date after a successful camp interaction.
## Gap=1 → increment. Gap≥2 → reset to 1. Gap=0 (same day) → no change.
func _update_streak_on_interaction() -> void:
	var today: String = _get_today_utc()
	var last: String = GameStore.get_last_interaction_date()

	if last.is_empty():
		# First interaction ever.
		GameStore.set_streak(1)
		GameStore.set_last_interaction_date(today)
		return

	var gap: int = _day_gap(last, today)
	if gap == 0:
		# Same day — streak unchanged, just ensure date is recorded.
		return
	elif gap == 1:
		GameStore.set_streak(GameStore.get_streak() + 1)
	else:
		GameStore.set_streak(1)

	GameStore.set_last_interaction_date(today)

# ── Mood State Machine ────────────────────────────────────────────────────────

## Decays a companion's mood to Content if the expiry date has passed.
func _decay_mood_if_expired(companion_id: String) -> void:
	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty():
		return
	var expiry: String = state.get("mood_expiry_date", "")
	if expiry.is_empty():
		return
	var today: String = _get_today_utc()
	if today > expiry:
		GameStore.set_mood(companion_id, Mood.CONTENT, "")

## Sets a companion's mood with a duration from the config.
## mood_name must be a key in "mood_durations_days" config entry.
func _set_mood(companion_id: String, mood_value: int, mood_name: String) -> void:
	var durations: Dictionary = _config.get("mood_durations_days", {})
	var days: int = int(durations.get(mood_name, 2))
	var expiry: String = ""
	if days > 0:
		expiry = _date_add_days(_get_today_utc(), days)
	GameStore.set_mood(companion_id, mood_value, expiry)

## Resolves which mood wins when multiple triggers fire simultaneously.
## Returns the mood constant with the highest priority value.
func _resolve_mood_priority(moods: Array[int]) -> int:
	var winner: int = Mood.CONTENT
	for m: int in moods:
		if m > winner:
			winner = m
	return winner

## Returns a date string offset by `days` from `from_date` (YYYY-MM-DD).
func _date_add_days(from_date: String, days: int) -> String:
	var unix: int = _date_to_unix(from_date) + days * 86400
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

# ── Relationship Gain Formula ─────────────────────────────────────────────────

## Computes the final RL gain: floor(base_rl * streak_multiplier).
## Returns 0 when base_rl is 0 (base-0 stays 0, never bumped to 1).
func _compute_rl_gain(base_rl: int) -> int:
	if base_rl == 0:
		return 0
	var multiplier: float = get_streak_multiplier()
	return floori(float(base_rl) * multiplier)

## Applies a signed RL delta to a companion through CompanionState (clamped).
## This is the single write path for all RL changes via this autoload.
func _apply_rl_delta(companion_id: String, delta: int) -> void:
	var current: int = GameStore.get_relationship_level(companion_id)
	var new_rl: int = clampi(current + delta, 0, 100)
	var old_stage: int = CompanionState.get_romance_stage(companion_id)
	CompanionState.set_relationship_level(companion_id, new_rl)
	var new_stage: int = CompanionState.get_romance_stage(companion_id)
	if new_stage > old_stage:
		_queue_or_emit_stage_changed(companion_id, old_stage, new_stage)

## Queues or immediately emits romance_stage_changed depending on dialogue state.
func _queue_or_emit_stage_changed(companion_id: String, old_stage: int, new_stage: int) -> void:
	if _dialogue_active:
		_pending_stage_signals.append({
			"id": companion_id,
			"old": old_stage,
			"new": new_stage,
		})
	else:
		EventBus.romance_stage_changed.emit(companion_id, old_stage, new_stage)

# ── Talk Interaction ──────────────────────────────────────────────────────────

## Performs a Talk interaction with the given companion.
## Validates: tokens > 0 and companion is met.
## Returns a result dict: {success, rl_gained, mood_change, error}.
func do_talk(companion_id: String) -> Dictionary:
	# Validate token availability.
	if GameStore.get_daily_tokens() <= 0:
		return {"success": false, "rl_gained": 0, "mood_change": 0, "error": "no_tokens"}

	# Validate companion is met.
	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty() or not state.get("met", false):
		return {"success": false, "rl_gained": 0, "mood_change": 0, "error": "companion_not_met"}

	# Determine base RL from mood.
	var current_mood: int = get_mood(companion_id)
	var mood_name: String = _mood_int_to_name(current_mood)
	var talk_base_rl: Dictionary = _config.get("talk_base_rl", {})
	var base_rl: int = int(talk_base_rl.get(mood_name, 3))

	# Compute final gain and apply.
	var rl_gained: int = _compute_rl_gain(base_rl)
	_apply_rl_delta(companion_id, rl_gained)

	# Spend token.
	GameStore.spend_token()

	# Update streak.
	_update_streak_on_interaction()

	# Update mood → Happy after a successful talk (from Content/Lonely/Annoyed).
	var new_mood: int = current_mood
	if current_mood in [Mood.CONTENT, Mood.LONELY, Mood.ANNOYED]:
		new_mood = Mood.HAPPY
		_set_mood(companion_id, Mood.HAPPY, "Happy")
	# Happy stays Happy; Excited stays Excited.

	return {
		"success": true,
		"rl_gained": rl_gained,
		"mood_change": new_mood,
		"error": "",
	}

# ── Gift Interaction ──────────────────────────────────────────────────────────

## Performs a Gift interaction with the given companion and item.
## Gift preference (liked/neutral/disliked) is matched against companion
## known_likes and known_dislikes arrays.
## Returns a result dict: {success, rl_gained, preference, error}.
func do_gift(companion_id: String, item_id: String) -> Dictionary:
	# Validate token availability.
	if GameStore.get_daily_tokens() <= 0:
		return {"success": false, "rl_gained": 0, "preference": "neutral", "error": "no_tokens"}

	# Validate companion is met.
	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty() or not state.get("met", false):
		return {"success": false, "rl_gained": 0, "preference": "neutral", "error": "companion_not_met"}

	# Determine preference.
	var known_likes: Array = state.get("known_likes", [])
	var known_dislikes: Array = state.get("known_dislikes", [])
	var preference: String = "neutral"
	if known_likes.has(item_id):
		preference = "liked"
	elif known_dislikes.has(item_id):
		preference = "disliked"

	# Compute gain (no streak multiplier for gift RL lookup — it IS applied via _compute_rl_gain).
	var gift_base_rl: Dictionary = _config.get("gift_base_rl", {})
	var base_rl: int = int(gift_base_rl.get(preference, 1))
	var rl_gained: int = _compute_rl_gain(base_rl)
	_apply_rl_delta(companion_id, rl_gained)

	# Spend token.
	GameStore.spend_token()

	# Update streak.
	_update_streak_on_interaction()

	# Generate combat buff after successful gift.
	_generate_and_store_combat_buff(companion_id)

	return {
		"success": true,
		"rl_gained": rl_gained,
		"preference": preference,
		"error": "",
	}

# ── Date Sub-System ───────────────────────────────────────────────────────────

## Starts a date session with the given companion.
## Consumes one token, snapshots romance_stage for the duration.
## Returns true on success, false if tokens = 0 or companion is not met.
func start_date(companion_id: String) -> bool:
	if GameStore.get_daily_tokens() <= 0:
		return false
	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty() or not state.get("met", false):
		return false

	# Snapshot stage at date start — live changes are ignored during the date.
	var snapshotted_stage: int = CompanionState.get_romance_stage(companion_id)

	GameStore.spend_token()
	_update_streak_on_interaction()

	_date_session = {
		"companion_id": companion_id,
		"snapshotted_stage": snapshotted_stage,
		"current_round": 0,
		"total_rl_gained": 0,
		"completed": false,
	}
	return true

## Presents 3 activity options for the current date round.
## Activities are drawn from the 6 categories with replacement (random selection).
## Returns a dict with {round, options: Array[String]} or {} if no active date.
func get_date_round_options() -> Dictionary:
	if _date_session.is_empty() or _date_session.get("completed", true):
		return {}
	var categories: Array = _config.get("date_activity_categories",
		["romantic", "active", "intellectual", "domestic", "adventure", "artistic"])
	var options: Array[String] = []
	for _i: int in range(3):
		var idx: int = randi() % categories.size()
		options.append(str(categories[idx]))
	return {
		"round": _date_session.get("current_round", 0) + 1,
		"options": options,
	}

## Selects an activity for the current date round and scores it.
## companion preference weights are stored in known_likes/known_dislikes.
## Returns a round result dict: {round, rl_gained, total_rl, date_complete}.
func select_date_activity(activity_id: String) -> Dictionary:
	if _date_session.is_empty() or _date_session.get("completed", true):
		return {"error": "no_active_date"}

	var companion_id: String = _date_session.get("companion_id", "")
	var state: Dictionary = GameStore.get_companion_state(companion_id)

	# Determine if activity matches companion preference.
	var known_likes: Array = state.get("known_likes", [])
	var known_dislikes: Array = state.get("known_dislikes", [])
	var preference: String = "neutral"
	if known_likes.has(activity_id):
		preference = "liked"
	elif known_dislikes.has(activity_id):
		preference = "disliked"

	var round_rl_table: Dictionary = _config.get("date_round_rl", {})
	var rl_gained: int = int(round_rl_table.get(preference, 5))

	_date_session["current_round"] += 1
	_date_session["total_rl_gained"] = _date_session.get("total_rl_gained", 0) + rl_gained

	var rounds: int = int(_config.get("date_rounds", 4))
	var date_complete: bool = _date_session["current_round"] >= rounds

	if date_complete:
		# Apply all accumulated RL in one write using snapshotted stage context.
		var total: int = _date_session.get("total_rl_gained", 0)
		_apply_rl_delta(companion_id, total)
		_date_session["completed"] = true
		# Reveal a preference category (dates unlock gift preferences).
		_discover_preference_from_date(companion_id, activity_id, preference)
		# Generate combat buff.
		_generate_and_store_combat_buff(companion_id)

	return {
		"round": _date_session.get("current_round", 0),
		"rl_gained": rl_gained,
		"total_rl": _date_session.get("total_rl_gained", 0),
		"date_complete": date_complete,
	}

## Discovers and stores a preference category revealed through a date activity.
func _discover_preference_from_date(companion_id: String, activity_id: String, preference: String) -> void:
	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty():
		return
	if preference == "liked":
		var likes: Array = state.get("known_likes", [])
		if not likes.has(activity_id):
			likes.append(activity_id)
			# Write back through GameStore companion state update.
			# We use the internal companion state dict update path.
			GameStore._companion_states[companion_id]["known_likes"] = likes
			GameStore._mark_dirty()
	elif preference == "disliked":
		var dislikes: Array = state.get("known_dislikes", [])
		if not dislikes.has(activity_id):
			dislikes.append(activity_id)
			GameStore._companion_states[companion_id]["known_dislikes"] = dislikes
			GameStore._mark_dirty()

# ── Combat Buff Generation ────────────────────────────────────────────────────

## Generates a combat buff dict based on the companion's current romance stage.
## Replacement rule: new buff replaces old only if (new.chips + new.mult) > (old.chips + old.mult).
func generate_combat_buff(companion_id: String) -> Dictionary:
	var stage: int = CompanionState.get_romance_stage(companion_id)
	var buff_config: Dictionary = _config.get("combat_buff", {})
	var by_stage: Array = buff_config.get("by_stage", [])
	if by_stage.is_empty() or stage >= by_stage.size():
		return {}
	var row: Dictionary = by_stage[stage] as Dictionary
	return {
		"chips": int(row.get("chips", 0)),
		"mult": float(row.get("mult", 0.0)),
		"combats_remaining": int(row.get("combats", 0)),
	}

## Generates buff and applies replacement rule against the existing active buff.
func _generate_and_store_combat_buff(companion_id: String) -> void:
	var new_buff: Dictionary = generate_combat_buff(companion_id)
	if new_buff.is_empty():
		return
	var old_buff: Dictionary = GameStore.get_combat_buff()
	var new_sum: float = float(new_buff.get("chips", 0)) + float(new_buff.get("mult", 0.0))
	var old_sum: float = 0.0
	if not old_buff.is_empty():
		old_sum = float(old_buff.get("chips", 0)) + float(old_buff.get("mult", 0.0))
	if new_sum > old_sum:
		GameStore.set_combat_buff(new_buff)

# ── EventBus Signal Handlers ──────────────────────────────────────────────────

## Handles relationship_changed from DialogueRunner.
## Applies flat delta — NO streak multiplier (ADR-0010, TR-romance-social-010).
func _on_relationship_changed(companion_id: String, delta: int) -> void:
	if GameStore.get_companion_state(companion_id).is_empty():
		return
	var current: int = GameStore.get_relationship_level(companion_id)
	var old_stage: int = CompanionState.get_romance_stage(companion_id)
	var new_rl: int = clampi(current + delta, 0, 100)
	CompanionState.set_relationship_level(companion_id, new_rl)
	var new_stage: int = CompanionState.get_romance_stage(companion_id)
	if new_stage > old_stage:
		_queue_or_emit_stage_changed(companion_id, old_stage, new_stage)

## Handles trust_changed from DialogueRunner.
## Applies flat delta to companion trust — no multiplier.
func _on_trust_changed(companion_id: String, delta: int) -> void:
	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty():
		return
	var current: int = state.get("trust", 0)
	GameStore.set_trust(companion_id, clampi(current + delta, 0, 100))

## Handles combat_completed from CombatSystem.
## Decrements buff combats_remaining. Captain companion gains +1 RL (flat, no multiplier).
func _on_combat_completed(result: Dictionary) -> void:
	# Decrement active buff.
	var buff: Dictionary = GameStore.get_combat_buff()
	if not buff.is_empty():
		var remaining: int = int(buff.get("combats_remaining", 0)) - 1
		if remaining <= 0:
			GameStore.clear_combat_buff()
		else:
			buff["combats_remaining"] = remaining
			GameStore.set_combat_buff(buff)

	# Captain +1 RL on victory (flat, no streak multiplier — ADR-0010 Rule 8).
	var victory: bool = result.get("victory", false)
	if not victory:
		return
	var captain_id: String = result.get("captain_id", "")
	if captain_id.is_empty():
		return
	var state: Dictionary = GameStore.get_companion_state(captain_id)
	if state.is_empty():
		return
	var current: int = GameStore.get_relationship_level(captain_id)
	var old_stage: int = CompanionState.get_romance_stage(captain_id)
	CompanionState.set_relationship_level(captain_id, clampi(current + 1, 0, 100))
	var new_stage: int = CompanionState.get_romance_stage(captain_id)
	if new_stage > old_stage:
		_queue_or_emit_stage_changed(captain_id, old_stage, new_stage)

## Handles dialogue_ended — flushes any queued stage-changed signals.
func _on_dialogue_ended(_sequence_id: String) -> void:
	_dialogue_active = false
	for entry: Dictionary in _pending_stage_signals:
		EventBus.romance_stage_changed.emit(
			entry.get("id", ""),
			entry.get("old", 0),
			entry.get("new", 0),
		)
	_pending_stage_signals.clear()

# ── Helpers ───────────────────────────────────────────────────────────────────

## Converts a Mood enum int to its string key used in config lookups.
func _mood_int_to_name(mood_value: int) -> String:
	match mood_value:
		Mood.CONTENT:  return "Content"
		Mood.HAPPY:    return "Happy"
		Mood.EXCITED:  return "Excited"
		Mood.LONELY:   return "Lonely"
		Mood.ANNOYED:  return "Annoyed"
		_:             return "Content"
