extends Node

## SaveManager — JSON Persistence (ADR-0002, ADR-0006)
## Autoload #5. Pure I/O service — reads/writes save.json.
## _ready() may reference GameStore (#1), SettingsStore (#2) — both load before this.

# ── Constants ─────────────────────────────────────────────────────────────────

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save.json"
const TEMP_PATH: String = "user://save.json.tmp"

# ── Virtual Methods ───────────────────────────────────────────────────────────

func _ready() -> void:
	pass  # No initialization needed — save/load triggered by GameStore or UI

# ── Public Methods ────────────────────────────────────────────────────────────

## Writes current GameStore + SettingsStore state to disk atomically.
## Returns true on success, false on write failure.
## Write order: TEMP_PATH first, then rename to SAVE_PATH (ADR-0002).
func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": int(Time.get_unix_time_from_system()),
		"game": GameStore.to_dict(),
		"settings": SettingsStore.to_dict(),
	}
	var json_string := JSON.stringify(data)

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if not file:
		push_warning("SaveManager: cannot open temp file for writing")
		return false
	var success := file.store_string(json_string)
	file.close()
	if not success:
		push_warning("SaveManager: store_string failed")
		return false

	var dir := DirAccess.open("user://")
	if dir:
		dir.rename(TEMP_PATH, SAVE_PATH)
	return true

## Loads save file, migrates if needed, restores GameStore + SettingsStore.
## Returns true on success, false if no file or parse error.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: cannot open save file")
		return false
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("SaveManager: JSON parse error: " + json.get_error_message())
		return false
	var data = json.data
	if not data is Dictionary:
		push_error("SaveManager: save data is not a Dictionary")
		return false
	var save_version: int = data.get("version", 0)
	if save_version < SAVE_VERSION:
		data = _migrate(data, save_version)
	GameStore.from_dict(data.get("game", {}))
	SettingsStore.from_dict(data.get("settings", {}))
	_reconcile_companions()
	return true

## Returns true if a save file exists on disk.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Migrates save data from `from_version` up to SAVE_VERSION.
## Returns the mutated data dictionary with "version" set to SAVE_VERSION.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 1:
		data = _migrate_v0_to_v1(data)
	# Future: if from_version < 2: data = _migrate_v1_to_v2(data)
	data["version"] = SAVE_VERSION
	return data

## Upgrades a version-0 save to version 1.
## Adds economy and social fields that did not exist in v0.
func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	var game: Dictionary = data.get("game", {})
	if not game.has("player_xp"):
		game["player_xp"] = 0
	if not game.has("daily_tokens_remaining"):
		game["daily_tokens_remaining"] = 3
	if not game.has("current_streak"):
		game["current_streak"] = 0
	if not game.has("last_interaction_date"):
		game["last_interaction_date"] = ""
	if not game.has("active_combat_buff"):
		game["active_combat_buff"] = {}
	if not game.has("last_captain_id"):
		game["last_captain_id"] = ""
	data["game"] = game
	return data

## Reconciles GameStore companion states against the authoritative companion
## IDs provided by CompanionRegistry. Called at the end of load_game() so
## that saves written before a companion was added (or after one was removed)
## are healed without corrupting fresh-game state.
## Passes only the 4 playable companion IDs — the priestess NPC entry in
## CompanionRegistry has no mutable state in GameStore and is excluded.
func _reconcile_companions() -> void:
	var companion_ids: Array[String] = ["artemisa", "hipolita", "atenea", "nyx"]
	GameStore.reconcile_companion_states(companion_ids)

## Deletes the save file and resets stores to defaults.
## Idempotent — safe to call when no save file exists.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(TEMP_PATH)
	GameStore._initialize_defaults()
	SettingsStore.from_dict({})
