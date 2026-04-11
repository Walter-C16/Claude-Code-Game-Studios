# Achievements System — GDD

> **Status**: Designed
> **Created**: 2026-04-10
> **Priority**: Full Vision
> **Layer**: Polish
> **Depends On**: Story Flow, Romance & Social, Abyss Mode, Poker Combat

---

## 1. Overview

The Achievements system tracks milestone completion across all major game systems and presents players with a list of locked/unlocked goals. Achievement conditions are evaluated on demand against live GameStore state — there is no background listener. All condition types are data-driven from achievements.json. No XP, gold, or gameplay reward is granted for unlocking achievements; they are prestige markers only.

---

## 2. Player Fantasy

Players feel recognized for their dedication. Unlocking "Complete Chapter 1" feels like a story milestone; "Win 10 Combats" reflects mastery; "Unlock all CGs" celebrates the completionist run. The achievements screen is the player's trophy room — proof of everything they have done.

---

## 3. Detailed Rules

**Achievement states:** An achievement is either complete or incomplete. There is no partial persistence — progress is re-derived each time `get_progress()` is called.

**Condition types:**

| Type | Source | Evaluation |
|------|--------|-----------|
| `flag` | GameStore | `has_flag(params.flag_name)` |
| `combat_wins` | GameStore | `get_counter("combat_wins") >= params.target` |
| `romance_stage` | CompanionState | any companion: `get_romance_stage(id) >= params.target` |
| `gallery_count` | Gallery | `Gallery.get_unlocked_count() >= params.target` |
| `equipment_rarity` | GameStore | `get_equipped_weapon()` or `get_equipped_amulet()` resolves to rarity == params.rarity` |

**Progress:** For countable conditions (`combat_wins`, `romance_stage`, `gallery_count`), `get_progress()` returns `{current, target, complete}`. For flag and equipment conditions, `current` is 0 or 1 (binary).

**12 achievements defined in data:** see `src/assets/data/achievements.json`.

**Unlock is idempotent:** Calling `check_achievement()` on an already-complete achievement returns true without side effects.

---

## 4. Formulas

```
# flag
complete = GameStore.has_flag(params.flag_name)

# combat_wins
current  = GameStore.get_counter("combat_wins")
complete = current >= params.target

# romance_stage (any companion)
current  = max(CompanionState.get_romance_stage(id) for id in COMPANION_IDS)
complete = current >= params.target

# gallery_count
current  = Gallery.get_unlocked_count()
complete = current >= params.target

# equipment_rarity
equipped_ids = [GameStore.get_equipped_weapon(), GameStore.get_equipped_amulet()]
complete     = any(EquipmentSystem.get_item(id).get("rarity","") == params.rarity
                   for id in equipped_ids if id != "")
current      = 1 if complete else 0
```

---

## 5. Edge Cases

- **Unknown condition type:** `check_achievement()` returns false and logs a warning; it does not crash.
- **Unknown achievement ID:** `check_achievement()` returns false; `get_progress()` returns `{current:0, target:0, complete:false}`.
- **GameStore counter absent:** `get_counter()` returns 0 — achievement remains locked at target > 0.
- **No companions at any stage:** `romance_stage` condition evaluates to false correctly.
- **Empty JSON:** `get_all()` returns empty array; `get_unlocked()` returns empty array.
- **JSON parse failure:** same as empty — safe defaults, no crash.
- **Cache reset:** `_reset_cache()` is for test isolation only.

---

## 6. Dependencies

- **GameStore** (upstream): `has_flag()`, `get_counter()`, `get_equipped_weapon()`, `get_equipped_amulet()`
- **CompanionState** (upstream): `get_romance_stage(id)`
- **Gallery** (upstream): `get_unlocked_count()`
- **EquipmentSystem** (upstream): `get_item(id)` to resolve rarity
- **Story Flow** (upstream): writes `story_{chapter}_complete` flags checked by flag-type achievements
- **Abyss Mode** (upstream): writes `abyss_ante_{n}_cleared` flags; increments `combat_wins` counter

---

## 7. Tuning Knobs

| Knob | Current Value | Safe Range | Effect |
|------|--------------|-----------|--------|
| Achievement count | 12 | 6–50 | Data-driven; add entries to achievements.json |
| combat_wins target | 10 | 1–100 | How many wins to earn combat achievement |
| Abyss ante target | 8 | 1–8 | Which ante clears the Abyss achievement |
| Romance stage target | 5 | 1–5 | Which stage triggers romance achievement |
| Gallery count target | 15 | 1–15 | How many CGs needed for collection achievement |

---

## 8. Acceptance Criteria

| ID | Criterion | Type |
|----|-----------|------|
| AC-ACH-1 | `get_all()` returns 12 entries when achievements.json has 12 entries | Logic |
| AC-ACH-2 | `check_achievement()` returns true for a `flag` condition when the flag is set | Logic |
| AC-ACH-3 | `check_achievement()` returns false for a `flag` condition when the flag is not set | Logic |
| AC-ACH-4 | `check_achievement()` returns true for `combat_wins` when counter >= target | Logic |
| AC-ACH-5 | `check_achievement()` returns false for `combat_wins` when counter < target | Logic |
| AC-ACH-6 | `check_achievement()` returns true for `romance_stage` when any companion meets the threshold | Logic |
| AC-ACH-7 | `check_achievement()` returns true for `gallery_count` when Gallery.get_unlocked_count() >= target | Logic |
| AC-ACH-8 | `get_progress()` returns correct `{current, target, complete}` for countable conditions | Logic |
| AC-ACH-9 | Unknown condition type returns false without crashing | Logic |
| AC-ACH-10 | `get_unlocked()` returns only achievements where `check_achievement()` is true | Logic |
| AC-ACH-11 | JSON parse failure results in empty returns, not a crash | Logic |
| AC-ACH-12 | `equipment_rarity` condition returns true when a Legendary item is equipped | Logic |
