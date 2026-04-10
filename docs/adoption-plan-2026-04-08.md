# Adoption Plan

> **Generated**: 2026-04-08
> **Project phase**: Production (early)
> **Engine**: Godot 4.6 (GDScript)
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

No blocking gaps detected. Existing artifacts are not malformed — the issue is
that template-expected artifacts don't exist yet in the right locations.

---

## Step 2: Fix High-Priority Gaps

These must be resolved before the template's design-to-code pipeline can operate.

### 2a. Extract game concept from monolithic GDD

**Problem:** `/map-systems` expects `design/gdd/game-concept.md` but the game
concept lives inside `docs/GAME_DESIGN_DOCUMENT.md` (Sections 1-3).

**Fix:** Run `/brainstorm` with the existing concept to produce a formal
`game-concept.md`, OR manually extract Sections 1-3 of the monolithic GDD
into `design/gdd/game-concept.md` with the template's required format.

**Time:** 30 min
- [ ] `design/gdd/game-concept.md` created

### 2b. Create systems index

**Problem:** `/design-system`, `/gate-check`, and `/create-architecture` all
require `design/gdd/systems-index.md` to know what systems exist.

**Fix:** Run `/map-systems` — it reads the game concept and decomposes it into
a systems index with dependency mapping and priority ordering.

**Time:** 30 min
- [ ] `design/gdd/systems-index.md` created

### 2c. Decompose monolithic GDD into per-system GDDs

**Problem:** All design-consuming skills read from `design/gdd/[system].md`.
Your game design for ~8 systems lives in one file (`docs/GAME_DESIGN_DOCUMENT.md`)
and is invisible to the pipeline.

**Systems to extract** (from the monolithic GDD):
1. Combat System (Section 4) — hand ranks, scoring formula, enhancements, blessings, enemies
2. Romance & Social System (Section 5) — relationship stages, daily interactions, dates, combat buffs
3. Intimacy System (Section 5, subsection) — phases, momentum, speed tiers, ecstasy
4. Abyss Mode (Section 6) — antes, blinds, shop, weekly modifiers
5. Equipment System (Section 7) — slots, rarities, stats
6. Exploration System (Section 7) — dispatch missions, node types
7. Save System (Section 7/9) — JSON save/load, versioning, autosave
8. UI/Navigation (Section 8) — screens, tabs, theme

**Fix:** For each system, run `/design-system [system-name]`. The skill walks
through the 8 required sections collaboratively. Use existing content from the
monolithic GDD as source material — don't start from scratch.

**Each GDD needs these 8 sections:**
1. Overview
2. Player Fantasy
3. Player Fantasy
4. Formulas
5. Edge Cases
6. Dependencies
7. Tuning Knobs
8. Acceptance Criteria

**Time:** 30-60 min per system (~4-6 sessions for all 8)
- [ ] `design/gdd/combat-system.md`
- [ ] `design/gdd/romance-social-system.md`
- [ ] `design/gdd/intimacy-system.md`
- [ ] `design/gdd/abyss-mode.md`
- [ ] `design/gdd/equipment-system.md`
- [ ] `design/gdd/exploration-system.md`
- [ ] `design/gdd/save-system.md`
- [ ] `design/gdd/ui-navigation.md`

### 2d. Create Architecture Decision Records

**Problem:** `/create-stories` and `/story-readiness` require ADR references.
Zero ADRs exist.

**Fix:**
1. Run `/create-architecture` — reads all GDDs and produces a master architecture
   blueprint with a Required ADR list
2. Run `/architecture-decision` for each required ADR

**Prerequisite:** Step 2c (GDDs must exist first)
**Time:** 1-2 sessions for architecture + ADRs
- [ ] Master architecture document created
- [ ] All required ADRs created

### 2e. Create control manifest

**Problem:** Stories can't embed layer rules without a control manifest.

**Fix:** Run `/create-control-manifest` after ADRs are complete.

**Prerequisite:** Step 2d (ADRs must exist)
**Time:** 30 min
- [ ] `docs/architecture/control-manifest.md` created

### 2f. Bootstrap TR registry

**Problem:** `tr-registry.yaml` exists but is empty. No stable requirement IDs
for traceability between GDDs and stories.

**Fix:** Run `/architecture-review` — it reads all GDDs and ADRs, builds the
traceability matrix, and populates `tr-registry.yaml`.

**Prerequisite:** Steps 2c + 2d (GDDs and ADRs must exist)
**Time:** 1 session
- [ ] `tr-registry.yaml` populated with requirement entries

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates tr-registry entries)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps
the TR registry from your existing GDDs and ADRs.
**Time**: 1 session (review can be long for large codebases)
- [ ] tr-registry.yaml populated

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min (if sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage
Run `/gate-check Production`
**Time**: 5 min
- [ ] production/stage.txt written

---

## Step 4: Medium-Priority Gaps

### 4a. Sprint status tracking
**Problem:** `/sprint-status` has no `sprint-status.yaml` to read.
**Fix:** Addressed in Step 3c.
- [ ] Sprint tracking operational

### 4b. Architecture traceability
**Problem:** No persistent cross-reference matrix between GDDs, ADRs, and stories.
**Fix:** Addressed in Step 3a (`/architecture-review` creates this).
- [ ] Architecture traceability matrix created

### 4c. Stage file
**Problem:** No authoritative `production/stage.txt` — phase detection is heuristic-based.
**Fix:** Addressed in Step 3d.
- [ ] Stage file written

---

## Step 5: Optional Improvements

### 5a. Archive monolithic GDD
After all per-system GDDs are created, move or rename the monolithic file to
`docs/GAME_DESIGN_DOCUMENT.archive.md` to avoid confusion. It remains useful
as a quick reference but is no longer the source of truth.
- [ ] Monolithic GDD archived

---

## What to Expect from Existing Stories

No stories exist yet. When stories are created via `/create-stories` after
completing Steps 2-3, they will automatically include TR-IDs, ADR references,
and manifest version stamps.

---

## Recommended Migration Order

```
Step 2a: game-concept.md        ← START HERE
Step 2b: /map-systems           ← depends on 2a
Step 2c: /design-system (×8)    ← depends on 2b
Step 2d: /create-architecture   ← depends on 2c
         /architecture-decision (×N)
Step 2e: /create-control-manifest ← depends on 2d
Step 2f: /architecture-review   ← depends on 2c + 2d
Step 3c: /sprint-plan           ← independent
Step 3d: /gate-check            ← after all above
```

---

## Re-run

Run `/adopt` again after completing Step 2c to verify all high-priority gaps
are resolved. The new run will reflect the current state of the project.
