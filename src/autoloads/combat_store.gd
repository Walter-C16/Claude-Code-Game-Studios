extends Node

signal phase_changed(new_phase: int)
signal hand_updated
signal score_changed

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var phase: int = Enums.CombatPhase.DRAW
var deck: Array = []
var hand: Array = []
var selected_indices: Array[int] = []
var current_score: int = 0
var target_score: int = 0
var hands_remaining: int = Balance.POKER_COMBAT["default_hands"]
var discards_remaining: int = Balance.POKER_COMBAT["default_discards"]
var enemy: Dictionary = {}
var companion_id: String = ""
var last_hand_result: Dictionary = {}
var sort_mode: String = "value"
var ecstasy: float = 0.0
var max_ecstasy: float = 100.0

# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------
func init_combat(enemy_data: Dictionary, comp_id: String, deck_cards: Array) -> void:
	enemy = enemy_data
	companion_id = comp_id
	deck = deck_cards.duplicate()
	hand.clear()
	selected_indices.clear()
	current_score = 0
	target_score = enemy_data.get("hp", 300)
	hands_remaining = Balance.POKER_COMBAT["default_hands"]
	discards_remaining = Balance.POKER_COMBAT["default_discards"]
	last_hand_result = {}
	ecstasy = 0.0
	sort_mode = "value"
	# Shuffle and draw initial hand
	deck = CombatSystem.shuffle_array(deck)
	draw_hand()
	set_phase(Enums.CombatPhase.SELECT)

func draw_hand() -> void:
	var hand_size: int = Balance.POKER_COMBAT["default_hand_size"]
	while hand.size() < hand_size and deck.size() > 0:
		hand.append(deck.pop_front())
	_sort_hand()
	hand_updated.emit()

# ---------------------------------------------------------------------------
# Selection
# ---------------------------------------------------------------------------
func toggle_card_selection(index: int) -> void:
	if index in selected_indices:
		selected_indices.erase(index)
	elif selected_indices.size() < Balance.POKER_COMBAT["max_play_size"]:
		selected_indices.append(index)
	hand_updated.emit()

func clear_selection() -> void:
	selected_indices.clear()
	hand_updated.emit()

# ---------------------------------------------------------------------------
# Play / Discard
# ---------------------------------------------------------------------------
func play_hand(result: Dictionary) -> void:
	last_hand_result = result
	current_score += result.get("score", 0)
	hands_remaining -= 1
	# Remove played cards
	_remove_selected_cards()
	# Check win/lose
	if current_score >= target_score:
		set_phase(Enums.CombatPhase.VICTORY)
	elif hands_remaining <= 0 and discards_remaining <= 0:
		set_phase(Enums.CombatPhase.DEFEAT)
	else:
		draw_hand()
		set_phase(Enums.CombatPhase.SELECT)
	score_changed.emit()

func discard_selected() -> void:
	if discards_remaining <= 0:
		return
	discards_remaining -= 1
	_remove_selected_cards()
	draw_hand()
	hand_updated.emit()

func _remove_selected_cards() -> void:
	# Sort indices descending to avoid shift issues
	var sorted_idx := selected_indices.duplicate()
	sorted_idx.sort()
	sorted_idx.reverse()
	for idx in sorted_idx:
		if idx < hand.size():
			hand.remove_at(idx)
	selected_indices.clear()

# ---------------------------------------------------------------------------
# Sorting
# ---------------------------------------------------------------------------
func reorder_card(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= hand.size():
		return
	if to_idx < 0 or to_idx >= hand.size():
		return
	var card = hand[from_idx]
	hand.remove_at(from_idx)
	hand.insert(to_idx, card)
	hand_updated.emit()

func set_sort_mode(mode: String) -> void:
	sort_mode = mode
	_sort_hand()
	hand_updated.emit()

func _sort_hand() -> void:
	if sort_mode == "value":
		hand.sort_custom(func(a, b): return a["value"] > b["value"])
	else:
		hand.sort_custom(func(a, b):
			if a["suit"] == b["suit"]:
				return a["value"] > b["value"]
			return a["suit"] < b["suit"]
		)

# ---------------------------------------------------------------------------
# Phase
# ---------------------------------------------------------------------------
func set_phase(new_phase: int) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset_combat() -> void:
	phase = Enums.CombatPhase.DRAW
	deck.clear()
	hand.clear()
	selected_indices.clear()
	current_score = 0
	target_score = 0
	hands_remaining = 0
	discards_remaining = 0
	enemy = {}
	last_hand_result = {}
	ecstasy = 0.0
