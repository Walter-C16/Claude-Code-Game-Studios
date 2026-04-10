# Romance & Social

> **Status**: In Design
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-09
> **Implements Pillar**: Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Romance & Social manages all companion relationship progression in Dark Olympus — the daily interactions (talk, gift, date), streak-based engagement rewards, dynamic companion moods, gift preference discovery, and social combat buffs that bridge romance investment into poker combat power. It is the primary writer of companion state (relationship_level, trust, dates_completed, known_likes, known_dislikes) and the system that makes Pillar 3's promise real: romance IS mechanical investment.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Companion Data, Save System`

## Overview

Romance & Social is the system through which players build and deepen relationships with the four companion goddesses. At Camp, players spend daily interaction tokens — talking to learn personality, gifting to discover preferences, and dating to earn the largest relationship gains. Each companion tracks a dynamic mood influenced by recent interactions, which colors dialogue responses and subtly affects interaction outcomes. Consecutive daily engagement builds streaks that multiply relationship point gains, rewarding consistent investment over sporadic attention. As relationship levels cross stage thresholds (Stranger -> Acquaintance -> Friend -> Close -> Devoted), new mechanics unlock: date activities, visible gift preferences, intimacy scenes, and divine blessing slots that directly enhance poker combat scoring. Before combat, players can activate a social buff — a temporary chips-and-multiplier bonus lasting a set number of fights — converting social investment into tangible combat power. The system also receives relationship and trust changes from dialogue choices during story sequences and may award small relationship gains when a companion serves as combat captain. Every interaction feeds back into the core loop: invest in romance, grow stronger in combat, progress further in the story, unlock deeper romance.

## Player Fantasy

**"The Bridge Between Worlds"**

You exist between the mortal and the divine. Camp is the quiet space between battles where fallen goddesses let themselves be people — petty, funny, jealous, tender. You are not worshipping them; you are *seeing* them. Artemisa teases you about your terrible aim. Hipolita challenges you to a sparring match she knows you'll lose. Nyx sits in silence beside you and that silence means more than any prayer.

The fantasy is intimacy with beings who terrify everyone else. Every talk, every gift, every date is a small act of choosing to show up for someone the world forgot. The companion mood system makes each visit feel like reading a real person — sometimes she's warm, sometimes distant, and learning which offerings reach her on a bad day is its own reward. When you discover that Artemisa lights up at wildflowers but rolls her eyes at gold, you know something no other mortal knows.

The combat buffs are not transactional. They are what happens when a goddess actually trusts someone. The first time a social buff turns a losing poker hand into a win, the player should feel the cause-and-effect chain: "I sat with her at camp, I learned what she likes, I showed up every day — and now she's fighting for me." Romance is not a side activity. It is the reason you win.

## Detailed Design

### Core Rules

**Rule 1 — Daily Token Pool.**
Each calendar day (UTC date at session start, stored as `last_interaction_date`) the player receives **3 interaction tokens**. Tokens reset at midnight UTC. Unused tokens do not carry over. One token is spent per camp interaction (Talk, Gift, or Date). A single companion may receive multiple interactions per day. The token pool is shared across all companions — spending 2 on Artemisa leaves 1 for anyone else.

**Rule 2 — Camp Interactions.**
Three interaction types available at Camp:

| Interaction | Token Cost | Base RL Gain | Gate |
|---|---|---|---|
| Talk | 1 | +3 | `met = true` |
| Gift | 1 | +2 (liked) / +1 (neutral/unknown) / 0 (disliked) | `met = true` |
| Date | 1 | +5 per round minimum (see Rule 4) | `romance_stage >= 1` |

- **Talk**: Short dialogue exchange (2-3 lines) from the companion's current mood pool. No player choice. Always +3 RL regardless of mood, but dialogue text reflects mood. Mood_Happy bonus: +4 instead of +3.
- **Gift**: Player selects a gift item from inventory. Liked gifts (+2 RL, happy mood response), disliked gifts (0 RL, sad/angry response), unknown/neutral gifts (+1 RL, neutral response). Gifting does NOT discover preferences — discovery is exclusive to dates (Rule 5).
- **Date**: Launches the Date sub-scene. Gated behind romance_stage >= 1. Awards are calculated per Rule 4.

**Rule 3 — Streak Multiplier.**
A streak counts consecutive calendar days with at least 1 interaction token spent (any companion). Increments when current date is exactly 1 day after `last_interaction_date`. Gap of 0 days (same day): no increment. Gap of 2+ days: streak resets to 0; next interaction starts at day 1.

| Streak (days) | Multiplier |
|---|---|
| 1 | 1.00x |
| 2 | 1.10x |
| 3-4 | 1.25x |
| 5-6 | 1.40x |
| 7+ | 1.50x |

Applied as: `final_RL_gain = floor(base_RL_gain x streak_multiplier)`. Minimum 1 after floor (except base 0 from disliked gift remains 0). Streak applies to Talk, Gift, and Date gains only — NOT to dialogue signals or captain gains.

**Rule 4 — Date Sub-System.**
A date consists of **4 rounds**. Each round presents 3 activity options drawn from 6 categories (romantic, active, intellectual, domestic, adventure, artistic). Each companion has static hidden preference weights per category.

| Round Outcome | RL Gain |
|---|---|
| Liked activity | +8 |
| Neutral activity | +5 |
| Disliked activity | +3 |

