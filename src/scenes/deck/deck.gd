extends Control

## Deck — Player's active poker-combat deck management screen.
##
## Shows cards in the current deck, allows reordering and removal.
## Navigates back to HUB on dismiss.

@onready var title_label: Label = %TitleLabel
@onready var card_list: VBoxContainer = %CardList
@onready var deck_size_label: Label = %DeckSizeLabel
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	pass


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
