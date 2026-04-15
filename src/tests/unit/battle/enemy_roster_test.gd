class_name EnemyRosterTest
extends GdUnitTestSuite

## Integration test for the enemy roster spread across three data files.
##
## Every enemy that has combat stats in `character_battle_stats.json` must also:
##   • appear in `enemies.json` with a localized `name_key`
##   • have a moveset in `battle_movesets.json` with at least `normal` + `special`
##   • use only registered effect strings in its moves
##   • declare `has_ultimate: true` iff its moveset actually has an ultimate
##   • use a known `ai_profile` value
##   • carry `turn_timer_seconds >= 0`
##
## This test catches drift when a designer adds an enemy to one file but
## forgets the others (a realistic failure mode — we saw amazon_challenger
## ship stats with no moveset before this test existed).

const STATS_PATH: String = "res://assets/data/character_battle_stats.json"
const MOVESETS_PATH: String = "res://assets/data/battle_movesets.json"
const ENEMIES_PATH: String = "res://assets/data/enemies.json"

const VALID_AI_PROFILES: Array[String] = [
	"aggressive", "tactical", "berserker", "defensive"
]

## Move effects recognized by BattleManager._apply_effect. Unknown effects
## push_warning at runtime — this test keeps the JSON in sync with the code.
const VALID_EFFECTS: Array[String] = [
	"",
	"pierce_def",
	"ignore_defense",
	"repeat_on_crit",
	"apply_hunter_mark_2_turns",
	"guaranteed_crit_3_turns",
	"party_shield_30_percent",
	"dodge_next_attack",
	"dispel_enemy_buffs",
	"corrupted_bloom",
]


# ── Helpers ───────────────────────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _get_enemy_stats() -> Dictionary:
	var data: Dictionary = _load_json(STATS_PATH)
	return data.get("enemies", {}) as Dictionary


func _get_movesets() -> Dictionary:
	return _load_json(MOVESETS_PATH)


func _get_enemy_registry_ids() -> Array:
	var data: Dictionary = _load_json(ENEMIES_PATH)
	var list: Array = data.get("enemies", []) as Array
	var ids: Array = []
	for entry: Variant in list:
		var e: Dictionary = entry as Dictionary
		ids.append(e.get("id", ""))
	return ids


# ── Cross-file presence ──────────────────────────────────────────────────────

func test_every_combat_enemy_is_registered_in_enemies_json() -> void:
	# Arrange
	var stats: Dictionary = _get_enemy_stats()
	var registry_ids: Array = _get_enemy_registry_ids()

	# Act + Assert — every id in stats must also live in the registry
	for enemy_id: Variant in stats.keys():
		var id: String = str(enemy_id)
		assert_bool(registry_ids.has(id)) \
			.override_failure_message(
				"Enemy '%s' has battle stats but is missing from enemies.json" % id
			) \
			.is_true()


func test_every_combat_enemy_has_a_moveset() -> void:
	# Arrange
	var stats: Dictionary = _get_enemy_stats()
	var movesets: Dictionary = _get_movesets()

	# Act + Assert — every id in stats must have a moveset block
	for enemy_id: Variant in stats.keys():
		var id: String = str(enemy_id)
		# sardis_card_master is poker-only and doesn't have an action moveset.
		if id == "sardis_card_master":
			continue
		assert_bool(movesets.has(id)) \
			.override_failure_message(
				"Enemy '%s' has battle stats but no entry in battle_movesets.json" % id
			) \
			.is_true()


func test_every_moveset_contains_normal_and_special() -> void:
	# Arrange
	var movesets: Dictionary = _get_movesets()

	# Act + Assert
	for enemy_id: Variant in movesets.keys():
		var id: String = str(enemy_id)
		var moves: Dictionary = movesets[id] as Dictionary
		assert_bool(moves.has("normal")) \
			.override_failure_message("Enemy '%s' is missing a normal move" % id) \
			.is_true()
		assert_bool(moves.has("special")) \
			.override_failure_message("Enemy '%s' is missing a special move" % id) \
			.is_true()


# ── Data integrity ───────────────────────────────────────────────────────────

