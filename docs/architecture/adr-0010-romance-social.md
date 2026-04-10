# ADR-0010: Romance & Social — Interaction Engine

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (gameplay logic) |
| **Knowledge Risk** | LOW — Pure GDScript logic. Time API for UTC date checks. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Verify `Time.get_datetime_dict_from_system()` returns UTC consistently across Android/iOS/Web. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore), ADR-0004 (EventBus), ADR-0009 (CompanionState) |
| **Enables** | ADR-0012 (Blessings: stage_changed signal), ADR-0014 (Deck: last_captain_id) |
| **Blocks** | Romance epic, Camp epic |
| **Ordering Note** | Feature layer. Implement after all Foundation + Core ADRs. |

## Context

### Problem Statement

Romance & Social is the system that makes Pillar 3 real: romance IS mechanical investment. It manages daily interaction tokens, streak multipliers, companion moods, gift preference discovery, and social combat buffs. It is the primary writer of companion relationship state and the emitter of `romance_stage_changed` — the signal that unlocks divine blessings.

## Decision

**RomanceSocial is an autoload that manages all companion interaction logic.** It reads/writes companion state via GameStore (ADR-0001) and CompanionState (ADR-0009), emits stage changes via EventBus (ADR-0004), and receives relationship/trust deltas from DialogueRunner via EventBus signals.

### Key Subsystems

1. **Token Pool**: 3 daily tokens, UTC midnight reset. Shared across all companions.
2. **Streak Multiplier**: Consecutive-day engagement tracker. Lookup table: 1.0x-1.5x.
3. **Mood State Machine**: 5 moods (Content, Happy, Lonely, Annoyed, Excited) with trigger-based transitions and expiry dates.
4. **Gift Preferences**: Discovered through dates. 6 categories (romantic, active, intellectual, domestic, adventure, artistic).
5. **Combat Buffs**: Temporary chips+mult bonus lasting N combats. One active at a time. Replacement rule: new > old by sum.
6. **Dialogue Delta Receiver**: Applies flat RL/trust deltas from dialogue choices — no streak multiplier.
7. **Captain Gain**: +1 RL on combat victory with companion as captain.

### Key Interfaces

```gdscript
extends Node

# Camp interactions
func do_talk(companion_id: String) -> Dictionary
func do_gift(companion_id: String, item_id: String) -> Dictionary
func start_date(companion_id: String) -> void

# State queries
func get_token_count() -> int
func get_streak() -> int
func get_streak_multiplier() -> float
func get_mood(companion_id: String) -> int

# Internal — connected in _ready()
func _on_relationship_changed(companion_id: String, delta: int) -> void
func _on_trust_changed(companion_id: String, delta: int) -> void
func _on_combat_completed(result: Dictionary) -> void
func _check_midnight_reset() -> void
```

### Interaction Flow

```
do_talk(id) →
  1. Validate: tokens > 0, met == true
  2. base_rl = 3 (or 4 if Happy mood)
  3. final_rl = floor(base_rl * streak_multiplier)
  4. CompanionState.set_relationship_level(id, current + final_rl)
  5. GameStore.spend_token()
  6. Update mood → GameStore
  7. Return {rl_gain, new_mood, stage_changed}
```

## Alternatives Considered

### Alternative 1: Camp Owns Interaction Logic

- **Rejection Reason**: Camp is a UI layer (Presentation). Interaction logic must be reusable — Camp calls it, but so could future systems (Abyss shop, story events). Logic in an autoload is callable from anywhere.

## Consequences

### Positive
- Centralized romance logic callable from Camp, Story, and future systems
- Single writer for companion relationship state (prevents desync)
- Mood state machine is self-contained and testable

### Negative
- Another autoload (total: 9). Acceptable given it owns persistent interaction state.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| romance-social.md | 3 daily tokens, UTC midnight reset (Rule 1) | Token pool with midnight check |
| romance-social.md | Talk/Gift/Date interactions (Rule 2) | do_talk/do_gift/start_date APIs |
| romance-social.md | Streak multiplier 1.0x-1.5x (Rule 3) | Streak lookup table |
| romance-social.md | Date sub-system 4 rounds (Rule 4) | start_date launches Date scene |
| romance-social.md | Social combat buffs (Rule 6) | Buff generation + GameStore persistence |
| romance-social.md | Dialogue delta reception (Rule 7) | EventBus listener, no streak multiplier |
| romance-social.md | Captain +1 RL on victory (Rule 8) | combat_completed listener |
| romance-social.md | romance_stage_changed on advance (Rule 9) | Via CompanionState.set_relationship_level() |
| camp.md | Camp reads token/mood/streak from R&S | Public query methods |

## Validation Criteria

1. **Unit test**: do_talk at day-5 streak with Happy mood → RL gain = floor(4 * 1.40) = 5.
2. **Unit test**: 3 tokens spent → 4th interaction rejected.
3. **Unit test**: Gift liked at stage 2 → buff {chips:10, mult:0.5, combats:2}.
4. **Unit test**: Dialogue delta -5 applied without streak multiplier.
5. **Unit test**: Captain +1 RL on combat victory.
6. **Integration test**: RL crosses stage threshold → romance_stage_changed emitted → blessing unlocks.

## Related Decisions

- ADR-0001, ADR-0004, ADR-0009 (dependencies)
- ADR-0012 (planned): Blessings — consumes romance_stage_changed
- `design/gdd/romance-social.md` — complete design spec
