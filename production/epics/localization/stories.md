# Stories: Localization

> **Epic**: Localization
> **Layer**: Foundation
> **Governing ADRs**: ADR-0005, ADR-0006
> **Manifest Version**: 2026-04-09

---

### STORY-LOC-001: JSON String Table Loading + SUPPORTED_LOCALES

- **Type**: Logic
- **TR-IDs**: TR-localization-001, TR-localization-007, TR-localization-010
- **ADR Guidance**: ADR-0005 — Flat JSON string tables at `res://i18n/{locale_code}.json`; English always loaded as baseline in `_ready()`; SUPPORTED_LOCALES array is the sole authority for valid locale codes; two dictionaries in memory under 1.2MB at 3000 keys
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `localization.gd`, WHEN inspected, THEN `const SUPPORTED_LOCALES: Array[String] = ["en"]` and `const DEFAULT_LOCALE: String = "en"` are declared as top-level constants
  - [ ] AC2: GIVEN Localization's `_ready()`, WHEN it runs, THEN `res://i18n/en.json` is loaded into `_english_table` unconditionally (English is always the baseline)
  - [ ] AC3: GIVEN `res://i18n/en.json` contains 1000 entries, WHEN `_ready()` completes, THEN the `_english_table` Dictionary has exactly 1000 keys
  - [ ] AC4: GIVEN `res://i18n/en.json` is missing or malformed, WHEN `_ready()` runs, THEN a `push_error()` is logged and the autoload initializes with an empty fallback (no crash)
  - [ ] AC5: GIVEN two locale dictionaries loaded simultaneously, WHEN their total memory is measured, THEN it is under 1.2MB (verified with a 3000-key test fixture)
