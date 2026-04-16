extends Control

## Forge of Hephaestus — Equipment gacha UI (v1: forge fragments only).
##
## Mirrors the Oracle scene's structure but is much simpler: each pull
## grants forge fragments (3-5 per roll). Equipment drops will replace
## some fragment outcomes once the Equipment GDD ships.
##
## The weekly pull cap is shared with the Oracle.

const WEEKLY_CAP: int = 30

var _forge: Forge
var _back_btn: Button
var _gold_label: Label
var _pulls_label: Label
var _fragment_label: Label
var _single_btn: Button
var _ten_btn: Button

## Reveal overlay.
var _reveal_root: Control
var _reveal_panel: PanelContainer
var _reveal_title: Label
var _reveal_text: Label
var _reveal_continue_btn: Button


func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/camp.ogg")
	GameStore.tick_oracle_weekly_reset()
	_forge = Forge.new()
	_build_layout()
	_refresh_all()
	GameStore.state_changed.connect(_on_state_changed)
	tree_exiting.connect(_disconnect_autoload_signals)


func _disconnect_autoload_signals() -> void:
	if GameStore.state_changed.is_connected(_on_state_changed):
		GameStore.state_changed.disconnect(_on_state_changed)


func _build_layout() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.14, 0.08, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 16.0
	root_vbox.offset_right = -16.0
	root_vbox.offset_top = 20.0
	root_vbox.offset_bottom = -20.0
	root_vbox.add_theme_constant_override("separation", 16)
	add_child(root_vbox)

	# Top bar.
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(top_row)

	_back_btn = Button.new()
	_back_btn.text = "<"
	_back_btn.custom_minimum_size = Vector2(44.0, 44.0)
	_back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(_back_btn)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	_gold_label.add_theme_font_size_override("font_size", 18)
	top_row.add_child(_gold_label)

	var sep: Control = Control.new()
	sep.custom_minimum_size = Vector2(16.0, 0.0)
	top_row.add_child(sep)

	_pulls_label = Label.new()
	_pulls_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_pulls_label.add_theme_font_size_override("font_size", 14)
	top_row.add_child(_pulls_label)

	# Title.
	var title: Label = Label.new()
	title.text = Localization.get_text("FORGE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1.0))
	title.add_theme_font_size_override("font_size", 26)
	root_vbox.add_child(title)

	# Subtitle.
	var subtitle: Label = Label.new()
	subtitle.text = Localization.get_text("FORGE_SUBTITLE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	subtitle.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(subtitle)

	# Fragment counter — the centerpiece of the v1 Forge.
	var frag_panel: PanelContainer = PanelContainer.new()
	frag_panel.custom_minimum_size = Vector2(0.0, 120.0)
	var frag_style: StyleBoxFlat = StyleBoxFlat.new()
	frag_style.bg_color = UIConstants.BG_SECONDARY
	frag_style.border_color = Color(1.0, 0.5, 0.2, 1.0)
	frag_style.set_border_width_all(2)
	frag_style.set_corner_radius_all(10)
	frag_style.content_margin_left = 20.0
	frag_style.content_margin_right = 20.0
	frag_style.content_margin_top = 16.0
	frag_style.content_margin_bottom = 16.0
	frag_panel.add_theme_stylebox_override("panel", frag_style)
	root_vbox.add_child(frag_panel)

	var frag_vbox: VBoxContainer = VBoxContainer.new()
	frag_vbox.add_theme_constant_override("separation", 6)
	frag_panel.add_child(frag_vbox)

	var frag_header: Label = Label.new()
	frag_header.text = Localization.get_text("FORGE_FRAGMENTS_HEADER")
	frag_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frag_header.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	frag_header.add_theme_font_size_override("font_size", 14)
	frag_vbox.add_child(frag_header)

	_fragment_label = Label.new()
	_fragment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fragment_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3, 1.0))
	_fragment_label.add_theme_font_size_override("font_size", 36)
	frag_vbox.add_child(_fragment_label)

	var frag_hint: Label = Label.new()
	frag_hint.text = Localization.get_text("FORGE_FRAGMENTS_HINT")
	frag_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frag_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frag_hint.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	frag_hint.add_theme_font_size_override("font_size", 11)
	frag_vbox.add_child(frag_hint)

	# Spacer.
	var body_spacer: Control = Control.new()
	body_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(body_spacer)

	# Pull buttons.
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(btn_row)

	_single_btn = _make_pull_button(
		Localization.get_text("FORGE_PULL_SINGLE") % _forge.single_cost
	)
	_single_btn.pressed.connect(_on_single_pressed)
	btn_row.add_child(_single_btn)

	_ten_btn = _make_pull_button(
		Localization.get_text("FORGE_PULL_TEN") % _forge.ten_cost
	)
	_ten_btn.pressed.connect(_on_ten_pressed)
	btn_row.add_child(_ten_btn)

	_build_reveal_overlay()


