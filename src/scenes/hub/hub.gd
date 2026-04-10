extends Control

## Hub screen — companion portrait, currency, bottom tabs.

@onready var portrait: TextureRect = %Portrait
@onready var companion_name: Label = %CompanionName
@onready var companion_role: Label = %CompanionRole
@onready var gold_label: Label = %GoldLabel

var _breathe_tween: Tween

func _ready() -> void:
	_update_companion_display()
	_update_currency()
	_start_breathing_animation()

	GameStore.state_changed.connect(_update_currency)

func _update_companion_display() -> void:
	var id: String = GameStore.get_last_captain_id()
	var comp: Dictionary = Companions.get_companion(id)
	companion_name.text = comp.get("display_name", id.capitalize())
	companion_role.text = comp.get("role", "")

	var path := Companions.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(path):
		portrait.texture = load(path)

func _update_currency() -> void:
	gold_label.text = str(GameStore.get_gold())

func _start_breathing_animation() -> void:
	_breathe_tween = create_tween().set_loops()
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.02, 1.02), 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.0, 1.0), 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------------------
# Tab buttons
# ---------------------------------------------------------------------------

func _on_story_pressed() -> void:
	# TODO: navigate to chapter map
	pass

func _on_arena_pressed() -> void:
	var enemy := CombatSystem.create_enemy("Arena Challenger", 200)
	var deck := CombatSystem.create_standard_deck()
	CombatStore.init_combat(enemy, GameStore.get_last_captain_id(), deck)
	SceneManager.change_scene(SceneManager.SceneId.COMBAT)

func _on_settings_pressed() -> void:
	# TODO: navigate to settings
	pass
