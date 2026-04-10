# Poker Combat

> **Status**: Designed
> **Author**: game-designer + systems-designer + art-director + qa-lead
> **Last Updated**: 2026-04-08
> **Implements Pillar**: Pillar 1 — Balatro-Inspired Poker Combat

## Summary

Poker Combat is the core gameplay loop of Dark Olympus -- the system where the player selects cards from a hand of 5, forms poker hands, and scores chips x mult against an enemy's HP threshold. It encompasses the 52-card deck, hand evaluation (10 poker ranks), the scoring pipeline (base chips + per-card chips + enhancements + blessings) x (base mult + enhancement mult + blessing mult), card enhancements (Foil, Holographic, Polychrome), element-suit mapping (Hearts->Fire, Diamonds->Water, Clubs->Earth, Spades->Lightning), and the combat encounter lifecycle (draw, select, play/discard, resolve, victory/defeat). Three downstream systems extend it: Divine Blessings modifies the scoring pipeline, Abyss Mode adds roguelike scaling, and Story Flow sequences encounters within the narrative.

> **Quick reference** -- Layer: `Core` · Priority: `MVP` · Key deps: `Enemy Data, Companion Data`

## Overview

Poker Combat is the primary action the player takes in Dark Olympus. Each combat encounter pits the player against a mythological enemy with an HP-based score threshold. The player has 4 hands and 4 discards to accumulate enough score to meet or exceed the threshold. On each turn, they draw 5 cards from a shuffled 52-card deck, select 1-5 cards to play as a poker hand (or discard to redraw), and the system evaluates the hand rank, calculates a score via chips x mult, and adds it to the running total. Card suits map to the four elements (Fire, Water, Earth, Lightning), tying combat to the companion romance system -- deeper relationships unlock divine blessings that modify scoring. The system must be deep enough to sustain hundreds of encounters across story chapters and Abyss runs while remaining accessible in the first 5 minutes with a Forest Monster tutorial fight worth 40 HP.

## Player Fantasy

You play not as a lone gambler but as someone whose strength grows from connection. The cards you hold are power, but the blessings your companions unlock transform that power into something personal -- Artemisa sharpens your Earth-suit hands, Hipolita turns Fire into fury. As relationships deepen, the scoring pipeline feels increasingly tailored to how you play, as though the goddesses are reading your strategy and amplifying it. This makes each combat encounter a living record of the relationships you've invested in: your deck reflects your alliances. The "juice" of a big scoring moment in Dark Olympus carries extra resonance because you can trace it -- this score happened because you talked to Artemisa three days in a row, earned her trust, and she gave you something real.

*Pillar 1: "Combat is poker hand evaluation with chips x mult scoring. Every card play is a strategic decision."*
*Pillar 3: "Romance is not a cosmetic layer -- it directly enhances combat via divine blessings."*

## Detailed Design

### Core Rules

1. **Deck Composition.** Standard 52 cards: 4 suits x 13 values (2-14, Ace=14). No jokers, no wildcards. Each companion has a "signature card" -- the card matching their suit and card_value (e.g., Artemisa = King of Clubs). Signature cards are tagged with the companion's ID when the deck is built but play identically to any other card. In story combat, the deck is always a clean 52 cards. Deck modifications (card removal, additions) are Abyss Mode territory, not core combat.

2. **Combat Encounter Setup.** Each encounter is configured by an enemy profile dictionary:
   - `name_key` (String) -- i18n key for display name
   - `score_threshold` (int) -- score needed to win
   - `hp` (int) -- visual HP bar value (may differ from score_threshold)
   - `element` (Element enum) -- enemy's affinity (Fire/Water/Earth/Lightning/None)
   - `hands_allowed` (int, default 4) -- hands the player may play
   - `discards_allowed` (int, default 4) -- discards available

   The active captain companion is set before combat begins. Their stats and blessings are locked for the duration of the encounter.

3. **Turn Flow.** Each combat follows this sequence:

   **Setup (once):** Retrieve captain stats and blessings. Build and shuffle deck. Initialize: `current_score = 0`, `hands_remaining = hands_allowed`, `discards_remaining = discards_allowed`.

   **Draw:** Deal 5 cards from the top of the deck. If fewer than 5 remain, draw all remaining.

   **Select:** Player selects 1-5 cards and chooses PLAY or DISCARD.

   **Play:** Run scoring pipeline on selected cards. Add score to `current_score`. Remove played cards from the game. Decrement `hands_remaining`. Check victory/defeat.

   **Discard:** Remove selected cards. Draw replacements to refill hand to 5 (or as many as deck allows). Decrement `discards_remaining`. Return to Select.

4. **Hand Evaluation.** 10 poker ranks:

   | Rank | Base Chips | Base Mult | Requirement |
   |------|-----------|-----------|-------------|
   | High Card | 5 | 1x | No pattern |
   | Pair | 10 | 2x | 2 same value |
   | Two Pair | 20 | 2x | 2 different pairs |
   | Three of a Kind | 30 | 3x | 3 same value |
   | Straight | 30 | 4x | 5 consecutive values (includes A-2-3-4-5 wheel) |
   | Flush | 35 | 4x | 5 same suit |
   | Full House | 40 | 4x | 3 + 2 same value |
   | Four of a Kind | 60 | 7x | 4 same value |
   | Straight Flush | 100 | 8x | 5 same suit + consecutive |
   | Royal Flush | 100 | 8x | 10-J-Q-K-A same suit |

   Flush and Straight require exactly 5 cards. Fewer-than-5-card plays can only achieve High Card through Four of a Kind. Per-card chips: Ace=11, J/Q/K=10, 2-10=face value. All selected cards contribute per-card chips -- no "kicker" distinction.

5. **Scoring Pipeline.** Strictly ordered: additive chips, then additive mult, then multiplicative mult, then floor.

   **Chips (additive):**
   ```
   total_chips = base_hand_chips
               + sum(per_card_chips for each card)
               + sum(foil_chips: +50 per Foil card)
               + blessing_chips (from Divine Blessings)
               + sum(element_bonus: +25 per weak-element card, -15 per resist-element card)
               + captain_chip_bonus (floor(STR x 0.5))
               + social_buff_chips (from active CombatBuff)
   ```
   Minimum total_chips = 1 (clamped after all additions).

   **Mult (additive then multiplicative):**
   ```
   additive_mult = base_hand_mult
                 + sum(holo_mult: +10 per Holographic card)
                 + blessing_mult (additive portion)
                 + sum(element_bonus_mult: +0.5 per weak-element card)
                 + social_buff_mult

   final_mult = additive_mult
              x product(1.5 for each Polychrome card)
              x (1.0 + INT_captain x 0.025)
   ```

   **Final score:** `score = floor(total_chips x final_mult)`

6. **Element Weakness and Resistance.** The element cycle:
   ```
   Fire > Earth > Lightning > Water > Fire
   ```
   Fire beats Earth. Earth beats Lightning. Lightning beats Water. Water beats Fire.

   Per card in the played hand:
   - Card element = enemy's weak element: **+25 chips, +0.5 mult** (additive)
   - Card element = enemy's own element: **-15 chips** (no mult penalty)
   - Card element = neutral: no effect
   - Enemy element = None: no element interactions

   **Element cycle table:**

   | Enemy Element | Weak To | Cards That Trigger Weakness | Cards That Trigger Resistance |
   |--------------|---------|---------------------------|------------------------------|
   | Fire | Water | Diamonds (Water) | Hearts (Fire) |
   | Water | Lightning | Spades (Lightning) | Diamonds (Water) |
   | Earth | Fire | Hearts (Fire) | Clubs (Earth) |
   | Lightning | Earth | Clubs (Earth) | Spades (Lightning) |
   | None | -- | No bonus | No penalty |

