# Dialogue

> **Status**: In Design
> **Author**: game-designer + narrative-director + creative-director
> **Last Updated**: 2026-04-08
> **Implements Pillar**: Pillar 2 — Visual Novel Dialogue with Consequences

## Summary

The Dialogue system is the interactive narrative engine for Dark Olympus — it delivers all story content, character conversations, and branching choices through a visual novel-style interface with typewriter text, character portraits with mood variants, and player choices that produce visible consequences (stat changes, relationship shifts, story flags). It is broader than a pure dialogue tree: it handles narration, cutscene-style sequences, and in-game conversations across story nodes, camp interactions, and scripted events. Two downstream systems orchestrate it: Story Flow sequences dialogue within chapter nodes, and Romance & Social feeds relationship changes triggered by dialogue choices.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Localization, Companion Data`

## Overview

The Dialogue system is the primary narrative delivery mechanism in Dark Olympus — the engine through which the player experiences story, character, and consequence. When a dialogue sequence begins, the system loads a script (a structured data file of nodes), displays text line by line with typewriter animation, shows character portraits with mood-appropriate expressions, and presents branching choices when the script calls for them. The player advances text by tapping and selects choices from on-screen options. Each choice can trigger effects: relationship point changes, trust adjustments, story flag sets, and item grants. The system resolves all player-facing text through the Localization autoload (`get_text(key, params)`), reads companion profiles from Companion Data for portrait display and branch gating (e.g., a dialogue branch available only at romance stage 2+), and emits signals that consuming systems (Story Flow, Romance & Social) use to apply consequences. It supports multiple speaker types — companions with full portrait/mood support, the priestess NPC with portraits but no companion state, a narrator voice with no portrait, and environmental text. The system must feel like a living conversation where choices matter — not a wall of text between combat encounters — because under Pillar 2, dialogue IS gameplay.

## Player Fantasy

Every conversation in Dark Olympus is an act of perception. These are not ordinary people — they are fallen goddesses, ancient warriors, beings who once held divine authority and lost it. They deflect, they posture, they test. The player fantasy is being the one who sees through the mask — the person perceptive enough to read what Artemisa means when she looks away mid-sentence, what Hipolita hides behind bravado, why the priestess won't answer directly. When a dialogue choice lands, it doesn't feel like picking the "right answer" from a menu; it feels like understanding someone well enough to say what they needed to hear.

This is powered by a secondary fantasy of *consequence*: every choice the player makes during dialogue reshapes the world as tangibly as a winning poker hand reshapes combat. A trust gain is not a hidden number ticking up — it's a companion's portrait shifting from guarded to warm. A wrong word isn't punished with a game-over; it's punished with a goddess going quiet, her mood portrait shifting to something the player hasn't seen before. The weight of dialogue comes from knowing that the next line could open a door or close one — and that the player chose it.

The anchor moment is not the grand speech or the dramatic revelation. It's the small beat: a companion says something dismissive, and one of the dialogue options is the one that sees through it. The player who picks it earns a response that no other choice would have produced — a moment of vulnerability from someone who doesn't give it easily. That moment is the reward. That moment is what makes the player come back to talk to this companion again tomorrow.

*Pillar 2: "Dialogue IS gameplay, not an obstacle between fights." The player's skill in dialogue is reading people — not optimizing stats.*

## Detailed Design

### Core Rules

**1. Dialogue Script Data Format.** Each dialogue sequence is a JSON file at `res://assets/data/dialogue/{chapter_id}/{sequence_id}.json`. The root object contains:

| Root Field | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | String | Yes | Matches filename. Unique across all dialogue scripts. |
| `nodes` | Dictionary | Yes | Maps `node_id` (String) to node objects. |
| `requires_met` | String | No | Companion ID. Sequence blocked if `companion.met == false`. |
| `requires_romance_stage` | Object | No | `{ "companion": id, "min": N }`. Blocked if `romance_stage < min`. |
| `requires_flag` | String | No | Story flag name. Blocked if flag not set. |

**Node schema:**

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `id` | String | Yes | Unique within the script. `"start"` is reserved as entry point. |
| `speaker` | String | Yes | Companion ID, `"priestess"`, `"narrator"`, `"environment"` |
| `speaker_type` | Enum | Yes | `"companion"`, `"npc"`, `"narrator"`, `"environment"` |
| `text_key` | String | Yes | Localization key passed to `Localization.get_text(key, params)` |
| `text_params` | Dictionary | No | Parameters for interpolation (e.g., `{"name": "Artemisa"}`) |
| `mood` | String | Required for companion/npc | `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive` |
| `choices` | Array | No (default `[]`) | If non-empty, `next` is ignored. |
| `next` | String | Required if `choices` is empty | Node ID or `"END"` |

**Choice schema:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Unique within this node's choices |
| `text_key` | String | Yes | Localization key for choice label |
| `tier` | Enum | No (default `"standard"`) | `"standard"`, `"insight"`, `"cost"` |
| `condition` | Object | No | Gate condition (see Rule 4) |
| `effects` | Array | No (default `[]`) | Applied on selection |
| `next` | String | Yes | Node ID or `"END"` |

1a. Every node must be reachable from `"start"` via `next`/`choice.next` chains. Unreachable nodes are stripped at load with a warning.

1b. Every `next` and `choice.next` must resolve to a valid node ID or `"END"`. Invalid refs trigger a descriptive error in debug; graceful end in release.

1c. A node may not have both `choices` populated and a `next` field. If both present, `choices` takes priority; `next` is ignored with a warning.

**2. Turn Flow.** Each dialogue sequence executes these steps in order:

