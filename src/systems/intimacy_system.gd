class_name IntimacySystem
extends RefCounted

## IntimacySystem — Intimacy Scene Gate + Completion Logic
##
## Feature-layer utility class (static methods). No autoload — tests can
## instantiate or call static methods directly.
##
## Manages the 3-scene intimacy arc per companion:
##   - Scene 1 & 2 unlock at romance_stage >= 4 (Close)
##   - Scene 3 unlocks at romance_stage >= 5 (Devoted) + scene 2 done
##   - Each scene costs 1 interaction token (same pool as Talk/Gift/Date)
##   - Completion awards +10 RL (scenes 1–2) or +20 RL (scene 3)
##   - Completion flags are write-once via GameStore story flags
##   - Gallery replay: no token cost, no reward
##
## GDD: design/gdd/intimacy.md
## ADR: docs/architecture/ (pending)

# ── Constants ─────────────────────────────────────────────────────────────────

## RL awarded for completing scenes 1 and 2.
const BASE_RL_AWARD: int = 10

## Multiplier applied to BASE_RL_AWARD for scene 3 completion.
const SCENE_3_MULTIPLIER: int = 2

## Interaction token cost per scene (same pool as Talk/Gift/Date).
const TOKEN_COST: int = 1

## Number of intimacy scenes per companion.
const SCENES_PER_COMPANION: int = 3

## Romance stage required to access scenes 1 and 2.
const STAGE_GATE_SCENES_1_2: int = 4

## Romance stage required to access scene 3.
const STAGE_GATE_SCENE_3: int = 5

## Known companion IDs supported by this system.
const COMPANION_IDS: Array[String] = ["artemis", "hipolita", "atenea", "nyx"]

# ── Data ──────────────────────────────────────────────────────────────────────

## Cached scene data loaded from intimacy_scenes.json.
## Keys: companion_id (String) → Array of scene dicts.
static var _scene_data: Dictionary = {}
static var _data_loaded: bool = false

# ── Public API ────────────────────────────────────────────────────────────────

## Returns true if [param companion_id]/[param scene_num] can be started right now.
## Checks: companion met, romance_stage gate, prior-scene completion, token available.
## scene_num is 1-indexed (1, 2, or 3).
static func can_start_scene(companion_id: String, scene_num: int) -> bool:
	if not _is_valid_companion(companion_id):
		return false
	if scene_num < 1 or scene_num > SCENES_PER_COMPANION:
		return false

	var state: Dictionary = GameStore.get_companion_state(companion_id)
	if state.is_empty():
		return false

	# Companion must have been met.
	if not state.get("met", false):
		return false

	# Stage gate: scene 3 requires stage 5, scenes 1–2 require stage 4.
	var required_stage: int = STAGE_GATE_SCENE_3 if scene_num == 3 else STAGE_GATE_SCENES_1_2
	if CompanionState.get_romance_stage(companion_id) < required_stage:
		return false

	# Prior scene in sequence must be complete (scene 1 has no prerequisite).
	if scene_num > 1 and not is_scene_complete(companion_id, scene_num - 1):
		return false

	# Scene must not already be complete.
	if is_scene_complete(companion_id, scene_num):
		return false

	# Player must have at least TOKEN_COST tokens.
	if GameStore.get_daily_tokens() < TOKEN_COST:
		return false

	return true

## Returns an Array[int] of scene numbers (1-indexed) available for [param companion_id].
## "Available" means can_start_scene() returns true for that scene number.
## Returns an empty array if the companion is unknown or no scenes are available.
static func get_available_scenes(companion_id: String) -> Array[int]:
	var result: Array[int] = []
	if not _is_valid_companion(companion_id):
		return result
	for scene_num: int in range(1, SCENES_PER_COMPANION + 1):
		if can_start_scene(companion_id, scene_num):
			result.append(scene_num)
	return result

