class_name Forge
extends RefCounted

## Forge — Equipment gacha pure logic (v1: fragments only).
##
## Shares the Oracle's weekly pull cap. Each pull grants 3-5 forge fragments
## (v1 — all outcome rows resolve to fragments; equipment drops land in v2
## when the Equipment GDD ships). Config loaded from forge_pool.json.
##
## See design/quick-specs/forge-gacha.md for the full system design.

const DATA_PATH: String = "res://assets/data/forge_pool.json"

var single_cost: int = 30
var ten_cost: int = 270
var fragment_min: int = 3
var fragment_max: int = 5
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


## Shared cap validation — uses the same Oracle weekly counter.
func can_single_pull(gold: int, pulls_this_week: int, weekly_cap: int) -> bool:
	return gold >= single_cost and pulls_this_week < weekly_cap


func can_ten_pull(gold: int, pulls_this_week: int, weekly_cap: int) -> bool:
	return gold >= ten_cost and pulls_this_week + 10 <= weekly_cap


## Rolls a single forge outcome. Returns the fragment count granted.
func roll_single() -> int:
	return _rng.randi_range(fragment_min, fragment_max)


## Rolls 10 outcomes and returns the total fragment count.
func roll_ten() -> int:
	var total: int = 0
	for _i: int in range(10):
		total += roll_single()
	return total
