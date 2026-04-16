# Quick Design Spec: Side Characters with Quests + Intimacy

> **Type**: Non-companion characters with relationship + quest systems
> **Author**: game-designer
> **Created**: 2026-04-16
> **Cross refs**: design/gdd/romance-social.md (relationship mechanics), design/gdd/companion-data.md (registry + state model), design/gdd/intimacy.md (intimate scene system)

---

## Problem

The game has 4 battle companions (Artemis, Hippolyta, Atenea, Nyx) but no other characters the player can build relationships with. Side content is limited to exploration missions and the gacha system. Players who want more character interaction — and a reason to keep playing between chapter beats — have nothing to pursue.

## Solution

Add **5 side characters** who have their own multi-step quest chains, can be talked to and gifted (reusing the existing romance system), and unlock intimate scenes when BOTH their personal quest is complete AND their romance stage reaches >= 3. These characters are **NOT battle companions** — no combat stats, no party slot, no BattleManager integration. They exist in the social/narrative layer of the game only.

**Intimacy gate**: dual — `quest_complete` flag AND `romance_stage >= 3`. Ensures both narrative investment and relationship investment before the payoff.

---

## Character Sheets

### 1. Daphne — The Herbalist Nymph

| Field | Value |
|---|---|
| **ID** | `daphne` |
| **Location** | Sardis village (Chapter 1, available after `ch01_exposition_done`) |
| **Role** | Forest nymph herbalist who tends the great tree's garden |
| **Personality** | Shy, kind, speaks to plants, touch-averse (mythological callback to fleeing Apollo) |
| **Visual concept** | Green hair with leaves, simple earth-toned dress, always carrying a basket of herbs |
| **Gameplay reward** | Healing potions (new consumable item type, usable pre-battle) |
| **Lore function** | Remembers the pre-Kronos world — her memories unlock backstory |
| **Likes** | wildflowers, woven_blanket |
| **Dislikes** | training_sword |

**Quest chain — "Garden of Memory" (4 nodes)**

| Node | Title | Type | Prereqs | Combat | RL reward | Flags set |
|---|---|---|---|---|---|---|
| `daphne_01` | The Wilting Garden | exploration | `ch01_exposition_done` | — | +10 | `daphne_01_done` |
| `daphne_02` | Moonlit Waters | dialogue + combat | `daphne_01_done` | 2× cave_bat | +15 | `daphne_02_done` |
| `daphne_03` | The Seed of Memory | exploration | `daphne_02_done` | — | +20 | `daphne_03_done` |
| `daphne_04` | Garden in Bloom | dialogue | `daphne_03_done` | — | +10 | `daphne_quest_complete` |

**Intimacy scene**: Moonlit garden. Daphne trusts you enough to lower her guard. Gentle, tender, slow. Natural setting under the great tree's branches.

---

### 2. Circe — The Sorceress of Thebes

| Field | Value |
|---|---|
| **ID** | `circe` |
| **Location** | Thebes (Chapter 2) |
| **Role** | Powerful enchantress, holds the third Gaia fragment |
| **Personality** | Morally ambiguous, seductive, manipulative but not evil — survived 1000 years by being smarter than everyone |
| **Visual concept** | Dark purple robes, golden circlet, mesmerizing eyes, magical aura |
| **Gameplay reward** | Equipment enchantment (+permanent stat bonus to one equipped item) |
| **Lore function** | Knew Zeus personally — reveals the gods' flaws and the rebellion's true cause |
| **Likes** | ancient_scroll, olive_oil |
| **Dislikes** | wild_berries |

**Quest chain — "The Enchantress's Price" (5 nodes)**

| Node | Title | Type | Prereqs | Combat | RL reward | Flags set |
|---|---|---|---|---|---|---|
| `circe_01` | The Enchantress's Test | dialogue | `ch02_start` | — | +10 | `circe_01_done` |
| `circe_02` | Titan's Blood | combat | `circe_01_done` | 2× obsidian_guardian | +15 | `circe_02_done` |
| `circe_03` | The Spy | dialogue (choices) | `circe_02_done` | — | +20 | `circe_03_done` |
| `circe_04` | Trust or Betray | dialogue (choice) | `circe_03_done` | — | +15 | `circe_quest_complete` |
| `circe_05` | The Third Fragment | main story | `circe_quest_complete` | — | +10 | `ch02_gaia_fragment` |

