extends Node

## StoryFlow — Chapter Node Sequencer (ADR-0011)
##
## Autoload #11. Orchestrates all story content: loads chapter JSON files,
## sequences nodes (dialogue, combat, companion_unlock, mixed, boss, reward),
## tracks node completion state, manages story flags, and distributes rewards.
##
## StoryFlow is the orchestrator — it calls other systems. Other systems
## (DialogueRunner, CombatSystem) NEVER call back into StoryFlow directly;
## all coordination flows through EventBus signals.
##
## NO class_name — autoload rule (memory/feedback_godot_class_name.md).
## Tests preload this file with: const Script = preload("res://autoloads/story_flow.gd")
##
## Boot order: Autoload #11. References autoloads 1-10 in _ready().
## Upstream ADRs: ADR-0001, ADR-0003, ADR-0004, ADR-0008, ADR-0009.
##
## State persisted in GameStore:
##   - node_states (node_id → "not_started"|"in_progress"|"completed")
##   - current_node_id
##   - story_flags
##   - player_gold, player_xp
##
## See: docs/architecture/adr-0011-story-flow.md

# ── Node State Constants ───────────────────────────────────────────────────────

const NODE_NOT_STARTED: String = "not_started"
const NODE_IN_PROGRESS: String = "in_progress"
const NODE_COMPLETED: String = "completed"

## Path template for chapter JSON files.
const CHAPTER_PATH_TEMPLATE: String = "res://assets/data/story/%s.json"

# ── Private State ──────────────────────────────────────────────────────────────

## The active chapter data dictionary loaded from JSON.
var _chapter: Dictionary = {}

## All nodes in the active chapter keyed by node_id.
var _nodes: Dictionary = {}

## The node_id being actively executed (in_progress).
var _active_node_id: String = ""

## Sequence ID expected from dialogue_ended signal for the current await.
var _awaiting_sequence_id: String = ""

## True while waiting for a combat result.
var _awaiting_combat: bool = false

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.combat_completed.connect(_on_combat_completed)

# ── Public API ─────────────────────────────────────────────────────────────────

## Loads a chapter JSON file from res://assets/data/story/{chapter_id}.json.
## Populates internal node map and initializes any missing node states in GameStore.
## Logs a warning and sets a "to_be_continued" state on load failure.
func load_chapter(chapter_id: String) -> void:
	var path: String = CHAPTER_PATH_TEMPLATE % chapter_id
	if not FileAccess.file_exists(path):
		push_warning("[StoryFlow] Chapter file not found: %s" % path)
		_chapter = {"id": chapter_id, "nodes": [], "_state": "to_be_continued"}
		_nodes = {}
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[StoryFlow] Failed to open chapter file: %s" % path)
		_chapter = {"id": chapter_id, "nodes": [], "_state": "to_be_continued"}
		_nodes = {}
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null or not parsed is Dictionary:
		push_warning("[StoryFlow] Failed to parse chapter JSON: %s" % path)
		_chapter = {"id": chapter_id, "nodes": [], "_state": "to_be_continued"}
		_nodes = {}
		return

	_chapter = parsed as Dictionary
	_nodes = {}
	var node_list: Array = _chapter.get("nodes", [])
	for item: Variant in node_list:
		if item is Dictionary:
			var node: Dictionary = item as Dictionary
			var nid: String = node.get("id", "")
			if not nid.is_empty():
				_nodes[nid] = node
				# Initialize state in GameStore if not already tracked.
				if GameStore.get_node_state(nid).is_empty():
					GameStore.set_node_state(nid, NODE_NOT_STARTED)

## Returns the current chapter state dictionary.
## Returns a "to_be_continued" dict when no valid chapter is loaded.
func get_chapter_state() -> Dictionary:
	if _chapter.is_empty() or _chapter.has("_state"):
		return {"state": "to_be_continued"}
	return {
		"id": _chapter.get("id", ""),
		"node_count": _nodes.size(),
	}

## Returns all nodes whose prerequisites are met and state is not "completed".
## Prerequisite: previous node completed + all requires_flags present.
func get_available_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var previous_complete: bool = true  # First node has no predecessor.

	var node_list: Array = _chapter.get("nodes", [])
	for item: Variant in node_list:
		if not item is Dictionary:
			continue
		var node: Dictionary = item as Dictionary
		var nid: String = node.get("id", "")
		var state: String = GameStore.get_node_state(nid)

		if state == NODE_COMPLETED:
			previous_complete = true
			continue

		if not previous_complete:
			break

		# Check flag prerequisites.
		if _check_requires_flags(node):
			result.append(node.duplicate())

		# Once we hit the first non-completed node, stop (linear sequence).
		previous_complete = false

	return result

