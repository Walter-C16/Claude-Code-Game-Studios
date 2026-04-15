extends Control

## Party — Companion grid (browse) + detail view (add / remove from party).
##
## Flow:
##   Grid view: 2-column grid of met companions, each showing a party slot
##   number (P1, P2, P3) if they're in the active party.
##   Tap a companion → detail view: full portrait, stats, blessings, and a
##   single action button (Add to Party / Remove from Party).
##   Party cap: 3 companions (plus the protagonist who is always in slot 0
##   during battle). Trying to add when the party is full prompts to replace.
##
## The file is still named "deck" for backward compat with the scene id and
## existing saves; the player-facing label is "MY PARTY" and the data is
## stored in GameStore._deck_companions.

# ── Constants ─────────────────────────────────────────────────────────────────

const VIEW_GRID: int = 0
const VIEW_DETAIL: int = 1

## Maximum companions in the active party. The protagonist is implicit and
## always occupies slot 0 — these 3 slots cover the other battle positions.
const MAX_PARTY_SIZE: int = 3

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
var _party_action_btn: Button
var _scroll: ScrollContainer
var _active_popup: PanelContainer

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	title_label.text = Localization.get_text("PARTY_TITLE")
	_clear_tscn_placeholder()
	_build_grid_view()
	_build_detail_view()
	_build_bottom_action_bar()
	_show_grid_view()
	TutorialOverlay.show_once(self,
		"tutorial_deck_shown",
		"TUTORIAL_DECK_TITLE",
		"TUTORIAL_DECK_BODY")


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

	# Element badge — bottom-right overlay on the cell (replaces card value).
	var element_label: Label = Label.new()
	element_label.text = profile.get("element", "") as String
	element_label.add_theme_color_override("font_color", _element_color(profile.get("element", "") as String))
	element_label.add_theme_font_size_override("font_size", 12)
	element_label.anchor_left = 1.0
	element_label.anchor_right = 1.0
	element_label.anchor_top = 1.0
	element_label.anchor_bottom = 1.0
	element_label.offset_left = -60.0
	element_label.offset_top = -22.0
	element_label.offset_right = -6.0
	element_label.offset_bottom = -4.0
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	element_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(element_label)

	# Party slot indicator — top-right overlay shows P1/P2/P3 when in party.
	var party_slot: int = _party_slot_of(id)
	if party_slot > 0:
		var slot_label: Label = Label.new()
		slot_label.text = "P%d" % party_slot
		slot_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
		slot_label.add_theme_font_size_override("font_size", 18)
		slot_label.anchor_left = 1.0
		slot_label.anchor_right = 1.0
		slot_label.offset_left = -34.0
		slot_label.offset_top = 4.0
		slot_label.offset_right = -6.0
		slot_label.offset_bottom = 28.0
		slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(slot_label)

	return btn


## Returns the 1-based party slot index (1, 2, or 3) for the given companion,
## or 0 if they're not in the party. The slot number reflects insertion order
## in GameStore.get_deck_companions().
func _party_slot_of(companion_id: String) -> int:
	var members: Array[String] = GameStore.get_deck_companions()
	for i: int in range(members.size()):
		if members[i] == companion_id:
			return i + 1
	return 0


func _show_grid_view() -> void:
	_view_state = VIEW_GRID
	_selected_id = ""
	_scroll.visible = true
	_detail_root.visible = false
	_party_action_btn.visible = false
	_populate_grid()
	deck_size_label.text = "%d/%d %s" % [
		GameStore.get_deck_companions().size(),
		MAX_PARTY_SIZE,
		Localization.get_text("PARTY_IN_PARTY_SUFFIX"),
	]
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
	_party_action_btn.visible = true

	var profile: Dictionary = CompanionRegistry.get_profile(id)
	var portrait_path: String = CompanionRegistry.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(portrait_path):
		_detail_portrait.texture = load(portrait_path)
	else:
		_detail_portrait.texture = null

	_detail_name_label.text = profile.get("display_name", id.capitalize())
	_detail_role_label.text = profile.get("role", "")
	var element: String = profile.get("element", "") as String
	var battle_row: Dictionary = _battle_stats_for(id)
	if not battle_row.is_empty():
		_detail_stats_label.text = "%s | HP %d  ATK %d  DEF %d  AGI %d  CRIT %d%%" % [
			element,
			int(battle_row.get("hp", 0)),
			int(battle_row.get("atk", 0)),
			int(battle_row.get("def", 0)),
			int(battle_row.get("agi", 0)),
			int(battle_row.get("crit_chance", 0)),
		]
	else:
		_detail_stats_label.text = element

	_populate_blessings_list(id)
	_update_action_buttons_for(id)

	Fx.slide_in(_detail_root, Vector2(0.0, 30.0), 0.3)