2a. **Load.** DialogueRunner receives `sequence_id` and `chapter_id`. Loads the JSON file. Parses into Dictionary. Sets `current_node_id = "start"`.

2b. **Sequence gate check.** Evaluates root-level gates (`requires_met`, `requires_romance_stage`, `requires_flag`). If any fail, the sequence aborts and emits `dialogue_blocked(sequence_id, reason)`. No UI is displayed.

2c. **Display node.** Reads the current node. Dispatches to the speaker-type display handler (see Rule 3). Renders speaker name, portrait (if applicable), and begins typewriter animation.

2d. **Advance.** Player taps the dialogue area. If typewriter is running: complete instantly (skip remaining animation + pause markers). Tap is consumed — does not also advance. If typewriter is complete: advance to next step.

2e. **Choice presentation.** If `choices` is non-empty, after typewriter completes, the choice panel slides in from the bottom. Each choice is evaluated for visibility (Rule 4). Player taps one choice.

2f. **Effect resolution.** Effects from the chosen option execute in array order (Rule 5). Effects are synchronous. DialogueRunner does not advance until all complete.

2g. **Next node.** Sets `current_node_id` to `choice.next` or `next`. Returns to step 2c. If value is `"END"`, proceed to 2h.

2h. **End sequence.** Emits `dialogue_ended(sequence_id)`. Clears dialogue UI. Story Flow receives the signal.

**3. Speaker Types.**

3a. **Companion** (`speaker_type: "companion"`). Portrait displays on the left side, 200×400 logical px. Mood determines variant: `res://assets/images/companions/{speaker}/{speaker}_{mood}.png`. Speaker name from Companion Data `display_name`. If `companion.met == false`, this node is a data error — log warning, skip node.

3b. **NPC** (`speaker_type: "npc"`). Portrait displays identically to companion. Speaker name resolved via `get_text("COMP_PRIESTESS")`. No companion state lookup. No `met` gate. Priestess portraits at `res://assets/images/npcs/priestess/priestess_{mood}.png`.

3c. **Narrator** (`speaker_type: "narrator"`). No portrait. No speaker name label. Text renders centered/full-width in italic style. Mood field is absent; ignored if present.

3d. **Environment** (`speaker_type: "environment"`). No portrait. No speaker name. Text renders in a visually distinct panel (dimmed background, environmental icon). Used for ambient text, inscriptions, location descriptions. Mood ignored.

3e. **Portrait transitions.** When mood changes between consecutive companion/NPC nodes, the portrait crossfades over `PORTRAIT_CROSSFADE_SEC` (default 0.15s). Text does not wait for the crossfade.

**4. Choice Mechanics.**

4a. **Choice rendering.** Choices render as vertically stacked tap targets at the bottom of the screen. Minimum height: 44px per target. Maximum 4 choices per node. If >4 pass conditions, show the first 4 and log a warning.

4b. **Choice tiers.** Three tiers affect presentation and authoring:

- **Standard** — always visible (unless condition-gated). Differ in tone. No visual marker.
- **Insight** — gated by prior observation (flag-based conditions, not stat thresholds). Invisible if the player hasn't earned the flag. When visible, no special marker — the player doesn't know it was hidden from others. The insight option's text is the tell: it references something only an attentive player would know.
- **Cost** — always visible. Displays a brief consequence preview beneath the choice text (e.g., *"Hipolita will remember this."*). Used for trust-breaking or irreversible moments.

4c. **Condition evaluation.** Each choice may have a `condition`. If absent, the choice is visible. Supported conditions:

| Condition type | Fields | Pass condition |
|---------------|--------|----------------|
| `romance_stage` | `companion`, `min` | `companion.romance_stage >= min` |
| `met` | `companion` | `companion.met == true` |
| `flag_set` | `flag` | Story flag is true |
| `flag_not_set` | `flag` | Story flag is false or absent |
| `trust_min` | `companion`, `value` | `companion.trust >= value` |

A choice whose condition fails is **hidden entirely** — not greyed out, not locked. Invisible. If ALL choices fail their conditions, this is a data error; log warning and end sequence.

4d. **Conditions are evaluated at render time**, not at script load. This allows flags set earlier in the same sequence to gate later choices.

**5. Effects.**

5a. Supported effect types:

| Effect type | Fields | Action |
|------------|--------|--------|
| `relationship` | `companion`, `delta` (int) | Emits `relationship_changed(companion_id, delta)` |
| `trust` | `companion`, `delta` (int) | Emits `trust_changed(companion_id, delta)` |
| `flag_set` | `flag` | Sets story flag to true |
| `flag_clear` | `flag` | Clears story flag |
| `item_grant` | `item_id`, `quantity` | Emits `item_granted(item_id, quantity)` |
| `mood_set` | `companion`, `mood` | Updates portrait immediately |

5b. DialogueRunner does not apply state changes directly. It emits signals. Downstream systems (Romance & Social, Story Flow, Inventory) receive and apply them.

5c. **Effect feedback.** Relationship and trust changes are communicated through two layers:

- **Immediate**: The companion's portrait mood shifts within the same beat (via `mood_set` effect or next node's mood field).
- **Deferred**: A subtle HUD pulse (relationship icon glows briefly) on transition out of the dialogue sequence, not inline. No floating numbers. No exact deltas shown during the scene.

This preserves the reading-people fantasy: the player reads the companion's reaction, not a scoreboard.

**6. Text Display Rules.**

6a. **Typewriter speed.** Characters reveal at `TYPEWRITER_CPS` characters per second (default: 40). Configurable in dialogue config.

