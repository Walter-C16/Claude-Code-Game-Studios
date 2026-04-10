# Divine Blessings

> **Status**: In Design
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-09
> **Implements Pillar**: Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Divine Blessings is the 20 unique passive buffs (5 per companion goddess) that inject bonus chips and multipliers into the poker combat scoring pipeline, gated by romance stage progression. It is the mechanical bridge between Romance & Social and Poker Combat -- the system that makes Pillar 3's promise real. Each companion's 5 blessings form a coherent combat kit reflecting her personality and element, creating distinct strategic identities that reward diverse romantic investment.

> **Quick reference** -- Layer: `Feature` · Priority: `Vertical Slice` · Key deps: `Romance & Social, Poker Combat`

## Overview

Divine Blessings converts romantic investment into combat power. Each of the four companion goddesses has 5 unique blessings that modify the poker scoring pipeline when she serves as combat captain. Blessings unlock progressively as romance stage advances (1 at stage 1, 1 at stage 2, 2 at stage 3, 1 at stage 4) and inject `blessing_chips` (additive) and `blessing_mult` (additive) into the scoring formula alongside existing base hand values, captain bonuses, and social buffs. Each blessing is either always-on or triggered by a hand-specific condition (suit composition, hand rank, card count, combat state). The four companions offer distinct strategic kits: Artemisa rewards patient, full-hand Earth builds; Hipolita favors aggressive, chip-heavy opening strikes; Atenea delivers precision mult through calculated plays; and Nyx compounds across all vectors as the deepest romantic investment. No companion dominates both chips and mult -- strategic diversity is enforced by asymmetric kit design.

## Player Fantasy

**"Love Made Manifest"**

In most games, romance exists in a separate lane from combat -- you talk, you feel, you go back to fighting alone. In Dark Olympus, love literally reshapes the rules of combat. When a blessing unlocks, the player should feel: "What we have together changes the world itself." When blessings turn a losing hand into a winner, the player doesn't think "my stats are better" -- they think "this relationship matters, and the game proves it."

The unlock moment is a revelation, not a reward screen. Artemisa's patience becomes your endurance. Hipolita's fury becomes your opening strike. Atenea's precision becomes your calculated play. Nyx's depth becomes your inevitability. Each blessing is not a buff icon -- it is proof that the relationship is real and has weight in the world.

The fantasy moves from "I'm alone against impossible odds" to "I carry the power of someone who chose me." Romance isn't decorative. It is load-bearing. Together, you rewrite fate.

## Detailed Design

### Core Rules

**Rule 1 -- Captain Lock.** Divine Blessings are tied to the active captain companion. The captain is locked when combat begins (via Deck Management). Only the captain's blessings contribute `blessing_chips` and `blessing_mult` to the scoring pipeline. Other companions' blessings are entirely inactive.

**Rule 2 -- Slot Availability by Romance Stage.** Each companion has 5 blessing slots numbered 1-5:

| Stage | Label | Slots Available |
|---|---|---|
| 0 | Stranger | 0 (no blessings) |
| 1 | Acquaintance | Slot 1 |
| 2 | Friend | Slots 1-2 |
| 3 | Close | Slots 1-4 |
| 4 | Devoted | Slots 1-5 |

Stage 3 unlocks two slots simultaneously (3 and 4) as a reward for crossing the hardest RL threshold.

**Rule 3 -- Passive Activation.** Blessings are always-on -- they require no player action to trigger. Individual blessings may have trigger conditions (e.g., "if hand contains a Club", "if hand rank >= Three of a Kind"). Triggers are evaluated once per PLAY action, at the moment `blessing_chips` and `blessing_mult` are computed. Blessings without a trigger condition apply every hand unconditionally.

**Rule 4 -- Pipeline Injection.** The scoring pipeline reads two aggregate values:
- `blessing_chips` -- single integer, summed across all triggered blessings this hand
- `blessing_mult` -- single float, summed additively across all triggered blessings this hand

Both computed fresh each PLAY. Neither persists across turns. They inject at their designated positions in the combat_score_pipeline (per Poker Combat GDD Rule 5).

**Rule 5 -- Separation from Social Buffs.** `blessing_chips`/`blessing_mult` are computed entirely separately from `social_buff_chips`/`social_buff_mult`. They occupy different pipeline slots. Both can be active simultaneously. No shared caps or limits.

**Rule 6 -- Immutability During Combat.** Romance stage changes during combat (edge case: dialogue-triggered RL gains) do NOT unlock new blessing slots mid-fight. The blessing set active at combat start is frozen for the encounter duration.

