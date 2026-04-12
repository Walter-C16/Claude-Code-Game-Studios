extends Control

## Combat Screen — Poker card combat UI controller (STORY-COMBAT-011, ADR-0007)
##
## Reads arrival context from SceneManager to obtain enemy_config, then wires
## a scene-local CombatManager instance to drive all UI updates. No combat state
## is stored here — this script is purely a view/controller.
##
## Layout zones (430 x 932 viewport, portrait):
##   EnemyInfoPanel   y =   0 – 120 px
##   ScoringTray      y = 120 – 420 px
##   HandArea         y = 420 – 800 px
##   ActionBar        y = 800 – 932 px
##
## Arrival context schema (set by the launching scene via SceneManager):
##   enemy_config    Dictionary — required keys: score_threshold, hands_allowed,
##                   discards_allowed, element, name_key
##   captain_id      String     — companion ID to use as captain ("" for none)
##
## On VICTORY: awards gold/XP via GameStore, emits EventBus.combat_completed,
##             navigates to HUB via SceneManager.
## On DEFEAT:  shows retry / retreat options.
##
## See: docs/architecture/adr-0007-poker-combat.md

# ── Script references (preload avoids circular autoload dependency) ────────────

const CombatManagerScript = preload("res://systems/combat/combat_manager.gd")

# ── Constants ─────────────────────────────────────────────────────────────────

## Gold awarded to the player on VICTORY.
## TODO: load from Balance config when the Balance system exists.
const VICTORY_GOLD_REWARD: int = 50

## XP awarded to the player on VICTORY.
## TODO: load from Balance config when the Balance system exists.
const VICTORY_XP_REWARD: int = 25

## Duration in seconds for the HP bar ease-out tween (AC5, COMBAT-011).
const HP_TWEEN_DURATION: float = 0.6

## Duration in seconds for each per-card score cascade step (AC4, COMBAT-011).
const SCORE_CASCADE_STEP: float = 0.1

## Vertical rise in px applied to selected card buttons.
const CARD_SELECTED_RISE_PX: float = 12.0

## Sort mode token used for sorting by card value.
const SORT_VALUE: StringName = &"value"

## Sort mode token used for sorting by suit then value.
const SORT_SUIT: StringName = &"suit"

# ── @onready node references ──────────────────────────────────────────────────

@onready var score_label: Label = %ScoreLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var mult_label: Label = %MultLabel
@onready var chips_label: Label = %ChipsLabel
@onready var hands_label: Label = %HandsLabel
@onready var discards_label: Label = %DiscardsLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var play_btn: Button = %PlayBtn
@onready var discard_btn: Button = %DiscardBtn
@onready var sort_btn: Button = %SortBtn
@onready var victory_overlay: Control = %VictoryOverlay
@onready var defeat_overlay: Control = %DefeatOverlay
@onready var retreat_confirm: Control = %RetreatConfirm

# ── Private state ─────────────────────────────────────────────────────────────

## Scene-local CombatManager. Created and wired in _ready().
var _combat_manager: RefCounted = null

## Currently selected card indices (indices into _combat_manager.hand).
var _selected_indices: Array[int] = []

## Current sort mode. Flips between SORT_VALUE and SORT_SUIT on each sort tap.
var _sort_mode: StringName = SORT_VALUE

## Enemy config dict read from SceneManager arrival context.
var _enemy_config: Dictionary = {}

## Tracks the displayed score so the count-up animation knows its starting value.
var _displayed_score: int = 0

## Dynamically built HBoxContainer showing active blessing icons above the hand.
var _blessing_strip: HBoxContainer

# ── Built-in virtual methods ──────────────────────────────────────────────────