func _make_pull_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 56.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	btn.add_theme_font_size_override("font_size", 16)
	return btn


func _build_reveal_overlay() -> void:
	_reveal_root = ColorRect.new()
	_reveal_root.color = Color(0.0, 0.0, 0.0, 0.75)
	_reveal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal_root.visible = false
	add_child(_reveal_root)

	_reveal_panel = PanelContainer.new()
	_reveal_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_reveal_panel.custom_minimum_size = Vector2(340.0, 260.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.border_color = Color(1.0, 0.5, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	_reveal_panel.add_theme_stylebox_override("panel", style)
	_reveal_root.add_child(_reveal_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_reveal_panel.add_child(vbox)

	_reveal_title = Label.new()
	_reveal_title.text = Localization.get_text("FORGE_REVEAL_TITLE")
	_reveal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3, 1.0))
	_reveal_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_reveal_title)

	_reveal_text = Label.new()
	_reveal_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_text.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	_reveal_text.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_reveal_text)

	_reveal_continue_btn = Button.new()
	_reveal_continue_btn.text = Localization.get_text("FORGE_REVEAL_CONTINUE")
	_reveal_continue_btn.custom_minimum_size = Vector2(0.0, 48.0)
	_reveal_continue_btn.pressed.connect(_on_reveal_continue)
	vbox.add_child(_reveal_continue_btn)


# ── Refresh ──────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_gold_label.text = "%s %d" % [Localization.get_text("ORACLE_GOLD_LABEL"), GameStore.get_gold()]
	_pulls_label.text = Localization.get_text("ORACLE_PULLS_LABEL") % [
		GameStore.get_oracle_pulls_this_week(), WEEKLY_CAP,
	]
	_fragment_label.text = str(GameStore.get_forge_fragments())
	var gold: int = GameStore.get_gold()
	var pulls: int = GameStore.get_oracle_pulls_this_week()
	_single_btn.disabled = not _forge.can_single_pull(gold, pulls, WEEKLY_CAP)
	_ten_btn.disabled = not _forge.can_ten_pull(gold, pulls, WEEKLY_CAP)


# ── Pull handlers ────────────────────────────────────────────────────────────

func _on_single_pressed() -> void:
	var gold: int = GameStore.get_gold()
	var pulls: int = GameStore.get_oracle_pulls_this_week()
	if not _forge.can_single_pull(gold, pulls, WEEKLY_CAP):
		return
	_single_btn.pivot_offset = _single_btn.size * 0.5
	Fx.pop_scale(_single_btn, 1.08, 0.25)
	GameStore.spend_gold(_forge.single_cost)
	GameStore.add_oracle_pulls(1)
	var fragments: int = _forge.roll_single()
	GameStore.add_forge_fragments(fragments)
	_show_reveal(fragments)


func _on_ten_pressed() -> void:
	var gold: int = GameStore.get_gold()
	var pulls: int = GameStore.get_oracle_pulls_this_week()
	if not _forge.can_ten_pull(gold, pulls, WEEKLY_CAP):
		return
	_ten_btn.pivot_offset = _ten_btn.size * 0.5
	Fx.pop_scale(_ten_btn, 1.08, 0.25)
	GameStore.spend_gold(_forge.ten_cost)
	GameStore.add_oracle_pulls(10)
	var fragments: int = _forge.roll_ten()
	GameStore.add_forge_fragments(fragments)
	_show_reveal(fragments)


func _show_reveal(fragments: int) -> void:
	_reveal_text.text = Localization.get_text("FORGE_REVEAL_RESULT") % fragments
	_reveal_root.visible = true

	# Pop entrance — same pattern as Oracle.
	if _reveal_panel != null:
		_reveal_panel.pivot_offset = _reveal_panel.size * 0.5
		_reveal_panel.scale = Vector2(0.85, 0.85)
		_reveal_panel.modulate.a = 0.0
		var tween: Tween = _reveal_panel.create_tween().set_parallel(true)
		tween.tween_property(_reveal_panel, "scale", Vector2.ONE, 0.35) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_reveal_panel, "modulate:a", 1.0, 0.2)

	_refresh_all()


func _on_reveal_continue() -> void:
	_reveal_root.visible = false


# ── Navigation + signals ────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


func _on_state_changed(_key: String) -> void:
	_refresh_all()
