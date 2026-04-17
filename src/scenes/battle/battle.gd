extends Control

## Battle — Side-view turn-based action combat scene.
##
## Wraps a BattleManager instance and drives the UI from its signals.
## Flow:
##   1. _ready reads arrival context (enemy_ids, story_node, tavern_id unused)
##   2. Builds party from GameStore.get_deck_companions() + protagonist
##   3. BattleManager.setup() and listens to its signals
##   4. On player turn: enables action buttons, waits for tap
##   5. On enemy turn: runs _run_enemy_ai after a small delay
##   6. On victory/defeat: shows overlay and handles story rewards
##
## This scene replaces the poker combat scene for story combats. The old
## combat.gd is still used for tavern tournaments.

# ── Constants ─────────────────────────────────────────────────────────────────

## How long to pause between enemy turn_started and enemy action.
const ENEMY_AI_DELAY: float = 0.8

## How long to show reaction banners before clearing.
const REACTION_BANNER_DURATION: float = 1.4

## Hit flash duration when a unit takes damage.
const HIT_FLASH_DURATION: float = 0.2

# ── Node references ──────────────────────────────────────────────────────────

@onready var arena: Control = %Arena
@onready var enemy_row: HBoxContainer = %EnemyRow
@onready var party_row: HBoxContainer = %PartyRow
@onready var reaction_banner: Label = %ReactionBanner
@onready var turn_banner: Label = %TurnBanner
@onready var hud_panel: PanelContainer = %HudPanel
@onready var actor_name_label: Label = %ActorName
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var energy_label: Label = %EnergyLabel
@onready var ult_label: Label = %UltLabel
@onready var attack_btn: Button = %AttackBtn
@onready var special_btn: Button = %SpecialBtn
@onready var ultimate_btn: Button = %UltimateBtn
@onready var hint_label: Label = %HintLabel
@onready var victory_overlay: ColorRect = %VictoryOverlay
@onready var victory_continue_btn: Button = %VictoryContinueBtn
@onready var defeat_overlay: ColorRect = %DefeatOverlay
@onready var defeat_retry_btn: Button = %DefeatRetryBtn
@onready var defeat_retreat_btn: Button = %DefeatRetreatBtn

# ── Private state ────────────────────────────────────────────────────────────

var _battle: BattleManager
var _party_slots: Array[Control] = []
var _enemy_slots: Array[Control] = []
var _pending_move_type: String = ""
var _is_picking_target: bool = false

## Per-turn countdown timer. Created on _ready if the encounter has a non-zero
## turn_time_limit AND the global accessibility kill switch is off. Drives the
## %TimerBar widget through _process. Null when the encounter is untimed.
var _turn_timer: BattleTurnTimer = null
var _timer_bar: ProgressBar = null
var _timer_label: Label = null

## Ultimate charge progress bar — sits next to the ult text label. Built at
## runtime so the .tscn doesn't need editing. Filled via _refresh_actor_hud.
var _ult_bar: ProgressBar = null

## Arrival context — captured in _ready, used in victory handler.
var _story_node: String = ""
var _enemy_ids: Array[String] = []

# ── Built-in ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/combat_standard.ogg")
	victory_overlay.visible = false
	defeat_overlay.visible = false
	reaction_banner.text = ""

	attack_btn.pressed.connect(_on_attack_pressed)
	special_btn.pressed.connect(_on_special_pressed)
	ultimate_btn.pressed.connect(_on_ultimate_pressed)
	victory_continue_btn.pressed.connect(_on_victory_continue)
	defeat_retry_btn.pressed.connect(_on_defeat_retry)
	defeat_retreat_btn.pressed.connect(_on_defeat_retreat)

	var ctx: Dictionary = SceneManager.get_arrival_context()
	_story_node = ctx.get("story_node", "") as String
	_enemy_ids = _resolve_enemy_ids(ctx)

	tree_exiting.connect(_disconnect_battle_signals)

	var party_ids: Array[String] = _build_party_ids()
	_battle = BattleManager.new()
	_battle.turn_started.connect(_on_turn_started)
	_battle.move_executed.connect(_on_move_executed)
	_battle.reaction_triggered.connect(_on_reaction_triggered)
	_battle.battle_ended.connect(_on_battle_ended)

	if not _battle.setup(party_ids, _enemy_ids):
		push_error("battle.gd: BattleManager.setup failed")
		_on_defeat_retreat()
		return

	_apply_tutorial_safety_net()
	_build_unit_slots()
	_install_turn_timer()
	_install_ult_bar()
	_refresh_all()

	# Kick off the first turn — the signal fires inside setup(), but we missed
	# it because we hadn't connected yet. Drive it from here.
	var starter: Combatant = _battle.current_combatant()
	if starter != null:
		_on_turn_started(starter)

	# Combat mechanics tutorial — shown on the first NON-tutorial battle
	# (after ch01_n00 is done). Explains energy, specials, crits, and timer.
	if _story_node != "ch01_n00":
		TutorialOverlay.show_once(self,
			"tutorial_battle_mechanics_shown",
			"TUTORIAL_BATTLE_MECHANICS_TITLE",
			"TUTORIAL_BATTLE_MECHANICS_BODY")


# ── Turn timer ───────────────────────────────────────────────────────────────