**Intimacy scene**: Circe's private chamber. She finally drops her masks — the seductress becomes vulnerable. Magical, intense, otherworldly.

---

### 3. Megara — The War Widow

| Field | Value |
|---|---|
| **ID** | `megara` |
| **Location** | Sardis outskirts → moves to Thebes (Ch1-2, mobile NPC) |
| **Role** | Heracles' widow. Runs a mercenary supply post. Only vendor in the game. |
| **Personality** | Tough, bitter, practical. Resists connection because everyone she loves dies. |
| **Visual concept** | Red-brown hair tied back, leather armor, scar across cheek, strong arms |
| **Gameplay reward** | Equipment vendor (the only shop). Heracles' legacy weapon (best Ch1-2 weapon). |
| **Lore function** | Fought alongside the original hero from another world. Recognizes something familiar about you. |
| **Likes** | training_sword, bronze_bracer |
| **Dislikes** | wildflowers |

**Quest chain — "The Widow's Legacy" (4 nodes)**

| Node | Title | Type | Prereqs | Combat | RL reward | Flags set |
|---|---|---|---|---|---|---|
| `megara_01` | The Widow's Trade | combat | `ch01_exposition_done` | 2× amazon_challenger | +10 | `megara_01_done` |
| `megara_02` | Heracles' Shield | exploration | `megara_01_done` | — | +15 | `megara_02_done` |
| `megara_03` | The Letter | dialogue | `megara_02_done`, `ch02_start` | — | +20 | `megara_03_done` |
| `megara_04` | Closure | combat | `megara_03_done` | 1× gaia_spirit (weak) | +15 | `megara_quest_complete` |

**Intimacy scene**: Her tent at night. Raw, emotional, not seductive. She cries afterward — not from sadness but because she didn't think she could feel this again.

---

### 4. Thetis — The Sea Nymph

| Field | Value |
|---|---|
| **ID** | `thetis` |
| **Location** | Coastal area / underwater grotto (Ch2-3) |
| **Role** | Mother of Achilles. Sea goddess hiding from Kronos's agents. |
| **Personality** | Reclusive, grieving, immortal. Terrified of connecting with a mortal again. |
| **Visual concept** | Silver-blue hair, iridescent skin, flowing water-like dress, pearls in her hair |
| **Gameplay reward** | Water enchantment for protagonist's gun. Unique amulet (Thetis' Pearl). |
| **Lore function** | Witnessed Kronos kill Poseidon. Reveals the full timeline-break story. |
| **Likes** | painted_stone, woven_blanket |
| **Dislikes** | honey_mead |

**Quest chain — "The Sea's Memory" (4 nodes)**

| Node | Title | Type | Prereqs | Combat | RL reward | Flags set |
|---|---|---|---|---|---|---|
| `thetis_01` | The Hidden Grotto | exploration | `ch02_coastal` | — | +10 | `thetis_01_done` |
| `thetis_02` | Achilles' Armor | combat | `thetis_01_done` | 3× river_drake | +15 | `thetis_02_done` |
| `thetis_03` | Poseidon's Echo | dialogue (ritual) | `thetis_02_done` | — | +20 | `thetis_03_done` |
| `thetis_04` | The Sea's Grief | boss combat | `thetis_03_done` | poseidon_echo | +15 | `thetis_quest_complete` |

**Intimacy scene**: Underwater grotto lit by bioluminescent fish. Thetis lets a mortal hold her for the first time in a thousand years. Ethereal and dreamlike.

---

### 5. Echo — The Cursed Bard

| Field | Value |
|---|---|
| **ID** | `echo_bard` |
| **Location** | Forest ruins near Sardis (Ch1, extends to Ch2) |
| **Role** | Nymph cursed by Hera to only repeat others' words. Communicates through song and gesture. |
| **Personality** | Haunting, melancholic, beautiful. Expressive despite being unable to speak freely. |
| **Visual concept** | Pale skin, long dark hair, simple white shift, always near broken columns or ruins |
| **Gameplay reward** | Battle song buffs (party-wide +2 ATK or +10 HP for the next fight) |
| **Lore function** | Cursed for helping Heracles during the rebellion. Breaking her curse reveals Hera's secret role. |
| **Likes** | painted_stone, explorers_map |
| **Dislikes** | bronze_bracer |