7. **Captain Stat Bonus.** The active companion contributes passively to every hand:
   - `captain_chip_bonus = floor(STR x 0.5)` -- additive chips
   - `captain_mult_modifier = 1.0 + (INT x 0.025)` -- multiplicative (applied after Polychrome)
   - AGI has no combat effect -- reserved for future systems

   | Captain | STR | Chip Bonus | INT | Mult Modifier |
   |---------|-----|-----------|-----|--------------|
   | Artemisa | 17 | +8 | 13 | x1.325 |
   | Hipolita | 20 | +10 | 9 | x1.225 |
   | Atenea | 13 | +6 | 19 | x1.475 |
   | Nyx | 18 | +9 | 19 | x1.475 |

   Captain is locked at combat start. No captain = no bonus.

8. **Card Enhancements.** Three types, applied per-card during scoring:
   - **Foil**: +50 chips (additive)
   - **Holographic**: +10 mult (additive)
   - **Polychrome**: x1.5 mult (multiplicative, applied sequentially per Poly card)

   A card has at most one enhancement. Enhancements are gained through Abyss shop purchases or story rewards.

9. **Discard Rules.** Player selects 1-5 cards to discard (0 is not valid). Discarded cards are permanently removed from combat. Replacement cards are drawn immediately. No cost or penalty for discarding -- discards are a limited resource (default 4).

10. **Victory and Defeat.**
    - **Victory**: `current_score >= score_threshold` after any PLAY. Combat ends immediately -- remaining hands forfeited. Social buff consumed. Gold and XP awarded.
    - **Defeat**: `hands_remaining == 0` AND `current_score < score_threshold`. Social buff NOT consumed (persists to next attempt). No penalty. Player may retry with fresh deck.

11. **Card Sorting.** Two modes toggled by the player: Sort by Value (default, 2->A left to right) or Sort by Suit (Hearts->Diamonds->Clubs->Spades, then by value). Display-only, no gameplay effect.

### States and Transitions

| State | Entry Condition | Valid Actions | Exit Condition | Next State |
|-------|----------------|--------------|----------------|------------|
| `SETUP` | Combat encounter initiated | None (automated) | Deck built, captain loaded | `DRAW` |
| `DRAW` | Start of combat; after PLAY with hands remaining | None (automated) | 5 cards dealt (or deck exhausted) | `SELECT` |
| `SELECT` | Draw complete; after discard refill | PLAY (1-5 cards), DISCARD (1-5 cards), SORT TOGGLE | Player commits action | `RESOLVE` or `DISCARD_DRAW` |
| `RESOLVE` | Player plays a hand | None (automated) | Score calculated, added to total | `VICTORY`, `DEFEAT`, or `DRAW` |
| `DISCARD_DRAW` | Player discards cards | None (automated) | Replacement cards drawn | `SELECT` |
| `VICTORY` | `current_score >= score_threshold` | Continue (to story/hub) | Story Flow or player navigates out | Terminal |
| `DEFEAT` | `hands_remaining == 0` AND `current_score < threshold` | Retry or Retreat | Player chooses | Terminal (retry -> `SETUP`) |

Invalid transitions:
- Cannot reach DEFEAT from DISCARD_DRAW (discarding never ends combat)
- Cannot enter DISCARD_DRAW if `discards_remaining == 0`
- Cannot enter RESOLVE with 0 cards selected
- Cannot enter RESOLVE if `hands_remaining == 0`

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Enemy Data** | This depends on Enemy Data | Reads enemy profiles (hp, score_threshold, element, type) to configure encounters. Story combat uses inline `enemy_config` from chapter nodes. |
| **Companion Data** | This depends on Companion Data | Reads captain's STR, INT for stat bonus. Reads card_element and card_value for signature card tagging. Reads element enum for suit mapping. |
| **Divine Blessings** | Blessings extends this | Blessings inject `blessing_chips` and `blessing_mult` into the scoring pipeline. Slots unlock by romance_stage. Interface defined in Divine Blessings GDD (not yet designed). |
| **Story Flow** | Story Flow consumes this | Story Flow calls SceneManager to load combat with enemy_config context. Combat emits `combat_completed(result)`. Story Flow listens and advances the story node. |
| **Abyss Mode** | Abyss extends this | Abyss generates score_threshold targets procedurally (not from Enemy Data). Abyss shop modifies deck (remove cards, add enhancements). Interface defined in Abyss GDD. |
| **Romance & Social** | Social buffs feed this | Social combat buffs (mult + chips for N combats) are read at combat start. Consumed on victory, retained on defeat. Defined in Romance & Social GDD. |
| **Scene Navigation** | This calls SceneManager | On victory/defeat, combat calls `SceneManager.change_scene()` to return to Hub or advance story. Uses `SceneId` enum and context payload. |
| **Deck Management** | Deck configures this | Captain selection and deck composition are set before combat via the Deck screen. Interface defined in Deck Management GDD. |
| **Save System** | Indirect | Combat state is NOT saved mid-fight. Only outcomes (gold, XP, story progress) are persisted via autoload stores. |

## Formulas

### F1 -- Per-Card Chips

```
card_chips(v) = v           where v in [2, 10]
card_chips(v) = 10          where v in {11, 12, 13}   (J, Q, K)
card_chips(v) = 11          where v = 14              (Ace)
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Card value | v | int | [2, 14] | Card face value (2=2 through 14=Ace) |
| Card chips | card_chips(v) | int | [2, 11] | Chip contribution of one card |

**Output Range:** 2 to 11. Bounded. J/Q/K collapse to 10; Ace is 11.

**Example:** K, Q, 9, 6, 3 yields: 10 + 10 + 9 + 6 + 3 = 38 per-card chips.

### F2 -- Element Interaction

```
element_chips(card) =  +25   if suit_element(card) == enemy_weak_element
                       -15   if suit_element(card) == enemy_element
                         0   otherwise

element_mult(card)  =  +0.5  if suit_element(card) == enemy_weak_element
                         0   otherwise
