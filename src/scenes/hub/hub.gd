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
var _name_shimmer_tween: Tween

## Last known gold value — used to drive the count-up animation.
var _displayed_gold: int = 0

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	_update_companion_display()
	_update_currency()
	_start_breathing_animation()

	GameStore.state_changed.connect(_on_state_changed)

	# Entrance animation: stagger all direct children from their edges.
	await get_tree().process_frame
	_animate_entrance()


# ── Display ────────────────────────────────────────────────────────────────────

func _update_companion_display() -> void:
	var id: String = GameStore.get_last_captain_id()
	var profile: Dictionary = CompanionRegistry.get_profile(id)

	companion_name.text = profile.get("display_name", id.capitalize())
	companion_role.text = profile.get("role", "")

	var path: String = CompanionRegistry.get_portrait_path(id, "neutral")
	if ResourceLoader.exists(path):
		portrait.texture = load(path)


## Syncs the gold label text directly (no animation — used on first load).
func _update_currency() -> void:
	_displayed_gold = GameStore.get_gold()
	gold_label.text = str(_displayed_gold)


## Animates gold counter from old value to new value with count-up + pulse.
func _animate_gold_change(old_val: int, new_val: int) -> void:
	Fx.count_to(gold_label, old_val, new_val, 0.45)
	await get_tree().create_timer(0.45).timeout
	Fx.pulse(gold_label, 1.2, 0.35)


func _start_breathing_animation() -> void:
	_breathe_tween = create_tween().set_loops()
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.02, 1.02), 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(portrait, "scale", Vector2(1.0, 1.0), 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Subtle gold shimmer loop on the companion name label.
func _start_name_shimmer() -> void:
	_name_shimmer_tween = Fx.gold_shimmer(companion_name, 3.0)


## Stagger all immediate Control children of the root into view from their edges.
func _animate_entrance() -> void:
	# Slide portrait + name panel from left, gold from top, tabs from bottom.
	# We use the generic stagger_children on the root — it handles layout children.
	Fx.stagger_children(self, 0.05, 30.0)
	await get_tree().create_timer(0.4).timeout
	_start_name_shimmer()


# ── Signal Callbacks ────────────────────────────────────────────────────────────

func _on_state_changed() -> void:
	var new_gold: int = GameStore.get_gold()
	if new_gold != _displayed_gold:
		var old: int = _displayed_gold
		_displayed_gold = new_gold
		_animate_gold_change(old, new_gold)


# ── Tab Buttons ────────────────────────────────────────────────────────────────

func _on_story_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.CHAPTER_MAP)


func _on_camp_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.COMPANION_ROOM)


func _on_deck_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.DECK)


func _on_explore_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.EXPLORATION)


func _on_abyss_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.ABYSS)


func _on_equipment_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.EQUIPMENT)


func _on_gallery_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.GALLERY)


func _on_achievements_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.ACHIEVEMENTS)


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
	SceneManager.open_settings_overlay()