### Companion Kit Design

**Artemisa (Earth/Clubs) -- The Patient Strategist**
STR 17/INT 13. Rewards patience and hand-building discipline. Favors consistent, full-hand plays over gambling. Blessings compound across the fight. Strategic identity: "The longer the fight goes, the stronger she gets."

**Hipolita (Fire/Hearts) -- The Aggressor**
STR 20/INT 9. Highest chip base, weakest mult. Wants to end fights fast with explosive chip hands. Blessings reward playing Hearts and committing early. Strategic identity: "Hit hard, hit fast, don't look back."

**Atenea (Lightning/Spades) -- The Analyst**
STR 13/INT 19. Weakest chips, highest mult. Converts precision into exponential scores. Blessings reward playing fewer cards for maximum effect. Strategic identity: "Every card she plays was decided before she sat down."

**Nyx (Water/Diamonds) -- The Tidal Force**
STR 18/INT 19. Highest combined stats but hardest to unlock. Earlier slots moderate, later slots dramatically stronger. Strategic identity: "She holds back until she trusts you completely -- then she holds nothing back."

### The 20 Blessings

#### Artemisa (Earth / Clubs)

| Slot | Stage | Name | Effect | blessing_chips | blessing_mult | Trigger |
|---|---|---|---|---|---|---|
| 1 | 1 | Rooted Ground | Per-Club chip bonus | +8 per Club played | +0 | Always; per Club |
| 2 | 2 | Patient Hunt | Bonus if no discards used yet this combat | +20 | +0 | `discards_used == 0` |
| 3 | 3 | Earth Memory | Stacking chips per prior hand that scored >= 60 chips (cap 3 stacks) | +12 per stack (max +36) | +0 | Conditional; counts prior hands |
| 4 | 3 | Forest Bond | Bonus mult if King of Clubs (signature card) is in played cards | +0 | +3.0 | Signature card present |
| 5 | 4 | Ancient Grove | Bonus if all 5 cards are played (full hand) | +25 | +1.5 | `cards_played == 5` |

#### Hipolita (Fire / Hearts)

| Slot | Stage | Name | Effect | blessing_chips | blessing_mult | Trigger |
|---|---|---|---|---|---|---|
| 1 | 1 | Ember Strike | Per-Heart chip bonus | +10 per Heart played | +0 | Always; per Heart |
| 2 | 2 | Warchief's Will | Bonus on first or second hand of combat | +30 | +0 | `hands_played <= 2` |
| 3 | 3 | Fury Surge | Bonus mult on Three of a Kind or higher | +0 | +2.0 | `hand_rank >= THREE_OF_A_KIND` |
| 4 | 3 | Blood Price | Bonus chips if 2+ discards used this combat | +35 | +0 | `discards_used >= 2` |
| 5 | 4 | Inferno Crown | Bonus on Heart Flush (Flush+ with all Hearts) | +40 | +4.0 | `hand_rank >= FLUSH` AND all suited cards Hearts |

#### Atenea (Lightning / Spades)

| Slot | Stage | Name | Effect | blessing_chips | blessing_mult | Trigger |
|---|---|---|---|---|---|---|
| 1 | 1 | Static Charge | Per-Spade mult bonus | +0 | +0.8 per Spade played | Always; per Spade |
| 2 | 2 | Calculated Strike | Bonus mult if exactly 3 cards played | +0 | +2.5 | `cards_played == 3` |
| 3 | 3 | Overload | Chips bonus if Ace of Spades (signature) is played | +33 | +0 | Signature card present |
| 4 | 3 | Strategic Mastery | Bonus mult if current_score is 0 (first play) or >= 150 | +0 | +3.0 | `current_score == 0` OR `>= 150` |
| 5 | 4 | Thunderclap | Bonus mult if raw hand chips (before bonuses) <= 40 | +0 | +5.0 | `raw_hand_chips <= 40` |

#### Nyx (Water / Diamonds)

| Slot | Stage | Name | Effect | blessing_chips | blessing_mult | Trigger |
|---|---|---|---|---|---|---|
| 1 | 1 | Moonlit Current | Per-Diamond chip bonus | +7 per Diamond played | +0 | Always; per Diamond |
| 2 | 2 | Abyssal Depth | Bonus mult if 2+ Diamonds in played hand | +0 | +1.5 | `diamonds_in_hand >= 2` |
| 3 | 3 | Starless Night | Bonus if no discards used at all (discards_remaining == discards_allowed) | +15 | +2.0 | `discards_remaining == discards_allowed` |
| 4 | 3 | Tidal Surge | Bonus mult if blessing_chips from other blessings this hand >= 14 | +0 | +2.5 | `blessing_chips_before_this >= 14` |
| 5 | 4 | Devoted Ocean | Unconditional flat bonus -- always active, no trigger | +30 | +3.5 | Always-on |

