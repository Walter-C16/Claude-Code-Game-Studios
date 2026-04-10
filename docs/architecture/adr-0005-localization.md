# ADR-0005: Localization — String Resolution Pipeline

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Localization / UI |
| **Knowledge Risk** | LOW — CSV plural form support added in 4.6, but we use JSON (unaffected). Godot's built-in `tr()` unchanged. |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md` (4.6 CSV plural forms), `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | None — custom JSON-based lookup, not Godot's built-in localization. |
| **Verification Required** | Verify JSON parse performance for ~1,200 keys on minimum-spec mobile (<16.6ms). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (SettingsStore provides `locale` field) |
| **Enables** | ADR-0008 (Dialogue — all text resolution), ADR-0013 (UI Theme — all UI labels) |
| **Blocks** | Any system that displays player-facing text |
| **Ordering Note** | Foundation layer. Autoload #4 in boot order (after GameStore, SettingsStore, EventBus). |

## Context

### Problem Statement

Dark Olympus has ~1,200 player-facing strings (dialogue, UI labels, enemy names, companion names, system messages). MVP ships English only, with Spanish planned for Full Vision. All strings must route through one API so that adding Spanish requires zero code changes — only a new JSON file.

### Constraints

- **MVP: English only.** Spanish deferred. But the architecture must support it without refactoring.
- **Dialogue text is the largest consumer** (~800+ keys). Must integrate seamlessly with DialogueRunner.
- **Parameter interpolation required**: "{{name}} attacks {{target}}" patterns in dialogue and combat strings.
- **Synchronous loading**: String table must load within 1 frame (16.6ms) at ~120KB.
- **No Godot built-in localization**: The GDD specifies custom JSON files at `res://i18n/{locale}.json`, not `.po`/`.csv` files. This gives full control over format, fallback chain, and key naming.

### Requirements

- Single `get_text(key, params)` API callable from any context
- Fallback chain: active locale → English → raw key
- Runtime locale switching with `locale_changed` signal
- Parameter interpolation with `{{name}}` syntax
- English always loaded as baseline (never unloaded)
- Key naming convention enforced: `PREFIX_DESCRIPTION` in `UPPER_SNAKE_CASE`

## Decision

**Localization is an autoload that loads flat JSON string tables and provides `get_text(key, params)` as the sole text resolution API.** No system reads `i18n/*.json` directly. No system hardcodes player-facing strings.

### String Table Format

```json
{
  "UI_NEW_GAME": "New Game",
  "UI_CONTINUE": "Continue",
  "COMP_ARTEMISA": "Artemisa",
  "POKER_SCORE": "Score: {{score}}",
  "CH1_ARTEMISA_01": "You look lost. Are you hurt?"
}
```

Flat key-value. No nesting. No arrays. O(1) Dictionary lookup.

### Lookup Algorithm

```gdscript
func get_text(key: String, params: Dictionary = {}) -> String:
    # 1. Try active locale
    if key in _active_table:
        return _interpolate(_active_table[key], params)

    # 2. Fallback to English (always loaded)
    if key in _english_table:
        push_warning("Localization: fallback to English for key '%s'" % key)
        return _interpolate(_english_table[key], params)

    # 3. Key not found anywhere
    push_warning("Localization: unknown key '%s'" % key)
    return key  # raw key as last resort

func _interpolate(text: String, params: Dictionary) -> String:
    for param_key in params:
        text = text.replace("{{%s}}" % param_key, str(params[param_key]))
    return text
```

### Locale Switching

```gdscript
signal locale_changed

func switch_locale(code: String) -> bool:
    if code not in SUPPORTED_LOCALES:
        return false
    if code == _active_locale:
        return true  # no-op, no signal

    var path := "res://i18n/%s.json" % code
    if not FileAccess.file_exists(path):
        push_warning("Localization: file missing for locale '%s'" % code)
        return false

    var file := FileAccess.open(path, FileAccess.READ)
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK:
        push_warning("Localization: parse failed for '%s'" % code)
        return false

    _active_table = json.data
    _active_locale = code
    locale_changed.emit()
    return true
```

### Key Interfaces

```gdscript
extends Node

signal locale_changed

const SUPPORTED_LOCALES: Array[String] = ["en"]  # add "es" for Full Vision
const DEFAULT_LOCALE: String = "en"

func get_text(key: String, params: Dictionary = {}) -> String
func switch_locale(code: String) -> bool
func get_active_locale() -> String
```

### Boot Sequence

In `_ready()`:
1. Load English table (always, as fallback baseline)
2. Read `SettingsStore.locale`
3. If locale != "en", load that locale's table too
4. If load fails, stay on English

## Alternatives Considered

### Alternative 1: Godot Built-in `tr()` with .po Files