func _ready() -> void:
	AudioManager.play_bgm("res://assets/audio/bgm/combat_standard.ogg")
	victory_overlay.visible = false
	defeat_overlay.visible = false
	_build_blessing_strip()

	retreat_confirm.visible = false

	# Read arrival context (consumed once — SceneManager clears it after this call)
	var ctx: Dictionary = SceneManager.get_arrival_context()
	var captain_id: String = ctx.get("captain_id", "") as String

	# Build enemy config — support both "enemy_config" dict and "enemy_id" string
	if ctx.has("enemy_config"):
		_enemy_config = ctx.get("enemy_config") as Dictionary
	elif ctx.has("enemy_id"):
		var eid: String = ctx.get("enemy_id", "") as String
		_enemy_config = EnemyRegistry.get_enemy(eid)
		if _enemy_config.is_empty():
			_enemy_config = _default_enemy_config()
	else:
		_enemy_config = _default_enemy_config()

	# Pass story_node through so victory handler can apply story rewards
	if ctx.has("story_node"):
		_enemy_config["story_node"] = ctx.get("story_node", "")

	# Build captain scoring context from CompanionRegistry + GameStore
	var captain_ctx: Dictionary = _build_captain_context(captain_id)

	# Create and set up the scene-local CombatManager
	_combat_manager = CombatManagerScript.new()
	var ok: bool = _combat_manager.setup(
		_enemy_config,
		captain_ctx,
		GameStore,
		EventBus
	)
	if not ok:
		push_error("combat.gd: CombatManager.setup() failed — invalid enemy_config.")
		return

	# Connect state-change signal AFTER setup so we don't miss the initial SELECT
	_combat_manager.state_changed.connect(_on_state_changed)

	_refresh_all()
	_update_enemy_display()


# ── UI Refresh ────────────────────────────────────────────────────────────────

## Rebuilds all UI elements from the current CombatManager state.
func _refresh_all() -> void:
	_refresh_hand()
	_refresh_stats()


## Rebuilds the card buttons in HandArea from the current hand.
func _refresh_hand() -> void:
	for child: Node in hand_container.get_children():
		child.queue_free()

	var hand_cards: Array[Dictionary] = _combat_manager.hand

	# Apply sort order to a working copy without mutating CombatManager state
	var display_order: Array[int] = _sorted_indices(hand_cards)

	for display_pos: int in range(display_order.size()):
		var real_idx: int = display_order[display_pos]
		var card: Dictionary = hand_cards[real_idx]
		var btn: Button = _create_card_button(card, real_idx)
		hand_container.add_child(btn)

	_update_action_buttons()


## Creates a single card button for the given card dictionary and hand index.
## Minimum touch target: 64x90px (AC2, COMBAT-011).
func _create_card_button(card: Dictionary, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(64, 90)
	btn.toggle_mode = true
	btn.button_pressed = index in _selected_indices

	# Value label (J/Q/K/A abbreviations)
	var val_str: String = _value_label(card.get("value", 0) as int)

	# Suit/element icon — both shape and color for accessibility (AC9, COMBAT-011)
	var element: String = card.get("element", "") as String
	var icon_text: String = _element_icon(element)

	btn.text = "%s\n%s" % [val_str, icon_text]

	# Color tint by element (never sole differentiator — icon carries shape too)
	btn.modulate = _element_color(element).lerp(Color.WHITE, 0.5)

	# Store real index as metadata so card-rise animation can find this button.
	btn.set_meta("card_index", index)

	btn.toggled.connect(func(pressed: bool) -> void:
		_on_card_toggled(index, pressed)
	)

	# Button press feedback: scale to 0.95 on press, spring back on release.
	btn.button_down.connect(func() -> void:
		var t: Tween = btn.create_tween()
		t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08) \
			.set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		Fx.pop_scale(btn, 1.05, 0.25)
	)

	return btn


## Refreshes score, HP bar, and counter labels from CombatManager.
func _refresh_stats() -> void:
	var cs: Dictionary = _combat_manager.get_state()
	var current: int  = cs.get("current_score", 0) as int
	var threshold: int = cs.get("score_threshold", 1) as int
	var remaining: int = maxi(0, threshold - current)

	score_label.text = "%s / %s" % [_format_number(current), _format_number(threshold)]

	# HP bar represents how far the player still needs to go (AC5, COMBAT-011)
	if threshold > 0:
		var ratio: float = float(remaining) / float(threshold)
		_tween_hp_bar(ratio * 100.0)
	hp_label.text = "%s / %s" % [_format_number(remaining), _format_number(threshold)]

	hands_label.text    = "%d" % (cs.get("hands_remaining", 0) as int)
	discards_label.text = "%d" % (cs.get("discards_remaining", 0) as int)


