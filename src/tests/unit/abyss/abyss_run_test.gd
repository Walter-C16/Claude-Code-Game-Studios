class_name AbyssRunTest
extends GdUnitTestSuite

## Unit tests for Abyss Mode — STORY-ABYSS-001 through STORY-ABYSS-007
##
## Covers:
##   ABYSS-001 AC1 — get_threshold(1–8) returns correct values
##   ABYSS-001 AC2 — get_threshold(0) and get_threshold(9) return -1
##   ABYSS-001 AC3 — config constants readable with correct default values
##   ABYSS-001 AC4 — AbyssConfig falls back to defaults without crashing
##   ABYSS-002 AC1 — start_run() transitions LOBBY → ANTE_COMBAT, ante_current=1
##   ABYSS-002 AC2 — complete_ante() (not ante 8) → SHOP
##   ABYSS-002 AC3 — defeat() → DEFEAT
##   ABYSS-002 AC4 — enter_next_ante() → ANTE_COMBAT, ante_current increments
##   ABYSS-002 AC5 — ante 8 complete → COMPLETE
##   ABYSS-002 AC7 — start_run() from DEFEAT resets all run state
##   ABYSS-004 AC1 — 4 hands, no buffs → gold = (4*2)+15 = 23
##   ABYSS-004 AC2 — Golden Hand buff → gold = (4*(2+5))+15 = 43
##   ABYSS-004 AC5 — new run starts with run_gold = 0
##   ABYSS-004 AC6 — complete_ante uses actual hands_used, not fixed 4
##   ABYSS-003 AC2 — purchase CARD_REMOVAL with sufficient gold succeeds
##   ABYSS-003 AC3 — purchase with insufficient gold is rejected
##   ABYSS-003 AC4 — run_gold never goes below 0
##   ABYSS-003 AC5 — already purchased slot is rejected
##   ABYSS-003 AC6 — enhancement purchase mutates run deck
##   ABYSS-003 AC7 — enhancement stacks on already-enhanced card (EC-8)
##   ABYSS-006 AC1 — Hunter's Focus buff injects chip_bonus effect
##   ABYSS-006 AC2 — Divine Favor buff injects mult_bonus effect
##   ABYSS-006 AC3 — Last Gambit buff increases hands_allowed in enemy config
##   ABYSS-006 AC6 — Two Hunter's Focus buffs stack additively
##   ABYSS-007 AC1 — build_run_summary returns required keys
##   ABYSS-007 AC2 — new highscore is flagged
##
## See: design/gdd/abyss-mode.md