```

Element cycle: `Fire > Earth > Lightning > Water > Fire`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Card element | suit_element(card) | Element enum | {Fire, Water, Earth, Lightning} | Derived from suit: Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning |
| Enemy element | enemy_element | Element enum | {Fire, Water, Earth, Lightning, None} | Enemy's affinity; None disables all interactions |
| Weak element | enemy_weak_element | Element enum | Derived from cycle | The element that beats the enemy's element |
| Chip bonus | element_chips(card) | int | {-15, 0, +25} | Per-card chip adjustment |
| Mult bonus | element_mult(card) | float | {0.0, +0.5} | Per-card additive mult adjustment |

**Output Range:** Per card: chips in {-15, 0, +25}, mult in {0.0, 0.5}. Summed across 5 cards: chips [-75, +125], mult [0.0, +2.5].

**Example:** 5-card Flush (all Hearts = Fire) vs Gaia Spirit (Earth, weak to Fire): element_chips = 5 x (+25) = +125, element_mult = 5 x (+0.5) = +2.5.

### F3 -- Captain Stat Bonus

```
captain_chip_bonus    = floor(STR x 0.5)
captain_mult_modifier = 1.0 + (INT x 0.025)
```

Applied once per hand, passively, regardless of cards played.

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Strength | STR | int | [1, 30] | Captain's STR stat from Companion Data |
| Intelligence | INT | int | [1, 30] | Captain's INT stat from Companion Data |
| Chip bonus | captain_chip_bonus | int | [0, 15] | Flat chips added each hand (floored) |
| Mult modifier | captain_mult_modifier | float | [1.025, 1.75] | Multiplicative, applied after Polychrome |

**Companion reference values:**

| Captain | STR | Chip Bonus | INT | Mult Modifier |
|---------|-----|-----------|-----|--------------|
| Artemisa | 17 | +8 | 13 | x1.325 |
| Hipolita | 20 | +10 | 9 | x1.225 |
| Atenea | 13 | +6 | 19 | x1.475 |
| Nyx | 18 | +9 | 19 | x1.475 |

No captain = captain_chip_bonus 0, captain_mult_modifier 1.0.

### F4 -- Combat Score (Full Pipeline)

```
total_chips = base_hand_chips
            + sum(card_chips(v) for each played card)
            + sum(+50 for each Foil card)
            + blessing_chips
            + sum(element_chips(card) for each played card)
            + captain_chip_bonus
            + social_buff_chips

total_chips = max(1, total_chips)                             [floor clamp]

additive_mult = base_hand_mult
              + sum(+10 for each Holographic card)
              + blessing_mult
              + sum(element_mult(card) for each played card)
              + social_buff_mult

additive_mult = max(1.0, additive_mult)                      [floor clamp]

final_mult = additive_mult
           x product(1.5 for each Polychrome card)
           x captain_mult_modifier

score = floor(total_chips x final_mult)
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_hand_chips | -- | int | {5, 10, 20, 30, 35, 40, 60, 100} | From hand rank evaluation |
| base_hand_mult | -- | float | {1, 2, 3, 4, 7, 8} | From hand rank evaluation |
| foil_chips | -- | int | 0 or +50 per card | Foil enhancement bonus |
| blessing_chips | -- | int | [0, unbounded] | From active Divine Blessings |
| social_buff_chips | -- | int | [0, unbounded] | From active social combat buff |
| holo_mult | -- | float | 0 or +10 per card | Holographic enhancement bonus |
| blessing_mult | -- | float | [0.0, unbounded] | From active Divine Blessings |
| social_buff_mult | -- | float | [0.0, unbounded] | From active social combat buff |
| total_chips | -- | int | [1, unbounded] | Resolved chip total, clamped to min 1 |
| additive_mult | -- | float | [1.0, unbounded] | Sum of all additive mult sources |
| final_mult | -- | float | [1.025, unbounded] | After Polychrome and captain scaling |
| score | -- | int | [1, unbounded] | Final hand score, floored to integer |

**Output Range:** Minimum 1 (clamped chips x minimum mult). No upper cap -- intentionally unbounded for Abyss scaling.

#### Worked Example A -- Early Game: Pair vs Forest Monster

**Setup:** No captain, no enhancements, no blessings. Forest Monster (element: None, threshold: 40). Cards: 7, 7, 9, 5, 3 (Pair of 7s).

| Phase | Component | Value |
|-------|-----------|-------|
| Chips | base_hand_chips (Pair) | 10 |
| | per_card_chips (7+7+9+5+3) | 31 |
| | All other chip sources | 0 |
| | **total_chips** | **41** |
| Mult | base_hand_mult (Pair) | 2.0 |
| | All other mult sources | 0 |
| | **final_mult** | **2.0** |
| Score | floor(41 x 2.0) | **82** |

Result: **82**. Threshold 40 -- victory on the first hand. Tutorial enemy falls to even an unoptimized hand.

#### Worked Example B -- Mid-Game: Flush with Synergies vs Gaia Spirit

**Setup:** Captain Hipolita (STR=20, INT=9). 5-card Flush, all Hearts (Fire). Enemy = Gaia Spirit (Earth, threshold: 130). 1 Foil card (K). No Holo, Poly, blessings, or social buff.

| Phase | Component | Value |
|-------|-----------|-------|
| Chips | base_hand_chips (Flush) | 35 |
| | per_card_chips (10+10+9+6+3) | 38 |
| | foil_chips (1 Foil x 50) | 50 |
| | element_chips (5 Fire vs Earth weak: 5 x +25) | +125 |
| | captain_chip_bonus (floor(20 x 0.5)) | +10 |
| | **total_chips** | **258** |
| Mult | base_hand_mult (Flush) | 4.0 |
| | element_mult (5 Fire vs Earth weak: 5 x +0.5) | +2.5 |
| | **additive_mult** | **6.5** |
| | captain_mult_modifier (1.0 + 9 x 0.025) | x1.225 |
| | **final_mult** | **7.9625** |
| Score | floor(258 x 7.9625) | **2,054** |

Result: **2,054**. Threshold 130 -- dramatic overkill. This is the "everything clicked" synergy moment: element weakness + Foil + captain alignment on a Flush.

### F5 -- Victory Condition

```
victory = (current_score >= score_threshold)
```

Evaluated immediately after each PLAY resolves. Combat ends as soon as true.

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| current_score | -- | int | [0, unbounded] | Accumulated score across all played hands |
| score_threshold | -- | int | [40, 250+] | Target from enemy profile |
| victory | -- | bool | {true, false} | True = player wins, combat ends |

**Example:** After two hands totaling 95 vs Cyclops (threshold: 100): victory = false. Third hand scores 12 more: 107 >= 100 = true, combat ends.

## Edge Cases

### Boundary Values

- **If the deck has fewer than 5 cards at DRAW:** Deal all remaining cards. The player receives a hand of 1–4 cards. Flush and Straight are unachievable (require exactly 5); maximum rank is Four of a Kind. UI must display the reduced hand and allow PLAY/DISCARD with 1–N selections.

- **If the deck is empty at DRAW (0 cards available):** Treat as defeat — combat ends immediately as a loss. Rationale: SELECT with 0 cards has no valid action; auto-defeat prevents UI deadlock.

- **If all 5 played cards are resist-element (same element as enemy):** element_chips = 5 × (−15) = −75. If total pre-clamp chips ≤ 0, the `max(1, total_chips)` clamp fires. Minimum score is `floor(1 × 1.0) = 1`. This is the primary scenario the clamp exists for.

- **If `discards_remaining == 0`:** DISCARD action is disabled (state machine blocks transition to DISCARD_DRAW). UI must grey out or hide the discard button.

### Simultaneous / Conflicting Rules

- **If a hand contains both weak-element and resist-element cards (mixed suits vs. elemental enemy):** Each card is evaluated independently. Weak cards get +25 chips/+0.5 mult; resist cards get −15 chips; neutral cards get nothing. No conflict — per-card independence resolves all mixed hands.

