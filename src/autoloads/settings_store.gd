extends Node

## SettingsStore — Player Settings (ADR-0001, ADR-0006)
## Autoload #2. Holds locale, volume levels, and text speed.
## _ready() must NOT reference any other autoload.

signal settings_changed(key: String)

# Private state
var _locale: String = "en"
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_volume: float = 1.0
var _text_speed: float = 1.0

# Persistence flags (same pattern as GameStore GS-003)
var _dirty: bool = false
var _save_pending: bool = false

func _ready() -> void:
	pass  # Boot order: no autoload refs

# ── Getters ──
func get_locale() -> String:
	return _locale

func get_master_volume() -> float:
	return _master_volume

func get_sfx_volume() -> float:
	return _sfx_volume

func get_music_volume() -> float:
	return _music_volume

func get_text_speed() -> float:
	return _text_speed

# ── Setters ──
func set_locale(value: String) -> void:
	_locale = value
	_mark_dirty()
	settings_changed.emit("locale")

func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_mark_dirty()
	settings_changed.emit("master_volume")

func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_mark_dirty()
	settings_changed.emit("sfx_volume")

func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_mark_dirty()
	settings_changed.emit("music_volume")

func set_text_speed(value: float) -> void:
	_text_speed = clampf(value, 0.1, 3.0)
	_mark_dirty()
	settings_changed.emit("text_speed")

# ── Persistence ──
func _mark_dirty() -> void:
	_dirty = true
	if not _save_pending:
		_save_pending = true
		call_deferred("_flush_save")

func _flush_save() -> void:
	if not _dirty:
		_save_pending = false
		return
	SaveManager.save_game()
	_dirty = false
	_save_pending = false

func to_dict() -> Dictionary:
	return {
		"locale": _locale,
		"master_volume": _master_volume,
		"sfx_volume": _sfx_volume,
		"music_volume": _music_volume,
		"text_speed": _text_speed,
	}

func from_dict(data: Dictionary) -> void:
	_locale = data.get("locale", "en")
	_master_volume = data.get("master_volume", 1.0)
	_sfx_volume = data.get("sfx_volume", 1.0)
	_music_volume = data.get("music_volume", 1.0)
	_text_speed = data.get("text_speed", 1.0)
	_dirty = false
	_save_pending = false
