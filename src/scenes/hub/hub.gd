extends Control

## Hub screen — companion portrait, currency, bottom tabs.
##
## Reads companion display data from CompanionRegistry (autoload #7).
## Navigates to combat via SceneManager with an arrival context that
## combat.gd reads on its _ready() call via SceneManager.get_arrival_context().

# ── Node References ────────────────────────────────────────────────────────────

@onready var portrait: TextureRect = %Portrait
@onready var companion_name: Label = %CompanionName
@onready var companion_role: Label = %CompanionRole
@onready var gold_label: Label = %GoldLabel

# ── Private State ──────────────────────────────────────────────────────────────

var _breathe_tween: Tween
var _name_shimmer_tween: Tween

## Last known gold value — used to drive the count-up animation.
var _displayed_gold: int = 0

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

## Welcome popup overlay — built dynamically on first visit.
var _welcome_popup: PanelContainer

func _ready() -> void:
	_update_companion_display()
	_update_currency()
	_start_breathing_animation()

	GameStore.state_changed.connect(_on_state_changed)

	# Entrance animation: stagger all direct children from their edges.
	await get_tree().process_frame
	_animate_entrance()

	# During early game, only Story is enabled until ch01_tutorial_done.
	if not GameStore.has_flag("ch01_exposition_done"):
		_lock_tabs_for_tutorial()

	# Show welcome popup on first Hub visit (after prologue + tutorial combat).
	if GameStore.has_flag("prologue_done") and not GameStore.has_flag("hub_welcomed"):
		_show_welcome_popup()


# ── Display ────────────────────────────────────────────────────────────────────

func _update_companion_display() -> void:
	var id: String = GameStore.get_last_captain_id()
	var profile: Dictionary = CompanionRegistry.get_profile(id)

	companion_name.text = profile.get("display_name", id.capitalize())
	companion_role.text = profile.get("role", "")

	var path: String = CompanionRegistry.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(path):
		portrait.texture = load(path)


## Syncs the gold label text directly (no animation — used on first load).
func _update_currency() -> void:
	_displayed_gold = GameStore.get_gold()
	gold_label.text = str(_displayed_gold)


## Animates gold counter from old value to new value with count-up + pulse.
func _animate_gold_change(old_val: int, new_val: int) -> void:
	Fx.count_to(gold_label, old_val, new_val, 0.45)
	await get_tree().create_timer(0.45).timeout
	Fx.pulse(gold_label, 1.2, 0.35)


func _start_breathing_animation() -> void:
	_breathe_tween = create_tween().set_loops()
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.02, 1.02), 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.0, 1.0), 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Subtle gold shimmer loop on the companion name label.
func _start_name_shimmer() -> void:
	_name_shimmer_tween = Fx.gold_shimmer(companion_name, 3.0)


## Stagger all immediate Control children of the root into view from their edges.
func _animate_entrance() -> void:
	# Slide portrait + name panel from left, gold from top, tabs from bottom.
	# We use the generic stagger_children on the root — it handles layout children.
	Fx.stagger_children(self, 0.05, 30.0)
	await get_tree().create_timer(0.4).timeout
	_start_name_shimmer()


# ── Tutorial Lock ──────────────────────────────────────────────────────────────

## Disables all Hub tab buttons except STORY during the first-time tutorial.
func _lock_tabs_for_tutorial() -> void:
	var bottom_tabs: Node = get_node_or_null("BottomTabs")
	var more_tabs: Node = get_node_or_null("MoreTabs")
	if bottom_tabs != null:
		for child: Node in bottom_tabs.get_children():
			if child is Button and child.name != "StoryBtn":
				(child as Button).disabled = true
				(child as Button).modulate.a = 0.35
	if more_tabs != null:
		for child: Node in more_tabs.get_children():
			if child is Button:
				(child as Button).disabled = true
				(child as Button).modulate.a = 0.35


