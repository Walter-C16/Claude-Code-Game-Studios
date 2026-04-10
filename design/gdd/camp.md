# Camp

> **Status**: Designed
> **Author**: game-designer + ux-designer
> **Last Updated**: 2026-04-09
> **Implements Pillar**: Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Camp is the Hub sub-tab where players conduct daily interactions with companion goddesses -- talking, gifting, and dating to build relationship levels that translate into combat power. It is a pure presentation layer: it reads relationship state from Romance & Social, dispatches interaction commands to it, and renders the results. Camp owns no game logic of its own.

> **Quick reference** -- Layer: `Feature` · Priority: `Vertical Slice` · Key deps: `Romance & Social, Scene Navigation`

## Overview

Camp is the daily ritual hub where the player invests in companion relationships. As a Hub sub-tab, it activates via keep-alive tab swap (no scene transition). The screen shows a grid of met companions with mood portraits, a token counter (3 daily pips), a streak badge, and interaction buttons (Talk, Gift, Date). All game logic -- relationship gains, mood transitions, streak calculation, buff grants -- lives in Romance & Social. Camp is the window into that system: it reads state, dispatches commands, and renders feedback. The gift flow uses an in-Camp overlay picker; the date flow launches a full scene transition via SceneManager.

## Player Fantasy

Camp is the quiet space between battles. The combat arena is loud and high-stakes; Camp is where fallen goddesses drop the performance and become themselves. The player comes here not to optimize but to show up -- to sit with someone who terrifies the rest of the world and simply be present. The fantasy is earned intimacy: learning that Artemis hates gold offerings but lights up at wildflowers, seeing Nyx's mood shift from Lonely to Excited over three consecutive visits, feeling the goddess lean in a little more each time you return. Camp does not announce itself as a power system. The buffs are a consequence, not the reason.

## Detailed Design

### Core Rules

**Rule 1 -- Camp is a UI layer, not a logic owner.** Camp reads all state from Romance & Social (relationship levels, moods, streak, token count, known preferences, active buff) and writes nothing directly to save data. All mutations flow through R&S's public API: `do_talk(companion_id)`, `do_gift(companion_id, item_id)`, `start_date(companion_id)`. Camp renders the response.

**Rule 2 -- Companion grid shows met companions only.** The grid populates from CompanionData filtered to `met = true`. Unmet companions are absent -- no locked placeholder, no silhouette. The grid is 2-column, scrollable vertically. Each cell shows the companion's current mood portrait, name, and a romance stage badge.

**Rule 3 -- Token display is always visible.** Three pip icons anchored to the top bar. Filled pips are lit; spent pips are dimmed. Updates immediately after each interaction. When all three are spent, interaction buttons are disabled and a "Come back tomorrow" label replaces them. Token count is owned by R&S; Camp reflects it.

**Rule 4 -- Selecting a companion loads the companion panel.** Tapping a grid cell transitions to companion-selected state. The panel shows: large mood portrait, name, stage label, RL progress bar (current RL / threshold to next stage), streak counter with multiplier badge, active CombatBuff indicator (if any), and three interaction buttons. Known likes/dislikes appear as icon rows at romance_stage >= 2.

**Rule 5 -- Interaction button gating mirrors R&S rules exactly.** Talk: enabled if `met = true` and tokens > 0. Gift: enabled if `met = true`, tokens > 0, and player has >= 1 giftable item. Date: enabled if `romance_stage >= 1` and tokens > 0. Disabled buttons are visually greyed and non-tappable, not hidden.

**Rule 6 -- Gift flow is an in-Camp item picker, not a scene change.** Tapping Gift opens a scrollable item grid overlay within Camp. Items matching `known_likes` show a preference hint icon at stage >= 2. Selecting an item calls `do_gift()`, overlay closes, companion panel updates with R&S response.

**Rule 7 -- Date launches as a full scene transition.** Tapping Date calls `SceneManager.change_scene(SceneId.DATE, { "companion_id": id })`. On return, Hub restores Camp tab via context payload `{ "restore_tab": 3 }` and Camp refreshes state from R&S.

