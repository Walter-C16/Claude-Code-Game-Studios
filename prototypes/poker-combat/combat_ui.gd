# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does chips x mult poker combat feel satisfying on 430x932 touch?
# Date: 2026-04-10

extends Control

# --- Enemy data (hardcoded) ---
const ENEMIES := [
	{"name": "Forest Monster", "threshold": 40, "element": PokerLogic.Element.NONE, "color": Color("#4a7a4a")},
	{"name": "Cyclops", "threshold": 100, "element": PokerLogic.Element.FIRE, "color": Color("#8a3a2a")},
	{"name": "Gaia Spirit", "threshold": 130, "element": PokerLogic.Element.EARTH, "color": Color("#3a6a3a")},
]

# Hardcoded captain: Hipolita (STR=20, INT=9)
const CAPTAIN_STR := 20
const CAPTAIN_INT := 9
const CAPTAIN_NAME := "Hipolita"

# Combat state
var deck: Array[PokerLogic.Card] = []
var hand: Array[PokerLogic.Card] = []
var selected: Array[bool] = []
var current_score := 0
var hands_remaining := 4
var discards_remaining := 4
var current_enemy_idx := 0
var combat_active := false
var animating := false

# UI references
var card_buttons: Array[Button] = []
var enemy_label: Label
var score_label: Label
var threshold_bar: ProgressBar
var hands_label: Label
var discards_label: Label
var play_btn: Button
var discard_btn: Button
var next_btn: Button
var result_label: Label
var score_breakdown: RichTextLabel
var hand_rank_label: Label
var captain_label: Label
var sort_btn: Button
var sort_by_value := true

# Score animation
var anim_tween: Tween
var displayed_score := 0


func _ready() -> void:
	_build_ui()
	_start_encounter()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color("#1a1210")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Main container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.set("offset_left", 12)
	vbox.set("offset_right", -12)
	vbox.set("offset_top", 20)
	vbox.set("offset_bottom", -20)
	add_child(vbox)

	# Enemy section
	enemy_label = Label.new()
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 22)
	enemy_label.add_theme_color_override("font_color", Color("#D4A843"))
	vbox.add_child(enemy_label)

	threshold_bar = ProgressBar.new()
	threshold_bar.custom_minimum_size = Vector2(0, 30)
	threshold_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color("#3a2a1a")
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	threshold_bar.add_theme_stylebox_override("background", bar_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#D4A843")
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	threshold_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(threshold_bar)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color("#F5E6C8"))
	vbox.add_child(score_label)

	# Captain info
	captain_label = Label.new()
	captain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	captain_label.add_theme_font_size_override("font_size", 14)
	captain_label.add_theme_color_override("font_color", Color("#aa8855"))
	captain_label.text = "Captain: %s (STR %d / INT %d)" % [CAPTAIN_NAME, CAPTAIN_STR, CAPTAIN_INT]
	vbox.add_child(captain_label)

	# Hand rank display
	hand_rank_label = Label.new()
	hand_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_rank_label.add_theme_font_size_override("font_size", 20)
	hand_rank_label.add_theme_color_override("font_color", Color("#D4A843"))
	hand_rank_label.text = ""
	vbox.add_child(hand_rank_label)

	# Score breakdown
	score_breakdown = RichTextLabel.new()
	score_breakdown.custom_minimum_size = Vector2(0, 60)
	score_breakdown.bbcode_enabled = true
	score_breakdown.fit_content = true
	score_breakdown.add_theme_font_size_override("normal_font_size", 14)
	score_breakdown.add_theme_color_override("default_color", Color("#F5E6C8"))
	vbox.add_child(score_breakdown)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Card hand area
	var card_container := HBoxContainer.new()
	card_container.custom_minimum_size = Vector2(0, 180)
	card_container.add_theme_constant_override("separation", 6)
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(card_container)

	for i in range(5):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 170)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 14)
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#2a1f14")
		normal_style.border_color = Color("#5a4a3a")
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", normal_style)
		btn.add_theme_stylebox_override("focus", normal_style)
		var pressed_style := normal_style.duplicate()
		pressed_style.bg_color = Color("#4a3a2a")
		pressed_style.border_color = Color("#D4A843")
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.pressed.connect(_on_card_pressed.bind(i))
		card_container.add_child(btn)
		card_buttons.append(btn)

	# Sort toggle
	sort_btn = Button.new()
	sort_btn.text = "Sort: Value"
	sort_btn.custom_minimum_size = Vector2(0, 36)
	sort_btn.add_theme_font_size_override("font_size", 14)
	sort_btn.pressed.connect(_on_sort_pressed)
	vbox.add_child(sort_btn)

	# Hands / Discards counters
	var counter_row := HBoxContainer.new()
	counter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	counter_row.add_theme_constant_override("separation", 40)
	vbox.add_child(counter_row)

	hands_label = Label.new()
	hands_label.add_theme_font_size_override("font_size", 16)
	hands_label.add_theme_color_override("font_color", Color("#6a9fd8"))
	counter_row.add_child(hands_label)

	discards_label = Label.new()
	discards_label.add_theme_font_size_override("font_size", 16)
	discards_label.add_theme_color_override("font_color", Color("#d86a6a"))
	counter_row.add_child(discards_label)

	# Action buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	play_btn = _make_action_button("PLAY HAND", Color("#3a6a3a"))
	play_btn.pressed.connect(_on_play_pressed)
	play_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_row.add_child(play_btn)

	discard_btn = _make_action_button("DISCARD", Color("#6a3a3a"))
	discard_btn.pressed.connect(_on_discard_pressed)
	discard_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_row.add_child(discard_btn)

	# Result / Next
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	result_label.visible = false
	vbox.add_child(result_label)

	next_btn = _make_action_button("NEXT ENEMY", Color("#3a4a6a"))
	next_btn.pressed.connect(_on_next_pressed)
	next_btn.visible = false
	vbox.add_child(next_btn)


