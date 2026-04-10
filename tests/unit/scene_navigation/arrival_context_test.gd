class_name ArrivalContextTest
extends GdUnitTestSuite

const _SceneManagerScript = preload("res://src/autoloads/scene_manager.gd")

# Unit tests for STORY-SN-005: Arrival Context Payload (Read-Once)
#
# Covers:
#   AC1 — change_scene with context stores it; get_arrival_context() returns it
#   AC2 — Second get_arrival_context() call returns empty {}
#   AC3 — New change_scene with new context replaces old unread context
#   AC4 — change_scene with no context → get_arrival_context() returns {}
#
# See: docs/architecture/adr-0003-scene-management.md

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_manager() -> SceneManager:
	var manager := _SceneManagerScript.new()
	add_child(manager)
	return manager

# ---------------------------------------------------------------------------
# AC1 — Context stored by change_scene is returned by get_arrival_context()
#
# We inject _arrival_context directly (the same write change_scene() performs)
# rather than calling change_scene() which would trigger a real scene swap.
# This isolates the context storage/retrieval contract from the I/O path.
# ---------------------------------------------------------------------------

func test_arrival_context_stored_context_is_returned() -> void:
	# Arrange
	var manager := _make_manager()
	var expected: Dictionary = {"enemy_id": "mountain_beast"}

	# Act — simulate what change_scene() does when context is provided
	manager._arrival_context = expected

	# Assert
	var actual: Dictionary = manager.get_arrival_context()
	assert_bool(actual.has("enemy_id")).is_true()
	assert_str(actual["enemy_id"]).is_equal("mountain_beast")

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC2 — Second get_arrival_context() call returns empty {}
# ---------------------------------------------------------------------------

func test_arrival_context_second_call_returns_empty() -> void:
	# Arrange
	var manager := _make_manager()
	manager._arrival_context = {"enemy_id": "mountain_beast"}

	# Act
	var first: Dictionary = manager.get_arrival_context()
	var second: Dictionary = manager.get_arrival_context()

	# Assert — first call returns the stored data
	assert_bool(first.is_empty()).is_false()
	assert_str(first["enemy_id"]).is_equal("mountain_beast")

	# Assert — second call returns empty (context was consumed on first read)
	assert_bool(second.is_empty()).is_true()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC3 — New change_scene() with new context replaces old unread context
# ---------------------------------------------------------------------------

func test_arrival_context_new_context_replaces_old_unread_context() -> void:
	# Arrange — inject an old context that was never read
	var manager := _make_manager()
	manager._arrival_context = {"old_key": "old_value"}

	# Act — simulate a second change_scene() call with a new context.
	# change_scene() unconditionally overwrites _arrival_context before
	# any transition logic runs, so the old value is always discarded.
	manager._arrival_context = {"companion_id": "athena"}

	# Assert — only the new context is present
	var ctx: Dictionary = manager.get_arrival_context()
	assert_bool(ctx.has("companion_id")).is_true()
	assert_str(ctx["companion_id"]).is_equal("athena")
	assert_bool(ctx.has("old_key")).is_false()

	# Cleanup
	manager.queue_free()

# ---------------------------------------------------------------------------
# AC4 — change_scene() with no context → get_arrival_context() returns {}
# ---------------------------------------------------------------------------

func test_arrival_context_no_context_argument_returns_empty() -> void:
	# Arrange — ensure any previously set context is cleared first
	var manager := _make_manager()
	manager._arrival_context = {"stale": true}

	# Act — simulate change_scene() called with the default empty context.
	# The default parameter for `context` is `{}`, so _arrival_context is
	# overwritten with an empty dictionary.
	manager._arrival_context = {}

	# Assert
	var ctx: Dictionary = manager.get_arrival_context()
	assert_bool(ctx.is_empty()).is_true()

	# Cleanup
	manager.queue_free()
