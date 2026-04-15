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

## Looping pulse on the Story button, shown after the welcome popup so the
## player knows exactly which tab to tap first. Killed on scene exit or when
## the player taps Story.
var _story_highlight_tween: Tween

## Last known gold value — used to drive the count-up animation.
var _displayed_gold: int = 0

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

## Welcome popup overlay — built dynamically on first visit.
var _welcome_popup: PanelContainer

func _ready() -> void:
	_update_companion_display()
	_update_currency()
	_start_breathing_animation()

	AudioManager.play_bgm("res://assets/audio/bgm/camp.ogg")
	GameStore.state_changed.connect(_on_state_changed)
	tree_exiting.connect(_disconnect_autoload_signals)

	# Inject Oracle + Forge placeholder buttons into MoreTabs before the
	# progressive unlock pass runs so they participate in the same gating.
	_install_gacha_placeholders()

	# Entrance animation: stagger all direct children from their edges.
	await get_tree().process_frame
	_animate_entrance()

	# Progressive tab unlock based on story progress.
	_apply_progressive_unlock()

	# Show welcome popup on first Hub visit (after prologue + tutorial combat).
	if GameStore.has_flag("prologue_done") and not GameStore.has_flag("hub_welcomed"):
		_show_welcome_popup()

	# Show "Artemis joins your party" gacha splash once — after the player
	# wakes up in her house (ch01_exposition_done) and returns to the Hub.
	elif GameStore.has_flag("ch01_exposition_done") and not GameStore.has_flag("artemis_join_shown"):
		call_deferred("_show_companion_join_splash", "artemis")
	# Otherwise show the Hub tutorial once (after the welcome flow has run).
	elif GameStore.has_flag("hub_welcomed"):
		call_deferred("_show_hub_tutorial")


## Shows the Hub tutorial overlay once.
func _show_hub_tutorial() -> void:
	TutorialOverlay.show_once(self,
		"tutorial_hub_shown",
		"TUTORIAL_HUB_TITLE",
		"TUTORIAL_HUB_BODY")


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


# ── Progressive Tab Unlock ─────────────────────────────────────────────────────

## Unlocks hub tabs progressively based on story flags.
## Tier 0 (start, pre-Artemis-house): Only STORY + SETTINGS
## Tier 1 (ch01_exposition_done — woke up in Artemis's house):
##          + CAMP, DECK (gacha splash triggers this tier)
## Tier 2 (ch01_tavern_done — after the first tavern scene):
##          + ARENA button (rebranded to TAVERN for the tournament map)
## Tier 3 (ch01_complete): + EXPLORE, EQUIP, ABYSS
func _apply_progressive_unlock() -> void:
	var has_expo: bool = GameStore.has_flag("ch01_exposition_done")
	var has_tavern: bool = GameStore.has_flag("ch01_tavern_done")
	var has_ch1: bool = GameStore.has_flag("ch01_complete")

	# Map button names to their unlock tier.
	var unlock_map: Dictionary = {
		"StoryBtn": 0,
		"SettingsBtn": 0,
		"CampBtn": 1,
		"DeckBtn": 1,
		"ArenaBtn": 2,
		"ExploreBtn": 3,
		"AbyssBtn": 3,
		"EquipBtn": 3,
		"OracleBtn": 3,
		"ForgeBtn": 3,
	}

	# Names of buttons that exist purely as visual placeholders for systems
	# that aren't implemented yet. They reach tier 3 (so they appear once the
	# player is far enough into the story) but stay disabled regardless.
	var placeholder_buttons: Array[String] = ["OracleBtn", "ForgeBtn"]

	# Current player tier.
	var tier: int = 0
	if has_ch1:
		tier = 3
	elif has_tavern:
		tier = 2
	elif has_expo:
		tier = 1

	# Rename Arena → Tavern once tier 2 is reached.
	var arena_btn: Node = get_node_or_null("BottomTabs/ArenaBtn")
	if arena_btn is Button:
		(arena_btn as Button).text = "TAVERN" if tier >= 2 else "ARENA"

	var bottom_tabs: Node = get_node_or_null("BottomTabs")
	var more_tabs: Node = get_node_or_null("MoreTabs")

	for tab_parent: Node in [bottom_tabs, more_tabs]:
		if tab_parent == null:
			continue
		for child: Node in tab_parent.get_children():
			if child is Button:
				var btn: Button = child as Button
				var required: int = unlock_map.get(btn.name, 99)
				var is_placeholder: bool = btn.name in placeholder_buttons
				if tier >= required:
					# Placeholder buttons stay disabled so the player sees the
					# slot but can't interact — implementation lands in v2.
					btn.disabled = is_placeholder
					btn.modulate.a = 0.55 if is_placeholder else 1.0
				else:
					btn.disabled = true
					btn.modulate.a = 0.35


