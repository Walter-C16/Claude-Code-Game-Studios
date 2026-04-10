# Story Flow

> **Status**: In Design
> **Author**: game-designer + narrative-director
> **Last Updated**: 2026-04-09
> **Implements Pillar**: Pillar 2 — Visual Novel Dialogue with Consequences

## Summary

Story Flow is the chapter-node sequencer that orchestrates Dark Olympus's narrative progression — threading dialogue scenes, combat encounters, companion unlocks, and rewards into a coherent mythological journey. It owns chapter state (node progression, story flags, completion tracking), drives the Chapter Map UI, and coordinates Dialogue and Poker Combat as subordinate systems. It is the system that makes Pillar 2's promise real: dialogue choices have consequences because Story Flow tracks them as flags that gate future content.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Dialogue, Poker Combat, Companion Data`

## Overview

Story Flow sequences the player through chapter-based story content, one node at a time. Each chapter is a JSON file defining an ordered chain of nodes — dialogue scenes, combat encounters, boss fights, companion introductions, and reward beats. The player navigates via the Chapter Map, selecting the next available node. Nodes unlock linearly: each requires the previous node to be completed and may require specific story flags. Within a node, Story Flow delegates to the Dialogue system for narrative delivery and to Poker Combat for encounters, listening for completion signals before granting rewards, setting flags, and advancing to the next node. Story flags — write-once strings set on node completion — are the atomic units of consequence that drive both node gating and dialogue branching. Combat defeat triggers a retry prompt with no penalty. Chapter 1 contains 10 nodes spanning the prologue tutorial combat through the Gaia revelation, introducing Artemisa and Hipolita along the way.

## Player Fantasy

**"The Living Myth"**

You are inside a myth that is still being told — not a history, but an ongoing act of creation. Each story node is an episode in an epic poem where the hero shapes the telling. Dialogue choices are not menu selections; they are declarations that reshape the mythological world. Meeting Artemisa in the forest does not feel like a tutorial unlock — it feels like fate intervening. Defeating the Gaia Spirit at the night siege does not feel like clearing a level — it feels like a chapter of legend being sealed.

The emotional arc of each node follows the rhythm of myth: wonder (entering the scene) into gravity (the stakes of this episode) into declaration (the player's choice that defines this chapter) into resonance (feeling the mythological weight of what just happened). The cumulative effect across a chapter is the sensation of a myth being written around you — and your choices are the ink.

This framing demands consistently elevated writing and presentation. Every node transition must feel like turning the page of an epic, not clicking "Next" on a menu. The system succeeds when a player describes their experience not as "I played through Chapter 1" but as "I was there when the gods fell."

## Detailed Design

### Core Rules

**Rule 1 — Chapter Data Structure.**
Each chapter is a JSON file at `res://assets/data/story/ch{NN}.json`. A chapter contains an ordered array of nodes. Node schema:

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | String | Yes | `ch{NN}_n{NN}`, globally unique |
| `type` | Enum | Yes | `dialogue`, `combat`, `mixed`, `boss`, `reward`, `companion_unlock` |
| `title_key` | String | Yes | Localization key for Chapter Map display |
| `sequence_id` | String | No | Dialogue sequence to play. Required for `dialogue`, `mixed`, `boss` (pre-combat), `companion_unlock` |
| `enemy_id` | String | No | Required for `combat`, `mixed`, `boss` |
| `defeat_mode` | Enum | No | `retry` (default) or `continue`. Required for combat/boss nodes |
| `post_combat_sequence_id` | String | No | Dialogue after combat victory. Used in `mixed` and `boss` |
| `requires_flags` | Array[String] | Yes | Node locked until all flags set |
| `sets_flags` | Array[String] | Yes | Flags set atomically on node completion |
| `unlocks_companions` | Array[String] | No | Companion IDs to set `met = true` on completion |
| `reward` | Object | Yes | `{ "gold": int, "xp": int }` |
| `next` | String | Yes | Next node ID, or `ch{NN}_end` |

**Rule 2 — Node Types.**

| Type | Execution Order |
|---|---|
| `dialogue` | Dialogue sequence -> flags + rewards -> advance |
| `combat` | Pre-dialogue (optional) -> combat -> flags + rewards -> advance |
| `mixed` | Dialogue -> combat -> post-combat dialogue -> flags + rewards -> advance |
| `boss` | Pre-combat dialogue -> combat -> post-combat dialogue -> flags + rewards -> advance (signals boss music + boss HP bar) |
| `reward` | Immediate reward grant -> flags -> advance |
| `companion_unlock` | Dialogue -> set `met = true` -> companion reveal animation -> flags + rewards -> advance |

