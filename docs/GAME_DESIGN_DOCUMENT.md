# Dark Olympus — Game Design Document

> Master reference for all systems, story, and implementation status.
> Engine: Godot 4.6 | Language: GDScript | Platform: Mobile (portrait) + Web

---

## 1. Game Overview

**Dark Olympus** is a narrative RPG / dating sim / poker combat game set in a world where Greek gods have fallen. The player is a hero from another world who crashed on Earth and must collect Gaia fragments while building relationships with companion goddesses.

**Core pillars:**
- **Balatro-inspired poker combat** — select cards, evaluate poker hands, score chips × mult
- **Visual novel dialogue** — branching choices with stat effects, typewriter text, portraits
- **Companion romance** — relationship stages, daily interactions, dates, NSFW intimacy scenes
- **Roguelike Abyss mode** — escalating antes, shop system, weekly modifiers

**Target:** Mobile (portrait mode, 430×932 viewport), Android + iOS, optional web export.

---

## 2. Story

### Prologue

**OLYMPUS — 1000 years ago**

Heroes and Gods won the war against Zeus, Poseidon and Hades. The rebellion was led by Heracles, goddess Mnemosyne, and a hero from another world. Peace lasted 1000 years until Kronos broke free, turned back time, and killed Zeus, Poseidon, and the hero. The world is broken — gods scattered.

**SARDIS — Present day**

You wake in a forest. Your ship crashed. Monsters attack. A girl with a bow (Artemis) saves you. You fall unconscious.

### Chapter 1: Sardis

