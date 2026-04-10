extends Control

## Combat screen — poker card combat with hand evaluation and scoring.

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

func _ready() -> void:
	victory_overlay.visible = false
	defeat_overlay.visible = false

	CombatStore.hand_updated.connect(_refresh_hand)
	CombatStore.score_changed.connect(_refresh_stats)
	CombatStore.phase_changed.connect(_on_phase_changed)

	_refresh_hand()
	_refresh_stats()
	_update_enemy_display()

# ---------------------------------------------------------------------------
# UI Refresh
# ---------------------------------------------------------------------------

func _refresh_hand() -> void:
	# Clear old cards
	for child in hand_container.get_children():
		child.queue_free()

	# Create card buttons
	for i in range(CombatStore.hand.size()):
		var card: Dictionary = CombatStore.hand[i]
		var btn := _create_card_button(card, i)
		hand_container.add_child(btn)

	_update_buttons()

func _create_card_button(card: Dictionary, index: int) -> Button:
	var btn := Button.new()
	var suit_sym: String = Enums.SUIT_SYMBOLS.get(
		Enums.Suit.values()[card["element"]], "?"
	)
	var val_str := _value_label(card["value"])
	btn.text = "%s\n%s" % [val_str, suit_sym]
	btn.custom_minimum_size = Vector2(64, 96)
	btn.toggle_mode = true
	btn.button_pressed = index in CombatStore.selected_indices
	btn.toggled.connect(func(pressed: bool):
		CombatStore.toggle_card_selection(index)
		_update_buttons()
	)
	# Color by element
	var colors := [Color("#F24D26"), Color("#338CF2"), Color("#73BF40"), Color("#CCaa33")]
	var element: int = card.get("element", 0)
	if element < colors.size():
		btn.modulate = colors[element].lerp(Color.WHITE, 0.5)
	return btn

func _refresh_stats() -> void:
	var remaining: int = maxi(0, CombatStore.target_score - CombatStore.current_score)
	score_label.text = "%s / %s" % [
		_format_number(CombatStore.current_score),
		_format_number(CombatStore.target_score),
	]
	# HP bar
	if CombatStore.target_score > 0:
		hp_bar.value = float(remaining) / float(CombatStore.target_score) * 100.0
	hp_label.text = "%s / %s" % [_format_number(remaining), _format_number(CombatStore.target_score)]

	# Last hand result
	var result: Dictionary = CombatStore.last_hand_result
	mult_label.text = "%.1f" % result.get("mult", 1.0)
	chips_label.text = str(result.get("chips", 0))
	hands_label.text = "%d/%d" % [CombatStore.hands_remaining, Balance.POKER_COMBAT["default_hands"]]
	discards_label.text = "%d/%d" % [CombatStore.discards_remaining, Balance.POKER_COMBAT["default_discards"]]

func _update_enemy_display() -> void:
	var enemy: Dictionary = CombatStore.enemy
	enemy_name_label.text = DialogueRunner.get_text(enemy.get("name_key", "Enemy"))

func _update_buttons() -> void:
	var sel_count: int = CombatStore.selected_indices.size()
	play_btn.disabled = sel_count == 0 or CombatStore.hands_remaining <= 0
	discard_btn.disabled = sel_count == 0 or CombatStore.discards_remaining <= 0
	play_btn.text = "PLAY HAND" if sel_count == 0 else "PLAY %d" % sel_count
	discard_btn.text = "DISCARD" if sel_count == 0 else "DISC %d" % sel_count

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _on_play_pressed() -> void:
	if CombatStore.selected_indices.is_empty() or CombatStore.hands_remaining <= 0:
		return
	# Gather selected cards
	var played: Array = []
	for idx in CombatStore.selected_indices:
		if idx < CombatStore.hand.size():
			played.append(CombatStore.hand[idx])
	# Calculate score
	var result := CombatSystem.calculate_score(played, CombatStore.companion_id)
	CombatStore.play_hand(result)

func _on_discard_pressed() -> void:
	CombatStore.discard_selected()

func _on_sort_pressed() -> void:
	var next_mode := "suit" if CombatStore.sort_mode == "value" else "value"
	CombatStore.set_sort_mode(next_mode)
	sort_btn.text = "RANK ↕" if next_mode == "value" else "SUIT ↕"

func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		Enums.CombatPhase.VICTORY:
			victory_overlay.visible = true
		Enums.CombatPhase.DEFEAT:
			defeat_overlay.visible = true

func _on_victory_continue_pressed() -> void:
	CombatStore.reset_combat()
	if StoryFlow.active:
		StoryFlow.advance_step()
	else:
		GameStore.add_gold(50)  # TODO: read from data config when Balance system exists
		GameStore.add_xp(25)    # TODO: read from data config when Balance system exists
		SceneManager.change_scene(SceneManager.SceneId.HUB)

func _on_defeat_retreat_pressed() -> void:
	CombatStore.reset_combat()
	SceneManager.change_scene(SceneManager.SceneId.HUB)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _value_label(v: int) -> String:
	match v:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(v)

func _format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
