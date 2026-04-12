class_name EquipmentSystem
extends RefCounted

## EquipmentSystem — Equipment Slot Management and Drop Generation
##
## Loads item definitions from res://assets/data/equipment.json and config
## knobs from res://assets/data/equipment_config.json. Manages the two
## equipment slots (weapon, amulet) and the pending_equipment queue via
## GameStore. Provides drop generation respecting rarity weights.
##
## Scoring pipeline integration:
##   get_weapon_chip_bonus() → injected at Step 4 (after captain, before blessings)
##   get_amulet_mult_bonus() → injected at Step D (after captain mult, before blessings)
##
## Both slots are empty by default (bonus = 0 / 0.0). EC-5: if JSON fails to
## load all bonuses default to 0 and combat proceeds without error.
##
## See: design/gdd/equipment.md
## Stories: STORY-EQUIP-001 through STORY-EQUIP-006

# ── Signals ──────────────────────────────────────────────────────────────────

## Emitted when an item is discarded due to full inventory.
## [param item_name_key] is the display_name_key of the discarded item.
signal inventory_full_discard(item_name_key: String)

## Emitted when pending inventory reaches the warning threshold (cap - 1).
signal inventory_near_full()

# ── Constants ─────────────────────────────────────────────────────────────────

const _ITEMS_PATH: String = "res://assets/data/equipment.json"
const _CONFIG_PATH: String = "res://assets/data/equipment_config.json"

const SLOT_WEAPON: String = "weapon"
const SLOT_AMULET: String = "amulet"

const RARITY_COMMON: String    = "common"
const RARITY_RARE: String      = "rare"
const RARITY_LEGENDARY: String = "legendary"

# ── Private State ─────────────────────────────────────────────────────────────

## All item definitions keyed by item id. Empty if JSON failed to load.
var _items: Dictionary = {}

## True once JSON data files have been loaded (even if load failed).
var _loaded: bool = false

## Config knobs loaded from equipment_config.json.
var _config: Dictionary = {}

## Default config values used if equipment_config.json fails to load.
const _DEFAULT_CONFIG: Dictionary = {
	"DROP_RATE_STANDARD":    20,
	"DROP_RATE_BOSS":        100,
	"RARITY_WEIGHT_COMMON":  65,
	"RARITY_WEIGHT_RARE":    30,
	"RARITY_WEIGHT_LEGENDARY": 5,
	"PENDING_INVENTORY_CAP": 5,
	"BOSS_MIN_RARITY":       "rare",
}

# ── Initialization ────────────────────────────────────────────────────────────

func _init() -> void:
	_load_data()

# ── Public API — Item Queries ─────────────────────────────────────────────────

## Returns the item dict for [param item_id], or an empty Dictionary if not found.
## Returns null only when JSON failed to load entirely (EC-5).
func get_item(item_id: String) -> Dictionary:
	if not _loaded:
		_load_data()
	return _items.get(item_id, {}) as Dictionary

## Returns all item dicts as an Array.
func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Variant in _items.values():
		result.append(item as Dictionary)
	return result