func test_every_enemy_uses_valid_ai_profile() -> void:
	# Arrange
	var stats: Dictionary = _get_enemy_stats()

	# Act + Assert
	for enemy_id: Variant in stats.keys():
		var id: String = str(enemy_id)
		var row: Dictionary = stats[id] as Dictionary
		var profile: String = row.get("ai_profile", "aggressive") as String
		assert_bool(VALID_AI_PROFILES.has(profile)) \
			.override_failure_message(
				"Enemy '%s' uses unknown ai_profile '%s'" % [id, profile]
			) \
			.is_true()


func test_every_enemy_turn_timer_is_non_negative() -> void:
	# Arrange
	var stats: Dictionary = _get_enemy_stats()

	# Act + Assert
	for enemy_id: Variant in stats.keys():
		var id: String = str(enemy_id)
		var row: Dictionary = stats[id] as Dictionary
		var timer: int = int(row.get("turn_timer_seconds", 0))
		assert_int(timer) \
			.override_failure_message(
				"Enemy '%s' has negative turn_timer_seconds %d" % [id, timer]
			) \
			.is_greater_equal(0)


func test_every_move_uses_known_effect_string() -> void:
	# Arrange
	var movesets: Dictionary = _get_movesets()

	# Act + Assert
	for enemy_id: Variant in movesets.keys():
		var id: String = str(enemy_id)
		var moves: Dictionary = movesets[id] as Dictionary
		for move_type: Variant in moves.keys():
			var move: Dictionary = moves[move_type] as Dictionary
			var effect: String = move.get("effect", "") as String
			assert_bool(VALID_EFFECTS.has(effect)) \
				.override_failure_message(
					"Enemy '%s' move '%s' uses unknown effect '%s'" \
						% [id, move_type, effect]
				) \
				.is_true()


func test_has_ultimate_flag_matches_moveset_ultimate_presence() -> void:
	# Arrange
	var stats: Dictionary = _get_enemy_stats()
	var movesets: Dictionary = _get_movesets()

	# Act + Assert
	for enemy_id: Variant in stats.keys():
		var id: String = str(enemy_id)
		if id == "sardis_card_master":
			continue
		if not movesets.has(id):
			continue
		var row: Dictionary = stats[id] as Dictionary
		var moves: Dictionary = movesets[id] as Dictionary
		var declared: bool = row.get("has_ultimate", false) as bool
		var actual: bool = moves.has("ultimate")
		assert_bool(declared == actual) \
			.override_failure_message(
				"Enemy '%s' has_ultimate=%s but moveset ultimate=%s" \
					% [id, declared, actual]
			) \
			.is_true()


# ── Localization presence ────────────────────────────────────────────────────

func test_every_enemy_name_key_resolves_to_a_non_empty_string() -> void:
	# Arrange
	var data: Dictionary = _load_json(ENEMIES_PATH)
	var entries: Array = data.get("enemies", []) as Array

	# Act + Assert — Localization.get_text returns the key itself on a miss,
	# so we compare before vs after. A successful lookup yields a different
	# string (the English label).
	for entry: Variant in entries:
		var e: Dictionary = entry as Dictionary
		var id: String = e.get("id", "") as String
		var key: String = e.get("name_key", "") as String
		assert_bool(not key.is_empty()) \
			.override_failure_message(
				"Enemy '%s' has empty name_key" % id
			) \
			.is_true()
		var localized: String = Localization.get_text(key)
		assert_bool(localized != key and not localized.is_empty()) \
			.override_failure_message(
				"Enemy '%s' name_key '%s' is not localized (got '%s')" \
					% [id, key, localized]
			) \
			.is_true()


func test_every_move_name_key_resolves_to_a_non_empty_string() -> void:
	# Arrange
	var movesets: Dictionary = _get_movesets()

	# Act + Assert
	for enemy_id: Variant in movesets.keys():
		var id: String = str(enemy_id)
		var moves: Dictionary = movesets[id] as Dictionary
		for move_type: Variant in moves.keys():
			var move: Dictionary = moves[move_type] as Dictionary
			var key: String = move.get("name_key", "") as String
			if key.is_empty():
				continue
			var localized: String = Localization.get_text(key)
			assert_bool(localized != key and not localized.is_empty()) \
				.override_failure_message(
					"Enemy '%s' move '%s' name_key '%s' is not localized" \
						% [id, move_type, key]
				) \
				.is_true()