**Rule 3 — Node Sequencing.**
Linear with flag-gated unlocks. A node becomes available when:
1. Its `state == not_started`
2. All `requires_flags` present in `GameStore.story_flags`
3. Previous node's `state == completed`

No chapter-level branching. Branching exists only within dialogue scripts (Dialogue system). Chapter 1 is a single chain of 9 nodes.

**Rule 4 — Story Flags.**
Flags are write-once strings in `GameStore.story_flags: Array[String]`.
1. Once set, never unset.
2. Set atomically when node reaches `completed`.
3. Pattern: `[a-z_]+`. No spaces, no special characters.
4. **Node-declared only**: Dialogue `set_flag` effects may only set flags declared in the active node's `sets_flags`. Undeclared flags log a warning and are dropped.

Chapter 1 flags (in order): `forest_monster_defeated`, `prologue_complete`, `artemis_house_complete`, `tavern_complete`, `mountains_complete`, `village_met_hipolita`, `hipolita_challenge_complete`, `village_report_complete`, `night_siege_complete`, `ch01_complete`, `gaia_revealed`

**Rule 5 — Reward Distribution.**
Rewards granted atomically when node transitions to `completed` -- after all execution steps including post-combat dialogue. Never mid-execution.

| Node Type | Gold Range | XP Range |
|---|---|---|
| `dialogue` | 0-30 | 50-80 |
| `companion_unlock` | 0-20 | 50-60 |
| `combat` | 40-60 | 80-120 |
| `mixed` | 40-60 | 80-120 |
| `boss` | 80-120 | 150-250 |
| `reward` | 50-200 | 0 |

Chapter 1 totals: Gold = 270, XP = 790.

**Rule 6 — Combat Defeat Handling.**
- **`retry`** (default): On `combat_completed({victory: false})`, return to Chapter Map. Retry prompt. Re-enter combat on confirm. No penalty, unlimited retries. Node stays `in_progress`.
- **`continue`** (reserved): Story continues on defeat with defeat-variant flag. Not used in Chapter 1.

**Rule 7 — Chapter Completion.**
When the final node reaches `completed`: set `completion_flag`, write `current_chapter` to GameStore, emit `chapter_completed(chapter_id)`. Chapter Map routes to chapter-end summary, then Hub.

**Rule 8 — Chapter 1 Node Map.**

| # | Node ID | Type | Enemy | Unlocks | Gold/XP | Flag |
|---|---|---|---|---|---|---|
| 0 | `ch01_n00` | `combat` | `forest_monster` | -- | 10/30 | `forest_monster_defeated` |
| 1 | `ch01_n01` | `companion_unlock` | -- | `artemisa` | 0/50 | `prologue_complete` |
| 2 | `ch01_n02` | `dialogue` | -- | -- | 20/60 | `artemis_house_complete` |
| 3 | `ch01_n03` | `dialogue` | -- | -- | 30/60 | `tavern_complete` |
| 4 | `ch01_n04` | `mixed` | `cyclops` | -- | 40/80 | `mountains_complete` |
| 5 | `ch01_n05` | `companion_unlock` | -- | `hipolita` | 20/60 | `village_met_hipolita` |
| 6 | `ch01_n06` | `combat` | `hipolita_duel` | -- | 50/100 | `hipolita_challenge_complete` |
| 7 | `ch01_n07` | `dialogue` | -- | -- | 0/50 | `village_report_complete` |
| 8 | `ch01_n08` | `boss` | `gaia_spirit` | -- | 100/200 | `night_siege_complete` |
| 9 | `ch01_n09` | `dialogue` | -- | -- | 0/100 | `ch01_complete`, `gaia_revealed` |

### States and Transitions

**Node State Machine:**

| State | Description | Persisted |
|---|---|---|
| `not_started` | Node not entered. Requires flags/previous node. | Yes |
| `in_progress` | Currently executing or awaiting retry. | Yes (supports resume) |
| `completed` | All steps finished. Rewards granted. Flags set. Cannot re-enter. | Yes |