- **If a single card's element could trigger both weakness AND resistance simultaneously:** Impossible under the element cycle. An enemy's own element and its weak element are always distinct. No card can trigger both bonuses on one enemy.

- **If enemy element is `None`:** All element interactions are disabled. No +25, no +0.5, no −15 regardless of suits played. Binary flag — implementations must not accidentally apply bonuses against None.

### Formula Extremes

- **If `additive_mult` resolves to ≤ 0 (via future blessing or debuff interactions):** A `max(1.0, additive_mult)` clamp is applied after all additive mult sources, before Polychrome and captain scaling. This mirrors the chips clamp and guarantees `score ≥ 1` always. *(Note: F4 formula updated to include this clamp.)*

- **If a hand contains 5 Polychrome cards:** Multiplicative stacking = 1.5^5 = 7.59375×. Combined with captain and high base mult, scores can reach hundreds of thousands. This is intentional — the formula is unbounded by design for Abyss scaling. Implementations must use 64-bit integers or sufficient float precision.

- **If STR or INT is 0 (e.g., future Abyss debuff):** captain_chip_bonus = floor(0 × 0.5) = 0; captain_mult_modifier = 1.0 + (0 × 0.025) = 1.0. Both produce valid identity values. No division by zero, no negative output.

### Data Validation

- **If `hands_allowed < 1` or `score_threshold < 1` in enemy config:** Reject the enemy profile at data load time with an error. `hands_allowed = 0` produces unwinnable combat with no player agency; `score_threshold ≤ 0` produces instant victory. Both are semantically invalid.

- **If `discards_allowed` is 0 in enemy config:** Valid configuration. Player simply cannot discard. Not an error — this is a legitimate difficulty lever.

### Degenerate Strategies

- **If the player uses all 4 discards fishing for a perfect hand before playing:** Valid strategy. Discards are a limited resource; the tension between spending discards and conserving hands is a core strategic decision. No rule prevents this — it is an intended expression of the resource system.

- **If the player plays 1-card hands every turn (pure attrition):** Maximum output: High Card (5 base) + Ace (11) = 16 chips × 1.0 mult = 16/hand, or 64 over 4 hands without bonuses. Viable against tutorial enemies (threshold 40) but fails against mid/late-game (250+). The chip × mult structure inherently incentivizes multi-card hands. No fix needed.

### State Machine

- **If victory is achieved on the same hand that exhausts `hands_remaining`:** Victory check executes first in RESOLVE, before defeat check. Victory short-circuits — defeat is never evaluated. Implementation must enforce this ordering.

- **If the player attempts PLAY with 0 cards selected:** Blocked by state machine ("Cannot enter RESOLVE with 0 cards selected"). UI disables PLAY when selection count is 0. Hand evaluator should include a defensive assert against empty input.

- **If the deck runs out mid-discard-refill (e.g., discard 3 cards, only 1 remains in deck):** Draw the 1 available card. Hand now has (original hand − 3 discarded + 1 drawn) cards. Player continues in SELECT with a reduced hand. Same rules as reduced-hand draw for achievable ranks.

## Dependencies

| System | Direction | Type | Data Interface |
|--------|-----------|------|----------------|
| **Enemy Data** | Poker Combat depends on | **Hard** | Reads `enemy_config` dict: `name_key`, `score_threshold`, `hp`, `element`, `hands_allowed`, `discards_allowed`. Story combat provides inline config from chapter nodes; Abyss generates procedurally. Validation: `hands_allowed ≥ 1`, `score_threshold ≥ 1`. |
| **Companion Data** | Poker Combat depends on | **Hard** | Reads captain's `STR`, `INT` for stat bonus (F3). Reads `card_element` and `card_value` for signature card tagging. Reads `Element` enum for suit-element mapping. Captain locked at combat start. |
| **Scene Navigation** | Poker Combat calls | **Hard** | On victory/defeat, combat calls `SceneManager.change_scene()` to return to Hub or advance story. Uses `SceneId` enum and context payload. |
| **Divine Blessings** | Extends Poker Combat | **Soft** | Injects `blessing_chips` (additive) and `blessing_mult` (additive) into the scoring pipeline (F4). Slots unlock by `romance_stage`. Interface owned by Divine Blessings GDD (not yet designed). Combat functions without blessings — all blessing values default to 0. |
| **Story Flow** | Consumes Poker Combat | **Soft** | Story Flow loads combat via `SceneManager.change_scene()` with `enemy_config` context. Combat emits `combat_completed(result: {victory: bool, score: int, hands_used: int})`. Story Flow listens and advances the story node. |
| **Abyss Mode** | Extends Poker Combat | **Soft** | Abyss generates `score_threshold` targets procedurally (not from Enemy Data). Abyss shop modifies deck (remove cards, add enhancements). Abyss owns its own encounter loop; Poker Combat provides the scoring engine. Interface defined in Abyss GDD. |
| **Romance & Social** | Feeds Poker Combat | **Soft** | Social combat buffs (`social_buff_chips`, `social_buff_mult`, `combats_remaining`) read at combat start. Consumed on victory, retained on defeat. Interface defined in Romance & Social GDD. |
| **Deck Management** | Configures Poker Combat | **Soft** | Captain selection and deck composition set before combat via the Deck screen. Without Deck Management, combat uses default 52-card deck with no captain. Interface defined in Deck Management GDD. |
| **Save System** | Indirect | **Soft** | Combat state is NOT saved mid-fight. Only outcomes (gold, XP, story progress) are persisted via autoload stores after victory. No direct dependency — combat reads no saved state and writes none directly. |

**Hard dependencies (3):** Enemy Data, Companion Data, Scene Navigation — combat cannot function without these.
**Soft dependencies (6):** Divine Blessings, Story Flow, Abyss Mode, Romance & Social, Deck Management, Save System — combat functions without these (all values default to 0/identity).

**Bidirectional consistency notes:**
- Enemy Data GDD must list "consumed by: Poker Combat"
- Companion Data GDD must list "consumed by: Poker Combat"
- Scene Navigation GDD must list "called by: Poker Combat"
- Divine Blessings, Story Flow, Abyss Mode, Romance & Social, and Deck Management GDDs must list their relationship to Poker Combat when authored

## Tuning Knobs

### Combat Flow

| Knob | Value | Safe Range | Gameplay Effect |
|------|-------|-----------|-----------------|
| `DEFAULT_HANDS_ALLOWED` | 4 | 2–6 | Scoring attempt budget. Below 2: no recovery from bad draws. Above 6: scoring pressure collapses. |
| `DEFAULT_DISCARDS_ALLOWED` | 4 | 0–6 | Hand-crafting budget. 0 is valid (forces immediate play). Above 6 with 4 hands: player nearly always finds ideal hand. |
| `DEFAULT_HAND_SIZE` | 5 | **Locked** | Fixed — Flush and Straight require exactly 5 cards. Cannot change without redesigning hand rank requirements. |

### Scoring — Base Hand Values

