# Epic: Dialogue

> **Layer**: Core
> **GDD**: design/gdd/dialogue.md
> **Architecture Module**: DialogueRunner (autoload #9)
> **Governing ADRs**: ADR-0008
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories dialogue`

## Overview

DialogueRunner is the playback engine for all narrative content in Dark Olympus. It loads JSON dialogue scripts organized by chapter and sequence, plays them node-by-node with typewriter text animation, renders portraits for 4 speaker types (companion, npc, narrator, environment), presents branching choices with condition-gated visibility across 3 tiers (standard, insight, cost), and executes effects (relationship, trust, flag, mood changes) by emitting signals via EventBus rather than writing state directly. The system is stateless between sequences -- all persistent state flows through Story Flow and Romance & Social via signals.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Dialogue -- Script Format + Playback Engine | DialogueRunner as Node/autoload loading JSON scripts with node-graph format. Typewriter via RichTextLabel.visible_characters. 4 speaker types, 3 choice tiers, effect emission via EventBus. State machine: Idle->Loading->Displaying->Waiting/Choosing->Resolving->Ended. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-dialogue-001 | Dialogue scripts as JSON files at res://assets/data/dialogue/{chapter_id}/{sequence_id}.json | ADR-0008 |
| TR-dialogue-002 | Node schema: speaker, speaker_type, text_key, mood, choices, next | ADR-0008 |
| TR-dialogue-003 | Choice schema: tier (standard/insight/cost), condition gating, effects array, next | ADR-0008 |
| TR-dialogue-004 | All text resolution via Localization.get_text(); no internal translation cache | ADR-0008 |
| TR-dialogue-005 | Typewriter text animation at configurable CPS (default 40); tap-to-complete | ADR-0008 |
| TR-dialogue-006 | Portrait system: 200x400 on left; crossfade 0.15s between moods | ADR-0008 |
| TR-dialogue-007 | Choice panel: vertically stacked, 44px min height, max 4 visible choices | ADR-0008 |
| TR-dialogue-008 | Effect system: relationship, trust, flag_set, etc. emit signals, not direct state writes | ADR-0008 |
| TR-dialogue-009 | State machine: Idle->Loading->Displaying->Waiting/Choosing->Resolving->Ended | ADR-0008 |
| TR-dialogue-010 | Root-level gates: requires_met, requires_romance_stage, requires_flag | ADR-0008 |
| TR-dialogue-011 | Text length limit 280 characters per node; truncate at word boundary | ADR-0008 |
| TR-dialogue-012 | Pacing constraints: 6-line cap between interactions; 12-line max between choices | ADR-0008 |
| TR-dialogue-013 | Rapid tap handling: first tap completes typewriter; subsequent same-frame taps ignored | ADR-0008 |
| TR-dialogue-014 | Screen reader support via AccessKit (Godot 4.5+) | ADR-0008 |
| TR-dialogue-015 | Dialogue is stateless between sequences; persistent state via Story Flow or R&S signals | ADR-0008 |
| TR-dialogue-016 | Four speaker types: companion (portrait+mood), npc (portrait, no state), narrator (centered italic, no portrait), environment (distinct panel, icon) | ADR-0008 |
| TR-dialogue-017 | dialogue_ended(sequence_id) and dialogue_blocked(sequence_id, reason) signals for Story Flow | ADR-0008 |
| TR-dialogue-018 | Choice conditions: romance_stage, met, flag_set, flag_not_set, trust_min; evaluated at render time | ADR-0008 |
| TR-dialogue-019 | Effect types: relationship, trust, flag_set, flag_clear, item_grant, mood_set | ADR-0008 |
| TR-dialogue-020 | Pause markers {pause:N} in text (N=0.1-3.0); stripped from visible output | ADR-0008 |
| TR-dialogue-021 | Choice panel slide-in 0.25s ease-out; tap during animation buffered until complete | ADR-0008 |
| TR-dialogue-022 | Failed choice conditions hide choice entirely (not greyed); all-fail ends sequence | ADR-0008 |
| TR-dialogue-023 | start_dialogue() rejected while not in Idle; active sequence continues | ADR-0008 |
| TR-dialogue-024 | Dialogue load to first character rendered within 100ms on target mobile | ADR-0008 |
| TR-dialogue-025 | Priestess NPC: portrait at res://assets/images/npcs/priestess/priestess_{mood}.png; name via get_text('COMP_PRIESTESS') | ADR-0008 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/dialogue.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories dialogue` to break this epic into implementable stories.