6b. **Pause markers.** Resolved text may contain `{pause:N}` (N = seconds, float, range 0.1–3.0). Typewriter pauses for N seconds, then continues. Markers are stripped from visible text.

6c. **Tap to complete.** Tapping during typewriter skips remaining animation and shows full text. The tap is consumed — does not advance.

6d. **Wait for tap.** After typewriter completes, a visual indicator appears (blinking arrow). Player taps to proceed.

6e. **Text length limit.** No single node's resolved text may exceed 280 characters. If exceeded, truncate at nearest word boundary with `[...]`. Log a content warning.

6f. **No auto-advance.** Text never advances without player input. No auto-play mode in MVP.

**7. Dialogue Gating.**

7a. Root-level gates (`requires_met`, `requires_romance_stage`, `requires_flag`) are checked before any UI displays.

7b. Gate failure emits `dialogue_blocked(sequence_id, reason)`. Story Flow determines the fallback.

7c. **Gating is invisible.** Players never see "locked" or "come back later" messages from the Dialogue system. Gated sequences don't appear. Gated choices don't render.

**8. Pacing Rules.**

8a. **6-line cap.** No more than 6 consecutive dialogue lines may pass without a player interaction (tap-to-advance or choice selection). This is a content authoring constraint enforced in pre-release validation, not at runtime.

8b. **12-line max between choices.** Maximum two 6-line segments between choice points. If a scene exceeds this, it needs a choice point or a scene cut.

8c. **Dialogue fatigue check.** If a sequence has >3 consecutive choice-free exchanges, it should be flagged for review during authoring.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| **Idle** | No sequence loaded | `start_dialogue()` called | DialogueRunner is inactive. No UI visible. |
| **Loading** | `start_dialogue(chapter_id, sequence_id)` called | JSON parsed, gates pass | Loads script, evaluates root gates. |
| **Blocked** | Root gate fails during Loading | Signal emitted, returns to Idle | Emits `dialogue_blocked`. No UI shown. |
| **Displaying** | Node is being rendered | Typewriter completes | Portrait + text rendering. Typewriter animating. Tap-to-complete available. |
| **Waiting** | Typewriter complete, no choices | Player taps | Shows advance indicator. Waiting for tap. |
| **Choosing** | Node has choices, typewriter complete | Player taps a choice | Choice panel visible. Waiting for selection. |
| **Resolving** | Choice selected or non-choice node advances | Effects complete | Executing effect array. Brief pause for portrait mood shift. |
| **Ended** | `"END"` reached or sequence aborted | Signal emitted, returns to Idle | Emits `dialogue_ended`. Clears UI. |

Transitions: Idle → Loading → Displaying → Waiting → Displaying (loop) / Choosing → Resolving → Displaying (loop) / → Ended → Idle. Loading → Blocked → Idle (gate failure path).

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Localization** | Dialogue depends on Localization | `Localization.get_text(key, params)` for all text resolution | DialogueRunner delegates all string resolution. No internal translation cache. |
| **Companion Data** | Dialogue depends on Companion Data | Reads `display_name`, portrait paths, `met`, `romance_stage`, `trust` | Used for speaker names, portrait display, and condition evaluation. |
| **Story Flow** | Story Flow depends on Dialogue | `start_dialogue(chapter_id, sequence_id)` / `dialogue_ended` signal / `dialogue_blocked` signal | Story Flow orchestrates when sequences run. Dialogue just plays them. |
| **Romance & Social** | Romance depends on Dialogue | `relationship_changed(companion_id, delta)` / `trust_changed(companion_id, delta)` signals | Romance & Social applies the state changes. Dialogue only emits. |
| **Save System** | Indirect via Story Flow | Story flags (set by Dialogue effects) are persisted by Story Flow, not Dialogue | Dialogue is stateless between sequences. All persistent state flows through Story Flow or Romance & Social. |
| **Scene Navigation** | Dialogue depends on Scene Navigation | Scene context (background, chapter) passed in by Story Flow when starting a sequence | Dialogue does not trigger scene transitions itself. |

## Formulas

### F1 — Typewriter Display Duration

The Dialogue system performs one calculation: the time a text node takes to fully animate if the player never taps to skip.

`T = L / CPS + P_total`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Character count | `L` | int | 1–280 | Resolved text length (after localization, after `{pause:N}` markers stripped) |
| Typewriter speed | `CPS` | float | 1–120 | Characters per second. Tuning knob, default 40. |
| Total pause time | `P_total` | float | 0.0–unbounded | Sum of all `{pause:N}` values in the node text |
| Display duration | `T` | float | 0.025–unbounded (sec) | Time to fully animate. Skip-tap terminates early. |

**Output range:** Minimum 0.025s (1 char at 40 CPS). No upper clamp — this is a display duration, not a game variable.

**Example:** 160 chars, one `{pause:0.5}`, CPS = 40 → `T = 160/40 + 0.5 = 4.5 seconds`

### Non-Formulas (Explicit)

- **Relationship/trust deltas** are flat integers from the data file. No weighting formula — the `delta` value is emitted verbatim. Accumulation logic lives in Romance & Social.
- **Condition evaluation** is boolean logic (comparisons against stored values). No math.
- **Portrait crossfade** and **pacing caps** are fixed constants, not calculated.

## Edge Cases

### Data Integrity

