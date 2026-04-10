# Localization

> **Status**: Designed
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-08
> **Implements Pillar**: Pillar 2 (Visual Novel Dialogue with Consequences)

## Summary

The Localization system manages all player-facing text in Dark Olympus through translation keys mapped to locale-specific string files. It provides a single lookup interface that every UI element, dialogue line, enemy name, and system message calls to resolve a key into the player's chosen language. MVP ships with English only; Spanish is scoped for Full Vision.

> **Quick reference** -- Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

The Localization system is the string resolution layer for all player-facing text. No UI element, dialogue line, or system message displays a hardcoded string -- every visible text originates from a translation key that this system resolves against the active locale's string table.

The system provides three capabilities: (1) key-to-string lookup with parameter interpolation (`{{name}}`, `{{value}}`), (2) locale switching at runtime without restarting the game, and (3) a fallback chain that ensures missing translations degrade to the English string or the raw key rather than crashing or showing blank text.

At MVP, only English (`en`) is supported. The system's design accommodates additional locales (starting with Spanish `es`) without requiring changes to consuming systems -- adding a language means adding a string file and registering it, not modifying Dialogue, Combat UI, or any other downstream system.

The system owns the string table files and the lookup API. It does not own the text content itself -- dialogue scripts, UI labels, and enemy names are authored by their respective systems and stored as translation keys. Localization resolves those keys at display time.

## Player Fantasy

Localization has no player fantasy of its own -- it is infrastructure whose success is measured by its invisibility. When localization works, every player experiences Dark Olympus as if it were written natively in their language: Artemisa's dialogue carries the same fierce warmth in Spanish as in English, poker hand names feel natural rather than transliterated, and mythological terms land with their intended gravity. When localization fails, the illusion shatters -- a placeholder like `UI_COMPANION_GREETING_03` appearing mid-confession, a truncated button label during a tense poker showdown, or a companion's emotional arc flattened by toneless translation. A fallen goddess pleading for help must sound like a fallen goddess in every supported language, not like a software tooltip. In a text-heavy visual novel where words ARE the gameplay, broken localization doesn't just look unprofessional -- it severs the player's emotional connection to every pillar the game rests on.

## Detailed Design

### Core Rules

1. **String table format.** Each locale is a single flat JSON file at `res://i18n/{locale_code}.json`. Keys are strings, values are strings. No nesting, no arrays. The flat structure enables O(1) dictionary lookup and trivial version-control diffs for translator handoff.

2. **Key naming convention.** All keys use `PREFIX_DESCRIPTION` in `UPPER_SNAKE_CASE`. Keys are immutable once shipped -- renaming is a breaking change.

   | Prefix | Scope | Examples |
   |--------|-------|---------|
   | `UI_` | Shared interface elements | `UI_NEW_GAME`, `UI_CONTINUE`, `UI_SAVE_ERROR` |
   | `SETTINGS_` | Settings screen labels | `SETTINGS_LANGUAGE`, `SETTINGS_MASTER_VOL` |
   | `HUB_` | Hub navigation labels | `HUB_TAB_HOME`, `HUB_TAB_GALLERY` |
   | `ENEMY_` | Enemy display names | `ENEMY_CYCLOPS`, `ENEMY_FOREST_MONSTER` |
   | `BOSS_` | Boss-tier enemy names | `BOSS_CRONOS_AVATAR` |
   | `LOC_` | Location/map names | `LOC_TAVERN`, `LOC_SHADOW_REALM` |
   | `POKER_` | Poker combat UI | `POKER_PLAY`, `POKER_SCORE` |
   | `COMP_` | Companion names and labels | `COMP_ARTEMISA`, `COMP_HIPOLITA` |
   | `DATE_` | Date activity labels | `DATE_STARGAZING`, `DATE_RESULT_LOVED` |
   | `PROL_` | Prologue narrative | `PROL_NARRATOR_1`, `PROL_CHOICE_1A` |
   | `CH{N}_` | Chapter-specific dialogue | `CH1_NODE_TAVERN` |
   | `EQUIP_` | Equipment names | `EQUIP_SWORD_OLYMPUS` |
   | `EXPLORE_` | Exploration labels | `EXPLORE_SEND`, `EXPLORE_TIME_LEFT` |
   | `ABYSS_` | Abyss mode labels | `ABYSS_TITLE`, `ABYSS_ENTER` |
   | `INTIMACY_` | Intimacy scene labels | `INTIMACY_TITLE`, `INTIMACY_INVITE` |

   - 2a. Prefixes are the only categorization. No sub-prefixes (e.g., not `UI_COMBAT_` -- use `UI_COMBAT_STARTED`).
   - 2b. Numbered suffixes (`_1`, `_2`) are permitted for ordered narrative sequences only, not for UI keys.
   - 2c. A key present in `en.json` but absent in another locale's file is a missing translation, not an error. The fallback chain (Rule 6) handles it.

