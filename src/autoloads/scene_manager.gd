extends Node

## SceneManager — Centralised Scene Navigation with Fade Transitions (ADR-0003)
##
## All scene transitions must go through this autoload. Use [method change_scene]
## with a [enum SceneId] and optional [enum TransitionType]. Never call
## [method SceneTree.change_scene_to_file] directly, and never embed raw .tscn
## path strings in other scripts.
##
## Arrival context (arbitrary data passed from the launching scene) is stored
## here and consumed once by the arriving scene via [method get_arrival_context].

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum SceneId {
	SPLASH,
	DIALOGUE,
	COMBAT,
	HUB,
	CHAPTER_MAP,
	COMPANION_ROOM,
	DATE,
	INTIMACY,
	DECK,
	DECK_VIEWER,
	EQUIPMENT,
	EXPLORATION,
	ABYSS,
	GALLERY,
	ACHIEVEMENTS,
	SETTINGS,
}

enum TransitionType {
	FADE,
	INSTANT,
	NONE,
}

## Internal state machine for the transition pipeline.
## IDLE       — no transition in progress; accepts new [method change_scene] calls.
## FADING_OUT — fade-to-black tween running; double-tap calls are dropped.
## LOADING    — scene swap executing (between fade-out and fade-in).
## FADING_IN  — fade-from-black tween running.
## OVERLAY_OPEN — a modal overlay (e.g. Settings) is on top; scene swaps blocked.
enum TransitionState {
	IDLE,
	FADING_OUT,
	LOADING,
	FADING_IN,
	OVERLAY_OPEN,
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Maps every non-SETTINGS SceneId to its canonical .tscn path.
## SETTINGS is intentionally omitted — it overlays the current scene
## rather than replacing it; callers must use [method open_settings_overlay].
const SCENE_PATHS: Dictionary = {
	SceneId.SPLASH:          "res://scenes/splash/splash.tscn",
	SceneId.DIALOGUE:        "res://scenes/dialogue/dialogue.tscn",
	SceneId.COMBAT:          "res://scenes/combat/combat.tscn",
	SceneId.HUB:             "res://scenes/hub/hub.tscn",
	SceneId.CHAPTER_MAP:     "res://scenes/chapter_map/chapter_map.tscn",
	SceneId.COMPANION_ROOM:  "res://scenes/companion_room/companion_room.tscn",
	SceneId.DATE:            "res://scenes/date/date.tscn",
	SceneId.INTIMACY:        "res://scenes/intimacy/intimacy.tscn",
	SceneId.DECK:            "res://scenes/deck/deck.tscn",
	SceneId.DECK_VIEWER:     "res://scenes/deck_viewer/deck_viewer.tscn",
	SceneId.EQUIPMENT:       "res://scenes/equipment/equipment.tscn",
	SceneId.EXPLORATION:     "res://scenes/exploration/exploration.tscn",
	SceneId.ABYSS:           "res://scenes/abyss/abyss.tscn",
	SceneId.GALLERY:         "res://scenes/gallery/gallery.tscn",
	SceneId.ACHIEVEMENTS:    "res://scenes/achievements/achievements.tscn",
}

## Duration in seconds for each half of a fade transition (out + in).
const FADE_DURATION: float = 0.3

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted immediately when a transition begins, before any scene swap occurs.
signal transition_started(scene_id: int)

## Emitted after the incoming scene is fully visible (fade-in complete,
## or immediately after swap for INSTANT/NONE transitions).
signal scene_changed(scene_id: int)

## Emitted when a [method change_scene] call fails to load the target .tscn file.
## The transition fades back to the previous scene before this signal fires.
## [param scene_id] is the [enum SceneId] that failed; [param reason] is a
## human-readable explanation for logging and UI display.
signal navigation_error(scene_id: int, reason: String)

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _transition_layer: CanvasLayer
var _overlay: ColorRect
## Current state of the transition state machine. Use [method is_transitioning]
## to query from outside this class.
var _state: TransitionState = TransitionState.IDLE
var _arrival_context: Dictionary = {}
## CanvasLayer at layer 50 that hosts the Settings overlay scene.
## Null when no overlay is open.
var _settings_layer: CanvasLayer = null

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

## Intercepts the Android back button (ui_cancel action) while a modal overlay
## is open. Closes the overlay and returns the state machine to IDLE without
## navigating away from the current scene. All other states let the event
## propagate normally so the OS can handle it (e.g. exit the app from Home).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _state == TransitionState.OVERLAY_OPEN:
			_on_settings_closed()
			get_viewport().set_input_as_handled()

func _ready() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100
	add_child(_transition_layer)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	_transition_layer.add_child(_overlay)

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Navigate to [param target] scene using [param transition] style.
## [param context] is arbitrary data made available to the arriving scene once
## via [method get_arrival_context]. Calls while not in IDLE state are silently
## dropped to prevent scene stack corruption (double-tap guard).
func change_scene(
		target: int,
		transition: int = TransitionType.FADE,
		context: Dictionary = {}) -> void:
	if _state != TransitionState.IDLE:
		return
	if not SCENE_PATHS.has(target):
		push_error(
			"SceneManager.change_scene: SceneId %d has no registered path "
			% target
			+ "(SETTINGS must use open_settings_overlay)."
		)
		return