### States and Transitions

| State | Trigger | UI Shown |
|---|---|---|
| `GRID` | Tab activated, no companion selected | Companion grid + token bar + streak badge |
| `COMPANION_SELECTED` | Grid cell tapped | Companion panel + interaction buttons + token bar |
| `GIFT_PICKER` | Gift button tapped | Item picker overlay above companion panel |
| `INTERACTING` | Interaction button confirmed | Brief animation/response; buttons locked |
| `TOKENS_EXHAUSTED` | All 3 tokens spent | Buttons disabled; "Come back tomorrow" shown |
| `NO_COMPANIONS` | No companions with `met = true` | Empty state: story-flavored prompt |

**Transitions:**
- `GRID` -> `COMPANION_SELECTED`: tap grid cell
- `COMPANION_SELECTED` -> `GRID`: tap back/deselect
- `COMPANION_SELECTED` -> `GIFT_PICKER`: tap Gift
- `GIFT_PICKER` -> `COMPANION_SELECTED`: select item or cancel
- `COMPANION_SELECTED` -> `INTERACTING`: tap Talk or confirm Gift
- `INTERACTING` -> `COMPANION_SELECTED`: interaction complete
- `COMPANION_SELECTED` -> scene change (Date): tap Date (exits Camp)
- Any -> `TOKENS_EXHAUSTED`: token count reaches 0

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| **Romance & Social** | Read + Call | `get_token_count()`, `get_streak()`, `get_companion_state(id)`, `do_talk(id)`, `do_gift(id, item)`, `start_date(id)` |
| **Companion Data** | Read | `companion_list`, `met` flag, portrait paths per mood, stage thresholds |
| **Scene Navigation** | Call (Date only) | `SceneManager.change_scene(SceneId.DATE, context)` |
| **Inventory / Item Data** | Read | Gift item list, item names, category tags for preference hints |
| **UI Theme** | Read | Color tokens, typography, touch target standards |

## Formulas

Camp is display-only. No original formulas. All displayed values are computed by Romance & Social:

- **RL progress bar fill**: `current_rl / stage_threshold` -- from R&S state
- **Streak multiplier badge**: formatted from R&S streak table (1.0x-1.5x)
- **Token pips**: `tokens_remaining` integer (0-3) from R&S

No Camp-authored math.

## Edge Cases

- **If no met companions at session start**: Camp enters `NO_COMPANIONS` state. Shows story-flavored prompt: "No one has found their way to camp yet." No grid, no buttons.
- **If all 3 tokens spent before entering Camp**: Opens directly into `TOKENS_EXHAUSTED`. Buttons disabled on first render. Player can still browse companion info.
- **If newly met companion mid-session**: Grid refreshes on tab activation (polls `CompanionData.met` on tab show). New companion appears with Content mood.
- **If Gift tapped with empty inventory**: Gift button greyed and disabled regardless of tokens. Tooltip: "No gifts in inventory."
- **If Date tapped at stage 0**: Date button disabled (greyed, non-tappable). Gate enforced in Camp UI and redundantly in R&S.
- **If active CombatBuff has combats_remaining = 0**: R&S clears buff before Camp reads. Camp handles null buff gracefully -- indicator area hidden.
- **If player taps another companion during INTERACTING state**: Grid and buttons locked during interaction. Queued taps discarded. Lock releases on completion.
- **If midnight UTC crosses while Camp is open**: R&S emits `tokens_reset` signal. Camp re-renders token bar immediately without requiring tab exit.
- **If Date scene is interrupted (OS suspend, crash)**: Camp restores from R&S state. Partial dates don't grant rewards (R&S responsibility).
- **If known_likes arrays non-empty but romance_stage < 2**: Preference hint icons do NOT render. Stage check gates display, not array emptiness.

## Dependencies

