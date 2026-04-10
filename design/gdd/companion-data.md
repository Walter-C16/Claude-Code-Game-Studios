# Companion Data

> **Status**: In Design
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-08
> **Implements Pillar**: Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Companion Data is the central data authority for all four companion characters (Artemisa, Hipolita, Atenea, Nyx) and the priestess NPC. It defines static companion profiles (stats, elements, roles, portraits) and mutable companion state (relationship level, trust, romance stage, met status). Ten downstream systems read from this data layer -- it is the most-depended-on system in the project.

> **Quick reference** -- Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Companion Data defines the schema and access patterns for all companion-related information in Dark Olympus. Each companion has a static profile (identity, base stats, element affinity, portrait paths) and a mutable state record (relationship progression, trust, motivation, romance stage, interaction history). This system does not implement any gameplay logic -- it provides the data contracts that Romance & Social, Poker Combat, Dialogue, Divine Blessings, Intimacy, Story Flow, Deck Management, Equipment, Exploration, and Camp all consume. It is designed first because every other system's GDD will reference companion attributes defined here.

## Player Fantasy

Companion Data has no direct player fantasy -- players never interact with the data layer itself. Its fantasy is inherited: it enables the feeling of each companion being a distinct, memorable individual with her own combat identity (element affinity), personality (mood portraits, dialogue responses), and progression arc (relationship stages that unlock new abilities). When a player says "Artemisa feels different from Hipolita," that distinction originates in the data defined here. The system succeeds when players forget it exists and simply experience companions as living characters.

## Detailed Design

### Core Rules

#### Companion Registry

The game defines exactly 4 playable companions and 1 NPC. Each has a unique string ID used as the lookup key across all systems.

| ID | Display Name | Role | Element | STR | INT | AGI | Card Value | Starting Location |
|----|-------------|------|---------|-----|-----|-----|-----------|------------------|
| `artemisa` | Artemisa | Goddess of the Hunt | Earth | 17 | 13 | 20 | 13 | base_camp |
| `hipolita` | Hipolita | Queen of the Amazons | Fire | 20 | 9 | 18 | 14 | amazon_camp |
| `atenea` | Atenea | Goddess of Wisdom | Lightning | 13 | 19 | 12 | 14 | ruined_temple |
| `nyx` | Nyx | Primordial Goddess of Night | Water | 18 | 19 | 8 | 14 | shadow_realm |

Non-playable character (no companion state, no romance, no blessings):

| ID | Display Name | Role | Element | Notes |
|----|-------------|------|---------|-------|
| `priestess` | Priestess | Gaia Fragment (NPC) | None | Blonde, temple keeper. Appears only in story dialogue. |

**Rules:**
1. Companion IDs are immutable string constants. No system may create companions at runtime.
2. Each companion maps 1:1 to an element. No two companions share an element. Elements map to card suits: Fire=Hearts, Water=Diamonds, Earth=Clubs, Lightning=Spades.
3. Base stats (STR, INT, AGI) are integers in range [1, 30]. They are read-only -- no system modifies base stats. Equipment modifiers are additive and tracked separately.
4. Card value determines the companion's face-card value when represented as a playing card in the deck system.
5. Starting location is the background used for the companion's first encounter in Story Flow.

#### Companion State Record

Each companion has mutable state that persists across sessions via the Save System. Initial state for all companions:

| Field | Type | Initial Value | Range | Description |
|-------|------|--------------|-------|-------------|
| `relationship_level` | int | 0 | [0, 100] | Accumulated relationship points |
| `trust` | int | 0 | [0, 100] | Trust score from dialogue choices |
| `motivation` | int | 50 | [0, 100] | Motivation score (affects exploration) |
| `romance_stage` | int | 0 | [0, 4] | Derived from relationship_level thresholds |
| `dates_completed` | int | 0 | [0, +inf) | Total dates completed with this companion |
| `met` | bool | false | -- | Whether the player has encountered this companion in story |
| `known_likes` | Array[String] | [] | -- | Activity IDs the player has discovered this companion likes |
| `known_dislikes` | Array[String] | [] | -- | Activity IDs the player has discovered this companion dislikes |

