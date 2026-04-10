class_name HapticManager
extends RefCounted

## HapticManager — Touch Haptic Feedback (ADR-0013)
##
## Static utility class. Calls [method Input.vibrate_handheld] on supported
## platforms (Android, iOS). Gracefully degrades on Web/desktop — Godot's
## [method Input.vibrate_handheld] is a documented no-op on unsupported
## platforms, so callers never need platform guards.
##
## Usage:
##   HapticManager.light()   # button taps, selection feedback
##   HapticManager.medium()  # confirmations, card plays
##   HapticManager.heavy()   # impacts, critical events

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const LIGHT_MS: int = 15
const MEDIUM_MS: int = 30
const HEAVY_MS: int = 50

# ---------------------------------------------------------------------------
# Public static methods
# ---------------------------------------------------------------------------

## Triggers a short 15 ms vibration. Use for button taps and minor feedback.
static func light() -> void:
	_vibrate(LIGHT_MS)

## Triggers a medium 30 ms vibration. Use for confirmations and card plays.
static func medium() -> void:
	_vibrate(MEDIUM_MS)

## Triggers a strong 50 ms vibration. Use for impacts and critical events.
static func heavy() -> void:
	_vibrate(HEAVY_MS)

# ---------------------------------------------------------------------------
# Private static methods
# ---------------------------------------------------------------------------

static func _vibrate(duration_ms: int) -> void:
	# vibrate_handheld() is a no-op on unsupported platforms (Web, desktop).
	# No platform check needed — the engine handles graceful degradation.
	Input.vibrate_handheld(duration_ms)
