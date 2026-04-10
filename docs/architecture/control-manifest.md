# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-04-09
> **Manifest Version**: 2026-04-09
> **ADRs Covered**: ADR-0001 through ADR-0015 (15 Accepted)
> **Status**: Active — regenerate with `/create-control-manifest` when ADRs change

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: GameStore, SaveManager, SceneManager, EventBus, Localization, UITheme, SettingsStore*

### Required Patterns

- **All mutable game state must live in GameStore.** No system maintains its own persistent state. Scene-local ephemeral state (e.g., combat encounter) is the only exception. — source: ADR-0001
- **Every GameStore setter must set `_dirty = true` and call `call_deferred("_flush_save")` if not already pending.** This ensures continuous persistence within 1 frame. — source: ADR-0001, ADR-0002
- **Save writes must use atomic temp-file + rename pattern.** Write to `user://save.json.tmp`, then `DirAccess.rename()` to `user://save.json`. Never overwrite directly. — source: ADR-0002
- **Check `FileAccess.store_string()` return value.** Returns `bool` since Godot 4.4 — was void. — source: ADR-0002
- **All scene transitions must go through `SceneManager.change_scene(SceneId)`.** Use the SceneId enum, never raw `.tscn` path strings. — source: ADR-0003
- **Input must be blocked during scene transitions.** Transition overlay sets `MOUSE_FILTER_STOP` during FADING_OUT/LOADING/FADING_IN. — source: ADR-0003
- **Settings screen must be an overlay on CanvasLayer 50**, not a scene change. Underlying scene stays alive. — source: ADR-0003
- **Hub tabs must use keep-alive hide/show**, not scene changes. No SceneManager call for tab switching. — source: ADR-0003
- **All cross-system signals must be declared on EventBus.** Emitters call `EventBus.[signal].emit()`. Listeners call `EventBus.[signal].connect()`. — source: ADR-0004
- **All player-facing text must resolve through `Localization.get_text(key, params)`.** No hardcoded strings in any scene or script. — source: ADR-0005
- **English string table must always be loaded as fallback baseline**, regardless of active locale. — source: ADR-0005
- **Autoloads must be ordered in project.godot as:** GameStore, SettingsStore, EventBus, Localization, SaveManager, SceneManager, CompanionRegistry, EnemyRegistry. Each may only reference autoloads listed before it during `_ready()`. — source: ADR-0006

### Forbidden Approaches

- **Never write to state owned by another system directly.** All mutations go through GameStore's typed setter methods. — source: ADR-0001
- **Never maintain parallel mutable state outside GameStore.** Scene-local ephemeral state (combat) is the only exception. — source: ADR-0001
- **Never call `SceneTree.change_scene_to_file()` outside `scene_manager.gd`.** — source: ADR-0003
- **Never connect signals directly across architectural layers.** Use EventBus. Foundation-to-Foundation direct signals are allowed (e.g., SceneManager.scene_changed). — source: ADR-0004
- **Never read `i18n/*.json` files directly.** Always use `Localization.get_text()`. — source: ADR-0005
- **Never reference a later autoload in `_ready()`.** Boot order is strict. — source: ADR-0006

### Performance Guardrails

- **Save write (JSON.stringify + file write)**: <3ms on minimum-spec mobile — source: ADR-0002
- **Locale switch (file load + JSON parse)**: <16.6ms (one frame at 60fps) — source: ADR-0005
- **Scene transition**: maintain 30fps during fade tweens — source: ADR-0003

---

## Core Layer Rules

*Applies to: CombatSystem, DialogueRunner, CompanionRegistry, CompanionState, EnemyRegistry*

### Required Patterns

- **Scoring pipeline must follow strict order:** additive chips → clamp(1) → additive mult → clamp(1.0) → multiplicative mult (Polychrome, captain) → floor. No reordering. — source: ADR-0007
- **Element interactions are per-card, independent.** Weak = +25 chips / +0.5 mult. Resist = -15 chips. Neutral = 0. Enemy element None disables all interactions. — source: ADR-0007
- **CombatSystem must call `BlessingSystem.compute()` as a black box.** Pass hand_context Dictionary, receive {blessing_chips, blessing_mult}. Do not inspect blessing internals. — source: ADR-0007
- **CombatSystem emits `combat_completed` via EventBus**, not a local signal. — source: ADR-0007
- **Hand rank values and element bonuses must be loaded from config files**, not hardcoded. — source: ADR-0007
- **DialogueRunner must emit effects via EventBus** (relationship_changed, trust_changed), not apply state directly. Flag effects may write to GameStore directly (Foundation layer, allowed). — source: ADR-0008
- **CompanionRegistry is read-only.** Static profiles loaded once at boot. No writes. — source: ADR-0009
- **CompanionState is a RefCounted utility class**, not an autoload. Static methods over GameStore. — source: ADR-0009