| Knob | Value | Safe Range | Gameplay Effect |
|------|-------|-----------|-----------------|
| `HAND_CHIPS_HIGH_CARD` | 5 | 3–15 | Floor for failed-hand scoring. Too high: High Card becomes viable late-game. Too low: resist hands always clamp to 1. |
| `HAND_CHIPS_PAIR` | 10 | 8–20 | Entry-level hand. Primary score source in tutorial (threshold 40). Changes directly affect onboarding. |
| `HAND_CHIPS_ROYAL_FLUSH` | 100 | 80–150 | Peak base chips. Currently shares value with Straight Flush — widen gap if differentiation needed. |
| `HAND_MULT_HIGH_CARD` | 1.0x | 1.0–1.5x | Floor mult. Cannot go below 1.0 (overridden by additive_mult clamp). |
| `HAND_MULT_FOUR_OF_A_KIND` | 7x | 5–10x | Biggest mult jump in table (3x over the 4x tier). Reducing below 5x collapses the payoff moment of finding the 4th match. |
| `HAND_MULT_STRAIGHT_FLUSH` | 8x | 6–12x | Peak mult tier. Primary lever for late-game/Abyss scoring feel without touching per-card values. |

### Element Interactions

| Knob | Value | Safe Range | Gameplay Effect |
|------|-------|-----------|-----------------|
| `ELEMENT_WEAKNESS_CHIPS` | +25 | +10 to +50 | Per-card chip bonus for exploiting weakness. 5-card all-weak = +125 chips. Below +10: elements feel cosmetic. Above +50: trivializes thresholds. |
| `ELEMENT_WEAKNESS_MULT` | +0.5 | +0.0 to +1.5 | Per-card additive mult. 5-card = +2.5 on top of base. Above +1.5/card: element system outvalues hand rank selection. |
| `ELEMENT_RESIST_CHIPS` | -15 | -5 to -30 | Per-card resist penalty. 5-card = -75, fires chips clamp on low-base hands. Below -5: players ignore elements. Above -30: single resist card cripples low hands. |

### Enhancements

| Knob | Value | Safe Range | Gameplay Effect |
|------|-------|-----------|-----------------|
| `FOIL_CHIPS_BONUS` | +50 | +25 to +100 | Highest single-source chips. 5 Foil = +250 chips. Above +100: Foil-stacked Abyss builds outperform all mult strategies. |
| `HOLO_MULT_BONUS` | +10 | +5 to +20 | Additive mult per card. One Holo = 20 weak-element cards worth of mult. Below +5: indistinguishable from Foil. |
| `POLY_MULT_FACTOR` | x1.5 | x1.2 to x2.0 | Only multiplicative enhancement. Stacks exponentially (1.5^5 = 7.59x). Above x2.0: 5 Poly = 32x, overflows visual display in Abyss. |

### Captain Stat Bonus

| Knob | Value | Safe Range | Gameplay Effect |
|------|-------|-----------|-----------------|
| `CAPTAIN_STR_CHIP_RATIO` | 0.5 | 0.25–1.0 | In `floor(STR × ratio)`. Current range: +6 to +10 chips. Above 1.0: captain chips exceed most hand base values. |
| `CAPTAIN_INT_MULT_RATIO` | 0.025 | 0.01–0.05 | In `1.0 + (INT × ratio)`. Current range: x1.225 to x1.475. Applied after Polychrome — even modest increases amplify high-Poly hands significantly. Above 0.05: captain choice dominates all balance. |

### Critical Cross-Knob Interactions

1. **Mult chain** (`ELEMENT_WEAKNESS_MULT` × `HAND_MULT_*` × `CAPTAIN_INT_MULT_RATIO` × `POLY_MULT_FACTOR`): All multiply together. Raising any two simultaneously produces non-linear score growth.
2. **Additive chips stack** (`FOIL_CHIPS_BONUS` + `ELEMENT_WEAKNESS_CHIPS`): Both add to total_chips before the mult multiplication. 5 Foil + 5 weak = +375 chips, amplified by final_mult.
3. **Clamp interaction** (`ELEMENT_RESIST_CHIPS` vs `HAND_CHIPS_HIGH_CARD`): Raising High Card chips or lowering resist penalty means the chips clamp never fires — decide if the clamp should be a felt mechanic or silent backstop.
4. **Resource ratio** (`HANDS` : `DISCARDS`): These are a ratio, not independent. 4:4 = balanced. 2:6 = more fishing, less scoring. 6:2 = more pressure, less optimization. Never tune in isolation.

## Visual/Audio Requirements

> **Design Premise:** Chips and mult are divine energy; cards are conduits; the scoring pipeline is a ritual. Effects feel warm — ember-glow, old gold, candleflame — not cold sci-fi or neon. Exception: element effects use their own saturated color vocabulary.

### Animation Constraints (Mobile)

- Max 4 active GPU particle emitters simultaneously
- Max 2 animated shaders on screen at once
- Card enhancement effects: single `CanvasItemMaterial` with custom shader, not stacked sprites
- No bloom/glow post-processing (Mobile renderer); simulate with additive-blended sprite layers (1–2 quads)
- Screen shake: translate-only, max ±6px, ≤300ms
- Number popups: Cinzel Label nodes, GPU-animated scale + opacity tween only

**Timing vocabulary:**

| Name | Duration | Easing | Usage |
|------|----------|--------|-------|
| **Snap** | 80ms | ease-out | Selection, press |
| **Beat** | 200ms | ease-in-out | Card play submission |
| **Reveal** | 400ms | ease-out + spring overshoot | Hand rank banner, victory |
| **Cascade** | 80ms/item | staggered | Per-card chip counting |
| **Sustain** | 600–800ms | hold | Post-big-scoring moments |

### Visual Feedback — Combat Events

**Card Draw:** Cards fly in from off-screen bottom, fanning into hand tray. Cascade timing (80ms stagger). Arc trajectory. Start 0.7 scale, spring settle to 1.0 from 1.06. Total: ~480ms. Enhancement effects activate on card landing.

**Card Selection:** Selected card rises 14px. Snap timing. 2px gold border (`ACCENT_GOLD`) activates. Deselected cards dim to `BG_SECONDARY`. Haptic: medium (30ms) on select/deselect.

**Card Play:** Selected cards animate to central scoring tray (top 30%). Beat timing. Non-selected cards slide out and fade. 3px gold border on tray. Haptic: heavy (50ms).

**Hand Rank Reveal:** Cinzel banner slides down. Reveal timing. `ACCENT_GOLD_BRIGHT`, Cinzel 40px. Scale overshoot by tier: High Card–Two Pair = 1.0×; Three of a Kind–Full House = 1.04×; Four of a Kind–Royal Flush = 1.08× + radial gold burst. Banner holds 400ms before scoring begins.

**Scoring Cascade:** Fast chain — each source resolves in ~100ms, full pipeline <2 seconds. Two counters (CHIPS left, MULT right, × between, total below in Cinzel 32px gold). Per-card: card highlights gold, chip value pops above it. Enhancements: shimmer + value pop. Captain: 64×64 companion icon flashes, bonus pops in element-tinted gold. Final score flashes and scales 1.0→1.1→1.0 (Beat timing).

**Element Weakness (+25 chips, +0.5 mult):** Elemental flare per weak card — simultaneous, 300ms:

| Element | VFX | Color |
|---------|-----|-------|
| Fire | UV-scrolling flame texture strip | `#F24D26` |
| Water | Ripple ring expanding from card center | `#338CF2` |
| Earth | 4–6 leaf sprites radiating outward | `#73BF40` |
| Lightning | 3-frame crackle sprite sheet | `#CCAA33` |

