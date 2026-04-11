extends Control

## ChapterMap — Story chapter selection screen.
##
## Displays available chapters and lets the player enter a chapter's dialogue.
## Navigates back to HUB on dismiss.

@onready var title_label: Label = %TitleLabel
@onready var chapter_list: VBoxContainer = %ChapterList
@onready var back_btn: Button = %BackBtn


func _ready() -> void:


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