## Builds the per-turn countdown timer + UI bar if the encounter has a
## non-zero turn_time_limit and the accessibility kill switch isn't on. The
## tutorial fight is hard-overridden — never timed regardless of enemy data.
func _install_turn_timer() -> void:
	if _story_node == "ch01_n00":
		return
	if _battle.turn_time_limit <= 0:
		return
	if SettingsStore.combat_disable_timers:
		return

	_turn_timer = BattleTurnTimer.new()
	_turn_timer.expired.connect(_on_turn_timer_expired)

	# Bar widget — sits inside the HUD panel above the action buttons. Built
	# at runtime so the .tscn doesn't need to be edited.
	var bar_box: VBoxContainer = VBoxContainer.new()
	bar_box.name = "TimerBox"
	bar_box.add_theme_constant_override("separation", 2)

	_timer_label = Label.new()
	_timer_label.text = Localization.get_text("BATTLE_TIMER_LABEL")
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_color_override("font_color", UIConstants.TEXT_SECONDARY)
	_timer_label.add_theme_font_size_override("font_size", 11)
	bar_box.add_child(_timer_label)

	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0.0, 10.0)
	_timer_bar.max_value = 1.0
	_timer_bar.step = 0.001
	_timer_bar.value = 1.0
	_timer_bar.show_percentage = false
	bar_box.add_child(_timer_bar)

	# Slot the box at the top of the HUD panel so it sits above the action
	# buttons. PanelContainer wraps a single child so we walk one level in.
	var hud_inner: Node = hud_panel.get_child(0) if hud_panel.get_child_count() > 0 else null
	if hud_inner is BoxContainer:
		hud_inner.add_child(bar_box)
		hud_inner.move_child(bar_box, 0)
	else:
		hud_panel.add_child(bar_box)


## Builds the ultimate charge bar next to the ult text label. The bar is a
## thin ProgressBar placed after ult_label in the same container.
func _install_ult_bar() -> void:
	_ult_bar = ProgressBar.new()
	_ult_bar.custom_minimum_size = Vector2(0.0, 8.0)
	_ult_bar.max_value = 1.0
	_ult_bar.step = 0.01
	_ult_bar.value = 0.0
	_ult_bar.show_percentage = false
	_ult_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.65, 0.45, 1.0, 1.0)  # purple-ish for ult charge
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	_ult_bar.add_theme_stylebox_override("fill", fill)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	_ult_bar.add_theme_stylebox_override("background", bg)
	# Slot the bar right after the ult label in its parent container.
	var parent: Node = ult_label.get_parent()
	if parent != null:
		var idx: int = ult_label.get_index() + 1
		parent.add_child(_ult_bar)
		parent.move_child(_ult_bar, idx)


func _on_turn_timer_expired() -> void:
	if _battle == null or _battle.is_battle_over():
		return
	var actor: Combatant = _battle.current_combatant()
	if actor == null or actor.is_enemy:
		return
	var result: Dictionary = _battle.auto_normal_attack()
	_animate_hit_results(result)


func _process(delta: float) -> void:
	if _turn_timer == null or not _turn_timer.enabled:
		return
	if _battle == null or _battle.is_battle_over():
		return
	var actor: Combatant = _battle.current_combatant()
	if actor == null or actor.is_enemy:
		return
	_turn_timer.tick(delta)
	if _timer_bar != null and _battle.turn_time_limit > 0:
		var fraction: float = _turn_timer.time_remaining / float(_battle.turn_time_limit)
		_timer_bar.value = fraction
		# Urgency: tint red + subtle pulse when below 25%.
		if fraction < 0.25:
			var fill: StyleBoxFlat = _timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
			if fill != null:
				fill.bg_color = UIConstants.STATUS_DANGER
			# Subtle scale pulse on the timer container.
			var bar_parent: Node = _timer_bar.get_parent()
			if bar_parent is Control and not bar_parent.has_meta("_pulsing"):
				bar_parent.set_meta("_pulsing", true)
				Fx.pulse(bar_parent as Control, 1.04, 0.4)


## Disconnects BattleManager signals and kills any in-flight tweens on
## scene exit. Without this, callbacks fire on freed nodes after the
## player leaves via victory/defeat/retreat.
func _disconnect_battle_signals() -> void:
	if _battle != null:
		if _battle.turn_started.is_connected(_on_turn_started):
			_battle.turn_started.disconnect(_on_turn_started)
		if _battle.move_executed.is_connected(_on_move_executed):
			_battle.move_executed.disconnect(_on_move_executed)
		if _battle.reaction_triggered.is_connected(_on_reaction_triggered):
			_battle.reaction_triggered.disconnect(_on_reaction_triggered)
		if _battle.battle_ended.is_connected(_on_battle_ended):
			_battle.battle_ended.disconnect(_on_battle_ended)
	if _turn_timer != null and _turn_timer.expired.is_connected(_on_turn_timer_expired):
		_turn_timer.expired.disconnect(_on_turn_timer_expired)


# ── Setup helpers ────────────────────────────────────────────────────────────