Number pop: "+25" in element foreground color (not gold). HP bar flashes element color (200ms, 0.4 opacity).

**Element Resistance (−15 chips):** Card border desaturates to `ACCENT_GOLD_DIM`. Red-black overlay (30% opacity, 200ms fade). "−15" in `STATUS_ERROR` red, floats *down* 10px. No flare — resistance is absence, not counter-force.

**Enhancement Visual Treatments:**

| Enhancement | Idle Effect | Activation Effect | Badge |
|-------------|------------|-------------------|-------|
| **Foil** | Horizontal shimmer band (additive shader, 2s loop, 0.25 opacity) | Shimmer brightens to 0.7, fast sweep (400ms) | "F" in `ACCENT_GOLD` |
| **Holographic** | Rainbow iridescent overlay (soft-light shader, 4s loop, 0.3 opacity) | Opacity peaks 0.6 with hue rotation (400ms) | "H" in rainbow gradient |
| **Polychrome** | Full-card hue rotation (±15°, 6s loop) | 360° prismatic spin (600ms) | "P" with prismatic diamond |

All badges: top-right with 4px offset from card value, 12px Cinzel.

**Captain Stat Bonus:** 64×64 cropped companion icon flashes (400ms, Reveal timing). "+N" chips and "×N.NNN" mult pop in element-tinted gold near the icon.

**Victory (sequence):**
1. Score total flashes gold, scales to 1.15×, holds 400ms
2. Gold horizontal wipe sweeps left→right (300ms additive sprite, 600ms total fade)
3. Banner transitions to "VICTORY" in `STATUS_SUCCESS` green, Cinzel 40px
4. 64×64 companion portrait — pleased/excited mood variant
5. 20–30 gold particle burst from score counter (GPU ParticleSystem2D)

Haptic: double heavy pulse (50ms, 400ms gap, 50ms).

**Defeat (not punishing — resource exhaustion):**
1. Scoring tray dims (`BG_TERTIARY` overlay, 0→0.6 opacity, Beat timing)
2. Banner shows "EXHAUSTED" in `TEXT_SECONDARY`, Cinzel 24px (not red)
3. 64×64 companion portrait — worried/concerned mood variant
4. RETRY (primary gold) and RETREAT (secondary gold) buttons slide up from bottom

No screen shake, no red flash. Emotional tone: "you were close, try again."

**Score Accumulation / Enemy HP Bar:**
- Full-width bar (minus 32px gutters), 8px height, 8px radius
- Red fill (`#D94040`) = enemy HP. Gold fill (`ACCENT_GOLD`) = player score, overlaid from left
- Gold extends right over 600ms (ease-out) per hand resolved. Score counter counts up during animation
- Element weakness: HP bar red fill briefly flashes element color (200ms, 0.4 opacity)

**Discard:** Cards desaturate (100ms), slide off-screen left (Beat timing). Replacements fly in with tighter stagger (60ms). Discard counter decrements immediately before animation completes.

### Element Visual Language on Cards

**Suit symbols (element-colored):**

| Suit | Element | Color | Variant |
|------|---------|-------|---------|
| Hearts | Fire | `#F24D26` | Subtle flame-tip on heart top point |
| Diamonds | Water | `#338CF2` | Teardrop orientation, elongated vertically |
| Clubs | Earth | `#73BF40` | Classic trefoil, element-colored |
| Spades | Lightning | `#CCAA33` | Zigzag point variant (reads as spade at 8px) |

**Card tint:** Element background color at 8% opacity (rest), 20% (selected), 40% (element trigger → returns to 20%).

**Element indicator:** 2px colored horizontal line below suit symbol for secondary readout at small sizes.

### Audio Direction

**Combat BGM (2-layer dynamic mix):**
- **Base layer** (always): Sparse low drone — sustained minor string chord, slow tremolo (0.3Hz). Volume: 0.4. Ancient ceremony under pressure.
- **Tension layer** (scales with pressure): Rhythmic low drum at 60BPM. Volume by `hands_remaining`: 4→0.0, 3→0.2, 2→0.5, 1→0.8.
- **Boss layer** (boss enemies only): Distant dissonant choir vocalization.
- Transitions: 1s fade-in at SETUP, 2s fade-out on victory/defeat.

**SFX Spec** (mono, 24-bit, 44.1kHz, −6dBFS peak):

| Event | Sound Description | Duration |
|-------|-------------------|----------|
| Card land | Soft "fwip" — heavy card on velvet. ±3 semitone pitch variation per card | 80ms |
| Card select | Soft "thunk" + faint gold ring tail | 100ms |
| Card deselect | Same at 0.8 pitch, 0.7 volume | 100ms |
| Card play submit | Stone-sliding bass thud (marble slab) | 150ms |
| Rank: High Card–Pair | Single low muted bell | 300ms |
| Rank: Two Pair–Three of a Kind | Two ascending bells (minor 3rd) | 400ms |
| Rank: Straight–Full House | Three ascending bells (major triad) | 500ms |
| Rank: Four of a Kind | Deep resonant gong, slow decay | 800ms |
| Rank: Straight/Royal Flush | Gong + layered choir tone | 1000ms |
| Chip tick (per-card) | Short high metallic click | 30ms |
| Foil trigger | Low metallic shimmer | 200ms |
| Holo trigger | Rising shimmer, 3-note rapid ascent | 200ms |
| Poly trigger | Prismatic chord burst with harmonic wash | 300ms |
| Fire weakness | Quick "whoosh-crack" | 250ms |
| Water weakness | Low liquid resonance — drop in stone basin | 300ms |
| Earth weakness | Deep stone-thud with organic quality | 250ms |
| Lightning weakness | Sharp crackle-snap | 150ms |
| Element resistance | Muted low thud — absorbed, not deflected | 100ms |
| Captain bonus | Soft two-note ascending chime (pitch per captain) | 200ms |
| Victory | Gold orchestral fanfare — strings + brass, 1s build + 2s peak | 3000ms |
| Defeat | Descending low string phrase, unresolved chord | 2000ms |
| Discard | Card-flutter, slightly pitched down | 100ms |

## UI Requirements

> **Viewport:** 430×932 portrait. All measurements in logical pixels at 1× scale.

### Screen Zones

| Zone | Y Range | Height | Contents |
|------|---------|--------|----------|
| **Enemy Info** | 0–120 | 120px | Enemy name, element icon, HP bar, score counter |
| **Scoring Tray** | 120–420 | 300px | Played cards, hand rank banner, chips/mult counters, scoring cascade |
| **Hand Area** | 420–800 | 380px | 5-card hand fan, card selection, sort toggle |
| **Action Bar** | 800–932 | 132px | PLAY button, DISCARD button, hand/discard counters |

### Enemy Info Zone (0–120px)

- Enemy name: Cinzel 20px, `TEXT_PRIMARY`, left-aligned at x=16
- Element icon: 24×24 colored circle with element symbol, right of name
- HP bar: full width minus 32px gutters, 8px height, y=80. Red fill + gold score overlay
- Score text: "1,234 / 5,000" below HP bar in Nunito Sans 16px, `TEXT_SECONDARY`

### Scoring Tray (120–420px)