## Loads the battle-stats row for [param companion_id] from the JSON file.
## Returns empty dict if the id is not in the characters section.
func _battle_stats_for(companion_id: String) -> Dictionary:
	var data: Dictionary = JsonLoader.load_dict("res://assets/data/character_battle_stats.json")
	var chars: Dictionary = data.get("characters", {}) as Dictionary
	return chars.get(companion_id, {}) as Dictionary


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
	bar.offset_top = -76.0
	bar.offset_bottom = -12.0
	bar.offset_left = 12.0
	bar.offset_right = -12.0
	bar.add_theme_constant_override("separation", 10)
	add_child(bar)

	_party_action_btn = _make_action_button(Localization.get_text("PARTY_ADD_BTN"))
	_party_action_btn.pressed.connect(_on_party_action_pressed)
	bar.add_child(_party_action_btn)

	# Hidden until a companion is selected.
	_party_action_btn.visible = false


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
	var in_party: bool = GameStore.has_deck_companion(id)
	if in_party:
		_party_action_btn.text = Localization.get_text("PARTY_REMOVE_BTN")
	else:
		_party_action_btn.text = Localization.get_text("PARTY_ADD_BTN")


# ── Actions ────────────────────────────────────────────────────────────────────

func _on_companion_selected(id: String) -> void:
	_show_detail_view(id)


## Single entry point for the Add/Remove party action.
## Toggles the selected companion in or out of the party. If adding and the
## party is already at MAX_PARTY_SIZE, shows a picker popup so the player
## can choose which member to replace.
func _on_party_action_pressed() -> void:
	if _selected_id.is_empty():
		return

	# Already in party → remove.
	if GameStore.has_deck_companion(_selected_id):
		GameStore.remove_deck_companion(_selected_id)
		_sync_captain_with_party()
		_update_action_buttons_for(_selected_id)
		_populate_grid()
		return

	# Not in party — add if there's room.
	var members: Array[String] = GameStore.get_deck_companions()
	var profile: Dictionary = CompanionRegistry.get_profile(_selected_id)
	var card_value: int = int(profile.get("card_value", 0))

	if members.size() < MAX_PARTY_SIZE:
		GameStore.add_deck_companion(_selected_id, card_value)
		_sync_captain_with_party()
		_update_action_buttons_for(_selected_id)
		_populate_grid()
		Fx.pop_scale(_party_action_btn)
		return

	# Full party — prompt which member to replace.
	_show_replace_party_picker(profile.get("display_name", _selected_id))


## Shows a popup listing current party members so the player picks who to
## kick out when adding a new companion to a full party.
func _show_replace_party_picker(incoming_name: String) -> void:
	_close_popup()

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
	_active_popup.offset_top = -180.0
	_active_popup.offset_bottom = 180.0
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
	vbox.add_theme_constant_override("separation", 10)
	_active_popup.add_child(vbox)

	var title: Label = Label.new()
	title.text = Localization.get_text("PARTY_FULL_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var body: Label = Label.new()
	body.text = Localization.get_text("PARTY_FULL_BODY") % incoming_name
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	body.add_theme_font_size_override("font_size", 13)
	vbox.add_child(body)

	# One button per current party member.
	for cid: String in GameStore.get_deck_companions():
		var name: String = CompanionRegistry.get_profile(cid).get("display_name", cid) as String
		var btn: Button = _make_action_button(name)
		var captured: String = cid
		btn.pressed.connect(func() -> void:
			var incoming_profile: Dictionary = CompanionRegistry.get_profile(_selected_id)
			var incoming_value: int = int(incoming_profile.get("card_value", 0))
			GameStore.remove_deck_companion(captured)
			GameStore.add_deck_companion(_selected_id, incoming_value)
			_sync_captain_with_party()
			_update_action_buttons_for(_selected_id)
			_populate_grid()
			_close_popup()
		)
		vbox.add_child(btn)

	var cancel_btn: Button = _make_action_button(Localization.get_text("PARTY_CANCEL_BTN"))
	cancel_btn.pressed.connect(_close_popup)
	vbox.add_child(cancel_btn)

	Fx.slide_in(_active_popup, Vector2(0.0, 20.0), 0.25)


## Backward-compat bridge for the old poker combat (tavern tournaments):
## they still read GameStore.get_last_captain_id() to compute STR/INT bonuses.
## We auto-sync the captain slot to the first party member so players never
## have to manage two concepts.
func _sync_captain_with_party() -> void:
	var members: Array[String] = GameStore.get_deck_companions()
	if members.is_empty():
		if not GameStore.get_last_captain_id().is_empty():
			GameStore.set_last_captain_id("")
	else:
		GameStore.set_last_captain_id(members[0])


# ── Popup Cleanup ─────────────────────────────────────────────────────────────

func _close_popup() -> void:
	if _active_popup == null:
		return
	var backdrop: Node = get_node_or_null("PopupBackdrop")
	if backdrop != null:
		backdrop.queue_free()
	_active_popup.queue_free()
	_active_popup = null


# ── Helpers ────────────────────────────────────────────────────────────────────

func _element_color(element: String) -> Color:
	match element:
		"Fire": return UIConstants.ELEM_FIRE_FG
		"Water": return UIConstants.ELEM_WATER_FG
		"Earth": return UIConstants.ELEM_EARTH_FG
		"Lightning": return UIConstants.ELEM_LIGHTNING_FG
		_: return UIConstants.TEXT_SECONDARY
