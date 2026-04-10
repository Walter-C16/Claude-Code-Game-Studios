# ADR-0007: Poker Combat — Scoring Pipeline Architecture

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (gameplay logic) |
| **Knowledge Risk** | LOW — Pure GDScript math and Dictionary operations. No engine-specific APIs beyond basic Node lifecycle. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — scoring is pure math. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore: reads social_buff, last_captain_id), ADR-0004 (EventBus: emits combat_completed) |
| **Enables** | ADR-0012 (Divine Blessings: injects into scoring pipeline), ADR-0011 (Story Flow: consumes combat_completed) |
| **Blocks** | Combat epic, Story Flow epic (both need combat outcomes) |
| **Ordering Note** | Core layer. Implement after all Foundation ADRs. This is the most complex gameplay system. |

## Context

### Problem Statement

Poker Combat is the core action loop. The player selects cards, forms poker hands, and scores chips x mult against an enemy's HP threshold. The scoring pipeline must support 7 distinct additive and multiplicative sources that inject at specific positions. The pipeline must be extensible (Abyss Mode will add more sources) without modifying the core scoring logic.

### Constraints

- **Performance**: Scoring computes on every PLAY action. Must complete in <1ms including blessing evaluation.
- **Determinism**: Same cards + same state = same score. No randomness in scoring.
- **Extensibility**: Divine Blessings, social buffs, and Abyss enhancements all inject into the pipeline without CombatSystem knowing their internal logic.
- **Scene-local**: CombatSystem lives only during the combat scene. No persistent state. On crash, combat restarts.

### Requirements

- 52-card deck (4 suits x 13 values), shuffled per encounter
- 10 poker hand ranks with defined base chips/mult
- Strictly ordered scoring pipeline: additive chips → additive mult → multiplicative mult → floor
- Element-suit mapping (Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning)
- Element weakness (+25 chips, +0.5 mult per card) and resistance (-15 chips per card)
- Captain stat bonus (STR→chips, INT→mult modifier)
- Card enhancements (Foil +50 chips, Holo +10 mult, Poly x1.5 mult)
- Injection points for blessing_chips, blessing_mult, social_buff_chips, social_buff_mult
- Victory: current_score >= score_threshold. Checked after each PLAY.
- 4 hands allowed, 4 discards allowed (configurable per enemy)

## Decision

**CombatSystem is a scene-local Node that owns the combat encounter lifecycle and scoring pipeline.** It receives configuration (enemy, captain, deck, buffs) at start, runs the DRAW→SELECT→PLAY/DISCARD loop, and emits `combat_completed` via EventBus on victory or defeat.

### Scoring Pipeline (Strict Order)

```
CHIPS (all additive, summed):
  total_chips = base_hand_chips              [from hand rank table]
              + sum(card_chips per played card)  [2-11 per card]
              + sum(foil_chips: +50 per Foil card)
              + blessing_chips               [from BlessingSystem.compute()]
              + sum(element_chips per card)   [+25 weak, -15 resist, 0 neutral]
              + captain_chip_bonus           [floor(STR * 0.5)]
              + social_buff_chips            [from GameStore combat buff]

  total_chips = max(1, total_chips)          [CLAMP — score >= 1 always]

MULT (additive sources, summed):
  additive_mult = base_hand_mult             [from hand rank table]
                + sum(holo_mult: +10 per Holo card)
                + blessing_mult              [from BlessingSystem.compute()]
                + sum(element_mult per card)  [+0.5 per weak card]
                + social_buff_mult           [from GameStore combat buff]

  additive_mult = max(1.0, additive_mult)    [CLAMP]

MULT (multiplicative sources, chained):
  final_mult = additive_mult
             * product(1.5 for each Polychrome card)
             * captain_mult_modifier         [1.0 + (INT * 0.025)]

SCORE:
  score = floor(total_chips * final_mult)
```

### Hand Rank Table

| Rank | Base Chips | Base Mult | Cards Required |
|---|---|---|---|
| High Card | 5 | 1 | No pattern |
| Pair | 10 | 2 | 2 same value |
| Two Pair | 20 | 2 | 2 different pairs |
| Three of a Kind | 30 | 3 | 3 same value |
| Straight | 30 | 4 | 5 consecutive (A-2-3-4-5 wraps) |
| Flush | 35 | 4 | 5 same suit |
| Full House | 40 | 4 | 3 + 2 same value |
| Four of a Kind | 60 | 7 | 4 same value |
| Straight Flush | 100 | 8 | 5 same suit + consecutive |
| Royal Flush | 100 | 8 | 10-J-Q-K-A same suit |

Data-driven: loaded from `res://assets/data/hand_ranks.json`, not hardcoded.

