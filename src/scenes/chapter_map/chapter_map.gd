extends Control

## ChapterMap — Story node progression screen for Chapter 1.
## Loads ch01.json, displays nodes as buttons, checks flag prerequisites.

@onready var title_label: Label = %TitleLabel
@onready var chapter_list: VBoxContainer = %ChapterList
@onready var back_btn: Button = %BackBtn

var _chapter_data: Dictionary = {}
var _nodes: Array = []

func _ready() -> void:
	_load_chapter()
	_build_node_list()


func _load_chapter() -> void:
	var path: String = "res://assets/data/chapters/ch01.json"
	if not FileAccess.file_exists(path):
		push_warning("ChapterMap: ch01.json not found")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	_chapter_data = json.data
	_nodes = _chapter_data.get("nodes", [])
	title_label.text = Localization.get_text(_chapter_data.get("title_key", "Chapter 1"))


func _build_node_list() -> void:
	# Clear existing
	for child in chapter_list.get_children():
		child.queue_free()

	for node_data in _nodes:
		var node_id: String = node_data.get("id", "")
		var node_type: String = node_data.get("type", "dialogue")
		var prereqs: Array = node_data.get("prereqs", [])

		# Check if all prereqs are met
		var available: bool = true
		for prereq in prereqs:
			if not GameStore.has_flag(str(prereq)):
				available = false
				break

		# Check if already completed
		var completed: bool = false
		var reward_flags: Array = node_data.get("rewards", {}).get("flags", [])
		for flag in reward_flags:
			if GameStore.has_flag(str(flag)):
				completed = true
				break

		# Create button
		var btn = Button.new()
		var icon: String = "⚔" if node_type == "combat" else "💬"
		var status: String = " ✓" if completed else ""

		# Get display name from en.json or node_id
		var name_key: String = "CHAPTER_NODE_%s" % node_id.to_upper()
		var display_name: String = Localization.get_text(name_key)
		if display_name == name_key:
			# No translation — use a readable fallback
			display_name = node_id.replace("ch01_", "").replace("_", " ").capitalize()

		btn.text = "%s %s%s" % [icon, display_name, status]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.disabled = not available or completed

		if available and not completed:
			var captured_data: Dictionary = node_data
			btn.pressed.connect(func() -> void: _on_node_pressed(captured_data))

		chapter_list.add_child(btn)


func _on_node_pressed(node_data: Dictionary) -> void:
	var node_type: String = node_data.get("type", "dialogue")
	var node_id: String = node_data.get("id", "")

	# Apply meet effects before navigation
	var effects: Array = node_data.get("effects", [])
	for fx in effects:
		var fx_type: String = fx.get("type", "")
		if fx_type == "meet":
			GameStore.set_met(fx.get("companion", ""), true)

	if node_type == "combat":
		var enemy_id: String = node_data.get("enemy_id", "forest_monster")
		SceneManager.change_scene(
			SceneManager.SceneId.COMBAT,
			SceneManager.TransitionType.FADE,
			{"enemy_id": enemy_id, "captain_id": GameStore.get_last_captain_id(), "story_node": node_id}
		)
	else:
		var sequence: String = node_data.get("sequence", "")
		SceneManager.change_scene(
			SceneManager.SceneId.DIALOGUE,
			SceneManager.TransitionType.FADE,
			{"chapter_id": "ch01", "sequence_id": sequence, "story_node": node_id}
		)


## Apply node rewards (gold, xp, flags) — called when returning from combat/dialogue
func _apply_rewards(node_data: Dictionary) -> void:
	var rewards: Dictionary = node_data.get("rewards", {})
	var gold: int = rewards.get("gold", 0)
	var xp: int = rewards.get("xp", 0)
	var flags: Array = rewards.get("flags", [])
	if gold > 0:
		GameStore.add_gold(gold)
	if xp > 0:
		GameStore.add_xp(xp)
	for flag in flags:
		GameStore.set_flag(str(flag))


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
