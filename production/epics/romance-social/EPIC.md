# Epic: Romance & Social

> **Layer**: Feature
> **GDD**: design/gdd/romance-social.md
> **Architecture Module**: RomanceSocial
> **Governing ADRs**: ADR-0010
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories romance-social`

## Overview

Romance & Social is the interaction engine that makes Pillar 3 real: romance IS mechanical investment. It manages a shared daily token pool (3 tokens, UTC midnight reset), a consecutive-day streak multiplier (1.0x-1.5x), a per-companion mood state machine (Content/Happy/Lonely/Annoyed/Excited), gift preference discovery through dates, and social combat buffs (temporary chips+mult bonuses). It is the primary writer of companion relationship state and the emitter of `romance_stage_changed` -- the signal that unlocks divine blessings. It also receives flat relationship/trust deltas from dialogue choices and grants +1 RL on combat victory when a companion is captain.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Romance & Social -- Interaction Engine | RomanceSocial autoload manages all companion interaction logic: tokens, streaks, moods, gifts, dates, combat buffs. Reads/writes via GameStore + CompanionState, emits stage changes via EventBus. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-romance-social-001 | Daily token pool (3 tokens, UTC midnight reset); tokens do not carry over | ADR-0010 |
| TR-romance-social-002 | Streak multiplier: 5-tier lookup table [1.0, 1.1, 1.25, 1.4, 1.5]; camp gains only | ADR-0010 |
| TR-romance-social-003 | Companion mood state machine: Content/Happy/Lonely/Annoyed/Excited | ADR-0010 |
| TR-romance-social-004 | Date sub-system: 4 rounds, 3 activity options, static hidden preference weights | ADR-0010 |
| TR-romance-social-005 | CombatBuff: per-stage lookup for social_buff_chips + social_buff_mult + combats_remaining | ADR-0010 |
| TR-romance-social-006 | Mood persistence: current_mood + mood_expiry_date stored; decay to Content on expiry | ADR-0010 |
| TR-romance-social-007 | Midnight UTC crossing detection while app is open: reset tokens, evaluate streak | ADR-0010 |
| TR-romance-social-008 | Device clock backward protection: negative date gaps treated as 0 | ADR-0010 |
| TR-romance-social-009 | romance_stage_changed(companion_id, old, new) signal; autosave triggered | ADR-0010 |
| TR-romance-social-010 | Dialogue relationship/trust deltas applied verbatim (no streak, no mood modifier) | ADR-0010 |
| TR-romance-social-011 | Captain relationship gain: flat +1 RL on combat victory | ADR-0010 |
| TR-romance-social-012 | CombatBuff persists across sessions (written to save data) | ADR-0010 |
| TR-romance-social-013 | companion_met(companion_id) signal for reactive UI updates | ADR-0010 |
| TR-romance-social-014 | All RL writes clamp to [0, 100]; stage re-evaluated after every write | ADR-0010 |
| TR-romance-social-015 | Date romance_stage snapshotted at entry; live changes during date ignored | ADR-0010 |
| TR-romance-social-016 | Visual/audio feedback: portrait crossfades, particle effects, stage advance ceremony | ADR-0010 |
| TR-romance-social-017 | Talk base RL=3 (Happy +4); Gift RL=2 liked/1 neutral/0 disliked; mood modifies Gift outcomes | ADR-0010 |
| TR-romance-social-018 | Relationship gain formula: floor(base_RL x streak_multiplier); min 1 except base-0 stays 0 | ADR-0010 |
| TR-romance-social-019 | Mood priority: Excited > Happy > Annoyed > Lonely > Content; highest wins on simultaneous triggers | ADR-0010 |
| TR-romance-social-020 | CombatBuff replacement rule: replace if (new_chips + new_mult) > (old_chips + old_mult) | ADR-0010 |
| TR-romance-social-021 | Gift preference discovery only through dates, not gifts | ADR-0010 |
| TR-romance-social-022 | Date activity categories drawn with replacement; 6 categories | ADR-0010 |
| TR-romance-social-023 | Streak increments on gap=1 day; resets on gap >= 2 days; first session ever = streak 1 | ADR-0010 |
| TR-romance-social-024 | romance_stage_changed queued during active dialogue; applied after dialogue_ended | ADR-0010 |
| TR-romance-social-025 | Camp interaction processing within 16ms (one frame at 60fps) | ADR-0010 |
| TR-romance-social-026 | All relationship values, streak thresholds, buff values, mood durations data-driven from config | ADR-0010 |
| TR-romance-social-027 | Stage re-evaluation on save load to catch data desync | ADR-0010 |
| TR-romance-social-028 | Additional companion state fields persisted: current_mood, mood_expiry_date, current_streak, last_interaction_date, daily_tokens_remaining, active_combat_buff | ADR-0010 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/romance-social.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories romance-social` to break this epic into implementable stories.
