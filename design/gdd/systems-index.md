# Systems Index: Dark Olympus

> **Status**: Approved
> **Created**: 2026-04-08
> **Last Updated**: 2026-04-08
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Dark Olympus requires 21 systems spanning poker combat, visual novel dialogue,
companion romance, roguelike endgame, and supporting infrastructure. The core
loop is: play poker hands to defeat mythological enemies, deepen relationships
with companion goddesses through dialogue and daily interactions, and unlock
divine blessings that enhance combat scoring. All systems serve four pillars:
Balatro-inspired poker combat, visual novel dialogue with consequences, companion
romance as mechanical investment, and roguelike Abyss for replayability.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Companion Data | Data | MVP | Designed | design/gdd/companion-data.md | — |
| 2 | Enemy Data | Data | MVP | Designed | design/gdd/enemy-data.md | — |
| 3 | Save System | Persistence | MVP | Designed | design/gdd/save-system.md | — |
| 4 | Localization | Infrastructure | MVP | Designed | design/gdd/localization.md | — |
| 5 | UI Theme | UI | MVP | Designed | design/gdd/ui-theme.md | — |
| 6 | Scene Navigation (inferred) | Infrastructure | MVP | Designed | design/gdd/scene-navigation.md | — |
| 7 | Poker Combat | Gameplay | MVP | Designed | design/gdd/poker-combat.md | Enemy Data, Companion Data |
| 8 | Dialogue | Narrative | MVP | Designed | design/gdd/dialogue.md | Localization, Companion Data |
| 9 | Romance & Social | Gameplay | MVP | Designed | design/gdd/romance-social.md | Companion Data, Save System |
| 10 | Story Flow | Narrative | MVP | Designed | design/gdd/story-flow.md | Dialogue, Poker Combat, Companion Data |
| 11 | Deck Management | Gameplay | Vertical Slice | Designed | design/gdd/deck-management.md | Companion Data |
| 12 | Divine Blessings | Gameplay | Vertical Slice | Designed | design/gdd/divine-blessings.md | Romance & Social, Poker Combat |
| 13 | Camp | UI | Vertical Slice | Designed | design/gdd/camp.md | Romance & Social, Scene Navigation |
| 14 | Intimacy | Gameplay | Alpha | Designed | design/gdd/intimacy.md | Romance & Social, Companion Data |
| 15 | Equipment | Gameplay | Alpha | Designed | design/gdd/equipment.md | Companion Data, Save System |
| 16 | Exploration | Gameplay | Alpha | Designed | design/gdd/exploration.md | Companion Data, Save System |
| 17 | Abyss Mode | Gameplay | Alpha | Designed | design/gdd/abyss-mode.md | Poker Combat, Deck Management, Divine Blessings |
| 18 | Abyss Modifiers | Gameplay | Alpha | Designed | design/gdd/abyss-modifiers.md | Abyss Mode |
| 19 | Audio | Audio | Alpha | Designed | design/gdd/audio.md | — |
| 20 | Gallery | Meta | Full Vision | Not Started | — | Intimacy, Story Flow |
| 21 | Achievements | Meta | Full Vision | Not Started | — | Story Flow, Romance & Social, Abyss Mode, Poker Combat |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Gameplay** | Core mechanics that make the game fun | Poker Combat, Romance & Social, Divine Blessings, Deck Management, Intimacy, Equipment, Exploration, Abyss Mode, Abyss Modifiers |
| **Narrative** | Story and dialogue delivery | Dialogue, Story Flow |
| **Data** | Central data definitions consumed by multiple systems | Companion Data, Enemy Data |
| **Persistence** | Save state and continuity | Save System |
| **Infrastructure** | Platform services and framework | Localization, Scene Navigation |
| **UI** | Player-facing layouts and themes | UI Theme, Camp |
| **Audio** | Sound and music systems | Audio |
| **Meta** | Collection and tracking outside core loop | Gallery, Achievements |

---

## Priority Tiers

| Tier | Definition | Systems | Count |
|------|------------|---------|-------|
| **MVP** | Required for the core poker-combat + dialogue loop to function. Chapter 1 playable with 2 companions. | Companion Data, Enemy Data, Save System, Localization, UI Theme, Scene Navigation, Poker Combat, Dialogue, Romance & Social, Story Flow | 10 |
| **Vertical Slice** | Complete Chapter 1 experience with blessings, camp, and deck management. Demonstrates the romance-to-power pipeline. | Deck Management, Divine Blessings, Camp | 3 |
| **Alpha** | All companion features, roguelike endgame, and secondary systems in rough form. | Intimacy, Equipment, Exploration, Abyss Mode, Abyss Modifiers, Audio | 6 |
| **Full Vision** | Completionist features and polish. | Gallery, Achievements | 2 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Companion Data** — central authority for all companion definitions (stats, elements, portraits, moods); 10 systems depend on it
2. **Enemy Data** — combat enemy definitions (HP, threshold, chapter context); consumed by Poker Combat and Story Flow
3. **Save System** — JSON persistence backbone; all state-mutating systems write through it
4. **Localization** — string lookup for 1,200+ translation keys; Dialogue and all UI consume it
5. **UI Theme** — shared Godot .tres theme (gold/brown palette, Cinzel/Nunito fonts, element colors)
6. **Scene Navigation** — SceneManager autoload handles transitions between all 18 screens
7. **Audio** — BGM/SFX playback; standalone, no gameplay dependencies

