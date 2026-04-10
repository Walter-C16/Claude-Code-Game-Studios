# ADR-0006: Autoload Boot Order + Layer Dependency Rules

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (project configuration) |
| **Knowledge Risk** | LOW — Autoload behavior unchanged since 4.0. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 through ADR-0005 (defines the autoloads this ADR orders) |
| **Enables** | All Core/Feature ADRs — establishes the framework they build on |
| **Blocks** | Implementation — project.godot autoload order must match this spec |
| **Ordering Note** | Last Foundation ADR. Codifies what ADRs 1-5 establish individually. |

## Context

### Problem Statement

Godot loads autoloads in the order they appear in Project Settings. If Localization's `_ready()` reads `SettingsStore.locale` but SettingsStore hasn't loaded yet, the locale defaults to English regardless of the save. The boot order must be explicitly defined and enforced.

Additionally, the layer isolation rules (no upward imports) established across ADRs 1-5 need a single, referenceable document that programmers can check.

## Decision

### Autoload Boot Order

Configure in `project.godot` `[autoload]` section, in this exact order:

```
 1. GameStore         — No dependencies. All state lives here.
 2. SettingsStore     — No dependencies. Player settings.
 3. EventBus          — No dependencies. Signal declarations only.
 4. Localization      — Reads SettingsStore.locale in _ready().
 5. SaveManager       — Calls GameStore.from_dict() + SettingsStore.from_dict() on load.
 6. SceneManager      — Creates transition overlay CanvasLayer in _ready().
 7. CompanionRegistry — Loads static companion profiles from data files.
 8. EnemyRegistry     — Loads static enemy profiles from data files.
 9. DialogueRunner    — Reads EventBus, Localization. Playback engine for dialogue sequences.
10. RomanceSocial     — Reads GameStore, EventBus, CompanionRegistry. Interaction engine.
11. StoryFlow         — Reads GameStore, EventBus, SceneManager, CompanionRegistry. Chapter sequencer.
```

**Rule**: Each autoload may only reference autoloads listed ABOVE it in this order during `_ready()`. No autoload may call downward during initialization.

**Note (2026-04-09 update)**: Autoloads 9-11 were added to resolve architecture review blocker — ADRs 0008, 0010, and 0011 each define an autoload but they were not listed in the original boot order.

### Layer Import Rules

```
PRESENTATION  may import  FEATURE, CORE, FOUNDATION
FEATURE       may import  CORE, FOUNDATION
CORE          may import  FOUNDATION
FOUNDATION    may import  (nothing — only Godot engine APIs)
```

**Enforcement**: Code review + grep audit. Any `preload()` or `load()` that crosses layers upward is a violation.

**Exception**: EventBus signals cross all layers by design (ADR-0004). This is signal-based communication, not file import.

### Autoload Access Rules

| Autoload | Who may access | Access type |
|---|---|---|
| GameStore | All layers | Read: any. Write: only through typed setters. |
| SettingsStore | Foundation (Localization, SaveManager) + Presentation (Settings UI) | Read: any. Write: Settings UI only. |
| EventBus | All layers | Emit: any system for its own events. Connect: any listener. |
| Localization | All layers | Read-only via get_text(). Write: only switch_locale() from Settings UI. |
| SaveManager | Foundation only (called by GameStore._flush_save) + Presentation (Splash for load, Settings for delete) | Called by GameStore for saves. UI for load/delete. |
| SceneManager | All layers (any system may request navigation) | change_scene(), open_settings_overlay() |
| CompanionRegistry | Core + Feature + Presentation | Read-only. Static data. |
| EnemyRegistry | Core + Feature + Presentation | Read-only. Static data. |
| DialogueRunner | Feature + Presentation | start_dialogue(), advance(). Emits effects via EventBus. |
| RomanceSocial | Feature + Presentation | talk(), gift(), start_date(). Reads/writes companion state via GameStore. |
| StoryFlow | Feature + Presentation | start_chapter(), advance_node(). Orchestrates dialogue + combat sequences. |

## Alternatives Considered

### Alternative 1: No Formal Boot Order (Rely on Godot Defaults)

- **Description**: Let Godot load autoloads in whatever order they appear in Project Settings without documenting it.
- **Pros**: Less documentation to maintain.
- **Cons**: Silent bugs when load order is accidentally rearranged. Localization reads stale locale. SaveManager can't restore state if GameStore isn't ready. These bugs are hard to diagnose because they only manifest in specific conditions (fresh install, locale change, etc.).
- **Rejection Reason**: The dependencies between autoloads are real. Documenting the order prevents a class of bugs that are silent, intermittent, and hard to reproduce.

### Alternative 2: Lazy Initialization (No Order Dependency)

- **Description**: Each autoload checks if its dependencies are ready before using them. If not, defer to next frame.
- **Pros**: Order-independent. Resilient to reordering.
- **Cons**: Adds conditional checks and deferred calls to every autoload's `_ready()`. Creates a "who initializes first" race on the first frame. More complex code for a problem that has a simpler solution (just order them correctly).
- **Rejection Reason**: Godot's autoload order is deterministic and documented. Explicit ordering is simpler and more reliable than lazy initialization guards.

## Consequences

### Positive

- **Deterministic boot**: Every launch initializes autoloads in the same order. No race conditions.
- **Single reference**: Programmers check one ADR for "who can import what" and "what loads when."
- **Layer violations are greppable**: `grep -r "preload.*feature" src/core/` catches upward imports.

### Negative

- **Rigid ordering**: Adding a new autoload requires thinking about where it fits in the sequence. Mitigation: new autoloads should be rare (the 11 listed cover all Foundation + Core + Feature needs).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| save-system.md | Load restores all state on app launch (Rule 7) | SaveManager loads after GameStore + SettingsStore |
| localization.md | Reads SettingsStore.locale on boot (Rule 5c) | Localization loads after SettingsStore |
| scene-navigation.md | SceneManager creates overlay in _ready() | SceneManager loads last (no dependency on game data) |

## Performance Implications

None. Boot order is a configuration concern, not a runtime concern.

## Migration Plan

Update `src/project.godot` `[autoload]` section to match the specified order. Verify no autoload's `_ready()` references a later autoload.

## Validation Criteria

1. **Startup test**: Fresh install, no save file → game reaches Splash without errors.
2. **Startup test**: Existing save with `locale: "en"` → Localization loads English correctly.
3. **Grep audit**: No autoload's `_ready()` references an autoload loaded after it.
4. **Grep audit**: No `preload()` or class reference crosses layers upward.

## Related Decisions

- ADR-0001 through ADR-0005: Define the individual autoloads this ADR orders
- `docs/architecture/architecture.md`: Architecture Principle #3 (Layer Isolation)
