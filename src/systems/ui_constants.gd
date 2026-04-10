class_name UIConstants
extends RefCounted

## UIConstants — Semantic Color Tokens (ADR-0013)
##
## All named colors for Dark Olympus UI.
## Code must use these constants, not raw Color literals.
## Theme .tres references these values by convention; this file is the
## canonical source of truth for every color token in the project.
##
## Usage:
##   label.modulate = UIConstants.TEXT_PRIMARY
##   panel.self_modulate = UIConstants.BG_SECONDARY

# ── Background ──────────────────────────────────────────────────────────────

## Primary screen background — near-black warm brown (#1a1210).
const BG_PRIMARY := Color("#1a1210")

## Secondary panel / card background (#2A1F14).
const BG_SECONDARY := Color("#2A1F14")

## Tertiary / inset surface background (#3a2a1a).
const BG_TERTIARY := Color("#3a2a1a")

# ── Text ─────────────────────────────────────────────────────────────────────

## Primary readable text — warm cream (#F5E6C8). WCAG contrast on BG_PRIMARY: 14.40:1 (AAA).
const TEXT_PRIMARY := Color("#F5E6C8")

## Secondary / subdued text — muted gold (#aa8855).
const TEXT_SECONDARY := Color("#aa8855")

## Disabled / unavailable text — dark muted brown (#6a5a4a).
const TEXT_DISABLED := Color("#6a5a4a")

# ── Accent Gold ──────────────────────────────────────────────────────────────

## Primary brand gold — used for borders, highlights, active states (#D4A843).
const ACCENT_GOLD := Color("#D4A843")

## Bright gold — hover/focus highlight, shimmering VFX (#E8C860).
const ACCENT_GOLD_BRIGHT := Color("#E8C860")

## Dark gold — inactive gold, inactive borders (#8a7030).
const ACCENT_GOLD_DARK := Color("#8a7030")

## Dim gold — deeply subdued, backgrounds behind gold text (#6a5a3a).
const ACCENT_GOLD_DIM := Color("#6a5a3a")

# ── Status ───────────────────────────────────────────────────────────────────

## Positive outcome / success / health in range (#73BF40).
const STATUS_SUCCESS := Color("#73BF40")

## Danger / health critical / destructive action (#D94040).
const STATUS_DANGER := Color("#D94040")

## Warning / caution / partial state (#CCaa33).
const STATUS_WARNING := Color("#CCaa33")

## Error — alias for STATUS_DANGER, used for form validation (#D94040).
const STATUS_ERROR := Color("#D94040")

# ── Element: Fire ────────────────────────────────────────────────────────────

## Fire element foreground — icon / badge text (#F24D26).
const ELEM_FIRE_FG := Color("#F24D26")

## Fire element background — badge / chip fill (#3a1a10).
const ELEM_FIRE_BG := Color("#3a1a10")

# ── Element: Water ───────────────────────────────────────────────────────────

## Water element foreground — icon / badge text (#338CF2).
const ELEM_WATER_FG := Color("#338CF2")

## Water element background — badge / chip fill (#102a3a).
const ELEM_WATER_BG := Color("#102a3a")

# ── Element: Earth ───────────────────────────────────────────────────────────

## Earth element foreground — icon / badge text (#73BF40).
const ELEM_EARTH_FG := Color("#73BF40")

## Earth element background — badge / chip fill (#1a3a10).
const ELEM_EARTH_BG := Color("#1a3a10")

# ── Element: Lightning ───────────────────────────────────────────────────────

## Lightning element foreground — icon / badge text (#CCaa33).
const ELEM_LIGHTNING_FG := Color("#CCaa33")

## Lightning element background — badge / chip fill (#3a3010).
const ELEM_LIGHTNING_BG := Color("#3a3010")