3. **Lookup API contract.** A single function:

   ```
   get_text(key: String, params: Dictionary = {}) -> String
   ```

   - 3a. `get_text` is the sole public entry point. No system reads `i18n/*.json` directly.
   - 3b. Always returns a String. Never returns null, never crashes, never returns empty unless the string table value is explicitly empty.
   - 3c. Callable from any context without instantiation (static function on a singleton autoload).

4. **Parameter interpolation.**
   - 4a. Placeholders use `{{name}}` syntax (double curly braces, no spaces). This is the existing convention and is locked.
   - 4b. Placeholder names are case-sensitive.
   - 4c. All param values are coerced to String before substitution. The caller formats numbers.
   - 4d. Unmatched placeholders (present in string but absent in params) remain literally in the output to surface authoring errors visually.
   - 4e. Multiple instances of the same placeholder in one string are all replaced.

5. **Locale registration and switching.**
   - 5a. `SUPPORTED_LOCALES: Array[String]` defines supported locales. MVP: `["en"]`. Full Vision: `["en", "es"]`.
   - 5b. Active locale is stored in `SettingsStore.locale` (String, default `"en"`).
   - 5c. `switch_locale(new_code: String) -> bool` validates the code is supported, loads the new string table, emits `locale_changed` signal, returns `true`/`false`.
   - 5d. All persistent UI nodes displaying localized text connect to `locale_changed` and re-resolve their strings on receipt. The signal carries no payload.
   - 5e. Locale switching is synchronous. At 1,230 keys (~100 KB), file read + parse fits within the 16.6ms frame budget.
   - 5f. Switching to the already-active locale is a no-op (returns `true`, no signal emitted).

6. **Fallback chain.** When `get_text(key, params)` is called:
   1. Look up `key` in the active locale's table. If found -> resolve params -> return.
   2. If active locale is not `en`, look up `key` in the English table (always in memory). If found -> log warning -> resolve params -> return.
   3. Key not in any table -> log warning -> return raw key as-is (no param substitution).

   The English string table is always loaded in memory regardless of active locale, ensuring missing translations degrade to readable English rather than raw keys.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| **Uninitialized** | App launch, before autoload `_ready()` | `_ready()` completes initial load | `get_text` returns raw keys. No consuming system should call before autoload is ready. |
| **Loading** | `_ready()` or `switch_locale()` begins file read | Parse completes | Synchronous -- no frame passes in this state. Previous table remains until swap. |
| **Active** | Load succeeds | `switch_locale()` called with new locale | Normal operation. `get_text` resolves from active locale + English fallback. |
| **Fallback Active** | Non-English locale load fails (file missing/corrupt) | `switch_locale()` succeeds with valid locale | `get_text` resolves from English only. UI locale selector reverts to `en`. Warning logged. |
| **Error** | English file load fails | Manual fix (file restored) | `get_text` returns raw keys. Warning on every call. Should never occur in shipped build. |

Transitions: `Uninitialized -> Loading -> Active` on startup. `Active -> Loading -> Active` on successful switch. `Active -> Loading -> Fallback Active` on failed switch. `Fallback Active -> Loading -> Active` on next valid switch.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **All UI nodes** | Calls Localization | `get_text(key)` + connect to `locale_changed` | Every Label, Button, RichTextLabel with player-facing text. |
| **DialogueRunner** | Calls Localization | `get_text(key, params)` | Must migrate from its own `_translations` cache to delegate to Localization autoload. |
| **Enemy Data** | Calls Localization | `get_text(name_key)` | `ENEMY_*` keys for display names. Raw key as fallback per Enemy Data GDD. |
| **Combat System** | Calls Localization | `get_text(key, params)` | Combat log strings (`UI_ATTACKS`, `UI_VICTORY`, etc.) |
| **Story Flow** | Calls Localization | `get_text(key)` | Chapter/node display labels. |
| **Settings Screen** | Calls `switch_locale(code)` | Only system that triggers locale change | Shows language selector, writes to SettingsStore on switch. |
| **SettingsStore** | Provides locale to Localization | `SettingsStore.locale` read on `_ready()` | One-directional dependency. SettingsStore does not call Localization. |
| **Save System** | Indirect via SettingsStore | `locale` in `SettingsStore.to_dict()` / `from_dict()` | On load, Save System restores SettingsStore, then calls `switch_locale()` to activate. |

