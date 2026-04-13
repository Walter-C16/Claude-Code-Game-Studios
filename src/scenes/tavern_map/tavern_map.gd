extends Control

## TavernMap — Browse tavern tournaments across unlocked locations.
##
## Reads taverns from res://assets/data/taverns.json and shows one card per
## unlocked tavern with difficulty, strong element, and daily-play state.
## Tapping a tavern launches a tournament combat (once per day per tavern).

const DATA_PATH: String = "res://assets/data/taverns.json"

@onready var title_label: Label = %TitleLabel
@onready var tavern_list: VBoxContainer = %TavernList
@onready var back_btn: Button = %BackBtn

var _taverns: Array[Dictionary] = []

func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/camp.ogg")
	title_label.text = Localization.get_text("TAVERN_TITLE")
	_load_taverns()
	_populate()
	await get_tree().process_frame
	Fx.stagger_children(tavern_list, 0.05, 24.0)


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── Data Loading ──────────────────────────────────────────────────────────────

func _load_taverns() -> void:
	_taverns.clear()
	var data: Dictionary = JsonLoader.load_dict(DATA_PATH)
	var entries: Array = data.get("taverns", []) as Array
	for entry: Variant in entries:
		if entry is Dictionary:
			_taverns.append(entry as Dictionary)


# ── UI Construction ───────────────────────────────────────────────────────────

func _populate() -> void:
	for child: Node in tavern_list.get_children():
		child.queue_free()

	# Filter to unlocked taverns only.
	var unlocked: Array[Dictionary] = []
	for tavern: Dictionary in _taverns:
		var unlock_flag: String = tavern.get("unlock_flag", "") as String
		if unlock_flag.is_empty() or GameStore.has_flag(unlock_flag):
			unlocked.append(tavern)

	if unlocked.is_empty():
		var empty: Label = Label.new()
		empty.text = Localization.get_text("TAVERN_LIST_EMPTY")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		empty.add_theme_font_size_override("font_size", 14)
		empty.custom_minimum_size = Vector2(0.0, 80.0)
		tavern_list.add_child(empty)
		return

	# Subtitle.
	var subtitle: Label = Label.new()
	subtitle.text = Localization.get_text("TAVERN_SUBTITLE")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	subtitle.add_theme_font_size_override("font_size", 12)
	tavern_list.add_child(subtitle)

	for tavern: Dictionary in unlocked:
		tavern_list.add_child(_make_tavern_card(tavern))


func _make_tavern_card(tavern: Dictionary) -> Control:
	var tavern_id: String = tavern.get("id", "") as String
	var name_text: String = Localization.get_text(tavern.get("name_key", "") as String)
	var location_text: String = Localization.get_text(tavern.get("location_key", "") as String)
	var desc_text: String = Localization.get_text(tavern.get("description_key", "") as String)
	var difficulty: int = int(tavern.get("difficulty", 1))
	var strong_element: String = tavern.get("strong_element", "") as String
	var gold_reward: int = int(tavern.get("base_gold_reward", 0))
	var can_play: bool = GameStore.can_play_tavern_today(tavern_id)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 180.0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = UIConstants.ACCENT_GOLD if can_play else UIConstants.ACCENT_GOLD_DARK
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Tavern name.
	var name_lbl: Label = Label.new()
	name_lbl.text = name_text
	name_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD if can_play else UIConstants.TEXT_DISABLED)
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)
	if can_play:
		Fx.gold_shimmer(name_lbl, 3.0)

	# Location subtitle.
	var loc_lbl: Label = Label.new()
	loc_lbl.text = location_text
	loc_lbl.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	loc_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(loc_lbl)

	# Description.
	var desc_lbl: Label = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_lbl)

	# Info row: difficulty + strong element + gold.
	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	vbox.add_child(info_row)

	var diff_lbl: Label = Label.new()
	diff_lbl.text = "%s: %s" % [
		Localization.get_text("TAVERN_DIFFICULTY_LABEL"),
		"★".repeat(difficulty),
	]
	diff_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	diff_lbl.add_theme_font_size_override("font_size", 12)
	info_row.add_child(diff_lbl)

	var elem_lbl: Label = Label.new()
	elem_lbl.text = strong_element
	elem_lbl.add_theme_color_override("font_color", _element_color(strong_element))
	elem_lbl.add_theme_font_size_override("font_size", 12)
	info_row.add_child(elem_lbl)

	var gold_lbl: Label = Label.new()
	gold_lbl.text = "+%d gold" % gold_reward
	gold_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	gold_lbl.add_theme_font_size_override("font_size", 12)
	info_row.add_child(gold_lbl)

	# Action button — play or cooldown.
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 44.0)
	btn.add_theme_font_size_override("font_size", 14)
	if can_play:
		btn.text = Localization.get_text("TAVERN_PLAY_BTN")
		btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
		btn_style.bg_color = UIConstants.BG_TERTIARY
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.corner_radius_bottom_right = 6
		btn_style.border_width_left = 1
		btn_style.border_width_right = 1
		btn_style.border_width_top = 1
		btn_style.border_width_bottom = 1
		btn_style.border_color = UIConstants.ACCENT_GOLD
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.pressed.connect(_on_tavern_pressed.bind(tavern))
	else:
		btn.text = Localization.get_text("TAVERN_COME_BACK")
		btn.disabled = true
		btn.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
	vbox.add_child(btn)

	return panel


# ── Tavern Launch ─────────────────────────────────────────────────────────────

func _on_tavern_pressed(tavern: Dictionary) -> void:
	var enemy_config: Dictionary = {
		"name_key": tavern.get("name_key", "ENEMY_SARDIS_CARD_MASTER") as String,
		"score_threshold": int(tavern.get("score_threshold", 70)),
		"hands_allowed": int(tavern.get("hands_allowed", 4)),
		"discards_allowed": int(tavern.get("discards_allowed", 4)),
		"element": tavern.get("strong_element", "") as String,
		"hp": int(tavern.get("score_threshold", 70)),
	}
	var context: Dictionary = {
		"enemy_config": enemy_config,
		"captain_id": GameStore.get_last_captain_id(),
		"tavern_id": tavern.get("id", "") as String,
		"tavern_gold_reward": int(tavern.get("base_gold_reward", 0)),
	}
	SceneManager.change_scene(
		SceneManager.SceneId.COMBAT,
		SceneManager.TransitionType.FADE,
		context
	)


# ── Helpers ────────────────────────────────────────────────────────────────────

func _element_color(element: String) -> Color:
	match element:
		"Fire": return UIConstants.ELEM_FIRE_FG
		"Water": return UIConstants.ELEM_WATER_FG
		"Earth": return UIConstants.ELEM_EARTH_FG
		"Lightning": return UIConstants.ELEM_LIGHTNING_FG
		_: return UIConstants.TEXT_SECONDARY
