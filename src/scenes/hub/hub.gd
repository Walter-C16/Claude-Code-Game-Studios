extends Control

## Hub screen — companion portrait, currency, bottom tabs.
##
## Reads companion display data from CompanionRegistry (autoload #7).
## Navigates to combat via SceneManager with an arrival context that
## combat.gd reads on its _ready() call via SceneManager.get_arrival_context().

# ── Node References ────────────────────────────────────────────────────────────

@onready var portrait: TextureRect = %Portrait
@onready var companion_name: Label = %CompanionName
@onready var companion_role: Label = %CompanionRole
@onready var gold_label: Label = %GoldLabel

# ── Private State ──────────────────────────────────────────────────────────────

var _breathe_tween: Tween

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	_update_companion_display()
	_update_currency()
	_start_breathing_animation()

	GameStore.state_changed.connect(_update_currency)

# ── Display ────────────────────────────────────────────────────────────────────

func _update_companion_display() -> void:
	var id: String = GameStore.get_last_captain_id()
	var profile: Dictionary = CompanionRegistry.get_profile(id)

	companion_name.text = profile.get("display_name", id.capitalize())
	companion_role.text = profile.get("role", "")

	var path: String = CompanionRegistry.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(path):
		portrait.texture = load(path)

func _update_currency() -> void:
	gold_label.text = str(GameStore.get_gold())

func _start_breathing_animation() -> void:
	_breathe_tween = create_tween().set_loops()
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.02, 1.02), 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.0, 1.0), 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ── Tab Buttons ────────────────────────────────────────────────────────────────

func _on_story_pressed() -> void:
	# TODO: navigate to chapter map
	pass

func _on_arena_pressed() -> void:
	# Pass enemy config to combat.gd via arrival context.
	# combat.gd reads SceneManager.get_arrival_context() in _ready() and builds
	# the enemy + deck from EnemyRegistry using the id provided here.
	# TODO: replace "arena_challenger" with a real EnemyRegistry id when the
	#       enemy data file is populated (Balance values not yet ported).
	var context: Dictionary = {
		"enemy_id": "arena_challenger",
		"captain_id": GameStore.get_last_captain_id(),
	}
	SceneManager.change_scene(
		SceneManager.SceneId.COMBAT,
		SceneManager.TransitionType.FADE,
		context
	)

func _on_settings_pressed() -> void:
	# TODO: navigate to settings
	pass