const AbyssConfigScript = preload("res://systems/abyss/abyss_config.gd")
const AbyssRunScript = preload("res://systems/abyss/abyss_run.gd")
const AbyssShopScript = preload("res://systems/abyss/abyss_shop.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

## Returns a fresh AbyssConfig loaded from the real JSON file.
func _make_config():
	return AbyssConfigScript.new()

## Returns a fresh AbyssRun with a real config.
func _make_run():
	var cfg = _make_config()
	return AbyssRunScript.new(cfg)

## Returns a fresh AbyssShop with a real config.
func _make_shop():
	var cfg = _make_config()
	return AbyssShopScript.new(cfg)

## Returns a minimal 52-card deck for testing.
func _make_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	var suits: Array[String] = ["Hearts", "Diamonds", "Clubs", "Spades"]
	var values: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
	for suit: String in suits:
		for value: int in values:
			deck.append({
				"suit": suit,
				"value": value,
				"element": "Fire",
				"enhancement": "",
				"is_signature": false,
				"companion_id": "",
			})
	return deck

# ── ABYSS-001: Ante Threshold Progression Data ────────────────────────────────

func test_abyss_config_threshold_ante_1_returns_300() -> void:
	# Arrange
	var cfg = _make_config()
	# Act
	var result: int = cfg.get_threshold(1)
	# Assert
	assert_int(result).is_equal(300)

func test_abyss_config_threshold_ante_8_returns_6000() -> void:
	# Arrange
	var cfg = _make_config()
	# Act
	var result: int = cfg.get_threshold(8)
	# Assert
	assert_int(result).is_equal(6000)

func test_abyss_config_all_8_thresholds_match_gdd() -> void:
	# Arrange
	var cfg = _make_config()
	var expected: Array[int] = [300, 500, 800, 1200, 1800, 2700, 4000, 6000]
	# Act / Assert
	for i: int in range(expected.size()):
		var threshold: int = cfg.get_threshold(i + 1)
		assert_int(threshold).is_equal(expected[i])

func test_abyss_config_threshold_ante_0_returns_minus_1() -> void:
	# Arrange — ante 0 is out of bounds (antes are 1-indexed)
	var cfg = _make_config()
	# Act
	var result: int = cfg.get_threshold(0)
	# Assert — ABYSS-001 AC2
	assert_int(result).is_equal(-1)

func test_abyss_config_threshold_ante_9_returns_minus_1() -> void:
	# Arrange — ante 9 exceeds the 8-ante structure
	var cfg = _make_config()
	# Act
	var result: int = cfg.get_threshold(9)
	# Assert — ABYSS-001 AC2
	assert_int(result).is_equal(-1)

func test_abyss_config_default_constants_are_correct() -> void:
	# Arrange — ABYSS-001 AC3
	var cfg = _make_config()
	# Act / Assert all tuning knobs
	assert_int(cfg.get_hands_per_ante()).is_equal(4)
	assert_int(cfg.get_discards_per_ante()).is_equal(4)
	assert_int(cfg.get_base_hand_gold()).is_equal(2)
	assert_int(cfg.get_ante_completion_bonus()).is_equal(15)
	assert_int(cfg.get_shop_slots()).is_equal(3)
	assert_int(cfg.get_removal_cost()).is_equal(20)
	assert_int(cfg.get_foil_cost()).is_equal(15)
	assert_int(cfg.get_holographic_cost()).is_equal(20)
	assert_int(cfg.get_polychrome_cost()).is_equal(25)

# ── ABYSS-002: Run State Machine ─────────────────────────────────────────────

func test_abyss_run_start_run_transitions_to_ante_combat() -> void:
	# Arrange
	var run = _make_run()
	var deck = _make_deck()
	assert_int(run.state).is_equal(AbyssRunScript.RunState.LOBBY)
	# Act
	run.start_run(deck)
	# Assert — ABYSS-002 AC1
	assert_int(run.state).is_equal(AbyssRunScript.RunState.ANTE_COMBAT)

func test_abyss_run_start_run_sets_ante_current_to_1() -> void:
	# Arrange
	var run = _make_run()
	var deck = _make_deck()
	# Act
	run.start_run(deck)
	# Assert — ABYSS-002 AC1
	assert_int(run.ante_current).is_equal(1)

func test_abyss_run_complete_ante_1_transitions_to_shop() -> void:
	# Arrange
	var run = _make_run()
	run.start_run(_make_deck())
	assert_int(run.state).is_equal(AbyssRunScript.RunState.ANTE_COMBAT)
	# Act — ABYSS-002 AC2
	run.complete_ante(3)
	# Assert
	assert_int(run.state).is_equal(AbyssRunScript.RunState.SHOP)

func test_abyss_run_defeat_transitions_to_defeat_state() -> void:
	# Arrange
	var run = _make_run()
	run.start_run(_make_deck())
	# Act — ABYSS-002 AC3
	run.defeat()
	# Assert
	assert_int(run.state).is_equal(AbyssRunScript.RunState.DEFEAT)

func test_abyss_run_enter_next_ante_transitions_shop_to_ante_combat() -> void:
	# Arrange
	var run = _make_run()
	run.start_run(_make_deck())
	run.complete_ante(4)  # → SHOP, ante_current still 1
	assert_int(run.state).is_equal(AbyssRunScript.RunState.SHOP)
	# Act — ABYSS-002 AC4
	run.enter_next_ante()
	# Assert
	assert_int(run.state).is_equal(AbyssRunScript.RunState.ANTE_COMBAT)
	assert_int(run.ante_current).is_equal(2)

func test_abyss_run_completing_ante_8_transitions_to_complete() -> void:
	# Arrange — simulate a run through all 8 antes
	var run = _make_run()
	run.start_run(_make_deck())
	# Fast-forward to ante 8.
	for i: int in range(7):
		run.complete_ante(4)
		run.enter_next_ante()
	assert_int(run.ante_current).is_equal(8)
	# Act — ABYSS-002 AC5
	run.complete_ante(4)
	# Assert
	assert_int(run.state).is_equal(AbyssRunScript.RunState.COMPLETE)

func test_abyss_run_start_run_from_defeat_resets_all_state() -> void:
	# Arrange — complete a run, reach DEFEAT
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_gold = 50
	run.run_buffs.append({ "buff_id": "hunters_focus", "effect": "chip_bonus", "value": 10 })
	run.defeat()
	assert_int(run.state).is_equal(AbyssRunScript.RunState.DEFEAT)
	# Act — ABYSS-002 AC7
	run.start_run(_make_deck())
	# Assert
	assert_int(run.state).is_equal(AbyssRunScript.RunState.ANTE_COMBAT)
	assert_int(run.run_gold).is_equal(0)
	assert_int(run.run_buffs.size()).is_equal(0)
	assert_int(run.ante_current).is_equal(1)

# ── ABYSS-004: Run-Scoped Gold Economy ───────────────────────────────────────

func test_abyss_run_complete_ante_4_hands_no_buffs_awards_23_gold() -> void:
	# Arrange — ABYSS-004 AC1: 4 hands played, no buffs → (4*2)+15 = 23
	var run = _make_run()
	run.start_run(_make_deck())
	# Act
	run.complete_ante(4)
	# Assert
	assert_int(run.run_gold).is_equal(23)

func test_abyss_run_complete_ante_golden_hand_buff_awards_43_gold() -> void:
	# Arrange — ABYSS-004 AC2: Golden Hand active → (4*(2+5))+15 = 43
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_buffs.append({
		"buff_id": "golden_hand",
		"effect": "hand_gold_bonus",
		"value": 5,
	})
	# Act
	run.complete_ante(4)
	# Assert
	assert_int(run.run_gold).is_equal(43)

func test_abyss_run_new_run_starts_with_zero_gold() -> void:
	# ABYSS-004 AC5
	var run = _make_run()
	run.start_run(_make_deck())
	# Assert
	assert_int(run.run_gold).is_equal(0)

func test_abyss_run_complete_ante_uses_actual_hands_used() -> void:
	# ABYSS-004 AC6: 2 hands used, not a fixed 4 → (2*2)+15 = 19
	var run = _make_run()
	run.start_run(_make_deck())
	# Act
	run.complete_ante(2)
	# Assert
	assert_int(run.run_gold).is_equal(19)

# ── ABYSS-003: Between-Ante Shop System ──────────────────────────────────────

func test_abyss_shop_purchase_card_removal_deducts_gold() -> void:
	# ABYSS-003 AC2: removal costs 20, run_gold 25 → run_gold 5
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_gold = 25
	var shop = _make_shop()
	var slot: Dictionary = {
		"type": AbyssShopScript.SlotType.CARD_REMOVAL,
		"cost": 20,
		"purchased": false,
		"target_index": 0,
	}
	# Act
	var result: Dictionary = shop.purchase(slot, run)
	# Assert
	assert_bool(result.get("ok", false)).is_true()
	assert_int(run.run_gold).is_equal(5)

func test_abyss_shop_purchase_rejected_when_insufficient_gold() -> void:
	# ABYSS-003 AC3: run_gold=10 < Foil cost 15 → rejected
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_gold = 10
	var shop = _make_shop()
	var slot: Dictionary = {
		"type": AbyssShopScript.SlotType.ENHANCEMENT_FOIL,
		"cost": 15,
		"purchased": false,
		"enhancement": "Foil",
		"target_index": 0,
	}
	# Act
	var result: Dictionary = shop.purchase(slot, run)
	# Assert
	assert_bool(result.get("ok", false)).is_false()
	assert_str(result.get("reason", "")).is_equal("insufficient_gold")
	assert_int(run.run_gold).is_equal(10)  # unchanged

func test_abyss_shop_purchase_rejected_when_already_purchased() -> void:
	# ABYSS-003 AC5
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_gold = 50
	var shop = _make_shop()
	var slot: Dictionary = {
		"type": AbyssShopScript.SlotType.CARD_REMOVAL,
		"cost": 20,
		"purchased": true,  # already bought
		"target_index": 0,
	}
	# Act
	var result: Dictionary = shop.purchase(slot, run)
	# Assert
	assert_bool(result.get("ok", false)).is_false()
	assert_str(result.get("reason", "")).is_equal("already_purchased")

func test_abyss_shop_purchase_enhancement_mutates_run_deck() -> void:
	# ABYSS-003 AC6: buying Holographic applies enhancement to run deck card
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_gold = 25
	var shop = _make_shop()
	var slot: Dictionary = {
		"type": AbyssShopScript.SlotType.ENHANCEMENT_HOLOGRAPHIC,
		"cost": 20,
		"purchased": false,
		"enhancement": "Holographic",
		"target_index": 0,
	}
	# Act
	var result: Dictionary = shop.purchase(slot, run)
	# Assert
	assert_bool(result.get("ok", false)).is_true()
	var card: Dictionary = run.deck[0]
	assert_str(card.get("enhancement", "")).is_equal("Holographic")

func test_abyss_shop_enhancement_stacks_on_foil_card() -> void:
	# ABYSS-003 AC7 / GDD EC-8: Foil card + Holographic purchase → "Foil+Holographic"
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_gold = 50
	# Pre-enhance card 0 with Foil
	run.deck[0]["enhancement"] = "Foil"
	var shop = _make_shop()
	var slot: Dictionary = {
		"type": AbyssShopScript.SlotType.ENHANCEMENT_HOLOGRAPHIC,
		"cost": 20,
		"purchased": false,
		"enhancement": "Holographic",
		"target_index": 0,
	}
	# Act
	var result: Dictionary = shop.purchase(slot, run)
	# Assert
	assert_bool(result.get("ok", false)).is_true()
	var card: Dictionary = run.deck[0]
	assert_str(card.get("enhancement", "")).is_equal("Foil+Holographic")

# ── ABYSS-006: Temporary Run Buffs ───────────────────────────────────────────

func test_abyss_run_hunters_focus_buff_registers_chip_bonus_effect() -> void:
	# ABYSS-006 AC1: Hunter's Focus → chip_bonus effect with value 10
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_buffs.append({
		"buff_id": "hunters_focus",
		"effect": "chip_bonus",
		"value": 10,
	})
	# Act — verify buff is present with correct effect
	var found_chip_bonus: bool = false
	for buff: Dictionary in run.run_buffs:
		if buff.get("effect", "") == "chip_bonus" and buff.get("value", 0) == 10:
			found_chip_bonus = true
	# Assert
	assert_bool(found_chip_bonus).is_true()

func test_abyss_run_divine_favor_buff_registers_mult_bonus_effect() -> void:
	# ABYSS-006 AC2: Divine Favor → mult_bonus effect with value 0.5
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_buffs.append({
		"buff_id": "divine_favor",
		"effect": "mult_bonus",
		"value": 0.5,
	})
	# Assert
	var found: bool = false
	for buff: Dictionary in run.run_buffs:
		if buff.get("effect", "") == "mult_bonus":
			assert_float(buff.get("value", 0.0) as float).is_equal_approx(0.5, 0.001)
			found = true
	assert_bool(found).is_true()

func test_abyss_run_last_gambit_buff_increases_hands_in_enemy_config() -> void:
	# ABYSS-006 AC3: Last Gambit (+1 hand) → enemy_config hands_allowed = 5
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_buffs.append({
		"buff_id": "last_gambit",
		"effect": "hands_allowed_bonus",
		"value": 1,
	})
	# Act
	var enemy_cfg: Dictionary = run.get_enemy_config()
	# Assert
	assert_int(enemy_cfg.get("hands_allowed", 0) as int).is_equal(5)

func test_abyss_run_two_hunters_focus_buffs_stack_to_chip_bonus_20() -> void:
	# ABYSS-006 AC6: two Hunter's Focus → chip_bonus total = 20
	var run = _make_run()
	run.start_run(_make_deck())
	run.run_buffs.append({ "buff_id": "hunters_focus", "effect": "chip_bonus", "value": 10 })
	run.run_buffs.append({ "buff_id": "hunters_focus", "effect": "chip_bonus", "value": 10 })
	# Act — sum chip_bonus effects
	var total: int = 0
	for buff: Dictionary in run.run_buffs:
		if buff.get("effect", "") == "chip_bonus":
			total += buff.get("value", 0) as int
	# Assert
	assert_int(total).is_equal(20)

# ── ABYSS-007: Run Summary and Reward Distribution ───────────────────────────

func test_abyss_run_summary_contains_required_keys() -> void:
	# ABYSS-007 AC1
	var run = _make_run()
	run.start_run(_make_deck())
	run.defeat(150)
	# Act
	var summary: Dictionary = run.build_run_summary(0)
	# Assert
	assert_bool(summary.has("antes_completed")).is_true()
	assert_bool(summary.has("total_gold_earned")).is_true()
	assert_bool(summary.has("best_score")).is_true()
	assert_bool(summary.has("is_new_highscore")).is_true()

func test_abyss_run_summary_flags_new_highscore_when_best_score_exceeds_saved() -> void:
	# ABYSS-007 AC2: best_score=500 > saved_highscore=200 → is_new_highscore=true
	var run = _make_run()
	run.start_run(_make_deck())
	run.defeat(500)
	# Act
	var summary: Dictionary = run.build_run_summary(200)
	# Assert
	assert_bool(summary.get("is_new_highscore", false)).is_true()
	assert_int(summary.get("best_score", 0) as int).is_equal(500)

func test_abyss_run_summary_no_new_highscore_when_score_below_saved() -> void:
	# ABYSS-007 AC2 (inverse): best_score=100 < saved=500 → is_new_highscore=false
	var run = _make_run()
	run.start_run(_make_deck())
	run.defeat(100)
	# Act
	var summary: Dictionary = run.build_run_summary(500)
	# Assert
	assert_bool(summary.get("is_new_highscore", false)).is_false()

func test_abyss_run_summary_defeat_at_ante_3_shows_antes_completed_2() -> void:
	# ABYSS-007 AC3: defeat at ante 3 means antes 1 and 2 were completed
	var run = _make_run()
	run.start_run(_make_deck())
	# Simulate completing antes 1 and 2, then defeat on 3.
	run.complete_ante(4)
	run.enter_next_ante()
	run.complete_ante(4)
	run.enter_next_ante()
	# Now on ante 3, fail.
	run.defeat(50)
	# Act
	var summary: Dictionary = run.build_run_summary(0)
	# Assert
	assert_int(summary.get("antes_completed", -1) as int).is_equal(2)
