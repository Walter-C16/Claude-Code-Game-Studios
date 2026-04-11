extends Control

## Date — Companion date activity screen.
##
## Hosts a date mini-game or dialogue segment with the active companion.
## Navigates back to HUB on completion.

@onready var title_label: Label = %TitleLabel
@onready var activity_area: Control = %ActivityArea
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	pass


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
