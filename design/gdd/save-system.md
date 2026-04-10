# Save System

> **Status**: In Design
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-08
> **Implements Pillar**: All pillars (persistence enables all progression)

## Summary

The Save System handles all game state persistence -- serializing companion state, story progress, settings, and gameplay data to JSON at `user://save.json`. It supports version-tracked saves with forward/backward migration, manual save/load, autosave on state change, and save deletion. Three downstream systems (Romance & Social, Equipment, Exploration) depend on it for persistent state.

> **Quick reference** -- Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

The Save System serializes all mutable game state to a single JSON file at `user://save.json` and restores it on load. It provides four operations: save, load, check existence, and delete. Each save is version-stamped to enable schema migration when content updates add new fields (e.g., new companions, new state properties). The system does not decide *what* to save -- each autoload (GameStore, SettingsStore) owns its own serialization via `to_dict()` / `from_dict()` contracts. The Save System orchestrates when and where persistence happens.

## Player Fantasy

The Save System has no direct player fantasy. Its success is invisibility -- the player never worries about losing progress. When they close the app mid-chapter and reopen it a week later, everything is exactly where they left it. The system fails when the player notices it: a lost save, a corrupted load, or a prompt asking them to manage save slots instead of playing the game.

## Detailed Design

### Core Rules

1. **Single save slot.** One save file per device at `user://save.json`. No save slot management UI -- the game auto-continues from the latest state.
2. **Version stamping.** Every save includes a `version` integer. Current version: 1. Incremented when the save schema changes (new fields, removed fields, restructured data).
3. **Serialization contract.** Each autoload that holds mutable state implements `to_dict() -> Dictionary` and `from_dict(data: Dictionary) -> void`. The Save System calls these to collect/restore state. Currently: GameStore, SettingsStore.
4. **Save file structure:**
   ```json
   {
     "version": 1,
     "timestamp": 1712534400,
     "game": { /* GameStore.to_dict() */ },
     "settings": { /* SettingsStore.to_dict() */ }
   }
   ```
5. **Continuous persistence.** The game saves like a server-based live-service game -- every state mutation persists within 1 frame. GameStore and SettingsStore set a dirty flag on any write; SaveManager flushes to disk on the next `_process()` frame if dirty. No player action is ever lost. There is no manual "Save" button -- the game is always saved.
6. **Combat is ephemeral.** Combat encounter state (current hand, score, deck order) is NOT persisted. If the app is killed mid-combat, the player returns to the Chapter Map with a retry prompt. This is intentional -- combat is a discrete challenge, not a persistent state.
7. **Load.** On app launch, if `has_save()` returns true, the splash screen shows "Continue" which calls `load_game()`.
8. **Delete.** From Settings screen. Requires confirmation dialog. Removes the file and resets all autoload state to defaults.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| No Save | Fresh install or after delete | Player starts New Game | Splash shows only "New Game" |
| Save Exists | After first save (manual or auto) | Player deletes save | Splash shows "Continue" + "New Game" |
| Saving | save_game() called | Write completes or fails | Block additional save requests (debounce) |
| Loading | load_game() called | Parse completes or fails | Restore all autoload state from file |

### Interactions with Other Systems

| System | Direction | Data Flow |
|--------|-----------|-----------|
| **GameStore** | This depends on GameStore | Calls `GameStore.to_dict()` to serialize, `GameStore.from_dict()` to restore. GameStore holds companion state, story progress, gold, XP, flags. |
| **SettingsStore** | This depends on SettingsStore | Calls `SettingsStore.to_dict()` / `from_dict()`. Holds volume, locale, text speed. |
| **Romance & Social** | Indirect via GameStore | Romance writes companion state to GameStore; Save System persists GameStore. |
| **Equipment** | Indirect via GameStore | Equipment slots stored in GameStore; persisted by Save System. |
| **Exploration** | Indirect via GameStore | Active dispatches stored in GameStore; persisted by Save System. |
| **Companion Data** | References | Companion Data GDD defines save migration rules for new companions (create default state on load if missing). |
| **Scene Navigation** | Save triggers | Splash screen checks `has_save()` to show Continue vs. New Game. |

## Formulas

No mathematical formulas. The Save System has one timing rule:

### Dirty-Flag Persistence

