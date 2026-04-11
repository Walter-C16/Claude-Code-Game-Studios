# Abyss Mode

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-10
> **Implements Pillar**: Pillar 4 — Roguelike Abyss for Replayability

## Summary

Abyss Mode is the roguelike endgame system. The player progresses through 8 antes with escalating score thresholds (300 → 6000). Between antes, a shop offers card removal, enhancements, and temporary buffs for gold. A run ends on defeat; no progress persists within a run. Divine blessings and equipment from the main game carry into every run as the only persistent advantage layer. A weekly rotating modifier changes the rules each week.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `Poker Combat, Deck Management, Divine Blessings`

---

## Overview

Abyss Mode is Dark Olympus's endgame replayability layer, modeled after Balatro's escalating ante structure. The player enters a self-contained roguelike run distinct from the story chapters. Each run consists of 8 antes; each ante requires the player to reach a score threshold within the standard combat rules (4 hands, 4 discards). Successfully meeting the threshold advances the player to the between-ante shop, where they spend gold earned during the run on card removal (from their 52-card deck), card enhancements (Foil, Holographic, Polychrome), and temporary run buffs that last until run end. Failing to meet an ante threshold ends the run immediately — no checkpoint, no retry. The player returns to the hub with their persistent assets (blessings, equipment) intact but all run-specific gold, removals, and enhancements lost.

Divine blessings and equipment carry into every Abyss run unchanged — the romance-to-power pipeline from Pillar 3 is the persistent meta-progression. The Abyss is not a separate power system; it is where the full power of the main game's investment is tested and displayed. A weekly rotating modifier (see abyss-modifiers.md) changes which rules govern the run.

---

## Player Fantasy

**"Into the Dark, Armed with Love"**

Abyss Mode is where the player proves everything they have built. Every blessing earned through romance, every piece of equipment found through exploration — it all comes here, to this pit of escalating divine judges. The run doesn't give the player new power. It shows them how much power they already have.

The fantasy is the climber who knows they are ready for this mountain because they prepared properly. Not grinding in a vacuum, but building something meaningful and then testing it against the hardest thing in the game. The ante structure creates a sawtooth of tension: you meet the threshold, exhale, spend your gold wisely in the shop, then look at the next threshold and feel the weight of the next climb.

The weekly modifier makes each run feel different without requiring the player to learn an entirely new game. "This week is Glass Cannon week — my mult is enormous, I only have two hands left, every play has to count." That's a different emotional experience than baseline, without being a different game.

*Pillar 4: "The Abyss provides infinitely replayable content after story chapters end. Weekly modifiers keep it fresh."*

---

## Detailed Rules

### Rule 1 — Run Structure

An Abyss run consists of exactly 8 antes. Antes are completed in order (Ante 1 → Ante 8). There is no branching or skipping.

| Ante | Score Threshold | Difficulty Name |
|------|----------------|----------------|
| 1 | 300 | Shattered Foothills |
| 2 | 500 | Corrupted Lowlands |
| 3 | 800 | Titan's Reach |
| 4 | 1,200 | Olympian Ruins |
| 5 | 1,800 | Kronos's Shadow |
| 6 | 2,700 | The Void's Edge |
| 7 | 4,000 | Primordial Abyss |
| 8 | 6,000 | Heart of the Abyss |

Completing all 8 antes constitutes a full run completion. Completion is recorded in save data and tracked for achievement purposes.

### Rule 2 — Ante Combat Rules

Each ante uses the standard Poker Combat ruleset with these fixed parameters:
- `hands_allowed`: 4
- `discards_allowed`: 4
- Enemy element: determined by the active weekly modifier (default: None/neutral)
- No enemy portrait (Abyss enemies are abstract divine constructs — flavor text only, no character art)

The player's full set of active divine blessings and equipped items apply to every ante as they do in story combat.

### Rule 3 — Between-Ante Shop

After successfully meeting an ante threshold, the player enters the shop before the next ante begins. The shop is not available after Ante 8 (run complete) or after a defeat.

**Shop Stock:** Generated freshly each visit. 3 slots presented. Each slot contains one of:
- Card removal
- Card enhancement (applied to a random card in deck)
- Temporary run buff (see Rule 4)

Stock is revealed immediately on shop load — no mystery. Player sees what is available and its cost before spending.

**Shop Currency:** Gold accumulated during the run. Gold is run-scoped — it does not carry over to the main game economy and does not persist after run end.

**Gold Acquisition During Run:** Each completed hand in Abyss combat awards gold:

| Outcome | Gold Award |
|---------|-----------|
| Hand played (win or loss) | +2 |
| Ante threshold met | +15 bonus |
| Discard (not a hand play) | +0 |