**DialogueRunner migration note:** The current `DialogueRunner.get_text()` hardcodes `res://i18n/en.json` with its own load/cache. Once the Localization autoload exists, `DialogueRunner.get_text()` must delegate to `Localization.get_text()` or be removed entirely. This migration is required for any non-English locale to work in dialogue.

## Formulas

This system performs no mathematical calculations. It is a key-value lookup with string interpolation. The following operational metrics define its performance contract:

### String Table Load Time

```
load_time_ms = file_size_kb / parse_rate_kb_per_ms
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `file_size_kb` | float | 80-200 | JSON file size on disk per locale |
| `parse_rate_kb_per_ms` | float | 20-50 | JSON parse throughput (device-dependent) |

**Expected output range:** 2-10ms on mid-range mobile. Must remain under 16.6ms (one frame at 60fps) to support synchronous loading.

**Example:** 120 KB file / 30 KB/ms parse rate = 4ms load time.

### Memory Footprint Per Locale

```
memory_kb = key_count * avg_entry_bytes / 1024
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `key_count` | int | 1,200-3,000 | Total keys in a locale file |
| `avg_entry_bytes` | int | 80-200 | Average bytes per key-value pair in Dictionary (key + value + overhead) |

**Expected output range:** 100-600 KB per locale. Two locales loaded simultaneously (English baseline + active): 200 KB - 1.2 MB. Well within the 512 MB mobile memory ceiling.

## Edge Cases

- **If a UI node calls `get_text` before the Localization autoload's `_ready()` completes**: Returns the raw key (e.g., `UI_CONTINUE` displayed instead of "Continue"). Consuming systems must not call `get_text` in their own `_ready()` unless they are guaranteed to initialize after the Localization autoload in Godot's Project Settings order.

- **If `switch_locale()` is called while a dialogue line is mid-display**: The `locale_changed` signal fires and persistent UI nodes re-resolve, but the currently-displayed dialogue line was already resolved to a string. The in-progress line stays in the old language; the next line advances to the new language. This is acceptable -- do not retroactively re-resolve the active dialogue line.

- **If a key's value in the JSON file is an empty string `""`**: `get_text` returns the empty string (per Rule 3b). No warning is logged. A pre-release validation pass must flag empty-value keys as potential authoring errors.

- **If a placeholder name contains a typo in the JSON file (e.g., `{{attakcer}}` instead of `{{attacker}}`)**: The unmatched placeholder remains literally in the output (per Rule 4d). The player sees `{{attakcer}} attacks Cronos`. This is by design during development to surface errors visually, but a pre-release string validation must catch all unresolved placeholders.

- **If a Spanish string is 30-50% longer than its English equivalent**: Text may overflow fixed-width UI containers. All UI containers that display localized text must use auto-wrap or auto-sizing. Button labels must be tested at 150% of English string length to verify no truncation. This is a UI system concern, not a Localization system concern, but the Localization GDD flags it as a cross-system risk.

- **If `switch_locale("es")` fails but SettingsStore already wrote `locale = "es"`**: The Settings Screen must write to `SettingsStore.locale` only after `switch_locale()` returns `true`, not before. If it writes first and the switch fails, the stored preference is `"es"` but the active table is `en`, creating a permanent mismatch on every app launch. The Settings Screen must gate persistence on confirmed success.

- **If the same key appears twice in a JSON file**: JSON parsers silently use the last occurrence. No warning is logged. A pre-release lint step must check for duplicate keys in all locale files.

- **If `SUPPORTED_LOCALES` is updated to add a new locale but the corresponding JSON file is not included in the export preset**: `switch_locale` fails on the missing file, enters Fallback Active state, and reverts to English. The Settings Screen must only show locales whose files are confirmed present at runtime (check `FileAccess.file_exists()` before populating the selector).

- **If a chapter key prefix uses inconsistent zero-padding (`CH1_` vs `CH01_`)**: Key lookup is exact-match. `CH1_NODE_TAVERN` and `CH01_NODE_TAVERN` are different keys. The naming convention specifies `CH{N}_` without zero-padding (e.g., `CH1_`, `CH2_`). Enforce this in authoring guidelines and lint checks.

- **If the DialogueRunner migration is not completed before Spanish ships**: `DialogueRunner.get_text()` hardcodes `en.json`. All dialogue remains English while UI switches to Spanish. This produces a visually inconsistent but non-crashing failure. The migration must be completed before any non-English locale is marked as supported.

