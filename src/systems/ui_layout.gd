class_name UILayout
extends RefCounted

## UILayout — Touch Target and Layout Constants (ADR-0013)
## Enforces minimum touch targets and thumb zone layout for 430x932 portrait.
##
## Usage:
##   var safe := UILayout.get_safe_area()
##   if not UILayout.is_valid_touch_target(my_button):
##       push_warning("Button below minimum touch target size")

# ── Viewport ──────────────────────────────────────────────────────────────────

## Logical viewport width in pixels (portrait mobile).
const VIEWPORT_WIDTH: int = 430

## Logical viewport height in pixels (portrait mobile).
const VIEWPORT_HEIGHT: int = 932

# ── Touch Targets (minimum dimensions) ───────────────────────────────────────

## Minimum size for any interactive Control (px). Both axes must meet this.
const TOUCH_MIN: int = 44

## Minimum height for primary CTA buttons (px).
const PRIMARY_BUTTON_HEIGHT: int = 52

## Minimum height for list row items (px).
const LIST_ROW_HEIGHT: int = 64

# ── Thumb Zone ────────────────────────────────────────────────────────────────

## Y coordinate where the primary thumb zone begins (932 - 560 = 372px from top).
## Primary action buttons must have their top edge at or below this value.
const THUMB_ZONE_TOP: int = 372

## Height of the primary thumb zone in pixels.
## All primary CTAs must fall within the bottom 560px of the viewport.
const THUMB_ZONE_HEIGHT: int = 560

# ── Margins ───────────────────────────────────────────────────────────────────

## Horizontal side margin applied to all screen content (px).
const SIDE_MARGIN: int = 16

## Usable content width after applying side margins on both sides (px).
const CONTENT_WIDTH: int = 398  # 430 - 16 * 2


## Returns the safe area rect, accounting for notch and home indicator.
## Falls back to full viewport rect if DisplayServer returns a zero-size area.
static func get_safe_area() -> Rect2i:
	var safe := DisplayServer.get_display_safe_area()
	if safe.size == Vector2i.ZERO:
		return Rect2i(0, 0, VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	return safe


## Returns true if the Control meets the minimum touch target size on both axes.
## Use this in debug/editor tooling to audit interactive elements.
static func is_valid_touch_target(control: Control) -> bool:
	return control.size.x >= TOUCH_MIN and control.size.y >= TOUCH_MIN