**Shop Item Costs:**

| Item Type | Cost | Notes |
|-----------|------|-------|
| Card removal | 20 gold | Removes one chosen card permanently from deck for this run |
| Enhancement (Foil) | 15 gold | Adds Foil to one chosen card |
| Enhancement (Holographic) | 20 gold | Adds Holographic to one chosen card |
| Enhancement (Polychrome) | 25 gold | Adds Polychrome to one chosen card |
| Temporary buff | 10–30 gold | Run-scoped; cost varies by buff strength (see Rule 4) |

Card removal and enhancement apply to the player's 52-card deck for the remainder of the run. Removed cards are gone for the run; enhancements are gone at run end.

### Rule 4 — Temporary Run Buffs

Temporary buffs are run-scoped bonuses available in the shop. They persist until run end (or defeat).

| Buff Name | Effect | Cost |
|-----------|--------|------|
| Hunter's Focus | +10 chip_bonus (flat, always-on for run) | 10 gold |
| Divine Favor | +0.5 mult_bonus (flat, always-on for run) | 15 gold |
| Golden Hand | +5 gold per hand played | 20 gold |
| Last Gambit | +1 hand_allowed to all remaining antes | 25 gold |
| Clear Mind | +1 discard_allowed to all remaining antes | 20 gold |
| Fortune's Eye | Item find chance +20% for post-run reward | 10 gold |

A player may purchase multiple buffs. Buff effects stack additively. The "Golden Hand" buff is applied retroactively per hand, not per ante — each subsequent hand awards +5 gold in addition to the base +2.

### Rule 5 — Run Persistence Rules

**Carries into every Abyss run (persistent):**
- All active divine blessings (based on current romance stage)
- Equipped Weapon and Amulet (current equipment from main game)

**Run-scoped (lost at run end or defeat):**
- Gold accumulated during run
- Card removals applied during run (deck resets to 52 clean cards on next run)
- Card enhancements applied during run
- Temporary run buffs purchased

**Not affected by Abyss:**
- Main game gold
- Companion relationship levels
- Romance stage
- Persistent equipment (equipped items are read at run start; Abyss cannot destroy them)

### Rule 6 — Defeat Handling

If the player's `current_score` does not meet the `score_threshold` after all hands and discards are exhausted:

1. Run ends immediately
2. Post-run summary shown: antes completed, gold earned (lost), score highscore (updated if new best)
3. Player returned to Hub
4. All run-scoped data cleared

There is no "close but partial credit" — defeat is binary. This is intentional for roguelike design (each run has clear stakes).

### Rule 7 — Run Completion Reward

Completing all 8 antes awards a post-run loot roll:

```
roll one item from the equipment drop table at LEGENDARY rarity floor
```

This guaranteed Legendary drop is the primary incentive for full-run completion. It does not apply to partial runs.

### Rule 8 — Weekly Modifier Integration

One weekly modifier is active at all times (see abyss-modifiers.md). The modifier is visible on the Abyss entry screen. The modifier applies globally to every ante in the run — players cannot opt out. Modifier rotation occurs at Monday 00:00 UTC.

---

## Formulas

### Score Threshold Progression

Thresholds follow a hand-tuned curve (not a pure formula) to ensure each ante is meaningfully harder but not impossibly steep:

| Ante | Threshold | Ratio to Previous |
|------|-----------|------------------|
| 1 | 300 | — |
| 2 | 500 | 1.67x |
| 3 | 800 | 1.60x |
| 4 | 1,200 | 1.50x |
| 5 | 1,800 | 1.50x |
| 6 | 2,700 | 1.50x |
| 7 | 4,000 | 1.48x |
| 8 | 6,000 | 1.50x |

The average ratio is ~1.53x per ante. This is gentler than the theoretical maximum per-hand output growth, giving players a meaningful margin to succeed if well-equipped.

**Max theoretical score per hand (well-equipped, late-game blessed):**

```
hand = Royal Flush → base chips = 100, base mult = 8
weapon_chip = 80 (Legendary)
amulet_mult = 4.0 (Legendary)
blessing_chips = 50, blessing_mult = 3.0 (Devoted Nyx)
total_chips = 100 + 80 + 50 = 230
total_mult = 8 + 4.0 + 3.0 = 15.0
single_hand_max ≈ 230 * 15 = 3,450
```

A maximally equipped player can theoretically clear Ante 8 (6,000) in 2 Royal Flushes. This is the extreme ceiling — typical play requires 3-4 hands.

### Gold Accumulation Per Ante

