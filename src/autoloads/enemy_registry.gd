extends Node

## EnemyRegistry — Static Enemy Profile Loader (ADR-0016, ADR-0006)
##
## Autoload #8. Boot position: after CompanionRegistry (or DialogueStore/CombatStore
## in current project.godot ordering). Must not reference any autoload positioned
## after #8 during _ready().
##
## Loads all enemy profiles from res://assets/data/enemies.json at startup.
## Derives attack values via floor(hp * ATTACK_RATIO) at load time.
## Validates data integrity: clamps score_threshold, logs hp<=0, nullifies bad elements.
## All getters return defensive copies — callers cannot mutate registry state.
##
## Public API:
##   get_enemy(id)                  -> Dictionary   (empty {} if not found)
##   has_enemy(id)                  -> bool
##   get_all_ids()                  -> Array[String]
##   get_all_enemies()              -> Array[Dictionary]
##   get_enemies_by_chapter(chap)   -> Array[Dictionary]
##   get_enemy_name(id)             -> String        (via Localization.get_text)
##
## See: docs/architecture/adr-0016-enemy-registry.md

# ── Constants ─────────────────────────────────────────────────────────────────

## Path to the JSON data file. Must exist at res://assets/data/enemies.json.
const DATA_PATH: String = "res://assets/data/enemies.json"

## Default attack ratio used when config block is absent from the JSON.
const DEFAULT_ATTACK_RATIO: float = 0.1

## Enemy type string constants (TR-enemy-data-003).
## Stored as strings — matches GDD naming and avoids cross-file enum coupling.
const TYPE_NORMAL: String = "Normal"
const TYPE_BOSS: String = "Boss"
const TYPE_DUEL: String = "Duel"
const TYPE_ABYSS: String = "Abyss"

## Valid element string values. Must stay in sync with CompanionData (ADR-0009).
const VALID_ELEMENTS: Array[String] = ["Fire", "Water", "Earth", "Lightning"]

## Valid enemy type string values.
const VALID_TYPES: Array[String] = ["Normal", "Boss", "Duel", "Abyss"]

# ── Private State ─────────────────────────────────────────────────────────────

## Internal registry. Key = enemy id String, value = validated profile Dictionary.
## Never mutated after _ready() completes — read-only thereafter.
var _enemies: Dictionary = {}

## Attack ratio loaded from the config block in enemies.json.
## Fallback: DEFAULT_ATTACK_RATIO if the key is absent.
var _attack_ratio: float = DEFAULT_ATTACK_RATIO

# ── Virtual Methods ───────────────────────────────────────────────────────────

func _ready() -> void:
	_load_enemies()

# ── Public Methods ────────────────────────────────────────────────────────────

## Returns a defensive copy of the enemy profile for id.
## Returns an empty Dictionary if id is not registered (never crashes).
## O(1) — Dictionary.get() lookup. Satisfies TR-enemy-data-007 (<1ms).
func get_enemy(id: String) -> Dictionary:
	var profile: Dictionary = _enemies.get(id, {})
	if profile.is_empty():
		return {}
	return profile.duplicate()

## Returns true if the enemy id exists in the registry.
func has_enemy(id: String) -> bool:
	return _enemies.has(id)

## Returns all registered enemy IDs as a typed Array[String].
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in _enemies:
		ids.append(key)
	return ids

## Returns defensive copies of all registered enemy profiles.
func get_all_enemies() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for profile: Dictionary in _enemies.values():
		result.append(profile.duplicate())
	return result

