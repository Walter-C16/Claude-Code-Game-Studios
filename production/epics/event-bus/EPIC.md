# Epic: EventBus

> **Layer**: Foundation
> **GDD**: ADR-driven (no GDD)
> **Architecture Module**: Core (signal architecture)
> **Governing ADRs**: ADR-0004, ADR-0006
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories event-bus`

## Overview

Cross-system signal relay that decouples layers. All inter-layer communication flows through typed signals on this autoload. EventBus owns no state and no logic -- it is a pure relay declaring ~15 cross-system signals (romance_stage_changed, combat_completed, dialogue_ended, relationship_changed, trust_changed, etc.). Emitting systems call EventBus.signal_name.emit(args), listening systems call EventBus.signal_name.connect(callable), and neither imports the other. Boot position #3, after GameStore, SettingsStore.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: EventBus -- Cross-System Signal Architecture | Lightweight autoload declaring all cross-system signals; pure relay with no state or logic; enforces layer isolation by preventing direct cross-layer imports | LOW |
| ADR-0006: Autoload Boot Order + Layer Dependency Rules | EventBus is autoload #3; no dependencies during _ready() | LOW |

## GDD Requirements

ADR-driven -- no GDD requirements. EventBus is pure infrastructure enabling cross-system communication.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| _(none)_ | _Infrastructure autoload with no dedicated GDD_ | ADR-0004, ADR-0006 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories event-bus` to break this epic into implementable stories.
