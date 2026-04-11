extends Control

## Exploration — Dispatch companions on timed missions for gold, XP, and items.
##
## Shows available missions when idle, or a timer + collect button when active.
## Uses ExplorationSystem (static API) for all logic.

# ── Node References ────────────────────────────────────────────────────────────

@onready var title_label: Label = %TitleLabel
@onready var zone_list: VBoxContainer = %ZoneList
@onready var back_btn: Button = %BackBtn

# ── Private State ──────────────────────────────────────────────────────────────

## Timer label reference for active mission countdown.
var _timer_label: Label
var _collect_btn: Button

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	title_label.text = "EXPLORATION"

	for child: Node in zone_list.get_children():
		child.queue_free()

	_build_ui()
	await get_tree().process_frame
	Fx.stagger_children(zone_list, 0.05, 20.0)


func _process(_delta: float) -> void:
	if ExplorationSystem.is_dispatched() and _timer_label != null:
		var remaining: float = ExplorationSystem.get_time_remaining()
		if remaining <= 0.0:
			_timer_label.text = "Mission Complete!"
			_timer_label.add_theme_color_override("font_color", UIConstants.STATUS_SUCCESS)
			if _collect_btn != null:
				_collect_btn.disabled = false
		else:
			_timer_label.text = _format_time(remaining)


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	if ExplorationSystem.is_dispatched():
		_build_active_view()
	else:
		_build_mission_list()


## Shows the active mission with timer and collect/cancel buttons.
func _build_active_view() -> void:
	var state: Dictionary = ExplorationSystem.get_active_mission()
	var companion_id: String = state.get("companion_id", "")
	var mission_id: String = state.get("mission_id", "")

	var profile: Dictionary = CompanionRegistry.get_profile(companion_id)
	var companion_name: String = profile.get("display_name", companion_id.capitalize())

	# Active mission header.
	var header: Label = Label.new()
	header.text = "%s is on a mission" % companion_name
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	header.add_theme_font_size_override("font_size", 18)
	zone_list.add_child(header)

	# Mission name.
	var mission_label: Label = Label.new()
	mission_label.text = mission_id.replace("_", " ").capitalize()
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	mission_label.add_theme_font_size_override("font_size", 14)
	zone_list.add_child(mission_label)

	# Timer.
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_timer_label.add_theme_font_size_override("font_size", 28)
	var remaining: float = ExplorationSystem.get_time_remaining()
	_timer_label.text = _format_time(remaining) if remaining > 0.0 else "Mission Complete!"
	zone_list.add_child(_timer_label)

	# Collect button.
	_collect_btn = _make_button("Collect Rewards")
	_collect_btn.disabled = remaining > 0.0
	_collect_btn.pressed.connect(_on_collect_pressed)
	zone_list.add_child(_collect_btn)

	# Cancel button.
	var cancel_btn: Button = _make_button("Cancel Mission")
	cancel_btn.add_theme_color_override("font_color", UIConstants.STATUS_DANGER)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	zone_list.add_child(cancel_btn)


## Shows available missions with companion selector.
func _build_mission_list() -> void:
	var missions: Array[Dictionary] = ExplorationSystem.get_all_missions()
	if missions.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "No missions available."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		zone_list.add_child(empty_lbl)
		return

	# Companion selector header.
	var comp_header: Label = Label.new()
	comp_header.text = "Select a companion to dispatch:"
	comp_header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	comp_header.add_theme_font_size_override("font_size", 14)
	zone_list.add_child(comp_header)

	# Companion buttons (only met companions).
	var ids: Array[String] = CompanionRegistry.get_all_ids()
	var _selected_companion: String = ""
	for id: String in ids:
		var state: Dictionary = GameStore.get_companion_state(id)
		if not state.get("met", false):
			continue
		var profile: Dictionary = CompanionRegistry.get_profile(id)
		var btn: Button = _make_button(profile.get("display_name", id.capitalize()))
		btn.pressed.connect(func() -> void:
			_show_missions_for(id, missions)
		)
		zone_list.add_child(btn)


## Shows missions for a selected companion.
func _show_missions_for(companion_id: String, missions: Array[Dictionary]) -> void:
	for child: Node in zone_list.get_children():
		child.queue_free()

	var profile: Dictionary = CompanionRegistry.get_profile(companion_id)
	var comp_name: String = profile.get("display_name", companion_id.capitalize())

	var header: Label = Label.new()
	header.text = "Missions for %s" % comp_name
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	header.add_theme_font_size_override("font_size", 16)
	zone_list.add_child(header)

	for mission: Dictionary in missions:
		var mid: String = mission.get("id", "")
		var duration_h: float = float(mission.get("duration_hours", 1))
		var gold: int = int(mission.get("base_gold", 0))
		var xp: int = int(mission.get("base_xp", 0))

		var btn: Button = _make_button(
			"%s\n%dh  |  %d gold  |  %d xp" % [
				mid.replace("_", " ").capitalize(),
				int(duration_h), gold, xp
			]
		)
		btn.pressed.connect(func() -> void:
			var result: Dictionary = ExplorationSystem.dispatch(companion_id, mid)
			if result.get("ok", false):
				_rebuild()
			else:
				push_warning("Dispatch failed: %s" % result.get("error", ""))
		)
		zone_list.add_child(btn)

	# Back to companion list.
	var back: Button = _make_button("< Back")
	back.pressed.connect(_rebuild)
	zone_list.add_child(back)

	await get_tree().process_frame
	Fx.stagger_children(zone_list, 0.04, 16.0)


# ── Actions ────────────────────────────────────────────────────────────────────

func _on_collect_pressed() -> void:
	var result: Dictionary = ExplorationSystem.collect()
	if result.has("error"):
		return
	var gold: int = result.get("gold", 0)
	var xp: int = result.get("xp", 0)
	# Show brief reward feedback.
	if _timer_label != null:
		_timer_label.text = "+%d gold  +%d xp" % [gold, xp]
		_timer_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
		Fx.pop_scale(_timer_label)
	await get_tree().create_timer(1.5).timeout
	_rebuild()


func _on_cancel_pressed() -> void:
	ExplorationSystem.cancel()
	_rebuild()


# ── Helpers ────────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	_timer_label = null
	_collect_btn = null
	for child: Node in zone_list.get_children():
		child.queue_free()
	_build_ui()
	await get_tree().process_frame
	Fx.stagger_children(zone_list, 0.04, 16.0)


func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	var h: int = total / 3600
	var m: int = (total % 3600) / 60
	var s: int = total % 60
	if h > 0:
		return "%dh %02dm %02ds" % [h, m, s]
	return "%02dm %02ds" % [m, s]


func _make_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 56.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	btn.add_theme_font_size_override("font_size", 14)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = UIConstants.ACCENT_GOLD_DARK
	btn.add_theme_stylebox_override("normal", style)
	return btn