## Reads the enemy list from arrival context. Accepts either "enemy_ids"
## (Array) or "enemy_id" (single String, legacy callers).
func _resolve_enemy_ids(ctx: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if ctx.has("enemy_ids"):
		for x: Variant in (ctx.get("enemy_ids", []) as Array):
			ids.append(str(x))
	elif ctx.has("enemy_id"):
		ids.append(ctx.get("enemy_id", "") as String)
	if ids.is_empty():
		ids.append("forest_monster")
	return ids


## Builds the active party id list. Always includes the protagonist in slot 0,
## followed by up to 3 companions assigned to the deck via GameStore.
func _build_party_ids() -> Array[String]:
	var ids: Array[String] = ["protagonist"]
	for cid: String in GameStore.get_deck_companions():
		if ids.size() >= 4:
			break
		ids.append(cid)
	return ids


## Tutorial combat safety net — ch01_n00 is the first fight and can't be lost.
## Knock the single enemy's HP down so the player sees a quick victory
## regardless of their input.
func _apply_tutorial_safety_net() -> void:
	if _story_node != "ch01_n00":
		return
	for enemy: Combatant in _battle.enemies:
		enemy.stats.max_hp = 30
		enemy.stats.current_hp = 30
		enemy.stats.atk = 5


# ── Unit slot widgets ─────────────────────────────────────────────────────────

func _build_unit_slots() -> void:
	for child: Node in party_row.get_children():
		child.queue_free()
	for child: Node in enemy_row.get_children():
		child.queue_free()

	_party_slots.clear()
	for p: Combatant in _battle.party:
		var slot: Control = _make_unit_slot(p, false)
		party_row.add_child(slot)
		_party_slots.append(slot)

	_enemy_slots.clear()
	for e: Combatant in _battle.enemies:
		var slot: Control = _make_unit_slot(e, true)
		enemy_row.add_child(slot)
		_enemy_slots.append(slot)


## Builds a single unit slot — name label, colored body rect, HP bar.
## Returns a Control whose children can be reached via the "combatant" meta.
func _make_unit_slot(combatant: Combatant, is_enemy: bool) -> Control:
	var root: PanelContainer = PanelContainer.new()
	root.custom_minimum_size = Vector2(84.0, 180.0)
	root.set_meta("combatant", combatant)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = _element_color(combatant.stats.element) if not is_enemy else UIConstants.STATUS_DANGER
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	root.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	root.add_child(vbox)

	# Name label.
	var name_label: Label = Label.new()
	name_label.text = combatant.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_label)

	# Body rect (placeholder for sprite).
	var body: ColorRect = ColorRect.new()
	body.custom_minimum_size = Vector2(0.0, 110.0)
	body.color = _element_color(combatant.stats.element).darkened(0.3)
	vbox.add_child(body)
	root.set_meta("body_rect", body)

	# HP bar — taller and red-tinted so enemy health is easy to read at a glance.
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0.0, 14.0)
	bar.max_value = 1.0
	bar.step = 0.01
	bar.show_percentage = false
	bar.value = 1.0
	var bar_fill: StyleBoxFlat = StyleBoxFlat.new()
	bar_fill.bg_color = UIConstants.STATUS_DANGER if is_enemy else UIConstants.STATUS_SUCCESS
	bar_fill.corner_radius_top_left = 3
	bar_fill.corner_radius_top_right = 3
	bar_fill.corner_radius_bottom_left = 3
	bar_fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", bar_fill)
	var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bar_bg.corner_radius_top_left = 3
	bar_bg.corner_radius_top_right = 3
	bar_bg.corner_radius_bottom_left = 3
	bar_bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bar_bg)
	vbox.add_child(bar)
	root.set_meta("hp_bar", bar)

	# HP numeric label — bold and white so the value is unmissable.
	var hp_lbl: Label = Label.new()
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	hp_lbl.add_theme_font_size_override("font_size", 14)
	hp_lbl.text = "%d / %d" % [combatant.stats.current_hp, combatant.stats.max_hp]
	vbox.add_child(hp_lbl)
	root.set_meta("hp_label", hp_lbl)

	# Status effect badges — tiny emoji row showing active buffs/debuffs.
	var status_lbl: Label = Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(status_lbl)
	root.set_meta("status_label", status_lbl)

	# Overlay button for target picking — initially transparent and disabled.
	var pick_btn: Button = Button.new()
	pick_btn.flat = true
	pick_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pick_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pick_btn.pressed.connect(_on_target_slot_pressed.bind(combatant))
	root.add_child(pick_btn)
	root.set_meta("pick_btn", pick_btn)

	return root


# ── Refresh ──────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	for slot: Control in _party_slots:
		_refresh_unit_slot(slot)
	for slot: Control in _enemy_slots:
		_refresh_unit_slot(slot)
	_refresh_actor_hud()


func _refresh_unit_slot(slot: Control) -> void:
	var c: Combatant = slot.get_meta("combatant", null) as Combatant
	if c == null:
		return
	var bar: ProgressBar = slot.get_meta("hp_bar", null) as ProgressBar
	if bar != null:
		bar.value = c.stats.hp_fraction()
	var hp_lbl: Label = slot.get_meta("hp_label", null) as Label
	if hp_lbl != null:
		hp_lbl.text = "%d / %d" % [c.stats.current_hp, c.stats.max_hp]
	slot.modulate.a = 1.0 if c.is_alive() else 0.3

	# Status effect badges — show tiny labels for active buffs/debuffs.
	var status_lbl: Label = slot.get_meta("status_label", null) as Label
	if status_lbl != null:
		var badges: Array[String] = []
		if c.stats.active_effects.has("shield"):
			badges.append("🛡")
		if c.stats.active_effects.has("forced_crit"):
			badges.append("⚔")
		if c.stats.active_effects.has("dodge_next"):
			badges.append("💨")
		if c.stats.active_effects.has("hunter_mark"):
			badges.append("🎯")
		if c.stats.active_effects.has("dot_burn"):
			badges.append("🔥")
		if c.stats.active_effects.has("corrupted_bloom"):
			badges.append("☠")
		status_lbl.text = " ".join(badges)

	# Dead units get a grey desaturated border.
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null and not c.is_alive():
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)