| Transition | Trigger | Action |
|---|---|---|
| `not_started -> in_progress` | Player taps node on Chapter Map | Load node, begin execution |
| `in_progress -> completed` | Final step ends (victory or continue) | Grant rewards, set flags, set `met`, autosave |
| `in_progress -> in_progress` (retry) | Combat defeat with `retry` mode | Show retry prompt, re-enter combat |

**Chapter states:** `locked` (previous chapter incomplete), `active` (in progress), `completed` (all nodes done).

### Interactions with Other Systems

| System | Direction | Contract |
|---|---|---|
| **Dialogue** | Story Flow -> Dialogue | `start_dialogue(chapter_id, sequence_id)`. Awaits `dialogue_ended` / `dialogue_blocked`. Blocked dialogue in a story node is always a data error. |
| **Poker Combat** | Story Flow -> SceneManager | `change_scene(COMBAT, {enemy_id, source, mode:"story", node_id})`. Awaits `combat_completed({victory, score, hands_used})`. |
| **Scene Navigation** | Story Flow -> SceneManager | FADE transitions. Chapter Map = `SceneId.CHAPTER_MAP`. Context payloads for routing. |
| **Companion Data** | Story Flow -> Companion Data | Sets `companion.met = true` for `unlocks_companions` IDs on node completion. |
| **Save System** | Story Flow -> GameStore | Writes `current_node_id`, `node_states`, `story_flags`, `player_gold`, `player_xp`. Autosave on node completion. |
| **Romance & Social** | Indirect via Dialogue | Story Flow does not touch R&S directly. Dialogue signals flow to R&S independently. |
| **Gallery** (future) | Gallery depends on this | Gallery reads `story_flags` and node completion for CG unlock gating. |
| **Achievements** (future) | Achievements depends on this | Reads chapter completion, node counts, story flags for milestones. |

## Formulas

Story Flow has no mathematical formulas. All values are data-driven from chapter JSON files.

### Non-Formulas (Explicit)

- **Reward values** (gold, XP) are flat integers from the chapter JSON `reward` field. No scaling formula.
- **Node gating** is boolean flag-set intersection, not a calculation.
- **Chapter completion** is a binary check: all nodes `completed`.
- **XP accumulation** is simple addition. No leveling formula in MVP -- XP thresholds are deferred to Deck Management GDD.

## Edge Cases

### Node Execution

- **If a `dialogue` node's sequence_id references a missing JSON file**: Log error, mark node as `completed` with zero rewards. Do not block story progression. Surface error in debug overlay.
- **If `dialogue_blocked` fires for a required story sequence**: This is always a data error (node gating should have prevented reaching a blocked sequence). Log error with node_id and blocked reason. Skip the sequence and continue execution.
- **If the player force-quits during a `mixed` node between dialogue and combat**: Node is `in_progress` in save. On resume, re-enter from the beginning of the node (replay dialogue). Dialogue is stateless between sequences -- no partial state to corrupt.
- **If the player force-quits during combat**: Node is `in_progress`. Combat state is NOT saved (per Poker Combat GDD). On resume, re-enter from Chapter Map with retry prompt.
- **If a node's `unlocks_companions` references an already-met companion**: Skip the `met = true` write (idempotent). No error, no companion reveal animation.

### Flag Edge Cases

- **If a dialogue `set_flag` effect references a flag not in the active node's `sets_flags`**: Log warning in debug, silently drop in release. The flag is NOT set.
- **If a node's `requires_flags` includes a flag that no prior node sets**: The node is permanently locked. This is a data error -- caught by `/consistency-check` at design time.
- **If `GameStore.story_flags` is corrupted (duplicate entries)**: Deduplicate on load. Flag presence is checked via `in` operator, so duplicates are harmless but wasteful.
- **If a save from an older version is loaded in a version with new nodes/flags**: New nodes start as `not_started`. Missing flags are simply absent -- gating works correctly. Forward-compatible by design.

### Reward Edge Cases

- **If gold/xp would exceed a future cap**: No cap defined in MVP. Values accumulate without limit. When Camp or Deck Management define sinks, add caps there.
- **If a `reward` node has gold=0 and xp=0**: Valid. The node is a pure narrative beat (e.g., cutscene). No reward panel displayed.

### Chapter Edge Cases

- **If the player completes all Chapter 1 nodes but Chapter 2 JSON is missing**: `next_chapter` resolves to null. Chapter Map shows "To be continued..." state. No crash.
- **If the player re-enters a `completed` node**: Not possible. Chapter Map disables completed nodes (greyed out, non-tappable). The state machine has no transition from `completed` to any other state.

