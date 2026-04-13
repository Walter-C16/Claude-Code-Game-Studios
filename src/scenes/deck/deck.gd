extends Control

## Deck — Companion grid (browse) + detail view (assign to deck / captain).
##
## Flow:
##   Grid view: 2-column grid of met companions, each showing their card value.
##   Tap a companion → detail view: full portrait, stats, blessings, action buttons.
##   Use in Deck: assigns companion's signature card to the deck.
##     If another companion already occupies the same (element, card_value) slot,
##     a confirm popup asks to replace.
##   Assign Captain: sets this companion as the captain.
##     If another captain exists, confirm popup asks to replace.

# ── Constants ─────────────────────────────────────────────────────────────────

const VIEW_GRID: int = 0
const VIEW_DETAIL: int = 1

# ── Node References ────────────────────────────────────────────────────────────

@onready var title_label: Label = %TitleLabel
@onready var deck_size_label: Label = %DeckSizeLabel
@onready var back_btn: Button = %BackBtn

# ── Private State ──────────────────────────────────────────────────────────────

var _view_state: int = VIEW_GRID
var _selected_id: String = ""
var _grid_container: GridContainer
var _detail_root: Control
var _detail_portrait: TextureRect
var _detail_name_label: Label
var _detail_role_label: Label
var _detail_stats_label: Label
var _detail_blessings_container: VBoxContainer
var _use_in_deck_btn: Button
var _assign_captain_btn: Button
var _scroll: ScrollContainer
var _active_popup: PanelContainer

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	title_label.text = "MY DECK"
	_clear_tscn_placeholder()
	_build_grid_view()
	_build_detail_view()
	_build_bottom_action_bar()
	_show_grid_view()


func _on_back_pressed() -> void:
	if _active_popup != null:
		_close_popup()
		return
	if _view_state == VIEW_DETAIL:
		_show_grid_view()
		return
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── Tscn Cleanup ───────────────────────────────────────────────────────────────

## Removes the placeholder nodes the .tscn ships with so we can rebuild
## cleanly in code (both grid and detail views are built dynamically).
func _clear_tscn_placeholder() -> void:
	var placeholder_scroll: Node = get_node_or_null("ScrollContainer")
	if placeholder_scroll != null:
		placeholder_scroll.queue_free()


# ── Grid View ──────────────────────────────────────────────────────────────────

func _build_grid_view() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "GridScroll"
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 64.0
	_scroll.offset_bottom = -120.0  # leave room for bottom action bar
	_scroll.offset_left = 12.0
	_scroll.offset_right = -12.0
	add_child(_scroll)

	_grid_container = GridContainer.new()
	_grid_container.columns = 2
	_grid_container.add_theme_constant_override("h_separation", 12)
	_grid_container.add_theme_constant_override("v_separation", 12)
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid_container)


## Rebuilds the companion grid from met companions.
func _populate_grid() -> void:
	for child: Node in _grid_container.get_children():
		child.queue_free()

	var ids: Array[String] = CompanionRegistry.get_all_ids()
	for id: String in ids:
		var state: Dictionary = GameStore.get_companion_state(id)
		if not state.get("met", false):
			continue
		# Skip non-combatant NPCs (priestess has no card_value).
		var profile: Dictionary = CompanionRegistry.get_profile(id)
		var card_value: int = int(profile.get("card_value", 0))
		if card_value <= 0:
			continue
		_grid_container.add_child(_make_companion_cell(id, profile))


func _make_companion_cell(id: String, profile: Dictionary) -> Control:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 180.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.flat = true
	btn.pressed.connect(_on_companion_selected.bind(id))

	# Card background with gold border.
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = UIConstants.ACCENT_GOLD if GameStore.has_deck_companion(id) else UIConstants.ACCENT_GOLD_DARK
	btn.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.border_color = UIConstants.ACCENT_GOLD_BRIGHT
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_right = -8.0
	vbox.offset_top = 8.0
	vbox.offset_bottom = 8.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Portrait.
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(110.0, 110.0)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_path: String = CompanionRegistry.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	vbox.add_child(portrait)

	# Name.
	var name_label: Label = Label.new()
	name_label.text = profile.get("display_name", id.capitalize())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# Card value badge — bottom-right overlay on the cell.
	var value_label: Label = Label.new()
	value_label.text = _card_value_name(int(profile.get("card_value", 0)))
	value_label.add_theme_color_override("font_color", _element_color(profile.get("element", "") as String))
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.anchor_left = 1.0
	value_label.anchor_right = 1.0
	value_label.anchor_top = 1.0
	value_label.anchor_bottom = 1.0
	value_label.offset_left = -32.0
	value_label.offset_top = -30.0
	value_label.offset_right = -8.0
	value_label.offset_bottom = -6.0
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(value_label)

	# Captain indicator (gold crown) — top-right overlay.
	if GameStore.get_last_captain_id() == id:
		var crown: Label = Label.new()
		crown.text = "★"
		crown.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
		crown.add_theme_font_size_override("font_size", 20)
		crown.anchor_left = 1.0
		crown.anchor_right = 1.0
		crown.offset_left = -26.0
		crown.offset_top = 4.0
		crown.offset_right = -6.0
		crown.offset_bottom = 24.0
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(crown)

	return btn


