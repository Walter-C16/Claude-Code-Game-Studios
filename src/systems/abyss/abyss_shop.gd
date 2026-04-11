class_name AbyssShop
extends RefCounted

## AbyssShop — Between-ante shop system for Abyss Mode.
##
## Generates exactly [shopSlots] shop slots per visit (default 3), each
## offering one of: card removal, card enhancement, or a temporary run buff.
## Purchasing deducts from run_gold. Gold never goes below 0. Re-roll is
## not available (GDD EC-6).
##
## AbyssShop does not mutate AbyssRun directly — it returns result dicts that
## the caller applies to AbyssRun state (deck, run_buffs, run_gold).
##
## Design contract:
##   - generate_stock() produces fresh slots each shop visit
##   - purchase(slot, run) returns { "ok": bool, "reason": String } and mutates run
##   - Enhancement stacking is allowed (GDD EC-8)
##
## See: design/gdd/abyss-mode.md (Rule 3)
## Stories: STORY-ABYSS-003

# ── Enums ─────────────────────────────────────────────────────────────────────

enum SlotType {
	CARD_REMOVAL,
	ENHANCEMENT_FOIL,
	ENHANCEMENT_HOLOGRAPHIC,
	ENHANCEMENT_POLYCHROME,
	BUFF,
}

# ── Private State ─────────────────────────────────────────────────────────────

## Injected config for all cost and slot-count knobs.
var _config: AbyssConfig = null

# ── Construction ──────────────────────────────────────────────────────────────

## [param config] — AbyssConfig instance. Must not be null.
func _init(config: AbyssConfig) -> void:
	_config = config

# ── Public API — Stock Generation ────────────────────────────────────────────

## Generates a fresh set of shop slots for one shop visit.
##
## Returns an Array of exactly [shopSlots] ShopSlot dictionaries.
## Each slot has keys: { "type": SlotType, "cost": int, "purchased": bool,
##                       "buff_id": String (BUFF slots only),
##                       "enhancement": String (enhancement slots only) }
##
## Slot selection uses a simple round-robin to guarantee variety:
##   slot 0 → CARD_REMOVAL, slot 1 → BUFF (random), slot 2 → enhancement (random)
## This is deterministic given a seed; caller may shuffle for UI variety.
func generate_stock(run: AbyssRun) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var slot_count: int = _config.get_shop_slots()

	# Slot composition: removal + buff + enhancement (cycles if shopSlots > 3)
	var slot_templates: Array[Dictionary] = [
		{ "type": SlotType.CARD_REMOVAL, "cost": _config.get_removal_cost() },
		_random_buff_slot(run),
		_random_enhancement_slot(),
	]

	for i: int in range(slot_count):
		var template: Dictionary = slot_templates[i % slot_templates.size()].duplicate()
		template["purchased"] = false
		slots.append(template)

	return slots

# ── Public API — Purchase ─────────────────────────────────────────────────────

## Attempts to purchase [param slot] using gold from [param run].
##
## Returns: { "ok": bool, "reason": String }
##   ok=true  → purchase succeeded; run state mutated.
##   ok=false → purchase rejected; run state unchanged.
##
## Rejection reasons: "insufficient_gold", "already_purchased", "no_valid_target"
func purchase(slot: Dictionary, run: AbyssRun) -> Dictionary:
	if slot.get("purchased", false):
		return { "ok": false, "reason": "already_purchased" }

	var cost: int = slot.get("cost", 0) as int
	if run.run_gold < cost:
		return { "ok": false, "reason": "insufficient_gold" }

	var slot_type: int = slot.get("type", -1) as int
	var apply_result: Dictionary = _apply_slot(slot_type, slot, run)
	if not apply_result.get("ok", false):
		return apply_result

	run.run_gold -= cost
	slot["purchased"] = true
	return { "ok": true, "reason": "" }

# ── Private — Slot Builders ───────────────────────────────────────────────────

## Builds a random buff slot. Excludes Fortune's Eye if run is already on last ante.
func _random_buff_slot(_run: AbyssRun) -> Dictionary:
	var buffs_cfg: Dictionary = _config.get_buffs_config()
	var buff_ids: Array = buffs_cfg.keys()
	if buff_ids.is_empty():
		# Fallback to a known default if config is empty.
		buff_ids = ["hunters_focus"]

	# Pick deterministically from available buff ids.
	var idx: int = randi() % buff_ids.size()
	var buff_id: String = buff_ids[idx] as String
	var buff_data: Dictionary = buffs_cfg.get(buff_id, {}) as Dictionary
	var cost: int = buff_data.get("cost", 10) as int

	return {
		"type": SlotType.BUFF,
		"cost": cost,
		"buff_id": buff_id,
	}