### Core Layer (depends on Foundation)

1. **Poker Combat** — depends on: Enemy Data, Companion Data. Core loop anchor; 3 systems build on it.
2. **Dialogue** — depends on: Localization, Companion Data. Visual novel engine; Story Flow orchestrates it.
3. **Deck Management** — depends on: Companion Data. 52-card deck with suit-element mapping, captain selection.

### Feature Layer (depends on Core)

1. **Story Flow** — depends on: Dialogue, Poker Combat, Companion Data. Chapter node orchestration (dialogue → combat → reward).
2. **Romance & Social** — depends on: Companion Data, Save System. Relationship stages, daily interactions, streak multipliers.
3. **Divine Blessings** — depends on: Romance & Social, Poker Combat. 20 passive buffs gated by romance stage.
4. **Equipment** — depends on: Companion Data, Save System. Artifact/amulet slots with stat modifiers.
5. **Intimacy** — depends on: Romance & Social, Companion Data. 4-phase interactive scenes.
6. **Camp** — depends on: Romance & Social, Scene Navigation. Daily interaction hub UI.
7. **Exploration** — depends on: Companion Data, Save System. Timed dispatch missions.
8. **Abyss Mode** — depends on: Poker Combat, Deck Management, Divine Blessings. Roguelike endgame with 8 antes.
9. **Abyss Modifiers** — depends on: Abyss Mode. 10 weekly rotating challenge effects.

### Polish Layer (depends on features)

1. **Gallery** — depends on: Intimacy, Story Flow. CG collection unlocked via scenes and story events.
2. **Achievements** — depends on: Story Flow, Romance & Social, Abyss Mode, Poker Combat. Milestone tracking across all systems.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Companion Data | MVP | Foundation | game-designer | S |
| 2 | Enemy Data | MVP | Foundation | game-designer | S |
| 3 | Save System | MVP | Foundation | game-designer | S |
| 4 | Localization | MVP | Foundation | game-designer | S |
| 5 | UI Theme | MVP | Foundation | game-designer, art-director | S |
| 6 | Scene Navigation | MVP | Foundation | game-designer | S |
| 7 | Poker Combat | MVP | Core | game-designer, systems-designer | L |
| 8 | Dialogue | MVP | Core | game-designer, narrative-director | M |
| 9 | Romance & Social | MVP | Feature | game-designer, systems-designer | M |
| 10 | Story Flow | MVP | Feature | game-designer, narrative-director | M |
| 11 | Deck Management | Vertical Slice | Core | game-designer | S |
| 12 | Divine Blessings | Vertical Slice | Feature | game-designer, systems-designer | M |
| 13 | Camp | Vertical Slice | Feature | game-designer, ux-designer | S |
| 14 | Intimacy | Alpha | Feature | game-designer | M |
| 15 | Equipment | Alpha | Feature | game-designer | S |
| 16 | Exploration | Alpha | Feature | game-designer | S |
| 17 | Abyss Mode | Alpha | Feature | game-designer, systems-designer | L |
| 18 | Abyss Modifiers | Alpha | Feature | game-designer, economy-designer | M |
| 19 | Audio | Alpha | Infrastructure | game-designer, audio-director | S |
| 20 | Gallery | Full Vision | Polish | game-designer | S |
| 21 | Achievements | Full Vision | Polish | game-designer | S |

**Effort key**: S = 1 session, M = 2-3 sessions, L = 4+ sessions

---

## Circular Dependencies

None found. The dependency graph is a clean DAG. No systems have mutual dependencies.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Poker Combat | Design | Core loop — if poker hand evaluation doesn't feel satisfying in the first 5 minutes, no amount of content saves the game. Balatro's "juice" is hard to replicate. | Working prototype already exists (combat scene implemented). Playtest early and often. |
| Intimacy | Technical | Video playback on low-end mobile (looping videos per position) may have performance issues. Production pipeline for video assets is undefined. | Prototype video playback on target devices before committing to video-based approach. Consider animation fallback. |
| Abyss Mode | Design / Scope | Endless scaling balance is hard — 300 to 50,000 score targets with 1.6x scaling. Weekly modifiers add 10 variants to balance. Risk of degenerate strategies or impossible antes. | Design formulas with simulation. Playtest at high antes. Consider soft caps. |
| Divine Blessings | Design | 20 blessings that modify combat scoring must not create dominant strategies or make some companions strictly better than others. | Balance spreadsheet with interaction matrix. Cross-GDD review via /review-all-gdds. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 21 |
| Design docs started | 19 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 10/10 |
| Vertical Slice systems designed | 3/3 |
| Alpha systems designed | 6/6 |

---

## Next Steps

- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [x] Start with Companion Data: `/design-system companion-data`
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/review-all-gdds` after completing all MVP GDDs
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the highest-risk system early (`/prototype poker-combat`)
