# Deck Management

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-09
> **Implements Pillar**: Pillar 1 — Balatro-Inspired Poker Combat; Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Deck Management is the pre-combat configuration system that lets the player choose their active captain companion before each encounter. In Story Mode it presents the standard clean 52-card deck (with suit-element mapping and companion signature cards) as read-only context; in Abyss Mode it becomes a full editor where cards can be added, removed, and enhanced. The Deck Viewer screen is the bridge between the companion-romance layer and the poker-combat layer.

> **Quick reference** -- Layer: `Core` · Priority: `Vertical Slice` · Key deps: `Companion Data, Poker Combat, Save System, Scene Navigation`

---

## Overview

Deck Management encompasses two tightly related concerns: (1) captain selection -- choosing which companion accompanies the player into the next combat encounter -- and (2) the Deck Viewer screen -- a pre-combat UI that displays the current 52-card deck, highlights signature cards, and summarises the active captain's stat contribution. In Story Mode the deck is always a clean, unmodified 52-card set and the viewer is read-only; the only meaningful decision is which captain to bring. In Abyss Mode the same screen expands to support card removal, card addition (jokers, tarot-type cards), and card enhancement (Foil, Holographic, Polychrome), but those features are out of scope for this document. This GDD defines the Story Mode behaviour and the data contract the Abyss Mode extension will build on.

---

## Player Fantasy

Choosing your captain is choosing which goddess fights beside you. Each companion brings a distinct element, a distinct card embedded in your deck, and a distinct arithmetic bonus to every hand you play. When Hipolita stands at your side, fire floods the Hearts suit and her raw strength pads every chip count; when Atenea takes her place, lightning crackles through Spades and her keen mind bends multipliers upward. The Deck Viewer makes this visible: you can scroll through all 52 cards, find your captain's signature card -- the King of Clubs glowing subtly for Artemis, the Ace of Hearts burning for Hipolita -- and feel the weight of the bond you've built. The act of choosing is itself a moment of connection. You are not picking a stat bonus; you are deciding who you trust today.

*Pillar 1: "Combat is poker hand evaluation with chips x mult scoring. Every card play is a strategic decision."*
*Pillar 3: "Romance is not a cosmetic layer -- it directly enhances combat via divine blessings."*

---

## Detailed Design

### Core Rules

1. **Deck Composition (Story Mode).** The deck is always a standard 52-card set: 4 suits x 13 values (2-14, Ace=14). No jokers, no wildcards, no duplicate cards. Suits map to elements: Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning. The deck composition cannot be modified in Story Mode -- any "edit deck" affordance is hidden or disabled.

2. **Signature Cards.** Each companion has one signature card defined by their suit (element) and card_value. Signature cards are cosmetically tagged in the Deck Viewer (companion portrait overlay, element glow) but play identically to any untagged card in combat. A signature card is always present in the deck regardless of which captain is active -- it is a property of the deck, not of captain selection.

   | Companion | Element | Suit | Card Value | Signature Card |
   |-----------|---------|------|-----------|----------------|
   | Artemis | Earth | Clubs | 13 | King of Clubs |
   | Hipolita | Fire | Hearts | 14 | Ace of Hearts |
   | Atenea | Lightning | Spades | 14 | Ace of Spades |
   | Nyx | Water | Diamonds | 14 | Ace of Diamonds |

3. **Captain Selection Flow.** Before every combat encounter the game presents the captain selection step. The player selects exactly one companion to serve as captain. Only companions whose `met` flag is `true` in CompanionState are available for selection. The first companion met in the story is always available as a fallback; the game can never enter combat with no captain.

   - Selection is confirmed explicitly (tap to highlight, tap Confirm button to lock in).
   - Cancelling returns the player to the previous screen without entering combat.
   - Once combat begins, the captain is locked for the duration of the encounter. No mid-combat captain switching.

4. **Captain Stat Bonus.** The active captain contributes a flat chip bonus and a multiplier bonus to every hand scored in the encounter. These values are derived from the captain's STR and INT stats (see Formulas). Blessings are applied separately by the Divine Blessings system and are not in scope here.

5. **Deck Viewer Screen.** After (or during) captain selection, the player may open the Deck Viewer. The viewer displays all 52 cards sorted by suit then value (Clubs 2-A, Diamonds 2-A, Hearts 2-A, Spades 2-A). Signature cards are visually distinguished. The viewer shows the active captain's portrait, their element badge, and their derived chip and mult bonuses. In Story Mode, no editing controls are shown. The viewer is dismissible at any time.

