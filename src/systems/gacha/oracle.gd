class_name Oracle
extends RefCounted

## Oracle — Companion gacha pure logic.
##
## Handles Bond Shard rolling, Epithet progression, pull-cost validation,
## and the weekly cap. This class holds no UI state — the scene layer calls
## [method roll_single] / [method roll_ten] and reacts to the returned
## Dictionary payloads.
##
## Config is loaded from [code]res://assets/data/oracle_pool.json[/code] at
## construction so designers can tune costs, weights, and thresholds without
## touching code.
##
## Determinism for tests: callers may inject a pre-seeded
## [code]RandomNumberGenerator[/code] via [method set_rng] so distribution
## sweeps are reproducible. Default RNG is unseeded for runtime use.
##
## See design/quick-specs/oracle-gacha.md for the full system design.

# ── Configuration ────────────────────────────────────────────────────────────

const DATA_PATH: String = "res://assets/data/oracle_pool.json"

var single_cost: int = 25
var ten_cost: int = 220
var weekly_cap: int = 30
var epithet_vi_refund_gold: int = 15
## Per-tier shard deltas (cost to go FROM that tier to the next). Index 0
## is the cost to reach Epithet I, index 5 is the cost to reach Epithet VI.
## Cumulative costs (5, 8, 13, 20, 30, 45) are in the design doc for reader
## clarity but the code operates on deltas for a simpler unlock loop.
var epithet_costs: Array[int] = [5, 3, 5, 7, 10, 15]
var weights_by_epithet: Array[float] = [4.0, 3.0, 3.0, 2.0, 2.0, 1.0, 0.25]
var outcome_table: Array[Dictionary] = []
var goddess_ids: Array[String] = []

## Internal RNG. Tests can swap this out with [method set_rng].
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


# ── Construction ─────────────────────────────────────────────────────────────

func _init() -> void:
	_rng.randomize()
	_load_config()


## Tests use this to inject a deterministic RNG.
func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng


func _load_config() -> void:
	var data: Dictionary = JsonLoader.load_dict(DATA_PATH)
	if data.is_empty():
		push_error("Oracle: failed to load %s — falling back to hardcoded defaults" % DATA_PATH)
		outcome_table = _default_outcome_table()
		goddess_ids = ["artemis", "hipolita", "atenea", "nyx"]
		return

	var cfg: Dictionary = data.get("config", {})
	single_cost = int(cfg.get("single_cost", 25))
	ten_cost = int(cfg.get("ten_cost", 220))
	weekly_cap = int(cfg.get("weekly_cap", 30))
	epithet_vi_refund_gold = int(cfg.get("epithet_vi_refund_gold", 15))

	epithet_costs = []
	for entry: Variant in (data.get("epithet_costs", []) as Array):
		epithet_costs.append(int(entry))
	if epithet_costs.size() != 6:
		push_warning("Oracle: epithet_costs has %d entries, expected 6" % epithet_costs.size())

	weights_by_epithet = []
	for entry: Variant in (data.get("weights_by_epithet", []) as Array):
		weights_by_epithet.append(float(entry))
	if weights_by_epithet.size() != 7:
		push_warning("Oracle: weights_by_epithet has %d entries, expected 7" % weights_by_epithet.size())

	outcome_table = []
	for entry: Variant in (data.get("outcome_table", []) as Array):
		outcome_table.append(entry as Dictionary)
	if outcome_table.is_empty():
		outcome_table = _default_outcome_table()

	goddess_ids = []
	for entry: Variant in (data.get("goddess_ids", []) as Array):
		goddess_ids.append(str(entry))


static func _default_outcome_table() -> Array[Dictionary]:
	return [
		{"prob": 0.60, "shards": 1, "player_pick": false},
		{"prob": 0.30, "shards": 2, "player_pick": false},
		{"prob": 0.09, "shards": 3, "player_pick": false},
		{"prob": 0.01, "shards": 5, "player_pick": true},
	]


# ── Cost validation ──────────────────────────────────────────────────────────

## True when the player has enough gold AND hasn't exhausted the weekly cap
## for a single pull. Checked before `roll_single` runs.
func can_single_pull(gold: int, pulls_this_week: int) -> bool:
	return gold >= single_cost and pulls_this_week < weekly_cap


## True when the player has enough gold AND enough weekly cap headroom to
## spend 10 pulls atomically. Ten-pulls are all-or-nothing — we never let
## a partial pull happen on cap boundary.
func can_ten_pull(gold: int, pulls_this_week: int) -> bool:
	return gold >= ten_cost and pulls_this_week + 10 <= weekly_cap


# ── Core rolling ─────────────────────────────────────────────────────────────

## Rolls a single outcome and returns a Dictionary payload describing the
## result. Does NOT mutate GameStore — the caller is responsible for
## applying the shard/epithet/refund changes via [method apply_result].
##
## Result shape:
##   {
##     "shards": int,                    # raw count before application
##     "player_pick": bool,              # legendary row forces the UI to ask
##     "goddess": String,                # chosen goddess (empty if player_pick)
##     "rarity_index": int,              # row in outcome_table
##   }
##
## [param epithets] is a snapshot of the current {goddess_id: tier} state so
## the weighted pick can favor the lowest-Epithet companion.
func roll_single(epithets: Dictionary) -> Dictionary:
	var row_index: int = _pick_outcome_row()
	var row: Dictionary = outcome_table[row_index]
	var shards_count: int = int(row.get("shards", 1))
	var player_pick: bool = bool(row.get("player_pick", false))

	var result: Dictionary = {
		"shards": shards_count,
		"player_pick": player_pick,
		"goddess": "",
		"rarity_index": row_index,
	}

	if not player_pick:
		result["goddess"] = _pick_weighted_goddess(epithets)

	return result


