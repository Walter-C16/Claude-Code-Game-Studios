class_name AbyssConfig
extends RefCounted

## AbyssConfig — Loads and exposes all Abyss Mode tuning knobs from JSON.
##
## All threshold and cost values originate from assets/data/abyss_config.json.
## No gameplay constants are hardcoded in this file. If the JSON fails to
## load, safe defaults are returned and an error is logged.
##
## Call AbyssConfig.new() once and inject into AbyssRun / AbyssShop.
##
## See: design/gdd/abyss-mode.md
## Stories: STORY-ABYSS-001

# ── Constants ─────────────────────────────────────────────────────────────────

const _CONFIG_PATH: String = "res://assets/data/abyss_config.json"

## Fallback values used when JSON fails to load. Matches GDD defaults exactly.
const _DEFAULTS: Dictionary = {
	"ante_thresholds": [300, 500, 800, 1200, 1800, 2700, 4000, 6000],
	"handsPerAnte": 4,
	"discardsPerAnte": 4,
	"baseHandGold": 2,
	"anteCompletionBonus": 15,
	"shopSlots": 3,
	"removalCost": 20,
	"foilCost": 15,
	"holographicCost": 20,
	"polychromeCost": 25,
	"buffs": {},
	"modifiers": [],
}

# ── Private State ─────────────────────────────────────────────────────────────

## Raw parsed JSON data. Empty dict if load failed.
var _data: Dictionary = {}

## True once a load attempt has been made.
var _loaded: bool = false

# ── Initialisation ────────────────────────────────────────────────────────────

func _init() -> void:
	_load_config()

## Loads abyss_config.json. Safe to call multiple times; only loads once.
func _load_config() -> void:
	if _loaded:
		return
	_loaded = true

	if not FileAccess.file_exists(_CONFIG_PATH):
		push_error("AbyssConfig: config file not found at %s — using defaults" % _CONFIG_PATH)
		return

	var file: FileAccess = FileAccess.open(_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("AbyssConfig: failed to open %s — using defaults" % _CONFIG_PATH)
		return

	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("AbyssConfig: malformed JSON in %s — using defaults" % _CONFIG_PATH)
		return

	_data = parsed as Dictionary

# ── Public API — Thresholds ───────────────────────────────────────────────────

## Returns the score threshold for [param ante] (1-indexed, 1–8).
## Returns -1 and logs a warning for out-of-bounds ante values.
func get_threshold(ante: int) -> int:
	var thresholds: Array = _get("ante_thresholds") as Array
	if ante < 1 or ante > thresholds.size():
		push_warning("AbyssConfig.get_threshold: ante %d is out of bounds (valid: 1–%d)" % [ante, thresholds.size()])
		return -1
	return thresholds[ante - 1] as int

## Returns the full thresholds array. Safe — never returns null.
func get_all_thresholds() -> Array[int]:
	var raw: Array = _get("ante_thresholds") as Array
	var result: Array[int] = []
	for v: Variant in raw:
		result.append(v as int)
	return result

## Returns the total number of antes in a run.
func get_ante_count() -> int:
	return (_get("ante_thresholds") as Array).size()

# ── Public API — Combat Config ────────────────────────────────────────────────

## Hands allowed per ante.
func get_hands_per_ante() -> int:
	return _get("handsPerAnte") as int

## Discards allowed per ante.
func get_discards_per_ante() -> int:
	return _get("discardsPerAnte") as int

# ── Public API — Gold Economy ─────────────────────────────────────────────────

## Gold awarded per hand played (BASE_HAND_GOLD).
func get_base_hand_gold() -> int:
	return _get("baseHandGold") as int

## Gold bonus awarded on ante threshold completion.
func get_ante_completion_bonus() -> int:
	return _get("anteCompletionBonus") as int

# ── Public API — Shop ─────────────────────────────────────────────────────────

## Number of shop slots generated per visit.
func get_shop_slots() -> int:
	return _get("shopSlots") as int

## Gold cost to remove one card from the run deck.
func get_removal_cost() -> int:
	return _get("removalCost") as int

## Gold cost for Foil enhancement.
func get_foil_cost() -> int:
	return _get("foilCost") as int

## Gold cost for Holographic enhancement.
func get_holographic_cost() -> int:
	return _get("holographicCost") as int

## Gold cost for Polychrome enhancement.
func get_polychrome_cost() -> int:
	return _get("polychromeCost") as int

# ── Public API — Buffs / Modifiers ────────────────────────────────────────────

## Returns the raw buff config dictionary keyed by buff_id.
func get_buffs_config() -> Dictionary:
	return _get("buffs") as Dictionary

## Returns the raw modifiers array.
func get_modifiers_config() -> Array:
	return _get("modifiers") as Array

# ── Private Helpers ───────────────────────────────────────────────────────────

## Returns value from loaded data or falls back to _DEFAULTS.
func _get(key: StringName) -> Variant:
	if _data.has(key):
		return _data[key]
	if _DEFAULTS.has(key):
		return _DEFAULTS[key]
	push_error("AbyssConfig._get: unknown key '%s'" % key)
	return null
