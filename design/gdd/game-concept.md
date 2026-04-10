# Game Concept: Dark Olympus

*Created: 2026-04-08*
*Status: Approved*

---

## Elevator Pitch

> It's a narrative RPG / dating sim where you play Balatro-style poker combat
> against mythological enemies in a world where Greek gods have fallen, building
> romantic relationships with companion goddesses while collecting ancient Gaia
> fragments to restore divine authority.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Narrative RPG / Dating Sim / Poker Combat |
| **Platform** | Mobile (Android, iOS), Web (HTML5) |
| **Target Audience** | 18-35, mid-core mobile gamers who enjoy narrative + strategic card play |
| **Player Count** | Single-player |
| **Session Length** | 15-30 minutes (mobile sessions), longer on web |
| **Monetization** | TBD (premium likely; NSFW content limits store distribution) |
| **Estimated Scope** | Medium (6-12 months) |
| **Comparable Titles** | Balatro (poker combat), Hades (narrative progression through repeated runs), HuniePop (dating sim + puzzle combat) |

---

## Core Fantasy

You are a hero from another world, crash-landed in a broken mythological
realm where fallen Greek goddesses need your help. Through poker-based combat
you prove your strength; through dialogue and romance you earn their trust
and affection. The fantasy is being the mythological champion who restores
a shattered divine order while building intimate relationships with powerful,
complex women.

What makes this unique: combat mastery and romantic connection are intertwined.
Deeper relationships unlock divine blessings that make you stronger in combat.
Social investment IS mechanical investment.

---

## Unique Hook

Poker hands as a combat system in a dating sim. Your romantic relationships
with companion goddesses directly enhance your combat through divine blessings --
each companion's blessing modifies your poker scoring in unique ways based on
relationship depth. Romance isn't separate from gameplay; it IS gameplay.

"It's like Balatro, AND ALSO your poker hands are powered by divine blessings
from Greek goddesses you're dating."

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 3 | Rich visual novel art, satisfying card animations, gold/mythological UI theme |
| **Fantasy** (make-believe, role-playing) | 1 | Greek mythology setting, player as otherworldly hero, companion goddesses |
| **Narrative** (drama, story arc) | 2 | Branching dialogue, chapter-based story, character arcs per companion |
| **Challenge** (obstacle course, mastery) | 4 | Poker hand optimization, Abyss mode escalation, boss encounters |
| **Fellowship** (social connection) | N/A | Single-player; parasocial connection with companions serves this role |
| **Discovery** (exploration, secrets) | 5 | Unlockable CGs, hidden dialogue branches, exploration missions |
| **Expression** (self-expression, creativity) | 6 | Deck building, companion selection, dialogue choices shape personality |
| **Submission** (relaxation, comfort zone) | 7 | Camp daily interactions, ambient hub exploration, low-stakes gift-giving |

### Key Dynamics (Emergent player behaviors)

- Players optimize companion relationships to unlock combat-enhancing blessings
- Players experiment with different poker hand strategies per enemy weakness (element system)
- Players replay story branches to see alternate dialogue and unlock all CGs
- Players balance daily social actions (talk/gift/date) to maximize relationship gains via streak multipliers
- In Abyss mode, players adapt strategy to weekly modifiers and shop offerings

### Core Mechanics (Systems we build)

1. **Poker combat** -- select cards from a hand of 5, form poker hands, score chips x mult against enemy HP threshold
2. **Visual novel dialogue** -- typewriter text, character portraits with moods, branching choices with stat effects
3. **Companion romance** -- 5 relationship stages with daily interactions, dates, and intimacy scenes
4. **Divine blessings** -- 20 passive buffs (5 per companion) that modify poker scoring based on romance stage
5. **Roguelike Abyss** -- 8 antes with escalating targets, shop upgrades, weekly rotating challenge modifiers

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Dialogue branching, companion selection, deck strategy, exploration dispatch | Core |
| **Competence** (mastery, skill growth) | Poker hand optimization, Abyss difficulty scaling, blessing synergy discovery | Core |
| **Relatedness** (connection, belonging) | Companion romance arcs, parasocial relationships, character development | Core |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) -- CG collection, achievement milestones, relationship stage completion, Abyss ante progression
- [x] **Explorers** (discovery, understanding systems, finding secrets) -- Dialogue branches, hidden story paths, blessing combinations, exploration missions
- [x] **Socializers** (relationships, cooperation, community) -- Companion romance is the primary loop alongside combat; daily interactions, dates, intimacy
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) -- N/A (single-player, no PvP)