func _show_grid_view() -> void:
	_view_state = VIEW_GRID
	_selected_id = ""
	_scroll.visible = true
	_detail_root.visible = false
	_use_in_deck_btn.visible = false
	_assign_captain_btn.visible = false
	_populate_grid()
	deck_size_label.text = "%d/%d in deck" % [GameStore.get_deck_companions().size(), _combatant_count()]
	await get_tree().process_frame
	Fx.stagger_children(_grid_container, 0.05, 20.0)


# ── Detail View ───────────────────────────────────────────────────────────────

func _build_detail_view() -> void:
	_detail_root = Control.new()
	_detail_root.name = "DetailRoot"
	_detail_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_root.offset_top = 64.0
	_detail_root.offset_bottom = -120.0
	_detail_root.offset_left = 12.0
	_detail_root.offset_right = -12.0
	_detail_root.visible = false
	add_child(_detail_root)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_root.add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Full portrait.
	_detail_portrait = TextureRect.new()
	_detail_portrait.custom_minimum_size = Vector2(0.0, 280.0)
	_detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_detail_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	vbox.add_child(_detail_portrait)

	# Name + role.
	_detail_name_label = Label.new()
	_detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	_detail_name_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_detail_name_label)

	_detail_role_label = Label.new()
	_detail_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_role_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_detail_role_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_detail_role_label)

	# Stats.
	_detail_stats_label = Label.new()
	_detail_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_stats_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_detail_stats_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_detail_stats_label)

	# Blessings header.
	var bless_header: Label = Label.new()
	bless_header.text = "Divine Blessings"
	bless_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bless_header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	bless_header.add_theme_font_size_override("font_size", 16)
	bless_header.custom_minimum_size = Vector2(0.0, 32.0)
	vbox.add_child(bless_header)

	_detail_blessings_container = VBoxContainer.new()
	_detail_blessings_container.add_theme_constant_override("separation", 6)
	_detail_blessings_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_detail_blessings_container)


func _show_detail_view(id: String) -> void:
	_view_state = VIEW_DETAIL
	_selected_id = id
	_scroll.visible = false
	_detail_root.visible = true
	_use_in_deck_btn.visible = true
	_assign_captain_btn.visible = true

	var profile: Dictionary = CompanionRegistry.get_profile(id)
	var portrait_path: String = CompanionRegistry.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(portrait_path):
		_detail_portrait.texture = load(portrait_path)
	else:
		_detail_portrait.texture = null

	_detail_name_label.text = profile.get("display_name", id.capitalize())
	_detail_role_label.text = profile.get("role", "")
	var element: String = profile.get("element", "") as String
	var card_value: int = int(profile.get("card_value", 0))
	_detail_stats_label.text = "%s  %s | STR %d  INT %d  AGI %d" % [
		_card_value_name(card_value), element,
		int(profile.get("STR", 0)),
		int(profile.get("INT", 0)),
		int(profile.get("AGI", 0)),
	]

	_populate_blessings_list(id)
	_update_action_buttons_for(id)

	Fx.slide_in(_detail_root, Vector2(0.0, 30.0), 0.3)


func _populate_blessings_list(id: String) -> void:
	for child: Node in _detail_blessings_container.get_children():
		child.queue_free()

	var blessings: Array[Dictionary] = BlessingSystem.get_blessing_info(id)
	if blessings.is_empty():
		var none: Label = Label.new()
		none.text = "(no blessings available)"
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		_detail_blessings_container.add_child(none)
		return

	var current_stage: int = CompanionState.get_romance_stage(id)
	for b: Dictionary in blessings:
		_detail_blessings_container.add_child(_make_blessing_row(b, current_stage))


