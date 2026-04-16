extends Control

## CompanionRoom — Camp screen. Grid of met companions, detail view, talk/gift interactions.
##
## All UI nodes beyond BackBtn are built dynamically in _build_ui().
## Uses: CompanionRegistry, GameStore, RomanceSocial, GiftItems, CompanionState, Fx, Localization.

# ── Constants ─────────────────────────────────────────────────────────────────

## Feedback auto-hide delay in seconds.
const FEEDBACK_HIDE_DELAY: float = 1.5

## Slide-in offset for the detail panel (from bottom).
const DETAIL_SLIDE_OFFSET: Vector2 = Vector2(0.0, 60.0)

## Romance stage names, indexed 0-4.
const STAGE_NAMES: Array[String] = ["Stranger", "Acquaintance", "Companion", "Confidant", "Soulmate"]

## Mood display names, indexed 0-4 (mirrors RomanceSocial.Mood enum order).
const MOOD_NAMES: Array[String] = ["Content", "Lonely", "Annoyed", "Happy", "Excited"]

# ── Node References ────────────────────────────────────────────────────────────

@onready var _back_btn: Button = %BackBtn

# Built dynamically — assigned in _build_ui().
var _title_label: Label
var _token_label: Label
var _streak_label: Label
var _gold_label: Label
var _companion_grid: GridContainer
var _detail_panel: PanelContainer
var _detail_portrait: TextureRect
var _detail_name_label: Label
var _detail_role_label: Label
var _detail_rl_bar: ProgressBar
var _detail_stage_label: Label
var _detail_mood_label: Label
var _detail_level_label: Label
var _detail_xp_bar: ProgressBar
var _detail_level_up_btn: Button
var _detail_level_up_cost_label: Label
var _talk_btn: Button
var _gift_open_btn: Button
var _gift_modal: PanelContainer
var _gift_list: VBoxContainer
var _feedback_label: Label

# ── Private State ──────────────────────────────────────────────────────────────

## ID of the currently selected companion in the detail panel.
var _selected_id: String = ""

## Feedback hide timer tween — killed if a new feedback fires before it expires.
var _feedback_tween: Tween
var _gift_modal_backdrop: ColorRect

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/camp.ogg")
	_build_ui()
	_build_companion_grid()
	_refresh_top_bar()
	GameStore.state_changed.connect(_on_state_changed)
	tree_exiting.connect(_disconnect_autoload_signals)
	await get_tree().process_frame
	Fx.stagger_children(_companion_grid, 0.06, 24.0)
	TutorialOverlay.show_once(self,
		"tutorial_camp_shown",
		"TUTORIAL_CAMP_TITLE",
		"TUTORIAL_CAMP_BODY")


# ── UI Construction ────────────────────────────────────────────────────────────

## Builds all dynamic UI nodes and wires signals.
func _build_ui() -> void:
	_build_top_bar_labels()
	_build_companion_grid_node()
	_build_detail_panel()
	_build_gift_modal()
	_build_feedback_label()


## Adds token/streak/gold labels into the existing TopBar HBoxContainer.
func _build_top_bar_labels() -> void:
	var top_bar: HBoxContainer = _find_top_bar()
	if top_bar == null:
		push_error("CompanionRoom: TopBar node not found")
		return

	# Remove the old Spacer if present.
	for child: Node in top_bar.get_children():
		if child.name == "Spacer":
			child.queue_free()

	_title_label = Label.new()
	_title_label.text = Localization.get_text("CAMP_TITLE")
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(_title_label)

	_token_label = Label.new()
	_token_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_token_label.add_theme_font_size_override("font_size", 14)
	_token_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(_token_label)

	_streak_label = Label.new()
	_streak_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	_streak_label.add_theme_font_size_override("font_size", 14)
	_streak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(_streak_label)

	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(_gold_label)


