class_name CombatIntegrationTest
extends GdUnitTestSuite

## Integration tests for STORY-COMBAT-012:
## Full Combat Integration — SceneManager, EventBus, and GameStore Rewards
##
## Covers:
##   AC1 — CombatManager does NOT call SceneTree.change_scene_to_file() or
##          reference raw .tscn paths
##   AC2 — combat_completed is emitted on EventBus (not as a local Node signal)
##   AC3 — combat_completed with victory=true: mock Story Flow listener advances
##   AC4 — DEFEAT + Retry restarts CombatManager with a fresh deck (no stale state)
##   AC5 — Combat scene freed: no in-progress state in GameStore
##   AC6 — VICTORY payload contains victory:bool, score:int, hands_used:int
##   AC7 — Scene transition uses SceneId enum value (not a raw string path)
##
## CombatManager is tested in isolation here — no scene tree is required.
## EventBus and GameStore are instantiated from their scripts to avoid autoload
## coupling (dependency injection pattern used by CombatManager.setup()).
##
## See: docs/architecture/adr-0007-poker-combat.md
## Stories: STORY-COMBAT-012

# ── Script references ─────────────────────────────────────────────────────────

const CombatManagerScript = preload("res://src/systems/combat/combat_manager.gd")
const EventBusScript      = preload("res://src/autoloads/event_bus.gd")
const GameStoreScript     = preload("res://src/autoloads/game_store.gd")
const SceneManagerScript  = preload("res://src/autoloads/scene_manager.gd")

# ── Helpers ───────────────────────────────────────────────────────────────────

## Returns a minimal valid enemy config.
func _enemy(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"score_threshold":  40,
		"hands_allowed":    4,
		"discards_allowed": 4,
		"element":          "",
		"name_key":         "Test Enemy",
	}
	for key: String in overrides:
		base[key] = overrides[key]
	return base


## Returns a minimal captain context with no optional fields.
func _captain_ctx(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"captain_id":            "",
		"captain_chip_bonus":    0,
		"captain_mult_modifier": 1.0,
		"social_buff_chips":     0,
		"social_buff_mult":      0.0,
		"romance_stages":        {},
	}
	for key: String in overrides:
		base[key] = overrides[key]
	return base


## Creates a fresh CombatManager wired to a local EventBus and GameStore.
## Returns [cm, event_bus, game_store] as an Array for easy unpacking.
func _create_wired_combat(
		enemy_overrides: Dictionary = {},
		captain_overrides: Dictionary = {}) -> Array:
	var event_bus = EventBusScript.new()
	var game_store = GameStoreScript.new()
	var cm = CombatManagerScript.new()

	cm.setup(
		_enemy(enemy_overrides),
		_captain_ctx(captain_overrides),
		game_store,
		event_bus
	)
	return [cm, event_bus, game_store]


# ── AC1 — CombatManager does not reference raw .tscn paths ───────────────────

func test_combat_integration_combat_manager_source_contains_no_tscn_paths() -> void:
	# Arrange — read the CombatManager source as a string
	var source_path: String = "res://src/systems/combat/combat_manager.gd"
	var file: FileAccess = FileAccess.open(source_path, FileAccess.READ)

	# Act
	assert_object(file).is_not_null()
	var source: String = file.get_as_text()
	file.close()

	# Assert — no raw .tscn references or change_scene_to_file calls
	assert_bool(source.contains(".tscn")).is_false()
	assert_bool(source.contains("change_scene_to_file")).is_false()


func test_combat_integration_combat_scene_source_uses_scene_manager_not_raw_path() -> void:
	# Arrange — read the combat scene controller source
	var source_path: String = "res://src/scenes/combat/combat.gd"
	var file: FileAccess = FileAccess.open(source_path, FileAccess.READ)

	# Act
	assert_object(file).is_not_null()
	var source: String = file.get_as_text()
	file.close()

	# Assert — scene transitions use SceneManager.change_scene(), not raw paths
	assert_bool(source.contains("change_scene_to_file")).is_false()
	# SceneManager.change_scene should appear (navigation present)
	assert_bool(source.contains("SceneManager.change_scene")).is_true()


# ── AC2 — combat_completed emitted on EventBus, not as a local Node signal ───

func test_combat_integration_victory_emits_combat_completed_on_event_bus() -> void:
	# Arrange — set a very low threshold so a single card play triggers VICTORY
	var parts: Array = _create_wired_combat({"score_threshold": 1})
	var cm = parts[0]
	var event_bus = parts[1]

	var received_result: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received_result = result
	)

	# Force a known hand
	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — EventBus received the signal (not a local signal)
	assert_bool(received_result.has("victory")).is_true()
	assert_bool(received_result.get("victory", false) as bool).is_true()