func _make_blessing_row(blessing: Dictionary, current_stage: int) -> PanelContainer:
	var slot: int = int(blessing.get("slot", 0))
	var stage_required: int = int(blessing.get("stage", 0))
	var unlocked: bool = current_stage >= stage_required
	var name_key: String = blessing.get("name_key", "") as String
	var desc_key: String = blessing.get("description_key", "") as String

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_TERTIARY if unlocked else UIConstants.BG_PRIMARY
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = UIConstants.ACCENT_GOLD if unlocked else UIConstants.TEXT_DISABLED
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)

	var row_vbox: VBoxContainer = VBoxContainer.new()
	row_vbox.add_theme_constant_override("separation", 2)
	panel.add_child(row_vbox)

	var title: Label = Label.new()
	var slot_tag: String = "Slot %d" % slot
	var title_text: String = "[%s] %s" % [slot_tag, Localization.get_text(name_key) if not name_key.is_empty() else "Blessing %d" % slot]
	title.text = title_text
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD if unlocked else UIConstants.TEXT_DISABLED)
	title.add_theme_font_size_override("font_size", 13)
	row_vbox.add_child(title)

	if not desc_key.is_empty():
		var desc: Label = Label.new()
		desc.text = Localization.get_text(desc_key)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY if unlocked else UIConstants.TEXT_DISABLED)
		desc.add_theme_font_size_override("font_size", 11)
		row_vbox.add_child(desc)

	if not unlocked:
		var lock: Label = Label.new()
		lock.text = "Unlocks at Stage %d" % stage_required
		lock.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		lock.add_theme_font_size_override("font_size", 10)
		row_vbox.add_child(lock)

	return panel


# ── Bottom Action Bar (Absolute Position) ─────────────────────────────────────

func _build_bottom_action_bar() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -104.0
	bar.offset_bottom = -12.0
	bar.offset_left = 12.0
	bar.offset_right = -12.0
	bar.add_theme_constant_override("separation", 10)
	add_child(bar)

	_use_in_deck_btn = _make_action_button("Use in Deck")
	_use_in_deck_btn.pressed.connect(_on_use_in_deck_pressed)
	bar.add_child(_use_in_deck_btn)

	_assign_captain_btn = _make_action_button("Assign Captain")
	_assign_captain_btn.pressed.connect(_on_assign_captain_pressed)
	bar.add_child(_assign_captain_btn)

	# Hidden until a companion is selected.
	_use_in_deck_btn.visible = false
	_assign_captain_btn.visible = false


func _make_action_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 56.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	btn.add_theme_font_size_override("font_size", 15)
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
	style.border_color = UIConstants.ACCENT_GOLD
	btn.add_theme_stylebox_override("normal", style)
	return btn


func _update_action_buttons_for(id: String) -> void:
	var in_deck: bool = GameStore.has_deck_companion(id)
	var is_captain: bool = GameStore.get_last_captain_id() == id
	_use_in_deck_btn.text = "Remove from Deck" if in_deck else "Use in Deck"
	_assign_captain_btn.text = "✓ Captain" if is_captain else "Assign Captain"
	_assign_captain_btn.disabled = is_captain


# ── Actions ────────────────────────────────────────────────────────────────────

func _on_companion_selected(id: String) -> void:
	_show_detail_view(id)


func _on_use_in_deck_pressed() -> void:
	if _selected_id.is_empty():
		return

	# Toggle off if already in deck.
	if GameStore.has_deck_companion(_selected_id):
		GameStore.remove_deck_companion(_selected_id)
		_update_action_buttons_for(_selected_id)
		return

	# Check for slot conflict: same (element, card_value) already assigned?
	var conflict_id: String = _find_slot_conflict(_selected_id)
	if not conflict_id.is_empty():
		_show_replace_popup(
			"Deck Slot Taken",
			"%s already uses this card slot. Replace with %s?" % [
				CompanionRegistry.get_profile(conflict_id).get("display_name", conflict_id),
				CompanionRegistry.get_profile(_selected_id).get("display_name", _selected_id),
			],
			func() -> void:
				GameStore.remove_deck_companion(conflict_id)
				GameStore.add_deck_companion(_selected_id)
				_update_action_buttons_for(_selected_id)
		)
		return

	# No conflict — just add.
	GameStore.add_deck_companion(_selected_id)
	_update_action_buttons_for(_selected_id)
	Fx.pop_scale(_use_in_deck_btn)


