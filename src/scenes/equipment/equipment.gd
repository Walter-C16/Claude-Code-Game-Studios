extends Control

## Equipment — Gear and relic management screen.
##
## Lets the player equip relics that modify combat stats and abilities.
## Navigates back to HUB on dismiss.

@onready var title_label: Label = %TitleLabel
@onready var slot_list: VBoxContainer = %SlotList
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