### Flow State Design

- **Onboarding curve**: Prologue tutorial fight (Forest Monster, 40 HP) teaches combat basics, then Artemis rescue introduces first companion, then opens up hub with progression options
- **Difficulty scaling**: Enemy HP thresholds scale per chapter; Abyss mode has 8 antes (300 to 50,000) with 1.6x endless scaling
- **Feedback clarity**: Score accumulates visually toward target threshold; relationship stage progress bars; blessing unlock notifications
- **Recovery from failure**: Combat allows 4 hands + 4 discards per fight; failure returns to hub with no permanent loss; Abyss runs are roguelike (expected failure)

---

## Core Loop

### Moment-to-Moment (30 seconds)
Select 1-5 cards from a hand of 5. Play a poker hand or discard to redraw.
Watch the score animate as chips x mult calculates against the enemy HP
threshold. Each decision is a risk/reward bet: play a weaker hand now or
discard for a chance at a stronger one.

### Short-Term (5-15 minutes)
Complete a story node: a dialogue scene (branching choices, character
interactions) followed by a combat encounter. After combat, receive rewards
(gold, XP, relationship points). Each story node advances the chapter plot
and deepens companion relationships.

### Session-Level (30-120 minutes)
Progress through 2-4 story nodes in a chapter. Visit camp for daily
interactions (talk, gift, date with companions). Manage equipment and deck.
Optionally enter Abyss for a roguelike run. Session ends at a natural
chapter break or after daily interaction limits.

### Long-Term Progression
Advance through chapters (Chapter 1: Sardis, Chapter 2: Thebes, ...).
Deepen all 4 companion relationships through 5 stages. Collect all 20
divine blessings. Unlock CG gallery. Push deeper into Abyss antes. Collect
Gaia fragments to progress the overarching story of restoring divine authority.

### Retention Hooks
- **Curiosity**: What happens next in the story? What's Chapter 2? What does the next relationship stage unlock?
- **Investment**: Companion relationships built over hours; Abyss progress; CG collection completion
- **Social**: N/A (single-player); potential community sharing of CG galleries and Abyss scores
- **Mastery**: Optimizing poker strategy with blessings; pushing Abyss ante records; discovering synergies

---

## Game Pillars

### Pillar 1: Balatro-Inspired Poker Combat
Combat is poker hand evaluation with chips x mult scoring. Every card play
is a strategic decision. The system must be deep enough to sustain hundreds
of encounters while remaining accessible in the first 5 minutes.

*Design test*: "Should we add real-time elements to combat?" -- No. Poker
is turn-based and deliberate. Speed comes from the Abyss timer pressure,
not from twitchy execution.

### Pillar 2: Visual Novel Dialogue with Consequences
Dialogue is the primary narrative delivery. Choices must have visible
consequences -- stat effects, relationship changes, flag-based story branching.
No fake choices; every option the player sees must matter.

*Design test*: "Should we skip dialogue to get to combat faster?" -- No.
Dialogue IS gameplay, not an obstacle between fights.

### Pillar 3: Companion Romance as Mechanical Investment
Romance is not a cosmetic layer -- it directly enhances combat via divine
blessings. Players who invest in relationships become mechanically stronger.
Each companion must feel distinct in personality, story, AND combat utility.

*Design test*: "Should blessings be purchasable instead of romance-locked?"
-- No. The romance-to-power pipeline is the core loop incentive.

### Pillar 4: Roguelike Abyss for Replayability
The Abyss provides infinitely replayable content after story chapters end.
Weekly modifiers keep it fresh. This is where late-game players spend most
of their time.