# ── Gacha placeholder buttons ────────────────────────────────────────────────

## Adds Oracle + Forge buttons to MoreTabs as visual placeholders. The actual
## gacha systems (see `design/quick-specs/oracle-gacha.md` and
## `design/quick-specs/forge-gacha.md`) ship in v2 — these buttons reserve the
## navigation slots and signal "more is coming" without doing anything yet.
## They participate in the progressive unlock pass via the `placeholder_buttons`
## set in `_apply_progressive_unlock`.
func _install_gacha_placeholders() -> void:
	var more_tabs: Node = get_node_or_null("MoreTabs")
	if more_tabs == null:
		return
	# Idempotent — bail out if a previous _ready already added them.
	if more_tabs.get_node_or_null("OracleBtn") != null:
		return

	var oracle_btn: Button = _make_placeholder_tab_button(
		"OracleBtn", Localization.get_text("HUB_TAB_ORACLE")
	)
	var forge_btn: Button = _make_placeholder_tab_button(
		"ForgeBtn", Localization.get_text("HUB_TAB_FORGE")
	)
	more_tabs.add_child(oracle_btn)
	more_tabs.add_child(forge_btn)


## Builds a single MoreTabs button matching the look of the existing tabs.
func _make_placeholder_tab_button(node_name: String, label_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = node_name
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 52.0)
	btn.add_theme_color_override("font_color", Color(0.667, 0.533, 0.333, 1.0))
	btn.add_theme_font_size_override("font_size", 12)
	btn.tooltip_text = Localization.get_text("HUB_TAB_COMING_SOON")
	# Buttons start disabled; the unlock pass keeps them disabled because they
	# are listed in `placeholder_buttons`. Setting it here means even an
	# uninitialized state shows the disabled style on first frame.
	btn.disabled = true
	return btn


# ── Companion Join Splash (Gacha-style) ───────────────────────────────────────