Full date range: +12 (all disliked) to +32 (all liked). Streak multiplier applies to the total. `dates_completed` increments by 1 after completion. A date also grants a CombatBuff (Rule 6). Mood_Excited bonus: +2 additional RL per round.

**Rule 5 — Gift Preference Discovery.**
Preferences are discovered through dates, not gifts. During a date, when a liked or disliked activity is selected:
- If the activity category is not in `known_likes` or `known_dislikes`, add it to the appropriate array.
- Already-known preferences are not duplicated.

Loop: date to discover preferences -> gift to exploit knowledge for reliable RL gains without the full date scene. At romance_stage 2 (Friend), the Camp UI displays hint icons on gift items matching `known_likes`.

**Rule 6 — Social Combat Buffs.**
Certain interactions grant a CombatBuff — temporary `social_buff_chips` + `social_buff_mult` lasting `combats_remaining` fights. No buff at stage 0 (Stranger). Talk never grants a buff.

| Stage | Trigger | social_buff_chips | social_buff_mult | combats_remaining |
|---|---|---|---|---|
| 1 | Gift (liked) | +5 | +0.5 | 2 |
| 1 | Date complete | +10 | +1.0 | 3 |
| 2 | Gift (liked) | +10 | +0.5 | 2 |
| 2 | Date complete | +15 | +1.0 | 3 |
| 3 | Gift (liked) | +15 | +1.0 | 3 |
| 3 | Date complete | +20 | +1.5 | 4 |
| 4 | Gift (liked) | +20 | +1.0 | 3 |
| 4 | Date complete | +25 | +2.0 | 5 |
| 3-4 | Intimacy | +30 | +2.5 | 5 |

- Only one CombatBuff active at a time. New buff replaces old if `(new_chips + new_mult) > (old_chips + old_mult)`; otherwise existing buff is retained.
- On combat **victory**: `combats_remaining` decrements by 1. When it reaches 0, buff is consumed.
- On combat **defeat**: buff is unchanged (not consumed, not decremented).
- CombatBuff persists across sessions (written to save data).

**Rule 7 — Relationship Changes from Dialogue.**
Dialogue emits `relationship_changed(companion_id, delta)` and `trust_changed(companion_id, delta)` with flat integer deltas. Romance & Social receives these and applies them directly — **no streak multiplier, no mood modifier**. These are story-authored values. Both clamp to [0, 100]. Stage re-evaluated after every write.

**Rule 8 — Combat Captain Relationship Gain.**
On combat victory with a companion as captain: +1 RL to that companion. No streak multiplier, no mood modifier, no CombatBuff granted. Flat, passive drip.

**Rule 9 — Stage Advancement.**
After every write to `relationship_level`, re-evaluate `romance_stage` using thresholds [0, 21, 51, 71, 91]. If new stage > current stage, update and emit `romance_stage_changed(companion_id, old_stage, new_stage)`. Stage never decreases. Autosave triggered on stage advance.

**Rule 10 — Marriage (Open Question).**
Marriage as a ceremony/permanent buff/narrative milestone at stage 4 after a specific story beat is not specified. Deferred to producer review before Chapter 2 scope is locked. No system should gate on marriage.

### States and Transitions

#### Companion Mood

Each companion maintains a `mood_state` enum that drives portrait selection and modifies interaction outcomes.

| Mood | Enum | Portrait Used | Effect on Interactions |
|---|---|---|---|
| Content | `MOOD_CONTENT` | `neutral` | No modifier |
| Happy | `MOOD_HAPPY` | `happy` | +1 bonus RL on Talk (+4 instead of +3) |
| Lonely | `MOOD_LONELY` | `sad` | No RL penalty. Dialogue lines express longing. |
| Annoyed | `MOOD_ANNOYED` | `angry` | Liked gift grants +1 RL (not +2). Neutral/disliked grant 0. |
| Excited | `MOOD_EXCITED` | `seductive` | Stage 3+ only. Date awards +2 additional RL per round. |

**Mood Transitions:**

| Trigger | Resulting Mood | Duration |
|---|---|---|
| Talk interaction | Happy | 1 calendar day |
| Liked gift | Happy | 1 calendar day |
| Disliked gift | Annoyed | 1 calendar day |
| Date completion | Happy | 2 calendar days |
| Intimacy completion (stage 3+) | Excited | 1 calendar day |
| No interaction for 1+ days (streak breaks) | Lonely | Until next interaction |
| Any interaction while Lonely | Content (then apply trigger) | Immediate |
| Any interaction while Annoyed | Content (then apply trigger) | Immediate |

**Mood priority** (simultaneous triggers, highest wins): Excited > Happy > Annoyed > Lonely > Content.

**Mood persistence**: Stored as `current_mood` (int enum) + `mood_expiry_date` (UTC date string). On session start: if today > `mood_expiry_date`, mood decays to Content. Lonely has no expiry — only cleared by interaction.

#### Romance Stage Progression

(Defined by Companion Data GDD, reproduced for reference)

| Stage | Name | Min RL | Unlocks |
|---|---|---|---|
| 0 | Stranger | 0 | Basic dialogue, Talk |
| 1 | Acquaintance | 21 | Dates, Gift buffs, Blessing slot 1 |
| 2 | Friend | 51 | Gift preference hints visible, Blessing slot 2 |
| 3 | Close | 71 | Intimacy available, Excited mood, Blessing slots 3-4 |
| 4 | Devoted | 91 | All content unlocked, Blessing slot 5 |

### Interactions with Other Systems