### Maximum Theoretical Blessing Contribution (Stage 4, All Triggers Met)

| Captain | Max blessing_chips | Max blessing_mult | Profile |
|---|---|---|---|
| Artemisa | +121 | +4.5 | High chips, moderate mult |
| Hipolita | +155 | +6.0 | Highest chips, moderate mult |
| Atenea | +33 | +14.5 | Low chips, highest mult |
| Nyx | +80 | +9.5 | Moderate both, strongest combined at full investment |

### States and Transitions

| State | Condition | Effect |
|---|---|---|
| `LOCKED` | `romance_stage < required_stage` | Hidden from player. Does not contribute. |
| `UNLOCKED` | `romance_stage >= required_stage` AND companion is not captain | Visible in profile, but dormant. |
| `ACTIVE` | `romance_stage >= required_stage` AND companion IS captain | Evaluates trigger each hand. |
| `INACTIVE_TRIGGER` | Active slot but trigger not met this hand | Contributes 0 this hand. Re-evaluates next hand. |

Transitions: `romance_stage_changed` (LOCKED -> UNLOCKED), captain selection at combat start (UNLOCKED -> ACTIVE), trigger evaluation each PLAY (ACTIVE <-> INACTIVE_TRIGGER).

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| **Romance & Social** | Blessings depends on R&S | Listens for `romance_stage_changed(companion_id, old, new)`. Updates slot availability. |
| **Poker Combat** | Blessings extends Poker Combat | At RESOLVE phase, Poker Combat calls `DivineBlessing.compute(hand_context)`. Receives `{blessing_chips, blessing_mult}`. |
| **Companion Data** | Blessings reads Companion Data | Reads `companion_id`, `element`, `signature_card` at combat setup for trigger evaluation. |
| **Deck Management** | Deck Management sets captain; Blessings reads it | Captain ID set before combat. Blessings caches active blessing set at SETUP. |
| **Save System** | Persists unlock state | `unlocked_slots` per companion persisted via companion state in GameStore. No mid-combat state saved. |
| **Abyss Mode** (future) | Abyss extends Blessings | Abyss may modify blessing values via shop upgrades. Interface defined in Abyss GDD when authored. |

## Formulas

### F1 -- Per-Hand Blessing Computation

Evaluated once per PLAY action, after hand rank is determined, before final score.

```
for each blessing_slot s in captain.unlocked_slots (order: 1, 2, 3, 4, 5):
    if evaluate_trigger(s, hand_context) == true:
        blessing_chips += s.chips_value(hand_context)
        blessing_mult  += s.mult_value(hand_context)
```

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `blessing_chips` | int | [0, 155] | Summed across active blessings | Injected into combat_score_pipeline |
| `blessing_mult` | float | [0.0, 14.5] | Summed across active blessings | Injected into combat_score_pipeline |
| `hand_context` | dict | -- | Poker Combat | cards_played, hand_rank, suit_counts, current_score, hands_played, discards_used, discards_remaining |

### F2 -- Per-Card Variable Blessings

```
blessing_value = value_per_card x count_matching_cards
```

| Blessing | Per-Card Value | Max Cards | Max Output |
|---|---|---|---|
| Artemisa Slot 1 (Rooted Ground) | +8 chips | 5 | +40 chips |
| Hipolita Slot 1 (Ember Strike) | +10 chips | 5 | +50 chips |
| Atenea Slot 1 (Static Charge) | +0.8 mult | 5 | +4.0 mult |
| Nyx Slot 1 (Moonlit Current) | +7 chips | 5 | +35 chips |

### F3 -- Worked Example (Hipolita Stage 4, Three of a Kind, 5 Hearts, Hand 1)