## Tweens the HP bar to [param target_value] with a 600ms ease-out (AC5, COMBAT-011).
func _tween_hp_bar(target_value: float) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(hp_bar, "value", target_value, HP_TWEEN_DURATION)


## Updates the enemy name label from the arrival config.
func _update_enemy_display() -> void:
	var name_key: String = _enemy_config.get("name_key", "") as String
	if name_key.is_empty():
		enemy_name_label.text = "Enemy"
	else:
		enemy_name_label.text = Localization.get_text(name_key)


## Enables/disables PLAY and DISCARD buttons based on current selection and state.
func _update_action_buttons() -> void:
	var sel: int = _selected_indices.size()
	var cs: Dictionary = _combat_manager.get_state()
	var hands: int = cs.get("hands_remaining", 0) as int
	var discards: int = cs.get("discards_remaining", 0) as int
	var state: int = cs.get("state", CombatManagerScript.State.DEFEAT) as int
	var in_select: bool = (state == CombatManagerScript.State.SELECT)

	play_btn.disabled = (sel == 0) or (hands <= 0) or not in_select
	discard_btn.disabled = (sel == 0) or (discards <= 0) or not in_select

	play_btn.text    = "PLAY %d" % sel if sel > 0 else "PLAY HAND"
	discard_btn.text = "DISC %d" % sel if sel > 0 else "DISCARD"


## Plays a short score cascade animation then refreshes stats.
## Total cascade must not exceed 2s (AC4, COMBAT-011).
func _animate_score_cascade(result: Dictionary, played_count: int) -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/combat/card_play.ogg")
	# Flash the hand container white as cards "fly" to center.
	Fx.flash(hand_container, Color(1.0, 1.0, 1.0, 0.6), 0.12)

	chips_label.text = str(result.get("chips", 0) as int)
	mult_label.text  = "%.1f" % (result.get("mult", 1.0) as float)

	# Pulse chips and mult labels to draw attention.
	Fx.pop_scale(chips_label, 1.25, 0.3)
	Fx.pop_scale(mult_label,  1.25, 0.3)

	# Per-card step: SCORE_CASCADE_STEP seconds each, capped so total ≤ 2s
	var step_duration: float = minf(SCORE_CASCADE_STEP, 2.0 / maxf(1.0, float(played_count)))
	var tween: Tween = create_tween()
	tween.set_parallel(false)
	for _i: int in range(played_count):
		tween.tween_interval(step_duration)

	await tween.finished

	# Snapshot old score before _refresh_stats overwrites the label.
	var old_score: int = _displayed_score
	_refresh_stats()

	# Count-up the score label to the new value and pulse it on landing.
	var cs: Dictionary = _combat_manager.get_state()
	var new_score: int = cs.get("current_score", 0) as int
	_displayed_score = new_score
	Fx.count_to(score_label, old_score, new_score, 0.4)
	await get_tree().create_timer(0.4).timeout
	Fx.pulse(score_label, 1.2, 0.35)


# ── Player Actions ────────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	if _selected_indices.is_empty():
		return
	var indices: Array[int] = _selected_indices.duplicate()
	_selected_indices.clear()

	var result: Dictionary = _combat_manager.play_hand(indices)
	if result.is_empty():
		# Rejected by CombatManager (wrong state, no hands left, etc.)
		_refresh_hand()
		return

	_animate_score_cascade(result, indices.size())
	# State transitions (VICTORY/DEFEAT/SELECT) handled via _on_state_changed


func _on_discard_pressed() -> void:
	if _selected_indices.is_empty():
		return
	var indices: Array[int] = _selected_indices.duplicate()
	_selected_indices.clear()
	_combat_manager.discard(indices)
	# CombatManager emits state_changed → _on_state_changed → _refresh_all


func _on_sort_pressed() -> void:
	_sort_mode = SORT_SUIT if _sort_mode == SORT_VALUE else SORT_VALUE
	sort_btn.text = "SUIT ↕" if _sort_mode == SORT_SUIT else "RANK ↕"
	_refresh_hand()


## Show retreat confirmation popup.
func _on_back_pressed() -> void:
	retreat_confirm.visible = true