## Highlights the active combatant's slot with a gold border and resets
## the previous actor's border to its element color. Gives a clear visual
## cue for whose turn it is beyond just the text banner.
func _highlight_active_slot(actor: Combatant) -> void:
	# Reset all slots to their element border.
	for slot: Control in _party_slots + _enemy_slots:
		var c: Combatant = slot.get_meta("combatant", null) as Combatant
		if c == null:
			continue
		var style: StyleBoxFlat = slot.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			continue
		if not c.is_alive():
			style.border_color = Color(0.3, 0.3, 0.3, 1.0)
			style.border_width_bottom = 2
		else:
			var is_enemy: bool = c.is_enemy
			style.border_color = _element_color(c.stats.element) if not is_enemy else UIConstants.STATUS_DANGER
			style.border_width_bottom = 2

	# Gold highlight on the active actor's slot.
	var active_slot: Control = _find_slot_for(actor)
	if active_slot != null:
		var active_style: StyleBoxFlat = active_slot.get_theme_stylebox("panel") as StyleBoxFlat
		if active_style != null:
			active_style.border_color = UIConstants.ACCENT_GOLD_BRIGHT
			active_style.border_width_bottom = 4


func _refresh_actor_hud() -> void:
	var actor: Combatant = _battle.current_combatant()
	if actor == null:
		return
	# Name · Lv N [blessings]. Enemies are shown with their display name only.
	var name_prefix: String = actor.display_name
	if not actor.is_enemy:
		var level: int = GameStore.get_companion_level(actor.id)
		name_prefix = "%s · %s %d" % [
			actor.display_name,
			Localization.get_text("BATTLE_LEVEL_SHORT"),
			level,
		]
	var bless_count: int = 0
	if not actor.is_enemy and _battle.active_blessings.has(actor.id):
		bless_count = (_battle.active_blessings[actor.id] as Array).size()
	if bless_count > 0:
		actor_name_label.text = "%s  [%s]" % [
			name_prefix,
			Localization.get_text("BATTLE_BLESSINGS_ACTIVE") % bless_count,
		]
	else:
		actor_name_label.text = name_prefix
	hp_bar.value = actor.stats.hp_fraction()
	hp_label.text = "HP %d / %d" % [actor.stats.current_hp, actor.stats.max_hp]
	energy_label.text = "⚡ %d / %d" % [actor.stats.current_energy, actor.stats.max_energy]
	# Tint energy gold when there's enough for the active special, dim otherwise.
	var special_cost: int = 0
	var special_move: BattleMove = actor.get_move("special")
	if special_move != null:
		special_cost = special_move.energy_cost
	var has_enough_energy: bool = actor.stats.current_energy >= special_cost and special_cost > 0
	energy_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.85, 0.3, 1.0) if has_enough_energy else Color(0.6, 0.6, 0.65, 1.0)
	)
	energy_label.add_theme_font_size_override("font_size", 18)
	ult_label.text = "ULT %d / %d" % [actor.stats.current_ultimate, actor.stats.max_ultimate]
	if _ult_bar != null:
		_ult_bar.value = actor.stats.ultimate_fraction()
		# Glow purple-bright when ult is ready.
		var fill_sb: StyleBoxFlat = _ult_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_sb != null:
			fill_sb.bg_color = Color(0.9, 0.7, 1.0, 1.0) if actor.stats.has_full_ultimate() else Color(0.65, 0.45, 1.0, 1.0)

	# Action buttons are only interactable on player turns.
	var is_player_turn: bool = not actor.is_enemy
	attack_btn.disabled = not is_player_turn
	special_btn.disabled = not is_player_turn or not actor.can_cast("special")
	ultimate_btn.disabled = not is_player_turn or not actor.can_cast("ultimate")

	# Localized move names on the buttons — each character's signature moves
	# show up instead of the generic "Attack/Special/Ultimate" text.
	_set_move_button(attack_btn, actor.get_move("normal"), "BATTLE_ACTION_ATTACK")
	_set_move_button(special_btn, actor.get_move("special"), "BATTLE_ACTION_SPECIAL")
	_set_move_button(ultimate_btn, actor.get_move("ultimate"), "BATTLE_ACTION_ULTIMATE")

	var turn_num: int = _battle.turn_number
	if actor.is_enemy:
		turn_banner.text = "Turn %d — %s's move" % [turn_num, actor.display_name]
		hint_label.text = ""
	else:
		turn_banner.text = "Turn %d — Your move, %s" % [turn_num, actor.display_name]
		if _is_picking_target:
			hint_label.text = Localization.get_text("BATTLE_HINT_TARGET")
		else:
			hint_label.text = Localization.get_text("BATTLE_HINT_ACTION")


## Sets a button's label to the localized move name, including energy/ult cost
## suffix when relevant. Falls back to a generic label when the actor lacks
## that move type (e.g. an enemy with no ultimate — button stays disabled).
func _set_move_button(btn: Button, move: BattleMove, fallback_key: String) -> void:
	if move == null:
		btn.text = Localization.get_text(fallback_key)
		btn.tooltip_text = ""
		return
	var name_key: String = move.name_key
	var move_name: String = Localization.get_text(name_key) if not name_key.is_empty() else Localization.get_text(fallback_key)
	if move.move_type == "special" and move.energy_cost > 0:
		btn.text = "%s\n⚡ %d" % [move_name, move.energy_cost]
	elif move.move_type == "ultimate":
		btn.text = "%s\n★ ULT" % move_name
	else:
		btn.text = move_name
	# Tooltip — shows target, damage, hits, and effect so the player
	# understands what the move does before committing.
	btn.tooltip_text = _build_move_tooltip(move)


