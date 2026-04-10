# Cross-GDD Review Report

**Date:** 2026-04-09
**Reviewer:** /review-all-gdds (Opus)
**GDDs Reviewed:** 13
**Systems Covered:** Companion Data, Enemy Data, Save System, Localization, UI Theme, Scene Navigation, Poker Combat, Dialogue, Romance & Social, Story Flow, Deck Management, Divine Blessings, Camp
**Entity Registry:** 6 formulas, 9 constants pre-loaded as conflict baseline

---

## Consistency Issues

### Blocking (must resolve before architecture begins)

#### B-01: Enemy ID Mismatch — Story Flow vs Enemy Data — RESOLVED 2026-04-10

- **Resolution:** Updated story-flow.md to use Enemy Data IDs: `mountain_beast` → `cyclops`, `amazon_challenger` → `hipolita_duel`. Enemy Data is the authoritative registry.

#### B-02: Ch1 Node Count Discrepancy — Game Concept vs Story Flow — RESOLVED 2026-04-10

- **Resolution:** Updated game-concept.md to say 9 nodes. Story Flow's 9-node structure is authoritative.

#### B-03: Gold Has No Sink in MVP — RESOLVED 2026-04-10

- **Resolution:** Gift Items (design/quick-specs/gift-items.md, ADR-0015) serves as the MVP gold sink. Players spend gold buying gifts for companions in Camp, reinforcing the romance pillar. Gift Items is already designed and architecturally covered.

### Warnings (should resolve, but won't block)

#### W-01: Dependency Asymmetry — Localization → Romance & Social

- `localization.md` lists Romance & Social as a Hard (MVP) downstream dependency
- `romance-social.md` does NOT list Localization in its dependencies table
- **Action:** Add Localization as a Soft dependency in R&S.

#### W-02: Dependency Asymmetry — Localization → Camp

- `localization.md` lists Camp as a Hard (Vertical Slice) downstream dependency
- `camp.md` does NOT list Localization in its dependencies table
- **Action:** Add Localization as a Soft dependency in Camp.

#### W-03: Dependency Asymmetry — Deck Management → Scene Navigation

- `deck-management.md` lists Scene Navigation as a dependency
- `scene-navigation.md` does NOT list Deck Management as a caller
- **Action:** Add Deck Management to Scene Navigation's interaction table.

#### W-04: Stale API Reference in Deck Management

- `deck-management.md` (Dependencies section): `SceneManager.go_to("poker_combat")`
- `scene-navigation.md` defines the API as `SceneManager.change_scene(SceneId.COMBAT, context)`
- **Action:** Update Deck Management to use the canonical API name.

#### W-05: Stale Cross-References in UI Theme

- `ui-theme.md` Cross-References table lists three GDDs as "not yet authored": Dialogue GDD, Poker Combat GDD, Scene Navigation GDD
- All three GDDs now exist with full specifications
- **Action:** Update UI Theme cross-references to point to actual GDD paths.

#### W-06: Stale Cross-Reference in Localization

- `localization.md` Cross-References: "Dialogue GDD -- not yet authored"
- `dialogue.md` now exists
- **Action:** Update the cross-reference.

#### W-07: Duplicate Tuning Knob Names — Poker Combat vs Deck Management

- `poker-combat.md` Tuning Knobs: `CAPTAIN_STR_CHIP_RATIO` (0.5), `CAPTAIN_INT_MULT_RATIO` (0.025)
- `deck-management.md` Tuning Knobs: `captain_str_chip_multiplier` (0.5), `captain_int_mult_base` (1.0), `captain_int_mult_per_point` (0.025)
- Same values under different names. Deck Management also adds `captain_int_mult_base` (1.0) which Poker Combat defines inline.
- **Action:** Poker Combat owns these formulas. Remove duplicates from Deck Management or mark as "mirrored from Poker Combat config."

---

## Game Design Issues

### Blocking

#### B-03: Gold Has No Sink in MVP — RESOLVED 2026-04-10

(See Consistency section — resolved via Gift Items as MVP gold sink.)

### Warnings

#### W-08: XP Has No Consumption Mechanism

- 760 XP awarded across Chapter 1 (50-250 per node)
- Story Flow notes: "XP thresholds are deferred to Deck Management GDD"
- Deck Management does not define XP consumption
- No system defines what XP does
- **Recommendation:** Hide XP display until a consuming system is designed, or explicitly declare it as "tracked for future use" and suppress the reward panel display.

#### W-09: Nyx Potential Dominant Captain at Stage 4

- Nyx: STR 18, INT 19 → +9 chips, x1.475 mult (highest combined stat bonus)
- Nyx Slot 5 (Devoted Ocean): **unconditional** +30 chips, +3.5 mult — always fires, no trigger
- Other companions' Slot 5 blessings have specific trigger conditions
- At stage 4, Nyx provides the most reliable damage floor across all hand types
- Divine Blessings GDD acknowledges this as intentional ("She holds back until she trusts you completely")
- **Recommendation:** Acceptable if Nyx is narratively the hardest to reach stage 4 (Chapter 2+). Monitor in playtesting. If Abyss Mode allows Nyx blessings before her story chapter, this becomes a harder balance problem.

#### W-10: Camp Gift System References Non-Existent Inventory