	_arrival_context = context
	_state = TransitionState.FADING_OUT
	transition_started.emit(target)

	var success: bool = true
	match transition:
		TransitionType.FADE:
			success = await _do_fade_transition(target)
		TransitionType.INSTANT, TransitionType.NONE:
			_do_instant_transition(target)

	# On FADE error, _do_fade_transition resets state and emits navigation_error
	# itself; skip the normal completion path to avoid a spurious scene_changed.
	if not success:
		return

	_state = TransitionState.IDLE
	scene_changed.emit(target)

## Returns the context Dictionary stored by the previous scene and clears it.
## Read-once: a second call in the same scene returns an empty Dictionary.
func get_arrival_context() -> Dictionary:
	var ctx: Dictionary = _arrival_context
	_arrival_context = {}
	return ctx

## Returns [code]true[/code] while a transition is in progress (any non-IDLE state).
func is_transitioning() -> bool:
	return _state != TransitionState.IDLE

## Open the Settings overlay on top of the current scene.
##
## Instantiates [code]settings.tscn[/code] on a [CanvasLayer] at layer 50,
## leaving the underlying scene fully intact. Calls while not in IDLE state
## are silently dropped. Connects the overlay's [signal close_requested] to
## [method _on_settings_closed] for teardown.
func open_settings_overlay() -> void:
	if _state != TransitionState.IDLE:
		return
	_state = TransitionState.OVERLAY_OPEN
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 50
	add_child(_settings_layer)
	const SETTINGS_PATH: String = "res://scenes/settings/settings.tscn"
	if not ResourceLoader.exists(SETTINGS_PATH):
		push_warning(
			"SceneManager.open_settings_overlay: settings.tscn not found at "
			+ SETTINGS_PATH
		)
		# Layer is still added so state machine stays consistent;
		# caller must close via _on_settings_closed or direct reset.
		return
	var settings_scene: Node = load(SETTINGS_PATH).instantiate()
	_settings_layer.add_child(settings_scene)
	if settings_scene.has_signal("close_requested"):
		settings_scene.close_requested.connect(_on_settings_closed)

## [deprecated] Use [method change_scene] with [enum SceneId] instead.
## Retained for backward compatibility during the SN-001 → SN-002 migration.
func go_to(scene_id: SceneId, transition: String = "fade") -> void:
	var t: int = TransitionType.FADE if transition == "fade" else TransitionType.INSTANT
	change_scene(scene_id, t)

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _do_fade_transition(target: int) -> bool:
	# FADING_OUT phase — block input immediately (state already set by caller)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_out()

	# LOADING phase — scene swap between the two tween halves
	_state = TransitionState.LOADING
	var path: String = SCENE_PATHS[target]
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		# Error recovery: fade back in so the player sees the previous scene,
		# then emit navigation_error. The caller's post-await code (state = IDLE,
		# scene_changed.emit) must NOT run, so we return early after restoring the
		# overlay and manually resetting state.
		push_error("SceneManager: failed to load scene: " + path)
		_state = TransitionState.FADING_IN
		await _fade_in()
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_state = TransitionState.IDLE
		navigation_error.emit(target, "Failed to load: " + path)
		return false

	await get_tree().process_frame

	# FADING_IN phase — reveal the new scene
	_state = TransitionState.FADING_IN
	await _fade_in()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Caller sets _state = IDLE and emits scene_changed after this returns
	return true

func _do_instant_transition(target: int) -> void:
	# Block input for exactly one frame so any touch event that triggered the
	# navigation cannot accidentally reach the new scene on the same frame.
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().change_scene_to_file(SCENE_PATHS[target])
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished

# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------

## Called when the Settings overlay emits [signal close_requested].
## Removes the overlay CanvasLayer and returns the state machine to IDLE.
## [signal scene_changed] is intentionally NOT emitted — Settings is not
## a scene transition.
func _on_settings_closed() -> void:
	if _settings_layer != null:
		_settings_layer.queue_free()
		_settings_layer = null
	_state = TransitionState.IDLE