### Forbidden Approaches

- **Never modify the scoring pipeline order.** Additive before multiplicative. Chips before mult. Clamps at defined positions. — source: ADR-0007
- **Never import Feature-layer code from Core.** CombatSystem does not know about RomanceSocial. It receives social buffs as config data. — source: ADR-0006, ADR-0007
- **Never use Godot's built-in `tr()` for localization.** Use `Localization.get_text()`. — source: ADR-0005

### Performance Guardrails

- **Scoring pipeline + blessing computation**: <1ms per PLAY action — source: ADR-0007, ADR-0012
- **Dialogue JSON parse**: <2ms per sequence load — source: ADR-0008

---

## Feature Layer Rules

*Applies to: RomanceSocial, StoryFlow, BlessingSystem, DeckManager, GiftItems, Camp logic*

### Required Patterns

- **RomanceSocial is the sole writer of relationship state.** Other systems emit signals; R&S applies the changes via CompanionState/GameStore. — source: ADR-0010
- **Dialogue deltas (relationship_changed, trust_changed) are applied without streak multiplier.** Flat deltas from story data. — source: ADR-0010
- **BlessingSystem must be stateless (RefCounted with static methods).** Pure function: inputs → outputs. No persistent state, no signals, no autoload. — source: ADR-0012
- **Blessing slots must be evaluated sequentially 1-5.** Order matters — Nyx Slot 4 depends on accumulated chips from prior slots. — source: ADR-0012
- **Blessing set is frozen at combat start.** Stage changes mid-combat are ignored. CombatSystem caches romance_stage at setup. — source: ADR-0012
- **Gift purchase is immediate gift.** No inventory storage. Buy = gift = relationship effect. — source: ADR-0015

### Forbidden Approaches

- **Never import Foundation directly from Feature.** Access state through GameStore's public API only. — source: ADR-0006
- **Never store blessing state between combats.** BlessingSystem recomputes from scratch each PLAY. — source: ADR-0012

### Performance Guardrails

- **Blessing computation**: <0.1ms per PLAY (5 trigger evaluations) — source: ADR-0012

---

## Presentation Layer Rules

*Applies to: all .tscn scene files, UI nodes, VFX, animations*

### Required Patterns

- **All Control nodes inherit from the shared Theme .tres resource.** No screen defines its own colors or fonts. — source: ADR-0013
- **All touch targets minimum 44x44px hitbox.** Visual may be smaller; hitbox must not be. Primary buttons: 52px height. — source: ADR-0013
- **Primary actions in the bottom 560px (primary thumb zone).** Top 182px is passive (display only). — source: ADR-0013

### Forbidden Approaches

- **Never hardcode color values in scene files.** All colors reference theme tokens. — source: ADR-0013

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController` |
| Variables/Functions | snake_case | `move_speed` |
| Signals | snake_case past tense | `health_changed` |
| Files | snake_case matching class | `player_controller.gd` |
| Scenes | PascalCase matching root node | `PlayerController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60fps |
| Frame budget | 16.6ms |
| Draw calls | <200 per frame (mobile) |
| Memory ceiling | 512MB (mobile) |

### Approved Libraries / Addons

- GdUnit4 — approved for unit and integration testing

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or changed. Do not use them:

| Deprecated | Use Instead | Since |
|---|---|---|
| `TileMap` | `TileMapLayer` | 4.3 |
| `yield()` | `await signal` | 4.0 |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | 4.0 |
| `instance()` | `instantiate()` | 4.0 |
| `PackedScene.instance()` | `PackedScene.instantiate()` | 4.0 |
| `get_world()` | `get_world_3d()` | 4.0 |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | 4.0 |
| `duplicate()` for nested resources | `duplicate_deep()` | 4.5 |
| `bone_pose_updated` signal | `skeleton_updated` | 4.3 |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | 4.0+ |
| `Texture2D` in shader parameters | `Texture` base type | 4.4 |
| `$NodePath` in `_process()` | `@onready var` cached reference | Best practice |

Source: `docs/engine-reference/godot/deprecated-apis.md`

### Cross-Cutting Constraints

- **No upward layer imports.** Foundation ← Core ← Feature ← Presentation. Only downward. — source: ADR-0006
- **All gameplay values must be data-driven** (external config files or JSON), never hardcoded in logic. — source: technical-preferences.md
- **All public methods must be unit-testable** (dependency injection over singletons). — source: coding-standards.md
- **Commits must reference the relevant design document or task ID.** — source: coding-standards.md
- **Combat state is ephemeral.** Not persisted in GameStore. Lost on crash. Intentional. — source: ADR-0002