- **If a JSON file is missing or fails to parse**: Log error with `sequence_id`/`chapter_id`, emit `dialogue_blocked`, return to Idle. Fail-fast is safer than partial render.
- **If the `"start"` node is absent**: Log data error, emit `dialogue_blocked`. The entry point is a contract.
- **If `next`/`choice.next` references a non-existent node ID**: Debug builds raise a descriptive error. Release builds emit `dialogue_ended` and log warning.
- **If a node has both `choices` and `next`**: `choices` takes priority; `next` ignored with warning (Rule 1c).
- **If a node is unreachable from `"start"`**: Strip at load, log content warning. Does not block the sequence.
- **If `speaker_type` is `"companion"` but `speaker` doesn't match Companion Data**: Log data error, skip node, advance to `next`.
- **If a choice's `effects` array contains an unknown effect type**: Skip that effect, log warning. Remaining effects still execute.

### State Conflicts

- **If `start_dialogue()` is called while not in Idle**: Reject the call, log warning with both sequence IDs. Active sequence continues.
- **If a scene transition fires during Displaying or Choosing**: DialogueRunner receives `force_end`, emits `dialogue_ended`, clears UI. Unresolved effects are discarded.
- **If save is triggered during Resolving**: Flags already set are persisted; in-flight effects are not. Dialogue mid-sequence is not a valid save point.

### Choice Edge Cases

- **If `choices: []` (empty) and no `next` field**: Data error, log warning, emit `dialogue_ended`.
- **If ALL choices fail conditions**: Log content warning with node ID, emit `dialogue_ended`. Do not display empty choice panel.
- **If only insight choices exist on a node and none pass**: Same as all-fail — end sequence. Missing standard fallback is a data error.
- **If a cost choice has no consequence preview text**: Renders without the preview line. Log authoring warning. Not an error.
- **If >4 choices pass conditions**: Display first 4 in array order, log content warning.

### Text Edge Cases

- **If `text_key` resolves to empty string `""`**: Display empty text box, typewriter completes instantly, advance indicator appears. Log localization warning.
- **If `text_key` is missing from Localization**: Display raw key as fallback (e.g., `"CH1_ARTEMISA_01"`). Log localization error.
- **If text contains only `{pause:N}` markers and no visible characters**: Pauses execute, then typewriter completes on empty text. Valid authored beat.
- **If text exceeds 280 characters**: Truncate at nearest word boundary, append `[...]`, log content warning.
- **If `{pause:N}` value is outside 0.1–3.0**: Clamp to range. Log content warning.

### System Interaction Edge Cases

- **If Localization autoload is not ready**: Return raw key as fallback. Log error. Do not block.
- **If portrait image is missing at resolved path**: Display blank portrait area, log missing asset warning. Text and name still display.
- **If Romance & Social is not listening for signals**: Signals emit and go unhandled. No error. Fire-and-forget.

### Touch Input Edge Cases

- **If rapid taps during typewriter**: First tap completes text (consumed). Subsequent taps in same frame ignored. Next valid tap advances.
- **If tap during choice panel slide-in animation**: Buffered until animation completes, then processed. Do not process against half-visible targets.
- **If tap on portrait area**: No action. Portrait is not an advance target.
- **If long-press on a choice**: Treat as standard tap-up. No long-press behavior in MVP.
- **If tap during Resolving state**: Ignored. Effects must complete before next node.

## Dependencies

| System | Direction | Nature | Hard/Soft | Interface |
|--------|-----------|--------|-----------|-----------|
| **Localization** | Dialogue depends on this | All text resolution via `get_text(key, params)` | Hard (MVP) | `Localization.get_text()`. DialogueRunner delegates all string resolution — no internal cache. |
| **Companion Data** | Dialogue depends on this | Reads `display_name`, portrait paths, `met`, `romance_stage`, `trust` | Hard (MVP) | Dictionary lookup by companion ID. Used for speaker names, portraits, and condition evaluation. |
| **Story Flow** | Story Flow depends on this | Orchestrates when sequences run; receives `dialogue_ended`/`dialogue_blocked` signals | Hard (MVP) | `start_dialogue(chapter_id, sequence_id)` entry point. `dialogue_ended` / `dialogue_blocked` signals. |
| **Romance & Social** | Romance depends on this | Applies relationship/trust changes from dialogue choice effects | Hard (MVP) | `relationship_changed(companion_id, delta)` / `trust_changed(companion_id, delta)` signals. |
| **Save System** | Indirect via Story Flow | Story flags set by dialogue effects are persisted by Story Flow, not Dialogue | Soft | No direct interface. Dialogue is stateless between sequences. |
| **Scene Navigation** | Dialogue depends on this | Scene context (background) passed in by Story Flow | Soft | Dialogue does not trigger transitions. Background context is display-only. |
| **Camp** | Camp depends on this | Daily companion conversations use dialogue sequences | Soft (Vertical Slice) | Camp calls `start_dialogue()` for camp-specific sequences. |
| **Intimacy** | Intimacy depends on this | Intimacy scenes may include dialogue segments | Soft (Alpha) | Intimacy calls `start_dialogue()` for pre/post scene dialogue. |