## Creates the 2-column GridContainer for companion cards.
func _build_companion_grid_node() -> void:
	# Remove old CompanionInfoPanel and Portrait from .tscn if they exist.
	for node_name: String in ["CompanionInfoPanel", "Portrait"]:
		var old_node: Node = get_node_or_null(node_name)
		if old_node != null:
			old_node.queue_free()

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 64.0
	scroll.offset_left = 12.0
	scroll.offset_right = -12.0
	add_child(scroll)

	_companion_grid = GridContainer.new()
	_companion_grid.columns = 2
	_companion_grid.add_theme_constant_override("h_separation", 12)
	_companion_grid.add_theme_constant_override("v_separation", 12)
	_companion_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_companion_grid)


## Builds the bottom-half detail panel (hidden by default).
func _build_detail_panel() -> void:
	_detail_panel = PanelContainer.new()
	_detail_panel.visible = false
	_detail_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_detail_panel.offset_top = -420.0
	_detail_panel.add_theme_stylebox_override("panel", _make_panel_style(UIConstants.BG_SECONDARY))
	add_child(_detail_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_detail_panel.add_child(vbox)

	# Close button row.
	var close_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(close_row)
	var close_spacer: Control = Control.new()
	close_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_row.add_child(close_spacer)
	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44.0, 44.0)
	close_btn.pressed.connect(_hide_detail)
	close_row.add_child(close_btn)

	# Portrait + name row.
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	_detail_portrait = TextureRect.new()
	_detail_portrait.custom_minimum_size = Vector2(80.0, 80.0)
	_detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_detail_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	header_row.add_child(_detail_portrait)

	var name_col: VBoxContainer = VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_col)

	_detail_name_label = Label.new()
	_detail_name_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	_detail_name_label.add_theme_font_size_override("font_size", 22)
	name_col.add_child(_detail_name_label)

	_detail_role_label = Label.new()
	_detail_role_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_detail_role_label.add_theme_font_size_override("font_size", 13)
	name_col.add_child(_detail_role_label)

	_detail_stage_label = Label.new()
	_detail_stage_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_detail_stage_label.add_theme_font_size_override("font_size", 13)
	name_col.add_child(_detail_stage_label)

	_detail_mood_label = Label.new()
	_detail_mood_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_detail_mood_label.add_theme_font_size_override("font_size", 13)
	name_col.add_child(_detail_mood_label)

	# RL progress bar.
	_detail_rl_bar = ProgressBar.new()
	_detail_rl_bar.min_value = 0.0
	_detail_rl_bar.max_value = 100.0
	_detail_rl_bar.custom_minimum_size = Vector2(0.0, 12.0)
	_detail_rl_bar.show_percentage = false
	var bar_fill: StyleBoxFlat = StyleBoxFlat.new()
	bar_fill.bg_color = UIConstants.ACCENT_GOLD
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_left = 4
	bar_fill.corner_radius_bottom_right = 4
	_detail_rl_bar.add_theme_stylebox_override("fill", bar_fill)
	var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
	bar_bg.bg_color = UIConstants.BG_TERTIARY
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	_detail_rl_bar.add_theme_stylebox_override("background", bar_bg)
	vbox.add_child(_detail_rl_bar)

	# Combat level + XP progress bar. Displayed below the relationship bar so
	# players read romance first (the primary arc) then combat progression.
	_detail_level_label = Label.new()
	_detail_level_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_detail_level_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_detail_level_label)

	_detail_xp_bar = ProgressBar.new()
	_detail_xp_bar.min_value = 0.0
	_detail_xp_bar.max_value = 1.0
	_detail_xp_bar.step = 0.001
	_detail_xp_bar.custom_minimum_size = Vector2(0.0, 10.0)
	_detail_xp_bar.show_percentage = false
	var xp_fill: StyleBoxFlat = StyleBoxFlat.new()
	xp_fill.bg_color = UIConstants.ACCENT_GOLD_BRIGHT
	xp_fill.corner_radius_top_left = 3
	xp_fill.corner_radius_top_right = 3
	xp_fill.corner_radius_bottom_left = 3
	xp_fill.corner_radius_bottom_right = 3
	_detail_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	var xp_bg: StyleBoxFlat = StyleBoxFlat.new()
	xp_bg.bg_color = UIConstants.BG_TERTIARY
	xp_bg.corner_radius_top_left = 3
	xp_bg.corner_radius_top_right = 3
	xp_bg.corner_radius_bottom_left = 3
	xp_bg.corner_radius_bottom_right = 3
	_detail_xp_bar.add_theme_stylebox_override("background", xp_bg)
	vbox.add_child(_detail_xp_bar)

	# Level up button + cost hint. The button is disabled until the player
	# has enough banked XP AND enough gold for the next level.
	_detail_level_up_cost_label = Label.new()
	_detail_level_up_cost_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_detail_level_up_cost_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_detail_level_up_cost_label)

	_detail_level_up_btn = Button.new()
	_detail_level_up_btn.text = Localization.get_text("COMPANION_LEVEL_UP_BUTTON")
	_detail_level_up_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_detail_level_up_btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_detail_level_up_btn.add_theme_font_size_override("font_size", 14)
	_detail_level_up_btn.pressed.connect(_on_level_up_pressed)
	vbox.add_child(_detail_level_up_btn)

	# Action buttons row.
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_talk_btn = _make_action_button(Localization.get_text("CAMP_TALK_BTN"))
	_talk_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(_talk_btn)
	_talk_btn.pressed.connect(_on_talk_pressed)

	_gift_open_btn = _make_action_button(Localization.get_text("CAMP_GIFT_BTN"))
	_gift_open_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(_gift_open_btn)
	_gift_open_btn.pressed.connect(_on_gift_btn_pressed)