1. **Artemis's House** — You wake up. She introduces herself. Agree to help fight monsters in exchange for finding an energy source for your ship.
2. **Tavern** — Meet village leader. The great tree is weakening, drawing monsters. Legend says restoring it grants power. Visit tree temple, meet priestess (Gaia fragment). Get blessing — weapon gains green energy ammo.
3. **Mountains** — Talk with Artemis about your pasts. She reveals she's Zeus's daughter. Earthquake — she falls in waterfall. You save her. Cave scene — intimacy (blowjob). Interrupted by monsters attacking village.
4. **Village attack** — Cyclops destroying village. Red-haired woman fighting it. You defeat cyclops. Meet Hippolyta, Queen of Amazons.
5. **Tavern** — Hippolyta agrees to help if you defeat her in a fight. You win (first man to do so). She takes you to her room — intimacy.
6. **Village report** — Explorers found dark crystal near ruins where monsters gather.
7. **Night siege (3 days later)** — Monsters attack. You infiltrate enemy camp, destroy dark crystal by fighting Gaia Spirit. Heroes celebrated. Threesome with Artemis + Hippolyta.
8. **Tree temple** — Priestess explains: dark crystal was one of three Gaia fragments. She IS one fragment (that's why only you see her). Third fragment held by a sorceress in Thebes. With all three, you can claim Gaia's authority. She thanks you with Paizuri.

### Chapter 2: Thebes (not yet written)

---

## 3. Characters

| ID | Name | Element | Stats (STR/INT/AGI) | Role | Personality |
|----|------|---------|---------------------|------|-------------|
| `artemisa` | Artemisa | Earth | 17/13/20 | Goddess of the Hunt | Clever, helpful, archer with bow |
| `hipolita` | Hipólita | Fire | 20/9/18 | Queen of the Amazons | Savage, horny, fearless. Red hair, muscled |
| `atenea` | Atenea | Lightning | 13/19/12 | Goddess of Wisdom | (Chapter 2+) |
| `nyx` | Nyx | Water | 18/19/8 | Primordial Goddess of Night | (Chapter 2+) |
| `priestess` | Priestess | — | — | Gaia Fragment (NPC) | Blonde, temple keeper. NOT a companion |

---

## 4. Combat System (Balatro-style Poker)

### Hand Ranks & Base Scores

| Rank | Chips | Mult |
|------|-------|------|
| High Card | 5 | 1× |
| Pair | 10 | 2× |
| Two Pair | 20 | 2× |
| Three of a Kind | 30 | 3× |
| Straight | 30 | 4× |
| Flush | 35 | 4× |
| Full House | 40 | 4× |
| Four of a Kind | 60 | 7× |
| Straight Flush | 100 | 8× |
| Royal Flush | 100 | 8× |

### Scoring Formula
```
score = floor((base_hand_chips + per_card_chips + enhancement_chips + blessing_chips) × (base_mult + enhancement_mult + blessing_mult))
```

### Per-Card Chips
Ace=11, J/Q/K=10, others=face value

### Enhancements
- **Foil:** +50 chips
- **Holographic:** +10 mult
- **Polychrome:** ×1.5 mult

### Combat Flow
1. Shuffle deck (52 cards, 4 suits mapped to 4 elements)
2. Draw 5 cards
3. Player selects cards (1-5), plays hand OR discards
4. Evaluate poker hand → calculate score
5. Score accumulates toward target_score (= enemy HP)
6. 4 hands + 4 discards per combat
7. Score >= target → Victory. Hands exhausted → Defeat.

### Suit → Element Mapping
hearts→Fire, diamonds→Water, clubs→Earth, spades→Lightning

### Divine Blessings (20 total, 5 per companion)
Unlocked by romance_stage (0-4). Applied during scoring:
- chips_bonus, mult_bonus, element_bonus, hand_rank_chips, hand_rank_mult
- play_five_chips, extra_discard, extra_hand

### Enemies (Chapter 1)
| Enemy | HP/Threshold | Context |
|-------|-------------|---------|
| Forest Monster | 40 | Prologue tutorial |
| Temple Beast | 80/50 | After tavern |
| Cyclops | 200/100 | Village attack |
| Hipólita Duel | 80/50 | Tavern challenge |
| Gaia Spirit | 250/130 | Night siege boss |

---

## 5. Romance & Social System

### Relationship Stages
Thresholds: [0, 21, 51, 71, 91] — 5 stages (0-4)

### Daily Interactions (Camp)
- **Talk:** +3 relationship
- **Gift:** +2 relationship
- **Date:** +5 relationship
- Streak multipliers: 1d=1.0×, 2d=1.1×, 3-4d=1.25×, 5-6d=1.4×, 7+d=1.5×

### Dates
- 4 rounds, 6 activity categories (romantic, active, intellectual, domestic, adventure, artistic)
- Base +5 relationship/round, bonuses for liked activities
- Requires relationship ≥ 21

### Social Combat Buffs
After talk/date/intimacy → companion grants CombatBuff (mult + chips bonus) for N combats.

### Intimacy
- **Phases:** invite → transition (3.5s cinematic) → scene (interactive) → complete
- **Mechanics:** Tap to build momentum → Speed tiers (slow/normal/fast/climax) → Ecstasy accumulates → Scenes unlock at 0%/30%/60%
- **Momentum:** max 20, decays every 1.5s
- **Speed tiers:** slow (0, 0.7× rate, 0.5 ecstasy/s), normal (4, 1.0×, 1.0), fast (9, 1.3×, 2.0), climax (16, 1.6×, 3.5)
- **Reward:** +10 relationship, +5 mult combat buff, CG unlock
- Each companion has 3 position scenes (cowgirl/doggy/missionary etc.)

---

## 6. Abyss (Roguelike Mode)

- 8 antes with escalating targets: [300, 800, 2000, 5000, 11000, 20000, 35000, 50000]
- 3 blinds per ante: small (1.0×), big (1.5×), boss (2.0×)
- Endless scaling: 1.6× after ante 8
- **Shop:** foil (100g), holographic (250g), polychrome (300g), remove card (75g), extra hand (200g), extra discard (150g)
- **10 weekly rotating modifiers:** zeus_wrath, poseidon_tide, hades_bargain, athenas_trial, ares_fury, hermes_speed, demeter_harvest, kronos_curse, gaia_blessing, apollo_light
- Effect types: element_boost, element_nerf, hand_rank_boost, fewer_hands, extra_discards, score_multiplier, gold_multiplier

---

## 7. Other Systems

### Equipment
- 2 slots: artifact, amulet
- Rarities: legendary, rare, common
- Stats: STR, AGI, INT modifiers

### Exploration
- Timed companion dispatch missions
- Node types: loot, encounter, story, rest
- Duration-based rewards

### Gallery
- CG (computer graphics) collection per companion
- Unlocked via intimacy completion, story events

### Achievements
- Milestone-based (first_combat, meet_all, gold_100, etc.)

### Save System
- JSON to user://save.json
- Version tracking for migration
- Autosave on state change (debounced)

---

## 8. UI/UX Design

### Theme
- **Background:** #2A1F14 (deep brown), #3D2E1E (secondary), #1A1410 (surface)
- **Gold accent:** #D4A843 (primary), #E8C65A (light), #B8963A (border)
- **Text:** #F5E6C8 (cream primary), #C4A882 (beige secondary)
- **Elements:** Fire #F24D26, Water #338CF2, Earth #73BF40, Lightning #CCaa33
- **Companion accents:** Atenea #3A5A7A, Nyx #4A2A6A, Hipolita #5A6A2A, Artemisa #2A6A5A
- **Fonts:** Cinzel (display/titles), Nunito Sans (body)

### Screens Needed (18 total)

| Screen | Priority | Description |
|--------|----------|-------------|
| **Splash** | ✅ DONE | Title, New Game / Continue |
| **Dialogue** | ✅ DONE | Typewriter text, portraits, branching choices |
| **Combat** | ✅ DONE | Poker card combat with scoring |
| **Hub** | ✅ DONE | Companion portrait, currency, bottom tabs |
| **Chapter Map** | HIGH | Chapter cards with play/continue, story progression |
| **Settings** | HIGH | Volume, language, NSFW, save/load |
| **Camp** | HIGH | Daily interactions, companion grid |
| **Companion Room** | MEDIUM | Stats, romance progress, gifts |
| **Date** | MEDIUM | 4-round activity picker |
| **Intimacy** | MEDIUM | 4-phase scene (invite→transition→scene→complete) |
| **Deck** | MEDIUM | Captain selection, companion cards |
| **Deck Viewer** | LOW | Card collection with element filters |
| **Equipment** | MEDIUM | Artifact/amulet slots |
| **Exploration** | MEDIUM | Dispatch missions |
| **Abyss** | MEDIUM | Roguelike shop + blinds |
| **Gallery** | LOW | CG collection |
| **Achievements** | LOW | Milestone tracking |

### Bottom Tab Bar (Hub)
| Tab | Label | Route |
|-----|-------|-------|
| 1 | TEAM | Deck/captain selection |
| 2 | ARENA | Quick combat (Arena Challenger, 200HP) |
| 3 | STORY | Chapter Map |
| 4 | CAMP | Daily interactions |
| 5 | SETTINGS | Settings screen |

---

## 9. Data Architecture

### Autoloads (Global Singletons)
| Autoload | Purpose |
|----------|---------|
| `GameStore` | Companions, flags, gold/xp, progress, equipment |
| `SettingsStore` | Volume, locale, NSFW, text speed |
| `DialogueStore` | Active dialogue, node traversal, choices |
| `CombatStore` | Combat phase, deck, hand, score, enemy |
| `SceneManager` | Scene transitions with fade |

### Data Files
| File | Purpose |
|------|---------|
| `data/enums.gd` | CompanionId, Mood, Element, Suit, HandRank, etc. |
| `data/balance.gd` | All game constants (combat, romance, abyss, intimacy) |
| `data/companions.gd` | 4 companions with stats, elements, portraits |
| `data/dialogues/*.json` | Dialogue trees (text_key references to i18n) |
| `data/story/chapters.json` | Chapter definitions with 18 nodes for Ch1 |
| `i18n/en.json` | 1,200+ translation keys |

### Systems
| System | Purpose |
|--------|---------|
| `combat_system.gd` | Hand evaluation, scoring pipeline, deck/enemy factories |
| `dialogue_runner.gd` | Load dialogue JSON, apply effects, translation lookup |
| `story_flow.gd` | Prologue controller (3 steps → hub) |
| `save_system.gd` | JSON save/load to user:// |

### Dialogue JSON Format
```json
{
  "id": "dialogue_name",
  "nodes": {
    "start": {
      "lines": [
        { "speaker": "narrator", "text_key": "TRANSLATION_KEY", "mood": null },
        { "speaker": "artemisa", "text_key": "KEY", "mood": "happy" }
      ],
      "next": "next_node_id",
      "choices": [
        { "text_key": "CHOICE_KEY", "next": "target_node", "effects": [...] }
      ]
    }
  }
}
```

### Story Node Types (chapters.json)
```json
{
  "id": "node_id",
  "type": "dialogue|combat|intimacy|reward",
  "dialogue_file": "ch01_s02_artemis_house",
  "companion": "artemisa",
  "background": "base_camp",
  "start_node": "start",
  "enemy_config": { "name_key": "ENEMY", "hp": 80, "score_threshold": 50 },
  "effects": [
    { "type": "meetCompanion", "target": "hipolita" },
    { "type": "setFlag", "target": "flag_name", "value": true },
    { "type": "addRelationship", "target": "artemisa", "amount": 8 },
    { "type": "addTrust", "target": "artemisa", "amount": 5 },
    { "type": "completeChapter", "target": "prologue" }
  ],
  "energy_cost": 0
}
```

---

## 10. Assets

### Companion Portraits (18 images)
3 companions × 6 moods (neutral, happy, sad, angry, surprised, seductive)
Location: `assets/images/companions/{id}/{id}_{mood}.png`
**Missing:** Artemisa (4th companion), Priestess (NPC)

### Backgrounds (24 images)
6 locations × 4 variants each
- `main_menu/` (fallen, glory, restored, twilight)
- `abyss/` (dormant, awakening, cosmic, sealed)
- `amazon_camp/` (day, night, rain, sunset)
- `base_camp/` (morning, evening, festive, night)
- `ruined_temple/` (day, night, storm, sunset)
- `shadow_realm/` (void, aurora, eclipse, nebula)

### Audio (all placeholders)
BGM: main_menu, hub, combat, dialogue, abyss, companion_room, date, exploration
SFX: card_play, card_discard, button_tap, victory, defeat, gold_collect, level_up

### Videos
None yet. Planned for intimacy scenes (looping video per position).

---

## 11. Migration Status (from React Native)

### DONE ✅
- Project structure (Godot 4.6, 430×932 portrait viewport)
- Data layer: enums, balance constants, companion definitions
- 5 autoloads: GameStore, SettingsStore, DialogueStore, CombatStore, SceneManager
- 4 systems: CombatSystem (full hand evaluation), DialogueRunner, StoryFlow, SaveSystem
- 4 scenes: Splash, Dialogue (typewriter + choices), Combat (full poker gameplay), Hub
- Prologue dialogue JSON (backstory with branching choices)
- Chapter 1 defined in chapters.json (18 nodes)
- 42 image assets copied (portraits + backgrounds)
- 1,200 translation keys (en.json)

### TODO — High Priority
- [ ] **Copy 15 dialogue JSONs** from RN project `src/data/dialogues/` (ch01_s01 through ch01_s09, companion free-roam)
- [ ] **StoryRunner system** — chapter node navigation (startChapter, navigateToNode, advanceStory)
- [ ] **Chapter Map scene** — chapter cards with unlock checks, play/continue buttons
- [ ] **Settings scene** — volume sliders, language toggle, NSFW, save/load buttons
- [ ] **Blessing system** — 20 blessings (5 per companion), applied during combat scoring
- [ ] **Autosave system** — debounced save on GameStore changes

### TODO — Medium Priority
- [ ] **AbyssStore autoload** — abyss run state, antes, blinds, shop
- [ ] **Abyss modifiers** — 10 weekly rotating challenge modifiers
- [ ] **Intimacy scenes data** — 3 positions per companion, speed tiers, ecstasy thresholds
- [ ] **Intimacy scene** — 4-phase (invite → transition → scene → complete) with momentum mechanics
- [ ] **Camp scene** — companion grid, daily interactions (talk/gift/date), streak tracking
- [ ] **Companion Room scene** — romance progress bars, stats, gallery hints
- [ ] **Date scene** — 4-round activity picker, 6 categories, relationship rewards
- [ ] **Deck scene** — companion grid, captain selection
- [ ] **Equipment scene** — artifact/amulet slots, rarity display
- [ ] **Exploration scene** — timed dispatch missions with node types
- [ ] **Companion room data** — seduction_data.json, companion_room_data.json
- [ ] **Date activity data** — en/es activity options, gifts

### TODO — Low Priority
- [ ] **Deck Viewer scene** — card collection with element filters
- [ ] **Gallery scene** — CG collection (no art yet)
- [ ] **Achievements scene** — milestone tracking
- [ ] **Audio service** — BGM/SFX playback (tracks are placeholders)
- [ ] **Particle effects** — GPUParticles2D for combat (score flash, enemy aura, victory confetti)
- [ ] **Card drag & drop** — Godot Input + Area2D for card reordering in combat
- [ ] **Theme resource** — Godot .tres theme with gold/brown colors and Cinzel/Nunito fonts

### TODO — Content
- [ ] Artemisa portrait artwork (6 moods)
- [ ] Priestess portrait artwork
- [ ] Intimacy video assets (looping per position)
- [ ] Audio tracks (BGM + SFX)
- [ ] CG gallery artwork
- [ ] Spanish translations for all keys (es.json)
- [ ] Chapter 2 story content (Thebes)

---

## 12. Source Reference

The original React Native project at `C:\Users\walte\Documents\dark-olympus-rn` contains:
- **23,000+ lines** across 18 screens, 7 stores, 8 systems, 34 components
- All game logic, balance numbers, and dialogue content that needs to be ported
- `docs/PROJECT_STATE.md` — detailed inventory of every file
- `docs/DARK_OLYMPUS_STORY.md` — master story document
- `docs/ENGINE_MIGRATION_ANALYSIS.md` — migration rationale

When implementing missing systems, reference the TypeScript source in the RN project for exact logic, then translate to idiomatic GDScript.