```
base_hand_chips = 30 (Three of a Kind)
per_card_chips  = 2+4+4+4+8 = 22
captain_chips   = floor(20 x 0.5) = 10

Slot 1 (Ember Strike): 5 Hearts x 10 = +50 chips
Slot 2 (Warchief's Will): hand 1, triggered = +30 chips
Slot 3 (Fury Surge): >= Three of a Kind, triggered = +2.0 mult
Slot 4 (Blood Price): discards_used=0, NOT >= 2 = no contribution
Slot 5 (Inferno Crown): not a Flush = no contribution

blessing_chips = 80, blessing_mult = 2.0
total_chips = 30 + 22 + 10 + 80 = 142
additive_mult = 3.0 (base) + 2.0 (blessing) = 5.0
captain_mult = 1.0 + (9 x 0.025) = 1.225
score = floor(142 x 5.0 x 1.225) = floor(869.75) = 869
```

Without blessings: `floor(62 x 3.0 x 1.225) = 227`. Blessings deliver a **3.8x uplift**.

### Non-Formulas (Explicit)

- **Slot unlock** is a boolean check against romance_stage thresholds, not a formula.
- **Trigger evaluation** is boolean per-blessing, not scored or weighted.
- **Evaluation order**: Slots 1-5 sequentially. Nyx Slot 4 depends on accumulated blessing_chips from prior slots.

## Edge Cases

- **If captain has romance_stage 0**: No blessings active. `blessing_chips = 0`, `blessing_mult = 0.0`. Combat functions normally.
- **If romance_stage changes mid-combat**: Ignored. Blessing set frozen at combat start per Rule 6.
- **If captain is switched between combats**: New captain's blessings activate. Previous captain's blessings immediately inactive.
- **If Nyx Slot 4 evaluates before Slot 1**: Incorrect result. Implementation MUST evaluate slots 1, 2, 3, 4, 5 sequentially.
- **If Artemisa Slot 3 (Earth Memory) on hand 1**: 0 stacks (no prior hands). Always +0 chips on first hand.
- **If all 5 cards match captain's element**: All per-card blessings fire at maximum. Optimal case, not an error.
- **If Poker Combat does not track `discards_used` or `hands_played`**: Implementation must add these as combat state fields. New requirement on Poker Combat internals.
- **If Hipolita Slot 5 fires with Foil/Holo cards in Abyss**: Blessing values are flat, do not scale with enhancements. Independent additive sources. Balance review for Abyss recommended.
- **If companion has 0 unlocked blessings but is captain**: Valid. Captain stat bonus applies. `blessing_chips = 0`, `blessing_mult = 0.0`.
- **If a blessing's trigger references a signature card not in the played hand**: Trigger is false. Blessing contributes 0. No error.

## Dependencies

| System | Direction | Nature | Interface |
|---|---|---|---|
| **Romance & Social** | Blessings depends on this | **Hard** | `romance_stage_changed(companion_id, old, new)` signal. Without R&S, no blessings unlock. |
| **Poker Combat** | Blessings extends this | **Hard** | `DivineBlessing.compute(hand_context) -> {blessing_chips, blessing_mult}`. Called at RESOLVE. |
| **Companion Data** | Blessings reads this | **Hard** | Reads `companion_id`, `element`, `card_value` (signature card), `romance_stage`. |
| **Deck Management** | Blessings reads captain | **Soft** | Captain ID set before combat. Without Deck Management, no captain = no blessings. |
| **Save System** | Persists unlock state | **Soft** | Unlock state = romance_stage (already persisted by R&S). No additional save data needed. |
| **Abyss Mode** (future) | Abyss extends Blessings | **Soft** | May modify blessing values via shop. Interface deferred to Abyss GDD. |

**Hard (3):** Romance & Social, Poker Combat, Companion Data.
**Soft (3):** Deck Management, Save System, Abyss Mode.

**Bidirectional consistency:**
- Poker Combat GDD lists Divine Blessings as soft dependency extending scoring pipeline
- Romance & Social GDD lists Divine Blessings as receiver of `romance_stage_changed`
- Companion Data GDD lists Divine Blessings as reading `romance_stage`

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|---|---|---|---|---|
| Per-card chip values (Slot 1s) | 7-10 per card | [3, 15] | Stronger suit-matching incentive; mono-suit dominates | Suit matching matters less; hand rank dominates |
| Conditional flat chips | 15-40 | [5, 60] | Larger spikes on trigger; more volatile scoring | Smoother scoring; triggers feel less impactful |
| Conditional flat mult | 1.5-5.0 | [0.5, 8.0] | Multiplicative scaling amplifies dramatically | Blessings feel like minor stat bumps |
| Nyx Slot 5 flat values | +30 chips, +3.5 mult | chips [15, 50], mult [2.0, 5.0] | Nyx becomes strictly best captain at stage 4 | Late-game payoff underwhelming for investment |
| Earth Memory stack cap | 3 stacks | [2, 5] | Longer fights favor Artemisa more | Artemisa late-fight identity weakens |
| Thunderclap threshold | raw_chips <= 40 | [25, 60] | Fires more often; low-card plays always strong | Fires rarely; must be very precise |