## Dependencies

| System | Direction | Nature | Interface |
|---|---|---|---|
| **Dialogue** | Story Flow depends on this | **Hard** | `start_dialogue(chapter_id, sequence_id)` / `dialogue_ended` / `dialogue_blocked` signals. Story Flow cannot present narrative without Dialogue. |
| **Poker Combat** | Story Flow depends on this | **Hard** | `SceneManager.change_scene(COMBAT, context)` / `combat_completed(result)`. Story Flow cannot present combat encounters without Poker Combat. |
| **Companion Data** | Story Flow depends on this | **Hard** | Writes `met = true` on companion unlock nodes. Reads companion IDs for validation. |
| **Scene Navigation** | Story Flow depends on this | **Hard** | All scene transitions route through SceneManager. |
| **Save System** | Story Flow depends on this | **Hard** | Persists `node_states`, `story_flags`, `current_node_id`, `player_gold`, `player_xp` via GameStore. |
| **Localization** | Story Flow depends on this | **Soft** | `title_key` fields resolve via Localization for Chapter Map display. Works without (shows raw keys). |
| **Romance & Social** | Indirect | **Soft** | Dialogue emits relationship/trust signals to R&S. Story Flow is unaware of this flow. |
| **Gallery** | Gallery depends on this | **Soft** | Reads `story_flags` and completion state for CG gating. Not yet designed. |
| **Achievements** | Achievements depends on this | **Soft** | Reads chapter completion, flag counts, node progress. Not yet designed. |

**Hard dependencies (5):** Dialogue, Poker Combat, Companion Data, Scene Navigation, Save System.
**Soft dependencies (4):** Localization, Romance & Social (indirect), Gallery, Achievements.

**Bidirectional consistency notes:**
- Dialogue GDD lists Story Flow as a downstream system that orchestrates sequences
- Poker Combat GDD lists Story Flow as consuming combat outcomes
- Companion Data GDD lists Story Flow as writing `met = true`
- Scene Navigation GDD lists Story Flow as a caller of `change_scene()`
- Romance & Social GDD lists Story Flow as reading `romance_stage` for gating

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|---|---|---|---|---|
| `DIALOGUE_NODE_XP` | 60 | [20, 150] | Faster XP accumulation through story | Slower; combat becomes the primary XP source |
| `COMBAT_NODE_GOLD` | 50 | [20, 150] | More gold per fight; Camp economy floods faster | Less gold; player must be efficient with gifts |
| `BOSS_NODE_GOLD` | 100 | [50, 300] | Boss victory feels like a milestone jackpot | Boss feels unrewarding relative to effort |
| `BOSS_NODE_XP` | 200 | [100, 400] | Boss XP is a significant progression spike | Boss XP is incremental, not milestone |
| `CHAPTER_1_NODE_COUNT` | 10 | [6, 14] | Longer chapter; more story beats and companion time | Shorter; faster to reach Chapter 2 |
| `COMBAT_DEFEAT_MODE` | `retry` (all Ch1) | `retry` or `continue` | `continue` removes all friction; story never blocks | `retry` ensures combat mastery |

**Cross-knob interactions:**
- `CHAPTER_1_NODE_COUNT` x reward values determines total gold/XP entering the Camp economy. If node count increases, per-node rewards may need to decrease to maintain pacing.
- `COMBAT_DEFEAT_MODE` interacts with difficulty: if combat is too hard, `retry` creates frustration loops. If too easy, `continue` removes all stakes.

## Visual/Audio Requirements

### Visual Feedback

| Event | Visual Feedback | Audio | Priority |
|---|---|---|---|
| Node unlock | Node icon on Chapter Map pulses gold, glow aura | Soft ascending chime | MVP |
| Node enter | FADE transition (0.3s) to dialogue or combat scene | Ambient music cross-fades to node track | MVP |
| Companion unlock reveal | Black overlay, portrait slides in from right at full height, Cinzel gold text: "[Name]". Element color ink wash behind portrait. | Orchestral sting (companion-specific, 3-4s). Non-verbal cue. | MVP |
| Combat victory (story) | Score animation, then FADE to Chapter Map. Node icon fills gold. | Victory fanfare (2s brass) | MVP |
| Combat defeat + retry | FADE to Chapter Map. Retry prompt modal (gold border). | Low brass descending note. Empathetic, not punishing. | MVP |
| Reward panel | Slide-up panel: gold + XP gained. Gold coin icon animates. | Coin clink per reward line. | MVP |
| Node completed | Chapter Map icon changes to gold circle + checkmark. | Soft confirmation tone. | MVP |
| Chapter completed | Summary screen: chapter title in Cinzel, completion stats. Painterly ink wash background. | Full orchestral resolution (8-12s). | MVP |
| Boss node enter | Pre-combat dialogue, boss name banner (red tint). | Boss music intro. | MVP |
| "To be continued" | Chapter 2 icon locked with "Coming Soon" label. | No audio change. | MVP |

