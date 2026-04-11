class_name GiftItems
extends RefCounted

## GiftItems — Gift Item Catalogue and Purchase Validation (ADR-0015)
##
## Stateless utility class with static methods. Loads 6 gift items from
## res://assets/data/gift_items.json on first access (lazy singleton pattern).
## No item IDs, costs, categories, or name keys appear as literals in this file —
## all data is sourced from the JSON file.
##
## Purchase flow (Camp → GiftItems → GameStore → RomanceSocial):
##   1. GiftItems.can_afford(item_id, GameStore.get_gold()) — validate
##   2. GameStore.spend_gold(GiftItems.get_cost(item_id))   — deduct
##   3. RomanceSocial.do_gift(companion_id, item_id)        — process outcome
##
## See: docs/architecture/adr-0015-gift-items.md

# ── Private Cache ─────────────────────────────────────────────────────────────

## Lazy-loaded item cache. Populated on first call to _load_items().
static var _items_cache: Array[Dictionary] = []

## True after the first successful load attempt.
static var _loaded: bool = false

## True if the JSON file failed to load. Callers can check this to gate UI.
static var _load_failed: bool = false

const DATA_PATH: String = "res://assets/data/gift_items.json"

# ── Public Static API ─────────────────────────────────────────────────────────

## Returns all gift items as an Array[Dictionary].
## Each dict has: id, name_key, category, gold_cost.
## Returns an empty array if the data file could not be loaded.
static func get_items() -> Array[Dictionary]:
	_ensure_loaded()
	return _items_cache.duplicate()

## Returns the item dict for [param id], or an empty Dictionary if not found.
static func get_item(id: String) -> Dictionary:
	_ensure_loaded()
	for item: Dictionary in _items_cache:
		if item.get("id", "") == id:
			return item.duplicate()
	return {}

## Returns true if [param player_gold] >= the cost of the item with [param item_id].
## Returns false if the item is not found.
static func can_afford(item_id: String, player_gold: int) -> bool:
	var cost: int = get_cost(item_id)
	if cost < 0:
		return false
	return player_gold >= cost

## Returns the gold_cost for the item with [param item_id].
## Returns -1 if the item is not found.
static func get_cost(item_id: String) -> int:
	_ensure_loaded()
	for item: Dictionary in _items_cache:
		if item.get("id", "") == item_id:
			return item.get("gold_cost", 0)
	return -1

## Returns true if the JSON file loaded successfully. False signals a load error.
static func is_loaded() -> bool:
	_ensure_loaded()
	return not _load_failed

## Clears the internal cache, forcing a reload on the next access.
## Use in tests to reset state between runs.
static func _reset_cache() -> void:
	_items_cache.clear()
	_loaded = false
	_load_failed = false

# ── Private ───────────────────────────────────────────────────────────────────

## Loads items from DATA_PATH on first call. Subsequent calls are no-ops.
static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_items()

## Parses the JSON data file and populates _items_cache.
static func _load_items() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("[GiftItems] Data file not found: %s" % DATA_PATH)
		_load_failed = true
		return

	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("[GiftItems] Failed to open: %s" % DATA_PATH)
		_load_failed = true
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null:
		push_error("[GiftItems] Failed to parse JSON: %s" % DATA_PATH)
		_load_failed = true
		return

	if not parsed is Array:
		push_error("[GiftItems] Expected top-level Array in %s" % DATA_PATH)
		_load_failed = true
		return

	_items_cache.clear()
	for entry: Variant in parsed as Array:
		if entry is Dictionary:
			_items_cache.append(entry as Dictionary)

	if _items_cache.is_empty():
		push_warning("[GiftItems] No items loaded from %s" % DATA_PATH)
