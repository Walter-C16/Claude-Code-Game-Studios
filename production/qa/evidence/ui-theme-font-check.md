# QA Evidence — STORY UT-001: Theme .tres Skeleton + Font Resources

**Story type:** Config
**Date:** 2026-04-10

## AC1 — dark_olympus_theme.tres exists at canonical path

**Canonical path:** `assets/themes/dark_olympus_theme.tres`

File created as a minimal `Theme` resource (Godot .tres format 3).
All scenes should set their `Theme` property to this path.

**Result: PASS**

## AC2 — Cinzel font present as FontFile

**Path:** `assets/fonts/cinzel_regular.tres`

FontFile resource skeleton created with `font_name = "Cinzel"`.

ACTION REQUIRED (manual): Download Cinzel from Google Fonts
(https://fonts.google.com/specimen/Cinzel) and place `Cinzel-Regular.ttf`
(and weights as needed) in `assets/fonts/`. Then open
`assets/fonts/cinzel_regular.tres` in the Godot editor and set the
`font_data` property to point to the downloaded .ttf file.

**Result: SKELETON PASS — manual font data import required**

## AC3 — Nunito Sans font present as FontFile

**Path:** `assets/fonts/nunito_sans_regular.tres`

FontFile resource skeleton created with `font_name = "Nunito Sans"`.

ACTION REQUIRED (manual): Download Nunito Sans from Google Fonts
(https://fonts.google.com/specimen/Nunito+Sans) and place
`NunitoSans-Regular.ttf` (and weights as needed) in `assets/fonts/`.
Then open `assets/fonts/nunito_sans_regular.tres` in the Godot editor
and set the `font_data` property to point to the downloaded .ttf file.

**Result: SKELETON PASS — manual font data import required**

## AC4 — Theme loads within 16.6ms

The skeleton theme contains no embedded data, so load time is negligible.
Once fonts are imported this should be verified with Godot's profiler:
`ResourceLoader.load("res://assets/themes/dark_olympus_theme.tres")` and
confirm the load completes in under 16.6ms.

**Result: ADVISORY — verify after font .ttf files are imported**

## AC5 — All scenes reference dark_olympus_theme.tres

Scenes must set their root Control node's `Theme` property to
`res://assets/themes/dark_olympus_theme.tres` in the Godot editor.

Currently existing scenes: splash, dialogue, combat, hub (stubs).
Each requires a one-time editor property assignment; no code change needed.

**Result: PENDING — assign per-scene in Godot editor after .ttf import**

## Summary of manual steps required

1. Download Cinzel-Regular.ttf → `assets/fonts/`
2. Download NunitoSans-Regular.ttf → `assets/fonts/`
3. In the Godot editor, open `assets/fonts/cinzel_regular.tres` and assign font_data
4. In the Godot editor, open `assets/fonts/nunito_sans_regular.tres` and assign font_data
5. In the Godot editor, assign `dark_olympus_theme.tres` to every scene's root Control node
6. Profile theme load time after step 4 to confirm AC4
