# QA Evidence — STORY UT-002: Semantic Color Token Palette

**Story type:** Config/Code  
**Date:** 2026-04-10  
**File under test:** `src/systems/ui_constants.gd`

---

## AC1 — BG, Text, Accent, Status tokens present

**Required tokens:**
`BG_PRIMARY`, `BG_SECONDARY`, `TEXT_PRIMARY`, `TEXT_SECONDARY`, `TEXT_DISABLED`,
`ACCENT_GOLD`, `ACCENT_GOLD_DARK`, `STATUS_SUCCESS`, `STATUS_DANGER`, `STATUS_WARNING`

All 10 required constants are defined in `UIConstants`. Additional tokens also
present: `BG_TERTIARY`, `ACCENT_GOLD_BRIGHT`, `ACCENT_GOLD_DIM`, `STATUS_ERROR`.

**Result: PASS**

---

## AC2 — TEXT_PRIMARY on BG_PRIMARY meets WCAG 4.5:1 contrast

### Method: WCAG 2.1 Relative Luminance

Formula:  
`L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin`

Linearization:  
- If `c_sRGB <= 0.04045`: `c_lin = c_sRGB / 12.92`  
- Else: `c_lin = ((c_sRGB + 0.055) / 1.055) ^ 2.4`

Contrast ratio:  
`CR = (L_lighter + 0.05) / (L_darker + 0.05)`

---

### TEXT_PRIMARY — #F5E6C8

| Channel | 8-bit | sRGB   | Linearized |
|---------|-------|--------|------------|
| R       | 245   | 0.9608 | 0.9145     |
| G       | 230   | 0.9020 | 0.8059     |
| B       | 200   | 0.7843 | 0.5994     |

`L_text = 0.2126 × 0.9145 + 0.7152 × 0.8059 + 0.0722 × 0.5994`  
`L_text = 0.1944 + 0.5764 + 0.0433 = **0.8141**`

---

### BG_PRIMARY — #1a1210

| Channel | 8-bit | sRGB   | Linearized |
|---------|-------|--------|------------|
| R       | 26    | 0.1020 | 0.01444    |
| G       | 18    | 0.0706 | 0.00891    |
| B       | 16    | 0.0627 | 0.00773    |

`L_bg = 0.2126 × 0.01444 + 0.7152 × 0.00891 + 0.0722 × 0.00773`  
`L_bg = 0.003069 + 0.006374 + 0.000558 = **0.01000**`

---

### Contrast Ratio

```
CR = (L_lighter + 0.05) / (L_darker + 0.05)
CR = (0.8141 + 0.05) / (0.01000 + 0.05)
CR = 0.8641 / 0.0600
CR = 14.40:1
```

| Level | Threshold | Result |
|-------|-----------|--------|
| WCAG AA (normal text) | 4.5:1 | **PASS** |
| WCAG AA (large text)  | 3.0:1 | **PASS** |
| WCAG AAA              | 7.0:1 | **PASS** |

**Result: PASS — 14.40:1 (AAA)**

---

## AC3 — Element colors have FG and BG variants

All four element pairs verified in `UIConstants`:

| Element   | FG constant         | BG constant         |
|-----------|---------------------|---------------------|
| Fire      | `ELEM_FIRE_FG`      | `ELEM_FIRE_BG`      |
| Water     | `ELEM_WATER_FG`     | `ELEM_WATER_BG`     |
| Earth     | `ELEM_EARTH_FG`     | `ELEM_EARTH_BG`     |
| Lightning | `ELEM_LIGHTNING_FG` | `ELEM_LIGHTNING_BG` |

**Result: PASS**

---

## AC4 — Code uses UIConstants, not raw hex

`UIConstants` provides all tokens as named `const` values. The coding standard
documented in ADR-0013 requires code to reference `UIConstants.TOKEN_NAME` or
`get_theme_color(&"token_name", &"DarkOlympus")`.

No `Color("#...")` literals appear in any scene script at this time.  
Enforcement: code review blocks any PR introducing `Color(` literals in UI scene scripts.

**Result: PASS (at time of writing — ongoing enforcement required)**

---

## AC5 — No hardcoded Color(...) literals in scene scripts for UI

Verified by grep of `src/scenes/` at time of writing:

```
$ grep -r "Color(" src/scenes/
(no matches)
```

Scenes currently exist as stubs with no color code. As screens are implemented,
`UIConstants` must be the sole source of color values.

**Result: PASS (stub scenes — verify each screen as implemented)**

---

## Token Count Summary

| Category   | Tokens |
|------------|--------|
| Background | 3      |
| Text       | 3      |
| Accent     | 4      |
| Status     | 4      |
| Elements   | 8      |
| **Total**  | **22** |

Exceeds the AC1 minimum of 20 tokens.

**Overall Story Result: PASS**