**Bidirectional notes:**
- Localization GDD already lists Dialogue as a hard downstream dependency and notes the DialogueRunner migration requirement.
- Companion Data GDD lists Dialogue as a downstream system that reads profile + state.
- Story Flow GDD (not yet authored) must list "depends on Dialogue" and specify the signal contract.
- Romance & Social GDD (not yet authored) must list "depends on Dialogue" for relationship/trust signals.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `TYPEWRITER_CPS` | 40 | 20–80 | Text appears faster; less dramatic tension per line | Slower reveal; more suspense but risks impatience on mobile |
| `PORTRAIT_CROSSFADE_SEC` | 0.15 | 0.05–0.5 | Slower mood transitions; more noticeable | Snappier transitions; feels more responsive |
| `MAX_TEXT_LENGTH` | 280 | 140–400 | Longer lines; fewer nodes needed per scene but risk overflow | Shorter lines; more tapping but better mobile readability |
| `MAX_CHOICES_PER_NODE` | 4 | 2–4 | More options per branch (but 44px minimum limits this on 932px viewport) | Fewer options; simpler but less player agency |
| `MIN_CHOICE_HEIGHT_PX` | 44 | 44–64 | Larger touch targets; fewer choices fit | Minimum per accessibility; do not go below 44 |
| `PAUSE_MARKER_MIN` | 0.1 | 0.05–0.2 | Minimum pause is longer | Very short pauses allowed; risk of feeling glitchy |
| `PAUSE_MARKER_MAX` | 3.0 | 1.0–5.0 | Longer dramatic pauses possible | Caps pause duration; less dramatic range |
| `PACING_LINE_CAP` | 6 | 4–10 | More lines between interactions; risk of dialogue fatigue | Fewer lines; more interaction points but choppier flow |
| `PACING_CHOICE_CAP` | 12 | 8–16 | More lines between choice points | Tighter pacing; more frequent decisions |
| `HUD_PULSE_DURATION_SEC` | 0.5 | 0.2–1.0 | Longer relationship feedback glow | Shorter, subtler pulse |

**Cross-knob interactions:**
- `TYPEWRITER_CPS` and `MAX_TEXT_LENGTH` together determine max display time per node. At CPS=20, LENGTH=400: T = 20 seconds per line — too slow.
- `MAX_CHOICES_PER_NODE` and `MIN_CHOICE_HEIGHT_PX` together constrain how many choices physically fit. At 4 choices × 64px = 256px of the 932px viewport.
- `PACING_LINE_CAP` and `PACING_CHOICE_CAP` are authoring constraints, not runtime values. They're enforced in pre-release validation.

## Visual/Audio Requirements

### Visual Requirements