func test_combat_integration_defeat_emits_combat_completed_on_event_bus() -> void:
	# Arrange — very high threshold, only 1 hand allowed → forces DEFEAT
	var parts: Array = _create_wired_combat(
		{"score_threshold": 999999, "hands_allowed": 1}
	)
	var cm = parts[0]
	var event_bus = parts[1]

	var received_result: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received_result = result
	)

	# Act — play 1 hand (all hands exhausted → DEFEAT)
	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Assert
	assert_bool(received_result.has("victory")).is_true()
	assert_bool(received_result.get("victory", true) as bool).is_false()


# ── AC3 — mock Story Flow listener receives combat_completed and can advance ──

func test_combat_integration_story_flow_mock_receives_victory_signal() -> void:
	# Arrange — lightweight Story Flow mock that records if it was notified
	var mock_story_flow_notified: bool = false

	var parts: Array = _create_wired_combat({"score_threshold": 1})
	var cm = parts[0]
	var event_bus = parts[1]

	# Simulate Story Flow listening on EventBus
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		if (result.get("victory", false) as bool):
			mock_story_flow_notified = true
	)

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — mock Story Flow was notified and would advance narrative
	assert_bool(mock_story_flow_notified).is_true()


func test_combat_integration_story_flow_mock_not_triggered_on_defeat() -> void:
	# Arrange
	var mock_story_flow_notified: bool = false

	var parts: Array = _create_wired_combat(
		{"score_threshold": 999999, "hands_allowed": 1}
	)
	var cm = parts[0]
	var event_bus = parts[1]

	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		if (result.get("victory", false) as bool):
			mock_story_flow_notified = true
	)

	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	cm.play_hand([0] as Array[int])

	# Assert — defeat does not trigger Story Flow advancement
	assert_bool(mock_story_flow_notified).is_false()


# ── AC4 — Retry restarts with a fresh deck (no stale state) ──────────────────

func test_combat_integration_retry_produces_fresh_deck_of_52_cards() -> void:
	# Arrange — run one combat to DEFEAT to get stale state
	var parts: Array = _create_wired_combat(
		{"score_threshold": 999999, "hands_allowed": 1}
	)
	var cm_first = parts[0]
	var game_store = parts[2]

	cm_first.hand.clear()
	cm_first.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})
	cm_first.play_hand([0] as Array[int])

	# Stale state: deck is now nearly empty, hands exhausted
	var stale_deck_size: int = cm_first.deck.size()
	var stale_hands_remaining: int = cm_first.hands_remaining

	# Act — create a new CombatManager to simulate Retry
	var event_bus_new = EventBusScript.new()
	var cm_retry = CombatManagerScript.new()
	cm_retry.setup(
		_enemy({"score_threshold": 999999, "hands_allowed": 4}),
		_captain_ctx(),
		game_store,
		event_bus_new
	)

	# Assert — fresh state, not stale
	# A fresh CombatManager draws 5 cards immediately; deck has 52 - 5 = 47 left
	assert_int(cm_retry.deck.size()).is_equal(47)
	assert_int(cm_retry.hands_remaining).is_equal(4)
	assert_int(cm_retry.current_score).is_equal(0)
	# Stale manager had different values
	assert_bool(stale_deck_size != 47 or stale_hands_remaining != 4).is_true()


func test_combat_integration_retry_current_score_resets_to_zero() -> void:
	# Arrange — run one combat until score accumulates
	var parts: Array = _create_wired_combat(
		{"score_threshold": 999999, "hands_allowed": 2}
	)
	var cm_first = parts[0]
	var game_store = parts[2]

	# Play two hands to build up some score
	cm_first.hand.clear()
	cm_first.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm_first.play_hand([0] as Array[int])

	assert_bool(cm_first.current_score > 0).is_true()

	# Act — retry with a new CombatManager
	var cm_retry = CombatManagerScript.new()
	cm_retry.setup(_enemy(), _captain_ctx(), game_store, EventBusScript.new())

	# Assert
	assert_int(cm_retry.current_score).is_equal(0)


# ── AC5 — GameStore has no in-progress combat state after scene freed ─────────

func test_combat_integration_game_store_has_no_combat_state_after_manager_freed() -> void:
	# Arrange — run a full combat and free the manager
	var parts: Array = _create_wired_combat({"score_threshold": 1})
	var cm = parts[0]
	var game_store = parts[2]

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Act — free the combat manager (simulates scene being removed)
	cm = null  # Unreference — RefCounted is freed when ref count reaches 0

	# Assert — GameStore has no combat progress keys.
	# CombatManager never writes current_score, deck, or hand to GameStore
	# (only the social buff lifecycle touches GameStore).
	# The only combat-related key in GameStore is the buff — verify it is untouched.
	var buff: Dictionary = game_store.get_combat_buff()
	# No buff was set for this test — it should remain empty.
	assert_bool(buff.is_empty()).is_true()


func test_combat_integration_game_store_has_no_deck_state_after_combat() -> void:
	# Arrange — verify GameStore has no deck/hand/score fields at all
	var game_store = GameStoreScript.new()

	# Act — check that the GameStore API has no combat progress getters
	# (CombatManager is the sole owner of deck, hand, current_score)
	assert_bool(game_store.has_method("get_deck")).is_false()
	assert_bool(game_store.has_method("get_hand")).is_false()
	assert_bool(game_store.has_method("get_current_score")).is_false()
	assert_bool(game_store.has_method("get_hands_remaining")).is_false()