### Combat State Machine

```
SETUP → DRAW → SELECT → RESOLVE → (VICTORY | DRAW)
                  ↓
            DISCARD_DRAW → SELECT
                  
DEFEAT: hands_remaining == 0 AND current_score < threshold
```

| State | Entry | Valid Actions | Exit |
|---|---|---|---|
| SETUP | Encounter initiated | None (auto) | DRAW |
| DRAW | After SETUP or PLAY with hands remaining | None (auto) | SELECT |
| SELECT | After DRAW or DISCARD | PLAY (1-5 cards) or DISCARD (1-5 cards) | RESOLVE or DISCARD_DRAW |
| RESOLVE | Player plays hand | None (auto: score, check victory) | VICTORY, DEFEAT, or DRAW |
| DISCARD_DRAW | Player discards | None (auto: remove + redraw) | SELECT |
| VICTORY | current_score >= threshold | Continue | Terminal |
| DEFEAT | hands_remaining == 0 | Retry or Retreat | Terminal |

### Element System

```
Fire > Earth > Lightning > Water > Fire

Suit mapping: Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning

Per card vs enemy element:
  Weak (card beats enemy):    +25 chips, +0.5 mult
  Resist (card = enemy):      -15 chips
  Neutral:                    0
  Enemy=None:                 all interactions disabled
```

### Key Interfaces

```gdscript
# CombatSystem (scene-local, in combat.tscn)
extends Node

# Signals (local, not on EventBus — these are intra-scene)
signal hand_scored(score: int, breakdown: Dictionary)
signal state_changed(new_state: String)

# Setup
func start_combat(config: Dictionary) -> void
# config: {
#   enemy: {name_key, score_threshold, hp, element, hands_allowed, discards_allowed},
#   captain: {id, str, int, element, card_value},
#   deck: Array[Dictionary],  # 52 CardData dicts, shuffled
#   social_buff: {chips: int, mult: float, combats_remaining: int},
#   blessings: Array[Dictionary]  # pre-cached unlocked blessings for captain
# }

# Player actions
func play_hand(selected_indices: Array[int]) -> void
func discard(selected_indices: Array[int]) -> void
func toggle_sort() -> void

# State queries
func get_state() -> Dictionary
# Returns: {current_score, score_threshold, hands_remaining, discards_remaining,
#           hand_cards: Array[Dictionary], state: String}

# Internal
func _evaluate_hand(cards: Array[Dictionary]) -> Dictionary
# Returns: {rank: String, base_chips: int, base_mult: float}

func _score_hand(cards: Array[Dictionary], hand_eval: Dictionary) -> int
# Runs full pipeline, returns final score

func _check_victory() -> void
# Emits combat_completed via EventBus if victory or defeat
```

### Blessing Integration

CombatSystem does NOT know blessing logic. It calls BlessingSystem as a black box:

```gdscript
# In _score_hand():
var blessing_result := BlessingSystem.compute(
    _captain_id, _captain_romance_stage, {
        "cards_played": cards,
        "hand_rank": hand_eval.rank,
        "suit_counts": _count_suits(cards),
        "current_score": _current_score,
        "hands_played": _hands_played,
        "discards_used": _discards_used,
        "discards_remaining": _discards_remaining,
        "signature_card_played": _has_signature(cards),
        "raw_hand_chips": hand_eval.base_chips + _sum_card_chips(cards)
    }
)
# blessing_result = {blessing_chips: int, blessing_mult: float}
```

BlessingSystem is a pure function (ADR-0012). CombatSystem treats its output as two numbers to add to the pipeline.

## Alternatives Considered

### Alternative 1: Plugin/Modifier Pattern

- **Description**: Each scoring source (blessings, buffs, elements, captain) registers a modifier function. CombatSystem iterates registered modifiers in priority order.
- **Pros**: Fully extensible. New sources added without modifying CombatSystem. Open-closed principle.
- **Cons**: Registration order determines score. Debugging "why did I get this score?" requires tracing N modifier functions. Priority conflicts between modifiers. Overkill for a known, bounded set of 7 sources.
- **Rejection Reason**: The scoring sources are known and finite (7 in MVP, maybe 2-3 more in Abyss). A fixed pipeline with named injection points is simpler to debug, test, and explain to players. If Abyss adds sources beyond the current pipeline, refactor to plugins then.

### Alternative 2: Monolithic Scoring Function

- **Description**: One giant function that computes everything inline — no injection points, no BlessingSystem call.
- **Pros**: Everything visible in one function. No abstraction overhead.
- **Cons**: 200+ lines. Untestable in isolation. Blessing logic mixed with combat logic. Adding Abyss modifiers requires editing the core scoring function.
- **Rejection Reason**: Violates separation of concerns. BlessingSystem has 20 blessings with individual triggers — embedding that logic in CombatSystem would make both untestable.

