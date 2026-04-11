# Intimacy

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-10
> **Implements Pillar**: Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Intimacy is the relationship milestone system that activates at romance stage 4 (Close) and delivers 3 interactive CG scenes per companion (12 total across 4 companions). Each scene is a static CG + text + choice sequence — not video. Completing a scene awards +10 RL and unlocks a CG gallery entry. Scenes are gated strictly by `romance_stage >= 4`.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `Romance & Social, Companion Data`

---

## Overview

Intimacy scenes are the emotional apex of each companion relationship arc. When a companion reaches romance stage 4 (Close), a new interaction type becomes available at Camp: "Spend Time Together." This launches a 3-part scene series (Scene 1 → Scene 2 → Scene 3) that must be completed in order over separate sessions. Each scene presents a static illustrated CG with layered dialogue delivered via the standard typewriter system, punctuated by 1-2 player choices that influence mood and dialogue direction but do not branch the outcome. Completing a scene awards +10 RL, triggers a gallery unlock notification, and records completion in the save file. Scene 3 of each companion is gated behind romance stage 5 (Devoted) rather than stage 4. No video assets are required — this is a simplified scope from the original React Native design. Each scene is a self-contained narrative moment delivered through the existing Dialogue system, with a dedicated full-screen CG background replacing the standard portrait layout.

---

## Player Fantasy

**"Finally Seen"**

The intimacy system delivers on the promise the entire romance arc has been building toward: two people — one mortal, one fallen divine — choosing each other fully. This is not a reward cutscene. It is a quiet, personal moment that feels earned because it required hundreds of small investments: talk tokens spent, gifts given, dates completed, stages climbed.

The player should feel: "She trusts me now. Not because I won fights or solved puzzles, but because I showed up." The CG art holds the weight of that choice — a single image that captures something true about this companion and this relationship at this moment. The choice sequences inside scenes exist not to branch outcomes but to let the player speak — to have a voice in this moment, to give something of themselves before receiving.

The gallery unlock notification is secondary. The primary feeling is intimacy itself: being known, being wanted, and wanting in return.

*Pillar 3: "Each companion must feel distinct in personality, story, AND combat utility."*

---

## Detailed Rules

### Rule 1 — Gate Conditions

An intimacy scene interaction is available at Camp when ALL of the following are true:

- `companion.romance_stage >= 4` (for Scenes 1 and 2)
- `companion.romance_stage >= 5` (for Scene 3 only)
- `companion.met == true`
- The previous scene in sequence has `completion_flag == true` in save data
- The player has at least 1 interaction token available (costs 1 token, same as Talk)

Scene 1 has no prerequisite completion flag (it is the entry point when stage 4 is reached). Scenes 2 and 3 require the prior scene to be completed.

### Rule 2 — Scene Structure

Each scene follows this fixed sequence:

1. **Fade to black** — standard scene transition
2. **CG display** — full-screen static CG image loads (replaces portrait layout)
3. **Companion name plate** appears (same visual as dialogue system)
4. **Dialogue sequence** — 4-8 dialogue lines delivered via typewriter at standard speed
5. **Choice moment** — 1-2 player choice nodes appear (using Dialogue system choice UI)
   - Each choice has a `mood_tag` (positive / neutral / reflective)
   - Mood tag adjusts 1-3 subsequent dialogue lines to match chosen tone
   - All choices converge to the same scene conclusion — no branching endings
6. **Scene conclusion dialogue** — 2-4 closing lines
7. **Completion sequence** — companion portrait appears briefly, delivers a final line
8. **Reward pop-up** — "+10 RL" displayed with companion's name
9. **Gallery unlock notification** — "[Companion] — [Scene Title] unlocked in Gallery"
10. **Return to Camp**

### Rule 3 — Rewards

| Event | Reward |
|-------|--------|
| Scene completion | +10 RL to companion |
| Gallery entry | CG image unlocked in Gallery screen |
| Scene 3 completion | +20 RL (bonus), unique companion item added to inventory |

Scene 3 awards +20 RL instead of +10 to mark the deepest milestone. The unique companion item is a gift-category collectible — it has no gameplay function but triggers special dialogue when shown to that companion.

### Rule 4 — Token Cost

Each scene costs 1 interaction token (same pool used by Talk/Gift/Date). This means a player can only trigger one intimacy scene per day. This is intentional — it enforces pacing and prevents binging all scenes in a single session.

### Rule 5 — Scene Inventory Per Companion