```
hands_played_gold = hands_played * BASE_HAND_GOLD
ante_bonus_gold = ANTE_COMPLETION_BONUS
total_gold_per_ante = hands_played_gold + ante_bonus_gold

with Golden Hand buff:
total_gold_per_ante = (hands_played * (BASE_HAND_GOLD + GOLDEN_HAND_BONUS)) + ante_bonus_gold
```

| Constant | Value |
|----------|-------|
| `BASE_HAND_GOLD` | 2 |
| `ANTE_COMPLETION_BONUS` | 15 |
| `GOLDEN_HAND_BONUS` | 5 (buff) |

**Expected gold per ante (4 hands played, no buffs):**
```
4 * 2 + 15 = 23 gold per ante
```

**After 4 antes (enough for 1-2 shop purchases):**
```
4 * 23 = 92 gold
```

This means most players can afford 3-5 shop items across the full run — a meaningful set of decisions without unlimited buying power.

---

## Edge Cases

**EC-1: Player has no blessings active (all companions at stage 0).**
Abyss is still accessible. No blessings means no blessing_chips or blessing_mult. The player relies on base hand strength, equipment, and run buffs. Ante 1-3 are completable without blessings; ante 4+ becomes very difficult. This is the designed experience: Abyss rewards romantic investment. No gating is applied — players may attempt a no-blessing run.

**EC-2: Player has no equipment equipped.**
Same as EC-1 — valid but harder. `weapon_chip_bonus = 0`, `amulet_mult_bonus = 0.0`. Scoring pipeline handles empty slots.

**EC-3: App closes mid-Abyss run (between antes, in shop).**
Run state is saved after each ante completion. Save includes: `abyss_ante_current`, `abyss_gold`, `abyss_run_buffs[]`, `abyss_deck_removals[]`, `abyss_deck_enhancements[]`. On next app open, the run resumes from the shop (or beginning of next ante). Partially played hands within an ante are NOT saved (same as story combat — hands are atomic).

**EC-4: App closes mid-ante (hands in progress).**
The current ante is not saved mid-hand. On resume, the ante restarts at `current_score = 0`, `hands_remaining = 4`, `discards_remaining = 4`. Gold earned from played hands in the interrupted ante is lost. This is the same behavior as story combat and is an acceptable constraint.

**EC-5: Weekly modifier changes mid-run.**
The modifier active when the run started is the modifier for the entire run. If Monday 00:00 UTC passes during an active run, the run's modifier does not change. The new modifier applies to the next run. Modifier used for a run is stored in save with `abyss_modifier_id`.

**EC-6: Player buys all shop items and clears the shop.**
After all 3 slots are purchased, the shop screen shows "Shop Empty." Player may still proceed to the next ante. No re-roll mechanic exists in the current design.

**EC-7: Score overflows int.**
At extreme late antes, scores can theoretically exceed int32 (2,147,483,647). Scores are calculated as int64 in GDScript (native int). Ante 8 threshold is 6,000 — realistically, scores will not approach int64 overflow. If overflow is detected (score > 9,999,999 as a soft cap), display as "9,999,999+" and log a warning. Combat outcome is still resolved correctly.

**EC-8: Shop enhancement targets a card that is already enhanced.**
The enhancement applies anyway (same card can have multiple enhancements stacked). If the card is Foil and player purchases Holographic, the card becomes Foil+Holographic. Polychrome can be added on top as well. This creates a high-power mid-to-late-run scenario that is intentional — it gives the player a strong-run payoff for targeting a single powerful card.

---

## Dependencies

### Systems this depends on

| System | Usage | Doc |
|--------|-------|-----|
| **Poker Combat** | Reuses the full poker hand evaluation and scoring pipeline; Abyss combat IS poker combat with different enemy configurations | design/gdd/poker-combat.md |
| **Deck Management** | Reads the player's current 52-card deck at run start; applies card removals and enhancements during the run as deck mutations | design/gdd/deck-management.md |
| **Divine Blessings** | All active blessings are read at run start and applied each hand; blessings are the persistent power layer | design/gdd/divine-blessings.md |
| **Equipment** | Reads equipped Weapon and Amulet at run start for `weapon_chip_bonus` and `amulet_mult_bonus` | design/gdd/equipment.md |
| **Abyss Modifiers** | Reads the active weekly modifier and applies its rule mutations to the run | design/gdd/abyss-modifiers.md |
| **Save System** | Reads/writes Abyss run state (ante progress, gold, deck mutations, buffs); reads highscore; writes run completion flag | design/gdd/save-system.md |

### Systems that depend on this