func _on_assign_captain_pressed() -> void:
	if _selected_id.is_empty():
		return

	var current_captain: String = GameStore.get_last_captain_id()
	if current_captain == _selected_id:
		return  # already captain

	if current_captain.is_empty():
		GameStore.set_last_captain_id(_selected_id)
		_update_action_buttons_for(_selected_id)
		Fx.pop_scale(_assign_captain_btn)
		return

	var captain_name: String = CompanionRegistry.get_profile(current_captain).get("display_name", current_captain)
	_show_replace_popup(
		"Replace Captain",
		"%s is already your captain. Replace with %s?" % [
			captain_name,
			CompanionRegistry.get_profile(_selected_id).get("display_name", _selected_id),
		],
		func() -> void:
			GameStore.set_last_captain_id(_selected_id)
			_update_action_buttons_for(_selected_id)
	)


# ── Slot Conflict Check ────────────────────────────────────────────────────────

## Returns the id of a deck companion that occupies the same (element, card_value)
## slot as [param candidate_id], or empty string if the slot is free.
func _find_slot_conflict(candidate_id: String) -> String:
	var candidate: Dictionary = CompanionRegistry.get_profile(candidate_id)
	var target_element: String = candidate.get("element", "") as String
	var target_value: int = int(candidate.get("card_value", 0))
	for id: String in GameStore.get_deck_companions():
		if id == candidate_id:
			continue
		var other: Dictionary = CompanionRegistry.get_profile(id)
		var other_element: String = other.get("element", "") as String
		var other_value: int = int(other.get("card_value", 0))
		if other_element == target_element and other_value == target_value:
			return id
	return ""


# ── Replace Popup ──────────────────────────────────────────────────────────────

## Shows a confirm popup with the given title/body, calling on_confirm if the
## player accepts. The popup captures input so the underlying view is locked.
func _show_replace_popup(popup_title: String, body: String, on_confirm: Callable) -> void:
	_close_popup()

	# Dim backdrop that eats input.
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "PopupBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_active_popup = PanelContainer.new()
	_active_popup.anchor_left = 0.5
	_active_popup.anchor_right = 0.5
	_active_popup.anchor_top = 0.5
	_active_popup.anchor_bottom = 0.5
	_active_popup.offset_left = -170.0
	_active_popup.offset_right = 170.0
	_active_popup.offset_top = -120.0
	_active_popup.offset_bottom = 120.0
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
	style.border_color = UIConstants.ACCENT_GOLD
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	_active_popup.add_theme_stylebox_override("panel", style)
	add_child(_active_popup)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_active_popup.add_child(vbox)

	var title: Label = Label.new()
	title.text = popup_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var body_label: Label = Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	body_label.add_theme_font_size_override("font_size", 14)
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_label)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var cancel_btn: Button = _make_action_button("Cancel")
	cancel_btn.pressed.connect(_close_popup)
	btn_row.add_child(cancel_btn)

	var confirm_btn: Button = _make_action_button("Replace")
	confirm_btn.pressed.connect(func() -> void:
		on_confirm.call()
		_close_popup()
	)
	btn_row.add_child(confirm_btn)

	Fx.slide_in(_active_popup, Vector2(0.0, 20.0), 0.25)


func _close_popup() -> void:
	if _active_popup == null:
		return
	var backdrop: Node = get_node_or_null("PopupBackdrop")
	if backdrop != null:
		backdrop.queue_free()
	_active_popup.queue_free()
	_active_popup = null


# ── Helpers ────────────────────────────────────────────────────────────────────

func _card_value_name(value: int) -> String:
	match value:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(value)


func _element_color(element: String) -> Color:
	match element:
		"Fire": return UIConstants.ELEM_FIRE_FG
		"Water": return UIConstants.ELEM_WATER_FG
		"Earth": return UIConstants.ELEM_EARTH_FG
		"Lightning": return UIConstants.ELEM_LIGHTNING_FG
		_: return UIConstants.TEXT_SECONDARY


## Count of companions with a valid combat card_value (excludes priestess).
func _combatant_count() -> int:
	var n: int = 0
	for id: String in CompanionRegistry.get_all_ids():
		var profile: Dictionary = CompanionRegistry.get_profile(id)
		if int(profile.get("card_value", 0)) > 0:
			n += 1
	return n