## Shows a one-time fullscreen reveal when a major companion joins the party.
## Sets a {id}_join_shown flag so it never replays. Animates the portrait
## with a gold flash and a spring scale.
func _show_companion_join_splash(companion_id: String) -> void:
	var profile: Dictionary = CompanionRegistry.get_profile(companion_id)
	if profile.is_empty():
		return

	# Black backdrop with gold-rim spotlight.
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "GachaBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var fade_in: Tween = create_tween()
	fade_in.tween_property(backdrop, "color:a", 0.85, 0.4)

	# Centered panel.
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "GachaPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180.0
	panel.offset_right = 180.0
	panel.offset_top = -260.0
	panel.offset_bottom = 260.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = UIConstants.ACCENT_GOLD_BRIGHT
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title.
	var title: Label = Label.new()
	title.text = Localization.get_text("ARTEMIS_JOINS_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	# Portrait.
	var portrait_rect: TextureRect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(0.0, 240.0)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	var portrait_path: String = CompanionRegistry.get_portrait_path(companion_id, "happy")
	if not ResourceLoader.exists(portrait_path):
		portrait_path = CompanionRegistry.get_portrait_path(companion_id, "neutral")
	if ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
	else:
		portrait_rect.modulate = Color(0.3, 0.25, 0.2, 1.0)
	vbox.add_child(portrait_rect)

	# Subtitle (the headline).
	var subtitle: Label = Label.new()
	subtitle.text = Localization.get_text("ARTEMIS_JOINS_SUBTITLE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	subtitle.add_theme_font_size_override("font_size", 22)
	vbox.add_child(subtitle)
	Fx.gold_shimmer(subtitle, 2.0)

	# Description.
	var desc: Label = Label.new()
	desc.text = Localization.get_text("ARTEMIS_JOINS_DESCRIPTION")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	desc.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc)

	# OK button.
	var ok_btn: Button = Button.new()
	ok_btn.text = Localization.get_text("ARTEMIS_JOINS_OK")
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
		GameStore.set_flag("%s_join_shown" % companion_id)
		backdrop.queue_free()
		panel.queue_free()
	)
	vbox.add_child(ok_btn)

	# Spring scale entrance.
	panel.scale = Vector2(0.4, 0.4)
	panel.pivot_offset = Vector2(180.0, 260.0)
	var spring: Tween = create_tween()
	spring.tween_property(panel, "scale", Vector2.ONE, 0.55) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


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
		# Chain into the hub tutorial immediately so first-time players see
		# it on the same visit instead of waiting for a later Hub return.
		_show_hub_tutorial()
		_start_story_highlight()
	)
	vbox.add_child(ok_btn)

	# Slide-in animation.
	Fx.slide_in(_welcome_popup, Vector2(0.0, 40.0), 0.35)
	Fx.gold_shimmer(title_lbl, 2.5)


## Starts a looping attention-grab on the Story button so first-time players
## know exactly where to go. Pulses the button scale + flashes the border
## color between gold-dark and gold-bright. Killed on scene exit or story tap.
func _start_story_highlight() -> void:
	var story_btn: Node = get_node_or_null("BottomTabs/StoryBtn")
	if story_btn == null or not story_btn is Button:
		return
	var btn: Button = story_btn as Button
	btn.pivot_offset = btn.size * 0.5

	# Kill any prior highlight (defensive — shouldn't happen).
	if _story_highlight_tween != null and _story_highlight_tween.is_valid():
		_story_highlight_tween.kill()

	_story_highlight_tween = btn.create_tween().set_loops()
	_story_highlight_tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.55) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_story_highlight_tween.tween_property(btn, "scale", Vector2.ONE, 0.55) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Gold glow on the button text as a second attention cue.
	Fx.gold_shimmer(btn, 1.4)


# ── Signal Callbacks ────────────────────────────────────────────────────────────

## Disconnects persistent autoload signals on scene exit to avoid dangling callbacks.
## Disconnects persistent autoload signals and kills looping tweens on scene
## exit. Looping tweens (breathe + name shimmer) keep running against a freed
## portrait/label if not explicitly killed — this is the cleanup hook.
func _disconnect_autoload_signals() -> void:
	if GameStore.state_changed.is_connected(_on_state_changed):
		GameStore.state_changed.disconnect(_on_state_changed)
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	if _name_shimmer_tween != null and _name_shimmer_tween.is_valid():
		_name_shimmer_tween.kill()
	if _story_highlight_tween != null and _story_highlight_tween.is_valid():
		_story_highlight_tween.kill()


func _on_state_changed(_key: String = "") -> void:
	var new_gold: int = GameStore.get_gold()
	if new_gold != _displayed_gold:
		var old: int = _displayed_gold
		_displayed_gold = new_gold
		_animate_gold_change(old, new_gold)


# ── Tab Buttons ────────────────────────────────────────────────────────────────

func _on_story_pressed() -> void:
	# Stop the welcome-flow highlight immediately so the button settles
	# before the scene transition fades out.
	if _story_highlight_tween != null and _story_highlight_tween.is_valid():
		_story_highlight_tween.kill()
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
	# The "arena" tab is rebranded to "Tavern" after ch01_tavern_done.
	# It now routes to the Tavern Map (list of tournaments by location).
	SceneManager.change_scene(SceneManager.SceneId.TAVERN_MAP)


func _on_settings_pressed() -> void:
	SceneManager.open_settings_overlay()