**Rules:**
1. State is per-companion. A fresh save creates one state record per companion, all at initial values.
2. Only the Romance & Social system writes to `relationship_level` and `trust`. Other systems read these values but never modify them directly.
3. `romance_stage` is derived from `relationship_level` using thresholds: [0, 21, 51, 71, 91]. Stage 0 = levels 0-20, Stage 1 = 21-50, Stage 2 = 51-70, Stage 3 = 71-90, Stage 4 = 91+.
4. `met` is set to `true` by Story Flow when the player first encounters the companion. It is never set back to `false`.
5. `known_likes` and `known_dislikes` are populated by the Date system when the player discovers preferences through interaction.

#### Portrait System

Each companion has 6 mood-variant portraits used by the Dialogue system:

| Mood | Enum Value | Usage Context |
|------|-----------|---------------|
| `neutral` | 0 | Default state, most dialogue |
| `happy` | 1 | Positive reactions, relationship gains |
| `sad` | 2 | Rejection, loss events |
| `angry` | 3 | Conflict, betrayal |
| `surprised` | 4 | Plot reveals, unexpected events |
| `seductive` | 5 | Intimacy approach, romance scenes |

**Path convention:** `res://assets/images/companions/{id}/{id}_{mood}.png`

The Dialogue system specifies mood per dialogue line via the `mood` field in dialogue JSON nodes.

### States and Transitions

Companion Data itself is stateless -- it is a data layer. However, it defines the **romance stage progression** that multiple systems read:

| Romance Stage | Min Relationship | Max Relationship | Unlocks |
|--------------|-----------------|-----------------|---------|
| 0 -- Stranger | 0 | 20 | Basic dialogue only |
| 1 -- Acquaintance | 21 | 50 | Dates unlocked, Blessing slot 1 |
| 2 -- Friend | 51 | 70 | Gift preferences visible, Blessing slot 2 |
| 3 -- Close | 71 | 90 | Intimacy available, Blessing slots 3-4 |
| 4 -- Devoted | 91 | 100 | All content unlocked, Blessing slot 5 |

**Transition rules:**
- Stage increases automatically when `relationship_level` crosses a threshold.
- Stage never decreases. Even if a mechanic could lower `relationship_level` below a threshold, the stage remains at its highest achieved value.
- Stage transitions emit a signal that the Romance & Social system can broadcast to other systems (e.g., unlock blessing, unlock intimacy scene).

### Interactions with Other Systems

| System | Direction | Data Flow |
|--------|-----------|-----------|
| **Romance & Social** | Reads profile, reads/writes state | Writes `relationship_level`, `trust`, `dates_completed`, `known_likes`, `known_dislikes`. Reads thresholds to determine stage. |
| **Poker Combat** | Reads profile | Reads `card_element` for suit-element matching. Reads base stats for potential combat modifier formulas. |
| **Dialogue** | Reads profile + state | Reads `display_name`, portrait path + mood. Reads `met` to gate dialogue availability. Reads `romance_stage` to gate dialogue branches. |
| **Divine Blessings** | Reads state | Reads `romance_stage` to determine which blessings are unlocked. |
| **Intimacy** | Reads profile + state | Reads `romance_stage` (must be >= 3). Reads companion ID for scene selection. |
| **Story Flow** | Reads profile, writes state | Reads companion data for node configuration. Writes `met = true` on first encounter. |
| **Deck Management** | Reads profile | Reads `card_element` and `card_value` for companion card representation. |
| **Equipment** | Reads profile | Reads base stats (STR/INT/AGI) as foundation for equipment modifier calculations. |
| **Exploration** | Reads profile + state | Reads `motivation` for dispatch mission success rates. Reads base stats for mission type matching. |
| **Camp** | Reads state | Reads `met` to display only encountered companions. Reads `romance_stage` to show appropriate interaction options. |
| **Save System** | Reads/writes state | Serializes all companion state to JSON. Deserializes on load. Handles version migration if schema changes. |

