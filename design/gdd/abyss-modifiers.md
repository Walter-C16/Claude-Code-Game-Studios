# Abyss Modifiers

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-10
> **Implements Pillar**: Pillar 4 — Roguelike Abyss for Replayability

## Summary

Abyss Modifiers are 10 weekly rotating rule-change effects that alter how Abyss Mode plays. One modifier is active at a time, rotating Monday 00:00 UTC. Modifiers affect scoring multipliers, hand size, element behavior, timer pressure, or economy rules. They apply globally to every ante in the active run and cannot be opted out of.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `Abyss Mode`

---

## Overview

Abyss Modifiers introduce a weekly layer of variation to Abyss runs without changing the underlying poker hand mechanics. Each of the 10 modifiers changes one to two rules governing the run: how elements interact, how much time or how many hands the player has, how scoring scales, or how the economy behaves. Modifiers are presented on the Abyss entry screen before the player commits to a run, giving them full information to decide whether to enter. Modifiers rotate weekly on a fixed deterministic schedule (week number modulo 10), making it possible for experienced players to anticipate which modifier is coming. The rotation cycle repeats after 10 weeks. Each modifier has a defined `modifier_id`, a display name, a one-sentence description, and a structured effect dictionary that the Abyss Mode system reads to mutate run parameters.

---

## Player Fantasy

**"The Rules Changed. You Didn't."**

A modifier is not a punishment — it is a premise. "This week, every enemy burns with fire." "This week, you have half as many hands but your mult is doubled." The player's job is not to survive despite the modifier, but to play the game that modifier creates.

Experienced players look forward to the weekly rotation the way competitive players look forward to a ranked season change. "Is this a Fire Storm week? Great — Nyx's Water blessings counter this perfectly." Modifiers make companion investment more legible: some modifiers reward players who have deeply invested in specific companions, giving the romance system a new axis of expression.

The weekly cadence also creates shared experience among players — this week, everyone is facing the same Fire Storm. That shared constraint is a form of fellowship even in a single-player game.

*Pillar 4: "Weekly modifiers keep it fresh."*

---

## Detailed Rules

### Rule 1 — Modifier Rotation

```
active_modifier_index = current_week_number % MODIFIER_COUNT
active_modifier = MODIFIER_LIST[active_modifier_index]
```

Where `current_week_number` is the ISO 8601 week number (Monday-anchored). `MODIFIER_COUNT = 10`. The rotation is deterministic and the same for all players — no server required.

The modifier rotates at Monday 00:00 UTC. An active Abyss run stores its modifier at run start and is not affected by mid-run rotation (see abyss-mode.md EC-5).

### Rule 2 — Modifier Catalog

Each modifier entry in `assets/data/abyss_modifiers.json` contains:
- `modifier_id` (String) — unique key
- `display_name_key` (String) — i18n key for localized name
- `description_key` (String) — i18n key for one-sentence description
- `effects` (Dictionary) — structured rule mutations (see per-modifier definitions)
- `week_index` (int 0–9) — position in rotation

#### Modifier 1: Fire Storm
**Week index**: 0
**Display name**: "Fire Storm"
**Description**: "All enemies burn with the Fire element."

```
effects: {
  "enemy_element_override": Element.FIRE
}
```