## Builds the centered gift picker modal (hidden by default). Ships with a
## full-screen backdrop that dismisses the modal on tap — otherwise the
## player's only exit is the Cancel button, which is easy to miss.
func _build_gift_modal() -> void:
	_gift_modal_backdrop = ColorRect.new()
	_gift_modal_backdrop.name = "GiftModalBackdrop"
	_gift_modal_backdrop.visible = false
	_gift_modal_backdrop.color = Color(0.0, 0.0, 0.0, 0.55)
	_gift_modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gift_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_gift_modal_backdrop.gui_input.connect(_on_gift_modal_backdrop_input)
	add_child(_gift_modal_backdrop)

	_gift_modal = PanelContainer.new()
	_gift_modal.visible = false
	_gift_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_gift_modal.custom_minimum_size = Vector2(320.0, 400.0)
	_gift_modal.add_theme_stylebox_override("panel", _make_panel_style(UIConstants.BG_SECONDARY))
	add_child(_gift_modal)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_gift_modal.add_child(vbox)

	var modal_title: Label = Label.new()
	modal_title.text = Localization.get_text("GIFT_MODAL_TITLE")
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	modal_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(modal_title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 260.0)
	vbox.add_child(scroll)

	_gift_list = VBoxContainer.new()
	_gift_list.add_theme_constant_override("separation", 6)
	_gift_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_gift_list)

	var cancel_btn: Button = _make_action_button(Localization.get_text("GIFT_MODAL_CANCEL"))
	cancel_btn.pressed.connect(_on_gift_modal_cancel)
	vbox.add_child(cancel_btn)


## Builds the floating feedback label (hidden by default).
func _build_feedback_label() -> void:
	_feedback_label = Label.new()
	_feedback_label.visible = false
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_feedback_label.offset_top = -80.0
	_feedback_label.offset_bottom = -40.0
	_feedback_label.add_theme_color_override("font_color", UIConstants.STATUS_SUCCESS)
	_feedback_label.add_theme_font_size_override("font_size", 28)
	add_child(_feedback_label)


# ── Companion Grid ─────────────────────────────────────────────────────────────

## Populates the grid with all met companions.
func _build_companion_grid() -> void:
	for child: Node in _companion_grid.get_children():
		child.queue_free()

	var ids: Array[String] = CompanionRegistry.get_all_ids()
	for id: String in ids:
		var state: Dictionary = GameStore.get_companion_state(id)
		if not state.get("met", false):
			continue
		var cell: Control = _make_companion_cell(id)
		_companion_grid.add_child(cell)


