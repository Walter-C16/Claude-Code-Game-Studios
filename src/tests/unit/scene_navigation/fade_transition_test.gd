class_name FadeTransitionTest
extends GdUnitTestSuite

const _SceneManagerScript = preload("res://autoloads/scene_manager.gd")

# Unit tests for STORY-SN-002: Fade Transition
#
# Covers:
#   AC1 — _ready() creates a CanvasLayer at layer 100
#   AC2 — Overlay starts fully transparent (modulate.a == 0)
#   AC3 — Overlay starts with MOUSE_FILTER_IGNORE
#   AC4 — is_transitioning() returns false on a fresh instance
#   AC5 — get_arrival_context() returns empty dict by default
#   AC6 — get_arrival_context() is read-once (second call returns empty)
#   AC7 — change_scene() with an unmapped SceneId (SETTINGS) is a no-op
#   AC8 — change_scene() while _is_transitioning is true is a no-op (guard)
#
# See: docs/architecture/adr-0003-scene-management.md

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates a fresh SceneManager instance and adds it to the scene tree so
## _ready() fires and the overlay/layer are constructed.
func _make_manager() -> SceneManager:
	var manager = _SceneManagerScript.new()
	add_child(manager)
	return manager

# ---------------------------------------------------------------------------
# AC1 — _ready() creates CanvasLayer at layer 100
# ---------------------------------------------------------------------------

func test_scene_manager_ready_creates_canvas_layer_at_100() -> void:
	# Arrange / Act
	var manager = _make_manager()

	# Assert — walk children looking for the CanvasLayer
	var found_layer: CanvasLayer = null
	for child: Node in manager.get_children():
		if child is CanvasLayer:
			found_layer = child as CanvasLayer
			break

	assert_object(found_layer).is_not_null()
	assert_int(found_layer.layer).is_equal(100)

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC2 — Overlay starts fully transparent
# ---------------------------------------------------------------------------

func test_scene_manager_ready_overlay_alpha_is_zero() -> void:
	# Arrange / Act
	var manager = _make_manager()

	# Assert
	assert_float(manager._overlay.modulate.a).is_equal(0.0)

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC3 — Overlay starts with MOUSE_FILTER_IGNORE
# ---------------------------------------------------------------------------

func test_scene_manager_ready_overlay_mouse_filter_is_ignore() -> void:
	# Arrange / Act
	var manager = _make_manager()

	# Assert
	assert_int(manager._overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC4 — is_transitioning() starts false
# ---------------------------------------------------------------------------

func test_scene_manager_is_transitioning_starts_false() -> void:
	# Arrange / Act
	var manager = _make_manager()

	# Assert
	assert_bool(manager.is_transitioning()).is_false()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC5 — get_arrival_context() returns empty dict by default
# ---------------------------------------------------------------------------

func test_scene_manager_get_arrival_context_returns_empty_by_default() -> void:
	# Arrange / Act
	var manager = _make_manager()

	# Act
	var ctx: Dictionary = manager.get_arrival_context()

	# Assert
	assert_bool(ctx.is_empty()).is_true()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC6 — get_arrival_context() is read-once
# ---------------------------------------------------------------------------

func test_scene_manager_get_arrival_context_is_read_once() -> void:
	# Arrange — inject a non-empty context directly into the private field
	var manager = _make_manager()
	manager._arrival_context = {"companion_id": "artemis", "chapter": "ch01"}

	# Act — first read returns the stored data
	var first: Dictionary = manager.get_arrival_context()

	# Act — second read must return empty (context was consumed)
	var second: Dictionary = manager.get_arrival_context()

	# Assert
	assert_bool(first.is_empty()).is_false()
	assert_bool(second.is_empty()).is_true()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC7 — change_scene() with SETTINGS (no registered path) is a no-op
# ---------------------------------------------------------------------------

func test_scene_manager_change_scene_with_settings_id_does_nothing() -> void:
	# Arrange
	var manager = _make_manager()

	# Act — SETTINGS is intentionally absent from SCENE_PATHS; this must not
	# set _is_transitioning or crash
	manager.change_scene(SceneManager.SceneId.SETTINGS)

	# Assert — transitioning flag must remain false (call was rejected)
	assert_bool(manager.is_transitioning()).is_false()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC8 — change_scene() while _state != IDLE is a no-op (double-tap guard)
# ---------------------------------------------------------------------------

func test_scene_manager_change_scene_while_transitioning_is_no_op() -> void:
	# Arrange — force state to FADING_OUT to simulate a transition already in
	# flight without actually triggering a scene swap.
	var manager = _make_manager()
	manager._state = SceneManager.TransitionState.FADING_OUT

	# Capture a signal emission count to confirm transition_started is NOT fired
	var signal_fired: bool = false
	manager.transition_started.connect(func(_id: int) -> void: signal_fired = true)

	# Act — attempt to queue a second transition while one is in progress
	manager.change_scene(SceneManager.SceneId.HUB)

	# Assert — neither the signal nor a scene change should have occurred
	assert_bool(signal_fired).is_false()
	# State must remain FADING_OUT (we set it; the guard returned early)
	assert_int(manager._state).is_equal(SceneManager.TransitionState.FADING_OUT)

	# Cleanup
	manager._state = SceneManager.TransitionState.IDLE
	manager.queue_free()