func _build_move_tooltip(move: BattleMove) -> String:
	var parts: Array[String] = []
	# Target scope.
	match move.target:
		"single_enemy": parts.append(Localization.get_text("TOOLTIP_TARGET_SINGLE"))
		"all_enemies": parts.append(Localization.get_text("TOOLTIP_TARGET_ALL_ENEMIES"))
		"all_allies": parts.append(Localization.get_text("TOOLTIP_TARGET_ALL_ALLIES"))
		"self": parts.append(Localization.get_text("TOOLTIP_TARGET_SELF"))
	# Damage.
	if move.damage_mult > 0.0:
		var pct: int = int(move.damage_mult * 100.0)
		parts.append("%d%% ATK" % pct)
	if move.hits > 1:
		parts.append("%dx hits" % move.hits)
	# Effect.
	if not move.effect.is_empty():
		var effect_key: String = "TOOLTIP_EFFECT_" + move.effect.to_upper()
		var effect_text: String = Localization.get_text(effect_key)
		if effect_text != effect_key:
			parts.append(effect_text)
		else:
			parts.append(move.effect.replace("_", " ").capitalize())
	# Scaling.
	if not move.bonus_scaling.is_empty():
		var stat: String = move.bonus_scaling.get("stat", "") as String
		var ratio: float = float(move.bonus_scaling.get("ratio", 0.0))
		if not stat.is_empty() and ratio > 0.0:
			parts.append("+%d%% %s" % [int(ratio * 100.0), stat.to_upper()])
	return " · ".join(parts)


# ── Signal callbacks from BattleManager ──────────────────────────────────────

func _on_turn_started(combatant: Combatant) -> void:
	_refresh_all()
	_is_picking_target = false
	_set_target_picking(false)

	# Turn banner slide-in — drops from above with a pulse so the player
	# notices whose turn it is without having to read the text.
	Fx.slide_in(turn_banner, Vector2(0.0, -20.0), 0.3)
	Fx.pulse(turn_banner, 1.08, 0.25)

	# Highlight the active combatant's unit slot with a gold border.
	_highlight_active_slot(combatant)

	# Turn timer: arm on player turns, hide and reset on enemy turns.
	if _turn_timer != null:
		if combatant.is_enemy:
			_turn_timer.reset()
			if _timer_bar != null:
				_timer_bar.get_parent().visible = false
		else:
			_turn_timer.start(float(_battle.turn_time_limit))
			if _timer_bar != null:
				_timer_bar.get_parent().visible = true
				_timer_bar.value = 1.0

	if combatant.is_enemy:
		# Give the player a beat to see what's happening before the enemy acts.
		await get_tree().create_timer(ENEMY_AI_DELAY).timeout
		if _battle.is_battle_over():
			return
		_run_enemy_ai(combatant)


func _on_move_executed(_actor: Combatant, _move: BattleMove, _targets: Array) -> void:
	_refresh_all()


## Called by _execute_queued_move and _run_enemy_ai with the Dictionary
## returned by BattleManager.execute_move. Iterates the hits array and
## spawns a floating damage number + shake/flash per target, plus any
## effect-specific VFX labels (PIERCE, TRUE, MARKED, CHAIN, etc.).
func _animate_hit_results(result: Dictionary) -> void:
	if not result.get("success", false):
		return
	var hits: Array = result.get("hits", []) as Array
	for hit: Variant in hits:
		var hit_dict: Dictionary = hit as Dictionary
		var target: Combatant = hit_dict.get("target", null) as Combatant
		var damage: int = int(hit_dict.get("damage", 0))
		var is_crit: bool = hit_dict.get("crit", false)
		var reaction_name: String = hit_dict.get("reaction", "") as String
		var dodged: bool = hit_dict.get("dodged", false)
		var effect: String = hit_dict.get("effect", "") as String
		var is_repeat: bool = hit_dict.get("repeat", false)
		if target == null:
			continue
		var slot: Control = _find_slot_for(target)
		if slot == null:
			continue

		# Dodge — no damage, no flash, small sidestep shake + MISS label.
		if dodged:
			Fx.shake(slot, 3.0, 0.2)
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_MISS"),
				Color(0.65, 0.85, 1.0, 1.0),
				18
			)
			continue

		var body: ColorRect = slot.get_meta("body_rect", null) as ColorRect
		if body != null:
			var flash_color: Color = _pick_flash_color(is_crit, reaction_name, effect)
			Fx.flash(body, flash_color, HIT_FLASH_DURATION)
			Fx.shake(slot, 4.0 if not is_crit else 7.0, 0.25)
		if damage > 0:
			_spawn_damage_number(slot, damage, is_crit, not reaction_name.is_empty())

		# Effect-specific label. Fires alongside the damage number so the
		# player learns what just happened even when numbers blur together.
		_spawn_effect_vfx(slot, effect, is_repeat, damage > 0)


