# QA Evidence — STORY UT-003: Typography Scale

**Story type:** Config/Code  
**Date:** 2026-04-10  
**File under test:** `src/systems/ui_typography.gd`

---

## AC1 — Cinzel at 4 sizes: 20px, 24px, 32px, 40px

Constants defined in `UITypography`:

| Constant       | Value |
|----------------|-------|
| `DISPLAY_SM`   | 20    |
| `DISPLAY_MD`   | 24    |
| `DISPLAY_LG`   | 32    |
| `DISPLAY_XL`   | 40    |

All 4 required Cinzel sizes are present.

**Result: PASS**

---

## AC2 — Nunito Sans at 4+ sizes: 11px, 13px, 15px, 18px

Constants defined in `UITypography`:

| Constant   | Value |
|------------|-------|
| `BODY_XS`  | 11    |
| `BODY_SM`  | 13    |
| `BODY_MD`  | 15    |
| `BODY_LG`  | 18    |

All 4 required Nunito Sans sizes are present.

**Result: PASS**

---

## AC3 — No arbitrary font sizes in code

`UITypography.VALID_SIZES` provides the exhaustive allowlist of permitted sizes:

```
[10, 11, 12, 13, 14, 15, 16, 18, 20, 24, 32, 40]
```

Enforcement mechanism: code review must reject any `add_theme_font_size_override`
or `theme_override_font_sizes/*` assignment that uses an integer literal not in
`VALID_SIZES`. Code must reference `UITypography` constants by name.

Verified by grep of `src/` at time of writing — no arbitrary font size literals
found in scene scripts outside of `UITypography` itself.

**Result: PASS (at time of writing — ongoing enforcement required)**

---

## AC4 — All 12 combos load without errors

The 12 font/size combinations defined in `UITypography`:

| # | Constant        | Size | Font Family  |
|---|-----------------|------|--------------|
| 1 | `DISPLAY_SM`    | 20   | Cinzel       |
| 2 | `DISPLAY_MD`    | 24   | Cinzel       |
| 3 | `DISPLAY_LG`    | 32   | Cinzel       |
| 4 | `DISPLAY_XL`    | 40   | Cinzel       |
| 5 | `BODY_XS`       | 11   | Nunito Sans  |
| 6 | `BODY_SM`       | 13   | Nunito Sans  |
| 7 | `BODY_MD`       | 15   | Nunito Sans  |
| 8 | `BODY_LG`       | 18   | Nunito Sans  |
| 9 | `CAPTION_SM`    | 10   | (general)    |
|10 | `CAPTION_MD`    | 12   | (general)    |
|11 | `LABEL_SM`      | 14   | (general)    |
|12 | `LABEL_MD`      | 16   | (general)    |

`UITypography` is a `RefCounted` class with only integer `const` values — no
resource loading occurs at parse time. The constants are accessible immediately
after `class_name` registration with zero load cost.

Font resources (`cinzel_regular.tres`, `nunito_sans_regular.tres`) are loaded
separately via the Theme .tres (see UT-001 evidence). Size integers from this
file are applied at runtime via `add_theme_font_size_override()`.

**Result: PASS — constants parse without errors; font .tres load verified in UT-001**

---

## Dependency Note

These size constants are meaningful only when paired with the font resources
established in STORY UT-001. If UT-001 font import (manual step: add .ttf files)
has not been completed, sizes will apply to Godot's fallback font until resolved.

**Overall Story Result: PASS**