**Cross-knob interactions:**
- Per-card values x 5 must not exceed early score thresholds, or stage 1 blessings trivialize Chapter 1.
- Nyx Slot 5 sets the ceiling for "best captain at stage 4." If too high, endgame converges on Nyx.
- Atenea mult values compound with her INT bonus (1.475x). Small mult increases have outsized impact.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio | Priority |
|---|---|---|---|
| Blessing unlocks (stage advance) | Full-screen ceremony: icon materializes in gold light, companion portrait + element glow. Blessing name in Cinzel. Element color ink wash. | Ascending chime chord (element-pitched). Companion non-verbal awe cue. | Vertical Slice |
| Blessing fires during combat | Subtle element-colored pulse on HUD icon (0.2s glow). No full-screen interruption. | Soft harmonic note (per-companion pitch). Must not interrupt card flow. | Vertical Slice |
| Blessing inactive this hand | HUD icon dims to 40% opacity. | No audio. Silence = nothing happened. | Vertical Slice |
| All 5 blessings fire same hand | All 5 icons pulse simultaneously. Element-colored screen edge glow (15% opacity, 0.3s). | Resonant chord (all 5 notes). Rare, satisfying. | Vertical Slice |
| Signature card played (triggers Slot 3/4) | Signature card gets brief gold border flash before scoring. | Distinct crystalline chime. | Vertical Slice |

### Art Principles
1. **Subtlety during combat**: Blessings fire every hand. VFX must NOT interrupt poker decision flow. 0.2s icon pulse, not screen-wide particles.
2. **Ceremony on unlock**: The unlock moment IS the reward for romance investment. Should feel as weighty as stage advance ceremony.
3. **Element color discipline**: Blessing VFX use companion's element color only. No mixing.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| Active blessings (captain's set) | Combat HUD, left edge -- vertical column of 1-5 icons (32x32px) | On combat start | During combat |
| Blessing trigger state | Icon opacity: 100% = triggered, 40% = not triggered | Per PLAY action | During combat |
| Blessing tooltip | Long-press on icon (pauses game) | On demand | During combat |
| Companion blessing overview | Companion Room -- 5 slots per companion, locked/unlocked | On romance_stage_changed | Camp/Companion Room |
| Blessing unlock notification | Full-screen overlay | On unlock | Outside combat |

**Layout** (combat screen, portrait 430x932): Blessing icons stacked vertically on left edge, 32x32px + 4px spacing. Outside card play area to avoid touch conflicts.

**Accessibility**: Distinct icon shapes per companion (not just color). Tooltip via long-press. Trigger state shown by opacity AND checkmark/x overlay for color-blind users.

> **UX Flag -- Divine Blessings**: This system has UI requirements in both the combat screen and companion room. In Phase 4, run `/ux-design` for both screens.

## Acceptance Criteria

### Rule 1-2 -- Captain Lock and Slot Availability
- [ ] **AC-DB-01** -- **GIVEN** Artemisa captain, romance_stage 2, **WHEN** combat starts, **THEN** slots 1-2 ACTIVE, slots 3-5 LOCKED.
- [ ] **AC-DB-02** -- **GIVEN** Hipolita captain, romance_stage 0, **WHEN** combat starts, **THEN** no blessings active, `blessing_chips = 0`, `blessing_mult = 0.0`.
- [ ] **AC-DB-03** -- **GIVEN** Nyx captain, romance_stage 3, **WHEN** combat starts, **THEN** slots 1-4 ACTIVE (stage 3 unlocks both 3 and 4).

### Rule 3-4 -- Trigger and Pipeline
- [ ] **AC-DB-04** -- **GIVEN** Artemisa captain stage 1, 3 Clubs played, **WHEN** PLAY resolves, **THEN** `blessing_chips = 24` (3 x 8), `blessing_mult = 0.0`.
- [ ] **AC-DB-05** -- **GIVEN** Atenea captain stage 2, exactly 3 cards played, **WHEN** PLAY resolves, **THEN** Calculated Strike triggers: `blessing_mult` includes +2.5.
- [ ] **AC-DB-06** -- **GIVEN** Atenea captain stage 2, 4 cards played, **WHEN** PLAY resolves, **THEN** Calculated Strike does NOT trigger.