## Chooses the body flash color based on crit / reaction / effect signals.
## Effect colors win over reaction colors, and reaction colors win over
## the plain crit gold, so the most "interesting" thing is what the player
## sees first.
func _pick_flash_color(is_crit: bool, reaction_name: String, effect: String) -> Color:
	match effect:
		"pierce_def":
			return Color(0.55, 0.75, 1.0, 0.85)  # blue pierce
		"ignore_defense":
			return Color(1.0, 1.0, 1.0, 0.95)    # pure white — true damage
		"apply_hunter_mark_2_turns":
			return Color(1.0, 0.35, 0.35, 0.85)  # red mark
		"dispel_enemy_buffs":
			return Color(0.2, 0.2, 0.25, 0.9)    # dark strip
	if not reaction_name.is_empty():
		return Color(0.85, 0.5, 1.0, 0.75)       # purple reaction
	if is_crit:
		return Color(1.0, 0.85, 0.3, 0.8)        # gold crit
	return Color(1.0, 1.0, 1.0, 0.7)             # plain white


## Spawns the effect-name label that floats above the target when a move
## applies a distinctive mechanic. Skips trivial cases to keep the screen
## from becoming a word soup on multi-hit attacks.
func _spawn_effect_vfx(slot: Control, effect: String, is_repeat: bool, had_damage: bool) -> void:
	# Repeat-on-crit hits get a CHAIN callout — only when damage landed so
	# the player sees a visual rhythm on consecutive crits.
	if is_repeat and had_damage:
		_spawn_effect_label(
			slot,
			Localization.get_text("BATTLE_VFX_CHAIN"),
			UIConstants.ACCENT_GOLD_BRIGHT,
			20
		)
		return

	match effect:
		"pierce_def":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_PIERCE"),
				Color(0.55, 0.75, 1.0, 1.0),
				18
			)
		"ignore_defense":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_TRUE"),
				Color(1.0, 1.0, 1.0, 1.0),
				20
			)
		"apply_hunter_mark_2_turns":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_MARKED"),
				Color(1.0, 0.35, 0.35, 1.0),
				18
			)
		"party_shield_30_percent":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_SHIELD"),
				Color(0.4, 0.8, 1.0, 1.0),
				16
			)
		"dodge_next_attack":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_EVADE"),
				Color(0.6, 0.85, 1.0, 1.0),
				16
			)
		"dispel_enemy_buffs":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_DISPEL"),
				Color(0.85, 0.5, 1.0, 1.0),
				18
			)
		"guaranteed_crit_3_turns":
			_spawn_effect_label(
				slot,
				Localization.get_text("BATTLE_VFX_CRIT_STANCE"),
				UIConstants.ACCENT_GOLD_BRIGHT,
				16
			)


## Creates a short-lived floating label above a unit slot with an arbitrary
## string and color. Used for effect callouts (PIERCE!, CHAIN!, TRUE! etc.)
## and the dodge MISS! message. Floats up and fades like damage numbers but
## starts slightly higher so it doesn't collide with them.
func _spawn_effect_label(on_slot: Control, text: String, color: Color, font_size: int) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	arena.add_child(lbl)
	var slot_pos: Vector2 = on_slot.global_position - arena.global_position
	var start: Vector2 = slot_pos + Vector2(on_slot.size.x * 0.5 - 36.0, -28.0)
	lbl.position = start
	lbl.modulate.a = 0.0

	# Fade in with a tiny pop, then float up and fade out.
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(lbl, "modulate:a", 1.0, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "position:y", start.y - 50.0, 0.9) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_property(lbl, "modulate:a", 0.0, 0.3) \
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)


