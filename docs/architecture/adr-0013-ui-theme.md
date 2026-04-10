# ADR-0013: UI Theme — Token System + Touch Target Standards

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI (theming, layout) |
| **Knowledge Risk** | MEDIUM — Dual-focus system (4.6). FoldableContainer (4.5). |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | FoldableContainer (4.5) optional for Settings. Dual-focus (4.6) — touch-only game, low impact. |
| **Verification Required** | Verify Theme .tres loads within 16.6ms. Verify touch targets work under dual-focus. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (Foundation infrastructure) |
| **Enables** | All screen implementations |
| **Blocks** | No ADR — screens can use default Godot theme temporarily |
| **Ordering Note** | Foundation layer. Deferrable — screens work without custom theme. |

## Context

Dark Olympus has a gold-on-dark-brown mythological aesthetic applied through a single Godot Theme .tres resource. All 17+ screens inherit from this theme. The GDD defines 20+ color tokens, a full typography scale, panel/button styles, and touch target minimums (44x44px).

## Decision

**A single Theme .tres resource defines all visual tokens.** Every Control node in the scene tree inherits from this theme. No screen defines its own colors or fonts. The theme is loaded once at startup and never modified at runtime.

### Token Categories

- **Colors**: 20+ named tokens (BG_PRIMARY, TEXT_PRIMARY, ACCENT_GOLD, element colors, status colors)
- **Typography**: 12 font/size combinations (Cinzel for titles 20-40px, Nunito Sans for body 11-18px)
- **Panels**: Standard (1px gold border, 8px radius), Elevated (2px gold, 12px radius, shadow)
- **Buttons**: Primary (gold fill), Secondary (gold border), Danger (red border), Disabled
- **Touch**: Minimum 44x44px hitbox, 52px primary buttons, 64px list rows

### Layout Zones (430x932 portrait)

```
Top 182px:     Passive zone (titles, gold balance, back button)
182-560px:     Secondary zone (tabs, section headers)
Bottom 560px:  Primary thumb zone (all primary actions here)
Bottom 34px:   Safe area (home indicator)
Top 44px:      Safe area (status bar / notch)
```

### Key Interfaces

Theme is a .tres resource, not code. Screens reference tokens by name:
```gdscript
# In scene .tscn files — theme overrides reference the shared theme
# In code — use theme color lookups:
var gold: Color = get_theme_color(&"accent_gold", &"DarkOlympus")
```

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| ui-theme.md | 20+ color tokens with semantic meaning | Theme .tres with named colors |
| ui-theme.md | Cinzel/Nunito Sans typography scale | Font resources in theme |
| ui-theme.md | 44x44px minimum touch targets | Enforced in all screen implementations |
| ui-theme.md | Thumb zone layout (bottom 60% primary) | Layout guideline for all screens |
| ui-theme.md | Button feedback within 1 frame | Scale 0.97 + color shift pattern |

## Related Decisions

- `design/gdd/ui-theme.md` — complete visual spec