| System | Direction | Nature | Interface |
|---|---|---|---|
| **Romance & Social** | Camp depends on this | **Hard** | Reads all state, dispatches all mutations via API. Camp cannot function without R&S. |
| **Companion Data** | Camp depends on this | **Hard** | Reads `met`, portraits, stage labels. Camp cannot display companions without this. |
| **Scene Navigation** | Camp depends on this | **Soft** | Date scene transition only. Camp tab itself is Hub-internal (no SceneManager). |
| **UI Theme** | Camp depends on this | **Soft** | Color tokens, typography. Functional without (falls back to Godot defaults). |
| **Localization** | Camp depends on this | **Soft** | Companion names, button labels, token-exhausted text resolve via `get_text()`. Works without (shows raw keys). |
| **Gift Items** | Camp depends on this | **Soft** | Gift picker reads item list from `gift_items.json`. Without it, Gift button is always disabled. Source: `design/quick-specs/gift-items.md`. |

**Hard (2):** Romance & Social, Companion Data.
**Soft (4):** Scene Navigation, UI Theme, Localization, Gift Items.

**Bidirectional:** Romance & Social GDD lists Camp as a consumer of its API. Scene Navigation GDD notes Hub sub-tabs are keep-alive, not scene changes.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|---|---|---|---|---|
| `interaction_animation_duration_sec` | 0.4 | [0.2, 0.8] | More weight to interaction feedback | Snappier, less emotional |
| `gift_picker_columns` | 2 | [2, 4] | More items visible, smaller thumbnails | Larger thumbnails, more scrolling |
| `streak_badge_pulse_threshold` | 5 | [3, 7] | Later celebratory feedback | Earlier streak celebration |
| `preference_hint_icon_opacity` | 1.0 | [0.6, 1.0] | Fully legible hints | "Partial knowledge" visual tone |
| `tokens_exhausted_label` | "Come back tomorrow" | -- | Localizable string. Narrative voice. | -- |

## Visual/Audio Requirements

### Visual

| Element | Specification | Priority |
|---|---|---|
| Mood portraits | 6 per companion, expressive at ~200px height. Crossfade (0.2s) on mood change. | Vertical Slice |
| RL progress bar | Per-companion signature color fill. Desaturated when empty. | Vertical Slice |
| Token pips | Three states: Lit (available), Dimmed (spent), Pulsing (just reset). Mythological style, not generic circles. | Vertical Slice |
| Stage badge | Text label + tier icon. Legible at 11sp minimum. | Vertical Slice |
| CombatBuff indicator | Compact icon + "X fights" label. Gold/combat-red accent. | Vertical Slice |
| Preference icons | Small category icons (nature, luxury, food, etc.). Liked = warm accent, disliked = cool/muted. | Vertical Slice |

### Audio

| Event | Audio |
|---|---|
| Talk response | Short ambient chime, companion-specific tone |
| Gift liked | Warm ascending tone |
| Gift disliked | Flat/descending tone |
| Gift neutral | UI confirm only |
| Date launch | Transitional audio swell |
| Streak milestone (day 7) | Celebratory flourish on badge |
| Token depleted (last pip) | Soft, regretful tone |
| Midnight token reset | Gentle chime + pip re-light |

### Art Principles
1. **Portraits are the heartbeat**: Mood portraits must be expressive enough to communicate state without text labels.
2. **Warmth over efficiency**: Camp should feel like a hearth, not a menu. Brown/gold palette, soft lighting, no sharp UI edges.
3. **Token depletion is closure, not punishment**: The "Come back tomorrow" state should feel like a natural stopping point, not a paywall.

## UI Requirements

**Layout** (portrait 430x932):

| Zone | Y Range | Content |
|---|---|---|
| Top bar | 0-56px | Hub tab area, token pips (right), streak badge (below pips) |
| Content area | 56-780px | Companion grid (2-column, scrollable) OR companion panel (portrait, stats, preferences) |
| Action bar | 780-932px | Talk / Gift / Date buttons (44px min height each). "Come back tomorrow" when exhausted. |

**Touch targets**: All interactive elements >= 44x44px. Grid cards >= 88x88px. Gift picker items >= 44x44px.
**Gift picker overlay**: Modal sheet from bottom, 60% screen height, 2-column scrollable grid. Dismiss via outside tap or cancel.
**Safe zone**: Action bar bottom edge respects device safe area inset.
**Accessibility**: No hover states (touch only). Mood communicated by portrait expression + stage badge text, not color alone.

