extends Control

## Abyss — Roguelike 8-ante run entry, shop, and progress screen.
##
## Uses AbyssRun, AbyssShop, AbyssConfig, AbyssModifiers for all logic.
## Run state is ephemeral — only gold/rewards are applied to GameStore on completion.

# ── Node References ────────────────────────────────────────────────────────────

@onready var title_label: Label = %TitleLabel
@onready var depth_label: Label = %DepthLabel
@onready var enter_btn: Button = %EnterBtn
@onready var back_btn: Button = %BackBtn

# ── Private State ──────────────────────────────────────────────────────────────

var _run: AbyssRun
var _shop: AbyssShop
var _config: AbyssConfig
var _modifiers: AbyssModifiers
var _content: VBoxContainer

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	title_label.text = Localization.get_text("ABYSS_TITLE")
	enter_btn.visible = false
	AudioManager.play_bgm("res://assets/audio/bgm/abyss.ogg")

	_config = AbyssConfig.new()
	_modifiers = AbyssModifiers.new(_config)

	# Build dynamic content area below the existing nodes.
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = 110.0
	_content.offset_left = 16.0
	_content.offset_right = -16.0
	_content.offset_bottom = -60.0
	add_child(_content)

	_show_lobby()


func _on_back_pressed() -> void:
	if _run != null and _run.state == AbyssRun.RunState.SHOP:
		# From shop, go back to ante (forfeit shop).
		_start_next_ante()
	else:
		SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── Lobby ──────────────────────────────────────────────────────────────────────

## Shows the lobby: weekly modifier info + start run button.
func _show_lobby() -> void:
	_clear_content()
	depth_label.text = "8 Antes — Escalating Difficulty"

	# Weekly modifier.
	var modifier: Dictionary = _modifiers.get_weekly_modifier()
	var modifier_name: String = modifier.get("id", "")
	if not modifier_name.is_empty():
		var mod_lbl: Label = Label.new()
		var name_key: String = modifier.get("nameKey", modifier_name)
		mod_lbl.text = "Weekly Modifier: %s" % Localization.get_text(name_key)
		mod_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mod_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
		mod_lbl.add_theme_font_size_override("font_size", 14)
		_content.add_child(mod_lbl)

	# Best depth (if tracked).
	var best: Label = Label.new()
	best.text = "Survive all 8 antes to claim legendary rewards."
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	best.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	best.add_theme_font_size_override("font_size", 13)
	_content.add_child(best)

	# Start button.
	var start_btn: Button = _make_button(Localization.get_text("ABYSS_BEGIN_DESCENT"))
	start_btn.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	start_btn.pressed.connect(_on_start_run)
	_content.add_child(start_btn)


# ── Run Flow ───────────────────────────────────────────────────────────────────

func _on_start_run() -> void:
	_run = AbyssRun.new(_config)
	_shop = AbyssShop.new(_config)

	# Build starting deck from DeckManager.
	var dm: DeckManager = DeckManager.new()
	add_child(dm)
	await get_tree().process_frame
	var deck: Array[Dictionary] = dm.build_deck()
	dm.queue_free()

	var modifier_id: String = _modifiers.get_weekly_modifier_id()
	_run.start_run(deck, modifier_id)

	_start_next_ante()


## Launches combat for the current ante.
func _start_next_ante() -> void:
	if _run == null or _run.state == AbyssRun.RunState.COMPLETE:
		_show_summary()
		return
	if _run.state == AbyssRun.RunState.DEFEAT:
		_show_defeat()
		return

	_run.state = AbyssRun.RunState.ANTE_COMBAT

	var enemy_config: Dictionary = _run.get_enemy_config()
	var captain_id: String = GameStore.get_last_captain_id()

	SceneManager.change_scene(
		SceneManager.SceneId.COMBAT,
		SceneManager.TransitionType.FADE,
		{
			"enemy_config": enemy_config,
			"captain_id": captain_id,
			"abyss_run": true,
		}
	)


# ── Shop ───────────────────────────────────────────────────────────────────────

## Shows the between-ante shop.
func _show_shop() -> void:
	_clear_content()
	depth_label.text = "Ante %d / 8 — Shop" % _run.ante_current

	var gold_lbl: Label = Label.new()
	gold_lbl.text = "Run Gold: %d" % _run.run_gold
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	gold_lbl.add_theme_font_size_override("font_size", 18)
	_content.add_child(gold_lbl)

	var stock: Array[Dictionary] = _shop.generate_stock(_run)
	for slot: Dictionary in stock:
		var slot_type: String = slot.get("type", "")
		var cost: int = slot.get("cost", 0)
		var desc: String = slot.get("description", slot_type.capitalize())

		var btn: Button = _make_button("%s  (%d gold)" % [desc, cost])
		if _run.run_gold < cost:
			btn.disabled = true
			btn.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		btn.pressed.connect(func() -> void:
			_shop.purchase(slot, _run)
			_show_shop()  # Refresh shop after purchase
		)
		_content.add_child(btn)

	var skip_btn: Button = _make_button("Skip Shop — Next Ante")
	skip_btn.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	skip_btn.pressed.connect(_start_next_ante)
	_content.add_child(skip_btn)


# ── Summary / Defeat ───────────────────────────────────────────────────────────

## Shows the run completion summary.
func _show_summary() -> void:
	_clear_content()
	depth_label.text = "Run Complete!"

	var title_lbl: Label = Label.new()
	title_lbl.text = Localization.get_text("ABYSS_CONQUERED")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	title_lbl.add_theme_font_size_override("font_size", 24)
	_content.add_child(title_lbl)
	Fx.gold_shimmer(title_lbl, 2.5)

	var gold_lbl: Label = Label.new()
	gold_lbl.text = "Total Gold Earned: %d" % _run.total_gold_earned
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	gold_lbl.add_theme_font_size_override("font_size", 16)
	_content.add_child(gold_lbl)

	# Award persistent gold.
	GameStore.add_gold(_run.total_gold_earned)

	var exit_btn: Button = _make_button(Localization.get_text("ABYSS_RETURN_HUB"))
	exit_btn.pressed.connect(func() -> void:
		SceneManager.change_scene(SceneManager.SceneId.HUB)
	)
	_content.add_child(exit_btn)


## Shows the defeat screen.
func _show_defeat() -> void:
	_clear_content()
	depth_label.text = "Defeated at Ante %d" % _run.ante_current

	var title_lbl: Label = Label.new()
	title_lbl.text = Localization.get_text("ABYSS_DEFEAT")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", UIConstants.STATUS_DANGER)
	title_lbl.add_theme_font_size_override("font_size", 20)
	_content.add_child(title_lbl)

	var gold_lbl: Label = Label.new()
	gold_lbl.text = "Gold Earned: %d (lost)" % _run.total_gold_earned
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
	gold_lbl.add_theme_font_size_override("font_size", 14)
	_content.add_child(gold_lbl)

	var exit_btn: Button = _make_button(Localization.get_text("ABYSS_RETURN_HUB"))
	exit_btn.pressed.connect(func() -> void:
		SceneManager.change_scene(SceneManager.SceneId.HUB)
	)
	_content.add_child(exit_btn)


# ── Helpers ────────────────────────────────────────────────────────────────────

func _clear_content() -> void:
	if _content == null:
		return
	for child: Node in _content.get_children():
		child.queue_free()


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
