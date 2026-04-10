class_name CompanionState
extends RefCounted

## CompanionState — Mutable Companion State Access (ADR-0009)
##
## Non-autoload utility class. Static methods over GameStore.
## Derives romance_stage from relationship_level threshold array.
##
## This class is NOT an autoload — instantiate or use static methods directly.
## romance_stage only ever increases (stage never decreases).
##
## Public API:
##   get_state(id)                 → Dictionary with all mutable fields + derived romance_stage
##   get_romance_stage(id)         → int stage [0..4], derived from STAGE_THRESHOLDS
##   set_relationship_level(id, v) → void, clamps to [0,100], emits romance_stage_changed on transition
##
## See: docs/architecture/adr-0009-companion-data.md

# ── Constants ─────────────────────────────────────────────────────────────────

## Minimum relationship_level to reach each stage index.
## Index 0 = Stranger (always reachable), index 4 = Soulmate.
const STAGE_THRESHOLDS: Array[int] = [0, 21, 51, 71, 91]

# ── Private State ─────────────────────────────────────────────────────────────

## Cache of the highest-ever romance stage per companion.
## Stage is monotonically non-decreasing: once reached it never falls.
## Keyed by companion ID string → int stage.
static var _max_stages: Dictionary = {}

# ── Public Static Methods ─────────────────────────────────────────────────────

## Returns all mutable companion state fields plus the derived [code]romance_stage[/code].
## Returns an empty Dictionary if [param id] is not registered in GameStore.
## Fields: relationship_level, trust, motivation, romance_stage, dates_completed,
##         met, known_likes, known_dislikes.
static func get_state(id: String) -> Dictionary:
	var state: Dictionary = GameStore.get_companion_state(id)
	if state.is_empty():
		return {}
	state["romance_stage"] = get_romance_stage(id)
	return state

## Derives the romance stage index for [param id] from [member STAGE_THRESHOLDS].
## The returned stage is the highest index whose threshold is ≤ relationship_level,
## subject to the monotonic constraint: stage never decreases from a previously
## reached maximum.
static func get_romance_stage(id: String) -> int:
	var rl: int = GameStore.get_relationship_level(id)
	var stage: int = 0
	for i: int in range(STAGE_THRESHOLDS.size()):
		if rl >= STAGE_THRESHOLDS[i]:
			stage = i

	# Enforce monotonic non-decrease
	var prev_max: int = _max_stages.get(id, 0)
	if stage > prev_max:
		_max_stages[id] = stage
		return stage
	return prev_max

## Sets [param id]'s relationship_level to [param value], clamped to [0, 100].
## Emits [signal EventBus.romance_stage_changed] when the clamped write causes
## a stage transition (new stage > old stage). No signal is emitted when the
## stage does not change.
static func set_relationship_level(id: String, value: int) -> void:
	var clamped: int = clampi(value, 0, 100)
	var old_stage: int = get_romance_stage(id)
	GameStore._set_relationship_level(id, clamped)
	var new_stage: int = get_romance_stage(id)
	if new_stage > old_stage:
		EventBus.romance_stage_changed.emit(id, old_stage, new_stage)