## Attempts to start an intimacy scene. Consumes 1 interaction token on success.
## Returns true if the scene was started successfully; false if gate checks fail.
## Callers should connect to DialogueRunner signals to drive scene playback.
static func start_scene(companion_id: String, scene_num: int) -> bool:
	if not can_start_scene(companion_id, scene_num):
		return false

	# Consume token immediately on scene launch (per GDD Rule 4 / AC-2).
	GameStore.spend_token()
	return true

## Records scene completion. Awards RL, writes write-once completion flag.
## Scene 3 awards BASE_RL_AWARD * SCENE_3_MULTIPLIER; scenes 1–2 award BASE_RL_AWARD.
## No-ops if companion_id or scene_num is invalid, or scene is already complete.
static func complete_scene(companion_id: String, scene_num: int) -> void:
	if not _is_valid_companion(companion_id):
		return
	if scene_num < 1 or scene_num > SCENES_PER_COMPANION:
		return

	# Write-once: do not re-award or re-flag if already done.
	if is_scene_complete(companion_id, scene_num):
		return

	# Write completion flag.
	var flag: String = _completion_flag(companion_id, scene_num)
	GameStore.set_flag(flag)

	# Award RL.
	var rl_award: int = _rl_for_scene(scene_num)
	CompanionState.set_relationship_level(
		companion_id,
		GameStore.get_relationship_level(companion_id) + rl_award
	)

## Returns true if the given scene has been completed (flag is set in GameStore).
static func is_scene_complete(companion_id: String, scene_num: int) -> bool:
	if not _is_valid_companion(companion_id):
		return false
	if scene_num < 1 or scene_num > SCENES_PER_COMPANION:
		return false
	return GameStore.has_flag(_completion_flag(companion_id, scene_num))

## Returns gallery entries for [param companion_id].
## Each entry is a Dictionary: {scene, cg_path, dialogue_seq, unlocked}.
## Returns an empty array if companion_id is invalid or data is not loaded.
static func get_gallery_entries(companion_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _is_valid_companion(companion_id):
		return result

	_ensure_data_loaded()
	var scenes: Array = _scene_data.get(companion_id, [])
	for entry: Variant in scenes:
		if entry is not Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var scene_num: int = d.get("scene", 0)
		result.append({
			"scene": scene_num,
			"cg_path": d.get("cg_path", ""),
			"dialogue_seq": d.get("dialogue_seq", ""),
			"unlocked": is_scene_complete(companion_id, scene_num),
		})
	return result

## Returns the scene data Dictionary for a specific companion and scene number.
## Returns an empty Dictionary if not found.
static func get_scene_data(companion_id: String, scene_num: int) -> Dictionary:
	_ensure_data_loaded()
	var scenes: Array = _scene_data.get(companion_id, [])
	for entry: Variant in scenes:
		if entry is not Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		if d.get("scene", 0) == scene_num:
			return d.duplicate()
	return {}

# ── Private Helpers ───────────────────────────────────────────────────────────

## Returns the write-once GameStore flag key for a scene completion.
## Format: "intimacy_{companion_id}_{scene_num}_complete"
static func _completion_flag(companion_id: String, scene_num: int) -> String:
	return "intimacy_%s_%d_complete" % [companion_id, scene_num]

## Returns RL awarded for completing [param scene_num].
static func _rl_for_scene(scene_num: int) -> int:
	if scene_num == SCENES_PER_COMPANION:
		return BASE_RL_AWARD * SCENE_3_MULTIPLIER
	return BASE_RL_AWARD

## Returns true if companion_id is in COMPANION_IDS.
static func _is_valid_companion(companion_id: String) -> bool:
	return COMPANION_IDS.has(companion_id)

## Loads intimacy_scenes.json into _scene_data if not already loaded.
static func _ensure_data_loaded() -> void:
	if _data_loaded:
		return
	_data_loaded = true
	_scene_data = JsonLoader.load_dict("res://assets/data/intimacy_scenes.json")

## Resets the static data cache. Used by tests to isolate state.
static func _reset_cache() -> void:
	_scene_data = {}
	_data_loaded = false