## Confirmed retreat — return to Hub without rewards.
func _on_retreat_confirm_yes() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)

## Cancel retreat — close popup and continue fighting.
func _on_retreat_confirm_no() -> void:
	retreat_confirm.visible = false


func _on_card_toggled(index: int, pressed: bool) -> void:
	if pressed:
		if not index in _selected_indices:
			_selected_indices.append(index)
	else:
		_selected_indices.erase(index)
	_update_action_buttons()

	# Animate card rise/drop with a bounce tween on the matching button.
	# Buttons are laid out in display order; find the one whose real index matches.
	for btn: Node in hand_container.get_children():
		var meta_index: int = btn.get_meta("card_index", -1) as int
		if meta_index == index:
			var target_y: float = btn.position.y + (CARD_SELECTED_RISE_PX * (-1.0 if pressed else 1.0))
			var t: Tween = btn.create_tween()
			t.tween_property(btn, "position:y", target_y, 0.18) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			break


## Called when the Victory overlay's "Continue" button is pressed.
func _on_victory_continue_pressed() -> void:
	GameStore.add_gold(VICTORY_GOLD_REWARD)
	GameStore.add_xp(VICTORY_XP_REWARD)

	# Check if this was a story combat — apply story node flags
	var story_node: String = _enemy_config.get("story_node", "") as String
	if story_node == "ch01_n00":
		# Tutorial combat done — set flag and play rescue cutscene
		GameStore.set_flag("ch01_tutorial_done")
		# After tutorial combat: pistol runs out, Artemis saves, player collapses
		SceneManager.change_scene(
			SceneManager.SceneId.DIALOGUE,
			SceneManager.TransitionType.FADE,
			{"chapter_id": "ch01", "sequence_id": "crash_rescue", "story_node": "ch01_crash"}
		)
	elif not story_node.is_empty():
		# Story combat — apply rewards and return to chapter map
		_apply_story_rewards(story_node)
		SceneManager.change_scene(SceneManager.SceneId.CHAPTER_MAP)
	else:
		# Arena/free combat — go to Hub
		SceneManager.change_scene(SceneManager.SceneId.HUB)


## Look up story node rewards from ch01.json and apply them.
## Applies gold, xp, flags, and meet effects. Stacks on top of the base
## VICTORY_GOLD_REWARD / VICTORY_XP_REWARD already granted by the caller.
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


## Called when the Defeat overlay's "Retry" button is pressed.
func _on_defeat_retry_pressed() -> void:
	# Restart the combat encounter with a fresh CombatManager (AC4, COMBAT-012)
	victory_overlay.visible = false
	defeat_overlay.visible = false

	_selected_indices.clear()

	# Read the previous captain id from arrival context, not from the old
	# CombatManager (which may have been freed or reinitialized).
	var captain_id: String = ""
	if _combat_manager != null:
		var prev_ctx: Dictionary = _combat_manager._captain_context as Dictionary
		captain_id = prev_ctx.get("captain_id", "") as String
	if captain_id.is_empty():
		captain_id = GameStore.get_last_captain_id()
	var captain_ctx: Dictionary = _build_captain_context(captain_id)

	_combat_manager = CombatManagerScript.new()
	_combat_manager.state_changed.connect(_on_state_changed)
	var ok: bool = _combat_manager.setup(_enemy_config, captain_ctx, GameStore, EventBus)
	if not ok:
		push_error("combat.gd: CombatManager.setup() failed on retry.")
		return
	_refresh_all()


## Called when the Defeat overlay's "Retreat" button is pressed.
func _on_defeat_retreat_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── CombatManager Signal Callbacks ────────────────────────────────────────────

func _on_state_changed(new_state: int) -> void:
	match new_state:
		CombatManagerScript.State.SELECT:
			_refresh_all()
		CombatManagerScript.State.VICTORY:
			_refresh_stats()
			_play_victory_animation()
		CombatManagerScript.State.DEFEAT:
			_refresh_stats()
			_play_defeat_animation()
		_:
			pass