6. **Pre-Combat Handoff.** When the player confirms captain and closes/skips the Deck Viewer, Deck Management emits a `combat_configured` signal carrying: `captain_id` (String), `captain_chip_bonus` (int), `captain_mult_bonus` (float), `deck` (Array[CardData] -- 52 shuffled cards). Poker Combat reads this signal to initialise the encounter. The deck array is shuffled by Deck Management at handoff, not by Poker Combat.

7. **Abyss Mode Extension Contract.** In Abyss Mode, the same screen is extended with edit controls. Deck Management exposes the deck as a mutable Array[CardData] and provides add/remove/enhance mutation methods. Abyss Mode calls these methods after captain selection and before emitting `combat_configured`. This GDD does not specify Abyss mutation rules -- they belong to the Abyss Mode GDD.

---

### States and Transitions

```
[Previous Screen]
      |
      v
[CAPTAIN_SELECT] <----------- cancel -----------+
      |                                          |
      | tap companion                            |
      v                                          |
[COMPANION_HIGHLIGHTED]                          |
      |                                          |
      | tap Confirm                              |
      v                                          |
[CAPTAIN_CONFIRMED] -----> open viewer -----> [DECK_VIEWER]
      |                                          |
      | (Story Mode: no edits)                   | dismiss
      |  <---------------------------------------+
      |
      | proceed to combat
      v
[HANDOFF_EMITTED] --> Poker Combat initialises encounter
```

**State descriptions:**

| State | Description | Allowed Actions |
|-------|-------------|-----------------|
| `CAPTAIN_SELECT` | Companion grid shown; no captain confirmed | Tap companion to highlight; cancel to go back |
| `COMPANION_HIGHLIGHTED` | One companion highlighted; Confirm button active | Tap Confirm; tap different companion; cancel |
| `CAPTAIN_CONFIRMED` | Captain locked; Confirm button becomes "Battle" | Open Deck Viewer; tap "Battle" to proceed |
| `DECK_VIEWER` | Full-screen card grid; read-only in Story Mode | Dismiss/close |
| `HANDOFF_EMITTED` | Signal fired; screen transitions to combat | None (transition in progress) |

---

### System Interactions

| System | Direction | What Deck Management needs | What it provides |
|--------|-----------|---------------------------|-----------------|
| Companion Data | Read | `met` flag, `name`, `element`, `STR`, `INT`, `card_value`, portrait path for each companion | Nothing -- read-only consumer |
| Poker Combat | Write (signal) | Nothing | `combat_configured` signal: `captain_id`, `captain_chip_bonus`, `captain_mult_bonus`, `deck` (Array[CardData], shuffled) |
| Save System | Read/Write | Read: last-used `captain_id` to pre-select on reopen; Write: save chosen `captain_id` after confirmation | Nothing -- state persistence only |
| Scene Navigation | Read | Transition source (which screen preceded this one); cancel destination | Nothing |
| Abyss Mode | Write (extension) | Nothing at Story Mode scope | Mutable `deck` Array and mutation API (add/remove/enhance card) for Abyss to call before handoff |

---

## Formulas

Deck Management does not own any novel formulas. It computes the captain stat bonuses as defined in the Poker Combat GDD and passes them to Poker Combat via the handoff signal.

**Captain Chip Bonus**

```
captain_chip_bonus = floor(captain.STR * 0.5)
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `captain.STR` | int | [1, 30] | Captain's base Strength stat from Companion Data |
| `captain_chip_bonus` | int | [0, 15] | Flat chips added to every hand's chip total |

*Example:* Hipolita (STR=20): `floor(20 * 0.5) = 10` chips per hand.
*Example:* Atenea (STR=13): `floor(13 * 0.5) = 6` chips per hand.

**Captain Mult Bonus**

```
captain_mult_bonus = 1.0 + (captain.INT * 0.025)
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `captain.INT` | int | [1, 30] | Captain's base Intelligence stat from Companion Data |
| `captain_mult_bonus` | float | [1.025, 1.75] | Multiplier applied once to each hand's mult total |

*Example:* Atenea (INT=19): `1.0 + (19 * 0.025) = 1.475x` per hand.
*Example:* Hipolita (INT=9): `1.0 + (9 * 0.025) = 1.225x` per hand.

**Companion Summary Table (Story Mode)**

