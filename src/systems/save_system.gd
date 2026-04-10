class_name SaveSystem

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

static func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game": GameStore.to_dict(),
		"settings": SettingsStore.to_dict(),
	}

	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[SaveSystem] Failed to open save file for writing.")
		return false

	file.store_string(json_string)
	file.close()
	return true

static func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("[SaveSystem] JSON parse error: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("[SaveSystem] Save version mismatch.")
		# Future: add migration logic here

	GameStore.from_dict(data.get("game", {}))
	SettingsStore.from_dict(data.get("settings", {}))
	return true

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
