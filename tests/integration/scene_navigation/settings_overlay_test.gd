class_name SettingsOverlayTest
extends GdUnitTestSuite

const SceneManagerScript = preload("res://src/autoloads/scene_manager.gd")

# Integration tests for STORY-SN-006: Settings Overlay (CanvasLayer 50)
#
# Covers:
#   AC1 — open_settings_overlay() in IDLE → state becomes OVERLAY_OPEN
#          and a CanvasLayer at layer 50 is added as a child of SceneManager
#   AC2 — Underlying scene is NOT freed while overlay is open
#   AC3 — change_scene() and open_settings_overlay() are silently dropped
#          while in OVERLAY_OPEN state
#   AC4 — Overlay's close_requested signal → CanvasLayer removed, state → IDLE
#   AC5 — scene_changed is NOT emitted on overlay open or close
#
# Implementation note: settings.tscn does not exist during headless CI runs.
# Tests drive the state machine directly (set _state, call _on_settings_closed)
# rather than relying on the real scene file, so the suite is deterministic and
# self-contained. AC1's CanvasLayer assertion uses open_settings_overlay() which
# will create the layer even when settings.tscn is absent (by design — the
# push_warning path still creates the layer to keep the state machine consistent).
#
# See: docs/architecture/adr-0003-scene-management.md

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates a fresh SceneManager, adds it to the tree so _ready() fires,
## and returns it. Caller is responsible for queue_free() in cleanup.
func _make_manager() -> Node:
	var manager := SceneManagerScript.new()
	add_child(manager)
	return manager

## Returns the first child CanvasLayer of [param manager] whose layer value
## matches [param layer_value], or null if none found.
func _find_canvas_layer(manager: Node, layer_value: int) -> CanvasLayer:
	for child: Node in manager.get_children():
		if child is CanvasLayer:
			var cl: CanvasLayer = child as CanvasLayer
			if cl.layer == layer_value:
				return cl
	return null

# ---------------------------------------------------------------------------
# AC1 — open_settings_overlay() in IDLE → state OVERLAY_OPEN + layer 50 exists
# ---------------------------------------------------------------------------

func test_settings_overlay_open_sets_state_to_overlay_open() -> void:
	# Arrange
	var manager := _make_manager()
	assert_int(manager._state).is_equal(SceneManagerScript.TransitionState.IDLE)

	# Act — settings.tscn may not exist; push_warning path still sets state
	manager.open_settings_overlay()

	# Assert — state machine must be OVERLAY_OPEN regardless of scene file
	assert_int(manager._state).is_equal(SceneManagerScript.TransitionState.OVERLAY_OPEN)

	# Cleanup
	manager._state = SceneManagerScript.TransitionState.IDLE
	manager.queue_free()

func test_settings_overlay_open_adds_canvas_layer_at_layer_50() -> void:
	# Arrange
	var manager := _make_manager()

	# Act
	manager.open_settings_overlay()

	# Assert — a CanvasLayer at layer 50 must be a child of the manager
	var layer: CanvasLayer = _find_canvas_layer(manager, 50)
	assert_object(layer).is_not_null()

	# Cleanup — reset state so queue_free is clean
	manager._state = SceneManagerScript.TransitionState.IDLE
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC2 — Underlying scene node is not freed while overlay is open
#
# We simulate this by creating a plain Node as a stand-in "scene root" and
# confirming it remains valid in the tree after the overlay is opened. In the
# real game this node is the current scene root managed by the SceneTree;
# the test uses a sibling node to verify SceneManager does not touch it.
# ---------------------------------------------------------------------------

func test_settings_overlay_does_not_free_underlying_scene_node() -> void:
	# Arrange — a fake "scene" sibling node that must survive the overlay open
	var manager := _make_manager()
	var fake_scene := Node.new()
	fake_scene.name = &"FakeScene"
	add_child(fake_scene)

	# Act
	manager.open_settings_overlay()

	# Assert — fake scene node must still be alive in the tree
	assert_bool(is_instance_valid(fake_scene)).is_true()
	assert_bool(fake_scene.is_inside_tree()).is_true()

	# Cleanup
	manager._state = SceneManagerScript.TransitionState.IDLE
	manager.queue_free()
	fake_scene.queue_free()

# ---------------------------------------------------------------------------
# AC3 — change_scene() dropped while OVERLAY_OPEN
# ---------------------------------------------------------------------------

