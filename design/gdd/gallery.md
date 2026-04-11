# Gallery System — GDD

> **Status**: Designed
> **Created**: 2026-04-10
> **Priority**: Full Vision
> **Layer**: Polish
> **Depends On**: Intimacy, Story Flow

---

## 1. Overview

The Gallery is a read-only CG collection viewer that lets players revisit unlocked artwork from intimacy scenes and story milestones. Entries are unlocked by completing the corresponding in-game event and tracked via GameStore story flags. The Gallery never grants gameplay rewards and imposes no costs — it is a completionist reward and replay surface.

---

## 2. Player Fantasy

Players feel a sense of accomplishment reviewing their journey: each CG is a trophy representing a meaningful story beat or intimate moment. The gallery communicates "you earned this." Locked entries tease future content without spoiling it — only a silhouette and a vague unlock hint are shown.

---

## 3. Detailed Rules

**Entry types:**

| Type | Count | Unlock condition |
|------|-------|-----------------|
| Intimacy | 12 | `intimacy_{companion_id}_{scene_num}_complete` flag set |
| Story | 3 | `story_{chapter}_complete` flag set (ch01, ch02, ch03) |
| Special | 0 (placeholder) | Reserved for future events |

**Locked entries:** visible as entries with `unlocked: false`. Title and CG path are hidden from the UI layer (the system still returns them for internal use; the UI must not display them).

**Total entries:** 15 (12 intimacy + 3 story).

**Replay:** Any unlocked CG can be viewed without consuming tokens or any resource.

**Entry ordering:** Sorted by `sort_order` field in gallery.json. Entries without `sort_order` sort after those with it.

---

## 4. Formulas

```
unlocked_count = count(entries where has_flag(entry.unlock_flag) == true)
total_count    = len(all entries in gallery.json)
completion_pct = unlocked_count / total_count * 100
```

No RNG. No math beyond counting.

---

## 5. Edge Cases

- **Missing flag:** If `unlock_flag` is absent from an entry dict, the entry is always locked.
- **Unknown flag:** `GameStore.has_flag()` returns false for any unset flag — entry remains locked.
- **Empty JSON:** `get_all_entries()` returns an empty array; `get_unlocked_count()` returns 0.
- **JSON parse failure:** Same as empty — all methods return safe defaults, no crash.
- **Duplicate IDs in JSON:** Last entry with the same ID wins (Array iteration order).
- **Cache reset:** `_reset_cache()` is provided for test isolation only; production code must not call it.

---

## 6. Dependencies

- **Intimacy System** (upstream): writes `intimacy_{id}_{n}_complete` flags that Gallery reads.
- **Story Flow** (upstream): writes `story_{chapter}_complete` flags that Gallery reads.
- **GameStore** (upstream): provides `has_flag()` — the sole unlock gate.
- **Achievements System** (downstream): reads `Gallery.get_unlocked_count()` to evaluate the "Unlock all CGs" achievement condition.

---

## 7. Tuning Knobs

| Knob | Current Value | Safe Range | Effect |
|------|--------------|-----------|--------|
| Total intimacy CG count | 12 (3 per companion × 4 companions) | 4–24 | Scales with companion roster |
| Total story CG count | 3 (1 per chapter) | 1–10 | Scales with chapter count |
| Special entries | 0 | 0–20 | Future event hooks |

All counts are driven by gallery.json — adding entries requires only data changes.

---

## 8. Acceptance Criteria

| ID | Criterion | Type |
|----|-----------|------|
| AC-GAL-1 | `get_all_entries()` returns 15 entries when gallery.json has 15 valid entries | Logic |
| AC-GAL-2 | An entry with its `unlock_flag` set in GameStore has `unlocked: true` | Logic |
| AC-GAL-3 | An entry without its `unlock_flag` set has `unlocked: false` | Logic |
| AC-GAL-4 | `get_unlocked_count()` returns the count of entries where `unlocked == true` | Logic |
| AC-GAL-5 | `get_total_count()` returns 15 regardless of unlock state | Logic |
| AC-GAL-6 | JSON parse failure results in empty returns, not a crash | Logic |
| AC-GAL-7 | Setting the flag for an intimacy scene unlocks the corresponding gallery entry | Integration |