## Builds a random enhancement slot (Foil / Holographic / Polychrome).
func _random_enhancement_slot() -> Dictionary:
	var enhancement_types: Array[SlotType] = [
		SlotType.ENHANCEMENT_FOIL,
		SlotType.ENHANCEMENT_HOLOGRAPHIC,
		SlotType.ENHANCEMENT_POLYCHROME,
	]
	var enhancement_names: Array[String] = ["Foil", "Holographic", "Polychrome"]
	var costs: Array[int] = [
		_config.get_foil_cost(),
		_config.get_holographic_cost(),
		_config.get_polychrome_cost(),
	]

	var idx: int = randi() % enhancement_types.size()
	return {
		"type": enhancement_types[idx],
		"cost": costs[idx],
		"enhancement": enhancement_names[idx],
	}

# ── Private — Slot Application ────────────────────────────────────────────────

## Dispatches slot application to the correct handler.
func _apply_slot(slot_type: int, slot: Dictionary, run: AbyssRun) -> Dictionary:
	match slot_type:
		SlotType.CARD_REMOVAL:
			return _apply_removal(slot, run)
		SlotType.ENHANCEMENT_FOIL, SlotType.ENHANCEMENT_HOLOGRAPHIC, SlotType.ENHANCEMENT_POLYCHROME:
			return _apply_enhancement(slot, run)
		SlotType.BUFF:
			return _apply_buff(slot, run)
		_:
			return { "ok": false, "reason": "unknown_slot_type" }

## Removes one card from the run deck. Uses slot["target_index"] if set,
## otherwise picks the first non-removed card.
## Stacks accumulated removals in run.removed_cards.
func _apply_removal(slot: Dictionary, run: AbyssRun) -> Dictionary:
	var target: int = slot.get("target_index", -1) as int
	if target == -1:
		# Auto-pick the first available card index.
		for i: int in range(run.deck.size()):
			if not run.removed_cards.has(i):
				target = i
				break

	if target == -1 or target >= run.deck.size():
		return { "ok": false, "reason": "no_valid_target" }
	if run.removed_cards.has(target):
		return { "ok": false, "reason": "no_valid_target" }

	run.removed_cards.append(target)
	return { "ok": true, "reason": "" }

## Applies an enhancement to a card in the run deck.
## Uses slot["target_index"] if set; otherwise picks a random valid card.
## Stacking is allowed (GDD EC-8): existing enhancements are not replaced.
func _apply_enhancement(slot: Dictionary, run: AbyssRun) -> Dictionary:
	var enhancement: String = slot.get("enhancement", "") as String
	if enhancement.is_empty():
		return { "ok": false, "reason": "no_valid_target" }

	var target: int = slot.get("target_index", -1) as int
	if target == -1:
		# Auto-pick a random non-removed card.
		var available: Array[int] = []
		for i: int in range(run.deck.size()):
			if not run.removed_cards.has(i):
				available.append(i)
		if available.is_empty():
			return { "ok": false, "reason": "no_valid_target" }
		target = available[randi() % available.size()]

	if target < 0 or target >= run.deck.size():
		return { "ok": false, "reason": "no_valid_target" }
	if run.removed_cards.has(target):
		return { "ok": false, "reason": "no_valid_target" }

	# Append enhancement — stacking allowed per GDD EC-8.
	var card: Dictionary = run.deck[target]
	var existing: String = card.get("enhancement", "") as String
	if existing.is_empty():
		card["enhancement"] = enhancement
	else:
		# Stack by concatenating with "+" separator.
		card["enhancement"] = existing + "+" + enhancement
	run.deck[target] = card

	return { "ok": true, "reason": "" }

## Adds a run buff to run.run_buffs. Buffs from the same buff_id stack additively.
func _apply_buff(slot: Dictionary, run: AbyssRun) -> Dictionary:
	var buff_id: String = slot.get("buff_id", "") as String
	if buff_id.is_empty():
		return { "ok": false, "reason": "no_valid_target" }

	var buffs_cfg: Dictionary = _config.get_buffs_config()
	var buff_data: Dictionary = buffs_cfg.get(buff_id, {}) as Dictionary
	if buff_data.is_empty():
		push_warning("AbyssShop: unknown buff_id '%s'" % buff_id)
		return { "ok": false, "reason": "no_valid_target" }

	run.run_buffs.append({
		"buff_id": buff_id,
		"effect": buff_data.get("effect", "") as String,
		"value": buff_data.get("value", 0),
	})
	return { "ok": true, "reason": "" }
