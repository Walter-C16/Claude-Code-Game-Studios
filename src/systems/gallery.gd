class_name Gallery
extends RefCounted

## Gallery — CG Collection Viewer
##
## Stateless utility class. All unlock state comes from GameStore story flags.
## Entry definitions are loaded once from gallery.json and cached statically.
##
## Unlock logic is read-only — Gallery never writes flags or mutates GameStore.
## A UI layer calls get_all_entries() and inspects the `unlocked` field per entry.
##
## Public API:
##   get_all_entries()      → Array[Dictionary] — all entries with unlock state
##   get_unlocked_count()   → int
##   get_total_count()      → int
##
## See: design/gdd/gallery.md
## Stories: AC-GAL-1 through AC-GAL-7

# ── Constants ─────────────────────────────────────────────────────────────────

const DATA_PATH: String = "res://assets/data/gallery.json"

# ── Static Cache ──────────────────────────────────────────────────────────────

## Raw entry dicts loaded from gallery.json. Keyed by insertion order.
static var _entries: Array[Dictionary] = []

## True once JSON has been loaded (even on failure — no retries).
static var _data_loaded: bool = false

# ── Public Static API ─────────────────────────────────────────────────────────

## Returns all gallery entries with current unlock state derived from GameStore.
##
## Each returned dict contains:
##   id          (String)  — stable identifier from JSON
##   title_key   (String)  — localization key for the entry title
##   cg_path     (String)  — res:// path to the CG image
##   type        (String)  — "intimacy" | "story" | "special"
##   unlocked    (bool)    — true if the unlock_flag is set in GameStore
##   sort_order  (int)     — display ordering hint (lower = earlier)
##
## Locked entries still appear in the array so the UI can show placeholders.
## The CG path and title are included — the UI layer is responsible for hiding
## them for locked entries per design/gdd/gallery.md Rule 3.
static func get_all_entries() -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for raw: Dictionary in _entries:
		result.append({
			"id":         raw.get("id", ""),
			"title_key":  raw.get("title_key", ""),
			"cg_path":    raw.get("cg_path", ""),
			"type":       raw.get("type", ""),
			"unlocked":   _is_unlocked(raw),
			"sort_order": raw.get("sort_order", 999),
		})
	return result

## Returns the number of entries whose unlock_flag is currently set in GameStore.
static func get_unlocked_count() -> int:
	_ensure_loaded()
	var count: int = 0
	for raw: Dictionary in _entries:
		if _is_unlocked(raw):
			count += 1
	return count

## Returns the total number of defined gallery entries regardless of unlock state.
static func get_total_count() -> int:
	_ensure_loaded()
	return _entries.size()

# ── Private Helpers ───────────────────────────────────────────────────────────

## Returns true if [param entry]'s unlock_flag is set in GameStore.
## Returns false if the entry has no unlock_flag field.
static func _is_unlocked(entry: Dictionary) -> bool:
	var flag: String = entry.get("unlock_flag", "")
	if flag.is_empty():
		return false
	return GameStore.has_flag(flag)

## Loads gallery.json into _entries if not already loaded.
## Sets _data_loaded = true even on failure to prevent repeated retries.
static func _ensure_loaded() -> void:
	if _data_loaded:
		return
	_data_loaded = true

	var root: Dictionary = JsonLoader.load_dict(DATA_PATH)
	if root.is_empty():
		return

	var raw_entries: Array = root.get("entries", []) as Array

	for raw: Variant in raw_entries:
		if raw is not Dictionary:
			continue
		var entry: Dictionary = raw as Dictionary
		var entry_id: String = entry.get("id", "")
		if entry_id.is_empty():
			push_warning("[Gallery] Entry with empty id skipped.")
			continue
		_entries.append(entry)

## Resets the static cache. For test isolation only — do not call in production.
static func _reset_cache() -> void:
	_entries = []
	_data_loaded = false
