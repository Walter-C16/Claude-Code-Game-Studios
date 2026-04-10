extends Node

signal line_changed
signal choices_presented(choices: Array)
signal dialogue_ended

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var active: bool = false
var dialogue_id: String = ""
var nodes: Dictionary = {}
var current_node_id: String = ""
var current_line_index: int = 0

# ---------------------------------------------------------------------------
# Derived (updated when state changes)
# ---------------------------------------------------------------------------
var is_choice_node: bool = false
var current_lines: Array = []
var current_choices: Array = []

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
func start_dialogue(id: String, nodes_dict: Dictionary, start_node: String = "start") -> void:
	dialogue_id = id
	nodes = nodes_dict
	current_node_id = start_node
	current_line_index = 0
	active = true
	_update_current_node()

func advance_line() -> bool:
	"""Advance to next line in current node. Returns false when node ends."""
	current_line_index += 1
	if current_line_index >= current_lines.size():
		# Node lines exhausted
		if is_choice_node:
			# Wait for choice selection
			choices_presented.emit(current_choices)
			return false
		else:
			# Auto-advance to next node
			var next_id: String = _get_current_node().get("next", "")
			if next_id.is_empty():
				end_dialogue()
				return false
			current_node_id = next_id
			current_line_index = 0
			_update_current_node()
			line_changed.emit()
			return true
	line_changed.emit()
	return true

func select_choice(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return
	var choice: Dictionary = current_choices[index]
	# Apply effects
	if choice.has("effects"):
		for fx in choice["effects"]:
			_apply_effect(fx)
	# Navigate to next node
	var next_id: String = choice.get("next", "")
	if next_id.is_empty():
		end_dialogue()
		return
	current_node_id = next_id
	current_line_index = 0
	_update_current_node()
	line_changed.emit()

func get_current_line() -> Dictionary:
	if current_line_index < current_lines.size():
		return current_lines[current_line_index]
	return {}

func end_dialogue() -> void:
	active = false
	dialogue_id = ""
	nodes.clear()
	current_node_id = ""
	current_line_index = 0
	current_lines.clear()
	current_choices.clear()
	is_choice_node = false
	dialogue_ended.emit()

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------
func _get_current_node() -> Dictionary:
	return nodes.get(current_node_id, {})

func _update_current_node() -> void:
	var node: Dictionary = _get_current_node()
	current_lines = node.get("lines", [])
	current_choices = node.get("choices", [])
	is_choice_node = current_choices.size() > 0

func _apply_effect(fx: Dictionary) -> void:
	match fx.get("type", ""):
		"relationship":
			# Legacy stub — RomanceSocial will own this in Sprint 2.
			# For now, write directly via the internal setter.
			var id: String = fx.get("companion", "")
			var delta: int = fx.get("value", 0)
			var current: int = GameStore.get_relationship_level(id)
			GameStore._set_relationship_level(id, current + delta)
		"trust":
			var id: String = fx.get("companion", "")
			GameStore.set_trust(id, fx.get("value", 0))
		"flag":
			var key: String = fx.get("key", "")
			if not key.is_empty():
				GameStore.set_flag(key)
		"meet":
			var id: String = fx.get("companion", "")
			GameStore.set_met(id, true)
