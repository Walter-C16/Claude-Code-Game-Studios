# Epic: Story Flow

> **Layer**: Feature
> **GDD**: design/gdd/story-flow.md
> **Architecture Module**: StoryFlow
> **Governing ADRs**: ADR-0011
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories story-flow`

## Overview

Story Flow sequences the player through chapter-based narrative content. Each chapter is a JSON file of ordered nodes -- dialogue scenes, combat encounters, companion unlocks, and reward beats. It coordinates DialogueRunner and CombatSystem (via SceneManager) while tracking node completion, story flags, and rewards. StoryFlow is the orchestrator: it calls other systems, they don't call it. It supports 6 node types (dialogue, combat, mixed, boss, reward, companion_unlock), write-once story flags for consequence tracking, atomic reward distribution, and combat defeat retry with unlimited attempts and no penalty.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: Story Flow -- Chapter Node Sequencer | StoryFlow autoload loads chapter JSON files and sequences nodes. Calls DialogueRunner for narrative, SceneManager for combat transitions, writes completion state to GameStore. Depends on 5 upstream ADRs (most of any system). | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-story-flow-001 | Chapter data as JSON files at res://assets/data/story/ch{NN}.json | ADR-0011 |
| TR-story-flow-002 | Node types: dialogue, combat, mixed, boss, reward, companion_unlock | ADR-0011 |
| TR-story-flow-003 | Story flags as write-once strings in GameStore.story_flags | ADR-0011 |
| TR-story-flow-004 | Node state machine: not_started -> in_progress -> completed; no backward transitions | ADR-0011 |
| TR-story-flow-005 | Linear node gating: requires_flags + previous node completed | ADR-0011 |
| TR-story-flow-006 | Combat defeat: retry mode (return to Chapter Map, unlimited retries, no penalty) | ADR-0011 |
| TR-story-flow-007 | Reward distribution: atomic on node completion; gold + XP via GameStore; autosave | ADR-0011 |
| TR-story-flow-008 | Companion unlock: sets met=true on node completion + companion reveal animation | ADR-0011 |
| TR-story-flow-009 | Chapter completion: set flag, write current_chapter, emit chapter_completed signal | ADR-0011 |
| TR-story-flow-010 | Force-quit resilience: mixed/combat nodes resume from beginning | ADR-0011 |
| TR-story-flow-011 | Chapter JSON parsing within 50ms for 12-node chapter | ADR-0011 |
| TR-story-flow-012 | No reward values, flag names, or node sequences hardcoded outside chapter JSON | ADR-0011 |
| TR-story-flow-013 | Missing chapter JSON shows 'To be continued' state; no crash | ADR-0011 |
| TR-story-flow-014 | Chapter node schema: id, type, title_key, sequence_id, enemy_id, defeat_mode, post_combat_sequence_id, requires_flags, sets_flags, unlocks_companions, reward, next | ADR-0011 |
| TR-story-flow-015 | Dialogue set_flag effects may only set flags declared in the active node's sets_flags; undeclared flags dropped with warning | ADR-0011 |
| TR-story-flow-016 | Node states persisted: node_states dict + current_node_id + story_flags + player_gold + player_xp in GameStore | ADR-0011 |
| TR-story-flow-017 | Chapter 1 defines 10 nodes (ch01_n00 through ch01_n09) with 11 canonical flags | ADR-0011 |
| TR-story-flow-018 | Boss nodes signal boss music + boss HP bar activation | ADR-0011 |
| TR-story-flow-019 | Completed nodes greyed and non-tappable on Chapter Map; no re-entry | ADR-0011 |
| TR-story-flow-020 | Reward panel: slide-up, gold + XP display; 3s auto-dismiss or tap | ADR-0011 |
| TR-story-flow-021 | Continue defeat mode (reserved): story continues on defeat with defeat-variant flag; not used in Chapter 1 | ADR-0011 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/story-flow.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories story-flow` to break this epic into implementable stories.