## White flash → overlay appears → gold title springs up → gentle pulse loop.
func _play_victory_animation() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/combat/victory_chime.ogg")
	AudioManager.play_bgm("res://assets/audio/bgm/victory.ogg")
	# Brief full-screen white flash on this Control root.
	Fx.flash(self, Color(1.0, 1.0, 1.0, 0.85), 0.12)
	await get_tree().create_timer(0.12).timeout

	victory_overlay.visible = true
	victory_overlay.modulate.a = 0.0

	var show_tween: Tween = create_tween()
	show_tween.tween_property(victory_overlay, "modulate:a", 1.0, 0.25)
	await show_tween.finished

	# Find and animate the first Label inside the victory overlay.
	for child: Node in victory_overlay.get_children():
		if child is Label:
			var lbl: Label = child as Label
			lbl.scale = Vector2(0.3, 0.3)
			Fx.pop_scale(lbl, 1.15, 0.5)
			await get_tree().create_timer(0.55).timeout
			# Gentle endless pulse so the overlay feels alive.
			var pulse_loop: Tween = lbl.create_tween().set_loops()
			pulse_loop.tween_property(lbl, "scale", Vector2(1.04, 1.04), 0.9) \
				.set_ease(Tween.EASE_IN_OUT)
			pulse_loop.tween_property(lbl, "scale", Vector2.ONE, 0.9) \
				.set_ease(Tween.EASE_IN_OUT)
			break


## Dim scene to 60 % → overlay fades in softly.
func _play_defeat_animation() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/combat/defeat_thud.ogg")
	AudioManager.play_bgm("res://assets/audio/bgm/defeat.ogg")
	# Dim the combat area (everything except the overlay itself).
	Fx.dim(self, 0.6, 0.7)
	await get_tree().create_timer(0.5).timeout

	defeat_overlay.visible = true
	defeat_overlay.modulate.a = 0.0
	var show_tween: Tween = create_tween()
	show_tween.tween_property(defeat_overlay, "modulate:a", 1.0, 0.6) \
		.set_ease(Tween.EASE_IN)
	# Restore root modulate so the overlay itself isn't dimmed.
	show_tween.parallel().tween_property(self, "modulate:a", 1.0, 0.1)


# ── Blessing HUD ─────────────────────────────────────────────────────────────

## Builds the blessing icon strip above the hand container (DB-005).
## Shows one small label per active blessing slot for the current captain.
func _build_blessing_strip() -> void:
	_blessing_strip = HBoxContainer.new()
	_blessing_strip.add_theme_constant_override("separation", 4)
	_blessing_strip.alignment = BoxContainer.ALIGNMENT_CENTER

	# Insert just before the hand container so it sits above the cards.
	var parent: Node = hand_container.get_parent()
	if parent != null:
		var hand_idx: int = hand_container.get_index()
		parent.add_child(_blessing_strip)
		parent.move_child(_blessing_strip, hand_idx)

	_populate_blessing_icons()


## Fills the blessing strip with icons for the current captain's active blessings.
func _populate_blessing_icons() -> void:
	for child: Node in _blessing_strip.get_children():
		child.queue_free()

	var captain_id: String = _enemy_config.get("captain_id", "") as String
	if captain_id.is_empty():
		# Try from the captain context
		if _combat_manager != null:
			captain_id = _combat_manager._captain_context.get("captain_id", "") as String
	if captain_id.is_empty():
		return

	var stage: int = CompanionState.get_romance_stage(captain_id)
	var blessings: Array[Dictionary] = BlessingSystem.get_blessing_info(captain_id)

	for blessing: Dictionary in blessings:
		var slot: int = blessing.get("slot", 0) as int
		var active: bool = slot <= _max_blessing_slot(stage)
		var trigger: String = blessing.get("trigger_type", "always") as String

		var icon: Label = Label.new()
		icon.custom_minimum_size = Vector2(28.0, 28.0)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 12)

		if active:
			icon.text = _blessing_icon(trigger)
			icon.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
			icon.tooltip_text = blessing.get("name", "Blessing %d" % slot)
		else:
			icon.text = "?"
			icon.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
			icon.tooltip_text = "Locked (Stage %d)" % slot

		_blessing_strip.add_child(icon)