## Begins execution of a story node.
## Transitions not_started → in_progress, persists to GameStore.
## Ignores calls on already-completed nodes (no re-execution, no reward re-grant).
func enter_node(node_id: String) -> void:
	if not _nodes.has(node_id):
		push_warning("[StoryFlow] enter_node(%s) — node not found." % node_id)
		return

	var current_state: String = GameStore.get_node_state(node_id)
	if current_state == NODE_COMPLETED:
		# No re-execution of completed nodes (AC3 SF-002).
		return

	_active_node_id = node_id
	GameStore.set_node_state(node_id, NODE_IN_PROGRESS)

	var node: Dictionary = _nodes[node_id]
	_execute_node(node)

# ── Private — Node Execution ──────────────────────────────────────────────────

## Dispatches execution to the appropriate handler based on node type.
func _execute_node(node: Dictionary) -> void:
	var node_type: String = node.get("type", "")
	match node_type:
		"dialogue":
			_execute_dialogue_node(node)
		"combat":
			_execute_combat_node(node)
		"companion_unlock":
			_execute_companion_unlock_node(node)
		"mixed":
			_execute_mixed_node(node)
		"boss":
			_execute_boss_node(node)
		"reward":
			_complete_node(node)
		_:
			push_warning("[StoryFlow] Unknown node type '%s' in node '%s'" % [node_type, node.get("id", "")])

## Dialogue node: calls DialogueRunner and awaits dialogue_ended.
func _execute_dialogue_node(node: Dictionary) -> void:
	var sequence_id: String = node.get("sequence_id", "")
	var chapter_id: String = _chapter.get("id", "")
	_awaiting_sequence_id = sequence_id
	DialogueRunner.start_dialogue(chapter_id, sequence_id)

## Combat node: transitions to combat scene via SceneManager.
## Awaits combat_completed via EventBus.
func _execute_combat_node(node: Dictionary) -> void:
	var enemy_id: String = node.get("enemy_id", "")
	_awaiting_combat = true
	SceneManager.change_scene(SceneManager.SceneId.COMBAT, SceneManager.TransitionType.FADE, {"enemy_id": enemy_id, "node_id": node.get("id", "")})

## Companion unlock: runs unlock dialogue, then sets met=true and emits unlock signal.
func _execute_companion_unlock_node(node: Dictionary) -> void:
	var sequence_id: String = node.get("sequence_id", "")
	var chapter_id: String = _chapter.get("id", "")
	if not sequence_id.is_empty():
		_awaiting_sequence_id = sequence_id
		DialogueRunner.start_dialogue(chapter_id, sequence_id)
	else:
		# No dialogue — immediately unlock companions and complete.
		_apply_companion_unlocks(node)
		_complete_node(node)

## Mixed node: dialogue → combat → post-combat dialogue → rewards.
## Restarted from beginning on force-quit recovery (AC3 SF-006).
func _execute_mixed_node(node: Dictionary) -> void:
	var sequence_id: String = node.get("sequence_id", "")
	var chapter_id: String = _chapter.get("id", "")
	if not sequence_id.is_empty():
		_awaiting_sequence_id = "mixed_pre_" + node.get("id", "")
		# Mixed uses sequence_id for pre-combat dialogue.
		DialogueRunner.start_dialogue(chapter_id, sequence_id)
	else:
		# Skip to combat if no pre-combat dialogue.
		_execute_combat_node(node)

## Boss node: pre-dialogue → combat (boss music) → post-dialogue → rewards.
func _execute_boss_node(node: Dictionary) -> void:
	var sequence_id: String = node.get("sequence_id", "")
	var chapter_id: String = _chapter.get("id", "")
	var enemy_id: String = node.get("enemy_id", "")
	EventBus.boss_encounter_started.emit(enemy_id)
	if not sequence_id.is_empty():
		_awaiting_sequence_id = "boss_pre_" + node.get("id", "")
		DialogueRunner.start_dialogue(chapter_id, sequence_id)
	else:
		_execute_combat_node(node)

# ── Private — Completion ──────────────────────────────────────────────────────

## Atomically: sets node state to completed, distributes rewards, sets flags,
## triggers autosave, then evaluates chapter completion.
func _complete_node(node: Dictionary) -> void:
	var node_id: String = node.get("id", "")

	# Distribute rewards atomically with state transition.
	var reward: Dictionary = node.get("reward", {})
	var gold_amount: int = reward.get("gold", 0)
	var xp_amount: int = reward.get("xp", 0)
	if gold_amount > 0:
		GameStore.add_gold(gold_amount)
	if xp_amount > 0:
		GameStore.add_xp(xp_amount)

	# Apply sets_flags atomically with reward.
	var sets_flags: Array = node.get("sets_flags", [])
	for flag: Variant in sets_flags:
		if flag is String:
			GameStore.set_flag(flag as String)

	# Transition to completed.
	GameStore.set_node_state(node_id, NODE_COMPLETED)
	EventBus.node_completed.emit(node_id)

	_active_node_id = ""

	# Check chapter completion.
	_check_chapter_completion()