## Creates a single tappable companion cell for the grid.
func _make_companion_cell(id: String) -> Control:
	var profile: Dictionary = CompanionRegistry.get_profile(id)
	var mood_int: int = RomanceSocial.get_mood(id)
	var mood_name: String = _mood_id_to_portrait_mood(mood_int)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 140.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.flat = true

	var cell_vbox: VBoxContainer = VBoxContainer.new()
	cell_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cell_vbox.add_theme_constant_override("separation", 4)
	cell_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cell_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cell_vbox)

	var portrait_rect: TextureRect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(80.0, 80.0)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell_vbox.add_child(portrait_rect)

	var portrait_path: String = CompanionRegistry.get_portrait_path(id, mood_name)
	if ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)

	var name_label: Label = Label.new()
	name_label.text = profile.get("display_name", id.capitalize())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell_vbox.add_child(name_label)

	# Style the cell background.
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = UIConstants.BG_SECONDARY
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = UIConstants.ACCENT_GOLD_DARK
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.border_color = UIConstants.ACCENT_GOLD
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	btn.pressed.connect(_on_companion_cell_pressed.bind(id))
	return btn


# ── Detail Panel ───────────────────────────────────────────────────────────────

## Shows the detail panel for the given companion id with a slide-in animation.
func _show_detail(id: String) -> void:
	_selected_id = id
	_refresh_detail_panel()
	_detail_panel.visible = true
	Fx.slide_in(_detail_panel, DETAIL_SLIDE_OFFSET, 0.35)


## Refreshes all fields in the detail panel for _selected_id.
func _refresh_detail_panel() -> void:
	if _selected_id.is_empty():
		return

	var profile: Dictionary = CompanionRegistry.get_profile(_selected_id)
	var state: Dictionary = GameStore.get_companion_state(_selected_id)
	var rl: int = state.get("relationship_level", 0)
	var stage: int = CompanionState.get_romance_stage(_selected_id)
	var mood_int: int = RomanceSocial.get_mood(_selected_id)
	var mood_str: String = _mood_id_to_portrait_mood(mood_int)

	# Portrait.
	var portrait_path: String = CompanionRegistry.get_portrait_path(_selected_id, mood_str)
	if ResourceLoader.exists(portrait_path):
		_detail_portrait.texture = load(portrait_path)

	# Labels.
	_detail_name_label.text = profile.get("display_name", _selected_id.capitalize())
	_detail_role_label.text = profile.get("role", "")
	var stage_name: String = STAGE_NAMES[clampi(stage, 0, STAGE_NAMES.size() - 1)]
	_detail_stage_label.text = "Stage %d - %s" % [stage, stage_name]
	_detail_mood_label.text = "Mood: %s" % MOOD_NAMES[clampi(mood_int, 0, MOOD_NAMES.size() - 1)]

	# RL bar.
	_detail_rl_bar.value = float(rl)

	# Combat level + XP. XP is spent on level-up, so the bar shows
	# "banked XP / XP needed for next level". "MAX" replaces the fraction at cap.
	var level: int = GameStore.get_companion_level(_selected_id)
	var banked_xp: int = GameStore.get_companion_xp(_selected_id)
	var xp_cost: int = GameStore.get_level_up_xp_cost(_selected_id)
	var gold_cost: int = GameStore.get_level_up_gold_cost(_selected_id)
	if xp_cost <= 0:
		_detail_level_label.text = "%s %d · %s" % [
			Localization.get_text("COMPANION_LEVEL_LABEL"),
			level,
			Localization.get_text("COMPANION_LEVEL_MAX"),
		]
		_detail_xp_bar.value = 1.0
		_detail_level_up_cost_label.text = ""
		_detail_level_up_btn.disabled = true
		_detail_level_up_btn.visible = false
	else:
		_detail_level_label.text = "%s %d · %d / %d XP" % [
			Localization.get_text("COMPANION_LEVEL_LABEL"),
			level,
			banked_xp,
			xp_cost,
		]
		_detail_xp_bar.value = clampf(float(banked_xp) / float(xp_cost), 0.0, 1.0)
		_detail_level_up_cost_label.text = "%s: %d XP · %d Gold" % [
			Localization.get_text("COMPANION_LEVEL_UP_COST"),
			xp_cost,
			gold_cost,
		]
		_detail_level_up_btn.visible = true
		_detail_level_up_btn.disabled = not GameStore.can_level_up(_selected_id)

	# Button availability — grey out if no tokens, with a tooltip so the
	# player understands why the button is unresponsive.
	var has_tokens: bool = GameStore.get_daily_tokens() > 0
	var no_tokens_tooltip: String = Localization.get_text("COMPANION_ROOM_NO_TOKENS")
	_talk_btn.disabled = not has_tokens
	_talk_btn.tooltip_text = "" if has_tokens else no_tokens_tooltip
	_gift_open_btn.disabled = not has_tokens
	_gift_open_btn.tooltip_text = "" if has_tokens else no_tokens_tooltip


