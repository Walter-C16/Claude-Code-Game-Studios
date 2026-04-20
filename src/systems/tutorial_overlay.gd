class_name TutorialOverlay
extends RefCounted

## TutorialOverlay — Reusable one-time tutorial popup builder.
##
## Usage from any scene:
##   func _ready() -> void:
##       TutorialOverlay.show_once(self,
##           "tutorial_combat_shown",
##           "TUTORIAL_COMBAT_TITLE",
##           "TUTORIAL_COMBAT_BODY")
##
## On dismiss, sets the GameStore flag so the popup never re-fires.
## All text is resolved through Localization — pass key strings.
## Centered, gold-bordered, dark mythological theme.
##
## Layer Classification: foundation-level stateless utility (same family
## as Fx, JsonLoader, UIConstants).

# ── Public API ─────────────────────────────────────────────────────────────────

## Shows a tutorial popup if [param flag_id] is not yet set in GameStore.
## No-op if the flag is already set. Sets the flag on dismiss.
## [param parent] receives the popup as a child (typically the scene root).
## [param title_key] / [param body_key] are looked up via Localization.
static func show_once(parent: Control, flag_id: String, title_key: String, body_key: String) -> void:
	if GameStore.has_flag(flag_id):
		return
	# Set the flag as soon as we commit to showing the overlay. If the player
	# force-quits the app before tapping "Got it", the tutorial still counts
	# as shown — otherwise it would re-trigger indefinitely on relaunch.
	GameStore.set_flag(flag_id)
	_build(parent, flag_id, title_key, body_key)


# ── Internal Construction ─────────────────────────────────────────────────────

static func _build(parent: Control, flag_id: String, title_key: String, body_key: String) -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "TutorialBackdrop_%s" % flag_id
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(backdrop)
	var fade_in: Tween = parent.create_tween()
	fade_in.tween_property(backdrop, "color:a", 0.7, 0.25)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "TutorialPanel_%s" % flag_id
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180.0
	panel.offset_right = 180.0
	panel.offset_top = -200.0
	panel.offset_bottom = 200.0
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	parent.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title row.
	var title_lbl: Label = Label.new()
	title_lbl.text = Localization.get_text(title_key)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	title_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_lbl)
	Fx.gold_shimmer(title_lbl, 2.5)

	# Tutorial badge subtitle.
	var badge: Label = Label.new()
	badge.text = Localization.get_text("TUTORIAL_BADGE")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	badge.add_theme_font_size_override("font_size", 11)
	vbox.add_child(badge)

	# Body — autowraps; bullets are encoded in the localization string.
	var body_lbl: Label = Label.new()
	body_lbl.text = Localization.get_text(body_key)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	body_lbl.add_theme_font_size_override("font_size", 14)
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_lbl)

	# Got it button.
	var ok_btn: Button = Button.new()
	ok_btn.text = Localization.get_text("TUTORIAL_OK")
	ok_btn.custom_minimum_size = Vector2(0.0, 52.0)
	ok_btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	ok_btn.add_theme_font_size_override("font_size", 16)
	ok_btn.add_theme_stylebox_override("normal", _make_button_style())
	# Flag was already set in show_once() — this callback only needs to
	# tear down the overlay nodes.
	ok_btn.pressed.connect(func() -> void:
		backdrop.queue_free()
		panel.queue_free()
	)
	vbox.add_child(ok_btn)

	# Spring entrance.
	panel.scale = Vector2(0.6, 0.6)
	panel.pivot_offset = Vector2(180.0, 200.0)
	var spring: Tween = parent.create_tween()
	spring.tween_property(panel, "scale", Vector2.ONE, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


static func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = UIConstants.ACCENT_GOLD
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	return style


static func _make_button_style() -> StyleBoxFlat:
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
	return style