| Companion | Scene 1 Gate | Scene 2 Gate | Scene 3 Gate |
|-----------|-------------|-------------|-------------|
| Artemis | Stage 4 | Stage 4 + Scene 1 done | Stage 5 + Scene 2 done |
| Hipolita | Stage 4 | Stage 4 + Scene 1 done | Stage 5 + Scene 2 done |
| Atenea | Stage 4 | Stage 4 + Scene 1 done | Stage 5 + Scene 2 done |
| Nyx | Stage 4 | Stage 4 + Scene 1 done | Stage 5 + Scene 2 done |

All 4 companions follow the same gating structure. Scenes are per-companion — completing Artemis Scene 1 does not affect Hipolita's sequence.

### Rule 6 — Save Data

Completion flags stored per companion in save file:

```
companion_intimacy: {
  "artemis": { scene_1: bool, scene_2: bool, scene_3: bool },
  "hipolita": { scene_1: bool, scene_2: bool, scene_3: bool },
  "atenea": { scene_1: bool, scene_2: bool, scene_3: bool },
  "nyx": { scene_1: bool, scene_2: bool, scene_3: bool }
}
```

Completion is write-once — once `scene_1: true`, it cannot revert to false. Scenes may be replayed from the Gallery screen (view-only, no rewards re-granted).

### Rule 7 — Interaction Token Spending

Intimacy scenes appear in Camp as a distinct interaction button labeled "Spend Time Together" (localized). It occupies the same interaction token slot as Talk/Gift/Date. The button is hidden if no scene is available for that companion (gate conditions not met). The button is greyed and labeled "Next scene available after [stage condition]" if gate conditions are partially met (stage reached, prior scene done, but token unavailable).

---

## Formulas

### RL Award

```
scene_rl_award = BASE_RL_AWARD                      (Scenes 1 and 2)
scene_rl_award = BASE_RL_AWARD * SCENE_3_MULTIPLIER  (Scene 3 only)
```

| Variable | Value | Notes |
|----------|-------|-------|
| `BASE_RL_AWARD` | 10 | Fixed per scene 1 and 2 |
| `SCENE_3_MULTIPLIER` | 2 | Scene 3 awards 20 RL total |

The RL award is applied directly to `companion.relationship_level` via Romance & Social's standard RL mutation path (subject to stage cap rules defined in romance-social.md).

**Example**: Completing Artemis Scene 2 awards +10 RL. If Artemis is at RL 87 with a stage 4 cap of 100, she moves to RL 97 — not capped.

### Gallery Unlock Count

```
gallery_total = COMPANIONS * SCENES_PER_COMPANION
gallery_total = 4 * 3 = 12
```

---

## Edge Cases

**EC-1: Player reaches stage 4 but lacks tokens.**
Gate check fails on `tokens_available >= 1`. The "Spend Time Together" button is visible but disabled with a tooltip: "No tokens remaining today." Standard behavior — no special handling needed.

**EC-2: Player completes Scene 2 then loses relationship level.**
RL can decrease from disliked gifts or certain dialogue choices. However, `romance_stage` is never decremented by RL loss alone — only by explicit story events (none exist in current design). Scene completion flags are write-once. Therefore a player who completes Scene 2 and then loses RL cannot re-lock Scene 2, and their completion record is preserved. If romance_stage somehow dropped below 4 via a future system, Scene 3 gate would block on `romance_stage >= 5` check, which is correct.

**EC-3: Companion not yet met (`met == false`).**
All intimacy interactions require `met == true`. This is the same gate used by Talk and Gift. A companion not yet encountered in story cannot have any camp interaction.

**EC-4: Scene data file missing or CG asset not loaded.**
The scene loader must validate CG asset presence before launching. If the CG resource path returns null, the scene should abort gracefully, log an error, return the player to Camp, and NOT consume the interaction token. Reward is not granted.

**EC-5: Scene interrupted (app backgrounded mid-scene).**
Dialogue progress within a scene is NOT persisted mid-scene. If the app closes mid-scene, the scene has not completed (no completion flag written, no RL awarded). On next session, the scene is available to replay from the beginning. This matches the visual novel dialogue system's behavior for standard scenes.

**EC-6: All 12 scenes completed.**
No special end state. Camp UI simply shows no "Spend Time Together" buttons for any companion. Gallery is fully unlocked. No achievement fires from this system (Achievements system handles milestone tracking separately).

**EC-7: Replay from Gallery.**
Gallery replay launches the same scene sequence (typewriter dialogue, CG display) but skips the reward sequence entirely. Completion flags are not re-evaluated. The choice UI appears but mood-tagged variants are pre-collapsed — player sees the same scene flow without branching. Replay does not consume an interaction token.