## Hides the detail panel.
func _hide_detail() -> void:
	_detail_panel.visible = false
	_selected_id = ""


# ── Gift Modal ─────────────────────────────────────────────────────────────────

## Populates and shows the gift picker modal (with its dismiss backdrop).
func _show_gift_modal() -> void:
	_populate_gift_list()
	if _gift_modal_backdrop != null:
		_gift_modal_backdrop.visible = true
	_gift_modal.visible = true
	Fx.slide_in(_gift_modal, Vector2(0.0, 20.0), 0.25)


## Closes the gift modal and hides the backdrop. Shared cancel path used
## by the Cancel button, the backdrop tap, and item-selected flows.
func _hide_gift_modal() -> void:
	_gift_modal.visible = false
	if _gift_modal_backdrop != null:
		_gift_modal_backdrop.visible = false


## Tap-outside-to-close for the gift modal. Only closes on LMB press events
## so drags / motion events don't dismiss accidentally.
func _on_gift_modal_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_hide_gift_modal()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_hide_gift_modal()


## Rebuilds the gift item list buttons based on current gold.
func _populate_gift_list() -> void:
	for child: Node in _gift_list.get_children():
		child.queue_free()

	var gold: int = GameStore.get_gold()
	var items: Array[Dictionary] = GiftItems.get_items()
	for item: Dictionary in items:
		var item_id: String = item.get("id", "")
		var name_key: String = item.get("name_key", item_id)
		var cost: int = item.get("gold_cost", 0)
		var affordable: bool = GiftItems.can_afford(item_id, gold)

		var item_btn: Button = Button.new()
		item_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_btn.custom_minimum_size = Vector2(0.0, 52.0)
		item_btn.text = "%s  (%d gold)" % [Localization.get_text(name_key), cost]
		item_btn.disabled = not affordable

		if affordable:
			item_btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
		else:
			item_btn.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)

		var item_style: StyleBoxFlat = StyleBoxFlat.new()
		item_style.bg_color = UIConstants.BG_TERTIARY if affordable else UIConstants.BG_PRIMARY
		item_style.corner_radius_top_left = 6
		item_style.corner_radius_top_right = 6
		item_style.corner_radius_bottom_left = 6
		item_style.corner_radius_bottom_right = 6
		item_btn.add_theme_stylebox_override("normal", item_style)

		item_btn.pressed.connect(_on_gift_item_selected.bind(item_id))
		_gift_list.add_child(item_btn)


# ── Top Bar ────────────────────────────────────────────────────────────────────

## Refreshes token, streak, and gold display labels.
func _refresh_top_bar() -> void:
	var tokens: int = GameStore.get_daily_tokens()
	var multiplier: float = RomanceSocial.get_streak_multiplier()
	var gold: int = GameStore.get_gold()

	_token_label.text = Localization.get_text("CAMP_TOKENS_LABEL") % tokens
	_streak_label.text = "x%.1f" % multiplier
	_gold_label.text = "%d gold" % gold


# ── Feedback ───────────────────────────────────────────────────────────────────

## Shows a floating feedback string with pop animation, auto-hides after delay.
func _show_feedback(message: String) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	_feedback_label.text = message
	_feedback_label.visible = true
	_feedback_label.modulate.a = 1.0
	Fx.pop_scale(_feedback_label)

	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(FEEDBACK_HIDE_DELAY)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.3)
	_feedback_tween.tween_callback(func() -> void: _feedback_label.visible = false)


