extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var version_label: Label = %VersionLabel
@onready var bg: TextureRect = %Background

## Looping shimmer tween kept so nothing garbage-collects it mid-loop.
var _shimmer_tween: Tween

func _ready() -> void:
	# Show continue only when a save actually exists.
	continue_btn.visible = _has_existing_save()

	# Hide everything before entrance animation begins.
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	new_game_btn.modulate.a = 0.0
	continue_btn.modulate.a = 0.0
	version_label.modulate.a = 0.0

	# Kill the looping shimmer tween on exit so it doesn't animate a freed label.
	tree_exiting.connect(_kill_shimmer)

	# Title slides down from above with a spring overshoot.
	# await one frame so layout positions are committed before we read them.
	AudioManager.play_bgm("res://assets/audio/bgm/main_menu.ogg")
	await get_tree().process_frame
	_animate_entrance()


func _kill_shimmer() -> void:
	if _shimmer_tween != null and _shimmer_tween.is_valid():
		_shimmer_tween.kill()


## Returns true when a playable save file exists.
## Fails silently instead of crashing when SaveManager is not ready.
func _has_existing_save() -> bool:
	if not is_instance_valid(SaveManager):
		return false
	if not SaveManager.has_method("has_save"):
		return false
	return SaveManager.has_save()


## Full dramatic entrance sequence: title → subtitle → buttons (staggered).
func _animate_entrance() -> void:
	# Title slides in from above (-120 px) with spring overshoot.
	title_label.modulate.a = 1.0
	Fx.slide_in(title_label, Vector2(0.0, -120.0), 0.55)

	# Subtitle fades in 0.5 s after title.
	var subtitle_tween: Tween = create_tween()
	subtitle_tween.tween_interval(0.5)
	subtitle_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT)

	# Buttons slide up from bottom with 100 ms stagger.
	# Build a flat list of which buttons to animate so we can stagger them.
	var btns: Array[Control] = []
	btns.append(new_game_btn)
	if continue_btn.visible:
		btns.append(continue_btn)

	var btn_delay: float = 0.7  # start after title has landed
	for btn: Control in btns:
		var target_y: float = btn.position.y
		btn.position.y += 40.0
		var t: Tween = create_tween()
		t.set_parallel(true)
		t.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(btn_delay)
		t.tween_property(btn, "position:y", target_y, 0.35) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
			.set_delay(btn_delay)
		btn_delay += 0.1

	# Version label fades in last, subtly.
	var ver_tween: Tween = create_tween()
	ver_tween.tween_interval(btn_delay)
	ver_tween.tween_property(version_label, "modulate:a", 0.6, 0.4)

	# Gold shimmer on title starts once the title is visible.
	await get_tree().create_timer(0.3).timeout
	_shimmer_tween = Fx.gold_shimmer(title_label, 2.5)


func _on_new_game_pressed() -> void:
	new_game_btn.disabled = true
	continue_btn.disabled = true
	Fx.pop_scale(new_game_btn)
	GameStore._initialize_defaults()
	# Start with prologue dialogue, then tutorial combat follows via StoryFlow
	SceneManager.change_scene(
		SceneManager.SceneId.DIALOGUE,
		SceneManager.TransitionType.FADE,
		{"chapter_id": "ch01", "sequence_id": "prologue"}
	)


func _on_continue_pressed() -> void:
	new_game_btn.disabled = true
	continue_btn.disabled = true
	Fx.pop_scale(continue_btn)
	SaveManager.load_game()
	SceneManager.change_scene(SceneManager.SceneId.HUB)
