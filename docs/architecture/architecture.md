# Dark Olympus — Master Architecture

## Document Status

- **Version**: 1
- **Last Updated**: 2026-04-09
- **Engine**: Godot 4.6
- **GDDs Covered**: Companion Data, Enemy Data, Save System, Localization, UI Theme, Scene Navigation, Poker Combat, Dialogue, Romance & Social, Story Flow, Deck Management, Divine Blessings, Camp + Gift Items (quick spec)
- **ADRs Referenced**: None yet — see Required ADRs section
- **Technical Director Sign-Off**: Pending
- **Lead Programmer Feasibility**: Pending

---

## Engine Knowledge Gap Summary

**Engine:** Godot 4.6 | **LLM Cutoff:** ~4.3 | **Post-Cutoff:** 4.4 (MEDIUM), 4.5 (HIGH), 4.6 (HIGH)

**Impact on this project:** LOW. Dark Olympus is a 2D, touch-only, Mobile-renderer game. The HIGH risk changes (Jolt physics, D3D12, glow pipeline, IK) target 3D/desktop features this project doesn't use.

| Domain | Risk | Relevant Change | Mitigation |
|---|---|---|---|
| UI/Focus | MEDIUM | Dual-focus system (4.6) — mouse/touch separate from keyboard/gamepad | Touch-only game. No gamepad. Verify MOUSE_FILTER behavior. |
| GDScript | LOW | Variadic args, @abstract (4.5) | New features. Opt-in, not breaking. |
| Accessibility | LOW | AccessKit screen reader (4.5) | Opportunity for a11y, not a risk. |
| Localization | LOW | CSV plural forms (4.6) | Additive feature. |
| Rendering | LOW | Glow/D3D12 changes | Using Mobile renderer. No glow in design. |
| Audio | LOW | No changes 4.4-4.6 | Stable API. |
| Physics | LOW | Jolt default (3D only) | 2D game. Physics unchanged. |

**Verified reference docs:** `docs/engine-reference/godot/` (VERSION.md, breaking-changes.md, deprecated-apis.md, current-best-practices.md, 8 module docs).

---

## Technical Requirements Baseline

Extracted from 13 GDDs + 1 quick spec | **83 total requirements**

| System | GDD | TR Count | Key Domains |
|---|---|---|---|
| Companion Data | companion-data.md | 6 | Data lookup, state persistence, stage derivation, portraits |
| Enemy Data | enemy-data.md | 3 | Static registry, localization keys |
| Save System | save-system.md | 6 | JSON persistence, atomic write, migration, continuous save |
| Localization | localization.md | 5 | String lookup, fallback chain, locale switching |
| UI Theme | ui-theme.md | 6 | Theme resource, touch targets, thumb zones, haptics |
| Scene Navigation | scene-navigation.md | 7 | Scene changes, transitions, overlays, context payload |
| Poker Combat | poker-combat.md | 12 | Deck, hand eval, scoring pipeline, elements, enhancements |
| Dialogue | dialogue.md | 9 | JSON scripts, typewriter, choices, effects, gating |
| Romance & Social | romance-social.md | 10 | Tokens, streaks, moods, gifts, dates, combat buffs |
| Story Flow | story-flow.md | 8 | Chapter JSON, node sequencing, flags, rewards |
| Deck Management | deck-management.md | 5 | Captain selection, deck viewer, handoff signal |
| Divine Blessings | divine-blessings.md | 6 | Slot unlock, trigger eval, pipeline injection |
| Camp | camp.md | 5 | Hub sub-tab, companion grid, gift picker |
| Gift Items | quick-specs/gift-items.md | 3 | Item registry, purchase flow, gold deduction |

Full TR-ID registry: `docs/architecture/tr-registry.yaml` (populated after ADRs are written).

---

## System Layer Map