| System | Direction | Data Flow |
|---|---|---|
| **Companion Data** | Reads profile, reads/writes state | Reads: `met`, base stats, portrait paths. Writes: `relationship_level`, `trust`, `dates_completed`, `known_likes`, `known_dislikes`. Also writes new fields: `current_mood`, `mood_expiry_date`, `current_streak`, `last_interaction_date`. |
| **Save System** | Writes to (via GameStore) | All companion mutable state + `active_combat_buff` + `daily_tokens_remaining` + `last_interaction_date` persisted to JSON. Autosave on RL write and stage advance. |
| **Poker Combat** | Provides buff, receives events | Provides: `social_buff_chips`, `social_buff_mult`, `combats_remaining` read at combat start. Receives: `combat_victory(companion_id)` for captain gain and buff decrement. |
| **Dialogue** | Receives signals | Receives: `relationship_changed(companion_id, delta)`, `trust_changed(companion_id, delta)`. Applied without multipliers. |
| **Divine Blessings** | Emits stage signal | Emits: `romance_stage_changed(companion_id, old, new)`. Blessings unlock automatically — R&S does not know which. |
| **Camp** | Provides state, receives commands | Provides: token count, mood, streak, romance_stage to Camp UI. Receives: Talk/Gift/Date commands from Camp. |
| **Intimacy** | Receives event, grants buff | Receives: `intimacy_completed(companion_id)`. Grants Intimacy-tier CombatBuff and +10 RL. |
| **Story Flow** | Provides stage for gating | Story Flow reads `romance_stage` and `relationship_level` for node/branch gating. Story effects route through Dialogue signals. |

## Formulas

### F1 — Relationship Gain (Camp Interactions)

```
relationship_gain = floor(base_RL x streak_multiplier)
```

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base RL | `base_RL` | int | [0, 10] | Interaction-specific base (see Rule 2/4), modified by mood and gift preference |
| Streak multiplier | `streak_multiplier` | float | [1.0, 1.5] | From streak lookup table (Rule 3) |
| Output | `relationship_gain` | int | [0, 15] | Applied to `relationship_level`, clamped to [0, 100] |

**Base RL derivation by interaction type:**
- **Talk**: 3 (or 4 if Mood_Happy)
- **Gift**: 2 (liked) / 1 (neutral/unknown) / 0 (disliked). If Mood_Annoyed: 1 (liked) / 0 (all others)
- **Date**: Sum of 4 rounds (see F2)

**Worked example — Day 5 streak, Talk with Happy companion:**
```
base_RL = 4 (Talk + Happy bonus)
streak_multiplier = 1.40 (day 5-6 bracket)
relationship_gain = floor(4 x 1.40) = floor(5.6) = 5
```

### F2 — Date Score

```
date_RL = sum(round_RL[i] for i in 1..4) + mood_excited_bonus
```

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Round RL | `round_RL` | int | {3, 5, 8} | Per round: liked=8, neutral=5, disliked=3 |
| Mood excited bonus | `mood_excited_bonus` | int | 0 or 8 | +2 per round if Mood_Excited (4 rounds x 2 = 8) |
| Date RL output | `date_RL` | int | [12, 40] | Before streak multiplier |

Streak applies to the total: `final_date_RL = floor(date_RL x streak_multiplier)`.

**Worked example — 3 liked + 1 neutral, Mood_Excited, day 7 streak:**
```
date_RL = (8 + 8 + 8 + 5) + 8 = 37
final_date_RL = floor(37 x 1.50) = floor(55.5) = 55
```
This is a best-case scenario (+55 RL in one interaction) requiring stage 3+ mood, 7-day streak, and 3/4 liked picks.

### F3 — Social Combat Buff Lookup

No formula — values are table-driven per Rule 6. The buff is looked up by `(romance_stage, trigger_type)` from the CombatBuff table. This is intentional: a formula would obscure the per-trigger distinction that rewards diverse engagement.

**Buff replacement comparison:**
```
replace = (new_chips + new_mult) > (old_chips + old_mult)
```

### F4 — Captain Relationship Gain

```
captain_RL = CAPTAIN_GAIN_BASE    (if combat_result == "victory")
captain_RL = 0                    (if defeat or no captain)
```

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Captain gain base | `CAPTAIN_GAIN_BASE` | int | 1 | Balance config constant |
| Combat result | `combat_result` | enum | {victory, defeat} | From Poker Combat |

No streak multiplier. No mood modifier. Flat +1.

**Worked example:** 50 combat victories with Artemisa as captain = +50 RL total across the playthrough. Roughly equivalent to 17 Talk interactions — meaningful background drip, not dominant.

### Non-Formulas (Explicit)

- **Dialogue deltas** are flat integers from story data, applied verbatim. No weighting formula.
- **Mood transitions** are trigger-based enum swaps, not calculated values.
- **Stage thresholds** [0, 21, 51, 71, 91] are defined in Companion Data GDD — not recalculated here.
- **Token reset** is a calendar check, not a formula.

## Edge Cases

### Boundary Values