- **If a param value itself contains `{{` syntax (e.g., a data entry error stores a name as `{{Cronos}}`)**: The substitution is single-pass (per Rule 4f -- `String.replace()` per param key). No recursive substitution occurs. The output contains the literal `{{Cronos}}` which looks like an unresolved placeholder but is inert. This is safe but visually confusing -- flag it in data validation.

## Dependencies

| System | Direction | Nature | Hard/Soft | Interface |
|--------|-----------|--------|-----------|-----------|
| **Dialogue** | Dialogue depends on this | Dialogue calls `get_text(key, params)` to resolve all dialogue text keys | Hard (MVP) | `get_text()` API. DialogueRunner must migrate from its own `_translations` to delegate to Localization. |
| **Enemy Data** | Enemy Data depends on this | Enemy display names are translation keys (`ENEMY_*`) | Soft | `get_text(name_key)`. Enemy Data GDD specifies raw key as fallback if Localization unavailable. |
| **Combat System** | Combat depends on this | Combat log strings, HUD labels, victory/defeat messages | Hard (MVP) | `get_text(key, params)` for parameterized combat strings. |
| **Story Flow** | Story Flow depends on this | Chapter labels, node descriptions | Hard (MVP) | `get_text(key)` for map and navigation strings. |
| **Romance & Social** | Romance depends on this | Relationship stage labels, daily interaction text | Hard (MVP) | `get_text(key, params)` for companion interaction strings. |
| **All UI screens** | UI depends on this | Every button label, menu text, settings label | Hard (MVP) | `get_text(key)` + `locale_changed` signal subscription. |
| **SettingsStore** | This reads from SettingsStore | Locale preference stored in `SettingsStore.locale` | Hard | Read-only. Localization reads locale on `_ready()`. |
| **Save System** | Indirect via SettingsStore | `locale` field persisted in save file via SettingsStore serialization | Soft | No direct interface. Save System restores SettingsStore, which Localization reads. |
| **Camp** | Camp depends on this | Daily interaction hub labels, companion names | Hard (Vertical Slice) | `get_text(key)`. |
| **Abyss Mode** | Abyss depends on this | Abyss UI labels, modifier descriptions | Hard (Alpha) | `get_text(key, params)`. |

**Bidirectional notes:**
- Dialogue GDD (when authored) must list "depends on Localization" and specify the key patterns it uses.
- Enemy Data GDD already lists Localization as a soft dependency (see `design/gdd/enemy-data.md` Dependencies section).
- No system depends on Localization's internal state -- all consumers use the `get_text()` API contract only.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `SUPPORTED_LOCALES` | `["en"]` | 1-10 locales | More language options; each adds ~100-600 KB memory | Fewer languages available |
| `DEFAULT_LOCALE` | `"en"` | Any value in `SUPPORTED_LOCALES` | Changes the fallback and default language | -- |
| `FALLBACK_LOG_LEVEL` | `warning` | `silent` / `warning` / `error` | `error` halts in debug builds on missing keys (strict mode for development). `silent` suppresses fallback warnings in production. | -- |
| `MAX_KEY_LENGTH` | 64 characters | 32-128 | Allows longer, more descriptive keys | Forces terser key names; risk of ambiguity |
| `INTERPOLATION_DELIMITERS` | `{{` / `}}` | Fixed (not tunable) | -- | -- |

**Notes:**
- `SUPPORTED_LOCALES` is the primary tuning knob. Adding a locale is a content addition, not a code change.
- `FALLBACK_LOG_LEVEL` is a development tool, not a player-facing setting. Set to `warning` for development, `silent` for release builds.
- `INTERPOLATION_DELIMITERS` are locked by Rule 4a and should not be tunable. Listed here for completeness.

## Visual/Audio Requirements

This system has no visual or audio output of its own. It is a string resolution layer consumed by other systems that handle their own rendering and audio.

## UI Requirements

The Localization system has one indirect UI requirement: the **Settings Screen** must include a language selector dropdown populated from `SUPPORTED_LOCALES`, filtered by `FileAccess.file_exists()` at runtime. The selector calls `switch_locale()` and only persists the choice to `SettingsStore` on confirmed success. This is owned by the Settings Screen UI, not by Localization itself.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Enemy display names use translation keys | `design/gdd/enemy-data.md` | `name_key` field on all enemy records | Data dependency |
| Locale preference stored in SettingsStore | `design/gdd/save-system.md` | `SettingsStore.to_dict()` / `from_dict()` contract | Data dependency |
| DialogueRunner migration required | `design/gdd/dialogue.md` | `DialogueRunner.get_text()` delegation | Ownership handoff |
| `locale_changed` signal consumed by all UI | `design/gdd/ui-theme.md` | Signal subscription pattern for persistent nodes | State trigger |