| System | How |
|--------|-----|
| **Abyss Modifiers** | Modifiers depend on Abyss Mode for their host context — they apply within a run, not outside it |
| **Achievements** | Reads `abyss_run_complete`, `abyss_best_ante`, and `abyss_highscore` from save for milestone triggers |
| **Equipment** | Receives a Legendary loot drop as a post-full-run completion reward |

### Integration Contract

**Provides to Save System**: Run state dict `abyss_run_state` containing `{ active: bool, ante_current: int, gold: int, buffs: [], removals: [], enhancements: [], modifier_id: String, highscore: int, runs_completed: int }`.

**Requires from Poker Combat**: `run_combat(enemy_config) -> { score_achieved: int, hands_used: int, gold_from_hands: int }` where enemy_config is `{ score_threshold: int, hands_allowed: int, discards_allowed: int, element: Element }`.

---

## Tuning Knobs

| Knob | Category | Default | Range | Notes |
|------|----------|---------|-------|-------|
| `ANTE_THRESHOLDS[8]` | Curve | [300,500,800,1200,1800,2700,4000,6000] | — | Hand-tuned. Changing requires full playtest validation at each ante. |
| `HANDS_PER_ANTE` | Gate | 4 | 3–5 | Matches story combat default. Increasing eases difficulty. |
| `DISCARDS_PER_ANTE` | Gate | 4 | 2–5 | Matches story combat default. |
| `BASE_HAND_GOLD` | Curve | 2 | 1–5 | Gold per hand played. Affects total shop purchasing power. |
| `ANTE_COMPLETION_BONUS` | Curve | 15 | 10–25 | Gold bonus per ante cleared. |
| `SHOP_SLOTS` | Gate | 3 | 2–4 | Items offered per shop visit. |
| `REMOVAL_COST` | Curve | 20 | 10–30 | Gold cost for card removal. |
| `FOIL_COST` | Curve | 15 | 10–25 | Gold cost for Foil enhancement. |
| `HOLOGRAPHIC_COST` | Curve | 20 | 15–30 | Gold cost for Holographic enhancement. |
| `POLYCHROME_COST` | Curve | 25 | 20–40 | Gold cost for Polychrome enhancement. |
| `FULL_RUN_REWARD_FLOOR` | Gate | Legendary | — | Minimum rarity for full-run completion reward. Not intended to be lowered. |

All knobs live in `assets/data/abyss_config.json`.

---

## Acceptance Criteria

### Functional Criteria

- [ ] **AC-1**: An Abyss run progresses through exactly 8 antes in order. Antes cannot be skipped. Run completes after Ante 8 threshold is met.
- [ ] **AC-2**: Failing to meet a threshold (hands exhausted, score < threshold) ends the run immediately. Post-run summary is shown. All run-scoped data (gold, removals, enhancements, buffs) is cleared. Persistent data (blessings, equipment, main-game gold, companion RL) is unchanged.
- [ ] **AC-3**: The between-ante shop generates exactly 3 slots. Each slot is one of: card removal, enhancement (Foil/Holographic/Polychrome applied to a deck card), or temporary run buff. Purchasing deducts gold from run-scoped gold. Gold cannot go below 0.
- [ ] **AC-4**: All active divine blessings and equipped item bonuses apply identically in Abyss combat as in story combat. Verification: same hand composition produces the same score output in both contexts.
- [ ] **AC-5**: Abyss run state (ante_current, gold, removals, enhancements, buffs) is saved after each successful ante. On app resume, the run continues from the saved state.
- [ ] **AC-6**: The weekly modifier active at run start is stored with the run and does not change if the weekly rotation fires mid-run.
- [ ] **AC-7**: Full run completion (all 8 antes met) awards one equipment item at Legendary rarity floor via the standard equipment award path.
- [ ] **AC-8**: Highscore (best ante reached, best score in a single run) is stored and updated in save data after every run, win or loss.

### Experiential Criteria

- [ ] **EX-1** (Playtest): Players completing Ante 4 for the first time report the difficulty as "challenging but fair" — they understand why they failed (if they did) and what they need to improve.
- [ ] **EX-2** (Playtest): The between-ante shop creates decision tension — players spend time evaluating options, not buying the first item reflexively. Target: average shop time > 15 seconds per visit in playtest sessions.
- [ ] **EX-3** (Playtest): Players who complete a full run report a sense of accomplishment proportional to the time investment. The Legendary drop reward is mentioned as a meaningful incentive in debrief.
- [ ] **EX-4** (Playtest): The weekly modifier meaningfully changes player strategy in at least 7 of 10 tested modifiers — players adapt their card selection or shop purchases in response to the modifier, not just play identically.