- **If `relationship_level` is at a stage threshold (e.g., 20) and gains +1**: RL becomes 21, crossing Stage 0->1. Stage re-evaluation runs immediately. `romance_stage_changed` emitted, autosave triggered, Date/Gift-buff eligibility unlocks in the same session.
- **If `relationship_level` is 100 and any further RL gain occurs**: Gain is discarded (clamp to 100). Camp UI should display a "Devoted" indicator and deprioritize RL-generating interactions visually — tokens still usable for mood/buff purposes, but the player should know RL is maxed.
- **If a dialogue delta lowers RL below a stage threshold (e.g., RL drops from 25 to 18)**: `romance_stage` stays at its highest achieved value (stage 1). Stage never decreases per Rule 9. Writers should be informed: negative RL deltas cannot de-rank a companion.
- **If `relationship_level` is 3 and dialogue emits delta = -5**: RL floors to 0, not -2. Clamp to [0, 100]. Stage remains 0.
- **If save data has RL=100 but romance_stage=3 (data desync)**: Run stage re-evaluation on save load (not only on write). If RL >= 91, normalize stage to 4. This catches manual edits, corruption, or migration bugs.

### Simultaneous Triggers

- **If 3 tokens are spent on the same companion in one session**: All three resolve sequentially using the same streak multiplier (set at session start). RL gains stack normally. No per-companion daily cap.
- **If a liked gift and a date complete in the same session**: Each independently triggers buff replacement. Interactions process sequentially in the order they occur. The higher-scoring buff wins per replacement rule.
- **If mood priority collides (e.g., Intimacy triggers Excited, gift triggers Happy)**: Highest-priority mood wins (Excited > Happy > Annoyed > Lonely > Content). Only the winning mood and its expiry are stored; losing triggers are discarded entirely.
- **If `romance_stage_changed` fires during an active dialogue sequence**: Signal is queued for post-dialogue resolution. Blessing unlocks and UI updates apply after `dialogue_ended`, not mid-sequence.

### Negative Dialogue Deltas

- **If trust drops to 0 via dialogue delta**: Trust has no mechanical gate in this GDD (unlike romance_stage). It is stored for future use by downstream systems. Trust at 0 has no functional consequence in Romance & Social. Writers should not assume trust gates exist unless a future GDD defines them.
- **If a story rejection emits negative RL but companion is in Mood_Annoyed**: Mood is NOT modified by dialogue deltas. Only the specific triggers in the mood transition table cause mood changes. A -10 RL from dialogue does not trigger Annoyed — that mood is only caused by disliked gifts.

### Token and Streak Edge Cases

- **If session spans UTC midnight without app restart**: Implement an app-resume or periodic midnight check to reset tokens. Session-start-only reset is exploitable (6-token day). On midnight tick: reset `daily_tokens_remaining` to 3, evaluate streak (yesterday vs. today), and update `last_interaction_date`.
- **If `last_interaction_date` is null (first-ever session)**: Treat as "no streak exists." First interaction sets `streak_days = 1` (multiplier 1.00x) and stores today as `last_interaction_date`.
- **If the device clock is set backward**: Calculate `gap = max(0, today - last_interaction_date)`. Negative gaps are treated as 0 (same-day, no streak increment, no reset). Prevents clock manipulation from granting or resetting streaks.

### Combat Buff State

- **If CombatBuff was granted by Companion A but captain switches to Companion B**: Buff is global (player-level), not companion-specific. It carries over regardless of captain. A Nyx date buff works with Artemisa as captain. This is intentional — the buff represents the companion's faith in the player, not active participation.
- **If `combats_remaining` reaches 0 after combat victory**: Clear the buff slot to null immediately at combat resolution. The next interaction writes into an empty slot without comparison.
- **If a new buff is generated while no active buff exists**: Write directly to the empty slot. No replacement comparison needed.

### Date Edge Cases

- **If activity categories repeat across rounds**: Categories are drawn with replacement — the same category can appear in multiple rounds of the same date. Individual activity text varies but category eligibility never exhausts.
- **If romance_stage advances mid-date due to RL gains from earlier rounds**: `romance_stage` is snapshotted at date entry. All 4 rounds and the CombatBuff table lookup use the snapshot, not the live value. Stage advance signals still fire during the date but do not affect date calculations.

### New Companion Unlocked

- **If `met` changes from false to true mid-session and player navigates to Camp**: Camp UI must reactively update. Subscribe to a `companion_met(companion_id)` signal rather than caching met status at session start.
- **If a companion is newly met but all 3 tokens are spent**: The companion appears in Camp with a "Come back tomorrow" indicator. She is visible but interactions are locked until tomorrow's token reset.

## Dependencies

| System | Direction | Nature | Interface |
|---|---|---|---|
| **Companion Data** | R&S depends on this | **Hard** | Reads: `met`, base stats, portrait paths, `romance_stage` thresholds. Writes: `relationship_level`, `trust`, `dates_completed`, `known_likes`, `known_dislikes`, `current_mood`, `mood_expiry_date`, `current_streak`, `last_interaction_date`. R&S is the sole writer of relationship state. |
| **Save System** | R&S depends on this | **Hard** | Persists all companion mutable state + `active_combat_buff` + `daily_tokens_remaining` via GameStore. Autosave on RL write and stage advance. CombatBuff persists across sessions. |
| **Dialogue** | R&S depends on this | **Hard** | Receives `relationship_changed(companion_id, delta)` and `trust_changed(companion_id, delta)` signals. Applied without multipliers. Dialogue is the primary source of story-driven relationship changes. |
| **Localization** | R&S depends on this | **Soft** | Interaction text, stage labels, mood labels, date activity names resolve via `get_text()`. Works without (shows raw keys). |
| **Poker Combat** | Poker Combat depends on this | **Soft** | R&S provides `social_buff_chips`, `social_buff_mult`, `combats_remaining` read at combat start. Poker Combat emits `combat_victory(companion_id)` for captain gain and buff decrement. Combat functions without buffs (all values default to 0). |
| **Divine Blessings** | Blessings depends on this | **Hard** | R&S emits `romance_stage_changed(companion_id, old, new)`. Blessings unlock based on stage. Without R&S, no blessings unlock. |
| **Camp** | Camp depends on this | **Hard** | Camp UI reads token count, mood, streak, romance_stage from R&S. Sends Talk/Gift/Date commands. Without R&S, Camp has no interactive content. |
| **Intimacy** | Intimacy depends on this | **Hard** | Reads `romance_stage >= 3` gate. On `intimacy_completed`, R&S grants Intimacy-tier CombatBuff and +10 RL. |
| **Story Flow** | Story Flow reads from this | **Soft** | Reads `romance_stage` and `relationship_level` for node/branch gating. Story effects route through Dialogue signals, not directly through R&S. |
| **Achievements** | Achievements depends on this | **Soft** | Reads `romance_stage`, `dates_completed`, streak data for milestone tracking. Not yet designed. |