- **Test Evidence**: `tests/unit/localization/localization_load_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-LOC-002: get_text API + Fallback Chain

- **Type**: Logic
- **TR-IDs**: TR-localization-002, TR-localization-004, TR-localization-009
- **ADR Guidance**: ADR-0005 — Three-step fallback: active locale → English → raw key; `push_warning()` logged for fallback to English and for missing key; raw key returned as last resort; no system reads i18n JSON directly
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN English table has `"UI_CONTINUE": "Continue"` and active locale is English, WHEN `get_text("UI_CONTINUE")` is called, THEN it returns `"Continue"`
  - [ ] AC2: GIVEN active locale is "es" with no "es" table loaded (Spanish missing), WHEN `get_text("UI_CONTINUE")` is called, THEN it falls back to the English value `"Continue"` and logs a `push_warning()`
  - [ ] AC3: GIVEN the key `"MISSING_KEY"` is not in any loaded table, WHEN `get_text("MISSING_KEY")` is called, THEN it returns the string `"MISSING_KEY"` (raw key) and logs a `push_warning()`
  - [ ] AC4: GIVEN a grep of `src/` for `FileAccess.open.*i18n`, WHEN run, THEN zero matches appear outside of `localization.gd` (no system reads locale files directly)
  - [ ] AC5: GIVEN a grep of `src/scenes/` for hardcoded player-facing strings (quoted English words in Labels/RichTextLabel), WHEN reviewed, THEN zero hardcoded strings exist (all use `Localization.get_text()`)
- **Test Evidence**: `tests/unit/localization/get_text_fallback_test.gd`
- **Status**: Ready
- **Depends On**: STORY-LOC-001

---

### STORY-LOC-003: Parameter Interpolation

- **Type**: Logic
- **TR-IDs**: TR-localization-003
- **ADR Guidance**: ADR-0005 — `{{name}}` double-curly-brace syntax; `_interpolate()` uses `String.replace()` for each param key; multiple params supported; unknown params leave their `{{placeholder}}` in place
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN English table has `"POKER_SCORE": "Score: {{score}}"`, WHEN `get_text("POKER_SCORE", {"score": "150"})` is called, THEN it returns `"Score: 150"`
  - [ ] AC2: GIVEN a string `"{{name}} attacks {{target}}"`, WHEN `get_text()` is called with `{"name": "Artemisa", "target": "Beast"}`, THEN it returns `"Artemisa attacks Beast"`
  - [ ] AC3: GIVEN a string with `{{name}}` and params dict has no "name" key, WHEN `get_text()` runs, THEN the placeholder `{{name}}` remains in the output (no crash, no null substitution)
  - [ ] AC4: GIVEN a string with no placeholders, WHEN `get_text()` is called with a non-empty params dict, THEN the string is returned unchanged (no corruption from unnecessary replacements)
  - [ ] AC5: GIVEN `_interpolate()` is called with an empty params Dictionary, WHEN it runs, THEN it returns the text unchanged with no iterations
- **Test Evidence**: `tests/unit/localization/interpolation_test.gd`
- **Status**: Ready
- **Depends On**: STORY-LOC-002

---

### STORY-LOC-004: Runtime Locale Switching + locale_changed Signal

- **Type**: Logic
- **TR-IDs**: TR-localization-005, TR-localization-006, TR-localization-010
- **ADR Guidance**: ADR-0005 — `switch_locale(code)` validates against SUPPORTED_LOCALES, loads the new JSON, swaps `_active_table`, emits `locale_changed`; switch must complete within 16.6ms; switching to the same locale is a no-op (no signal)
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `switch_locale("en")` called when active locale is already "en", WHEN it runs, THEN `locale_changed` is NOT emitted and method returns `true`
  - [ ] AC2: GIVEN `switch_locale("xx")` where "xx" is not in SUPPORTED_LOCALES, WHEN called, THEN it returns `false` and the active locale is unchanged
  - [ ] AC3: GIVEN `switch_locale("es")` where `res://i18n/es.json` does not exist, WHEN called, THEN it returns `false`, logs a warning, and active locale remains unchanged
  - [ ] AC4: GIVEN a valid `res://i18n/es.json` and "es" in SUPPORTED_LOCALES, WHEN `switch_locale("es")` is called, THEN `locale_changed` emits, `get_active_locale()` returns "es", and `get_text()` resolves from the Spanish table
  - [ ] AC5: GIVEN `switch_locale("es")` with a 120KB JSON file, WHEN timed, THEN the call completes in under 16.6ms on a minimum-spec device
- **Test Evidence**: `tests/unit/localization/locale_switch_test.gd`
- **Status**: Ready
- **Depends On**: STORY-LOC-001

---

### STORY-LOC-005: Localization Boot Order Wiring + DialogueRunner Migration

- **Type**: Integration
- **TR-IDs**: TR-localization-008
- **ADR Guidance**: ADR-0006 — Localization is autoload #4, reads `SettingsStore.locale` in `_ready()`; ADR-0005 — DialogueRunner must migrate from its internal `_translations` cache to `Localization.get_text()`
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `project.godot`, WHEN the autoload section is inspected, THEN Localization appears as autoload #4, after EventBus (#3) and before SaveManager (#5)
  - [ ] AC2: GIVEN Localization's `_ready()`, WHEN it runs, THEN it reads `SettingsStore.locale` and calls `switch_locale()` with that value (if locale is not "en")
  - [ ] AC3: GIVEN `dialogue_runner.gd`, WHEN grepped for `_translations` or direct `i18n/en.json` file reads, THEN zero matches are found (cache removed)
  - [ ] AC4: GIVEN `dialogue_runner.gd` resolving a dialogue text key, WHEN inspected, THEN it calls `Localization.get_text(text_key, text_params)` (not its own lookup)
  - [ ] AC5: GIVEN the game launches with `SettingsStore.locale = "en"`, WHEN Localization's `_ready()` completes, THEN `get_active_locale()` returns "en" and `get_text("UI_NEW_GAME")` returns the English string without error
- **Test Evidence**: `tests/integration/localization/boot_wiring_test.gd`
- **Status**: Ready
- **Depends On**: STORY-LOC-004, STORY-GS-005
