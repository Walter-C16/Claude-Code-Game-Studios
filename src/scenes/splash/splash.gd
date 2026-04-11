extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var version_label: Label = %VersionLabel
@onready var bg: TextureRect = %Background

func _ready() -> void:
	# Show continue only when a save actually exists.
	# Guard against a missing or uninitialised SaveManager on fresh installs.
	continue_btn.visible = _has_existing_save()

	# Animate entrance fade-in.
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

	_start_title_pulse()

## Returns true when a playable save file exists.
## Fails silently instead of crashing when SaveManager is not ready.
func _has_existing_save() -> bool:
	if not is_instance_valid(SaveManager):
		return false
	if not SaveManager.has_method("has_save"):
		return false
	return SaveManager.has_save()

func _start_title_pulse() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(title_label, "modulate:a", 0.7, 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN_OUT)

func _on_new_game_pressed() -> void:
	new_game_btn.disabled = true
	continue_btn.disabled = true
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
	SaveManager.load_game()
	SceneManager.change_scene(SceneManager.SceneId.HUB)
