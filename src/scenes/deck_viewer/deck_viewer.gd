extends Control

## DeckViewer — Read-only view of any deck (opponent or collection).
##
## Receives the deck to display via SceneManager arrival context.
## Key: "deck_id" (String) — identifies which deck to render.
## Navigates back to HUB on dismiss.

@onready var title_label: Label = %TitleLabel
@onready var card_grid: GridContainer = %CardGrid
@onready var back_btn: Button = %BackBtn


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	var ctx: Dictionary = SceneManager.get_arrival_context()
	if ctx.has("deck_id"):
		title_label.text = "DECK: %s" % ctx["deck_id"]


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