### Art Principles
1. **Node transitions are page turns**: Every scene change must feel deliberate and weighted. Companion unlocks and chapter completions get ceremony.
2. **Companion reveals are mythic entrances**: Meeting a companion must feel like encountering a legend, not spawning an NPC.
3. **Restraint on defeat**: No harsh failure screens. The retry prompt is gentle and empathetic.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| Chapter Map (node list) | Full screen, scrollable vertical list | On node state change | Chapter Map screen |
| Node status icons | Per-node: locked (grey/padlock), available (gold/star), in-progress (gold/arrow), completed (gold/checkmark) | On node transition | Chapter Map |
| Node title | Below each node icon | Static | Chapter Map |
| Current chapter title | Top of Chapter Map | On chapter change | Always |
| Retry prompt | Modal overlay, center screen | On combat defeat | `defeat_mode: retry` |
| Reward panel | Slide-up from bottom, 200px height | On node completion | 3s auto-dismiss or tap |
| Chapter summary screen | Full screen | On chapter completion | Once per chapter |
| "To be continued" | Bottom of Chapter Map | Static | Next chapter unavailable |

**Layout** (portrait 430x932):
- **Header** (0-80px): Chapter title, progress indicator
- **Node list** (80-850px): Scrollable vertical node chain with icons and titles
- **Navigation** (850-932px): Back to Hub button

**Accessibility**: Node status distinguished by icon shape (not just color). Locked=padlock, available=star, in-progress=arrow, completed=checkmark. All touch targets minimum 44x44px.

> **UX Flag -- Story Flow**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the Chapter Map screen **before** writing epics.

## Acceptance Criteria

### Rule 1-3 — Node Schema and Sequencing
- [ ] **AC-SF-01** — **GIVEN** a valid chapter JSON file, **WHEN** parsed, **THEN** all required fields are present and type-correct for every node.
- [ ] **AC-SF-02** — **GIVEN** node `ch01_n03` with `requires_flags: ["artemis_house_complete"]`, **WHEN** that flag is not in `story_flags`, **THEN** the node shows as locked and cannot be entered.
- [ ] **AC-SF-03** — **GIVEN** node `ch01_n02` completed, **WHEN** Chapter Map renders, **THEN** `ch01_n03` shows as available, `ch01_n04+` remain locked.

### Rule 2 — Node Types
- [ ] **AC-SF-04** — **GIVEN** a `dialogue` node, **WHEN** entered, **THEN** `start_dialogue()` called and Story Flow awaits `dialogue_ended` before granting rewards.
- [ ] **AC-SF-05** — **GIVEN** a `mixed` node, **WHEN** dialogue ends, **THEN** combat loads. After victory, post-combat sequence plays before rewards.
- [ ] **AC-SF-06** — **GIVEN** a `boss` node, **WHEN** entered, **THEN** boss music signal emitted and boss HP bar activated.
- [ ] **AC-SF-07** — **GIVEN** a `companion_unlock` node with `unlocks_companions: ["artemisa"]`, **WHEN** completed, **THEN** `artemisa.met = true` and companion reveal animation plays.

### Rule 4 — Story Flags
- [ ] **AC-SF-08** — **GIVEN** node `ch01_n01` completes with `sets_flags: ["prologue_complete"]`, **WHEN** flags checked, **THEN** `"prologue_complete"` is in `GameStore.story_flags`.
- [ ] **AC-SF-09** — **GIVEN** dialogue `set_flag` for flag NOT in node's `sets_flags`, **WHEN** executed, **THEN** flag NOT set, warning logged, execution continues.
- [ ] **AC-SF-10** — **GIVEN** all Ch1 nodes completed, **WHEN** flags counted, **THEN** exactly 11 flags matching canonical set.

