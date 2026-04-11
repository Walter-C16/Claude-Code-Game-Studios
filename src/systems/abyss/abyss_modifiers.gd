class_name AbyssModifiers
extends RefCounted

## AbyssModifiers — Weekly rotating modifier system for Abyss Mode.
##
## 10 modifiers are defined in abyss_config.json. The active modifier is
## determined by ISO week number modulo 10. Rotation fires at Monday 00:00 UTC.
##
## Design contract:
##   - get_weekly_modifier() → returns the modifier dict for the current week
##   - get_modifier_by_id() → returns a modifier dict by id
##   - apply_modifier(run, id) → mutates run parameters for modifier effects
##   - The modifier active at run start is stored in run.modifier_id;
##     rotation mid-run does NOT change it (GDD EC-5, Rule 8)
##
## See: design/gdd/abyss-mode.md (Rule 8)
## Stories: STORY-ABYSS-001

# ── Private State ─────────────────────────────────────────────────────────────

## Injected config.
var _config: AbyssConfig = null

# ── Construction ──────────────────────────────────────────────────────────────

## [param config] — AbyssConfig instance. Must not be null.
func _init(config: AbyssConfig) -> void:
	_config = config

# ── Public API ────────────────────────────────────────────────────────────────

## Returns the modifier dict active for the current ISO week.
## Uses Time.get_datetime_dict_from_system() to get the current UTC time.
## Falls back to modifier index 0 if modifiers list is empty.
##
## Keys in returned dict: id, nameKey, descKey, effect, value (and optional overrides).
func get_weekly_modifier() -> Dictionary:
	var week_number: int = _get_iso_week_number()
	return get_modifier_by_index(week_number)

## Returns the modifier at [param index] modulo the total modifier count.
## Safe for any integer index value.
func get_modifier_by_index(index: int) -> Dictionary:
	var modifiers: Array = _config.get_modifiers_config()
	if modifiers.is_empty():
		push_warning("AbyssModifiers: no modifiers defined in config")
		return {}
	var safe_index: int = index % modifiers.size()
	return modifiers[safe_index].duplicate() as Dictionary

## Returns the modifier dict for [param modifier_id].
## Returns empty dict and logs a warning if id is not found.
func get_modifier_by_id(modifier_id: String) -> Dictionary:
	var modifiers: Array = _config.get_modifiers_config()
	for entry: Variant in modifiers:
		var mod: Dictionary = entry as Dictionary
		if mod.get("id", "") == modifier_id:
			return mod.duplicate() as Dictionary
	push_warning("AbyssModifiers: modifier_id '%s' not found" % modifier_id)
	return {}

## Returns the modifier id active for the current week.
## Convenience wrapper used by AbyssRunner at run start.
func get_weekly_modifier_id() -> String:
	var mod: Dictionary = get_weekly_modifier()
	return mod.get("id", "") as String

## Applies modifier [param modifier_id] to [param run]'s parameters.
##
## Supported effects:
##   "mult_multiplier"     — injects a run buff that scales mult
##   "chip_bonus_flat"     — injects a run buff adding flat chip_bonus
##   "hand_size_bonus"     — (resolved by CombatManager; stored as buff)
##   "gold_multiplier"     — stored as a run buff for gold calculations
##   "discard_penalty"     — injects a run buff subtracting discards_allowed
##   "blessing_mult_bonus" — injects a run buff for blessing layer
##   "element_bonus"       — stored as metadata for UI display (no numeric effect)
##
## No-op if modifier_id is empty or not found.
func apply_modifier(run: AbyssRun, modifier_id: String) -> void:
	if modifier_id.is_empty():
		return

	var mod: Dictionary = get_modifier_by_id(modifier_id)
	if mod.is_empty():
		return

	var effect: String = mod.get("effect", "") as String
	var value: Variant = mod.get("value")

	match effect:
		"mult_multiplier":
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "mult_multiplier",
				"value": value,
			})
		"chip_bonus_flat":
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "chip_bonus",
				"value": value,
			})
		"hand_size_bonus":
			# Hand size is resolved by CombatManager; store as a buff
			# for the combat setup layer to read.
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "hand_size_bonus",
				"value": value,
			})
		"gold_multiplier":
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "gold_multiplier",
				"value": value,
			})
		"discard_penalty":
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "discards_allowed_bonus",
				"value": value,
			})
		"blessing_mult_bonus":
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "mult_bonus",
				"value": value,
			})
		"element_bonus":
			# Stored in run for UI and flavor; no numeric scoring effect.
			run.run_buffs.append({
				"buff_id": modifier_id,
				"effect": "element_bonus",
				"value": value,
			})
		_:
			push_warning("AbyssModifiers.apply_modifier: unknown effect '%s'" % effect)

# ── Private Helpers ───────────────────────────────────────────────────────────

## Returns the ISO 8601 week number (1–53) for the current UTC date.
## GDScript does not expose an ISO week API directly; computed from the
## day-of-year offset by weekday.
func _get_iso_week_number() -> int:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	# day_of_year is 1-indexed (1 = Jan 1).
	# weekday: 0=Sunday, 1=Monday … 6=Saturday in Godot.
	# ISO week: week starts Monday. Use (day_of_year + weekday_offset) / 7.
	var day_of_year: int = now.get("day_of_year", 1) as int
	# Convert Godot weekday to ISO offset (Monday=0 … Sunday=6).
	var godot_weekday: int = now.get("weekday", 0) as int
	var iso_weekday: int = (godot_weekday + 6) % 7  # Mon=0, Sun=6
	# Simple week number: floor((day_of_year - 1 + (3 - iso_weekday)) / 7) + 1
	# (Approximate ISO week — accurate for rotation purposes.)
	var week: int = int(floor((day_of_year - 1 + (3 - iso_weekday)) / 7.0)) + 1
	return week
