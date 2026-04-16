class_name Forge
extends RefCounted

## Forge — Equipment gacha pure logic.
##
## Shares the Oracle's weekly pull cap. Each pull rolls the outcome_table:
##   70% → forge fragments (3-5 per roll)
##   25% → random equipment item (uncommon — normal drop)
##   5%  → random equipment item (rare — boss-grade drop)
##
## Config loaded from forge_pool.json. Equipment drops delegate to
## EquipmentSystem.generate_drop so the item pool stays centralised.
##
## See design/quick-specs/forge-gacha.md for the full system design.

const DATA_PATH: String = "res://assets/data/forge_pool.json"

var single_cost: int = 30
var ten_cost: int = 270
var fragment_min: int = 3
var fragment_max: int = 5
var _outcome_table: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	_load_config()


func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng


func _load_config() -> void:
	var data: Dictionary = JsonLoader.load_dict(DATA_PATH)
	if data.is_empty():
		return
	var cfg: Dictionary = data.get("config", {})
	single_cost = int(cfg.get("single_cost", 30))
	ten_cost = int(cfg.get("ten_cost", 270))
	fragment_min = int(cfg.get("fragment_drop_min", 3))
	fragment_max = int(cfg.get("fragment_drop_max", 5))
	_outcome_table = []
	for entry: Variant in (data.get("outcome_table", []) as Array):
		_outcome_table.append(entry as Dictionary)
	if _outcome_table.is_empty():
		_outcome_table = [{"prob": 1.0, "type": "fragments"}]


## Shared cap validation — uses the same Oracle weekly counter.
func can_single_pull(gold: int, pulls_this_week: int, weekly_cap: int) -> bool:
	return gold >= single_cost and pulls_this_week < weekly_cap


func can_ten_pull(gold: int, pulls_this_week: int, weekly_cap: int) -> bool:
	return gold >= ten_cost and pulls_this_week + 10 <= weekly_cap


## Rolls a single forge outcome. Returns a result dict:
##   {"type": "fragments", "fragments": int}           — fragment drop
##   {"type": "equipment", "item": Dictionary}         — equipment item
##   {"type": "equipment", "item": {}}                 — equipment pool empty fallback
func roll_single() -> Dictionary:
	var row: Dictionary = _pick_outcome_row()
	var result_type: String = row.get("type", "fragments") as String

	if result_type == "equipment":
		var equip_sys: EquipmentSystem = EquipmentSystem.new()
		var is_boss: bool = bool(row.get("is_boss", false))
		var item: Dictionary = equip_sys.generate_drop(is_boss)
		return {"type": "equipment", "item": item}

	# Default: fragment drop.
	var count: int = _rng.randi_range(fragment_min, fragment_max)
	return {"type": "fragments", "fragments": count}


## Rolls 10 outcomes. Returns an Array of per-roll result dicts (same
## shape as roll_single).
func roll_ten() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for _i: int in range(10):
		results.append(roll_single())
	return results


## Picks an outcome row from the table using cumulative probability mass.
func _pick_outcome_row() -> Dictionary:
	var roll: float = _rng.randf()
	var cumulative: float = 0.0
	for row: Dictionary in _outcome_table:
		cumulative += float(row.get("prob", 0.0))
		if roll < cumulative:
			return row
	return _outcome_table[_outcome_table.size() - 1]
