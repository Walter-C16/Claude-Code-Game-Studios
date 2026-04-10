# ADR-0011: Story Flow — Chapter Node Sequencer

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (narrative orchestration) |
| **Knowledge Risk** | LOW — JSON loading + GameStore state + SceneManager calls. No post-cutoff APIs. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore: story_flags, node_states, gold, xp), ADR-0003 (SceneManager: scene transitions), ADR-0004 (EventBus: combat_completed, dialogue_ended), ADR-0008 (DialogueRunner: start_dialogue), ADR-0009 (CompanionState: met flag) |
| **Enables** | Story epic, Chapter Map screen |
| **Blocks** | Story content implementation |
| **Ordering Note** | Feature layer. Depends on the most ADRs of any system (5 upstream). Implement after all Core ADRs. |

## Context

### Problem Statement

Story Flow sequences the player through chapter-based narrative content. Each chapter is a JSON file of ordered nodes — dialogue scenes, combat encounters, companion unlocks, and reward beats. It must coordinate DialogueRunner and CombatSystem (via SceneManager) while tracking node completion, story flags, and rewards. It is the orchestrator — it calls other systems, they don't call it.

## Decision

**StoryFlow is an autoload that loads chapter JSON files and sequences nodes.** It calls DialogueRunner for narrative, SceneManager for combat transitions, and writes completion state to GameStore. It listens for combat_completed and dialogue_ended via EventBus to advance the sequence.

### Chapter Data Format

```json
{
  "id": "ch01",
  "nodes": [
    {
      "id": "ch01_n00",
      "type": "combat",
      "enemy_id": "forest_monster",
      "defeat_mode": "retry",
      "requires_flags": [],
      "sets_flags": ["forest_monster_defeated"],
      "reward": {"gold": 10, "xp": 30},
      "next": "ch01_n01"
    },
    {
      "id": "ch01_n01",
      "type": "companion_unlock",
      "sequence_id": "ch01_n01_artemisa",
      "unlocks_companions": ["artemisa"],
      "requires_flags": ["forest_monster_defeated"],
      "sets_flags": ["prologue_complete"],
      "reward": {"gold": 0, "xp": 50},
      "next": "ch01_n02"
    }
  ]
}
```

### Node Execution State Machine

```
NOT_STARTED → IN_PROGRESS → COMPLETED (terminal)
                  ↺ (retry on combat defeat)
```

### Node Type Execution

| Type | Sequence |
|---|---|
| `dialogue` | start_dialogue → await dialogue_ended → rewards + flags |
| `combat` | change_scene(COMBAT, config) → await combat_completed → rewards + flags |
| `mixed` | dialogue → combat → post_combat_dialogue → rewards + flags |
| `boss` | pre_dialogue → combat (boss music) → post_dialogue → rewards + flags |
| `reward` | immediate reward grant → flags |
| `companion_unlock` | dialogue → set met=true → reveal animation → rewards + flags |

### Key Interfaces

```gdscript
extends Node

func load_chapter(chapter_id: String) -> void
func enter_node(node_id: String) -> void
func get_available_nodes() -> Array[Dictionary]
func get_chapter_state() -> Dictionary

# Internal listeners (connected in _ready)
func _on_dialogue_ended(sequence_id: String) -> void
func _on_combat_completed(result: Dictionary) -> void
```

### Flag System

- Write-once strings in `GameStore.story_flags`
- Set atomically when node reaches COMPLETED
- Dialogue `set_flag` effects may only set flags declared in the active node's `sets_flags`
- Chapter 1: 11 flags (forest_monster_defeated through gaia_revealed)

### Reward Distribution

Rewards granted atomically when node transitions to COMPLETED. Gold/XP added to GameStore. Node rewards are flat values from chapter JSON — no formulas.

## Alternatives Considered

### Alternative 1: Scene-Local Story Manager

- **Rejection Reason**: Story state (node completion, flags) must persist across scene changes. An autoload survives scene transitions. Scene-local would lose state when navigating to combat.

## Consequences

### Positive
- Single orchestrator for all narrative sequencing
- Flag system enables consequence tracking across chapters
- Combat defeat handling (retry) is clean — node stays IN_PROGRESS

### Negative
- StoryFlow has the most upstream dependencies (5 ADRs). Complex integration testing required.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| story-flow.md | Chapter JSON at res://assets/data/story/ch{NN}.json (Rule 1) | Chapter data format |
| story-flow.md | 6 node types (Rule 2) | Type-based execution dispatch |
| story-flow.md | Linear with flag-gated unlocks (Rule 3) | requires_flags check on node entry |
| story-flow.md | Write-once story flags (Rule 4) | GameStore.set_flag() idempotent |
| story-flow.md | Node state machine: not_started → in_progress → completed (Rule 3) | State transitions with GameStore persistence |
| story-flow.md | Reward distribution on completion (Rule 5) | Atomic gold/xp add to GameStore |
| story-flow.md | Combat defeat retry (Rule 6) | Node stays in_progress, retry prompt |
| story-flow.md | Chapter completion detection (Rule 7) | chapter_completed signal via EventBus |

## Validation Criteria

1. **Unit test**: Node with requires_flags=["test"], flag not set → node locked.
2. **Unit test**: Node completed → flags set, rewards granted, state = completed.
3. **Unit test**: Combat defeat with retry mode → node stays in_progress.
4. **Unit test**: companion_unlock node → companion.met = true.
5. **Integration test**: Full node sequence: dialogue → combat → rewards → next node available.

## Related Decisions

- ADR-0001, ADR-0003, ADR-0004, ADR-0008, ADR-0009 (dependencies)
- `design/gdd/story-flow.md` — complete design spec