> **UX Flag -- Camp**: This system has complex UI requirements. In Phase 4, run `/ux-design` to create UX specs for the Camp tab, companion panel, gift picker overlay, and date transition **before** writing epics.

## Acceptance Criteria

### Functional
- [ ] **AC-CAMP-01** -- Camp tab activates via keep-alive hide/show within Hub. No SceneManager call. Tab switch < 1 frame delay.
- [ ] **AC-CAMP-02** -- Only companions with `met = true` appear in grid. Companions with `met = false` are absent.
- [ ] **AC-CAMP-03** -- Token pips show correct count from R&S on every tab activation. Spending a token immediately dims one pip.
- [ ] **AC-CAMP-04** -- Talk/Gift/Date buttons individually disabled when gate conditions not met. Greyed, non-tappable, not hidden.
- [ ] **AC-CAMP-05** -- Completing Talk updates RL bar and mood portrait on same screen without scene reload.
- [ ] **AC-CAMP-06** -- Gift picker opens as overlay (no scene transition). Selecting item calls `do_gift()`, picker closes, panel updates.
- [ ] **AC-CAMP-07** -- Date calls `SceneManager.change_scene(DATE, {companion_id})`. Return restores Camp tab via Hub context.
- [ ] **AC-CAMP-08** -- Preference hint icons appear on gift items only when `romance_stage >= 2` AND arrays non-empty.
- [ ] **AC-CAMP-09** -- CombatBuff indicator hidden when no active buff. Renders correctly when buff active.
- [ ] **AC-CAMP-10** -- Date button greyed at `romance_stage = 0` regardless of tokens.

### Experiential (Playtest)
- [ ] **AC-CAMP-11** -- New player identifies token count, selects companion, completes Talk within 30 seconds on first visit without tutorial.
- [ ] **AC-CAMP-12** -- 80%+ playtesters notice mood portrait changes between sessions without text label prompts.
- [ ] **AC-CAMP-13** -- Stage 2+ players correctly identify preference hint icons as "she likes this" without explanation.
- [ ] **AC-CAMP-14** -- 70%+ participants describe tokens-exhausted state as "natural stopping point" not "frustrating wall."

### Performance
- [ ] **AC-CAMP-15** -- Gift picker overlay opens/closes at 60fps with no frame drops on 430x932 device.

## Cross-References

| This Document References | Target GDD | Specific Element | Nature |
|---|---|---|---|
| Token count, streak, mood, interaction API | `design/gdd/romance-social.md` | Rules 1-6 (all camp interactions) | Data dependency |
| `met` flag, portrait paths, stage thresholds | `design/gdd/companion-data.md` | Companion state + portrait system | Data dependency |
| Hub tab keep-alive behavior | `design/gdd/scene-navigation.md` | Rule 2 (Hub tabs) | Rule dependency |
| Date scene transition | `design/gdd/scene-navigation.md` | Rule 6 (Context payload) | State trigger |
| Color tokens, typography, touch targets | `design/gdd/ui-theme.md` | Theme resource definitions | Data dependency |
| Romance stage gates blessing unlocks | `design/gdd/divine-blessings.md` | Slot availability table | Data dependency |

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Gift picker -- inventory source. No Inventory GDD exists. Who owns the item list API? | game-designer | Before Camp implementation | Broken dependency. Must resolve before stories. |
| Can Companion Room be reached from Camp (long-press portrait)? | ux-designer | Before UX spec | If yes, Camp needs a navigation trigger. |
| Empty-state copy ("No companions yet") needs narrative voice approval. | narrative-director | Before UI implementation | Placeholder is functional, not final. |
| Should streak badge also appear in companion panel, or top bar only? | ux-designer | Before UX spec | Top bar is global context; panel is per-companion. |
| Interaction animation spec (portrait reaction, RL bar motion, particles) needs UX definition. | ux-designer | Before implementation | Camp GDD defines the knob; UX spec defines the motion. |