## Returns the max active slot for a given romance stage (mirrors BlessingSystem).
func _max_blessing_slot(stage: int) -> int:
	match stage:
		0: return 0
		1: return 1
		2: return 2
		3: return 4
		4: return 5
		_: return 0


## Returns a short icon glyph for a blessing trigger type.
func _blessing_icon(trigger: String) -> String:
	match trigger:
		"always": return "★"
		"per_card": return "♦"
		"suit_count": return "♣"
		"hand_rank_min": return "♠"
		"signature_card": return "♥"
		"accumulated_chips_min": return "▲"
		"current_score_gate": return "◆"
		"heart_flush": return "❤"
		_: return "●"


# ── Private Helpers ───────────────────────────────────────────────────────────

## Builds the captain scoring context from CompanionRegistry + GameStore.
## Returns safe zero-value context when captain_id is empty.
func _build_captain_context(captain_id: String) -> Dictionary:
	var profile: Dictionary = {}
	if not captain_id.is_empty():
		profile = CompanionRegistry.get_profile(captain_id)

	var strength: int = profile.get("STR", 0) as int
	var intel: int    = profile.get("INT", 0) as int

	# Capture social buff from GameStore (frozen at SETUP — ADR-0007 AC4/COMBAT-009)
	var buff: Dictionary = GameStore.get_combat_buff()
	var buff_chips: int   = buff.get("chips", 0) as int
	var buff_mult: float  = buff.get("mult", 0.0) as float

	# Freeze romance_stages snapshot (ADR-0007 AC5/COMBAT-009)
	var romance_stages: Dictionary = {}

	return {
		"captain_id":            captain_id,
		"captain_chip_bonus":    floori(strength * DeckManager.CHIP_BONUS_MULTIPLIER),
		"captain_mult_modifier": 1.0 + intel * DeckManager.MULT_BONUS_INCREMENT,
		"social_buff_chips":     buff_chips,
		"social_buff_mult":      buff_mult,
		"romance_stages":        romance_stages,
	}


## Returns a fallback enemy config when none is provided via arrival context.
func _default_enemy_config() -> Dictionary:
	return {
		"score_threshold":  40,
		"hands_allowed":    4,
		"discards_allowed": 4,
		"element":          "",
		"name_key":         "Unknown Enemy",
	}


## Returns sorted display indices for hand_cards without mutating the array.
## SORT_VALUE: ascending card value.
## SORT_SUIT: Hearts→Diamonds→Clubs→Spades, then ascending value within each suit.
func _sorted_indices(hand_cards: Array[Dictionary]) -> Array[int]:
	var indices: Array[int] = []
	for i: int in range(hand_cards.size()):
		indices.append(i)

	if _sort_mode == SORT_SUIT:
		var suit_order: Dictionary = {"Hearts": 0, "Diamonds": 1, "Clubs": 2, "Spades": 3}
		indices.sort_custom(func(a: int, b: int) -> bool:
			var ca: Dictionary = hand_cards[a]
			var cb: Dictionary = hand_cards[b]
			var sa: int = suit_order.get(ca.get("suit", ""), 4) as int
			var sb: int = suit_order.get(cb.get("suit", ""), 4) as int
			if sa != sb:
				return sa < sb
			return (ca.get("value", 0) as int) < (cb.get("value", 0) as int)
		)
	else:
		indices.sort_custom(func(a: int, b: int) -> bool:
			return (hand_cards[a].get("value", 0) as int) < (hand_cards[b].get("value", 0) as int)
		)

	return indices


## Converts a numeric card value to its display string.
func _value_label(v: int) -> String:
	match v:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(v)


## Returns a shape+label icon for an element (color never sole differentiator — AC9).
func _element_icon(element: String) -> String:
	match element:
		"Fire":      return "[F]"
		"Water":     return "[W]"
		"Earth":     return "[E]"
		"Lightning": return "[L]"
		_:           return "[ ]"


## Returns the tint color for an element.
func _element_color(element: String) -> Color:
	match element:
		"Fire":      return Color("#F24D26")
		"Water":     return Color("#338CF2")
		"Earth":     return Color("#73BF40")
		"Lightning": return Color("#CCaa33")
		_:           return Color.WHITE


## Formats large integers with K/M suffixes for display.
func _format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