```
+----------------------------------------------------------------+
|  PRESENTATION LAYER                                             |
|  All .tscn scene files, VFX, animations, card visuals          |
|  > Hub, Combat, Dialogue, ChapterMap, Camp, Date, DeckViewer,  |
|    CompanionRoom, Splash, Settings (overlay)                    |
+----------------------------------------------------------------+
|  FEATURE LAYER                                                  |
|  > RomanceSocial  -- tokens, streaks, moods, buffs, stage mgmt |
|  > StoryFlow      -- chapter nodes, flags, sequencing, rewards  |
|  > DivineBlessing -- blessing computation, trigger evaluation   |
|  > DeckManager    -- captain selection, deck build, handoff     |
|  > Camp (logic)   -- gift picker flow, interaction dispatch     |
|  > GiftItems      -- item registry, purchase validation         |
+----------------------------------------------------------------+
|  CORE LAYER                                                     |
|  > CombatSystem   -- scoring pipeline, hand eval, state machine |
|  > DialogueRunner -- script playback, typewriter, choices       |
|  > CompanionData  -- profile registry + mutable state logic     |
|  > EnemyData      -- static enemy profile registry              |
+----------------------------------------------------------------+
|  FOUNDATION LAYER                                               |
|  > GameStore      -- all mutable game state (single source)     |
|  > SettingsStore  -- player settings (locale, volume, text spd) |
|  > SaveManager    -- JSON persistence, migration, continuous    |
|  > Localization   -- string tables, get_text(), fallback chain  |
|  > SceneManager   -- transitions, overlays, input blocking      |
|  > UITheme        -- .tres Theme resource, color/font tokens    |
|  > EventBus       -- cross-system signal relay (decoupling)     |
+----------------------------------------------------------------+
|  PLATFORM LAYER                                                 |
|  Godot 4.6 - Mobile Renderer - GDScript - Touch Input          |
+----------------------------------------------------------------+
```

### Layer Rules

1. **No upward imports.** A module may only import from its own layer or layers below it.
2. **Foundation never imports Core.** Foundation is engine-integration and pure infrastructure.
3. **Core never imports Feature.** CombatSystem does not know about RomanceSocial.
4. **Cross-layer communication via EventBus signals only.** This is the sole exception to the import rule.
5. **Presentation imports everything** (scenes instantiate and wire up all layers).

---

## Module Ownership

### Foundation Layer (Autoloads)

| Module | Owns | Exposes | Consumes |
|---|---|---|---|
| **GameStore** | All mutable game state: companion_states, story_flags, gold, xp, chapter, node_states, combat_buff, tokens, streak, interaction_date | get/set per field, to_dict(), from_dict(), state_changed signal | Nothing (root) |
| **SettingsStore** | Player settings: locale, master_volume, sfx_volume, music_volume, text_speed | get/set per field, to_dict(), from_dict() | Nothing |
| **SaveManager** | Save file path, version | save_game(), load_game(), has_save(), delete_save() | GameStore, SettingsStore |
| **Localization** | String tables, active locale | get_text(key, params), switch_locale(code), locale_changed signal | SettingsStore |
| **SceneManager** | Transition state, overlay state, previous_scene_id, arrival_context | change_scene(), open_settings_overlay(), get_arrival_context(), scene_changed/transition_started signals | Nothing |
| **UITheme** | Theme .tres resource | Inherited by all Control nodes | Nothing |
| **EventBus** | Nothing (relay only) | Typed signals for cross-system communication | Nothing |

### Core Layer

| Module | Owns | Exposes | Consumes |
|---|---|---|---|
| **CompanionRegistry** | Static companion profiles (immutable) | get_profile(id), get_all_ids(), get_portrait_path() | Nothing |
| **CompanionState** | Stage derivation logic (data in GameStore) | get_state(id), get_romance_stage(id), set_relationship_level() | GameStore |
| **EnemyRegistry** | Static enemy profiles (immutable) | get_enemy(id) | Localization |
| **CombatSystem** | Combat encounter state (scene-local, ephemeral) | start_combat(), play_hand(), discard(), combat_completed signal | CompanionRegistry, EnemyRegistry, BlessingSystem, GameStore |
| **DialogueRunner** | Active dialogue sequence state | start_dialogue(), dialogue_ended/blocked signals | Localization, CompanionRegistry |

### Feature Layer

| Module | Owns | Exposes | Consumes |
|---|---|---|---|
| **RomanceSocial** | Interaction logic, mood transitions, streak calc, buff generation | do_talk(), do_gift(), start_date(), get_token_count(), get_mood() | GameStore, CompanionState, EventBus |
| **StoryFlow** | Node sequencing, flag management | enter_node(), get_available_nodes(), get_chapter_state() | GameStore, SceneManager, DialogueRunner, EventBus |
| **BlessingSystem** | Blessing definitions, trigger evaluation (stateless) | compute(captain_id, stage, hand_context) -> {chips, mult} | CompanionState, CompanionRegistry |
| **DeckManager** | Deck composition, captain confirmation | build_deck(), combat_configured signal | CompanionRegistry, GameStore |
| **GiftItems** | Gift item definitions (data-driven) | get_items(), can_afford() | GameStore |