# ── Helpers ────────────────────────────────────────────────────────────────────

## Returns the portrait mood string for a RomanceSocial.Mood int value.
func _mood_id_to_portrait_mood(mood_int: int) -> String:
	match mood_int:
		0: return "neutral"
		1: return "sad"
		2: return "annoyed"
		3: return "happy"
		4: return "excited"
		_: return "neutral"


## Returns a flat StyleBoxFlat panel background with the given color.
func _make_panel_style(bg_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = UIConstants.ACCENT_GOLD_DARK
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


## Creates a themed action button with gold border style.
func _make_action_button(label_text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0.0, 52.0)
	btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	btn.add_theme_font_size_override("font_size", 16)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_TERTIARY
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = UIConstants.ACCENT_GOLD
	btn.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = UIConstants.ACCENT_GOLD_DIM
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	return btn


## Finds the TopBar HBoxContainer among direct children.
func _find_top_bar() -> HBoxContainer:
	for child: Node in get_children():
		if child is HBoxContainer and child.name == "TopBar":
			return child as HBoxContainer
	return null


# ── Signal Callbacks ───────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


func _on_companion_cell_pressed(id: String) -> void:
	_show_detail(id)


func _on_talk_pressed() -> void:
	if _selected_id.is_empty():
		return
	var result: Dictionary = RomanceSocial.do_talk(_selected_id)
	if result.get("success", false):
		var rl_gained: int = result.get("rl_gained", 0)
		_show_feedback("+%d RL" % rl_gained)
		_refresh_detail_panel()
		_refresh_top_bar()
		Fx.pulse(_detail_rl_bar)
	else:
		var error: String = result.get("error", "")
		if error == "no_tokens":
			_show_feedback(Localization.get_text("CAMP_FEEDBACK_NO_TOKENS"))
		_refresh_detail_panel()


func _on_gift_btn_pressed() -> void:
	if _selected_id.is_empty():
		return
	_show_gift_modal()


func _on_level_up_pressed() -> void:
	if _selected_id.is_empty():
		return
	if not GameStore.level_up_companion(_selected_id):
		return
	_show_feedback(Localization.get_text("CAMP_FEEDBACK_LEVEL_UP"))
	_refresh_detail_panel()
	_refresh_top_bar()
	Fx.pulse(_detail_level_label)


func _on_gift_item_selected(item_id: String) -> void:
	_hide_gift_modal()
	if _selected_id.is_empty():
		return

	var cost: int = GiftItems.get_cost(item_id)
	if cost < 0:
		return

	var gold: int = GameStore.get_gold()
	if not GiftItems.can_afford(item_id, gold):
		_show_feedback(Localization.get_text("CAMP_FEEDBACK_CANT_AFFORD"))
		return

	GameStore.spend_gold(cost)

	var result: Dictionary = RomanceSocial.do_gift(_selected_id, item_id)
	if result.get("success", false):
		var rl_gained: int = result.get("rl_gained", 0)
		var preference: String = result.get("preference", "neutral")
		var pref_display: String = preference.capitalize()
		_show_feedback("+%d RL  %s!" % [rl_gained, pref_display])
		_refresh_detail_panel()
		_refresh_top_bar()
		Fx.pulse(_detail_rl_bar)
		Fx.gold_shimmer(_detail_name_label, 1.5)
	else:
		var error: String = result.get("error", "")
		if error == "no_tokens":
			_show_feedback(Localization.get_text("CAMP_FEEDBACK_NO_TOKENS"))
		_refresh_detail_panel()


func _on_gift_modal_cancel() -> void:
	_hide_gift_modal()


func _on_state_changed(_key: String) -> void:
	_refresh_top_bar()
	if not _selected_id.is_empty() and _detail_panel.visible:
		_refresh_detail_panel()


## Disconnects persistent autoload signals on scene exit and kills any
## in-flight tweens that might otherwise animate a freed label.
func _disconnect_autoload_signals() -> void:
	if GameStore.state_changed.is_connected(_on_state_changed):
		GameStore.state_changed.disconnect(_on_state_changed)
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
