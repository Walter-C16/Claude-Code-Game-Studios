extends Control

@onready var title_label: Label = %Title
@onready var back_btn: Button = %BackBtn
@onready var list: VBoxContainer = %List

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_load_achievements()

func _load_achievements() -> void:
	var all = Achievements.get_all()
	for ach in all:
		var lbl := Label.new()
		var status := "[x]" if ach["unlocked"] else "[ ]"
		lbl.text = "%s %s" % [status, ach.get("title_key", ach["id"])]
		list.add_child(lbl)

func _on_back() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)
