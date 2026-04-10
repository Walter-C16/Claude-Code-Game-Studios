class_name DialogueRunner

## DialogueRunner — Dialogue Loading and Effect Processing (LOC-005)
##
## All text resolution routes through Localization.get_text().
## DialogueRunner does NOT read i18n files directly.

# ---------------------------------------------------------------------------
# Load dialogue JSON
# ---------------------------------------------------------------------------

static func load_dialogue(dialogue_id: String) -> Dictionary:
	var path := "res://data/dialogues/%s.json" % dialogue_id
	if not FileAccess.file_exists(path):
		push_warning("[DialogueRunner] File not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("[DialogueRunner] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}

	return json.data if json.data is Dictionary else {}

# ---------------------------------------------------------------------------
# Start dialogue
# ---------------------------------------------------------------------------

static func start_dialogue(dialogue_id: String, start_node: String = "start") -> bool:
	var data := load_dialogue(dialogue_id)
	if data.is_empty():
		return false

	var nodes: Dictionary = data.get("nodes", {})
	if nodes.is_empty():
		return false

	DialogueStore.start_dialogue(dialogue_id, nodes, start_node)
	return true

# ---------------------------------------------------------------------------
# Effect processing
# ---------------------------------------------------------------------------

static func apply_effects(effects: Array) -> void:
	for fx in effects:
		if fx is not Dictionary:
			continue
		match fx.get("type", ""):
			"relationship":
				var id: String = fx.get("companion", "")
				var delta: int = fx.get("value", 0)
				var current: int = GameStore.get_relationship_level(id)
				GameStore._set_relationship_level(id, current + delta)
			"trust":
				GameStore.set_trust(fx.get("companion", ""), fx.get("value", 0))
			"flag":
				var key: String = fx.get("key", "")
				if not key.is_empty():
					GameStore.set_flag(key)
			"meet":
				GameStore.set_met(fx.get("companion", ""), true)

# ---------------------------------------------------------------------------
# Text resolution
# ---------------------------------------------------------------------------

## Resolves a localised string via the Localization autoload.
## All {{param}} interpolation is handled by Localization.get_text().
static func get_text(key: String, params: Dictionary = {}) -> String:
	return Localization.get_text(key, params)
