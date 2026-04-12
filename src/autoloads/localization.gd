extends Node

## Localization — String Table Lookup (ADR-0005, ADR-0006)
##
## Autoload #4. Boot position: after GameStore, SettingsStore, EventBus.
## Provides get_text(key, params) as the sole API for all player-facing text.
##
## LOC-001: loads English baseline unconditionally in _ready().
## LOC-002: get_text() with fallback chain (stories: LOC-002, LOC-003).
## LOC-004: switch_locale() with locale_changed signal (story: LOC-004).
## LOC-005: reads SettingsStore.get_locale() in _ready() and calls switch_locale() when non-English.
##
## Control Manifest rules:
##   - All player-facing text MUST resolve through Localization.get_text()
##   - No other script may read res://i18n/*.json directly
##   - English table is always loaded as fallback baseline; never unloaded
##
## See: docs/architecture/adr-0005-localization.md

# ── Constants ─────────────────────────────────────────────────────────────────

## Authoritative list of valid locale codes. SUPPORTED_LOCALES is the sole
## source of truth. Adding a locale here + placing {code}.json in res://i18n/
## is all that is required to enable it (zero code changes elsewhere).
const SUPPORTED_LOCALES: Array[String] = ["en"]

## Locale used when no override is set and as the unconditional fallback.
const DEFAULT_LOCALE: String = "en"

## Base path for JSON string table files.
const I18N_PATH: String = "res://i18n/"

# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted after a successful switch_locale() call that changed the active locale.
## Listeners should refresh any displayed text.
signal locale_changed

# ── Private State ─────────────────────────────────────────────────────────────

## English string table. Loaded unconditionally in _ready() and never unloaded.
## Acts as the last-resort fallback for every get_text() call.
var _english_table: Dictionary = {}

## The table for the currently active locale. May point to _english_table when
## English is the active locale, or to a separately loaded locale table otherwise.
var _active_table: Dictionary = {}

## The currently active locale code (must be a member of SUPPORTED_LOCALES).
var _active_locale: String = DEFAULT_LOCALE

# ── Virtual Methods ───────────────────────────────────────────────────────────

func _ready() -> void:
	# AC2 — English baseline always loaded first, unconditionally.
	_english_table = _load_table(DEFAULT_LOCALE)
	_active_table = _english_table
	_active_locale = DEFAULT_LOCALE
	# LOC-005: read saved locale and switch if non-English.
	var saved_locale: String = SettingsStore.get_locale()
	if saved_locale != DEFAULT_LOCALE:
		switch_locale(saved_locale)

# ── Public Methods ────────────────────────────────────────────────────────────

## Returns the active locale code (always a member of SUPPORTED_LOCALES).
func get_active_locale() -> String:
	return _active_locale

## Returns the translated string for key, with optional {{param}} interpolation.
## Fallback chain: active locale → English → raw key (never returns empty string).
## LOC-002: three-step fallback + passthrough interpolation (LOC-003 implements {{key}} replacement).
func get_text(key: String, params: Dictionary = {}) -> String:
	var text: String = ""
	if _active_table.has(key):
		text = _active_table[key]
	elif _english_table.has(key):
		push_warning(
			"Localization: key '%s' missing from active locale '%s', falling back to English"
			% [key, _active_locale]
		)
		text = _english_table[key]
	else:
		push_warning("Localization: key '%s' not found in any locale" % key)
		return key
	return _interpolate(text, params) if not params.is_empty() else text

## Switches the active locale at runtime. Returns false without changing state if
## the code is not in SUPPORTED_LOCALES or its JSON file cannot be loaded.
## Emits locale_changed on success. Returns true without emitting if already on
## the requested locale (idempotent no-op).
## LOC-004: full implementation.
func switch_locale(code: String) -> bool:
	if code == _active_locale:
		return true
	if code not in SUPPORTED_LOCALES:
		push_warning("Localization: unsupported locale: " + code)
		return false
	var table: Dictionary = _load_table(code)
	if table.is_empty():
		push_warning("Localization: failed to load table for: " + code)
		return false
	_active_table = table
	_active_locale = code
	locale_changed.emit()
	return true

# ── Private Methods ───────────────────────────────────────────────────────────

## Applies {{key}} substitution from params into text.
## LOC-003: Iterates every key in params and replaces "{{key}}" with its value.
## Keys present in text but absent from params are left as-is (placeholders remain).
## Returns text unchanged when params is empty (caller short-circuits before here,
## but the guard is retained for direct callers).
func _interpolate(text: String, params: Dictionary) -> String:
	var result := text
	for key: String in params:
		result = result.replace("{{" + key + "}}", str(params[key]))
	return result

## Loads and parses the JSON string table for locale_code.
## Returns the parsed Dictionary on success, or an empty Dictionary on any error.
func _load_table(locale_code: String) -> Dictionary:
	var path: String = I18N_PATH + locale_code + ".json"
	return JsonLoader.load_dict(path)
