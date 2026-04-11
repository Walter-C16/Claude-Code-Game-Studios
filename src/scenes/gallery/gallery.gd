extends Control

@onready var title_label: Label = %Title
@onready var back_btn: Button = %BackBtn
@onready var grid: GridContainer = %Grid

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_load_gallery()

func _load_gallery() -> void:
	var entries = Gallery.get_all_entries()
	for entry in entries:
		var btn := Button.new()
		btn.text = "???" if not entry["unlocked"] else entry.get("title_key", "CG")
		btn.custom_minimum_size = Vector2(120, 120)
		btn.disabled = not entry["unlocked"]
		grid.add_child(btn)

func _on_back() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