**Quest chain — "The Silent Song" (4 nodes, multi-chapter)**

| Node | Title | Type | Prereqs | Combat | RL reward | Flags set |
|---|---|---|---|---|---|---|
| `echo_01` | The Silent Song | dialogue | `ch01_exposition_done` | — | +10 | `echo_01_done` |
| `echo_02` | Mirror Fragment | exploration | `echo_01_done` | — | +15 | `echo_02_done` |
| `echo_03` | The Bard's Memory | dialogue | `echo_02_done` | — | +20 | `echo_03_done` |
| `echo_04` | Voice Restored | exploration + dialogue | `echo_03_done`, `ch02_start` | — | +15 | `echo_quest_complete` |

**Intimacy scene**: The forest ruins at sunset. Echo has just spoken her first original words — your name. Everything she couldn't say for centuries comes out. The most emotionally charged scene in the game.

---

---

### 6. Lyra — The Tavern Keeper

| Field | Value |
|---|---|
| **ID** | `lyra` |
| **Location** | Sardis tavern (Ch1, available after `ch01_tavern_done`) |
| **Role** | Tavern keeper — warm, flirty, street-smart. Hears every rumor. |
| **Personality** | Bold, practical, makes the first move. Laughs easily. |
| **Visual concept** | Auburn hair in a messy bun, apron, rolled sleeves, warm smile |
| **Gameplay reward** | Gold discount at tavern, rumor intel revealing hidden quest nodes |
| **Lore function** | Gossip hub — overheard conversations give context to world events |
| **Likes** | honey_mead, wild_berries |
| **Dislikes** | ancient_scroll |

**Quest chain — "Tavern Tales" (4 nodes)**: Stolen wine shipment → village festival → cursed trader → closing time

**Intimacy**: After the festival, late night closing. Lyra is bold — she initiates. Warm, fun, no drama.

---

### 7. Melina — The Village Leader's Daughter

| Field | Value |
|---|---|
| **ID** | `melina` |
| **Location** | Sardis village (Ch1, available after `ch01_exposition_done`) |
| **Role** | Sheltered, curious, wants to see the world. Father is overprotective. |
| **Personality** | Innocent, eager, bookish. Brave when she has to be. |
| **Visual concept** | Brown hair with braids, simple dress, always carrying a journal |
| **Gameplay reward** | Lore entries from hidden library, bonus RL with village NPCs |
| **Lore function** | Ancient library contains pre-Kronos history that no one else remembers |
| **Likes** | explorers_map, wildflowers |
| **Dislikes** | training_sword |

**Quest chain — "Between the Pages" (4 nodes)**: Sneak out → self-defense lesson → hidden library → shared secret

**Intimacy**: In the hidden library. Tender and exploratory. She's grateful you showed her the world.

---

### 8. Old Kostas — The Fisherman (No Romance)

| Field | Value |
|---|---|
| **ID** | `old_kostas` |
| **Location** | Sardis river (Ch1, available after `ch01_exposition_done`) |
| **Role** | Weathered fisherman. Mentor figure. 60 years on the river. |
| **Personality** | Gruff, wise, laconic. Tells stories through fishing metaphors. |
| **Visual concept** | Grey beard, sun-weathered skin, patched hat, old wooden rod |
| **Gameplay reward** | Fishing spot (exploration dispatch with bonus gold + XP) |
| **Lore function** | Remembers the river before it was corrupted. His stories connect to Naida. |
| **Type** | `side_no_romance` — quests only, no intimacy gate |

**Quest chain — "The Old Man and the River" (3 nodes)**: Dying river → legendary catch → rescue the boat

---

### 9. Naida — The River Nymph

