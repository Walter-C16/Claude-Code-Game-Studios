extends Control

signal close_requested

@onready var title_label: Label = %Title
@onready var close_btn: Button = %CloseBtn
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	master_slider.value = SettingsStore.get_master_volume() * 100.0
	sfx_slider.value = SettingsStore.get_sfx_volume() * 100.0
	music_slider.value = SettingsStore.get_music_volume() * 100.0
	master_slider.value_changed.connect(func(v: float) -> void: SettingsStore.set_master_volume(v / 100.0))
	sfx_slider.value_changed.connect(func(v: float) -> void: SettingsStore.set_sfx_volume(v / 100.0))
	music_slider.value_changed.connect(func(v: float) -> void: SettingsStore.set_music_volume(v / 100.0))

func _on_close() -> void:
	close_requested.emit()
