extends Control

## Intimacy — High-affection companion scene screen.
##
## Gated by affection threshold. Displays a special companion moment.
## Navigates back to HUB on completion.

@onready var title_label: Label = %TitleLabel
@onready var content_area: Control = %ContentArea
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