## Re-enables all Hub tab buttons after the tutorial welcome is dismissed.
func _unlock_tabs() -> void:
	var bottom_tabs: Node = get_node_or_null("BottomTabs")
	var more_tabs: Node = get_node_or_null("MoreTabs")
	if bottom_tabs != null:
		for child: Node in bottom_tabs.get_children():
			if child is Button:
				(child as Button).disabled = false
				(child as Button).modulate.a = 1.0
	if more_tabs != null:
		for child: Node in more_tabs.get_children():
			if child is Button:
				(child as Button).disabled = false
				(child as Button).modulate.a = 1.0


# ── Welcome Popup ──────────────────────────────────────────────────────────────

## Builds and shows a one-time welcome popup guiding the player to tap Story.
func _show_welcome_popup() -> void:
	# Semi-transparent backdrop to dim the hub.
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "WelcomeBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	add_child(backdrop)

	# Center the popup using anchors at 50%/50% with symmetric offsets.
	_welcome_popup = PanelContainer.new()
	_welcome_popup.anchor_left = 0.5
	_welcome_popup.anchor_right = 0.5
	_welcome_popup.anchor_top = 0.5
	_welcome_popup.anchor_bottom = 0.5
	_welcome_popup.offset_left = -170.0
	_welcome_popup.offset_right = 170.0
	_welcome_popup.offset_top = -140.0
	_welcome_popup.offset_bottom = 140.0
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = UIConstants.BG_SECONDARY
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = UIConstants.ACCENT_GOLD
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	_welcome_popup.add_theme_stylebox_override("panel", panel_style)
	add_child(_welcome_popup)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_welcome_popup.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.text = Localization.get_text("HUB_WELCOME_TITLE")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title_lbl)

	var body_lbl: Label = Label.new()
	body_lbl.text = Localization.get_text("HUB_WELCOME_TEXT")
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	body_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(body_lbl)

	var ok_btn: Button = Button.new()
	ok_btn.text = Localization.get_text("HUB_WELCOME_OK")
	ok_btn.custom_minimum_size = Vector2(0.0, 52.0)
	ok_btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	ok_btn.add_theme_font_size_override("font_size", 16)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = UIConstants.BG_TERTIARY
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = UIConstants.ACCENT_GOLD
	ok_btn.add_theme_stylebox_override("normal", btn_style)
	ok_btn.pressed.connect(func() -> void:
		GameStore.set_flag("hub_welcomed")
		backdrop.queue_free()
		_welcome_popup.queue_free()
	)
	vbox.add_child(ok_btn)

	# Slide-in animation.
	Fx.slide_in(_welcome_popup, Vector2(0.0, 40.0), 0.35)
	Fx.gold_shimmer(title_lbl, 2.5)


# ── Signal Callbacks ────────────────────────────────────────────────────────────

func _on_state_changed(_key: String = "") -> void:
	var new_gold: int = GameStore.get_gold()
	if new_gold != _displayed_gold:
		var old: int = _displayed_gold
		_displayed_gold = new_gold
		_animate_gold_change(old, new_gold)


# ── Tab Buttons ────────────────────────────────────────────────────────────────

func _on_story_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.CHAPTER_MAP)


func _on_camp_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.COMPANION_ROOM)


func _on_deck_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.DECK)


func _on_explore_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.EXPLORATION)


func _on_abyss_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.ABYSS)


func _on_equipment_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.EQUIPMENT)


func _on_gallery_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.GALLERY)


func _on_achievements_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.ACHIEVEMENTS)


func _on_arena_pressed() -> void:
	# Pass enemy config to combat.gd via arrival context.
	# combat.gd reads SceneManager.get_arrival_context() in _ready() and builds
	# the enemy + deck from EnemyRegistry using the id provided here.
	# TODO: replace "arena_challenger" with a real EnemyRegistry id when the
	#       enemy data file is populated (Balance values not yet ported).
	var context: Dictionary = {
		"enemy_id": "arena_challenger",
		"captain_id": GameStore.get_last_captain_id(),
	}
	SceneManager.change_scene(
		SceneManager.SceneId.COMBAT,
		SceneManager.TransitionType.FADE,
		context
	)


func _on_settings_pressed() -> void:
	SceneManager.open_settings_overlay()