## Returns defensive copies of all enemy profiles for the given chapter string.
## Returns an empty array if no enemies match or chapter is unknown.
func get_enemies_by_chapter(chapter: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for profile: Dictionary in _enemies.values():
		if profile.get("chapter", "") == chapter:
			result.append(profile.duplicate())
	return result

## Returns the display name for the enemy, resolved through Localization.
## Falls back to the raw id if the enemy is not registered.
## Requires Localization autoload (#4) to be initialized — safe from #8.
func get_enemy_name(id: String) -> String:
	var profile: Dictionary = _enemies.get(id, {})
	if profile.is_empty():
		return id
	return Localization.get_text(profile["name_key"])

# ── Private Methods ───────────────────────────────────────────────────────────

## Loads and parses enemies.json, then validates and indexes each profile.
## On any load failure the registry remains empty and combat falls back to
## inline enemy_config from story nodes (per ADR-0016 risk mitigation).
func _load_enemies() -> void:
	var root: Dictionary = JsonLoader.load_dict(DATA_PATH)
	if root.is_empty():
		return

	# Read configurable attack ratio from the config block.
	if root.has("config") and root["config"] is Dictionary:
		var config: Dictionary = root["config"]
		if config.has("ATTACK_RATIO") and config["ATTACK_RATIO"] is float:
			_attack_ratio = config["ATTACK_RATIO"]

	# Parse the enemies array and index by id.
	if not root.has("enemies") or not root["enemies"] is Array:
		push_error("EnemyRegistry: missing or malformed 'enemies' array in '%s'" % DATA_PATH)
		return

	var enemies_array: Array = root["enemies"]
	for entry: Variant in enemies_array:
		if not entry is Dictionary:
			push_warning("EnemyRegistry: skipping non-Dictionary enemy entry")
			continue

		var profile: Dictionary = entry.duplicate()

		if not profile.has("id") or not profile["id"] is String or profile["id"].is_empty():
			push_warning("EnemyRegistry: skipping enemy with missing or empty id")
			continue

		var validated: Dictionary = _validate_enemy(profile)
		_enemies[validated["id"]] = validated

## Validates a single enemy profile Dictionary in-place and derives computed fields.
## Returns the mutated profile. All validation warnings/errors are emitted via
## push_warning / push_error so they appear in the Godot debugger and log.
func _validate_enemy(profile: Dictionary) -> Dictionary:
	var id: String = profile.get("id", "unknown")

	# Ensure required integer fields have sensible defaults if missing.
	if not profile.has("hp") or not profile["hp"] is float and not profile["hp"] is int:
		push_error("EnemyRegistry: %s missing or invalid 'hp', defaulting to 0" % id)
		profile["hp"] = 0

	var hp: int = int(profile["hp"])
	profile["hp"] = hp

	# TR-enemy-data-005 — hp <= 0 is a data error; flag for instant-victory.
	if hp <= 0:
		push_error(
			"EnemyRegistry: %s has hp <= 0 (%d), will be instant victory" % [id, hp]
		)
		profile["instant_victory"] = true
	else:
		profile["instant_victory"] = false

	# Ensure score_threshold exists and is an integer.
	if not profile.has("score_threshold"):
		profile["score_threshold"] = hp
	else:
		profile["score_threshold"] = int(profile["score_threshold"])

	# TR-enemy-data-005 — clamp score_threshold to hp if exceeded.
	var score_threshold: int = profile["score_threshold"]
	if score_threshold > hp:
		push_warning(
			"EnemyRegistry: %s score_threshold (%d) > hp (%d), clamping to hp"
			% [id, score_threshold, hp]
		)
		profile["score_threshold"] = hp

	# Validate element: must be null or one of VALID_ELEMENTS.
	var element: Variant = profile.get("element", null)
	if element != null:
		if not element is String or element not in VALID_ELEMENTS:
			push_warning(
				"EnemyRegistry: %s invalid element '%s', defaulting to null"
				% [id, str(element)]
			)
			profile["element"] = null

	# Validate type: must be one of VALID_TYPES; default to Normal.
	var enemy_type: Variant = profile.get("type", "")
	if not enemy_type is String or enemy_type not in VALID_TYPES:
		push_warning(
			"EnemyRegistry: %s invalid type '%s', defaulting to Normal"
			% [id, str(enemy_type)]
		)
		profile["type"] = TYPE_NORMAL

	# TR-enemy-data-004 — derive attack from hp * _attack_ratio.
	profile["attack"] = int(floor(float(hp) * _attack_ratio))

	return profile