- Played cards: up to 5 cards in horizontal row, centered. Card size: 56×80px
- Hand rank banner: Cinzel 40px, centered, y=140
- Chips/Mult counters: Nunito Sans 20px Bold, flanking "×" symbol, y=340
- Running total: Cinzel 32px, `ACCENT_GOLD_BRIGHT`, centered, y=380
- Captain icon: 64×64 cropped bust, appears at x=16, y=260 during captain bonus

### Hand Area (420–800px)

- 5 cards fanned in slight arc. Card size: 64×90px (exceeds 44×44px touch minimum)
- Selected cards rise 14px with gold border
- Sort toggle: 44×44px icon button at top-right (y=430, x=370)
- Reduced hand (<5 cards): cards spread to fill width, maintaining 64×90px per card

### Action Bar (800–932px)

- PLAY button: left side, 190×56px, primary gold style. Disabled when 0 cards selected
- DISCARD button: right side, 190×56px, secondary style. Disabled when `discards_remaining == 0`
- 16px gap between buttons, 16px side gutters
- Hand counter: "Hands: 3" — Nunito Sans 14px, `TEXT_SECONDARY`, above PLAY
- Discard counter: "Discards: 2" — same style, above DISCARD
- Counters update immediately on action commit (before animation completes)

### State-Dependent UI

| State | PLAY | DISCARD | Hand Cards | Scoring Tray |
|-------|------|---------|------------|--------------|
| SELECT (no selection) | Disabled | Enabled | Interactive | Empty |
| SELECT (1+ selected) | Enabled (gold) | Enabled | Interactive | Empty |
| SELECT (discards=0) | Per selection | Disabled (greyed) | Interactive | Empty |
| RESOLVE | Hidden | Hidden | Non-interactive | Active (scoring) |
| VICTORY | Hidden | Hidden | Non-interactive | Shows result |
| DEFEAT | Becomes "RETRY" | Becomes "RETREAT" | Non-interactive | Dimmed |

### Accessibility

- All text meets 4.5:1 contrast ratio (cream on brown passes)
- Score numbers use tabular/monospace figures (no layout shift during counting)
- Color is never sole indicator — element icons pair color with shape (flame, drop, leaf, bolt)
- Button states communicated by both color AND opacity change
- All interactive elements ≥44×44px touch target

## Acceptance Criteria

> All criteria below are **Logic** story type — **BLOCKING** gate. Automated unit test evidence required in `tests/unit/poker_combat/` for each criterion before any Poker Combat story can be marked Done.

### Deck Composition (Rule 1)

- **AC-01**: **GIVEN** a new combat encounter is initialized, **WHEN** the deck is built, **THEN** it contains exactly 52 cards (4 suits × 13 values, 2 through Ace=14), no duplicates, no jokers, no wildcards.

### Enemy Config Validation (Rule 2)

- **AC-02**: **GIVEN** a valid enemy config (`name_key`, `score_threshold=40`, `hp=40`, `element=None`, `hands_allowed=4`, `discards_allowed=4`), **WHEN** combat is initialized, **THEN** all fields are read without error and the encounter begins in SETUP state.
- **AC-03**: **GIVEN** an enemy config with `hands_allowed=0`, **WHEN** the profile is loaded at data load time, **THEN** the system rejects the profile with an error and combat does not begin.
- **AC-04**: **GIVEN** an enemy config with `score_threshold=0`, **WHEN** the profile is loaded at data load time, **THEN** the system rejects the profile with an error and combat does not begin.
- **AC-05**: **GIVEN** an enemy config with `discards_allowed=0`, **WHEN** combat is initialized, **THEN** combat begins normally and the DISCARD action is disabled from the start.

### Turn Flow State Machine (Rule 3)

- **AC-06**: **GIVEN** a valid combat encounter, **WHEN** the encounter is started, **THEN** the system transitions through states in order: SETUP → DRAW → SELECT, and after a PLAY action: SELECT → RESOLVE → DRAW (or VICTORY/DEFEAT), with no skipped states.
- **AC-07**: **GIVEN** `discards_remaining=0` and SELECT state, **WHEN** the player attempts DISCARD, **THEN** the transition is blocked and the game remains in SELECT.
- **AC-08**: **GIVEN** SELECT state with 0 cards selected, **WHEN** the player attempts PLAY, **THEN** the transition is blocked and RESOLVE is not entered.

### Hand Ranks (Rule 4)

- **AC-09**: **GIVEN** each of the 10 poker hand ranks played in isolation (no enhancements, no captain, enemy element=None), **WHEN** each hand is evaluated, **THEN** the system identifies the rank correctly with these base values:

  | Hand | Base Chips | Base Mult |
  |------|-----------|-----------|
  | High Card | 5 | 1x |
  | Pair | 10 | 2x |
  | Two Pair | 20 | 2x |
  | Three of a Kind | 30 | 3x |
  | Straight | 30 | 4x |
  | Flush | 35 | 4x |
  | Full House | 40 | 4x |
  | Four of a Kind | 60 | 7x |
  | Straight Flush | 100 | 8x |
  | Royal Flush | 100 | 8x |

- **AC-10**: **GIVEN** the player plays Ace, 2, 3, 4, 5 of mixed suits, **WHEN** the hand is evaluated, **THEN** it is recognized as a Straight (base chips=30, base mult=4x).
- **AC-11**: **GIVEN** the player selects 4 cards that would form a Flush or Straight if a 5th were added, **WHEN** the hand is played, **THEN** it is NOT evaluated as Flush or Straight; the highest achievable rank from the 4 cards is used.

### Per-Card Chips — Formula F1

- **AC-12**: **GIVEN** single-card plays with no enhancements, no captain, enemy element=None, **WHEN** each card value is played as High Card, **THEN** card_chips values are: 2–10=face value, J/Q/K=10, Ace=11.

### Scoring Pipeline — Formula F4

- **AC-13**: **GIVEN** a hand with Pair (10 chips, 2x), 1 Foil (+50), 1 Holo (+10 mult), 1 Polychrome (×1.5), no captain, no elements, **WHEN** scored, **THEN** pipeline resolves: chips additive → mult additive → mult multiplicative → floor. Foil adds to chips, Holo adds to mult, Polychrome multiplies mult.
- **AC-14**: **GIVEN** 5 resist-element cards with no other chip sources sufficient to offset, **WHEN** scored, **THEN** `max(1, total_chips)` clamp fires and `total_chips = 1`.
- **AC-15**: **GIVEN** a scenario where additive mult sources sum to ≤ 0, **WHEN** scored, **THEN** `max(1.0, additive_mult)` clamp fires before Polychrome and captain are applied.
- **AC-16**: **GIVEN** Worked Example A (Pair of 7s, cards 7/7/9/5/3, no captain, no enhancements, enemy element=None, threshold=40), **WHEN** scored, **THEN** score = floor(41 × 2.0) = **82**.
- **AC-17**: **GIVEN** Worked Example B (Flush all Hearts, Hipolita captain STR=20/INT=9, 1 Foil King, enemy=Gaia Spirit Earth threshold=130), **WHEN** scored, **THEN** total_chips=258, additive_mult=6.5, final_mult=7.9625, score = floor(258 × 7.9625) = **2,054**.

### Element Interactions — Formula F2