- **Description**: Use Godot's built-in `TranslationServer` with `.po` gettext files. Call `tr("KEY")` instead of custom `get_text()`.
- **Pros**: Engine-native. No custom code. Editor integration. `tr()` is available everywhere.
- **Cons**: `.po` files are verbose and harder to edit than flat JSON. No custom fallback chain control. Parameter interpolation requires Godot's `%s` syntax (not `{{name}}`). Less control over key naming enforcement. DialogueRunner already uses JSON — mixing `.po` for some strings and JSON for dialogue creates two systems.
- **Rejection Reason**: The GDD specifies JSON string tables and `{{name}}` interpolation. Godot's `tr()` would require refactoring the dialogue data format and losing control over the fallback chain. The custom approach is ~50 lines of code and gives full control.

### Alternative 2: CSV-Based with 4.6 Plural Support

- **Description**: Use CSV string tables (supported by Godot 4.6 with new plural form columns).
- **Pros**: Godot 4.6 native plural support. Spreadsheet-editable. Translator-friendly.
- **Cons**: CSV files are harder to version-control (diffs are noisy). Plural forms not needed for MVP (English only). Still requires custom parameter interpolation. Would need to migrate from JSON if adopted later.
- **Rejection Reason**: JSON is already the established format in the codebase (dialogue, chapters, enemy data all use JSON). Staying consistent simplifies the data pipeline. Plurals can be added to the custom system if Spanish requires them.

## Consequences

### Positive

- **Zero-code language addition**: Adding Spanish = create `es.json`, add "es" to `SUPPORTED_LOCALES`.
- **Consistent format**: All data files (dialogue, chapters, enemies, strings) are JSON.
- **Full control**: Custom fallback chain, custom interpolation, custom key naming enforcement.
- **Testable**: `get_text()` is a pure function with no side effects (except logging). Easy to unit test.

### Negative

- **Not engine-native**: Godot's `tr()` is available everywhere without import. Custom `get_text()` requires knowing about the Localization autoload. Mitigation: all code uses `Localization.get_text()` — one import pattern.
- **No editor preview**: Godot's built-in localization shows translated strings in the editor. Custom JSON does not. Mitigation: 4.5 added live translation preview, but only for built-in `tr()`. Custom strings require running the game to preview.

### Risks

- **Key naming drift**: Without enforcement, developers may create inconsistently named keys. Mitigation: pre-release lint check validates all keys match `^[A-Z][A-Z0-9_]+$`.
- **Missing translations at ship**: When Spanish is added, keys present in English but missing in Spanish will silently fall back. Mitigation: lint check compares key sets between locale files.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| localization.md | Single get_text(key, params) API (Rule 3) | Localization autoload with get_text() |
| localization.md | Fallback chain: locale → English → raw key (Rule 6) | Three-step lookup in get_text() |
| localization.md | {{name}} parameter interpolation (Rule 4) | _interpolate() with String.replace() |
| localization.md | Runtime locale switching with signal (Rule 5) | switch_locale() + locale_changed signal |
| localization.md | English always loaded as baseline (Rule 6) | _english_table never unloaded |
| localization.md | Flat JSON string tables (Rule 1) | res://i18n/{locale}.json |
| localization.md | Key naming: PREFIX_DESCRIPTION UPPER_SNAKE_CASE (Rule 2) | Convention enforced by pre-release lint |
| dialogue.md | All text resolved via Localization (Rule 1/2) | DialogueRunner calls get_text(text_key, text_params) |
| enemy-data.md | Enemy display names via translation keys | EnemyRegistry calls get_text(name_key) |

## Performance Implications

- **CPU**: Dictionary lookup O(1). String.replace() for interpolation: O(K*N) where K=param count, N=string length. Both negligible (<0.01ms per call).
- **Memory**: ~120KB per locale table in Dictionary. Two tables loaded (English + active): ~240KB. Well within 512MB mobile budget.
- **Load Time**: JSON parse of 120KB: ~4ms on mid-range mobile. Under 16.6ms frame budget for synchronous loading.

## Migration Plan

Existing `DialogueRunner.get_text()` hardcodes `res://i18n/en.json` with its own cache. Migration: remove `DialogueRunner.get_text()`, delegate to `Localization.get_text()`. All other systems that display text must be audited to use `Localization.get_text()` instead of hardcoded strings.

## Validation Criteria

1. **Unit test**: `get_text("UI_CONTINUE")` returns "Continue" (English loaded).
2. **Unit test**: `get_text("MISSING_KEY")` returns "MISSING_KEY" (raw key fallback).
3. **Unit test**: `get_text("POKER_SCORE", {"score": "150"})` returns "Score: 150".
4. **Unit test**: `switch_locale("es")` with missing `es.json` returns false, locale stays "en".
5. **Grep audit**: `grep -r "\"[A-Z][a-z]" src/scenes/` — finds hardcoded player-facing strings (should be zero).
6. **Performance test**: `switch_locale()` completes in <16.6ms on minimum-spec mobile.

## Related Decisions

- ADR-0001: GameStore / SettingsStore — locale stored in SettingsStore, persisted by SaveManager
- ADR-0004: EventBus — `locale_changed` signal is on Localization directly (Foundation-to-Foundation, no EventBus needed)
- ADR-0008 (planned): Dialogue — DialogueRunner delegates all text to Localization.get_text()
- `design/gdd/localization.md` — full design spec