---

## Data Flow

### Story Combat Flow (Core Loop)

```
Player taps story node on Chapter Map
    |
    v
StoryFlow.enter_node("ch01_n04")
    |--- type == "mixed" -> start dialogue first
    v
DialogueRunner.start_dialogue("ch01", "ch01_n04_pre")
    |   <- reads Localization.get_text() for text
    |   <- reads CompanionRegistry for portraits
    v   signal: dialogue_ended (via EventBus)
    |
StoryFlow receives -> launches combat
    v
SceneManager.change_scene(COMBAT, {enemy_id, mode: "story"})
    |   [FADE transition, 0.3s out]
    v
DeckManager (captain selection)
    |   <- reads CompanionRegistry (met, stats)
    |   <- reads GameStore (last_captain_id)
    v   player confirms -> emits combat_configured
    |
CombatSystem.start_combat(config)
    |   <- reads GameStore (social_buff)
    |   <- BlessingSystem caches captain's blessings
    |
    |   [DRAW -> SELECT -> PLAY loop]
    |   Per PLAY:
    |     1. Hand eval (rank, base chips/mult)
    |     2. Per-card chips + enhancements
    |     3. Element interaction (suit vs enemy)
    |     4. BlessingSystem.compute() -> blessing_chips/mult
    |     5. Captain bonus (STR->chips, INT->mult)
    |     6. Social buff (from config)
    |     7. Clamp (chips min 1, mult min 1.0)
    |     8. score = floor(total_chips x final_mult)
    |     9. Victory check
    |
    v   signal: combat_completed (via EventBus)
    |
StoryFlow: grant rewards (gold, XP -> GameStore), set flags, mark completed
RomanceSocial: captain +1 RL, buff decrement (via GameStore)
    |
    v   GameStore._dirty = true -> SaveManager persists next frame
    |
SceneManager.change_scene(CHAPTER_MAP)
```

### Camp Interaction Flow

```
Hub tab switch -> Camp tab (keep-alive show)
    |
Camp UI reads: RomanceSocial (tokens, streak, mood),
               CompanionState (stage, RL), CompanionRegistry (met, portraits)
    |
    v   Player taps companion -> Talk
    |
Camp calls: RomanceSocial.do_talk("artemisa")
    |
RomanceSocial:
  1. Validate tokens > 0
  2. Calculate base_RL (3 or 4 if Happy)
  3. Apply streak multiplier -> floor()
  4. GameStore: relationship_level += gain, token -= 1
  5. Update mood -> GameStore
  6. Re-evaluate romance_stage
  7. If stage advanced -> EventBus.emit(romance_stage_changed)
    |
    v   returns {rl_gain, new_mood, stage_changed}
    |
Camp UI updates: portrait crossfade, RL bar, token pip
GameStore._dirty = true -> SaveManager persists next frame
```

### Save/Load Path (Continuous Persistence)

```
SAVE (every frame if dirty):
  GameStore._process():
    if _dirty:
      SaveManager.save_game()
      _dirty = false

  SaveManager.save_game():
    data = { version, timestamp, game: GameStore.to_dict(),
             settings: SettingsStore.to_dict() }
    JSON.stringify(data) -> temp file
    Rename temp -> user://save.json (atomic)

LOAD (on Continue):
  SaveManager.load_game():
    FileAccess.open("user://save.json")
    JSON.parse() -> data
    Version check -> migration chain if needed
    GameStore.from_dict(data["game"])   -- _dirty stays false
    SettingsStore.from_dict(data["settings"])
    Localization.switch_locale(SettingsStore.locale)

COMBAT EXCEPTION:
  Combat state (deck, hand, score) NOT in GameStore.
  Scene-local in CombatSystem. Lost on crash.
  Resume: Chapter Map, node in_progress, retry prompt.
```

### Autoload Boot Order

```
1. GameStore        <- no dependencies
2. SettingsStore    <- no dependencies
3. EventBus         <- no dependencies (signal definitions only)
4. Localization     <- reads SettingsStore.locale in _ready()
5. SaveManager      <- reads GameStore + SettingsStore
6. SceneManager     <- creates transition overlay
7. CompanionRegistry <- loads static data
8. EnemyRegistry    <- loads static data
```

No circular dependencies. Each autoload only reads from autoloads loaded before it.

---

## API Boundaries

### Foundation Layer