- Camp Rule 5/6: Gift feature requires giftable items from an item/inventory system
- Camp Dependencies: "Inventory / Item Data — Soft"
- **No Inventory GDD exists.** Camp's own Open Questions flag this.
- **Recommendation:** Camp's Gift feature is unimplementable without defining where gift items come from. Either scope a minimal item data definition or defer gifting to Alpha alongside Equipment.

---

## Cross-System Scenario Issues

**Scenarios walked:** 4

1. Combat victory with captain RL gain crossing stage threshold
2. Story Flow combat node referencing non-existent enemy
3. Camp interaction triggering romance stage advance and blessing unlock
4. Full synergy combat: element weakness + captain + blessings + social buff

### Blockers

#### S-B01: Story Flow combat with undefined enemy — Story Flow × Enemy Data

- **Step:** Player reaches ch01_n04, Story Flow reads `enemy_id: "mountain_beast"`
- **Failure:** `mountain_beast` does not exist in Enemy Data registry
- **Nature:** Undefined behavior. If inline config defines the enemy, the registry is incomplete. If the registry is authoritative, the inline config will fail.
- **Action:** Reconcile the two enemy name sets before implementation.

### Warnings

#### S-W01: Compounding bonuses may trivialize Chapter 1 — Poker Combat × Divine Blessings × R&S

- With Hipolita captain (stage 2+), 5 Hearts vs Earth enemy: element weakness (+125 chips, +2.5 mult) + captain (+10 chips, x1.225) + Ember Strike (+50 chips) + Warchief's Will (+30 chips) + social buff (+15 chips, +1.0 mult) = massive overkill against 130 threshold
- This is the "everything clicked" synergy moment — requires rare 5-same-suit alignment (~0.05% probability from initial deal)
- **Recommendation:** Acceptable as aspirational peak. Monitor frequency in playtesting.

### Info

#### S-I01: Captain RL gain + Story Flow rewards ordering — Poker Combat × R&S × Story Flow

- Both captain RL (+1) and node completion rewards fire on combat victory
- Single-threaded GDScript ensures no race condition
- Implementation should establish consistent ordering for deterministic behavior.

#### S-I02: Stage advance during Camp interaction — Camp × R&S × Divine Blessings

- Signal chain is well-defined: R&S → writes RL → evaluates stage → emits signal → Blessings unlocks → autosave
- Camp UI refreshes from R&S state after interaction completes
- No issues detected — clean signal flow.

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| `story-flow.md` | Enemy IDs (`mountain_beast`, `amazon_challenger`) don't match Enemy Data registry | Consistency | Blocking |
| `enemy-data.md` | Missing enemies referenced by Story Flow, or has unreferenced enemies (`cyclops`, `temple_beast`) | Consistency | Blocking |
| `game-concept.md` | Says "8 nodes" but Story Flow defines 9 | Consistency | Blocking |
| `romance-social.md` | Missing Localization dependency | Consistency | Warning |
| `camp.md` | Missing Localization dependency; Gift system references non-existent Inventory | Consistency + Design | Warning |
| `deck-management.md` | Stale API reference; duplicate tuning knobs | Consistency | Warning |
| `ui-theme.md` | Stale cross-references to "not yet authored" GDDs | Consistency | Warning |
| `localization.md` | Stale cross-reference to "not yet authored" Dialogue GDD | Consistency | Warning |

---

## Design Theory: Positive Findings

These cross-GDD strengths are worth preserving:

- **Pillar alignment is excellent.** All 13 systems clearly serve at least one pillar. No pillar drift.
- **Player fantasy coherence is strong.** All fantasies converge on "mythological hero building bonds with fallen goddesses." No identity conflicts.
- **Player attention budget is healthy.** Maximum 3 simultaneously active decision systems in any game moment. Well under the 4-system cognitive load threshold.
- **No competing progression loops.** The core loop (combat → story → romance → blessings → combat) is a single unified chain with no parallel loops fighting for primacy.
- **Dependency graph is a clean DAG.** No circular dependencies detected across all 13 systems.
- **Formula compatibility is strong.** Blessing outputs fit cleanly into the combat scoring pipeline. Social buff outputs fit cleanly. Stage thresholds are consistent across all referencing GDDs.
- **Element system is internally consistent.** Fire > Earth > Lightning > Water > Fire cycle is identically defined in Poker Combat, Enemy Data, Companion Data, and Deck Management.

---

## Verdict: FAIL

3 blocking issues must be resolved before architecture begins.

### Required actions before re-running:

1. **Reconcile enemy IDs:** Decide whether Story Flow or Enemy Data has the canonical Ch1 enemy list. Update the other GDD to match. Ensure every `enemy_id` in Story Flow's node map exists in Enemy Data's registry, and every Ch1 enemy in the registry is referenced by at least one Story Flow node.
2. **Fix node count:** Update `game-concept.md` MVP section to reflect 9 nodes (or reconcile if Story Flow should have 8).
3. **Resolve gold sink:** Choose one: (a) defer gold display, (b) add minimal sink, or (c) remove gold from MVP rewards. Document the decision.

After these three are resolved, re-run `/review-all-gdds` to verify. The remaining warnings (dependency asymmetries, stale references, duplicate knobs) should also be cleaned up but are not blocking.