| Companion | STR | INT | Chip Bonus | Mult Bonus |
|-----------|-----|-----|-----------|-----------|
| Artemis | 17 | 13 | +8 chips | 1.325x |
| Hipolita | 20 | 9 | +10 chips | 1.225x |
| Atenea | 13 | 19 | +6 chips | 1.475x |
| Nyx | 18 | 19 | +9 chips | 1.475x |

*Note:* Nyx has the highest combined bonus at default stats. This is intentional -- she is the hardest companion to unlock narratively.

**Deck Build**

No formula; the deck is constructed as a deterministic set of 52 CardData objects (4 suits x 13 values), then shuffled using Godot's `randomize()` + `shuffle()` before handoff. Shuffling happens once per encounter setup, not on the Deck Viewer open.

---

## Edge Cases

1. **No captain ever selected (first launch).** If `last_captain_id` is null in SaveData and no companion is highlighted, the Confirm button remains disabled. The player cannot proceed to combat without selecting a captain. The UI shows a tooltip: "Choose a companion to fight beside you."

2. **All companions locked (met=false).** Impossible in normal Story Flow -- Artemis is always met before the first combat encounter. If this state is reached (corrupted save, debug skip), the system falls back to Artemis and logs a warning. Artemis's `met` flag is set to `true` during save initialisation and cannot be false at combat entry.

3. **Only one companion met.** The captain select grid shows all four companions; unmet companions are visually greyed out and non-tappable. The player must choose from the available (met) companions, which may be only one. The Confirm button activates on tap of that companion.