## Applies a dialogue flag_set effect only if the flag is declared in the
## active node's sets_flags array. Undeclared flags are dropped with a warning.
func apply_node_flag(flag: String) -> void:
	if _active_node_id.is_empty():
		push_warning("[StoryFlow] apply_node_flag('%s') called with no active node." % flag)
		return
	var node: Dictionary = _nodes.get(_active_node_id, {})
	var sets_flags: Array = node.get("sets_flags", [])
	if not sets_flags.has(flag):
		push_warning("[StoryFlow] Flag '%s' not declared in sets_flags of node '%s' — dropped." % [flag, _active_node_id])
		return
	GameStore.set_flag(flag)

## Checks if all nodes in the chapter are completed. If so, emits chapter_completed.
func _check_chapter_completion() -> void:
	for node_id: String in _nodes:
		if GameStore.get_node_state(node_id) != NODE_COMPLETED:
			return
	# All nodes complete.
	var chapter_id: String = _chapter.get("id", "")
	GameStore.set_flag("chapter_%s_complete" % chapter_id)
	EventBus.chapter_completed.emit(chapter_id)

# ── Private — Prerequisites ───────────────────────────────────────────────────

## Returns true if all requires_flags in [param node] are set in GameStore.
func _check_requires_flags(node: Dictionary) -> bool:
	var requires: Array = node.get("requires_flags", [])
	for flag: Variant in requires:
		if not GameStore.has_flag(str(flag)):
			return false
	return true

## Sets met=true and emits companion_unlocked for each companion in unlocks_companions.
func _apply_companion_unlocks(node: Dictionary) -> void:
	var unlocks: Array = node.get("unlocks_companions", [])
	for companion_variant: Variant in unlocks:
		var companion_id: String = str(companion_variant)
		GameStore.set_met(companion_id, true)
		EventBus.companion_met.emit(companion_id)
		EventBus.companion_unlocked.emit(companion_id)

# ── Private — EventBus Listeners ──────────────────────────────────────────────

## Called when DialogueRunner ends a sequence.
## Advances the node state for the active node if the sequence_id matches.
func _on_dialogue_ended(sequence_id: String) -> void:
	if _active_node_id.is_empty():
		return
	var node: Dictionary = _nodes.get(_active_node_id, {})
	var node_type: String = node.get("type", "")

	match node_type:
		"dialogue":
			if sequence_id == node.get("sequence_id", ""):
				_complete_node(node)
		"companion_unlock":
			if sequence_id == node.get("sequence_id", ""):
				_apply_companion_unlocks(node)
				_complete_node(node)
		"mixed":
			var pre_seq: String = node.get("sequence_id", "")
			var post_seq: String = node.get("post_combat_sequence_id", "")
			if sequence_id == pre_seq:
				# Pre-combat dialogue done — move to combat.
				_execute_combat_node(node)
			elif sequence_id == post_seq:
				# Post-combat dialogue done — complete node.
				_complete_node(node)
		"boss":
			var pre_seq: String = node.get("sequence_id", "")
			var post_seq: String = node.get("post_combat_sequence_id", "")
			if sequence_id == pre_seq:
				_execute_combat_node(node)
			elif sequence_id == post_seq:
				_complete_node(node)

## Called when CombatSystem completes an encounter.
## Handles victory (advance) and defeat (retry or fail).
func _on_combat_completed(result: Dictionary) -> void:
	if not _awaiting_combat:
		return
	_awaiting_combat = false

	if _active_node_id.is_empty():
		return
	var node: Dictionary = _nodes.get(_active_node_id, {})
	var node_type: String = node.get("type", "")
	var victory: bool = result.get("victory", false)
	var defeat_mode: String = node.get("defeat_mode", "retry")

	if victory:
		# Check for post-combat dialogue.
		var post_seq: String = node.get("post_combat_sequence_id", "")
		if not post_seq.is_empty():
			var chapter_id: String = _chapter.get("id", "")
			_awaiting_sequence_id = post_seq
			DialogueRunner.start_dialogue(chapter_id, post_seq)
		else:
			_complete_node(node)
	else:
		# Defeat handling.
		if defeat_mode == "retry":
			# Keep node in_progress — player can retry.
			# Return to chapter map (handled by UI listening to EventBus).
			pass
		else:
			push_warning("[StoryFlow] Unhandled defeat_mode '%s' on node '%s'" % [defeat_mode, node.get("id", "")])