| Event | Visual Feedback | Timing | Priority |
|-------|----------------|--------|----------|
| **Typewriter animation** | Characters fade in over 2 frames (not hard-pop). Cream (#F5E6C8) text. No cursor glyph. | Per-character at CPS rate | MVP |
| **Text completion** | Gold (#D4A843) chevron ("›") pulses at bottom-right of text box (scale 1.0→1.15→1.0, 0.3s interval), then holds. | On typewriter complete | MVP |
| **Choice panel entrance** | Slides up from off-screen bottom, 0.25s ease-out cubic. Each choice tile staggers 0.05s apart. | On choices ready | MVP |
| **Choice panel exit** | Fades out in 0.15s, no slide. Dissolves rather than retreating — signals finality. | On choice selected | MVP |
| **Mood change crossfade** | Portrait alpha fades to 0 over 0.15s, new mood swaps, fades back to 1 over 0.15s. No positional shift — portrait stays anchored. | 0.3s total | MVP |
| **Portrait entrance** | Slides in from left edge 24px over 0.2s ease-out, simultaneously fading 0→1. Exit is reverse. | On speaker change | MVP |
| **HUD relationship pulse** | Relationship icon scales 1.0→1.12→1.0 over 0.4s with warm gold glow overlay (30% opacity). One pulse. | On sequence end (deferred feedback) | MVP |
| **Narrator text** | Centered, italic, cream. Text box background deepens to #1A1209 (darker than standard #2A1F14). No portrait, no speaker label. | When speaker_type = narrator | MVP |
| **Environment text** | Left-aligned, small icon (32×32) top-left of panel. Background uses muted desaturated gold (#6B5A2E) at 80% opacity. | When speaker_type = environment | MVP |
| **Cost choice preview** | Consequence text in smaller, muted cream beneath the choice label. Italic. | When tier = cost | MVP |

### Audio Requirements

| Event | Sound Description | Duration | Priority |
|-------|-------------------|----------|----------|
| **Text tick** | Soft dry consonant click, ~4ms, pitched ±1 semitone (random walk). Fires every 2 characters, not every one. | ~4ms per tick | MVP |
| **Choice panel open** | Soft upward whoosh. Warm, not sharp. | 0.2s | MVP |
| **Choice selection** | Single mid-frequency tap, bell-like timbre (gold-adjacent). | 0.1s decay | MVP |
| **Mood change** | Subtle tonal shimmer, tied to character identity (each companion has a distinct timbre family). | 0.2s | Vertical Slice |
| **Relationship pulse** | Low resonant tone, warm. Registers as meaningful, not decorative. | 0.3s | MVP |
| **Sequence start** | Ambient swell in. Diegetically distinct from music layer. | 1.5s | Vertical Slice |
| **Sequence end** | Ambient fade out. | 2.0s | Vertical Slice |

### Art Bible Principles Applied

- **Color hierarchy**: Cream text on dark brown (AAA contrast). Gold reserved for interactive affordances (chevron, choice highlights, pulse) — never decorative.
- **Composition**: Portrait occupies left third; text occupies right two-thirds. Nothing crosses this boundary.
- **Typography**: Single typeface, two weights: regular for dialogue, italic for narrator. Minimum 16sp for mobile legibility at 430px width.
- **Motion language**: All transitions under 0.3s. Ease-out on entrances (responsive); fade-out on exits (conclusive).

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| **Speaker name** | Top of dialogue panel, left-aligned above portrait | Per node | When speaker_type = companion or npc |
| **Character portrait** | Left third of screen, 200×400 logical px | Per node (crossfade on mood change) | When speaker_type = companion or npc |
| **Dialogue text** | Right two-thirds of screen, in text box panel | Per character (typewriter) | Always during Displaying state |
| **Advance indicator** | Bottom-right of text box, gold chevron | On typewriter complete | When waiting for tap (no choices) |
| **Choice panel** | Bottom of screen, vertically stacked buttons | On choice presentation | When node has visible choices |
| **Cost consequence text** | Below choice label, smaller italic cream | Per cost-tier choice | When choice tier = cost |
| **Narrator text box** | Full-width centered, darker background (#1A1209) | Per node | When speaker_type = narrator |
| **Environment text box** | Full-width, muted gold background (#6B5A2E), 32×32 icon | Per node | When speaker_type = environment |
| **Relationship pulse icon** | HUD layer, relationship icon position | On sequence end | When relationship/trust effects were applied |

**Layout zones** (portrait-mode 430×932):

| Zone | Region | Content |
|------|--------|---------|
| **Background** | Full screen | Scene background image (provided by Story Flow context) |
| **Portrait zone** | Left third (~143px wide), vertical center | Character portrait, anchored. Sacred — no UI chrome overlaps. |
| **Text zone** | Right two-thirds (~287px wide), lower half | Dialogue text box with speaker name above |
| **Choice zone** | Full width, bottom of screen | Stacked choice buttons (44px min height each) |

**Accessibility:**
- All text meets AAA contrast (cream on dark brown)
- Touch targets minimum 44×44px
- Screen reader support via AccessKit (Godot 4.5+): dialogue text announced, choices announced as list
- No color-only indicators — all feedback uses motion + color

> **📌 UX Flag — Dialogue**: This system has significant UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the dialogue screen before writing epics. Stories that reference dialogue UI should cite `design/ux/dialogue.md`, not this GDD directly.

## Acceptance Criteria

### Rule 1 — Script Data Format

- [ ] **AC-DLG-01** — **GIVEN** a valid dialogue JSON file with a `"start"` node, **WHEN** `DialogueRunner.start_dialogue(chapter_id, sequence_id)` is called, **THEN** the runner loads without error and sets `current_node_id = "start"`.

- [ ] **AC-DLG-02** — **GIVEN** a dialogue node with both a `choices` array (non-empty) and a `next` field, **WHEN** the node is displayed and the player advances, **THEN** the choice panel is presented (not direct advance via `next`), and a content warning is logged.

- [ ] **AC-DLG-03** — **GIVEN** a dialogue script with a node unreachable from `"start"` via any `next`/`choice.next` chain, **WHEN** the script is loaded, **THEN** that node is stripped from the working graph and a content warning is logged; the sequence loads and plays normally.

- [ ] **AC-DLG-04** — **GIVEN** a dialogue node whose `choice.next` references a node ID that does not exist in the script, **WHEN** the player selects that choice in a debug build, **THEN** a descriptive error is logged; in release, `dialogue_ended(sequence_id)` is emitted and the UI clears gracefully.

### Rule 2 — Turn Flow

- [ ] **AC-DLG-05** — **GIVEN** a valid dialogue sequence, **WHEN** `start_dialogue()` is called, **THEN** the state machine transitions Idle → Loading → Displaying in order; no UI element is visible during Loading.

- [ ] **AC-DLG-06** — **GIVEN** a dialogue sequence with root gate `requires_met: "artemisa"` and Artemisa's `met == false`, **WHEN** `start_dialogue()` is called, **THEN** `dialogue_blocked(sequence_id, reason)` is emitted, no dialogue UI is shown, and the runner returns to Idle.

- [ ] **AC-DLG-07** — **GIVEN** a node with no choices and `next: "some_node_id"`, **WHEN** the typewriter completes and the player taps, **THEN** the runner loads the node identified by `"some_node_id"` and re-enters the Displaying state.

- [ ] **AC-DLG-08** — **GIVEN** a node whose `next` value is `"END"`, **WHEN** the player advances past it, **THEN** `dialogue_ended(sequence_id)` is emitted, the dialogue UI clears, and the runner returns to Idle.

- [ ] **AC-DLG-09** — **GIVEN** a running dialogue sequence in Displaying state, **WHEN** `start_dialogue()` is called again with a different sequence, **THEN** the call is rejected, a warning is logged with both sequence IDs, and the active sequence continues uninterrupted.

### Rule 3 — Speaker Types

- [ ] **AC-DLG-10** — **GIVEN** a node with `speaker_type: "companion"` and `speaker: "hipolita"` with `mood: "angry"`, **WHEN** the node displays, **THEN** Hipolita's name (from `CompanionData.display_name`) appears in the speaker label, the portrait image loaded is `res://assets/images/companions/hipolita/hipolita_angry.png`, and the portrait is anchored in the left-third zone.

- [ ] **AC-DLG-11** — **GIVEN** a node with `speaker_type: "npc"` and `speaker: "priestess"` with `mood: "neutral"`, **WHEN** the node displays, **THEN** no companion state lookup is performed, the speaker name resolves via `Localization.get_text("COMP_PRIESTESS")`, and the portrait path used is `res://assets/images/npcs/priestess/priestess_neutral.png`.

- [ ] **AC-DLG-12** — **GIVEN** a node with `speaker_type: "narrator"`, **WHEN** the node displays, **THEN** no portrait renders, no speaker name label renders, text is centered and italic, and the text-box background uses color `#1A1209`.

- [ ] **AC-DLG-13** — **GIVEN** two consecutive companion nodes where the first has `mood: "neutral"` and the second has `mood: "happy"`, **WHEN** the runner transitions between them, **THEN** the portrait crossfades (alpha 1→0→1) over `PORTRAIT_CROSSFADE_SEC` (default 0.15s total), and text display for the second node does not wait for the crossfade to complete.

### Rule 4 — Choice Mechanics

- [ ] **AC-DLG-14** — **GIVEN** a choice node with one `standard`, one `insight` (flag-gated, flag not set), and one `cost` tier choice, **WHEN** the choice panel renders, **THEN** only the `standard` and `cost` choices are visible; the `insight` choice is absent entirely; the `cost` choice displays its consequence preview text beneath the label in smaller italic cream text.

- [ ] **AC-DLG-15** — **GIVEN** a choice node where the `insight` choice has its gating flag set to true, **WHEN** the choice panel renders, **THEN** the insight choice appears without any special visual marker distinguishing it from the standard choices.

- [ ] **AC-DLG-16** — **GIVEN** a choice node where a `trust_min` condition references `companion: "artemisa", value: 30` and Artemisa's current trust is 29, **WHEN** the panel renders, **THEN** that choice is not visible; **WHEN** trust is 30 or above, **THEN** that choice is visible — confirming conditions are evaluated at render time against live state.

- [ ] **AC-DLG-17** — **GIVEN** a choice node with 5 choices that all pass their conditions, **WHEN** the panel renders, **THEN** only the first 4 (in array order) are displayed, and a content warning is logged identifying the node ID and the fifth choice that was dropped.

### Rule 5 — Effects

- [ ] **AC-DLG-18** — **GIVEN** a choice whose `effects` array contains `[{type: "relationship", companion: "artemisa", delta: 5}, {type: "flag_set", flag: "artemisa_trust_moment_1"}]`, **WHEN** the player selects that choice, **THEN** the signal `relationship_changed("artemisa", 5)` is emitted, followed by the story flag `"artemisa_trust_moment_1"` being set, in that array order, before the runner advances to the next node.

- [ ] **AC-DLG-19** — **GIVEN** a choice with a `mood_set` effect targeting a companion, **WHEN** the effect executes, **THEN** the companion portrait crossfades to the new mood immediately within the same beat (before the next node's text begins rendering).

- [ ] **AC-DLG-20** — **GIVEN** a choice whose `effects` array includes an unknown/unsupported effect type, **WHEN** the runner encounters it, **THEN** that individual effect is skipped with a warning logged, all preceding and following effects in the array still execute, and the sequence continues normally.

- [ ] **AC-DLG-21** — **GIVEN** a sequence where a `relationship_changed` signal was emitted, **WHEN** the sequence ends and the UI transitions out, **THEN** the HUD relationship icon pulses (scale 1.0→1.12→1.0 over 0.4s with gold glow) exactly once; no numeric delta is displayed inline during the scene.

### Rule 6 / Formula F1 — Text Display

- [ ] **AC-DLG-22** — **GIVEN** a node with resolved text of 160 characters and one `{pause:0.5}` marker at CPS=40, **WHEN** the typewriter animates without any player tap, **THEN** it completes in 4.5 seconds (T = 160/40 + 0.5 = 4.5s), the `{pause:N}` token does not appear in the rendered text, and the gold chevron advance indicator appears on completion.

- [ ] **AC-DLG-23** — **GIVEN** a typewriter animation in progress, **WHEN** the player taps the dialogue area, **THEN** the full resolved text renders instantly (skip), no advance occurs on that same tap, and the advance indicator appears; a subsequent tap then advances to the next node.

- [ ] **AC-DLG-24** — **GIVEN** a node whose resolved text (after localization and marker stripping) exceeds 280 characters, **WHEN** the node loads, **THEN** text is truncated at the nearest word boundary at or before 280 characters with `[...]` appended, a content warning is logged, and no text beyond the truncation point is displayed.

- [ ] **AC-DLG-25** — **GIVEN** a node containing `{pause:0.05}` (below minimum), **WHEN** the typewriter processes it, **THEN** the pause is clamped to 0.1s, a content warning is logged, and the rendered text does not contain the marker string.

### Rules 7–8 — Gating and Pacing

- [ ] **AC-DLG-26** — **GIVEN** a dialogue script with root gate `requires_romance_stage: { companion: "nyx", min: 2 }` and Nyx's current `romance_stage` is 1, **WHEN** `start_dialogue()` is called, **THEN** no UI element appears, `dialogue_blocked(sequence_id, reason)` is emitted, and Story Flow (not the Dialogue system) is responsible for determining the fallback path.

- [ ] **AC-DLG-27** — **GIVEN** a dialogue script with root gate `requires_flag: "chapter_2_unlocked"` and that flag is not set, **WHEN** `start_dialogue()` is called, **THEN** the sequence is blocked invisibly — no "locked" message is displayed to the player.

- [ ] **AC-DLG-28** — **GIVEN** a pre-release validation run against a dialogue script with 7 consecutive choice-free node advances, **WHEN** the pacing validator checks the script, **THEN** it flags a violation of the 6-line cap and reports the node ID where the cap is exceeded; the game itself does not enforce this at runtime.

### Edge Cases

- [ ] **AC-DLG-29** — **GIVEN** a call to `start_dialogue("chapter_1", "missing_sequence")` where no corresponding JSON file exists, **WHEN** the runner attempts to load it, **THEN** an error is logged with both `chapter_id` and `sequence_id`, `dialogue_blocked(sequence_id, "file_not_found")` is emitted, and the runner returns to Idle without displaying any UI.

- [ ] **AC-DLG-30** — **GIVEN** a valid dialogue JSON where the `"start"` node key is absent from the `nodes` dictionary, **WHEN** the script loads, **THEN** a data error is logged, `dialogue_blocked` is emitted, and the runner returns to Idle.

- [ ] **AC-DLG-31** — **GIVEN** a choice node where ALL choices have conditions that fail, **WHEN** the runner reaches that node, **THEN** the choice panel does not appear (no empty panel), a content warning is logged with the node ID, and `dialogue_ended(sequence_id)` is emitted.

- [ ] **AC-DLG-32** — **GIVEN** rapid multiple taps sent within a single frame during typewriter animation, **WHEN** the runner processes input, **THEN** only the first tap is consumed (completing the typewriter), all subsequent taps in the same frame are ignored, and no unintended advance past the completed-text state occurs.

- [ ] **AC-DLG-33** — **GIVEN** a tap registered on the portrait zone while a dialogue node is displaying, **WHEN** the runner processes the tap, **THEN** no action is taken (portrait is not an advance target) and the typewriter state is unchanged.

### Performance

- [ ] **AC-DLG-34** — **GIVEN** a dialogue sequence load call on a target mobile device (Android, minimum spec), **WHEN** `start_dialogue()` is called, **THEN** the transition from Idle to first character rendered (typewriter start) completes within 100ms; typewriter animation runs at a steady rate with no frame-skips measured over a 5-second window at 60fps target.

### Cross-System

- [ ] **AC-DLG-35** — **GIVEN** a dialogue node with `text_key: "CH1_ARTEMISA_01"` and a matching entry in the active locale's string table, **WHEN** the node renders, **THEN** `Localization.get_text("CH1_ARTEMISA_01")` is the sole text resolution call — no string is hardcoded in DialogueRunner or in the node data.

- [ ] **AC-DLG-36** — **GIVEN** a dialogue node with `text_key: "CH1_MISSING_KEY"` that is absent from the active locale's string table, **WHEN** the node renders, **THEN** the raw key `"CH1_MISSING_KEY"` is displayed as fallback text, a localization error is logged, and the sequence continues normally without crashing.

- [ ] **AC-DLG-37** — **GIVEN** a companion node for `speaker: "atenea"` that requires `CompanionData` for `display_name` and portrait path, **WHEN** the node displays, **THEN** the speaker name matches `CompanionData.get_profile("atenea").display_name` and the portrait path is constructed from `CompanionData`'s portrait convention — DialogueRunner holds no hardcoded companion strings.

- [ ] **AC-DLG-38** — **GIVEN** a choice that triggers `effects: [{type: "trust", companion: "hipolita", delta: 10}]`, **WHEN** the player selects the choice, **THEN** `trust_changed("hipolita", 10)` is emitted as a signal; DialogueRunner does not directly write to `CompanionData` state — verification: inspecting DialogueRunner's code should show no direct mutation of `companion.trust`.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| All text resolution via `get_text(key, params)` | `design/gdd/localization.md` | `get_text()` API contract (Rule 3) | Data dependency |
| DialogueRunner migration from internal cache | `design/gdd/localization.md` | DialogueRunner migration note (Interactions section) | Ownership handoff |
| `locale_changed` signal — in-progress line stays old language | `design/gdd/localization.md` | Edge case: mid-display locale switch | Rule dependency |
| Companion `display_name`, portrait paths, mood variants | `design/gdd/companion-data.md` | Companion profile schema (Core Rules) | Data dependency |
| `met` flag gates companion dialogue availability | `design/gdd/companion-data.md` | Companion state record `met` field | State trigger |
| `romance_stage` gates dialogue branches and sequences | `design/gdd/companion-data.md` | Romance stage derivation formula | Rule dependency |
| `trust` value gates choice conditions | `design/gdd/companion-data.md` | Companion state record `trust` field | Data dependency |
| Portrait fallback chain (missing mood → neutral → silhouette) | `design/gdd/companion-data.md` | Portrait system edge case | Rule dependency |
| `relationship_changed` / `trust_changed` signals consumed by Romance | (Romance & Social GDD — not yet authored) | Signal contract for stat application | Ownership handoff |
| Story Flow orchestrates dialogue sequences | (Story Flow GDD — not yet authored) | `start_dialogue()` entry point, `dialogue_ended`/`dialogue_blocked` signals | State trigger |
| Combat score pipeline reads from captain stats | `design/gdd/poker-combat.md` | `captain_stat_bonus` formula | Data dependency (indirect — Dialogue affects relationship which affects blessings which affects combat) |

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the priestess have a simplified companion profile for dialogue, or remain entirely separate? | Game Designer | Before Architecture phase | Currently resolved in Rule 3b: priestess is NPC type with own portrait set, no companion state. Confirm with Companion Data GDD owner. |
| Should DialogueRunner migration create a thin wrapper or remove `get_text` entirely? | Technical Director | Before Architecture phase | Pending — depends on whether other systems call `DialogueRunner.get_text()` directly. |
| Should dialogue scripts support compound conditions (AND/OR logic on multiple conditions per choice)? | Game Designer | Before Story Flow GDD | MVP uses single conditions. Compound logic would add complexity — assess need during Chapter 1 content authoring. |
| Should a dialogue history/backlog feature be included? | Game Designer | Before Vertical Slice | Excluded from MVP. FoldableContainer (Godot 4.5+) could serve this. Assess after MVP playtesting. |
| Should text tick SFX be per-character (pitched) or per-companion (unique voice blip)? | Audio Director | Before Audio GDD | Current spec: per-character pitched tick every 2 chars. Per-companion voice blips would require 5 SFX sets. |
