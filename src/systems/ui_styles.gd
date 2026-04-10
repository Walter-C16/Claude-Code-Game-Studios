class_name UIStyles
extends RefCounted

## UIStyles — StyleBox Factory (ADR-0013)
##
## Creates pre-configured StyleBoxFlat resources for panels and buttons.
## No ripple effects. Touch feedback is scale 0.97 + color shift (1 frame).
##
## Usage:
##   var panel_style: StyleBoxFlat = UIStyles.standard_panel()
##   var btn_normal: StyleBoxFlat = UIStyles.primary_button_normal()


# ── Panels ────────────────────────────────────────────────────────────────────

## Standard panel: 1px gold border, 8px corner radius. (AC1)
static func standard_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIConstants.BG_SECONDARY
	sb.border_color = UIConstants.ACCENT_GOLD
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	return sb


## Elevated panel: 2px gold border, 12px corner radius, drop shadow. (AC2)
static func elevated_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIConstants.BG_SECONDARY
	sb.border_color = UIConstants.ACCENT_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	return sb


# ── Primary Button ────────────────────────────────────────────────────────────

## Primary button normal state: gold fill, 8px radius. (AC3)
static func primary_button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIConstants.ACCENT_GOLD
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


## Primary button pressed state: darkened gold fill. (AC3, AC4)
## Scale 0.97 applied by the Button node via theme; no ripple. (AC5)
static func primary_button_pressed() -> StyleBoxFlat:
	var sb := primary_button_normal()
	sb.bg_color = UIConstants.ACCENT_GOLD_DARK
	return sb


## Primary button disabled state: tertiary background, disabled border. (AC3)
static func primary_button_disabled() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIConstants.BG_TERTIARY
	sb.border_color = UIConstants.TEXT_DISABLED
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


# ── Secondary Button ──────────────────────────────────────────────────────────

## Secondary button normal state: transparent fill, gold border. (AC3)
static func secondary_button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = UIConstants.ACCENT_GOLD
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


# ── Danger Button ─────────────────────────────────────────────────────────────

## Danger button normal state: transparent fill, danger-red border. (AC3)
static func danger_button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = UIConstants.STATUS_DANGER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb
