extends Control

## Exploration — Overworld map / zone exploration screen.
##
## Displays available zones and encounters the player can enter.
## Navigates back to HUB on dismiss.

@onready var title_label: Label = %TitleLabel
@onready var zone_list: VBoxContainer = %ZoneList
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