```gdscript
# -- GameStore (autoload) --
extends Node
signal state_changed(key: String)

# Companion state
func get_companion_state(id: String) -> Dictionary
func _set_relationship_level(id: String, value: int) -> void  # Internal — only CompanionState calls this
func get_relationship_level(id: String) -> int
func set_trust(id: String, value: int) -> void
func set_met(id: String, value: bool) -> void
# romance_stage: derived by CompanionState.get_romance_stage(), NOT stored on GameStore API

# Story state
func get_story_flags() -> Array[String]
func has_flag(flag: String) -> bool
func set_flag(flag: String) -> void
func get_node_state(node_id: String) -> String
func set_node_state(node_id: String, state: String) -> void

# Economy
func get_gold() -> int
func add_gold(amount: int) -> void
func spend_gold(amount: int) -> bool

# Combat buff
func get_combat_buff() -> Dictionary
func set_combat_buff(buff: Dictionary) -> void
func clear_combat_buff() -> void

# Romance state
func get_daily_tokens() -> int
func spend_token() -> void
func reset_tokens() -> void
func get_streak() -> int
func set_streak(days: int) -> void

# Serialization
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void


# -- SaveManager (autoload) --
extends Node
func save_game() -> bool
func load_game() -> bool
func has_save() -> bool
func delete_save() -> void


# -- Localization (autoload) --
extends Node
signal locale_changed
func get_text(key: String, params: Dictionary = {}) -> String
func switch_locale(code: String) -> bool


# -- SceneManager (autoload) --
extends Node
signal scene_changed(scene_id: int)
signal transition_started(scene_id: int)
enum SceneId { SPLASH, DIALOGUE, COMBAT, HUB, CHAPTER_MAP, CAMP,
    COMPANION_ROOM, DATE, INTIMACY, DECK, DECK_VIEWER, EQUIPMENT,
    EXPLORATION, ABYSS, GALLERY, ACHIEVEMENTS, SETTINGS }
enum TransitionType { FADE, INSTANT, NONE }
func change_scene(id: SceneId, transition: TransitionType = FADE,
    context: Dictionary = {}) -> void
func open_settings_overlay() -> void
func get_arrival_context() -> Dictionary
func is_transitioning() -> bool


# -- EventBus (autoload) --
extends Node
signal romance_stage_changed(companion_id: String, old_stage: int, new_stage: int)
signal combat_completed(result: Dictionary)
signal dialogue_ended(sequence_id: String)
signal dialogue_blocked(sequence_id: String, reason: String)
signal companion_met(companion_id: String)
signal relationship_changed(companion_id: String, delta: int)
signal trust_changed(companion_id: String, delta: int)
signal tokens_reset
signal chapter_completed(chapter_id: String)
```

### Core Layer

```gdscript
# -- CompanionRegistry (autoload) --
extends Node
func get_profile(id: String) -> Dictionary
func get_all_ids() -> Array[String]
func get_element_for_suit(suit: String) -> String
func get_portrait_path(id: String, mood: String) -> String

# -- EnemyRegistry (autoload) --
extends Node
func get_enemy(id: String) -> Dictionary

# -- CombatSystem (scene-local) --
extends Node
signal hand_scored(score: int, breakdown: Dictionary)
func start_combat(config: Dictionary) -> void
func play_hand(selected_indices: Array[int]) -> void
func discard(selected_indices: Array[int]) -> void
func get_state() -> Dictionary

# -- DialogueRunner --
extends Node
func start_dialogue(chapter_id: String, sequence_id: String) -> void
```

### Feature Layer

```gdscript
# -- RomanceSocial (autoload) --
extends Node
func do_talk(companion_id: String) -> Dictionary
func do_gift(companion_id: String, item_id: String) -> Dictionary
func start_date(companion_id: String) -> void
func get_token_count() -> int
func get_streak() -> int
func get_streak_multiplier() -> float
func get_mood(companion_id: String) -> int

# -- StoryFlow (autoload) --
extends Node
func load_chapter(chapter_id: String) -> void
func enter_node(node_id: String) -> void
func get_available_nodes() -> Array[Dictionary]
func get_chapter_state() -> Dictionary

# -- BlessingSystem (stateless utility) --
extends RefCounted
static func compute(captain_id: String, romance_stage: int,
    hand_context: Dictionary) -> Dictionary

# -- DeckManager (scene-local or utility) --
extends Node
signal combat_configured(config: Dictionary)
func build_deck() -> Array
func get_captain_chip_bonus(str_val: int) -> int
func get_captain_mult_bonus(int_val: int) -> float

# -- GiftItems (stateless utility) --
extends RefCounted
static func get_items() -> Array[Dictionary]
static func get_item(id: String) -> Dictionary
static func can_afford(item_id: String, player_gold: int) -> bool
```