*Design test*: "Should Abyss progress persist between runs?" -- No. Roguelike
reset per run; only meta-progression (blessings, equipment) carries over.

### Anti-Pillars (What This Game Is NOT)

- **NOT open-world exploration**: The world is structured as chapters and nodes. No free-roam overworld. Open exploration would dilute the narrative pacing.
- **NOT competitive/multiplayer**: Single-player only. Companion relationships are parasocial. Adding PvP would require balancing the blessing system for fairness, undermining the "romance = power" fantasy.
- **NOT a gacha/loot box game**: Equipment and blessings are earned through gameplay progression, not random purchases. Monetization must not compromise the earn-it-yourself design.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Balatro | Poker hand evaluation as core mechanic; chips x mult scoring system; card enhancement (foil, holo, polychrome) | Combat has a narrative context (enemies, elements); blessings from romance instead of jokers | Validates that poker mechanics sustain hundreds of hours |
| Hades | Narrative that advances through repeated runs; character relationships deepen over time | Our narrative is linear chapters, not roguelike structure (Abyss is separate mode) | Validates narrative-through-gameplay loop |
| HuniePop | Dating sim mechanics integrated with puzzle combat | Poker replaces match-3; deeper narrative and character development; element system ties romance to combat | Validates dating sim + combat hybrid genre |