func test_settings_overlay_change_scene_dropped_during_overlay_open() -> void:
	# Arrange
	var manager := _make_manager()
	manager._state = SceneManagerScript.TransitionState.OVERLAY_OPEN

	var signal_fired: bool = false
	manager.transition_started.connect(func(_id: int) -> void: signal_fired = true)

	# Act
	manager.change_scene(SceneManagerScript.SceneId.HUB)

	# Assert — state unchanged, no transition signal fired
	assert_bool(signal_fired).is_false()
	assert_int(manager._state).is_equal(SceneManagerScript.TransitionState.OVERLAY_OPEN)

	# Cleanup
	manager._state = SceneManagerScript.TransitionState.IDLE
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC3 — open_settings_overlay() dropped while OVERLAY_OPEN (second call)
# ---------------------------------------------------------------------------

func test_settings_overlay_second_open_call_dropped_during_overlay_open() -> void:
	# Arrange — simulate overlay already open with a layer in place
	var manager := _make_manager()
	manager._state = SceneManagerScript.TransitionState.OVERLAY_OPEN
	var existing_layer := CanvasLayer.new()
	existing_layer.layer = 50
	manager.add_child(existing_layer)
	manager._settings_layer = existing_layer

	# Record child count before the second call
	var child_count_before: int = manager.get_child_count()

	# Act — second call must be dropped by the IDLE guard
	manager.open_settings_overlay()

	# Assert — no new CanvasLayer was added
	assert_int(manager.get_child_count()).is_equal(child_count_before)
	assert_int(manager._state).is_equal(SceneManagerScript.TransitionState.OVERLAY_OPEN)

	# Cleanup
	manager._state = SceneManagerScript.TransitionState.IDLE
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC4 — _on_settings_closed removes CanvasLayer and returns to IDLE
# ---------------------------------------------------------------------------

func test_settings_overlay_close_removes_settings_layer() -> void:
	# Arrange — manually set up the OVERLAY_OPEN state with a real layer
	var manager := _make_manager()
	var settings_layer := CanvasLayer.new()
	settings_layer.layer = 50
	manager.add_child(settings_layer)
	manager._settings_layer = settings_layer
	manager._state = SceneManagerScript.TransitionState.OVERLAY_OPEN

	# Act — trigger the close callback directly (mirrors signal emission)
	manager._on_settings_closed()

	# Assert — layer reference cleared and state back to IDLE
	assert_object(manager._settings_layer).is_null()
	assert_int(manager._state).is_equal(SceneManagerScript.TransitionState.IDLE)

	# The layer itself is queued for deletion; is_instance_valid may still be
	# true until the next frame, so we only check the manager's internal state.
	manager.queue_free()

func test_settings_overlay_close_returns_state_to_idle() -> void:
	# Arrange
	var manager := _make_manager()
	manager._state = SceneManagerScript.TransitionState.OVERLAY_OPEN

	# Act
	manager._on_settings_closed()

	# Assert
	assert_int(manager._state).is_equal(SceneManagerScript.TransitionState.IDLE)
	assert_bool(manager.is_transitioning()).is_false()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC5 — scene_changed NOT emitted on overlay open or close
# ---------------------------------------------------------------------------

func test_settings_overlay_open_does_not_emit_scene_changed() -> void:
	# Arrange
	var manager := _make_manager()
	var scene_changed_count: int = 0
	manager.scene_changed.connect(func(_id: int) -> void: scene_changed_count += 1)

	# Act — open overlay (settings.tscn absent → push_warning path, no crash)
	manager.open_settings_overlay()

	# Assert — scene_changed must not have been emitted
	assert_int(scene_changed_count).is_equal(0)

	# Cleanup
	manager._state = SceneManagerScript.TransitionState.IDLE
	manager.queue_free()

func test_settings_overlay_close_does_not_emit_scene_changed() -> void:
	# Arrange
	var manager := _make_manager()
	var settings_layer := CanvasLayer.new()
	settings_layer.layer = 50
	manager.add_child(settings_layer)
	manager._settings_layer = settings_layer
	manager._state = SceneManagerScript.TransitionState.OVERLAY_OPEN

	var scene_changed_count: int = 0
	manager.scene_changed.connect(func(_id: int) -> void: scene_changed_count += 1)

	# Act
	manager._on_settings_closed()

	# Assert
	assert_int(scene_changed_count).is_equal(0)

	# Cleanup
	manager.queue_free()