# ── AC6 — VICTORY payload schema ─────────────────────────────────────────────

func test_combat_integration_victory_payload_contains_victory_key() -> void:
	# Arrange
	var parts: Array = _create_wired_combat({"score_threshold": 1})
	var cm = parts[0]
	var event_bus = parts[1]

	var received: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received = result
	)

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})

	# Act
	cm.play_hand([0] as Array[int])

	# Assert
	assert_bool(received.has("victory")).is_true()
	assert_bool(received.get("victory") is bool).is_true()


func test_combat_integration_victory_payload_contains_score_key() -> void:
	# Arrange
	var parts: Array = _create_wired_combat({"score_threshold": 1})
	var cm = parts[0]
	var event_bus = parts[1]

	var received: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received = result
	)

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Assert
	assert_bool(received.has("score")).is_true()
	assert_bool(received.get("score") is int).is_true()
	assert_int(received.get("score", -1) as int).is_greater(0)


func test_combat_integration_victory_payload_contains_hands_used_key() -> void:
	# Arrange
	var parts: Array = _create_wired_combat({"score_threshold": 1})
	var cm = parts[0]
	var event_bus = parts[1]

	var received: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received = result
	)

	cm.hand.clear()
	cm.hand.append({"value": 7, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Assert
	assert_bool(received.has("hands_used")).is_true()
	assert_bool(received.get("hands_used") is int).is_true()
	assert_int(received.get("hands_used", -1) as int).is_equal(1)


func test_combat_integration_defeat_payload_schema_matches_spec() -> void:
	# Arrange — single-hand combat, high threshold → DEFEAT
	var parts: Array = _create_wired_combat(
		{"score_threshold": 999999, "hands_allowed": 1}
	)
	var cm = parts[0]
	var event_bus = parts[1]

	var received: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received = result
	)

	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Assert — all three required keys present on defeat too
	assert_bool(received.has("victory")).is_true()
	assert_bool(received.has("score")).is_true()
	assert_bool(received.has("hands_used")).is_true()
	assert_bool(received.get("victory", true) as bool).is_false()


func test_combat_integration_victory_on_hand_2_reports_hands_used_equals_2() -> void:
	# Arrange — need 2 hands to reach threshold
	# hand 1: 1 card, score < threshold; hand 2: 1 card, total >= threshold
	# Use score_threshold that 1 low card won't reach but 2 will.
	# High Card single 2: chips=5+2=7, mult=1.0, score=7
	# High Card single A (14): chips=5+11=16, mult=1.0, score=16
	# After hand 1: total=7. After hand 2: total=23. Use threshold=20.
	var parts: Array = _create_wired_combat(
		{"score_threshold": 20, "hands_allowed": 4}
	)
	var cm = parts[0]
	var event_bus = parts[1]

	var received: Dictionary = {}
	event_bus.combat_completed.connect(func(result: Dictionary) -> void:
		received = result
	)

	# Hand 1 — score 7, total < 20 → continues
	cm.hand.clear()
	cm.hand.append({"value": 2, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Should still be in play
	assert_bool(received.is_empty()).is_true()

	# Hand 2 — score 16, total = 23 → VICTORY
	cm.hand.clear()
	cm.hand.append({"value": 14, "suit": 0, "element": "Fire", "enhancement": ""})
	cm.play_hand([0] as Array[int])

	# Assert — victory on hand 2, hands_used = 2
	assert_bool(received.get("victory", false) as bool).is_true()
	assert_int(received.get("hands_used", -1) as int).is_equal(2)


# ── AC7 — Scene transition uses SceneId enum (verified statically) ────────────

func test_combat_integration_combat_scene_uses_scene_id_hub_for_navigation() -> void:
	# Arrange — read the combat scene controller source
	var source_path: String = "res://src/scenes/combat/combat.gd"
	var file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	assert_object(file).is_not_null()
	var source: String = file.get_as_text()
	file.close()

	# Act + Assert — navigation calls reference SceneId enum values, not raw strings
	# The script should contain "SceneId.HUB" for victory/retreat transitions
	assert_bool(source.contains("SceneId.HUB")).is_true()
	# Must NOT contain raw scene paths in the navigation calls
	assert_bool(source.contains("hub.tscn")).is_false()


func test_combat_integration_scene_manager_scene_id_hub_is_registered() -> void:
	# Arrange — verify SceneManager knows about SceneId.HUB at the value level
	# SceneId.HUB is defined in scene_manager.gd as enum member HUB
	# We can read the source to confirm the enum entry exists
	var source_path: String = "res://src/autoloads/scene_manager.gd"
	var file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	assert_object(file).is_not_null()
	var source: String = file.get_as_text()
	file.close()

	# Assert — enum entry and path registration both present
	assert_bool(source.contains("HUB,")).is_true()
	assert_bool(source.contains("hub.tscn")).is_true()
