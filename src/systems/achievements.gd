class_name Achievements
extends RefCounted

## Achievements — Milestone Tracker (Full Vision)
##
## Checks conditions against GameStore state and companion/gallery progress.
## Returns unlocked/locked status per achievement. Stateless — evaluates
## conditions fresh on each call.

const DATA_PATH: String = "res://assets/data/achievements.json"

static var _definitions: Array = []
static var _loaded: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	var file = FileAccess.open(DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Achievements: failed to open " + DATA_PATH)
		_loaded = true
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Achievements: JSON parse error")
		_loaded = true
		return
	if json.data is Dictionary and json.data.has("achievements"):
		_definitions = json.data["achievements"]
	_loaded = true


## Returns all achievement definitions with their current unlock status.
static func get_all() -> Array:
	_ensure_loaded()
	var result: Array = []
	for def in _definitions:
		var unlocked: bool = check_achievement(def.get("id", ""))
		result.append({
			"id": def.get("id", ""),
			"title_key": def.get("title_key", ""),
			"description_key": def.get("description_key", ""),
			"unlocked": unlocked,
		})
	return result


## Returns only unlocked achievements.
static func get_unlocked() -> Array:
	var all = get_all()
	var result: Array = []
	for entry in all:
		if entry["unlocked"]:
			result.append(entry)
	return result


## Checks whether a specific achievement's conditions are met.
static func check_achievement(id: String) -> bool:
	_ensure_loaded()
	for def in _definitions:
		if def.get("id", "") == id:
			return _evaluate_condition(def.get("condition", {}))
	return false


## Returns progress toward an achievement: {current, target, complete}.
static func get_progress(id: String) -> Dictionary:
	_ensure_loaded()
	for def in _definitions:
		if def.get("id", "") == id:
			var cond: Dictionary = def.get("condition", {})
			var target: int = cond.get("target", 1)
			var current: int = _get_current_value(cond)
			return {"current": current, "target": target, "complete": current >= target}
	return {"current": 0, "target": 1, "complete": false}


static func _evaluate_condition(condition: Dictionary) -> bool:
	match condition.get("type", ""):
		"flag":
			return GameStore.has_flag(condition.get("flag", ""))
		"combat_wins":
			# Count combat win flags (ch01_combat_*, etc.)
			var count: int = 0
			for flag in GameStore.get_story_flags():
				if "combat_won" in flag:
					count += 1
			return count >= condition.get("target", 1)
		"romance_stage":
			var companion_id: String = condition.get("companion", "")
			var target: int = condition.get("target", 1)
			if companion_id == "any":
				for id in ["artemis", "hipolita", "atenea", "nyx"]:
					if CompanionState.get_romance_stage(id) >= target:
						return true
				return false
			return CompanionState.get_romance_stage(companion_id) >= target
		"gallery_count":
			return Gallery.get_unlocked_count() >= condition.get("target", 1)
		"equipment_rarity":
			var weapon: String = GameStore.get_equipped_weapon()
			var amulet: String = GameStore.get_equipped_amulet()
			# Check if either equipped item is Legendary
			# (would need EquipmentSystem.get_item() — simplified check via flag)
			return GameStore.has_flag("equipped_legendary")
		"abyss_ante":
			return GameStore.has_flag("abyss_ante_%d_cleared" % condition.get("target", 8))
	return false


static func _get_current_value(condition: Dictionary) -> int:
	match condition.get("type", ""):
		"combat_wins":
			var count: int = 0
			for flag in GameStore.get_story_flags():
				if "combat_won" in flag:
					count += 1
			return count
		"romance_stage":
			var companion_id: String = condition.get("companion", "")
			if companion_id == "any":
				var best: int = 0
				for id in ["artemis", "hipolita", "atenea", "nyx"]:
					best = maxi(best, CompanionState.get_romance_stage(id))
				return best
			return CompanionState.get_romance_stage(companion_id)
		"gallery_count":
			return Gallery.get_unlocked_count()
		"abyss_ante":
			for i in range(8, 0, -1):
				if GameStore.has_flag("abyss_ante_%d_cleared" % i):
					return i
			return 0
	return 0