## Creates a short-lived floating label above a unit slot showing damage.
## Crits use a larger gold label; reactions use a purple tint.
func _spawn_damage_number(on_slot: Control, amount: int, is_crit: bool, is_reaction: bool) -> void:
	var lbl: Label = Label.new()
	lbl.text = "-%d" % amount
	if is_crit:
		lbl.text = "-%d!" % amount
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	elif is_reaction:
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.5, 1.0, 1.0))
	else:
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", UIConstants.STATUS_DANGER)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Position above the unit slot (relative to arena so the float anim
	# tracks the arena, not world coordinates).
	arena.add_child(lbl)
	var slot_pos: Vector2 = on_slot.global_position - arena.global_position
	var start: Vector2 = slot_pos + Vector2(on_slot.size.x * 0.5 - 30.0, -6.0)
	lbl.position = start
	lbl.modulate.a = 1.0

	var float_tween: Tween = create_tween().set_parallel(true)
	float_tween.tween_property(lbl, "position:y", start.y - 40.0, 0.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.tween_property(lbl, "modulate:a", 0.0, 0.8) \
		.set_ease(Tween.EASE_IN).set_delay(0.3)
	float_tween.chain().tween_callback(lbl.queue_free)


func _on_reaction_triggered(reaction_name: String, _on_combatant: Combatant) -> void:
	reaction_banner.text = reaction_name
	Fx.pop_scale(reaction_banner, 1.25, 0.35)
	await get_tree().create_timer(REACTION_BANNER_DURATION).timeout
	if reaction_banner.text == reaction_name:
		reaction_banner.text = ""


func _on_battle_ended(victory: bool) -> void:
	_is_picking_target = false
	_set_target_picking(false)
	if victory:
		_grant_victory_xp()
		_try_equipment_drop()
		# Celebration VFX: gold flash → shake → pop overlay with shimmer.
		Fx.flash(arena, UIConstants.ACCENT_GOLD_BRIGHT, 0.25)
		Fx.shake(arena, 3.0, 0.3)
		victory_overlay.visible = true
		var victory_panel: Control = victory_overlay.get_child(0) as Control
		Fx.pop_scale(victory_panel, 1.3, 0.7)
		# Gold shimmer on the victory title (first Label child).
		for child: Node in victory_panel.get_children():
			if child is Label:
				Fx.gold_shimmer(child as Control, 1.5)
				break
		# Inject rewards summary so the player sees what they earned.
		_inject_victory_rewards(victory_panel)
	else:
		# Defeat VFX: heavy shake → dim arena → fade-in overlay.
		Fx.shake(arena, 8.0, 0.5)
		Fx.dim(arena, 0.4, 0.8)
		defeat_overlay.modulate.a = 0.0
		defeat_overlay.visible = true
		var fade_tween: Tween = defeat_overlay.create_tween()
		fade_tween.tween_property(defeat_overlay, "modulate:a", 1.0, 0.5) \
			.set_ease(Tween.EASE_IN)


## Injects a rewards summary label into the victory overlay so the player
## sees XP earned, gold from story, and any equipment drops at a glance.
func _inject_victory_rewards(panel: Control) -> void:
	if panel == null:
		return
	# Remove any previous rewards label (in case of re-display).
	var old: Node = panel.get_node_or_null("RewardsSummary")
	if old != null:
		old.queue_free()

	var lines: Array[String] = []
	# XP.
	var alive_count: int = 0
	var dead_count: int = 0
	for m: Combatant in _battle.party:
		if m.is_alive():
			alive_count += 1
		else:
			dead_count += 1
	var total_xp: int = alive_count * COMBAT_VICTORY_XP_ALIVE + dead_count * COMBAT_VICTORY_XP_FALLEN
	lines.append("+%d XP" % total_xp)
	# Gold from story node.
	if not _story_node.is_empty():
		lines.append(Localization.get_text("BATTLE_REWARD_STORY"))

	var summary: Label = Label.new()
	summary.name = "RewardsSummary"
	summary.text = " · ".join(lines)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	summary.add_theme_font_size_override("font_size", 14)
	# Insert before the continue button (last child of the panel).
	panel.add_child(summary)
	var btn_idx: int = panel.get_child_count() - 1
	if btn_idx > 0:
		panel.move_child(summary, btn_idx - 1)


## Post-victory XP distribution. Every party member that was still standing
## at the end of the fight earns the full combat_victory amount; KO'd
## members still get a reduced share (they learned from the fight). See
## design/quick-specs/companion-leveling.md for tuning.
const COMBAT_VICTORY_XP_ALIVE: int = 30
const COMBAT_VICTORY_XP_FALLEN: int = 10

func _grant_victory_xp() -> void:
	for member: Combatant in _battle.party:
		var amount: int = COMBAT_VICTORY_XP_ALIVE if member.is_alive() else COMBAT_VICTORY_XP_FALLEN
		GameStore.add_companion_xp(member.id, amount)


## Post-victory equipment drop. Boss encounters are guaranteed; regular
## fights have a 20% chance. Drops go into the pending queue (max 5).
## See design/gdd/equipment.md Rule 5 and the 20% DROP_RATE_STANDARD.
const EQUIPMENT_DROP_RATE: float = 0.20

func _try_equipment_drop() -> void:
	var is_boss: bool = false
	for e: Combatant in _battle.enemies:
		if e.stats.turn_timer_seconds >= 60:
			is_boss = true
			break
	var should_drop: bool = is_boss or randf() < EQUIPMENT_DROP_RATE
	if not should_drop:
		return
	var equip_sys: EquipmentSystem = EquipmentSystem.new()
	var drop: Dictionary = equip_sys.generate_drop(is_boss)
	if drop.is_empty():
		return
	var item_id: String = drop.get("id", "") as String
	if item_id.is_empty():
		return
	GameStore.add_pending_equipment(item_id)


# ── Player actions ───────────────────────────────────────────────────────────

func _on_attack_pressed() -> void:
	_queue_move("normal")


func _on_special_pressed() -> void:
	_queue_move("special")


func _on_ultimate_pressed() -> void:
	_queue_move("ultimate")


## Records which move the player wants to use, then either resolves it
## immediately (AoE / self-target) or starts the target picker.
func _queue_move(move_type: String) -> void:
	var actor: Combatant = _battle.current_combatant()
	if actor == null or actor.is_enemy:
		return
	if not actor.can_cast(move_type):
		hint_label.text = "Not enough resource"
		return
	var move: BattleMove = actor.get_move(move_type)
	if move == null:
		return

	_pending_move_type = move_type

	if move.targets_many():
		# AoE — no target picking needed.
		var targets: Array[Combatant] = _battle.live_enemies() if move.targets_enemies() else _battle.live_party()
		_execute_queued_move(targets)
		return
	if move.target == "self":
		_execute_queued_move([actor] as Array[Combatant])
		return
	if move.target == "single_ally":
		# Pick an ally. For now, just auto-target the lowest-HP ally.
		var lowest: Combatant = _lowest_hp_ally()
		if lowest != null:
			_execute_queued_move([lowest] as Array[Combatant])
		return

	# Single enemy — enter target picker.
	_is_picking_target = true
	_set_target_picking(true)
	hint_label.text = "Tap an enemy to target"


func _execute_queued_move(targets: Array[Combatant]) -> void:
	var mt: String = _pending_move_type
	_pending_move_type = ""
	_is_picking_target = false
	_set_target_picking(false)
	var result: Dictionary = _battle.execute_move(mt, targets)
	_animate_hit_results(result)


## Toggles pick buttons on enemy slots (for targeting single enemies).
func _set_target_picking(picking: bool) -> void:
	for slot: Control in _enemy_slots:
		var c: Combatant = slot.get_meta("combatant", null) as Combatant
		if c == null or not c.is_alive():
			continue
		var btn: Button = slot.get_meta("pick_btn", null) as Button
		if btn != null:
			btn.mouse_filter = Control.MOUSE_FILTER_STOP if picking else Control.MOUSE_FILTER_IGNORE
		# Subtle gold highlight during picking.
		slot.modulate = Color(1.3, 1.2, 1.0, 1.0) if picking and c.is_alive() else Color(1.0, 1.0, 1.0, 1.0)


func _on_target_slot_pressed(target: Combatant) -> void:
	if not _is_picking_target or _pending_move_type.is_empty():
		return
	if not target.is_alive():
		return
	_execute_queued_move([target] as Array[Combatant])


# ── Enemy AI ─────────────────────────────────────────────────────────────────

## Delegates to BattleAi for profile-driven move + target selection. The
## actual attack is still driven through BattleManager.execute_move, and the
## result flows through _animate_hit_results like player-initiated actions.
func _run_enemy_ai(actor: Combatant) -> void:
	var action: Dictionary = BattleAi.choose_action(actor, _battle)
	var move_type: String = action.get("move_type", "normal") as String
	var targets: Array[Combatant] = action.get("targets", [] as Array[Combatant]) as Array[Combatant]
	if targets.is_empty():
		return

	var result: Dictionary = _battle.execute_move(move_type, targets)
	_animate_hit_results(result)


# ── Victory / Defeat actions ─────────────────────────────────────────────────

func _on_victory_continue() -> void:
	# Apply story rewards if this was a story combat.
	if not _story_node.is_empty():
		_apply_story_rewards(_story_node)

	if _story_node == "ch01_n00":
		# Tutorial combat → continues into crash_rescue cutscene
		GameStore.set_flag("ch01_tutorial_done")
		SceneManager.change_scene(
			SceneManager.SceneId.DIALOGUE,
			SceneManager.TransitionType.FADE,
			{"chapter_id": "ch01", "sequence_id": "crash_rescue", "story_node": "ch01_crash"}
		)
		return

	# Return to the location list — both story combats and random encounters
	# should drop the player back into free-roam exploration. Time advances
	# after combat so the world feels like it moved.
	GameStore.advance_time()
	SceneManager.change_scene(
		SceneManager.SceneId.LOCATION_LIST,
		SceneManager.TransitionType.FADE
	)


func _on_defeat_retry() -> void:
	victory_overlay.visible = false
	defeat_overlay.visible = false
	_battle = null
	# Re-run _ready logic. Simplest: reload the scene.
	SceneManager.change_scene(
		SceneManager.SceneId.BATTLE,
		SceneManager.TransitionType.FADE,
		{"enemy_ids": _enemy_ids, "story_node": _story_node}
	)


func _on_defeat_retreat() -> void:
	SceneManager.change_scene(SceneManager.SceneId.LOCATION_LIST)


# ── Story reward helper (mirrors combat.gd) ──────────────────────────────────

func _apply_story_rewards(node_id: String) -> void:
	var data: Dictionary = JsonLoader.load_dict("res://assets/data/chapters/ch01.json")
	if data.is_empty():
		return
	var nodes: Array = data.get("nodes", [])
	for node: Variant in nodes:
		var nd: Dictionary = node as Dictionary
		if nd.get("id", "") == node_id:
			var rewards: Dictionary = nd.get("rewards", {})
			var gold: int = int(rewards.get("gold", 0))
			var xp: int = int(rewards.get("xp", 0))
			if gold > 0:
				GameStore.add_gold(gold)
			if xp > 0:
				GameStore.add_xp(xp)
			for flag: Variant in rewards.get("flags", []):
				GameStore.set_flag(str(flag))
			for fx: Variant in nd.get("effects", []):
				var fx_dict: Dictionary = fx as Dictionary
				if fx_dict.get("type", "") == "meet":
					CompanionRegistry.meet_companion(fx_dict.get("companion", "") as String)
			break


# ── Helpers ──────────────────────────────────────────────────────────────────

func _find_slot_for(c: Combatant) -> Control:
	for slot: Control in _party_slots:
		if slot.get_meta("combatant", null) == c:
			return slot
	for slot: Control in _enemy_slots:
		if slot.get_meta("combatant", null) == c:
			return slot
	return null


func _lowest_hp_ally() -> Combatant:
	var best: Combatant = null
	var best_frac: float = 2.0
	for c: Combatant in _battle.live_party():
		var f: float = c.stats.hp_fraction()
		if f < best_frac:
			best_frac = f
			best = c
	return best


func _element_color(element: String) -> Color:
	match element:
		"Fire": return UIConstants.ELEM_FIRE_FG
		"Water": return UIConstants.ELEM_WATER_FG
		"Earth": return UIConstants.ELEM_EARTH_FG
		"Lightning": return UIConstants.ELEM_LIGHTNING_FG
		"Neutral": return UIConstants.ACCENT_GOLD
		_: return UIConstants.TEXT_SECONDARY
