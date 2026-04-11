extends Control

## CompanionRoom — Companion detail and interaction screen.
##
## Shows the active companion's portrait, affection level, and available
## interaction options. Navigates back to HUB on dismiss.

@onready var companion_name_label: Label = %CompanionNameLabel
@onready var affection_label: Label = %AffectionLabel
@onready var portrait: TextureRect = %Portrait
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	pass


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