### Rule 5 — Rewards
- [ ] **AC-SF-11** — **GIVEN** boss node `ch01_n08` completes, **WHEN** rewards granted, **THEN** gold +100, XP +200.
- [ ] **AC-SF-12** — **GIVEN** reward node with gold=0, xp=0, **WHEN** completed, **THEN** no reward panel, flags still set.

### Rule 6 — Combat Defeat
- [ ] **AC-SF-13** — **GIVEN** combat defeat with `defeat_mode: retry`, **WHEN** received, **THEN** retry prompt appears, node stays `in_progress`, no rewards/flags.
- [ ] **AC-SF-14** — **GIVEN** retry prompt showing, **WHEN** "Retry" tapped, **THEN** combat re-enters with same enemy. Unlimited retries.
- [ ] **AC-SF-15** — **GIVEN** win on 3rd retry attempt, **WHEN** rewards granted, **THEN** full rewards (no penalty for retries).

### Rule 7 — Chapter Completion
- [ ] **AC-SF-16** — **GIVEN** all 10 Ch1 nodes `completed`, **WHEN** final node finishes, **THEN** `ch01_complete` flag set, `chapter_completed` emitted, summary screen shown.
- [ ] **AC-SF-17** — **GIVEN** Ch1 complete, Ch2 JSON missing, **WHEN** Chapter Map renders, **THEN** "To be continued..." shown, no crash.

### State Machine
- [ ] **AC-SF-18** — **GIVEN** completed node, **WHEN** tapped on Chapter Map, **THEN** nothing happens (greyed, non-tappable).
- [ ] **AC-SF-19** — **GIVEN** force-quit during `in_progress` mixed node, **WHEN** reopened, **THEN** node still `in_progress`, re-enters from beginning.

### Cross-System
- [ ] **AC-SF-20** — **GIVEN** `dialogue_blocked` in story node, **WHEN** error logged, **THEN** execution continues, node not stuck.
- [ ] **AC-SF-21** — **GIVEN** node completion autosave, **WHEN** save completes, **THEN** `node_states`, `story_flags`, `player_gold`, `player_xp` all persisted.

### Performance and Data
- [ ] **AC-SF-22** — Chapter JSON parsing completes within 50ms for a 12-node chapter.
- [ ] No reward values, flag names, or node sequences hardcoded outside chapter JSON data files.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---|---|---|---|
| `start_dialogue(chapter_id, sequence_id)` | `design/gdd/dialogue.md` | Rule 2a (Load) | Data dependency |
| `dialogue_ended` / `dialogue_blocked` signals | `design/gdd/dialogue.md` | Rule 2h / Rule 7b | State trigger |
| `combat_completed({victory, score, hands_used})` | `design/gdd/poker-combat.md` | Rule 10 (Victory/Defeat) | State trigger |
| `SceneManager.change_scene(SceneId, context)` | `design/gdd/scene-navigation.md` | Rule 6 (Context payload) | Data dependency |
| `companion.met = true` write | `design/gdd/companion-data.md` | Companion state `met` field | Ownership handoff |
| `romance_stage` for dialogue gating | `design/gdd/companion-data.md` | Romance Stage Derivation | Data dependency |
| `story_flags` via GameStore | `design/gdd/save-system.md` | Serialization contract (Rule 3) | Rule dependency |
| `relationship_changed` / `trust_changed` Dialogue->R&S | `design/gdd/romance-social.md` | Rule 7 (Dialogue deltas) | Ownership handoff |
| `romance_stage` / `relationship_level` for gating | `design/gdd/romance-social.md` | Stage progression | Data dependency |

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should completed nodes be replayable for story re-reading (no rewards)? | game-designer | Before Gallery GDD | Would require a `replay` state. Currently not supported. |
| Should XP be displayed in the reward panel before Deck Management defines its use? | ux-designer | Before UI implementation | Current: hide XP display until a system consumes it. |
| Will Chapter 2 support non-linear node unlocks (branching chapter structure)? | game-designer | Before Chapter 2 writing | Flag system supports it. Chapter 1 is intentionally linear. |
| Should `defeat_mode: continue` be used for any Chapter 1 nodes? | game-designer | Before playtest | Currently all retry. |
| How does the Chapter Map visually represent the node chain? Linear scroll or path visualization? | art-director | Before Chapter Map UX spec | Affects art asset requirements significantly. |
