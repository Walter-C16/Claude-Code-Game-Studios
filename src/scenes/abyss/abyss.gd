extends Control

## Abyss — Endless/roguelike dungeon mode screen.
##
## Entry point for the infinite Abyss challenge mode with escalating difficulty.
## Navigates back to HUB on dismiss.

@onready var title_label: Label = %TitleLabel
@onready var depth_label: Label = %DepthLabel
@onready var enter_btn: Button = %EnterBtn
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	enter_btn.pressed.connect(_on_enter_pressed)


## Begin descent into the Abyss (launches combat).
func _on_enter_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.COMBAT)


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