func _make_action_button(text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	var pressed_style := style.duplicate()
	pressed_style.bg_color = bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	return btn


# --- Combat Flow ---

func _start_encounter() -> void:
	var enemy: Dictionary = ENEMIES[current_enemy_idx]
	deck = PokerLogic.create_deck()
	hand.clear()
	selected = [false, false, false, false, false]
	current_score = 0
	displayed_score = 0
	hands_remaining = 4
	discards_remaining = 4
	combat_active = true
	animating = false

	enemy_label.text = "%s  (HP: %d)" % [enemy["name"], enemy["threshold"]]
	if enemy["element"] != PokerLogic.Element.NONE:
		var elem_names := {
			PokerLogic.Element.FIRE: "Fire",
			PokerLogic.Element.WATER: "Water",
			PokerLogic.Element.EARTH: "Earth",
			PokerLogic.Element.LIGHTNING: "Lightning",
		}
		enemy_label.text += "  [%s]" % elem_names[enemy["element"]]

	threshold_bar.max_value = enemy["threshold"]
	threshold_bar.value = 0
	score_label.text = "0 / %d" % enemy["threshold"]
	hand_rank_label.text = ""
	score_breakdown.text = ""
	result_label.visible = false
	next_btn.visible = false
	play_btn.visible = true
	discard_btn.visible = true
	sort_btn.visible = true

	_draw_hand()
	_update_counters()


func _draw_hand() -> void:
	hand.clear()
	var draw_count := mini(5, deck.size())
	for i in range(draw_count):
		hand.append(deck.pop_front())
	selected = []
	for i in range(hand.size()):
		selected.append(false)
	_sort_hand()
	_update_cards()
	_update_hand_preview()


func _sort_hand() -> void:
	if sort_by_value:
		hand.sort_custom(func(a: PokerLogic.Card, b: PokerLogic.Card) -> bool: return a.value < b.value)
	else:
		hand.sort_custom(func(a: PokerLogic.Card, b: PokerLogic.Card) -> bool:
			if a.suit != b.suit:
				return a.suit < b.suit
			return a.value < b.value
		)


func _update_cards() -> void:
	for i in range(5):
		if i < hand.size():
			var card: PokerLogic.Card = hand[i]
			card_buttons[i].text = "%s\n%s" % [PokerLogic.VALUE_NAMES[card.value], PokerLogic.SUIT_SYMBOLS[card.suit]]
			card_buttons[i].visible = true
			card_buttons[i].add_theme_color_override("font_color", card.get_color())
			_update_card_style(i)
		else:
			card_buttons[i].visible = false


func _update_card_style(idx: int) -> void:
	var card: PokerLogic.Card = hand[idx]
	var style: StyleBoxFlat = card_buttons[idx].get_theme_stylebox("normal").duplicate()
	if selected[idx]:
		style.bg_color = Color("#4a3a2a")
		style.border_color = Color("#D4A843")
		style.border_width_bottom = 3
		style.border_width_top = 3
		style.border_width_left = 3
		style.border_width_right = 3
		card_buttons[idx].position.y = -12
	else:
		style.bg_color = Color("#2a1f14")
		style.border_color = Color("#5a4a3a")
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		card_buttons[idx].position.y = 0
	card_buttons[idx].add_theme_stylebox_override("normal", style)
	card_buttons[idx].add_theme_stylebox_override("hover", style)
	card_buttons[idx].add_theme_stylebox_override("focus", style)


func _update_counters() -> void:
	hands_label.text = "Hands: %d" % hands_remaining
	discards_label.text = "Discards: %d" % discards_remaining
	play_btn.disabled = _selected_count() == 0 or hands_remaining <= 0 or animating
	discard_btn.disabled = _selected_count() == 0 or discards_remaining <= 0 or animating


func _selected_count() -> int:
	var count := 0
	for s in selected:
		if s:
			count += 1
	return count


func _get_selected_cards() -> Array[PokerLogic.Card]:
	var cards: Array[PokerLogic.Card] = []
	for i in range(hand.size()):
		if selected[i]:
			cards.append(hand[i])
	return cards


func _update_hand_preview() -> void:
	var cards := _get_selected_cards()
	if cards.is_empty():
		hand_rank_label.text = ""
		score_breakdown.text = ""
		return
	var eval_result := PokerLogic.evaluate_hand(cards)
	hand_rank_label.text = eval_result["rank"]


# --- Input Handlers ---

func _on_card_pressed(idx: int) -> void:
	if not combat_active or animating:
		return
	if idx >= hand.size():
		return
	selected[idx] = not selected[idx]
	_update_card_style(idx)
	_update_counters()
	_update_hand_preview()


func _on_play_pressed() -> void:
	if not combat_active or animating or _selected_count() == 0:
		return

	var cards := _get_selected_cards()
	var enemy: Dictionary = ENEMIES[current_enemy_idx]
	var result := PokerLogic.calculate_score(cards, enemy["element"], CAPTAIN_STR, CAPTAIN_INT)

	hands_remaining -= 1
	animating = true
	_update_counters()

	# Show breakdown
	var breakdown := "[color=#D4A843]%s[/color]\n" % result["rank"]
	breakdown += "[color=#6a9fd8]Chips:[/color] %d base + %d cards" % [result["base_chips"], result["per_card_chips"]]
	if result["element_chips"] != 0:
		var sign := "+" if result["element_chips"] > 0 else ""
		breakdown += " %s%d elem" % [sign, result["element_chips"]]
	if result["captain_chip_bonus"] > 0:
		breakdown += " +%d captain" % result["captain_chip_bonus"]
	breakdown += " = [color=#F5E6C8]%d[/color]\n" % result["total_chips"]

	breakdown += "[color=#d86a6a]Mult:[/color] %.1fx base" % result["base_mult"]
	if result["element_mult"] > 0:
		breakdown += " +%.1f elem" % result["element_mult"]
	breakdown += " x%.3f captain" % result["captain_mult_mod"]
	breakdown += " = [color=#F5E6C8]%.2fx[/color]\n" % result["final_mult"]

	breakdown += "[color=#D4A843]Score: %d x %.2f = %d[/color]" % [result["total_chips"], result["final_mult"], result["score"]]
	score_breakdown.text = breakdown

	# Remove played cards from hand
	var new_hand: Array[PokerLogic.Card] = []
	for i in range(hand.size()):
		if not selected[i]:
			new_hand.append(hand[i])
	hand = new_hand
	selected.clear()
	for i in range(hand.size()):
		selected.append(false)

	# Animate score
	var old_score := current_score
	current_score += result["score"]
	_animate_score(old_score, current_score, enemy["threshold"])


func _animate_score(from: int, to: int, threshold: int) -> void:
	if anim_tween:
		anim_tween.kill()
	anim_tween = create_tween()
	anim_tween.set_ease(Tween.EASE_OUT)
	anim_tween.set_trans(Tween.TRANS_CUBIC)
	anim_tween.tween_method(func(val: float) -> void:
		displayed_score = roundi(val)
		score_label.text = "%d / %d" % [displayed_score, threshold]
		threshold_bar.value = mini(displayed_score, threshold)
		if displayed_score >= threshold:
			score_label.add_theme_color_override("font_color", Color("#D4A843"))
		, float(from), float(to), 0.8)
	anim_tween.tween_callback(_on_score_anim_done)


func _on_score_anim_done() -> void:
	animating = false
	var enemy: Dictionary = ENEMIES[current_enemy_idx]

	# Victory check (before defeat)
	if current_score >= enemy["threshold"]:
		_end_combat(true)
		return

	# Defeat check
	if hands_remaining <= 0:
		_end_combat(false)
		return

	# Continue: draw new hand
	_draw_hand()
	_update_counters()


func _on_discard_pressed() -> void:
	if not combat_active or animating or _selected_count() == 0 or discards_remaining <= 0:
		return

	discards_remaining -= 1

	# Remove discarded cards
	var keep: Array[PokerLogic.Card] = []
	for i in range(hand.size()):
		if not selected[i]:
			keep.append(hand[i])

	# Draw replacements
	var need := 5 - keep.size()
	var draw := mini(need, deck.size())
	for i in range(draw):
		keep.append(deck.pop_front())

	hand = keep
	selected.clear()
	for i in range(hand.size()):
		selected.append(false)
	_sort_hand()
	_update_cards()
	_update_counters()
	_update_hand_preview()


func _on_sort_pressed() -> void:
	sort_by_value = not sort_by_value
	sort_btn.text = "Sort: %s" % ("Value" if sort_by_value else "Suit")
	_sort_hand()
	selected.clear()
	for i in range(hand.size()):
		selected.append(false)
	_update_cards()
	_update_counters()
	_update_hand_preview()


func _end_combat(victory: bool) -> void:
	combat_active = false
	play_btn.visible = false
	discard_btn.visible = false
	sort_btn.visible = false

	if victory:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color("#D4A843"))
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color("#d86a6a"))

	result_label.visible = true

	if victory and current_enemy_idx < ENEMIES.size() - 1:
		next_btn.text = "NEXT ENEMY"
		next_btn.visible = true
	elif not victory:
		next_btn.text = "RETRY"
		next_btn.visible = true
	else:
		next_btn.text = "RESTART (All defeated!)"
		next_btn.visible = true


func _on_next_pressed() -> void:
	if result_label.text == "DEFEAT":
		# Retry same enemy
		pass
	elif current_enemy_idx < ENEMIES.size() - 1:
		current_enemy_idx += 1
	else:
		current_enemy_idx = 0

	_start_encounter()
