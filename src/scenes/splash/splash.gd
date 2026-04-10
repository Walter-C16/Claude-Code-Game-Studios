extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var bg: TextureRect = %Background

func _ready() -> void:
	# Check for existing save
	continue_btn.visible = SaveManager.has_save()

	# Animate entrance
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

	# Title glow pulse
	_start_title_pulse()

func _start_title_pulse() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "modulate:a", 0.7, 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN_OUT)

func _on_new_game_pressed() -> void:
	new_game_btn.disabled = true
	continue_btn.disabled = true
	GameStore._initialize_defaults()
	SceneManager.change_scene(SceneManager.SceneId.HUB)

func _on_continue_pressed() -> void:
	new_game_btn.disabled = true
	continue_btn.disabled = true
	SaveManager.load_game()
	SceneManager.change_scene(SceneManager.SceneId.HUB)