## Formulas

### Romance Stage Derivation

```
romance_stage = max(stage for threshold in STAGE_THRESHOLDS if relationship_level >= threshold)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `relationship_level` | int | [0, 100] | Companion state record | Current accumulated relationship points |
| `STAGE_THRESHOLDS` | Array[int] | [0, 21, 51, 71, 91] | Balance config | Minimum relationship for each stage |

**Output range:** 0 to 4
**Example:** If `relationship_level` = 55, thresholds met are [0, 21, 51], so `romance_stage` = 2 (Friend).

### Stat Total Validation

No formula -- base stats are fixed per companion and not calculated. However, current stat totals vary:

| Companion | STR + INT + AGI | Total |
|-----------|----------------|-------|
| Artemisa | 17 + 13 + 20 | 50 |
| Hipolita | 20 + 9 + 18 | 47 |
| Atenea | 13 + 19 + 12 | 44 |
| Nyx | 18 + 19 + 8 | 45 |

> **Open question:** Stat totals are uneven (44-50). Whether to equalize or keep varying totals is deferred to balance tuning. See Open Questions.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| **If `relationship_level` is set above 100** | Clamp to 100. `romance_stage` remains at 4. | Prevents overflow; 100 is the design cap. |
| **If `relationship_level` crosses a threshold and then drops below it** | `romance_stage` stays at the higher value. Never decreases. | Players should never lose romance progress they earned. Losing a stage would feel punishing and could lock out blessings mid-combat. |
| **If a companion is referenced by ID but `met` is false** | Dialogue system skips companion-specific lines. Camp hides the companion. Blessings for unmet companions are inactive. | Prevents spoilers and ensures narrative pacing controls companion availability. |
| **If dialogue JSON references an invalid companion ID** | Log a warning. Use a fallback (narrator portrait, no mood). Do not crash. | Data errors in content shouldn't break the game. |
| **If portrait image file is missing for a mood** | Fall back to `neutral` portrait. If `neutral` is also missing, use a placeholder silhouette. | Missing art assets are common during development; the game must remain playable. |
| **If save data contains an unknown companion ID** (e.g., from a future content update loaded by an older version) | Ignore the unknown entry during deserialization. Do not discard the rest of the save. | Forward-compatibility for content updates that add new companions (Chapter 2+). |
| **If save data is missing a companion state record** (e.g., a new companion added in a content update) | Create a fresh state record with initial values for the missing companion. | Backward-compatibility for saves from before the companion existed. |
| **If two systems attempt to write companion state simultaneously** | Not possible in single-threaded GDScript. If ever refactored to async, use a single writer (Romance & Social) with a signal-based notification pattern. | Prevents race conditions in future architecture changes. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| **Save System** | Save System depends on this | Serializes/deserializes companion state records. Schema changes require save migration. |
| **Romance & Social** | Depends on this | Reads profile data and thresholds. Writes relationship state. Primary state mutator. |
| **Poker Combat** | Depends on this | Reads element affinity for suit-element matching. Reads base stats. |
| **Dialogue** | Depends on this | Reads display name, portrait paths, moods. Reads `met` and `romance_stage` for gating. |
| **Divine Blessings** | Depends on this | Reads `romance_stage` to unlock blessings per companion. |
| **Intimacy** | Depends on this | Reads `romance_stage` >= 3 gate. Reads companion ID for scene selection. |
| **Story Flow** | Depends on this | Reads companion data for node config. Writes `met = true`. |
| **Deck Management** | Depends on this | Reads `card_element` and `card_value` for face cards. |
| **Equipment** | Depends on this | Reads base stats as modifier foundation. |
| **Exploration** | Depends on this | Reads `motivation` and base stats for mission calculations. |
| **Camp** | Depends on this | Reads `met` for display filtering. Reads `romance_stage` for interaction options. |

**Hard dependencies** (system cannot function without Companion Data): All 10 downstream systems.
**Soft dependencies**: None. This system has no upstream dependencies.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `STAGE_THRESHOLDS` | [0, 21, 51, 71, 91] | Each in [0, 100], strictly ascending | Later stage unlocks require more investment; pacing slows | Earlier unlocks; players access blessings/intimacy sooner |
| `relationship_level` max | 100 | [50, 200] | More granular progression; wider threshold spacing possible | Compressed progression; stages feel rapid |
| `trust` max | 100 | [50, 200] | Trust accumulates more slowly relative to cap | Trust maxes out faster |
| `motivation` initial | 50 | [25, 75] | Companions start more willing for exploration | Companions start less willing; player must invest first |
| `motivation` max | 100 | [50, 200] | Higher ceiling for exploration success rates | Lower ceiling caps exploration effectiveness |
| Base stat range | [1, 30] | [1, 50] | Higher stat variance between companions; greater specialization | Flatter stat profiles; companions feel more similar |
| Portrait mood count | 6 | [4, 8] | More emotional nuance in dialogue (but more art assets needed) | Fewer moods; less visual variety in conversations |

**Interactions between knobs:**
- `STAGE_THRESHOLDS` and `relationship_level` max are tightly coupled. If max is lowered, thresholds must be proportionally compressed.
- Base stat range affects Equipment and Exploration balance. Wider ranges amplify equipment modifier impact.

## Acceptance Criteria

- [ ] **GIVEN** a new save file, **WHEN** the game initializes, **THEN** all 4 companions have state records with initial values (relationship_level=0, trust=0, motivation=50, romance_stage=0, met=false, empty likes/dislikes).
- [ ] **GIVEN** companion "artemisa" with relationship_level=55, **WHEN** romance_stage is derived, **THEN** romance_stage=2 (thresholds 0, 21, 51 are met; 71 is not).
- [ ] **GIVEN** companion at romance_stage=3 with relationship_level=75, **WHEN** relationship_level drops to 65, **THEN** romance_stage remains 3 (never decreases).
- [ ] **GIVEN** companion with met=false, **WHEN** the Camp screen is displayed, **THEN** that companion is not shown in the companion grid.
- [ ] **GIVEN** companion "hipolita" with mood "angry", **WHEN** the Dialogue system requests a portrait, **THEN** it receives path `res://assets/images/companions/hipolita/hipolita_angry.png`.
- [ ] **GIVEN** a portrait file is missing for mood "surprised", **WHEN** the Dialogue system requests it, **THEN** the neutral portrait is returned as fallback.
- [ ] **GIVEN** a save from an older version missing a companion entry (e.g., new companion added), **WHEN** the save is loaded, **THEN** a fresh default state record is created for the missing companion without corrupting existing data.
- [ ] **GIVEN** a save from a newer version with an unknown companion ID, **WHEN** the save is loaded by the older version, **THEN** the unknown entry is ignored and all known companions load correctly.
- [ ] **GIVEN** any companion, **WHEN** queried by ID string (e.g., "artemisa"), **THEN** the full profile (display_name, role, stats, element, card_value, starting_location) is returned.
- [ ] **GIVEN** relationship_level set to 105 by any system, **WHEN** the value is stored, **THEN** it is clamped to 100.
- [ ] No companion stat, threshold, or portrait path is hardcoded outside the data definition files. All values are data-driven.
- [ ] Performance: Companion data lookup completes within 1ms (dictionary access, not a bottleneck).

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should companion base stat totals be equalized to 50? Currently vary from 44-50. | game-designer | Before Poker Combat GDD | Affects combat balance and equipment modifier impact. |
| Will Chapter 2 companions (Atenea, Nyx) be available in Abyss mode before their story chapter? | game-designer | Before Abyss Mode GDD | If yes, `met` gate may need an Abyss-specific override. |
| Should the priestess have a simplified companion profile for dialogue (display_name, portraits) or remain entirely separate? | game-designer | Before Dialogue GDD | Current code treats her as a non-companion. Dialogue system needs to know which lookup to use. |
| Will additional companions be added beyond the current 4? If so, what's the extensibility contract? | game-designer | Before Architecture phase | Affects save schema migration strategy and registry capacity. |