### Key Invariants

1. **No Feature -> Foundation imports.** Feature accesses state only through GameStore API.
2. **No Core -> Feature imports.** CombatSystem receives social buffs as data, not by importing RomanceSocial.
3. **Signals cross layers freely** via EventBus.
4. **BlessingSystem is stateless.** Pure function: inputs -> outputs.
5. **All engine types (Node, SceneTree, Tween) confined to Foundation + Presentation.**

---

## ADR Audit

No existing ADRs found. All architectural decisions in this document require formal ADRs.

---

## Required ADRs

### Must have before coding starts (Foundation)

| # | ADR Title | Layer | Covers |
|---|---|---|---|
| 1 | GameStore: Centralized State Architecture | Foundation | Single state owner, dirty-flag persistence, to_dict/from_dict |
| 2 | Save System: Continuous Persistence | Foundation | Per-frame save, atomic write, version migration, combat exception |
| 3 | Scene Management: SceneId Registry + Transitions | Foundation | SceneId enum, FADE/INSTANT, overlay pattern, context payload |
| 4 | EventBus: Cross-System Signal Architecture | Foundation | Typed signal relay, layer isolation, signal catalog |
| 5 | Localization: String Resolution Pipeline | Foundation | get_text() API, fallback chain, locale switching |
| 6 | Autoload Boot Order + Dependency Rules | Foundation | Load sequence, layer import constraints |

### Must have before the relevant system is built (Core + Feature)

| # | ADR Title | Layer | Covers |
|---|---|---|---|
| 7 | Poker Combat: Scoring Pipeline Architecture | Core | Chips x mult pipeline, injection points, clamps |
| 8 | Dialogue: Script Format + Playback Engine | Core | JSON node graph, typewriter, choices, effects |
| 9 | Companion Data: Registry + State Schema | Core | Static profiles vs mutable state, stage derivation |
| 10 | Romance & Social: Interaction Engine | Feature | Tokens, streaks, moods, buffs, preference discovery |
| 11 | Story Flow: Chapter Node Sequencer | Feature | JSON chapters, node state machine, flags, rewards |
| 12 | Divine Blessings: Trigger Evaluation Pipeline | Feature | Per-hand computation, sequential slots, captain lock |

### Can defer to implementation sprint

| # | ADR Title | Layer | Covers |
|---|---|---|---|
| 13 | UI Theme: Token System + Touch Standards | Foundation | Theme .tres, color/font tokens, touch minimums |
| 14 | Deck Management: Captain Selection + Handoff | Feature | Captain grid, combat_configured signal, deck build |
| 15 | Gift Items: Purchase Flow + Gold Economy | Feature | Item registry, immediate purchase, gold deduction |

---

## Architecture Principles

1. **Single State Owner.** All mutable game data lives in GameStore. Systems compute and act; GameStore remembers. No parallel state.
2. **Continuous Persistence.** Every GameStore mutation persists within 1 frame. No "unsaved progress." Combat is the only ephemeral state.
3. **Layer Isolation.** Foundation <- Core <- Feature <- Presentation. No upward imports. Cross-layer via EventBus signals only.
4. **Data-Driven Everything.** All gameplay values (enemy stats, blessings, hand ranks, streaks) live in config resources or JSON, never hardcoded.
5. **Touch-First, Portrait-Only.** Every UI decision assumes 430x932 portrait with thumb-zone constraints. No hover, no keyboard shortcuts, no landscape.

---

## Open Questions

| Question | Owner | Impact | Deadline |
|---|---|---|---|
| Should DialogueRunner be an autoload or scene-local? | technical-director | Affects whether dialogue state survives scene changes. Current: either works since dialogue is stateless between sequences. | Before ADR-8 |
| Should CompanionState be merged into GameStore or remain a separate logic class? | technical-director | Separate = cleaner SRP. Merged = fewer files. | Before ADR-9 |
| Should the EventBus use typed signal parameters or Dictionary payloads? | lead-programmer | Typed = compile-time safety. Dictionary = flexibility for future signals. | Before ADR-4 |
| How should RomanceSocial handle UTC midnight while the app is backgrounded? | technical-director | Affects token reset reliability. Options: OS notification, periodic check, resume-from-background hook. | Before ADR-10 |