## Acceptance Criteria

- [ ] **AC-L01** — **GIVEN** `res://i18n/en.json` exists, **WHEN** parsed, **THEN** it is a flat Dictionary (no nested objects/arrays) and every key matches `^[A-Z][A-Z0-9_]+$`.

- [ ] **AC-L02** — **GIVEN** the Localization autoload is Active, **WHEN** `get_text` is called with (a) a valid key, (b) an unknown key, or (c) a key with empty string value, **THEN** all three return a String -- never null, never crashes.

- [ ] **AC-L03** — **GIVEN** a string with `{{attacker}}` appearing twice and `{{target}}` once, **WHEN** `get_text(key, {"attacker": "Zeus", "target": "Cyclops"})` is called, **THEN** returns `"Zeus attacks Cyclops for Zeus-strength damage"` -- all placeholders replaced.

- [ ] **AC-L04** — **GIVEN** a string with a typo `{{attakcer}}`, **WHEN** `get_text(key, {"attacker": "Zeus"})` is called, **THEN** `{{attakcer}}` remains literally in output. No crash.

- [ ] **AC-L05** — **GIVEN** Spanish is active, **WHEN** `get_text` is called for (a) a key in both `es.json` and `en.json`, (b) a key only in `en.json`, (c) a key in neither, **THEN** (a) returns Spanish, (b) returns English + warning, (c) returns raw key + warning. *BLOCKED until `es.json` exists.*

- [ ] **AC-L06** — **GIVEN** `en` is active and a listener is connected to `locale_changed`, **WHEN** `switch_locale("en")` is called, **THEN** returns `true` and `locale_changed` is NOT emitted.

- [ ] **AC-L07** — **GIVEN** `es` is in `SUPPORTED_LOCALES` but `es.json` does not exist, **WHEN** `switch_locale("es")` is called, **THEN** returns `false`, `SettingsStore.locale` remains `"en"`, system enters Fallback Active state.

- [ ] **AC-L08** — **GIVEN** `en.json` at representative size (~120 KB), **WHEN** `switch_locale` is timed, **THEN** completes in under 16.6ms (one frame at 60fps). *ADVISORY -- run on target mobile hardware.*

- [ ] **AC-L09** — **GIVEN** two locale dictionaries loaded (English baseline + active), **WHEN** memory is measured, **THEN** total is under 1.2 MB at 3,000 keys per locale. *ADVISORY.*

- [ ] **AC-L10** — **GIVEN** a UI node calls `get_text("UI_CONTINUE")` before Localization `_ready()` completes, **WHEN** the scene tree initializes, **THEN** returns raw key `"UI_CONTINUE"` without crash.

- [ ] **AC-L11** — **GIVEN** a dialogue line is mid-display, **WHEN** the player switches locale via Settings, **THEN** the in-progress line completes in the old language; the next line resolves in the new language. No flicker or blank.

- [ ] **AC-L12** — **GIVEN** DialogueRunner migration is complete and `es` is active, **WHEN** dialogue advances, **THEN** dialogue text is Spanish. *BLOCKED until DialogueRunner migration story is Done.*

- [ ] Performance: String table load completes within 16.6ms on mid-range mobile.
- [ ] No hardcoded player-facing strings in any consuming system.

**Pre-release lint checks** (separate from system acceptance -- authoring validation):
- No duplicate keys in any locale JSON
- No empty-string values in shipped locale files
- No unresolved `{{placeholder}}` patterns in final strings
- All `CH{N}_` prefixes use no zero-padding
- Every `SUPPORTED_LOCALES` entry has a corresponding file confirmed via `FileAccess.file_exists()`

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the DialogueRunner migration create a thin wrapper or remove `get_text` entirely? | Technical Director | Before Architecture phase | Pending -- depends on whether other systems call `DialogueRunner.get_text()` directly |
| Do we need pluralization support for Spanish? (e.g., "1 enemy" vs "2 enemies") | Game Designer | Before Spanish ships | Pending -- assess when Spanish content is authored |
| Should locale files be bundled in the export or downloadable post-install? | Technical Director | Before Full Vision | Pending -- bundled is simpler; downloadable saves install size |