**Hard dependencies (upstream, 3):** Companion Data, Save System, Dialogue — R&S cannot function without these.
**Soft dependencies (upstream, 1):** Localization — text display degrades to raw keys without it.
**Hard dependencies (downstream, 3):** Divine Blessings, Camp, Intimacy — these cannot function without R&S.
**Soft dependencies (downstream, 3):** Poker Combat, Story Flow, Achievements — these function without R&S but are enhanced by it.

**Bidirectional consistency notes:**
- Companion Data GDD lists R&S as the primary state mutator
- Poker Combat GDD lists R&S as soft dependency feeding social buffs
- Dialogue GDD lists R&S as the receiver of relationship/trust signals
- Divine Blessings, Camp, Intimacy, Story Flow, Achievements GDDs must list their relationship to R&S when authored

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|---|---|---|---|---|
| `DAILY_TOKENS` | 3 | [2, 5] | More interactions per day; faster RL progression; less daily tension in who to visit | Fewer interactions; slower progression; sharper daily choices |
| `TALK_BASE_RL` | 3 | [1, 5] | Talk becomes more competitive with Gift; less reason to risk unknown gifts | Talk becomes negligible; gifting dominates |
| `GIFT_LIKED_RL` | 2 | [1, 5] | Stronger reward for known preferences; widens gap between informed and uninformed gifting | Gift preference discovery matters less |
| `DATE_ROUND_LIKED_RL` | 8 | [5, 12] | Dates become dominant RL source; players rush to stage 1 | Dates feel underwhelming relative to talk/gift effort |
| `DATE_ROUND_DISLIKED_RL` | 3 | [1, 5] | Dates are always worthwhile even with bad picks; reduces preference learning incentive | Bad dates feel punishing; player avoids dating without full knowledge |
| `STREAK_CAP_MULTIPLIER` | 1.50x | [1.25, 2.0] | Stronger daily retention hook; faster RL for dedicated players | Streak feels less rewarding; less motivation for daily play |
| `STREAK_CAP_DAY` | 7 | [5, 14] | Longer ramp to max; rewards multi-week consistency | Quick cap; easy to maintain but less aspirational |
| `CAPTAIN_GAIN_BASE` | 1 | [0, 3] | Combat becomes a meaningful RL source; incentivizes captain diversity | Captain choice has no romance impact |
| `MOOD_HAPPY_BONUS` | +1 RL on Talk | [0, +3] | Happy mood is worth seeking; mood management becomes strategic | Happy mood is negligible; mood is cosmetic |
| `MOOD_EXCITED_DATE_BONUS` | +2 per round | [0, +4] | Excited mood is a significant date amplifier; intimacy->date pipeline strengthened | Excited mood is cosmetic |
| `COMBAT_BUFF_REPLACEMENT_RULE` | Replace if higher sum | -- | Could change to: always replace, or never replace | -- |
| `INTIMACY_RL_BONUS` | +10 | [5, 20] | Intimacy is a meaningful RL spike; rewards reaching stage 3 | Intimacy feels less impactful relative to daily interactions |

**Cross-knob interactions:**
- `DAILY_TOKENS` and `TALK_BASE_RL` are tightly coupled: 3 tokens x 3 RL = 9 RL/day from talk alone. Increasing both creates runaway RL progression.
- `STREAK_CAP_MULTIPLIER` amplifies all camp gains — increasing it while `DATE_ROUND_LIKED_RL` is high creates very fast progression for engaged players (55 RL in one date interaction at best case).
- `CAPTAIN_GAIN_BASE` interacts with combat frequency: a player doing 5 combats/session gains +5 RL passive, competing with a Talk interaction.

## Visual/Audio Requirements

### Visual Feedback