All ante enemies have `element = FIRE` regardless of their base definition. Earth-suit cards (Clubs) resist Fire (from the element table in poker-combat.md), so Earth-heavy hands gain an advantage. Fire-element blessings (Hipolita's kit) that trigger on enemy Fire affinity are also activated.

**Strategic impact**: Rewards Earth-suit hand building and Hipolita companion investment. Players with Hipolita at high romance stage find this modifier favorable.

#### Modifier 2: Glass Cannon
**Week index**: 1
**Display name**: "Glass Cannon"
**Description**: "Multiplier doubled, but you only have 2 hands per ante."

```
effects: {
  "mult_global_multiplier": 2.0,
  "hands_allowed_override": 2
}
```

`base_mult` and all additive mult sources are multiplied by 2.0 before the final `chips * mult` calculation. `hands_allowed` is set to 2 for every ante.

Formula: `adjusted_total_mult = total_mult * 2.0`

**Strategic impact**: Forces high-risk play. Players must play their best possible hand in the first two attempts. Rewards Polychrome cards (mult multiplier) and blessing kits that boost mult (Atenea, Nyx). Punishes inconsistent hands.

#### Modifier 3: Lucky Draw
**Week index**: 2
**Display name**: "Lucky Draw"
**Description**: "Hand size increased by 2 — draw 7 cards instead of 5."

```
effects: {
  "hand_size_bonus": 2
}
```

`draw_count` is set to 7 (standard 5 + 2). Players select 1-5 cards to play from a hand of 7. Discard returns to a 5-card hand (discard 2 to reach 5).

**Strategic impact**: Significantly increases odds of drawing high-rank hands (Straight, Flush, Full House). Reduces variance. Rewards players who know which card combinations to select from a larger pool. Generally favorable modifier — slightly reduced strategic tension because good hands appear more frequently.

#### Modifier 4: Poverty
**Week index**: 3
**Display name**: "Poverty"
**Description**: "Start with 0 gold. Shop purchases are impossible."

```
effects: {
  "starting_gold": 0,
  "gold_per_hand": 0,
  "gold_ante_bonus": 0,
  "shop_disabled": true
}
```

All gold generation during the run is set to 0. The between-ante shop screen is still shown but all items display "Out of Stock" and the shop description reads: "The wealth of Olympus is ash this week." No purchases can be made. Ante structure and thresholds are unchanged.

**Strategic impact**: Removes the entire shop layer. Runs succeed or fail purely on the persistent layer (blessings, equipment) and the player's poker skill. Reveals the baseline power of the player's relationship investment without augmentation.

#### Modifier 5: Blessed
**Week index**: 4
**Display name**: "Blessed"
**Description**: "One random blessing is active regardless of romance stage."

```
effects: {
  "free_blessing_count": 1,
  "free_blessing_source": "random_from_all"
}
```

At run start, one blessing is selected at random from the full pool of 20 (all companions, all stages). It is injected into the scoring pipeline as if the player had unlocked it normally. If the player already has this blessing from their romance progress, it does not double-apply — a different random blessing is selected.

**Strategic impact**: Gives low-romance-stage players a taste of the blessing system. Gives high-stage players an extra bonus. Random selection means the player cannot predict what they will receive — adds a lottery element to run setup.

#### Modifier 6: Cursed
**Week index**: 5
**Display name**: "Cursed"
**Description**: "All elemental resistance penalties are doubled."

```
effects: {
  "resist_penalty_multiplier": 2.0
}
```

When a player plays a hand that the enemy element resists (e.g., Fire enemy resists Water-suit cards), the resistance penalty to chips is doubled. See poker-combat.md for the base resistance formula.

If base resist penalty = -15% chip reduction:
`adjusted_resist = base_resist * 2.0 = -30%`

**Strategic impact**: Punishes playing off-element hands against a themed enemy. Rewards players who have carefully mapped suit-element relationships and avoid mismatched plays. Increases the value of card removal (shop) to purge off-element cards.

#### Modifier 7: Speed Run
**Week index**: 6
**Display name**: "Speed Run"
**Description**: "30-second timer per hand. Time expires = hand is auto-played."

```
effects: {
  "hand_timer_seconds": 30,
  "auto_play_on_timeout": true
}
```

A 30-second countdown timer is visible during each hand. If the timer expires before the player selects and plays a hand, the system auto-plays: selects the first 5 cards in hand order and plays them as-is (whatever hand rank they form). Discards do not have a timer — only hand plays.

**Strategic impact**: Introduces execution pressure. Tests whether the player can evaluate a 7-card hand and make a selection within 30 seconds. Rewards players who have internalized hand rankings intuitively. Auto-play produces suboptimal outcomes, creating genuine stakes for timer management.

**Implementation note**: The 30-second timer must display clearly (countdown bar + number). Auto-play is never silent — a brief flash animation signals that a timeout occurred. Timer is paused when the game is minimized.

#### Modifier 8: High Stakes
**Week index**: 7
**Display name**: "High Stakes"
**Description**: "All score thresholds increased by 50%."

```
effects: {
  "threshold_multiplier": 1.5
}
```

Applied to all 8 antes:

```
adjusted_threshold[i] = round(base_threshold[i] * 1.5)
```

| Ante | Base | High Stakes |
|------|------|-------------|
| 1 | 300 | 450 |
| 2 | 500 | 750 |
| 3 | 800 | 1,200 |
| 4 | 1,200 | 1,800 |
| 5 | 1,800 | 2,700 |
| 6 | 2,700 | 4,050 |
| 7 | 4,000 | 6,000 |
| 8 | 6,000 | 9,000 |

**Strategic impact**: Hardest modifier in the pool. Ante 7 and 8 require scores that exceed the base run's Ante 8. Only strongly-blessed, well-equipped players can complete a full High Stakes run. Intended as the prestige challenge modifier.

#### Modifier 9: Collector
**Week index**: 8
**Display name**: "Collector"
**Description**: "Earn bonus gold for each unique hand rank played per ante."

```
effects: {
  "unique_hand_rank_bonus_gold": 5,
  "unique_tracking_scope": "per_ante"
}
```

Each ante, the system tracks which hand ranks the player has played (Pair, Two Pair, Three of a Kind, Straight, Flush, Full House, Four of a Kind, Straight Flush, Royal Flush, High Card). The first time each rank is played within an ante, +5 gold is awarded in addition to the base +2 per hand.

Maximum bonus gold per ante: 9 unique ranks * 5 = +45 gold (if all 9 non-High-Card ranks are played, which requires all 4 hands to yield unique ranks — achievable with Lucky Draw but rare otherwise).

Tracker resets each ante.

**Strategic impact**: Rewards hand variety over repetition. Players are incentivized to play different hand types rather than spamming the same high-scoring rank. Increases gold acquisition for versatile players. Synergizes well with Lucky Draw modifier (but not available simultaneously in the current rotation).

#### Modifier 10: Mirror
**Week index**: 9
**Display name**: "Mirror"
**Description**: "Enemy element matches your combat captain's element."

```
effects: {
  "enemy_element_source": "captain_element"
}
```

All ante enemies inherit the element of the player's active combat captain. If Artemis (Earth) is captain, all enemies are Earth. If no captain is set, enemies are None/neutral (no element interactions).

**Strategic impact**: Creates a self-reinforcing or self-countering loop depending on which suit the player's blessings favor. If the player's captain is Artemis (Earth) and their deck is Earth-heavy (Clubs), the enemy will also be Earth — meaning Earth-vs-Earth hands have no resistance advantage. This forces players to either switch captain, diversify their hand composition, or accept the neutral-element combat. Rewards companion flexibility (players who have invested in multiple companions have more options).

---

## Formulas

### Modifier Rotation

```
active_modifier_index = iso_week_number(current_date_utc) % 10
active_modifier = MODIFIER_LIST[active_modifier_index]
```

ISO week number is Monday-anchored. `MODIFIER_COUNT = 10` (constant).

**Example**: Week 47 of 2026 → `47 % 10 = 7` → Modifier index 7 → High Stakes.

### Glass Cannon Adjusted Mult

```
adjusted_total_mult = (base_mult + enhancement_mult + captain_mult_bonus + amulet_mult_bonus + blessing_mult) * 2.0
final_score = total_chips * adjusted_total_mult
```

### High Stakes Threshold

```
adjusted_threshold[i] = round(ANTE_THRESHOLDS[i] * THRESHOLD_MULTIPLIER)
```

Where `THRESHOLD_MULTIPLIER = 1.5` and `ANTE_THRESHOLDS = [300, 500, 800, 1200, 1800, 2700, 4000, 6000]`.

### Collector Bonus Gold Per Ante

```
bonus_gold = count(unique_hand_ranks_played_this_ante) * UNIQUE_RANK_BONUS
where UNIQUE_RANK_BONUS = 5
```

### Cursed Resist Penalty

```
adjusted_resist_penalty = base_resist_penalty * RESIST_PENALTY_MULTIPLIER
where RESIST_PENALTY_MULTIPLIER = 2.0
```

---

## Edge Cases

**EC-1: Mirror modifier with no captain selected.**
`enemy_element_source = captain_element` resolves to `Element.NONE` when no captain is active. All enemies are neutral. No element interactions fire. Effectively disables the element system for the run — a valid state that makes Mirror a neutral modifier for unprepared players.

**EC-2: Blessed modifier selects a blessing already owned by the player.**
System re-rolls. Maximum 5 re-rolls before giving up and awarding no bonus blessing. If all 20 blessings are owned (fully maxed player at Devoted with all companions), the free blessing is not awarded and a debug log is written. This edge case only affects players who have completed all companion arcs — they are unlikely to need the bonus.

**EC-3: Speed Run modifier — app backgrounded mid-timer.**
Timer is paused when the app loses focus (same as any other time-based system). On foreground restore, the timer resumes from where it paused. This prevents background-switch exploiting.

**EC-4: Speed Run modifier — auto-play with fewer than 5 cards in hand.**
If the deck is nearly exhausted, the hand may have fewer than 5 cards. Auto-play selects all available cards (same behavior as manual play with a short hand). This is consistent with standard draw rules.

**EC-5: Two modifiers in the same rotation slot (data error).**
Each modifier has a unique `week_index` (0–9). If a data error results in two modifiers sharing a week_index, the system uses the first one in list order and logs a warning. Rotation still functions — only one modifier applies per run.

**EC-6: High Stakes + Glass Cannon in the same run.**
These are different weeks (indices 7 and 1 respectively) and cannot be simultaneously active by design. The rotation is weekly-exclusive — one modifier per run, always.

**EC-7: Collector modifier — High Card hand played.**
High Card is a valid poker hand (any 5 cards that don't form another rank). If the player plays High Card, it counts as a unique rank for Collector purposes and awards the +5 gold bonus on first play. High Card is intentionally included — it rewards players for understanding that even a weak hand contributes to the collector bonus.

**EC-8: Lucky Draw modifier — player draws more than 5 cards but the deck has fewer than 7.**
Draw resolves to min(7, remaining_deck_size). If 3 cards remain, player draws 3 and plays from that hand. Standard short-deck rules apply.

---

## Dependencies

### Systems this depends on

| System | Usage | Doc |
|--------|-------|-----|
| **Abyss Mode** | Modifiers apply within a run as rule mutations — Abyss Mode reads the modifier dict at run start and passes effect parameters to combat and shop subsystems | design/gdd/abyss-mode.md |
| **Poker Combat** | Reads modifier effects that alter hand_size, hands_allowed, resist penalties, mult multipliers, and enemy element overrides | design/gdd/poker-combat.md |

### Systems that depend on this

None — Abyss Modifiers is a pure dependency of Abyss Mode. No other system reads modifier state.

### Integration Contract

**Provides to Abyss Mode**: `get_active_modifier() -> Dictionary` returning the full modifier effects dict for the current week. Called once at run start; result is stored in run state.

**Provides to Poker Combat**: Effect parameters passed through Abyss Mode's combat configuration — Abyss Modifiers does not call Poker Combat directly.

---

## Tuning Knobs

| Knob | Category | Default | Range | Notes |
|------|----------|---------|-------|-------|
| `MODIFIER_COUNT` | Gate | 10 | 10 | Fixed to rotation list length. Adding a modifier requires extending the list. |
| `ROTATION_PERIOD_DAYS` | Gate | 7 | 7 | Weekly rotation. Changing to daily would require significant balance re-validation. |
| `GLASS_CANNON_MULT_MULTIPLIER` | Feel | 2.0 | 1.5–3.0 | Mult bonus for Glass Cannon. Higher makes the modifier more dramatic. |
| `GLASS_CANNON_HANDS_OVERRIDE` | Gate | 2 | 1–3 | Hands allowed under Glass Cannon. 1 is extremely punishing. |
| `LUCKY_DRAW_HAND_BONUS` | Feel | 2 | 1–3 | Extra cards drawn per hand under Lucky Draw. |
| `SPEED_RUN_TIMER_SECONDS` | Gate | 30 | 15–60 | Seconds per hand in Speed Run. Below 15 is likely inaccessible for casual players. |
| `HIGH_STAKES_THRESHOLD_MULTIPLIER` | Curve | 1.5 | 1.2–2.0 | Threshold multiplier for High Stakes. Above 2.0 may make later antes impossible. |
| `COLLECTOR_UNIQUE_RANK_BONUS` | Curve | 5 | 3–10 | Gold per unique hand rank in Collector. |
| `CURSED_RESIST_MULTIPLIER` | Curve | 2.0 | 1.5–3.0 | Resistance penalty multiplier in Cursed. |
| `BLESSED_FREE_BLESSING_COUNT` | Curve | 1 | 1–2 | Number of free blessings awarded under Blessed. |

All knobs live in `assets/data/abyss_modifiers.json`.

---

## Acceptance Criteria

### Functional Criteria

- [ ] **AC-1**: `active_modifier_index = iso_week_number % 10` correctly selects one modifier. Verified with known dates — Week 1 of 2026 → index 1 → Glass Cannon.
- [ ] **AC-2**: The active modifier is displayed on the Abyss entry screen before the player confirms entering a run. Modifier name, icon, and description are shown.
- [ ] **AC-3**: The modifier ID is stored in `abyss_run_state.modifier_id` at run start. Mid-run rotation (Monday UTC crossover) does not change the stored modifier ID for the active run.
- [ ] **AC-4 — Glass Cannon**: `total_mult` is multiplied by 2.0 in the scoring pipeline. `hands_allowed` is set to 2. Verified by: playing a known hand with and without the modifier and confirming the 2x mult output.
- [ ] **AC-5 — Lucky Draw**: `draw_count` is 7. Player is dealt 7 cards. Selecting 1-5 to play functions identically to standard play. Discard reduces to 5 cards.
- [ ] **AC-6 — Poverty**: Gold generation (per-hand and per-ante) is 0. Shop items show "Out of Stock." No purchase can be completed. Gold display reads 0 throughout run.
- [ ] **AC-7 — Speed Run**: A 30-second countdown timer is visible during hand selection. If the timer reaches 0, the first 5 cards in hand order are auto-played. Timer pauses on app background.
- [ ] **AC-8 — High Stakes**: Each ante threshold is `round(base * 1.5)`. Thresholds match the table in the Detailed Rules section to within ±1 (rounding tolerance).
- [ ] **AC-9 — Collector**: First play of each unique hand rank in an ante awards +5 gold in addition to the base +2. Tracker resets to empty at the start of each ante.
- [ ] **AC-10 — Mirror**: `enemy_element` is set to `captain.element` at combat setup. If no captain, enemy element is `NONE`.
- [ ] **AC-11 — Blessed**: One blessing from the full pool is injected into the scoring pipeline at run start. If the player already owns the randomly selected blessing, a different one is chosen (up to 5 re-rolls).
- [ ] **AC-12 — Cursed**: Resistance chip penalty is doubled. Verified by: playing a mismatched element hand and confirming the penalty is 2x the base resist penalty from poker-combat.md.
- [ ] **AC-13 — Fire Storm**: All ante enemies have `element = FIRE` regardless of their base data.

### Experiential Criteria

- [ ] **EX-1** (Playtest): After 2 weeks of play, players can name at least 3 modifiers from memory and describe how they change their strategy — indicating the modifier set is legible and memorable.
- [ ] **EX-2** (Playtest): High Stakes is perceived as the hardest modifier and is mentioned as a challenge by players who attempt it. Glass Cannon and Speed Run are described as "high pressure." Lucky Draw and Collector are described as "fun" or "favorable." This rough difficulty gradient matches design intent.
- [ ] **EX-3** (Playtest): Mirror modifier prompts at least 30% of playtesters to change their captain selection specifically because of the modifier — indicating it successfully creates a meaningful strategic decision at run entry.