---

## Dependencies

### Systems this depends on

| System | Usage | Doc |
|--------|-------|-----|
| **Romance & Social** | Reads `romance_stage` and `met`; writes RL award via social RL mutation path; reads/writes daily token pool | design/gdd/romance-social.md |
| **Companion Data** | Reads companion ID, name, element, portrait asset path, mood variants | design/gdd/companion-data.md |
| **Dialogue** | Uses Dialogue system's typewriter, choice node UI, and name plate for scene delivery | design/gdd/dialogue.md |
| **Save System** | Reads/writes `companion_intimacy` completion flags; save is the only persistent record | design/gdd/save-system.md |
| **Scene Navigation** | Uses SceneManager to transition into and out of intimacy scene view | design/gdd/scene-navigation.md |

### Systems that depend on this

| System | How |
|--------|-----|
| **Gallery** | Reads `companion_intimacy` flags to determine which CG entries are unlocked and displayable |
| **Achievements** | Reads completion flags to trigger "all scenes complete" or "companion full arc" milestones |
| **Camp** | Conditionally renders the "Spend Time Together" button based on gate conditions |

---

## Tuning Knobs

| Knob | Category | Default | Range | Notes |
|------|----------|---------|-------|-------|
| `BASE_RL_AWARD` | Curve | 10 | 5–20 | RL per scene 1 & 2 completion. Higher values accelerate stage 5 unlock. |
| `SCENE_3_MULTIPLIER` | Curve | 2 | 1.5–3 | Multiplier on BASE_RL_AWARD for scene 3 completion. |
| `TOKEN_COST` | Gate | 1 | 1–2 | Interaction tokens consumed per scene. 1 keeps pacing consistent with Talk/Gift/Date. |
| `SCENES_PER_COMPANION` | Gate | 3 | 2–4 | Fixed per production scope. Increasing requires new art assets. |
| `SCENE_2_GATE` | Gate | Stage 4 + Scene 1 | — | Minimum romance_stage to unlock Scene 2. Changing to Stage 5 would push pacing further. |
| `SCENE_3_GATE` | Gate | Stage 5 + Scene 2 | — | Minimum romance_stage for Scene 3. Stage 5 is the max — this is intentional. |

All knobs live in `assets/data/intimacy_config.json`.

---

## Acceptance Criteria

### Functional Criteria

- [ ] **AC-1**: "Spend Time Together" button appears at Camp for a companion only when `romance_stage >= 4`, `met == true`, and at least 1 scene is available (not yet completed). Button is hidden when no scene is available.
- [ ] **AC-2**: Triggering a scene costs exactly 1 interaction token. Token count decrements by 1 in save data immediately on scene launch.
- [ ] **AC-3**: Scene sequence plays in order: fade → CG → typewriter dialogue → choice node → conclusion → reward pop-up → gallery notification → return to Camp.
- [ ] **AC-4**: `scene_N: true` is written to `companion_intimacy` in save data exactly once per scene, upon completion of that scene's conclusion sequence. It is never written if the scene is interrupted mid-sequence.
- [ ] **AC-5**: +10 RL is credited to the correct companion's `relationship_level` on scene 1 and 2 completion. +20 RL is credited on scene 3 completion.
- [ ] **AC-6**: Scene 3 is inaccessible (button hidden/disabled) until `romance_stage >= 5` AND `scene_2: true`. Attempting to access it via any other path returns to Camp with no state change.
- [ ] **AC-7**: Gallery screen displays a CG entry as unlocked for each completed scene, and locked (blurred/placeholder) for incomplete scenes.
- [ ] **AC-8**: Replaying a scene from Gallery does not consume an interaction token, does not grant RL, and does not alter any completion flag.
- [ ] **AC-9**: If CG asset fails to load, scene aborts, token is not consumed, RL is not granted, and the player is returned to Camp.

### Experiential Criteria

- [ ] **EX-1** (Playtest): Players completing Scene 1 for the first time report feeling the scene was "earned" and "worth it" — not a sudden cutscene drop but a natural arc conclusion. Target: 80% positive response in playtest survey.
- [ ] **EX-2** (Playtest): The 1-token-per-day pacing does not feel punishing. Players understand they can return tomorrow. Target: fewer than 20% of playtesters report frustration at the single-scene-per-day limit.
- [ ] **EX-3** (Playtest): CG quality and scene length (estimated 3-5 minutes per scene) feel appropriate for the emotional weight of the moment — not too brief to be dismissive, not long enough to overstay.
