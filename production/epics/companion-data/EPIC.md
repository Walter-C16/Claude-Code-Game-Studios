# Epic: Companion Data

> **Layer**: Core
> **GDD**: design/gdd/companion-data.md
> **Architecture Module**: CompanionRegistry (autoload) + CompanionState (RefCounted)
> **Governing ADRs**: ADR-0009, ADR-0006
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories companion-data`

## Overview

Every system in Dark Olympus references companion data. The Companion Data epic implements two modules: CompanionRegistry, a read-only autoload that loads immutable companion profiles (name, stats, element, portraits) from `companions.json` at boot; and CompanionState, a RefCounted logic layer that provides typed access to mutable companion fields (relationship_level, trust, mood, romance_stage) stored in GameStore. Together they serve 10+ downstream consumers -- Combat, Dialogue, Romance, Blessings, Deck, Camp, and Story Flow -- without circular dependencies.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0009: Companion Data -- Registry + State Schema | Two modules: CompanionRegistry (autoload, static profiles from JSON) + CompanionState (RefCounted, static methods over GameStore). romance_stage derived from RL thresholds, never decreases. | LOW |
| ADR-0006: Autoload Boot Order + Layer Dependency Rules | CompanionRegistry is autoload #7. Each autoload may only reference autoloads above it during _ready(). | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-companion-data-001 | Companion registry as immutable static dictionary keyed by string ID | ADR-0009 |
| TR-companion-data-002 | Mutable companion state record per companion persisted via Save System | ADR-0009 |
| TR-companion-data-003 | Romance stage derived from relationship_level via threshold array; stage never decreases | ADR-0009 |
| TR-companion-data-004 | Portrait path convention with 6 mood variants per companion; fallback to neutral then placeholder | ADR-0009 |
| TR-companion-data-005 | Element-to-suit mapping (Fire=Hearts, Water=Diamonds, Earth=Clubs, Lightning=Spades) as shared enum | ADR-0009 |
| TR-companion-data-006 | Stage transition emits romance_stage_changed signal for downstream systems | ADR-0009 |
| TR-companion-data-007 | Save migration: create default state for missing companions on load; ignore unknown IDs | ADR-0009 |
| TR-companion-data-008 | All companion values data-driven; no hardcoded stats, thresholds, or portrait paths | ADR-0009 |
| TR-companion-data-009 | Companion data lookup within 1ms (dictionary access) | ADR-0009 |
| TR-companion-data-010 | Clamp relationship_level to [0, 100] on any write | ADR-0009 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/companion-data.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories companion-data` to break this epic into implementable stories.