| Field | Value |
|---|---|
| **ID** | `naida` |
| **Location** | Sardis river (Ch1, unlocks via Kostas' first quest) |
| **Role** | Shy water nymph who's been following Kostas' bait for years. |
| **Personality** | Shy, ethereal, gentle. Speaks in flowing sentences. |
| **Visual concept** | Translucent blue-green skin, water-like hair, iridescent eyes, no shoes |
| **Gameplay reward** | Water-element buff for next battle, healing fish consumables |
| **Lore function** | Knows the river's ancient connections to Poseidon's domain |
| **Likes** | painted_stone, wildflowers |
| **Dislikes** | training_sword |

**Quest chain — "The River's Secret" (4 nodes)**: Naida reveals herself → stolen pearl → reveal to Kostas → twilight together

**Intimacy**: River at twilight. Ethereal, water-themed. Connected to Kostas' blessing arc.

**Note**: Naida's quest requires completing Kostas' first quest (`kostas_01_done`) to unlock, and Kostas' full quest (`kostas_quest_complete`) to reach the reveal scene. The two quest chains are interleaved.

---

## Data Model

### Type field on companions.json

Add `"type": "side"` to distinguish side characters from battle companions. The existing 4 companions get `"type": "companion"` (or no field — backward-compatible default). The Priestess keeps `"type": "npc"`.

### State tracking

Side characters reuse the existing `GameStore._companion_states` system:
- `met`: set when the player first encounters them (via `CompanionRegistry.meet_companion`)
- `relationship_level`: increased by talk + gift actions (same as companions)
- `romance_stage`: derived from RL thresholds (same tiers: 0–4)

Quest progress tracked via `GameStore._story_flags`:
- Each quest node sets `{character_id}_{node_number}_done`
- Final node sets `{character_id}_quest_complete`

### Intimacy access check

```gdscript
static func can_access_intimacy(id: String) -> bool:
    var stage: int = CompanionState.get_romance_stage(id)
    var quest_done: bool = GameStore.has_flag(id + "_quest_complete")
    return stage >= 3 and quest_done
```

### Companion Room integration

Side characters appear in the Companion Room in a separate "Allies" section below the main companion grid. Each card shows:
- Portrait + name + role
- Talk button (uses existing `RomanceSocial.do_talk`)
- Gift button (uses existing `RomanceSocial.do_gift`)
- Quest button (opens quest progress / leads to quest dialogue)
- Intimacy button (visible only when dual gate is met)

No "Add to Party" button — side characters never enter battle.

### Quest data files

Each character has a quest JSON at `src/assets/data/quests/{id}.json`:

```json
{
  "quest_id": "daphne",
  "display_name_key": "QUEST_DAPHNE_TITLE",
  "nodes": [
    {
      "id": "daphne_01",
      "title_key": "QUEST_DAPHNE_01_TITLE",
      "description_key": "QUEST_DAPHNE_01_DESC",
      "type": "exploration",
      "prereqs": ["ch01_exposition_done"],
      "rewards": {
        "rl_companion": "daphne",
        "rl_amount": 10,
        "flags": ["daphne_01_done"]
      },
      "sequence": "daphne_wilting_garden"
    }
  ]
}
```

---

## Tuning Knobs

| Knob | Default | Range | Effect |
|---|---|---|---|
| RL per quest node | 10–20 | 5–30 | How fast romance progresses via quests |
| Romance stage 3 threshold | 51 RL | 40–60 | When intimacy becomes gatable |
| Gift RL gains | +1/+2 per interaction | — | Standard romance progression |
| Quest node count per character | 4-5 | 3-7 | Total quest length |
| Intimacy gate | quest_complete + stage >= 3 | — | Dual condition |

## Acceptance Criteria

- AC-SIDE-01: All 5 side characters appear in companions.json with `type: side`.
- AC-SIDE-02: Side characters appear in the Companion Room's "Allies" section after being met.
- AC-SIDE-03: Talk + Gift interactions work identically to battle companions.
- AC-SIDE-04: Each character's quest chain has a valid prereq progression (no broken flags).
- AC-SIDE-05: The intimacy scene is blocked until BOTH `{id}_quest_complete` flag is set AND `romance_stage >= 3`.
- AC-SIDE-06: Side characters cannot be added to the active party (no "Add to Party" button).
- AC-SIDE-07: Each quest node has a dialogue sequence file on disk.
- AC-SIDE-08: All localization keys referenced by quest nodes and character profiles resolve to non-empty English strings.
