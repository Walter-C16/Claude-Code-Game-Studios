extends Control

## ChapterMap — Story node progression screen for Chapter 1.
## Loads ch01.json, displays nodes as buttons, checks flag prerequisites.

@onready var title_label: Label = %TitleLabel
@onready var chapter_list: VBoxContainer = %ChapterList
@onready var back_btn: Button = %BackBtn

var _chapter_data: Dictionary = {}
var _nodes: Array = []

## Tracks looping pulse tweens for available (unlocked) node buttons so we can
## kill them when the scene exits without leaking orphaned tweens.
var _pulse_tweens: Array[Tween] = []

## Tracks looping gold glow tweens for completed node buttons.
var _glow_tweens: Array[Tween] = []

func _ready() -> void:
	_load_chapter()
	_build_node_list()
	# Stagger-animate nodes after a single frame so positions are committed.
	await get_tree().process_frame
	_animate_entrance()


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
	for child: Node in chapter_list.get_children():
		child.queue_free()

	_pulse_tweens.clear()
	_glow_tweens.clear()

	for node_data: Variant in _nodes:
		var data: Dictionary = node_data as Dictionary
		var node_id: String = data.get("id", "") as String
		var node_type: String = data.get("type", "dialogue") as String
		var prereqs: Array = data.get("prereqs", [])

		# Check if all prereqs are met
		var available: bool = true
		for prereq: Variant in prereqs:
			if not GameStore.has_flag(str(prereq)):
				available = false
				break

		# Check if already completed
		var completed: bool = false
		var reward_flags: Array = data.get("rewards", {}).get("flags", [])
		for flag: Variant in reward_flags:
			if GameStore.has_flag(str(flag)):
				completed = true
				break

		# Create button
		var btn := Button.new()
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

		# Visual states
		if completed:
			# Completed nodes: dim modulate to signal done; gold glow pulse on tint.
			btn.modulate = Color(UIConstants.ACCENT_GOLD_DARK, 0.85)
			_start_gold_glow(btn)
		elif not available:
			# Locked nodes: strongly dimmed and static.
			btn.modulate = Color(UIConstants.TEXT_DISABLED, 0.5)
		else:
			# Available nodes: subtle breathing scale animation.
			_start_breathing_pulse(btn)

		if available and not completed:
			var captured_data: Dictionary = data
			btn.pressed.connect(func() -> void: _on_node_pressed(captured_data))

		chapter_list.add_child(btn)


## Stagger all node buttons scaling from 0 to 1 with spring overshoot.
func _animate_entrance() -> void:
	var i: int = 0
	for child: Node in chapter_list.get_children():
		if child is Control:
			var ctrl: Control = child as Control
			ctrl.pivot_offset = ctrl.size * 0.5
			ctrl.scale = Vector2.ZERO
			var t: Tween = ctrl.create_tween()
			t.tween_property(ctrl, "scale", Vector2.ONE, 0.3) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
				.set_delay(i * 0.05)
			i += 1


## Gentle breathing scale loop for available (unlocked) nodes.
func _start_breathing_pulse(btn: Button) -> void:
	var t: Tween = btn.create_tween().set_loops()
	t.tween_property(btn, "scale", Vector2(1.03, 1.03), 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "scale", Vector2.ONE, 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tweens.append(t)


## Gold glow modulate pulse loop for completed nodes.
func _start_gold_glow(btn: Button) -> void:
	var t: Tween = btn.create_tween().set_loops()
	t.tween_property(btn, "modulate", Color(UIConstants.ACCENT_GOLD_BRIGHT, 0.95), 1.5) \
		.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(btn, "modulate", Color(UIConstants.ACCENT_GOLD_DARK, 0.75), 1.5) \
		.set_ease(Tween.EASE_IN_OUT)
	_glow_tweens.append(t)


func _on_node_pressed(node_data: Dictionary) -> void:
	var node_type: String = node_data.get("type", "dialogue") as String
	var node_id: String = node_data.get("id", "") as String

	# Apply meet effects before navigation
	var effects: Array = node_data.get("effects", [])
	for fx: Variant in effects:
		var fx_dict: Dictionary = fx as Dictionary
		var fx_type: String = fx_dict.get("type", "") as String
		if fx_type == "meet":
			GameStore.set_met(fx_dict.get("companion", "") as String, true)

	if node_type == "combat":
		var enemy_id: String = node_data.get("enemy_id", "forest_monster") as String
		SceneManager.change_scene(
			SceneManager.SceneId.COMBAT,
			SceneManager.TransitionType.FADE,
			{"enemy_id": enemy_id, "captain_id": GameStore.get_last_captain_id(), "story_node": node_id}
		)
	else:
		var sequence: String = node_data.get("sequence", "") as String
		SceneManager.change_scene(
			SceneManager.SceneId.DIALOGUE,
			SceneManager.TransitionType.FADE,
			{"chapter_id": "ch01", "sequence_id": sequence, "story_node": node_id}
		)


## Apply node rewards (gold, xp, flags) — called when returning from combat/dialogue
func _apply_rewards(node_data: Dictionary) -> void:
	var rewards: Dictionary = node_data.get("rewards", {}) as Dictionary
	var gold: int = rewards.get("gold", 0) as int
	var xp: int = rewards.get("xp", 0) as int
	var flags: Array = rewards.get("flags", [])
	if gold > 0:
		GameStore.add_gold(gold)
	if xp > 0:
		GameStore.add_xp(xp)
	for flag: Variant in flags:
		GameStore.set_flag(str(flag))


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