**Non-game inspirations**: Greek mythology (Ovid's Metamorphoses, classical art), visual novel tradition (Fate/stay night for mythological character reinterpretation), manga/anime aesthetic for character design.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-35 (NSFW content requires 18+) |
| **Gaming experience** | Mid-core; comfortable with card games and visual novels |
| **Time availability** | 15-30 minute mobile sessions; longer web sessions on weekends |
| **Platform preference** | Mobile primary, web secondary |
| **Current games they play** | Balatro, Genshin Impact, dating sims (Doki Doki, HuniePop), visual novels |
| **What they're looking for** | Strategic combat depth + meaningful character relationships + mythological setting |
| **What would turn them away** | Predatory monetization, shallow/repetitive combat, one-dimensional characters, forced grinding |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Godot 4.6 (migrated from React Native) |
| **Key Technical Challenges** | Touch-optimized card interaction; smooth portrait animations; save system versioning for content updates; intimacy scene performance (video playback) |
| **Art Style** | 2D illustrated; anime-influenced character portraits with mood variants; painterly backgrounds |
| **Art Pipeline Complexity** | Medium (custom 2D portraits, backgrounds, card assets; video for intimacy) |
| **Audio Needs** | Moderate (8 BGM tracks, 7+ SFX categories; all placeholder currently) |
| **Networking** | None (single-player, local save) |
| **Content Volume** | 2+ story chapters (18+ nodes each), 4 companions (6 moods each), 20 blessings, 10 Abyss modifiers, 18 screens |
| **Procedural Systems** | Abyss weekly modifier rotation; deck shuffling; exploration dispatch rewards |

---

## Risks and Open Questions

### Design Risks
- Core poker combat may feel repetitive after 50+ encounters without enough hand variety
- Romance pacing may feel grindy if daily interaction limits are too tight
- Abyss endless scaling may hit a hard wall where no strategy works

### Technical Risks
- Video playback for intimacy scenes may have performance issues on low-end mobile
- Portrait-mode touch targets at 430x932 leave tight spacing for card selection UI
- Save migration across content updates (new chapters) needs robust versioning

### Market Risks
- NSFW content limits distribution (no iOS App Store; Android sideload only; web primary)
- Niche genre intersection (poker + dating sim + mythology) may have a small addressable market
- Competitor landscape: Balatro dominates poker-mechanic space; HuniePop dominates dating-sim-combat hybrid

### Scope Risks
- 4 companions x 3 intimacy scenes x video assets = significant art production
- Chapter 2+ story content not yet written
- Spanish localization adds content doubling for every text asset

### Open Questions
- What is the monetization model? (Premium purchase vs. free with NSFW DLC vs. Patreon-funded)
- How will the game be distributed given NSFW content? (itch.io, web-only, sideload APK?)
- Should Chapter 2 companions (Atenea, Nyx) be playable in Abyss mode before their story chapter releases?
- What is the intimacy video production pipeline? (Live-action, animated, AI-generated?)

---

## MVP Definition

**Core hypothesis**: Players find the poker-combat + visual-novel-dialogue loop
engaging enough to complete Chapter 1 and want to continue to Chapter 2.

**Required for MVP** (Chapter 1 vertical slice):
1. Complete poker combat system with scoring, enhancements, and element mapping
2. Visual novel dialogue system with branching, portraits, mood variants
3. Chapter 1 story (9 nodes: prologue through tree temple)
4. 2 playable companions (Artemis, Hipolita) with relationship tracking
5. Hub screen with navigation to story, combat, camp
6. Save/load system

**Explicitly NOT in MVP** (defer to later):
- Abyss roguelike mode (requires complete blessing system)
- Intimacy scenes (requires video assets)
- Equipment system (additive, not core loop)
- Exploration dispatch missions
- Gallery, achievements, deck viewer screens
- Chapter 2 content
- Spanish localization

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | Chapter 1 (10 nodes), 2 companions | Combat, dialogue, hub, save | Current state |
| **Vertical Slice** | Chapter 1 complete + camp + blessings | + Daily interactions, blessings, settings | +2-3 months |
| **Alpha** | Chapter 1 + Abyss + all companion features | + Intimacy, equipment, exploration, deck | +4-6 months |
| **Full Vision** | Chapter 1-2+, all content, localized | All features, polished, NSFW content | +8-12 months |

---

## Characters

| ID | Name | Element | Stats (STR/INT/AGI) | Role | Personality |
|----|------|---------|---------------------|------|-------------|
| `artemis` | Artemis | Earth | 17/13/20 | Goddess of the Hunt | Clever, helpful, archer with bow |
| `hipolita` | Hipolita | Fire | 20/9/18 | Queen of the Amazons | Savage, horny, fearless. Red hair, muscled |
| `atenea` | Atenea | Lightning | 13/19/12 | Goddess of Wisdom | (Chapter 2+) |
| `nyx` | Nyx | Water | 18/19/8 | Primordial Goddess of Night | (Chapter 2+) |
| `priestess` | Priestess | -- | -- | Gaia Fragment (NPC) | Blonde, temple keeper. NOT a companion |

---

## Visual Identity Anchor

**Tone**: Mythological dark fantasy with warmth -- not grimdark, but a fallen world with hope.
**Color palette**: Deep brown (#2A1F14) background, gold (#D4A843) accents, cream (#F5E6C8) text. Element colors: Fire #F24D26, Water #338CF2, Earth #73BF40, Lightning #CCaa33.
**Typography**: Cinzel (display/titles), Nunito Sans (body).
**Character art style**: Anime-influenced with painterly shading; 6 mood variants per companion.

---

## Story Summary

### Prologue
Heroes and Gods won the war against Zeus, Poseidon, and Hades 1000 years ago.
Kronos broke free, turned back time, killed the old heroes. The world is broken,
gods scattered. You wake in a forest -- your ship crashed. Artemis saves you.

### Chapter 1: Sardis
10 story nodes: forest monster tutorial, Artemis rescue (companion unlock),
Artemis's house, tavern (meet village), mountains (Artemis backstory),
village attack (meet Hipolita), Hipolita's challenge, village report,
night siege (boss: Gaia Spirit), tree temple (Gaia revelation).
You learn about Gaia fragments and that the priestess IS one.

### Chapter 2: Thebes (not yet written)
Meet Atenea and Nyx. Third Gaia fragment held by a sorceress.

---

## Next Steps

- [x] Get concept approval *(working code validates concept)*
- [x] Configure engine (`/setup-engine` -- Godot 4.6)
- [ ] Decompose concept into systems (`/map-systems`)
- [ ] Create per-system GDDs (`/design-system` x8)
- [ ] Create architecture blueprint (`/create-architecture`)
- [ ] Create ADRs (`/architecture-decision` xN)
- [ ] Plan first sprint (`/sprint-plan new`)
