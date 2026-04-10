# QA Evidence — STORY SN-001: SceneId Enum + Scene Path Registry

**Story type:** Config
**Date:** 2026-04-10
**File:** `src/autoloads/scene_manager.gd`

## AC1 — SceneId enum present with all required values

Enum `SceneId` declared in `scene_manager.gd` with the following members:

| Value | Member |
|-------|--------|
| 0 | SPLASH |
| 1 | DIALOGUE |
| 2 | COMBAT |
| 3 | HUB |
| 4 | CHAPTER_MAP |
| 5 | COMPANION_ROOM |
| 6 | DATE |
| 7 | INTIMACY |
| 8 | DECK |
| 9 | DECK_VIEWER |
| 10 | EQUIPMENT |
| 11 | EXPLORATION |
| 12 | ABYSS |
| 13 | GALLERY |
| 14 | ACHIEVEMENTS |
| 15 | SETTINGS |

**Result: PASS**

## AC2 — SCENE_PATHS const maps non-SETTINGS SceneIds to res:// paths

`const SCENE_PATHS: Dictionary` contains 15 entries (all SceneIds except
SETTINGS). SETTINGS is intentionally omitted because it overlays the current
scene rather than replacing it.

Spot-check entries:

```
SceneId.SPLASH       → res://src/scenes/splash/splash.tscn
SceneId.COMBAT       → res://src/scenes/combat/combat.tscn
SceneId.HUB          → res://src/scenes/hub/hub.tscn
SceneId.ACHIEVEMENTS → res://src/scenes/achievements/achievements.tscn
```

**Result: PASS**

## AC3 — No direct change_scene_to_file calls outside scene_manager.gd

Command run:
```
grep -r "change_scene_to_file" src/ --include="*.gd" --exclude="scene_manager.gd"
```

Output: no matches.

**Result: PASS**

## AC4 — No raw .tscn path strings outside scene_manager.gd

Command run:
```
grep -r "\.tscn" src/ --include="*.gd" --exclude="scene_manager.gd"
```

Output: no matches.

**Result: PASS**

## Notes

- All callers must use `SceneManager.go_to(SceneManager.SceneId.X)`.
- The deprecated `change_scene(path: String)` overload has been removed.
- SETTINGS overlay logic is deferred to the UI layer (not a scene swap).