- **AC-18**: **GIVEN** enemy element=Earth (weak to Fire), player plays 3 Hearts (Fire) + 2 neutral cards, **WHEN** scored, **THEN** element_chips = +75, element_mult = +1.5.
- **AC-19**: **GIVEN** enemy element=Earth, player plays 2 Clubs (Earth = resist), **WHEN** scored, **THEN** element_chips = −30, element_mult = 0 (no mult penalty on resist).
- **AC-20**: **GIVEN** enemy element=None, player plays 5 Hearts (Fire), **WHEN** scored, **THEN** zero element contribution to chips and mult.
- **AC-21**: **GIVEN** enemies with each of the four elements, **WHEN** a weak-suit card and a resist-suit card are each played, **THEN** the element cycle resolves correctly: Fire weak to Water, Water weak to Lightning, Earth weak to Fire, Lightning weak to Earth.

### Captain Stat Bonus — Formula F3

- **AC-22**: **GIVEN** Captain Artemisa (STR=17), **WHEN** any hand is played, **THEN** captain_chip_bonus = floor(17 × 0.5) = 8, added once to total_chips.
- **AC-23**: **GIVEN** Captain Atenea (INT=19) and 1 Polychrome card, **WHEN** scored, **THEN** final_mult = additive_mult × 1.5 (Polychrome) × 1.475 (captain). Captain applied after Polychrome.
- **AC-24**: **GIVEN** no captain assigned, **WHEN** any hand is played, **THEN** captain_chip_bonus = 0 and captain_mult_modifier = 1.0.

### Card Enhancements (Rule 8)

- **AC-25**: **GIVEN** 2 Foil cards in played hand, **WHEN** scored, **THEN** exactly +100 chips from Foil in the additive phase.
- **AC-26**: **GIVEN** 2 Holo cards in played hand, **WHEN** scored, **THEN** exactly +20 additive mult from Holo before Polychrome.
- **AC-27**: **GIVEN** 2 Polychrome cards in played hand, **WHEN** scored, **THEN** multiplicative stacking = 1.5 × 1.5 = ×2.25 (not ×3.0).

### Discard Rules (Rule 9)

- **AC-28**: **GIVEN** `discards_remaining=4`, player selects 3 cards to discard from a hand of 5, **WHEN** DISCARD taken, **THEN** 3 cards removed, 3 replacements drawn, hand returns to 5, `discards_remaining` becomes 3.
- **AC-29**: **GIVEN** 0 cards selected, **WHEN** DISCARD attempted, **THEN** action blocked, counter not decremented.

### Victory and Defeat — Formula F5

- **AC-30**: **GIVEN** `score_threshold=100`, `current_score=95` after two hands, **WHEN** third hand scores 12 (total 107), **THEN** VICTORY immediately after RESOLVE; remaining hands forfeited.
- **AC-31**: **GIVEN** `hands_remaining=1` and `current_score < threshold`, **WHEN** final hand brings `current_score ≥ threshold`, **THEN** outcome is VICTORY (victory check before defeat check).
- **AC-32**: **GIVEN** `hands_remaining=1` and `current_score < threshold`, **WHEN** final hand scored and `current_score` still below threshold, **THEN** DEFEAT. Social buff NOT consumed, persists to next attempt.

### Edge Cases

- **AC-33**: **GIVEN** deck fully exhausted (0 cards) at DRAW, **WHEN** DRAW attempts to deal, **THEN** combat ends immediately in DEFEAT without entering SELECT.
- **AC-34**: **GIVEN** only 3 cards remain in deck, **WHEN** DRAW deals, **THEN** exactly 3 cards dealt, SELECT entered with 3-card hand, Flush/Straight unachievable.
- **AC-35**: **GIVEN** 5 resist-element cards played, base chips insufficient to offset, **WHEN** scored, **THEN** chips clamp fires, `total_chips = 1`, `score ≥ 1`.
- **AC-36**: **GIVEN** player discards 3 cards but only 1 remains in deck, **WHEN** replacements drawn, **THEN** exactly 1 card drawn, hand = (5 − 3 + 1) = 3 cards.

### Coverage Summary

| Category | ACs | Rules | Formulas | Gate |
|----------|-----|-------|----------|------|
| Deck Composition | AC-01 | R1 | — | BLOCKING |
| Enemy Config | AC-02–05 | R2 | — | BLOCKING |
| Turn Flow | AC-06–08 | R3 | — | BLOCKING |
| Hand Ranks | AC-09–11 | R4 | F1 | BLOCKING |
| Per-Card Chips | AC-12 | R4 | F1 | BLOCKING |
| Scoring Pipeline | AC-13–17 | R5 | F4 | BLOCKING |
| Elements | AC-18–21 | R6 | F2 | BLOCKING |
| Captain Bonus | AC-22–24 | R7 | F3 | BLOCKING |
| Enhancements | AC-25–27 | R8 | — | BLOCKING |
| Discards | AC-28–29 | R9 | — | BLOCKING |
| Victory/Defeat | AC-30–32 | R10 | F5 | BLOCKING |
| Edge Cases | AC-33–36 | All | F4 clamps | BLOCKING |

**Rule 11 (Card Sorting)** is display-only — Visual/Feel advisory gate, covered by manual walkthrough.

## Cross-References

- **Game Concept**: `design/gdd/game-concept.md` — Pillar 1 (Poker Combat), core loop definition, MDA framework
- **Enemy Data GDD**: `design/gdd/enemy-data.md` — enemy profile schema consumed by this system
- **Companion Data GDD**: `design/gdd/companion-data.md` — captain stats, element, card_value consumed by this system
- **Scene Navigation GDD**: `design/gdd/scene-navigation.md` — SceneManager interface for victory/defeat transitions
- **Systems Index**: `design/gdd/systems-index.md` — system #7, MVP priority, Core layer
- **Divine Blessings GDD** (not yet designed) — extends scoring pipeline with blessing_chips/blessing_mult
- **Abyss Mode GDD** (not yet designed) — extends combat with procedural thresholds, deck modification, shop
- **Romance & Social GDD** (not yet designed) — feeds social combat buffs
- **Deck Management GDD** (not yet designed) — configures captain selection and deck composition
- **Story Flow GDD** (not yet designed) — orchestrates combat encounters within chapter nodes

## Open Questions

| # | Question | Owner | Target |
|---|----------|-------|--------|
| OQ-1 | Should Divine Blessings be allowed to produce negative `blessing_mult`? The additive_mult clamp protects against it, but prohibiting negative values in the Blessings GDD is a belt-and-suspenders option. | game-designer | Divine Blessings GDD authoring |
| OQ-2 | What are the gold and XP reward values on victory? Combat specifies rewards are granted but doesn't define amounts — these belong in Story Flow or a rewards config. | game-designer | Story Flow / Economy GDD |
| OQ-3 | Should signature cards (companion's suit + card_value) have any special visual or scoring effect, or are they purely tagged for future use? Currently they play identically to other cards. | game-designer | Deck Management or Divine Blessings GDD |
| OQ-4 | How does the combat screen handle safe area insets on notched phones (iPhone notch, Android camera cutout)? The Enemy Info zone at y=0–120 may overlap system UI. | ux-designer | UX spec for combat screen |
| OQ-5 | Should the scoring cascade speed be configurable by the player (accessibility: some players may want to skip or speed through animations)? | ux-designer | UX spec or Accessibility requirements |
