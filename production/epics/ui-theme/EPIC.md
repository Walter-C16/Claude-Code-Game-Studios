# Epic: UI Theme

> **Layer**: Foundation
> **GDD**: design/gdd/ui-theme.md
> **Architecture Module**: UI (theming, layout)
> **Governing ADRs**: ADR-0013
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories ui-theme`

## Overview

A single Godot Theme .tres resource defines all visual tokens for Dark Olympus. Every Control node in the scene tree inherits from this theme. No screen defines its own colors or fonts. The theme encompasses 20+ semantic color tokens (gold-on-dark-brown mythological palette), a typography scale using Cinzel for display text and Nunito Sans for body text, panel and button StyleBox definitions, touch target minimums (44x44px interactive, 52px primary buttons, 64px list rows), thumb zone layout guidelines for the 430x932 portrait viewport, safe area handling, button press feedback (scale 0.97 + color shift within 1 frame), haptic feedback patterns, and WCAG AA contrast compliance. The theme is loaded once at startup and never modified at runtime.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0013: UI Theme -- Token System + Touch Target Standards | Single Theme .tres with semantic color tokens, typography scale, touch target minimums, thumb zone layout, button feedback pattern, haptic levels, WCAG AA contrast | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ui-theme-001 | Single Godot Theme .tres resource inherited by all Control nodes | ADR-0013 |
| TR-ui-theme-002 | Semantic color palette with 20+ named tokens | ADR-0013 |
| TR-ui-theme-003 | Typography: Cinzel (display) + Nunito Sans (body) bundled as .tres FontFile resources | ADR-0013 |
| TR-ui-theme-004 | Touch targets minimum 44x44px for all interactive elements; primary buttons 52px | ADR-0013 |
| TR-ui-theme-005 | Thumb zone layout for 430x932 portrait: primary actions in bottom 560px | ADR-0013 |
| TR-ui-theme-006 | Safe area handling via DisplayServer.get_display_safe_area() | ADR-0013 |
| TR-ui-theme-007 | Screen transitions: fade through black 200ms out + 200ms in | ADR-0013 |
| TR-ui-theme-008 | Button press feedback within 1 frame (16ms): scale 0.97 + color shift | ADR-0013 |
| TR-ui-theme-009 | Haptic feedback: light 15ms, medium 30ms, heavy 50ms; graceful degradation | ADR-0013 |
| TR-ui-theme-010 | Theme .tres load within 16.6ms (one frame) at startup | ADR-0013 |
| TR-ui-theme-011 | WCAG AA minimum contrast 4.5:1 for TEXT_PRIMARY on BG_PRIMARY | ADR-0013 |
| TR-ui-theme-012 | No ripple effect on buttons; scale-compression + color-shift is the feedback pattern | ADR-0013 |
| TR-ui-theme-013 | Element colors with pre-baked foreground/background variants | ADR-0013 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories ui-theme` to break this epic into implementable stories.
