# Epic: Save System

> **Layer**: Foundation
> **GDD**: design/gdd/save-system.md
> **Architecture Module**: Core (persistence, file I/O)
> **Governing ADRs**: ADR-0002, ADR-0006
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories save-system`

## Overview

SaveManager is an autoload that provides save_game(), load_game(), has_save(), and delete_save() as a pure I/O service. It does not decide when to save -- that is driven by GameStore's dirty-flag mechanism (ADR-0001). The save format is a single JSON file at user://save.json containing a version stamp, timestamp, GameStore snapshot, and SettingsStore snapshot. Writes are atomic (temp file + rename) to prevent corruption. Version migration runs a chained function that adds default fields for new schema versions. Combat state is intentionally ephemeral and never persisted. Boot position #5, after Localization.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Save System -- Continuous Persistence | SaveManager autoload with atomic write (temp file + rename), version-stamped JSON, chained migration, single save slot; GameStore dirty-flag drives save timing | LOW |
| ADR-0006: Autoload Boot Order + Layer Dependency Rules | SaveManager is autoload #5; calls GameStore.from_dict() + SettingsStore.from_dict() on load | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-system-001 | Single save slot at user://save.json with version-stamped JSON | ADR-0002 |
| TR-save-system-002 | Serialization contract: each autoload implements to_dict() / from_dict() | ADR-0002 |
| TR-save-system-003 | Dirty-flag per-frame autosave: set dirty flag, flush next _process() | ADR-0002 |
| TR-save-system-004 | Atomic writes via temp file + rename to prevent corruption | ADR-0002 |
| TR-save-system-005 | Version migration chain: v1->v2->...->current, adding default fields | ADR-0002 |
| TR-save-system-006 | Combat state is ephemeral (NOT persisted mid-fight) | ADR-0002 |
| TR-save-system-007 | Corrupted save (invalid JSON) returns false from load_game(); does not delete file | ADR-0002 |
| TR-save-system-008 | Save/load within 100ms for typical save file (< 1MB) | ADR-0002 |
| TR-save-system-009 | All save paths and version numbers as configurable constants | ADR-0002 |
| TR-save-system-010 | New Game with existing save requires confirmation dialog before overwriting | ADR-0002 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories save-system` to break this epic into implementable stories.
