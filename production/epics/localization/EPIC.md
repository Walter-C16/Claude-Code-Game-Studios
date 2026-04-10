# Epic: Localization

> **Layer**: Foundation
> **GDD**: design/gdd/localization.md
> **Architecture Module**: Localization / UI
> **Governing ADRs**: ADR-0005, ADR-0006
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories localization`

## Overview

Localization is an autoload that loads flat JSON string tables and provides get_text(key, params) as the sole text resolution API. No system reads i18n/*.json directly. No system hardcodes player-facing strings. The lookup follows a three-step fallback chain: active locale, then English (always loaded as baseline), then raw key. Parameter interpolation uses {{name}} double-curly-brace syntax. Runtime locale switching emits a locale_changed signal so persistent UI nodes can re-resolve their strings. MVP ships English only, with Spanish planned for Full Vision -- adding a language requires only a new JSON file and a SUPPORTED_LOCALES entry. Boot position #4, after EventBus.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: Localization -- String Resolution Pipeline | Custom JSON string tables with get_text(key, params) API; fallback chain locale->English->raw key; {{name}} interpolation; locale_changed signal; English always loaded | LOW |
| ADR-0006: Autoload Boot Order + Layer Dependency Rules | Localization is autoload #4; reads SettingsStore.locale in _ready() | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-localization-001 | Flat JSON string tables at res://i18n/{locale_code}.json; O(1) dictionary lookup | ADR-0005 |
| TR-localization-002 | Single get_text(key, params) API as sole public entry point on singleton autoload | ADR-0005 |
| TR-localization-003 | Parameter interpolation with {{name}} double-curly-brace syntax | ADR-0005 |
| TR-localization-004 | Fallback chain: active locale -> English -> raw key; English always in memory | ADR-0005 |
| TR-localization-005 | locale_changed signal on switch; all persistent UI nodes re-resolve strings | ADR-0005 |
| TR-localization-006 | Synchronous locale switching within 16.6ms frame budget for ~120KB file | ADR-0005 |
| TR-localization-007 | Memory footprint: two locale dictionaries under 1.2MB at 3000 keys | ADR-0005 |
| TR-localization-008 | DialogueRunner must migrate from internal _translations cache to Localization autoload | ADR-0005 |
| TR-localization-009 | No hardcoded player-facing strings in any consuming system | ADR-0005 |
| TR-localization-010 | SUPPORTED_LOCALES array; switch_locale() validates code, loads table, emits signal | ADR-0005 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories localization` to break this epic into implementable stories.