### Rule 5 -- Social Buff Independence
- [ ] **AC-DB-07** -- **GIVEN** active social buff AND blessings active, **WHEN** PLAY resolves, **THEN** both contribute independently to total_chips and additive_mult.

### Rule 6 -- Immutability
- [ ] **AC-DB-08** -- **GIVEN** captain stage 1 at combat start, stage advances to 2 mid-combat, **WHEN** next PLAY, **THEN** only Slot 1 contributes (frozen at start).

### Per-Companion Verification
- [ ] **AC-DB-09** -- **GIVEN** Hipolita captain stage 4, first hand, 5 Hearts, Three of a Kind, **WHEN** PLAY resolves, **THEN** Ember Strike (+50), Warchief's Will (+30), Fury Surge (+2.0 mult) trigger. Blood Price and Inferno Crown do not.
- [ ] **AC-DB-10** -- **GIVEN** Nyx captain stage 4, 3 Diamonds, no discards used, **WHEN** PLAY resolves, **THEN** all 5 blessings fire: chips = 21+15+30 = 66, mult = 1.5+2.0+2.5+3.5 = 9.5.
- [ ] **AC-DB-11** -- **GIVEN** Artemisa captain stage 3, King of Clubs played, **WHEN** PLAY resolves, **THEN** Forest Bond triggers: +3.0 mult.
- [ ] **AC-DB-12** -- **GIVEN** Atenea captain stage 4, raw_hand_chips = 35, **WHEN** PLAY resolves, **THEN** Thunderclap triggers: +5.0 mult.

### Edge Cases
- [ ] **AC-DB-13** -- **GIVEN** Nyx Slot 4 (Tidal Surge), **WHEN** evaluated, **THEN** slots 1-3 evaluated BEFORE slot 4.
- [ ] **AC-DB-14** -- **GIVEN** Artemisa Slot 3 (Earth Memory) on hand 1, **WHEN** evaluated, **THEN** 0 stacks, +0 chips.
- [ ] **AC-DB-15** -- **GIVEN** companion with 0 unlocked blessings as captain, **WHEN** combat runs, **THEN** no errors. Captain stat bonus applies. Blessings = 0.

### Performance and Data
- [ ] **AC-DB-16** -- Blessing computation completes within 1ms per PLAY action.
- [ ] No blessing names, values, or triggers hardcoded outside balance config files.
- [ ] All 20 blessings are data-driven from a config resource.

## Cross-References

| This Document References | Target GDD | Specific Element | Nature |
|---|---|---|---|
| `blessing_chips`, `blessing_mult` pipeline variables | `design/gdd/poker-combat.md` | `combat_score_pipeline` formula | Data dependency |
| Captain lock at combat start | `design/gdd/poker-combat.md` | Rule 2 (Captain) | Rule dependency |
| `romance_stage_changed` signal | `design/gdd/romance-social.md` | Rule 9 (Stage Advancement) | State trigger |
| Romance stage thresholds [0,21,51,71,91] | `design/gdd/companion-data.md` | Romance Stage Derivation | Rule dependency |
| Companion element, card_value, signature card | `design/gdd/companion-data.md` | Companion Registry table | Data dependency |
| Suit-element mapping (Hearts=Fire, etc.) | `design/gdd/poker-combat.md` | Rule 1 (Deck Composition) | Data dependency |
| Captain selection before combat | `design/gdd/deck-management.md` | Captain confirmation flow | State trigger |
| Social buff independence | `design/gdd/romance-social.md` | Rule 6 (Social Combat Buffs) | Rule dependency |

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should blessings be visible in Companion Room before unlocked (teaser) or hidden? | ux-designer | Before Camp UI | Teaser encourages investment; hidden prevents spoilers. |
| Should Abyss Mode allow temporary blessing upgrades via shop? | game-designer | Before Abyss Mode GDD | Would add blessing mutation layer. Defer to Abyss. |
| Should trigger conditions be visible to player during combat? | game-designer | Before UI implementation | Visible = strategic clarity. Hidden = discovery. Recommend visible for Vertical Slice. |
| Is Atenea Thunderclap threshold (raw_chips <= 40) correctly calibrated? | systems-designer | Before playtest | Needs simulation. Flag for /balance-check. |
| Should Earth Memory chip threshold be configurable per-enemy or fixed at 60? | systems-designer | Before balance tuning | Fixed for now. Per-enemy adds complexity for minimal Chapter 1 gain. |