## Consequences

### Positive

- **Debuggable**: Each pipeline step produces a named value. The `hand_scored` signal carries a full breakdown Dictionary showing every source's contribution.
- **Testable**: Each step can be unit-tested independently. BlessingSystem is tested separately from CombatSystem.
- **Extensible**: Abyss Mode adds new chip/mult sources at the same injection points. No pipeline refactoring needed.
- **Data-driven**: Hand rank values, element bonuses, enhancement values are all loaded from config. Balance tuning requires no code changes.

### Negative

- **Fixed pipeline order**: The strict ordering (additive chips → additive mult → multiplicative mult) is baked in. If a future source needs a different position (e.g., "multiply chips before adding blessings"), the pipeline structure must be revised. Mitigation: current GDD design exhaustively specifies the order. No known case requires reordering.

### Risks

- **Score overflow at high Abyss antes**: 5 Polychrome cards = 1.5^5 = 7.59x multiplicative, combined with high mult sources. Scores can reach millions. Mitigation: GDScript uses 64-bit integers. `floor()` on large floats works up to 2^53. Verify display formatting handles large numbers.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| poker-combat.md | 52-card deck, 10 hand ranks (Rule 1, 4) | Deck build + hand evaluation |
| poker-combat.md | Scoring pipeline: chips x mult with 7 sources (Rule 5) | Strict ordered pipeline with named injection points |
| poker-combat.md | Element weakness/resistance per card (Rule 6) | Element interaction in chip/mult accumulation |
| poker-combat.md | Captain stat bonus STR→chips, INT→mult (Rule 7) | captain_chip_bonus + captain_mult_modifier in pipeline |
| poker-combat.md | Card enhancements: Foil/Holo/Poly (Rule 8) | Per-card enhancement bonuses at injection points |
| poker-combat.md | Victory: current_score >= threshold (Rule 10) | Victory check after each PLAY |
| poker-combat.md | 4 hands, 4 discards default (Rule 2-3) | Configurable per enemy via config dict |
| poker-combat.md | Clamp: chips min 1, mult min 1.0 (Rule 5) | max(1, total_chips), max(1.0, additive_mult) |
| poker-combat.md | combat_completed signal (Rule 10) | Emitted via EventBus on victory or defeat |
| divine-blessings.md | blessing_chips/blessing_mult injection (Rule 4) | BlessingSystem.compute() called during _score_hand() |
| romance-social.md | social_buff_chips/social_buff_mult (Rule 6) | Read from config at combat start |
| deck-management.md | combat_configured signal provides deck + captain (Rule 6) | CombatSystem.start_combat() receives this config |

## Performance Implications

- **CPU**: Scoring pipeline: ~0.1ms per PLAY (7 additive sources + 1 multiplicative chain + floor). BlessingSystem.compute(): ~0.1ms (5 trigger evaluations). Total: <0.5ms per hand. Well within 16.6ms frame budget.
- **Memory**: 52 CardData dicts (~5KB) + combat state (~1KB). Negligible.
- **Load Time**: Hand rank config file: <0.1ms parse.

## Migration Plan

Existing combat prototype in `src/scenes/combat/` has a working scoring system. Refactor to match this pipeline specification: add named injection points, integrate BlessingSystem call, emit via EventBus instead of direct signal.

## Validation Criteria

1. **Unit test**: Pair of 7s, no bonuses → score = floor((10+31) * 2.0) = 82.
2. **Unit test**: 5 Hearts Flush vs Earth enemy with Hipolita captain → verify all element, captain, and enhancement bonuses apply correctly per worked example in GDD.
3. **Unit test**: All 5 resist-element cards → chips clamp to 1, score = floor(1 * mult).
4. **Unit test**: Victory detected when current_score crosses threshold mid-hand.
5. **Unit test**: Defeat detected when hands_remaining == 0 and score < threshold.
6. **Unit test**: BlessingSystem returns {0, 0.0} → scoring works identically (graceful without blessings).
7. **Integration test**: Full combat flow: SETUP → DRAW → SELECT → PLAY → VICTORY → combat_completed signal received by StoryFlow.

## Related Decisions

- ADR-0001: GameStore — social_buff read at combat start
- ADR-0004: EventBus — combat_completed signal
- ADR-0012 (planned): Divine Blessings — BlessingSystem.compute() is the injection interface
- ADR-0014 (planned): Deck Management — provides combat_configured config
- `design/gdd/poker-combat.md` — complete design spec