## Returns all item dicts for the given [param slot] ("weapon" or "amulet").
func get_items_by_slot(slot: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Variant in _items.values():
		var d: Dictionary = item as Dictionary
		if d.get("slot", "") == slot:
			result.append(d)
	return result

## Returns all item dicts for the given [param rarity].
func get_items_by_rarity(rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Variant in _items.values():
		var d: Dictionary = item as Dictionary
		if d.get("rarity", "") == rarity:
			result.append(d)
	return result

# ── Public API — Slot Management ──────────────────────────────────────────────

## Equips [param item_id] to its designated slot in GameStore.
## The item must have a valid "slot" field. Returns true on success,
## false if item_id is unknown.
## If an item is being equipped from pending_equipment, it is removed from
## the queue — pass [param from_pending_index] >= 0 to remove it.
func equip(item_id: String, from_pending_index: int = -1) -> bool:
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		push_error("EquipmentSystem.equip: unknown item_id '%s'" % item_id)
		return false

	var slot: String = item.get("slot", "") as String
	if slot == SLOT_WEAPON:
		GameStore.set_equipped_weapon(item_id)
	elif slot == SLOT_AMULET:
		GameStore.set_equipped_amulet(item_id)
	else:
		push_error("EquipmentSystem.equip: item '%s' has invalid slot '%s'" % [item_id, slot])
		return false

	# Remove from pending queue if it came from there.
	if from_pending_index >= 0:
		GameStore.remove_pending_equipment(from_pending_index)

	return true

## Clears the given [param slot] ("weapon" or "amulet").
func unequip(slot: String) -> void:
	if slot == SLOT_WEAPON:
		GameStore.set_equipped_weapon("")
	elif slot == SLOT_AMULET:
		GameStore.set_equipped_amulet("")
	else:
		push_error("EquipmentSystem.unequip: invalid slot '%s'" % slot)

## Returns the equipped item dict for [param slot], or an empty Dictionary
## if the slot is empty or the stored item_id is unknown.
func get_equipped(slot: String) -> Dictionary:
	var item_id: String = ""
	if slot == SLOT_WEAPON:
		item_id = GameStore.get_equipped_weapon()
	elif slot == SLOT_AMULET:
		item_id = GameStore.get_equipped_amulet()
	if item_id.is_empty():
		return {}
	return get_item(item_id)

# ── Public API — Scoring Bonuses ─────────────────────────────────────────────

## Returns the chip bonus from the equipped weapon. Returns 0 if slot empty
## or data failed to load (EC-5). Injected at Step 4 of the scoring pipeline.
func get_weapon_chip_bonus() -> int:
	var item: Dictionary = get_equipped(SLOT_WEAPON)
	if item.is_empty():
		return 0
	return item.get("chips_bonus", 0) as int

## Returns the mult bonus from the equipped amulet. Returns 0.0 if slot empty
## or data failed to load (EC-5). Injected at Step D of the scoring pipeline.
func get_amulet_mult_bonus() -> float:
	var item: Dictionary = get_equipped(SLOT_AMULET)
	if item.is_empty():
		return 0.0
	return item.get("mult_bonus", 0.0) as float

## Returns a dict with both bonuses captured at a single point in time.
## Used by CombatSystem to lock values at combat setup (AC-5).
##   {equipment_chips: int, equipment_mult: float}
func get_combat_bonuses() -> Dictionary:
	return {
		"equipment_chips": get_weapon_chip_bonus(),
		"equipment_mult":  get_amulet_mult_bonus(),
	}

# ── Public API — Drop Generation ─────────────────────────────────────────────

## Generates and returns a random item dict.
##
## If [param is_boss] is true the drop is guaranteed and rarity is at least
## "rare" (BOSS_MIN_RARITY). Otherwise a weighted rarity is selected from
## the config table.
##
## Returns an empty Dictionary if the item pool is empty or data failed to load.
func generate_drop(is_boss: bool) -> Dictionary:
	if _items.is_empty():
		push_error("EquipmentSystem.generate_drop: item pool is empty — check equipment.json")
		return {}

	var rarity: String = _pick_rarity(is_boss)
	return _random_item_by_rarity(rarity)

## Returns a random item dict for the given [param rarity] tier.
## Returns an empty Dictionary if no items of that rarity exist.
func get_random_item_by_rarity(rarity: String) -> Dictionary:
	return _random_item_by_rarity(rarity)

# ── Public API — Pending Queue ────────────────────────────────────────────────

## Adds [param item_id] to the pending_equipment queue if space permits.
## If the queue is at capacity ([_config.PENDING_INVENTORY_CAP]) the item is
## discarded and [signal inventory_full_discard] is emitted.
## Emits [signal inventory_near_full] when the queue reaches cap - 1 after adding.
## Returns true if the item was added, false if discarded.
func add_pending(item_id: String) -> bool:
	var cap: int = _config.get("PENDING_INVENTORY_CAP", 5) as int
	var pending: Array[String] = GameStore.get_pending_equipment()

	if pending.size() >= cap:
		var item: Dictionary = get_item(item_id)
		var name_key: String = item.get("name_key", item_id) as String
		inventory_full_discard.emit(name_key)
		return false

	GameStore.add_pending_equipment(item_id)

	var new_size: int = GameStore.get_pending_equipment().size()
	if new_size >= cap - 1:
		inventory_near_full.emit()

	return true

## Returns a copy of the pending_equipment Array[String] from GameStore.
func get_pending() -> Array[String]:
	return GameStore.get_pending_equipment()

## Removes the item at [param index] from pending_equipment.
## No-op if index is out of range.
func clear_pending(index: int) -> void:
	GameStore.remove_pending_equipment(index)

# ── Public API — Config Access ────────────────────────────────────────────────

## Returns the value of a config knob by key.
## Falls back to _DEFAULT_CONFIG if the key is absent.
func get_config(key: String) -> Variant:
	return _config.get(key, _DEFAULT_CONFIG.get(key, null))

# ── Private — Data Loading ────────────────────────────────────────────────────

## Loads equipment.json and equipment_config.json. Sets _loaded = true even
## on failure so repeated calls do not retry unnecessarily.
func _load_data() -> void:
	_loaded = true
	_load_items()
	_load_config()

func _load_items() -> void:
	var root: Dictionary = JsonLoader.load_dict(_ITEMS_PATH)
	if root.is_empty():
		return
	var raw_items: Array = root.get("items", []) as Array
	for raw: Variant in raw_items:
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw as Dictionary
		var item_id: String = item.get("id", "") as String
		if item_id.is_empty():
			push_warning("EquipmentSystem: item with empty id skipped")
			continue
		# Normalize: ensure both bonus fields always exist.
		if not item.has("chips_bonus"):
			item["chips_bonus"] = 0
		if not item.has("mult_bonus"):
			item["mult_bonus"] = 0.0
		_items[item_id] = item

func _load_config() -> void:
	var parsed: Dictionary = JsonLoader.load_dict(_CONFIG_PATH)
	if parsed.is_empty():
		_config = _DEFAULT_CONFIG.duplicate()
		return
	_config = parsed

# ── Private — Rarity Selection ────────────────────────────────────────────────

## Picks a rarity string using weighted random selection.
## If [param is_boss] is true, "common" is excluded (boss_min_rarity = "rare").
func _pick_rarity(is_boss: bool) -> String:
	var weight_common: int    = _config.get("RARITY_WEIGHT_COMMON", 65) as int
	var weight_rare: int      = _config.get("RARITY_WEIGHT_RARE", 30) as int
	var weight_legendary: int = _config.get("RARITY_WEIGHT_LEGENDARY", 5) as int

	if is_boss:
		# Boss floor: Rare or Legendary only.
		var total: int = weight_rare + weight_legendary
		var roll: int = randi() % total
		if roll < weight_rare:
			return RARITY_RARE
		return RARITY_LEGENDARY

	var total: int = weight_common + weight_rare + weight_legendary
	var roll: int = randi() % total
	if roll < weight_common:
		return RARITY_COMMON
	if roll < weight_common + weight_rare:
		return RARITY_RARE
	return RARITY_LEGENDARY

## Returns a random item dict from the pool matching [param rarity].
## Returns empty Dictionary if no items of that rarity exist.
func _random_item_by_rarity(rarity: String) -> Dictionary:
	var pool: Array[Dictionary] = get_items_by_rarity(rarity)
	if pool.is_empty():
		push_error("EquipmentSystem: no items found for rarity '%s'" % rarity)
		return {}
	var idx: int = randi() % pool.size()
	return pool[idx]