```
should_save = GameStore._dirty OR SettingsStore._dirty
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `_dirty` | bool | {true, false} | GameStore / SettingsStore | Set true on any write, cleared after save |

**Output:** boolean. Checked every `_process()` frame. Multiple mutations in the same frame batch into a single write. Typical save frequency: 0-3 times per second during active play, 0 during idle.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| **If save file is corrupted (invalid JSON)** | Log error, return false from `load_game()`. Splash shows "New Game" only. Do NOT delete the corrupted file. | Player may want to recover the file manually or report a bug. |
| **If save version is newer than current code** (downgrade) | Log warning, attempt to load anyway. Skip unrecognized keys. | Forward compatibility -- unknown fields are ignored, not fatal. |
| **If save version is older than current code** (upgrade) | Run migration chain: v1->v2->v3->...->current. Each migration adds new default fields. | Backward compatibility -- old saves gain new fields with safe defaults. |
| **If disk is full / write fails** | Return false from `save_game()`. Existing save file is not corrupted (write to temp file first, then rename). | Atomic writes prevent half-written saves. |
| **If dirty flag is set during an in-progress save** | Queue the flag; save again next frame after current write completes. | Prevents concurrent file writes while ensuring no mutation is lost. |
| **If player starts New Game while a save exists** | Prompt confirmation ("This will overwrite your current save"). On confirm, delete existing save and create fresh state. | Prevents accidental progress loss on mobile (easy to mis-tap). |
| **If `from_dict()` receives missing keys** | Each autoload handles missing keys with defaults. Never crash on partial data. | Supports both forward and backward compatibility. |
| **If app is killed mid-save** | Atomic write (temp file + rename) ensures either old save or new save exists, never a partial file. | Mobile apps can be killed at any moment. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| **GameStore** | This depends on GameStore | Hard -- cannot save without GameStore's `to_dict()` contract |
| **SettingsStore** | This depends on SettingsStore | Hard -- settings must persist across sessions |
| **Romance & Social** | Depends on this (indirect) | Soft -- relationship state persists through GameStore; without saves, romance progress resets on app close |
| **Equipment** | Depends on this (indirect) | Soft -- equipment loadout persists through GameStore |
| **Exploration** | Depends on this (indirect) | Soft -- active dispatch missions persist through GameStore |
| **Companion Data** | References | Companion Data GDD specifies save migration behavior for new/missing companions |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `SAVE_BATCH_MODE` | per-frame dirty flag | per-frame / timed (500ms) | Per-frame = zero data loss, more I/O. Timed = slight data loss risk, less I/O. | -- |
| `SAVE_VERSION` | 1 | [1, +inf) | Incremented on schema change; triggers migration chain | N/A (never decrease) |
| Save file path | `user://save.json` | -- | Single configurable path; could support multiple profiles in future | -- |

## Acceptance Criteria

- [ ] **GIVEN** no save file exists, **WHEN** `has_save()` is called, **THEN** returns false.
- [ ] **GIVEN** game state has been modified, **WHEN** `save_game()` is called, **THEN** a valid JSON file exists at `user://save.json` with `version`, `timestamp`, `game`, and `settings` keys.
- [ ] **GIVEN** a valid save file exists, **WHEN** `load_game()` is called, **THEN** GameStore and SettingsStore are populated with the saved values, and returns true.
- [ ] **GIVEN** a corrupted (non-JSON) save file, **WHEN** `load_game()` is called, **THEN** returns false and does not crash.
- [ ] **GIVEN** a save with version < current, **WHEN** loaded, **THEN** migration adds missing fields with default values and the game loads successfully.
- [ ] **GIVEN** a save with an unknown companion ID, **WHEN** loaded, **THEN** unknown entries are ignored; known companions load correctly (per Companion Data GDD edge case).
- [ ] **GIVEN** two GameStore mutations in the same frame, **WHEN** _process() runs, **THEN** exactly one save_game() call occurs (dirty-flag batching).
- [ ] **GIVEN** `delete_save()` is called, **WHEN** the file existed, **THEN** the file is removed and `has_save()` returns false.
- [ ] **GIVEN** disk write failure during save, **WHEN** `save_game()` returns false, **THEN** the previous save file is not corrupted (atomic write).
- [ ] All save paths and version numbers are configurable constants, not hardcoded in logic.
- [ ] Performance: Save/load completes within 100ms for a typical save file (< 1MB).

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the game support multiple save slots (e.g., 3 profiles)? | game-designer | Before Settings screen GDD | Current design is single-slot. Multiple slots add UI complexity. |
| Should autosave show a visual indicator (e.g., spinning icon)? | ux-designer | Before UI implementation | Mobile convention: brief non-blocking indicator. |
| Should save data be encrypted to prevent tampering? | game-designer | Before release | Single-player game -- low priority. Save editing is a player choice. |
| Should cloud save be supported (cross-device sync)? | game-designer | Before Full Vision tier | Would require account system or platform integration (Google Play, iCloud). |
