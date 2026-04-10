# ADR-0014: Deck Management — Captain Selection + Handoff

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (pre-combat UI flow) |
| **Knowledge Risk** | LOW — Dictionary operations, signal emission. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore: last_captain_id), ADR-0004 (EventBus: combat_configured), ADR-0009 (CompanionRegistry: stats, met flag) |
| **Enables** | ADR-0007 (Poker Combat: receives combat_configured config) |
| **Blocks** | Combat flow (captain selection must happen before combat) |
| **Ordering Note** | Feature layer. Deferrable — can use a default captain for early prototyping. |

## Context

Deck Management lets the player choose a captain companion before combat and view their 52-card deck. In Story Mode, the deck is a standard unmodified set. The captain's STR/INT stats produce combat bonuses. The system emits `combat_configured` via EventBus to initialize CombatSystem.

## Decision

**DeckManager is a scene-local Node that manages captain selection and deck building.** It reads companion profiles from CompanionRegistry, builds a 52-card deck, computes captain stat bonuses, and emits the `combat_configured` signal.

### Key Interfaces

```gdscript
extends Node

signal combat_configured(config: Dictionary)
# config: {captain_id, captain_chip_bonus, captain_mult_bonus, deck: Array[Dictionary]}

func build_deck() -> Array[Dictionary]  # 52 cards, shuffled
func get_captain_chip_bonus(str_val: int) -> int  # floor(STR * 0.5)
func get_captain_mult_bonus(int_val: int) -> float  # 1.0 + (INT * 0.025)
```

### State Machine

```
CAPTAIN_SELECT → COMPANION_HIGHLIGHTED → CAPTAIN_CONFIRMED → HANDOFF_EMITTED
                                              ↕
                                         DECK_VIEWER (read-only overlay)
```

### Deck Composition (Story Mode)

52 cards: 4 suits x 13 values (2-14). Each companion has a signature card tagged with their portrait. Deck shuffled once at handoff via `Array.shuffle()`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| deck-management.md | Captain selection with met-gated grid (Rule 3) | CompanionRegistry.met filter |
| deck-management.md | Captain stat bonuses STR→chips, INT→mult (Rule 4) | Formulas from Poker Combat GDD |
| deck-management.md | combat_configured signal (Rule 6) | EventBus emission |
| deck-management.md | 52-card deck, signature cards tagged (Rules 1-2) | build_deck() |
| deck-management.md | Last captain persisted (Rule 5) | GameStore.last_captain_id |

## Related Decisions

- ADR-0007: Poker Combat — consumes combat_configured
- ADR-0009: Companion Data — provides stats and met flag
- `design/gdd/deck-management.md` — complete design spec
