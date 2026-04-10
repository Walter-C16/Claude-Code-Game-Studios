# ADR-0012: Divine Blessings — Trigger Evaluation Pipeline

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (gameplay logic) |
| **Knowledge Risk** | LOW — Pure GDScript math. No engine APIs. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — stateless computation. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0007 (Poker Combat: calls BlessingSystem.compute()), ADR-0009 (CompanionState: romance_stage), ADR-0004 (EventBus: romance_stage_changed) |
| **Enables** | None (terminal system — nothing depends on Blessings) |
| **Blocks** | Vertical Slice milestone (blessings demonstrate romance→power pipeline) |
| **Ordering Note** | Feature layer. Implement after Combat + Companion Data ADRs. |

## Context

### Problem Statement

Divine Blessings is the mechanical bridge between Romance & Social and Poker Combat — the system that makes Pillar 3 real. 20 unique blessings (5 per companion) inject bonus chips and multipliers into the scoring pipeline, gated by romance stage. The evaluation must be: (1) stateless (pure function, no side effects), (2) deterministic (same inputs = same output), (3) sequential (slots 1-5 in order, because Nyx Slot 4 depends on prior slots' chips), and (4) fast (<1ms, runs every PLAY action).

## Decision

**BlessingSystem is a stateless utility class (`RefCounted` with static methods) that computes blessing_chips and blessing_mult from a captain's unlocked slots and the current hand context.** It has no persistent state, no signals, no autoload. CombatSystem calls it as a black box during RESOLVE.

### Computation

```gdscript
class_name BlessingSystem
extends RefCounted

static func compute(captain_id: String, romance_stage: int,
        hand_context: Dictionary) -> Dictionary:
    var blessing_chips: int = 0
    var blessing_mult: float = 0.0

    var blessings := _get_blessings_for(captain_id)
    var max_slot := _max_slot_for_stage(romance_stage)

    # Sequential evaluation: slots 1-5 (order matters for Nyx Slot 4)
    for slot in range(1, max_slot + 1):
        var b: Dictionary = blessings[slot]
        if _evaluate_trigger(b, hand_context, blessing_chips):
            blessing_chips += _compute_chips(b, hand_context)
            blessing_mult += _compute_mult(b, hand_context)

    return {"blessing_chips": blessing_chips, "blessing_mult": blessing_mult}

static func _max_slot_for_stage(stage: int) -> int:
    # Stage 0=0, 1=1, 2=2, 3=4, 4=5
    return [0, 1, 2, 4, 5][stage]

static func _evaluate_trigger(blessing: Dictionary, ctx: Dictionary,
        accumulated_chips: int) -> bool:
    # Each blessing has a trigger condition (or "always")
    match blessing.trigger_type:
        "always": return true
        "per_card": return true  # per-card blessings always fire, value scales
        "suit_count": return ctx.suit_counts.get(blessing.suit, 0) >= blessing.min_count
        "hand_rank_min": return ctx.hand_rank_value >= blessing.min_rank
        "cards_played_eq": return ctx.cards_played.size() == blessing.count
        "hands_played_max": return ctx.hands_played <= blessing.max_hands
        "discards_used_min": return ctx.discards_used >= blessing.min_discards
        "discards_remaining_eq": return ctx.discards_remaining == ctx.discards_allowed
        "signature_card": return ctx.signature_card_played
        "accumulated_chips_min": return accumulated_chips >= blessing.min_chips
        "raw_chips_max": return ctx.raw_hand_chips <= blessing.max_chips
        "current_score_gate": return ctx.current_score == 0 or ctx.current_score >= blessing.score_threshold
        "prior_hands_scored": return ctx.hands_scoring_above.get(blessing.threshold, 0) >= 1
    return false
```

### Blessing Data (Data-Driven)

All 20 blessings defined in `res://assets/data/blessings.json`:

```json
{
  "artemisa": [
    {"slot": 1, "stage": 1, "name_key": "BLESSING_ROOTED_GROUND",
     "trigger_type": "per_card", "suit": "Clubs",
     "chips_per_card": 8, "mult_per_card": 0},
    {"slot": 2, "stage": 2, "name_key": "BLESSING_PATIENT_HUNT",
     "trigger_type": "discards_remaining_eq",
     "chips_flat": 20, "mult_flat": 0}
  ]
}
```

### Key Interfaces

```gdscript
class_name BlessingSystem
extends RefCounted

static func compute(captain_id: String, romance_stage: int,
    hand_context: Dictionary) -> Dictionary
# Returns: {blessing_chips: int, blessing_mult: float}
# hand_context: {cards_played, hand_rank, hand_rank_value, suit_counts,
#   current_score, hands_played, discards_used, discards_remaining,
#   discards_allowed, signature_card_played, raw_hand_chips,
#   hands_scoring_above}

static func get_blessing_info(captain_id: String) -> Array[Dictionary]
# Returns all 5 blessings for a companion (for UI display)
```

### Immutability During Combat

BlessingSystem reads `romance_stage` at call time. CombatSystem caches the stage at combat start and passes the cached value. If stage changes mid-combat (edge case), the cached value is used — blessings are frozen at combat start per GDD Rule 6.

## Alternatives Considered

### Alternative 1: Blessing Modifiers Registered on CombatSystem

- **Rejection Reason**: Coupling. CombatSystem would need to import blessing definitions. BlessingSystem as a pure function keeps CombatSystem unaware of blessing internals — it just receives two numbers.

### Alternative 2: BlessingSystem as Autoload

- **Rejection Reason**: BlessingSystem has zero state. It's a pure computation. RefCounted with static methods is the lightest possible implementation.

## Consequences

### Positive
- **Pure function**: No state, no side effects, no signals. Easiest system to unit test.
- **Data-driven**: All 20 blessings in one JSON file. Balance changes require zero code edits.
- **Sequential evaluation**: Slots 1-5 order is explicit, supporting Nyx Slot 4's dependency on prior chips.

### Negative
- **CombatSystem must build hand_context**: The context dictionary has ~12 fields. If one is missing, triggers may evaluate incorrectly. Mitigation: unit test every trigger type.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| divine-blessings.md | 20 blessings, 5 per companion (Kit Design) | Data-driven blessings.json |
| divine-blessings.md | Slot availability by romance_stage (Rule 2) | _max_slot_for_stage() lookup |
| divine-blessings.md | Per-hand trigger evaluation (Rule 3) | compute() called each PLAY |
| divine-blessings.md | blessing_chips/blessing_mult injection (Rule 4) | Return dict consumed by scoring pipeline |
| divine-blessings.md | Sequential slots 1-5, order matters (Rule 3) | for loop 1..max_slot |
| divine-blessings.md | Nyx Slot 4 depends on accumulated chips | accumulated_chips passed to trigger eval |
| divine-blessings.md | Frozen at combat start (Rule 6) | CombatSystem caches romance_stage |
| divine-blessings.md | Per-card variable blessings (F2) | chips_per_card * count_matching |

## Performance Implications

- **CPU**: 5 trigger evaluations + value computations: <0.1ms. Called once per PLAY.
- **Memory**: Blessing data loaded once (~2KB). No persistent state.

## Validation Criteria

1. **Unit test**: Artemisa stage 1, 3 Clubs → blessing_chips = 24, blessing_mult = 0.0.
2. **Unit test**: Atenea stage 2, exactly 3 cards → Calculated Strike triggers: +2.5 mult.
3. **Unit test**: Nyx stage 4, all triggers met → all 5 blessings fire, chips = 66, mult = 9.5.
4. **Unit test**: Stage 0 → compute returns {0, 0.0}.
5. **Unit test**: Hipolita stage 4, worked example from GDD → score matches 869.

## Related Decisions

- ADR-0007: Poker Combat — calls BlessingSystem.compute() in scoring pipeline
- ADR-0009: Companion Data — provides romance_stage and element info
- ADR-0004: EventBus — romance_stage_changed triggers UI updates (not BlessingSystem itself)
- `design/gdd/divine-blessings.md` — complete design spec with all 20 blessings