4. **Deck Viewer opened before captain confirmed.** The Deck Viewer may be opened from the `CAPTAIN_SELECT` or `COMPANION_HIGHLIGHTED` state (via a "View Deck" button). In this case it shows the deck with no captain stats displayed (or the previously confirmed captain's stats if one exists from a prior encounter). The captain bonus panel shows "--" until a captain is confirmed.

5. **Player cancels after opening Deck Viewer.** Dismissing the Deck Viewer returns to `CAPTAIN_CONFIRMED` (or `CAPTAIN_SELECT` if no captain was confirmed). No state is lost. The deck is not re-shuffled on Deck Viewer open/close -- shuffle only happens at handoff.

6. **Signature card collision (three Aces).** Hipolita, Atenea, and Nyx all have `card_value=14` (Ace). Their signature cards are Ace of Hearts, Ace of Spades, and Ace of Diamonds respectively -- three distinct cards with three distinct suits. No collision. Artemis's signature is King of Clubs (value 13). All four signature cards are unique by suit+value combination.

7. **Captain stat values at boundaries.** STR=1 yields `floor(0.5) = 0` chip bonus (valid, not negative). INT=1 yields `1.025x` (valid). STR=30 yields `15` chip bonus; INT=30 yields `1.75x`. No formula produces negative or zero-mult values within the defined stat range [1, 30].

8. **Combat launched from Abyss Mode with Story Mode deck.** This cannot happen -- Abyss Mode sets a mode flag before opening the Deck Management screen. The screen reads this flag on init to determine whether to show editing controls. If the flag is somehow absent, the system defaults to Story Mode (read-only, clean deck). This is the safe fallback.

9. **Save fails during captain confirmation.** Captain ID is persisted to SaveData at confirmation. If the write fails (disk full, platform error), the captain ID is still held in memory for this session and combat proceeds normally. The save error is surfaced to the Save System's error handler, not to Deck Management's UI.

10. **Player force-quits during handoff.** If the game is killed between `combat_configured` signal emission and Poker Combat's encounter initialisation, the save system does not yet have a "combat in progress" flag written. On reload, the game returns to the screen before captain selection. No partially-initialised combat state is possible because handoff is a single-frame signal, not a multi-step async process.

---

## Dependencies

| System | Direction | Contract |
|--------|-----------|----------|
| **Companion Data** | Deck Management reads | Static: `STR`, `INT`, `element`, `card_value`, portrait path. Mutable: `met` flag. Deck Management never writes to Companion Data. |
| **Poker Combat** | Deck Management writes (signal) | Poker Combat subscribes to `combat_configured`. It expects: `captain_id: String`, `captain_chip_bonus: int`, `captain_mult_bonus: float`, `deck: Array[CardData]` (52 elements, shuffled). Poker Combat is blocked from initialising without this signal. |
| **Save System** | Bidirectional | Deck Management reads `last_captain_id` on screen open; writes `last_captain_id` on captain confirmation. Uses the Save System's standard read/write API -- no custom save format. |
| **Scene Navigation** | Deck Management reads | Needs to know the previous screen (to handle cancel) and the target scene (combat). Calls `SceneManager.change_scene(SceneId.COMBAT, context)` on handoff. |
| **Abyss Mode** | Abyss Mode calls into Deck Management | Deck Management exposes: `get_deck() -> Array[CardData]`, `remove_card(card: CardData)`, `add_card(card: CardData)`, `enhance_card(card: CardData, enhancement: Enhancement)`. These are no-ops or warnings in Story Mode. |

**Bidirectional note:** Poker Combat GDD references `captain_chip_bonus` and `captain_mult_bonus` as inputs from Deck Management. Companion Data GDD lists Deck Management as a downstream consumer. Save System GDD lists `last_captain_id` as a persisted field.

---

## Tuning Knobs

All tuning knobs live in `assets/data/deck_management_config.tres` (or equivalent Godot Resource). No values are hardcoded.

| Knob | Category | Default | Safe Range | Effect |
|------|----------|---------|-----------|--------|
| `captain_str_chip_multiplier` | Curve | 0.5 | [0.25, 1.0] | *Owned by Poker Combat — mirrored here for reference.* Scales how much STR converts to chip bonus. |
| `captain_int_mult_base` | Curve | 1.0 | [1.0, 1.5] | *Owned by Poker Combat — mirrored here for reference.* Base mult before INT scaling. |
| `captain_int_mult_per_point` | Curve | 0.025 | [0.01, 0.05] | *Owned by Poker Combat — mirrored here for reference.* Per-INT-point mult contribution. |
| `deck_sort_order` | Feel | `suit_then_value` | `suit_then_value`, `value_then_suit`, `random` | Order in which cards appear in Deck Viewer. |
| `signature_card_glow_intensity` | Feel | 0.8 | [0.0, 1.0] | Visual prominence of the signature card highlight in the Deck Viewer. 0.0 = no highlight. |
| `last_captain_persist` | Gate | `true` | `true`, `false` | Whether the previously chosen captain is pre-selected on next Deck Management open. Set false to always require explicit selection (higher friction, more deliberate choice). |

---

## Acceptance Criteria

All criteria follow GIVEN-WHEN-THEN. Criteria tagged [FUNCTIONAL] are automatable; [EXPERIENTIAL] require playtest sign-off.

**Captain Selection**

1. [FUNCTIONAL] GIVEN a new save with only Artemis met, WHEN the captain selection screen opens, THEN only Artemis's portrait is tappable; Hipolita, Atenea, and Nyx are visually greyed and do not respond to tap input.

2. [FUNCTIONAL] GIVEN no captain is highlighted, WHEN the player views the captain select screen, THEN the Confirm button is disabled and cannot be tapped.

3. [FUNCTIONAL] GIVEN Hipolita is tapped on the captain select screen, WHEN the player taps Confirm, THEN `captain_id = "hipolita"` is recorded in SaveData and the system transitions to `CAPTAIN_CONFIRMED` state.

4. [FUNCTIONAL] GIVEN the player is in `CAPTAIN_CONFIRMED` state, WHEN they tap "Battle", THEN `combat_configured` is emitted with `captain_id`, `captain_chip_bonus`, `captain_mult_bonus`, and a shuffled 52-card `deck` array.

5. [FUNCTIONAL] GIVEN Atenea (INT=19) is the active captain, WHEN `combat_configured` is emitted, THEN `captain_mult_bonus = 1.475` (within float tolerance of 0.001).

6. [FUNCTIONAL] GIVEN Hipolita (STR=20) is the active captain, WHEN `combat_configured` is emitted, THEN `captain_chip_bonus = 10`.

7. [FUNCTIONAL] GIVEN the player taps cancel on the captain selection screen, WHEN they confirm the cancel, THEN the system navigates to the previous screen and `combat_configured` is NOT emitted.

**Deck Viewer**

8. [FUNCTIONAL] GIVEN any game state in Story Mode, WHEN the Deck Viewer is opened, THEN it displays exactly 52 distinct card entries (no duplicates, no missing cards).

9. [FUNCTIONAL] GIVEN Artemis is the active captain, WHEN the Deck Viewer is open, THEN the King of Clubs card entry has Artemis's portrait overlay and an Earth-element glow; no other card has an overlay.

10. [FUNCTIONAL] GIVEN the Deck Viewer is open in Story Mode, WHEN the player looks for edit controls (add card, remove card, enhance card), THEN no such controls are visible or accessible.

11. [FUNCTIONAL] GIVEN the Deck Viewer is dismissed, WHEN the player returns to the captain confirmation screen, THEN the previously confirmed captain is still selected (no state reset).

**Deck Integrity**

12. [FUNCTIONAL] GIVEN `combat_configured` is emitted, WHEN Poker Combat receives the `deck` array, THEN the array contains exactly 52 CardData objects with no duplicate suit+value combinations.

13. [FUNCTIONAL] GIVEN `combat_configured` is emitted twice in the same session (two consecutive combats), WHEN both deck arrays are inspected, THEN their card orderings differ with probability >= 0.99 (shuffle is non-deterministic per encounter).

14. [FUNCTIONAL] GIVEN a save file where `last_captain_id = "nyx"`, WHEN the captain selection screen opens, THEN Nyx's portrait is pre-highlighted (but not yet confirmed -- Confirm button must still be tapped).

**Edge Cases**

15. [FUNCTIONAL] GIVEN Hipolita, Atenea, and Nyx all have `card_value=14`, WHEN the Deck Viewer is open with any of them as captain, THEN only their specific suit's Ace card shows the captain's portrait overlay; the other two Aces show no overlay.

16. [FUNCTIONAL] GIVEN STR=1 for a hypothetical companion, WHEN `captain_chip_bonus` is computed, THEN the result is 0 (floor(0.5) = 0) and no negative chip value is passed to Poker Combat.

17. [EXPERIENTIAL] GIVEN the player selects a different captain than they used last session, WHEN they enter combat, THEN playtest observers report the captain switch felt intentional and consequential -- the stat summary panel communicated the tradeoff clearly enough to inform the choice.

18. [EXPERIENTIAL] GIVEN the Deck Viewer is open with a captain confirmed, WHEN the player locates their captain's signature card, THEN playtest observers report finding the card within 10 seconds without instruction (signature card visual is distinctive enough to be discovered without a tutorial).

---

## Cross-References

| Document | Relationship |
|----------|-------------|
| `design/gdd/poker-combat.md` | Consumes `captain_chip_bonus` and `captain_mult_bonus` in the scoring pipeline (Section: Scoring Pipeline). Defines the `combat_configured` signal consumer. |
| `design/gdd/companion-data.md` | Authoritative source for STR, INT, element, card_value, and `met` flag. Captain stat formulas derive from values defined there. |
| `design/gdd/save-system.md` | Defines the save schema; `last_captain_id` must be added as a persisted field in the save schema. |
| `design/gdd/scene-navigation.md` | SceneManager handles transition from captain select screen to combat scene. |
| `design/gdd/abyss-mode.md` (not yet written) | Will extend Deck Management with card mutation APIs. Must respect the Story Mode / Abyss Mode flag contract defined in Core Rule 8 and the mutation API contract defined in Dependencies. |

---

## Open Questions

1. **Deck Viewer access point.** Should the Deck Viewer be accessible only during captain selection (pre-combat), or also from the Camp screen at any time? Persistent camp access adds discovery value (players can inspect deck composition between fights) but adds scope to the Camp GDD. Recommend: Camp-accessible as a read-only shortcut -- resolve when authoring the Camp GDD.

2. **Captain persistence across chapters.** Currently `last_captain_id` is a single global value. If the game introduces chapter-specific recommended captains (e.g., a Fire-heavy chapter favouring Hipolita), should the game suggest a captain rather than silently pre-selecting the last used? Recommend: suggestion UI as a post-MVP enhancement -- design if Story Flow data supports element-affinity hints.

3. **Locked companion display.** Currently unmet companions are greyed out. Should they show a silhouette with a "???" label (mystery, builds curiosity) or a locked icon with a story-context hint ("Meet her in Chapter 2")? The first approach serves Explorer players; the second serves Achievers. Recommend: silhouette + "???" for MVP to preserve story mystery -- revisit with narrative-director.

4. **Signature card cosmetic ownership.** If the player has not yet met a companion, does their signature card still glow in the Deck Viewer? Currently yes -- the card is in the deck regardless of `met` status. But revealing "Ace of Diamonds" glows as a companion card before Nyx is met could be a spoiler or a tantalising mystery. Resolve with narrative-director before Deck Viewer implementation.