## Rolls 10 outcomes back-to-back plus one bonus shard for the current
## lowest-Epithet goddess (the "guaranteed bonus" ten-pull mechanic).
## Returns an Array of per-roll result dicts.
func roll_ten(epithets: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for i: int in range(10):
		results.append(roll_single(epithets))

	# Guaranteed bonus — one extra shard for the lowest-Epithet goddess.
	# Ties broken by goddess_ids ordering (first-declared wins).
	var bonus_goddess: String = _pick_lowest_epithet_goddess(epithets)
	if not bonus_goddess.is_empty():
		results.append({
			"shards": 1,
			"player_pick": false,
			"goddess": bonus_goddess,
			"rarity_index": -1,  # marker: bonus, not a real roll
		})
	return results


# ── Result application ──────────────────────────────────────────────────────

## Applies a roll result to the given shard/epithet snapshots, returning a
## diff dict describing what changed. Pure function — callers pass in the
## current state, get back the updated state + refund payload.
##
## Returns:
##   {
##     "shards": Dictionary,            # updated shard balances
##     "epithets": Dictionary,          # updated epithet tiers
##     "refund_gold": int,              # gold to add back if VI was reached
##     "unlocked": Array[String],       # goddess ids that hit Epithet I on this call
##     "promoted": Array[Dictionary],   # {id, from, to} for every tier-up
##   }
func apply_result(
	result: Dictionary,
	shards: Dictionary,
	epithets: Dictionary,
	override_goddess: String = ""
) -> Dictionary:
	var goddess: String = override_goddess if not override_goddess.is_empty() else (result.get("goddess", "") as String)
	if goddess.is_empty():
		return {
			"shards": shards,
			"epithets": epithets,
			"refund_gold": 0,
			"unlocked": [] as Array[String],
			"promoted": [] as Array[Dictionary],
		}

	var out_shards: Dictionary = shards.duplicate()
	var out_epithets: Dictionary = epithets.duplicate()
	var refund: int = 0
	var unlocked: Array[String] = []
	var promoted: Array[Dictionary] = []

	var count: int = int(result.get("shards", 0))
	var current_shards: int = int(out_shards.get(goddess, 0)) + count
	var current_tier: int = int(out_epithets.get(goddess, 0))

	# Unlock loop — consume shards while we can afford the next tier.
	while current_tier < 6 and current_shards >= _cost_to_next_tier(current_tier):
		var cost: int = _cost_to_next_tier(current_tier)
		current_shards -= cost
		var before: int = current_tier
		current_tier += 1
		promoted.append({"id": goddess, "from": before, "to": current_tier})
		if current_tier == 1:
			unlocked.append(goddess)

	# Epithet VI refund path — surplus shards convert to gold, capped at
	# the single pull cost so legendaries on maxed goddesses can't generate
	# infinite profit (5 shards × 15 = 75 gold, but pull costs 25 → capped).
	if current_tier >= 6 and current_shards > 0:
		refund = mini(current_shards * epithet_vi_refund_gold, single_cost)
		current_shards = 0

	out_shards[goddess] = current_shards
	out_epithets[goddess] = current_tier

	return {
		"shards": out_shards,
		"epithets": out_epithets,
		"refund_gold": refund,
		"unlocked": unlocked,
		"promoted": promoted,
	}


# ── Helpers ──────────────────────────────────────────────────────────────────

## Returns the shard cost to reach the tier immediately above [param tier].
## Tier 0 → 1 costs the epithet_costs[0] delta, tier 5 → 6 costs the
## epithet_costs[5] delta. Tier 6 has no next and returns 0.
func _cost_to_next_tier(tier: int) -> int:
	if tier >= 6:
		return 0
	return epithet_costs[tier]


## Rolls a uniform float and returns the row index in outcome_table that
## covers it, using cumulative probability mass.
func _pick_outcome_row() -> int:
	var roll: float = _rng.randf()
	var cumulative: float = 0.0
	for i: int in range(outcome_table.size()):
		cumulative += float(outcome_table[i].get("prob", 0.0))
		if roll < cumulative:
			return i
	return outcome_table.size() - 1  # defensive fallback


## Weighted random pick across the goddess pool, favoring those at lower
## Epithet tiers. Uses weights_by_epithet[tier] as the per-goddess weight.
func _pick_weighted_goddess(epithets: Dictionary) -> String:
	if goddess_ids.is_empty():
		return ""
	var total: float = 0.0
	var weights: Array[float] = []
	for id: String in goddess_ids:
		var tier: int = clampi(int(epithets.get(id, 0)), 0, 6)
		var w: float = weights_by_epithet[tier]
		weights.append(w)
		total += w
	if total <= 0.0:
		return goddess_ids[0]

	var roll: float = _rng.randf() * total
	var cumulative: float = 0.0
	for i: int in range(goddess_ids.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return goddess_ids[i]
	return goddess_ids[goddess_ids.size() - 1]


## Returns the first goddess tied for the lowest Epithet tier. Used by
## ten-pull's guaranteed-bonus shard to prioritize whoever is behind.
func _pick_lowest_epithet_goddess(epithets: Dictionary) -> String:
	if goddess_ids.is_empty():
		return ""
	var best_id: String = ""
	var best_tier: int = 999
	for id: String in goddess_ids:
		var tier: int = int(epithets.get(id, 0))
		if tier < best_tier:
			best_tier = tier
			best_id = id
	return best_id