| Event | Visual Feedback | Duration | Priority |
|---|---|---|---|
| Talk interaction | Portrait cross-fades to mood variant (200ms). Dialogue box slides up (150ms). Gold (#D4A843) speech bubble border pulses once. | 350ms | MVP |
| Gift -- liked | Portrait swaps to Happy. Gold particle burst (12 particles, starburst from portrait center). Gift icon scales 1.0->1.3->0 (pop dissolve). | 600ms | MVP |
| Gift -- neutral | Portrait holds mood. Brief cream (#F5E6C8) shimmer on gift icon, then dissolve. | 300ms | MVP |
| Gift -- disliked | Portrait swaps to Annoyed. Red (#F24D26) crack overlay flashes on icon (2 frames). Screen edge vignette in #F24D26 at 20% opacity. | 400ms | MVP |
| Mood transition | Portrait cross-fades to new mood (300ms). Thin bar beneath portrait fills with mood color (Content=#73BF40, Happy=#D4A843, Lonely=#338CF2, Annoyed=#F24D26, Excited=#CCaa33) over 400ms. | 700ms | MVP |
| Streak increment | Counter badge scales 1.0->1.2->1.0 (250ms spring). Gold fill left-to-right. New number fades in. | 400ms | MVP |
| Streak reset | Badge flashes grey (#555) twice (100ms on/off). Number counts down to 1. | 500ms | MVP |
| CombatBuff granted | Full-width banner slides from top (200ms). Gold border, brown background. Companion element color pulses as left accent bar. Crossed swords icon. | Hold 2s, slide out 200ms | MVP |
| Romance stage advance | Black overlay (300ms). Cinzel gold text center-screen names new stage. Painterly ink wash left-to-right behind text (element color). Full-height portrait. | ~4s total | MVP |
| Gift preference discovered | Small scroll icon pops beside portrait (0->1, 200ms). Cream tooltip: "[Name] loves/hates [category]". Auto-dismiss 2.5s. | 2.7s | Vertical Slice |
| Token spent | Token pip drains grey left-to-right (200ms). Remaining pips stay gold. | 200ms | MVP |
| RL gain | No number shown. Subtle cream fill-line creeps right along thin bar beneath stage name. | 800ms ease-out | MVP |
| Date round -- liked | Activity card glows gold, card-flip (300ms). Happy portrait. | 500ms | Vertical Slice |
| Date round -- neutral | Card fades cream. Neutral portrait. | 300ms | Vertical Slice |
| Date round -- disliked | Card dims grey, shakes 4px horizontal (2 cycles). Annoyed portrait. | 350ms | Vertical Slice |

### Audio Feedback

| Event | Audio |
|---|---|
| Talk interaction | Soft chime (element pitch-tuned). Companion 1-2s breathy non-verbal cue. |
| Gift -- liked | Rising 3-note arpeggio (major). Short companion delight cue. |
| Gift -- neutral | Single mid-tone chime, no tail. |
| Gift -- disliked | Descending 2-note minor drop. Short companion dismissal cue. |
| Mood transition | Ambient layer cross-fades (300ms): Content=warm strings, Happy=light pizzicato, Lonely=low cello drone, Annoyed=dissonant pad, Excited=arpeggiated harp. |
| Streak increment | Coin tick + rising pitch per tier (5 tiers = 5 pitches). |
| Streak reset | Soft descending whoosh. Regretful, not punishing. |
| CombatBuff granted | Low brass swell (0.5s), then silence. Divine weight. |
| Romance stage advance | Per-stage musical sting (4-bar phrase, full orchestration). Revelation, not trophy. |
| Gift pref discovered | "Page turn" rustle + single soft note. |
| Token spent | Soft wooden click (token placed on table). |
| RL gain | No audio. Silence reinforces invisible, gradual growth. |
| Date round -- liked | Warm resonant bell. Companion approving non-verbal. |
| Date round -- disliked | Muted string pluck. Companion understated sigh. |

### Art Principles

1. **Mood-portrait consistency**: All 6 variants share identical silhouette and lighting anchor. Only expression, eye brightness, and mouth shape change.
2. **Color means something**: Element colors appear in social UI only on CombatBuff and stage-advance ink wash -- signaling "this connects to combat power." No decorative element color use elsewhere.
3. **Restraint on RL gain**: No floating numbers, no XP bar fanfare. The thin progress line is deliberately subtle. Growth is felt through unlocked content and changed dialogue, not a score counter.
4. **Portrait transitions**: Cross-fade only -- no slide or scale. Companion occupies a fixed spatial anchor.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| Daily tokens remaining | Camp HUD, top-right -- 3 gold pip icons | On token spend | Always visible at Camp |
| Current streak count + multiplier | Camp HUD, below tokens -- badge with day count | On session start, on interaction | Always visible at Camp |
| Companion mood indicator | Thin colored bar beneath companion portrait | On mood transition | When viewing a companion |
| Romance stage name | Below companion name -- text label (e.g., "Friend") | On stage advance | When viewing a companion |
| RL progress bar | Thin subtle line beneath stage name | On RL gain | When viewing a companion |
| Known likes/dislikes | Companion detail panel -- small icons with tooltips | On preference discovered | romance_stage >= 2 for hint icons on gift items |
| CombatBuff active indicator | Camp HUD + Pre-combat screen -- banner with chips/mult values | On buff grant/consume | When buff is active |
| Gift selection UI | Modal overlay with inventory grid, 44x44px touch targets | On Gift interaction | When gifting |
| Date activity selector | 3 activity cards per round, 44x44px minimum | On each date round | During date scene |

**Layout zones** (portrait-mode 430x932):
- **Top bar** (0-60px): Tokens, streak badge
- **Portrait zone** (60-500px): Companion portrait, mood bar, stage label, RL bar
- **Interaction zone** (500-800px): Talk/Gift/Date buttons (minimum 44x44px touch targets)
- **Info zone** (800-932px): Known preferences, CombatBuff status

**Accessibility**: All interactive elements must meet minimum 44x44px touch targets. Mood colors must be distinguishable at common color vision deficiency levels -- each mood bar has a distinct icon overlay (heart for Happy, teardrop for Lonely, flame for Annoyed, star for Excited, circle for Content) in addition to color.

> **UX Flag -- Romance & Social**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the Camp interaction screen, Date sub-scene, and Gift modal **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Acceptance Criteria

### Rule 1 — Daily Token Pool

- [ ] **AC-RS-01** — **GIVEN** a new session on a new UTC date, **WHEN** session loads, **THEN** `daily_tokens_remaining` is set to 3.
- [ ] **AC-RS-02** — **GIVEN** all 3 tokens spent, **WHEN** a 4th interaction is attempted, **THEN** rejected, no RL awarded, no token deducted, UI shows 0 tokens.
- [ ] **AC-RS-03** — **GIVEN** 2 tokens remaining, **WHEN** 1 spent on Companion A and 1 on B, **THEN** `daily_tokens_remaining` = 0, both companions received their interaction.
- [ ] **AC-RS-04** — **GIVEN** app running over UTC midnight, **WHEN** midnight tick detected, **THEN** tokens reset to 3, streak evaluated, `last_interaction_date` updated.

### Rule 2 — Camp Interactions

- [ ] **AC-RS-05** — **GIVEN** companion `met=true`, mood Content, **WHEN** Talk, **THEN** RL +3, token -1.
- [ ] **AC-RS-06** — **GIVEN** companion Mood_Happy, **WHEN** Talk, **THEN** RL +4 (Happy bonus applied before streak).
- [ ] **AC-RS-07** — **GIVEN** liked gift, mood Content, **WHEN** gifted, **THEN** RL +2, mood -> Happy (1 day).
- [ ] **AC-RS-08** — **GIVEN** disliked gift, mood Content, **WHEN** gifted, **THEN** RL +0, mood -> Annoyed (1 day).
- [ ] **AC-RS-09** — **GIVEN** Mood_Annoyed, liked gift, **WHEN** gifted, **THEN** RL +1 (not +2), mood -> Happy.
- [ ] **AC-RS-10** — **GIVEN** Mood_Annoyed, neutral/disliked gift, **WHEN** gifted, **THEN** RL +0.
- [ ] **AC-RS-11** — **GIVEN** `romance_stage=0`, **WHEN** Date attempted, **THEN** rejected, no token spent.

### Rule 3 — Streak Multiplier

- [ ] **AC-RS-12** — **GIVEN** `last_interaction_date` exactly 1 day prior, **WHEN** first token spent, **THEN** `current_streak` increments, correct multiplier applied.
- [ ] **AC-RS-13** — **GIVEN** `last_interaction_date` 2+ days prior, **WHEN** first token spent, **THEN** `current_streak` resets to 1, multiplier 1.00x.
- [ ] **AC-RS-14** [F1] — **GIVEN** Talk (base 3), day-5 streak (1.40x), **WHEN** gain calculated, **THEN** `floor(3 x 1.40) = 4` added to RL.
- [ ] **AC-RS-15** — **GIVEN** dialogue delta -5 during day-7 streak, **WHEN** applied, **THEN** -5 flat (no streak multiplier), streak unchanged.

### Rule 4 — Date Sub-System (F2)

- [ ] **AC-RS-16** [F2] — **GIVEN** stage >= 1, 4 liked rounds, no Excited, **WHEN** date completes, **THEN** date_RL=32, streak applied, `dates_completed` +1, buff granted.
- [ ] **AC-RS-17** [F2] — **GIVEN** stage >= 3, Mood_Excited, 3 liked + 1 neutral, **WHEN** date completes, **THEN** date_RL = 29 + 8 = 37 before streak.
- [ ] **AC-RS-18** — **GIVEN** stage advances mid-date, **WHEN** buff assigned at date end, **THEN** buff uses stage snapshotted at date entry, not post-advance value.

### Rule 5 — Gift Preference Discovery

- [ ] **AC-RS-19** — **GIVEN** "romantic" not in `known_likes`, **WHEN** liked "romantic" activity selected during date, **THEN** added to `known_likes`; no duplicate on repeat.
- [ ] **AC-RS-20** — **GIVEN** unknown gift preference, **WHEN** gift resolved, **THEN** no entry added to `known_likes`/`known_dislikes`.

### Rule 6 — Social Combat Buffs (F3)

- [ ] **AC-RS-21** [F3] — **GIVEN** stage 2, no active buff, liked gift, **WHEN** resolved, **THEN** buff = chips:10, mult:0.5, combats:2.
- [ ] **AC-RS-22** — **GIVEN** active buff sum=10.5, new buff sum=16.0, **WHEN** new buff generated, **THEN** new replaces old.
- [ ] **AC-RS-23** — **GIVEN** active buff sum=21.5, new buff sum=16.0, **WHEN** new buff generated, **THEN** existing retained.
- [ ] **AC-RS-24** — **GIVEN** buff `combats_remaining=1`, **WHEN** combat victory, **THEN** decrements to 0, slot cleared to null immediately.
- [ ] **AC-RS-25** — **GIVEN** buff `combats_remaining=3`, **WHEN** combat defeat, **THEN** `combats_remaining` unchanged at 3.
- [ ] **AC-RS-26** — **GIVEN** stage 0 (Stranger), **WHEN** any interaction completes, **THEN** no buff granted.

### Rule 7 — Dialogue Deltas

- [ ] **AC-RS-27** — **GIVEN** RL=15, dialogue emits delta=-20, **WHEN** applied, **THEN** RL clamps to 0, stage remains at highest achieved.

### Rule 8 — Captain Gain (F4)

- [ ] **AC-RS-28** [F4] — **GIVEN** companion is captain, **WHEN** combat victory, **THEN** RL +1, no streak, no mood modifier, no buff.
- [ ] **AC-RS-29** — **GIVEN** companion is captain, **WHEN** combat defeat, **THEN** RL unchanged.

### Rule 9 — Stage Advancement

- [ ] **AC-RS-30** — **GIVEN** RL=20, +1 gain applied, **WHEN** RL becomes 21, **THEN** stage advances 0->1, signal emitted, autosave triggered.
- [ ] **AC-RS-31** — **GIVEN** RL=25 (stage 1), dialogue delta -10, **WHEN** RL becomes 15, **THEN** stage remains 1.
- [ ] **AC-RS-32** — **GIVEN** RL=99, +5 gain, **WHEN** applied, **THEN** RL clamps to 100, stage re-evaluated (stage 4 if >= 91).

### Mood State Machine

- [ ] **AC-RS-33** — **GIVEN** Mood_Excited, liked gift in same session, **WHEN** mood priority evaluated, **THEN** Excited retained (Excited > Happy).
- [ ] **AC-RS-34** — **GIVEN** Mood_Lonely, **WHEN** Talk, **THEN** Lonely -> Content -> Happy (Talk trigger). Final mood: Happy.
- [ ] **AC-RS-35** — **GIVEN** `mood_expiry_date` is yesterday, **WHEN** session starts, **THEN** mood decays to Content. Lonely exempt (no expiry, cleared only by interaction).

### Cross-System

- [ ] **AC-RS-36** — **GIVEN** active buff `combats_remaining=2` at session end, **WHEN** app reopened, **THEN** buff restored from save with `combats_remaining=2` intact.
- [ ] **AC-RS-37** — **GIVEN** `romance_stage_changed` fires during date, **WHEN** date still active, **THEN** signal queued; blessing unlocks apply after date scene closes.

### Performance and Data-Driven

- [ ] **AC-RS-38** — All camp interaction processing (Talk/Gift/Date round) completes within 16ms (one frame at 60fps).
- [ ] No relationship values, streak thresholds, buff values, or mood durations are hardcoded outside balance config files.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---|---|---|---|
| Romance stage thresholds [0,21,51,71,91] | `design/gdd/companion-data.md` | Romance Stage Derivation formula | Rule dependency |
| Companion state fields (relationship_level, trust, etc.) | `design/gdd/companion-data.md` | Companion State Record table | Data dependency |
| Portrait mood variants (6 per companion) | `design/gdd/companion-data.md` | Portrait System | Data dependency |
| `met` flag gates camp interactions | `design/gdd/companion-data.md` | Companion state `met` field | State trigger |
| `social_buff_chips`, `social_buff_mult` injected into scoring | `design/gdd/poker-combat.md` | `combat_score_pipeline` formula (F2) | Data dependency |
| Buff consumed on victory, retained on defeat | `design/gdd/poker-combat.md` | Rule 10 (Victory and Defeat) | Rule dependency |
| `combat_victory(companion_id)` event for captain gain | `design/gdd/poker-combat.md` | Combat outcome signals | State trigger |
| `relationship_changed(companion_id, delta)` signal received | `design/gdd/dialogue.md` | Rule 5 (Effects) | Ownership handoff |
| `trust_changed(companion_id, delta)` signal received | `design/gdd/dialogue.md` | Rule 5 (Effects) | Ownership handoff |
| `romance_stage` gates dialogue branches | `design/gdd/dialogue.md` | Rule 7 (Gating) | Data dependency |
| Save persistence via GameStore `to_dict()`/`from_dict()` | `design/gdd/save-system.md` | Serialization contract (Rule 3) | Rule dependency |
| Autosave triggers on RL write and stage advance | `design/gdd/save-system.md` | Autosave debounce (Rule 6) | State trigger |
| `romance_stage_changed` signal consumed by Blessings | (Divine Blessings GDD -- not yet authored) | Blessing unlock trigger | Ownership handoff |
| Camp UI reads token/mood/streak/stage state | (Camp GDD -- not yet authored) | Camp interaction commands | Data dependency |
| `intimacy_completed` event grants buff + RL | (Intimacy GDD -- not yet authored) | Intimacy completion signal | State trigger |

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should marriage exist as a formal mechanic at stage 4? Ceremony, permanent buff, CG, narrative milestone? | game-designer | Before Chapter 2 scope lock | Deferred per Rule 10. No system should gate on marriage until resolved. |
| What is the mechanical use of `trust`? Currently stored but no system behavior is gated on it. | game-designer | Before Divine Blessings GDD | Trust may gate blessing tier quality, dialogue insight options, or intimacy scene variants. Define before downstream systems are authored. |
| Should RL gains be blocked when RL=100 (RL saturation)? Currently tokens can still be spent for mood/buff purposes but RL gain is wasted. | ux-designer | Before Camp UI implementation | Camp UI needs a visual indicator. Tokens are still valuable for buffs, so blocking isn't recommended -- but player communication is needed. |
| Should the streak system include a "grace token" (1 free miss per week without resetting)? | game-designer | Before playtest | Current binary reset may feel punishing. Defer to playtest data. |
| Should trust be able to go negative, or should it clamp at 0? | game-designer | Before Dialogue content authoring | Writers need to know if harsh trust penalties are possible or if 0 is a hard floor. |
