# Epic: GameStore + SettingsStore

> **Layer**: Foundation
> **GDD**: ADR-driven (no GDD)
> **Architecture Module**: Core (state management)
> **Governing ADRs**: ADR-0001, ADR-0006
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories game-store`

## Overview

Central mutable state store (GameStore) holding all companion states, story flags, gold, XP, chapter progress, and combat buffs as a single-source-of-truth dictionary. SettingsStore holds player preferences (locale, volume, text speed). Both are autoloads at positions #1 and #2 in boot order. Every gameplay system reads and writes state exclusively through GameStore's public API. No system maintains its own persistent state. Mutations trigger persistence within 1 frame via a dirty-flag + call_deferred pattern that batches all same-frame writes into a single disk flush.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: GameStore -- Centralized State Architecture | Single autoload holds all mutable game state as typed properties; dirty-flag + call_deferred for continuous persistence; atomic write via temp file + rename | LOW |
| ADR-0006: Autoload Boot Order + Layer Dependency Rules | GameStore is autoload #1, SettingsStore is autoload #2; each autoload may only reference autoloads above it during _ready() | LOW |

## GDD Requirements

ADR-driven -- no GDD requirements. GameStore and SettingsStore are pure infrastructure enabling all other systems.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| _(none)_ | _Infrastructure autoloads with no dedicated GDD_ | ADR-0001, ADR-0006 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories game-store` to break this epic into implementable stories.
