extends Node

## AudioManager — 2-Layer Dynamic BGM + SFX Playback (ADR-0012)
##
## Autoload #12. Persists across all scene changes. Manages:
##   - 2 BGM AudioStreamPlayer nodes (A/B crossfade on track change)
##   - 1 tension-layer AudioStreamPlayer (volume-blended on combat state)
##   - 1 stinger AudioStreamPlayer (victory/defeat short non-looping clips)
##   - Per-category SFX playback (combat, ui, dialogue, ambient)
##
## NO class_name — autoload rule (memory/feedback_godot_class_name.md).
## Tests preload this file with: const Script = preload("res://autoloads/audio_manager.gd")
##
## Volume settings are read from SettingsStore and updated in real time on
## SettingsStore.settings_changed.
##
## Boot order: Autoload #12. References SettingsStore (#2) in _ready().
##
## GDD: design/gdd/audio.md

# ── Constants (Tuning Knobs) ──────────────────────────────────────────────────

## Duration of BGM crossfade in seconds (GDD Tuning Knob).
const BGM_CROSSFADE_DURATION: float = 1.5

## Duration of tension layer fade in/out in seconds (GDD Tuning Knob).
const TENSION_FADE_DURATION: float = 1.0

## BGM volume reduction (dB) under a stinger (GDD Tuning Knob).
const BGM_DUCK_DB: float = -6.0

## Ramp time for BGM duck on stinger start (GDD Tuning Knob).
const STINGER_DUCK_FADE: float = 0.2

## Target volume (dB) of tension layer when engaged (GDD Tuning Knob).
const BGM_TENSION_TARGET_DB: float = -12.0

## Fade-in duration when BGM is restored after mute (GDD Tuning Knob).
const VOLUME_RESTORE_FADE: float = 0.5

## Silence threshold in dB — anything below this is considered silent.
const SILENCE_DB: float = -80.0

## Path to the audio manifest JSON file.
const MANIFEST_PATH: String = "res://assets/data/audio_manifest.json"

# ── Private State ─────────────────────────────────────────────────────────────

## BGM player currently on stage (playing).
var _bgm_a: AudioStreamPlayer

## BGM player used as the incoming track during crossfades.
var _bgm_b: AudioStreamPlayer

## Tension overlay player (plays simultaneously with active BGM).
var _tension: AudioStreamPlayer

## Stinger player for short non-looping victory/defeat clips.
var _stinger: AudioStreamPlayer

## Track ID currently loaded in _bgm_a (or the last completed crossfade target).
var _current_track_id: String = ""

## True when the tension layer is engaged.
var _tension_active: bool = false

## Active crossfade tween (killed on new play_bgm call).
var _crossfade_tween: Tween

## Active tension tween (killed when set_tension is called).
var _tension_tween: Tween

## Cached audio manifest data. Keys: "bgm" (Dict), "sfx" (Dict).
var _manifest: Dictionary = {}

## True if BGM was stopped due to volume_bgm == 0.
var _bgm_muted_stop: bool = false

# ── Built-in Virtual Methods ──────────────────────────────────────────────────

func _ready() -> void:
	_create_players()
	_load_manifest()
	_apply_volumes()
	SettingsStore.settings_changed.connect(_on_settings_changed)

# ── Public API ────────────────────────────────────────────────────────────────

## Plays BGM track identified by [param track_path] (direct resource path or
## manifest track_id). Crossfades from the current track over
## [param crossfade_duration] seconds. Passing the same track that is already
## playing is a no-op (GDD EC-1).
func play_bgm(track_path: String, crossfade_duration: float = BGM_CROSSFADE_DURATION) -> void:
	# EC-1: same track already playing — no-op.
	if track_path == _current_track_id and _bgm_a.playing:
		return

	var stream: AudioStream = _load_stream(track_path)
	if stream == null:
		push_error("[AudioManager] play_bgm: resource not found — '%s'" % track_path)
		return

	# Cancel any in-progress crossfade tween (GDD EC-4).
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	_current_track_id = track_path

	# BGM muted-stop: if master volume is zero, just load and record but don't play.
	var music_volume: float = SettingsStore.get_music_volume()
	if music_volume <= 0.0:
		_bgm_a.stop()
		_bgm_b.stop()
		_bgm_muted_stop = true
		return

	_bgm_muted_stop = false
	var target_db: float = linear_to_db(music_volume)

	# Load incoming track into _bgm_b and begin at silence.
	_bgm_b.stream = stream
	_bgm_b.volume_db = SILENCE_DB
	_bgm_b.play()

	# Tween: fade out A, fade in B simultaneously.
	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(_bgm_a, "volume_db", SILENCE_DB, crossfade_duration)
	_crossfade_tween.tween_property(_bgm_b, "volume_db", target_db, crossfade_duration)
	_crossfade_tween.chain().tween_callback(_on_crossfade_complete)

## Stops BGM playback, fading out over [param fade_duration] seconds.
func stop_bgm(fade_duration: float = BGM_CROSSFADE_DURATION) -> void:
	_current_track_id = ""
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(_bgm_a, "volume_db", SILENCE_DB, fade_duration)
	_crossfade_tween.tween_property(_bgm_b, "volume_db", SILENCE_DB, fade_duration)
	_crossfade_tween.chain().tween_callback(func() -> void:
		_bgm_a.stop()
		_bgm_b.stop()
	)

## Engages or disengages the tension overlay layer.
## Volume transition uses [constant TENSION_FADE_DURATION].
## If the current track has no tension layer, this is a no-op (GDD EC-6).
func set_tension(enabled: bool) -> void:
	if _tension_active == enabled:
		return

	# If tension player has no stream loaded, nothing to do.
	if _tension.stream == null:
		return

	_tension_active = enabled

	if _tension_tween != null and _tension_tween.is_valid():
		_tension_tween.kill()

	_tension_tween = create_tween()
	if enabled:
		if not _tension.playing:
			_tension.play()
		_tension_tween.tween_property(_tension, "volume_db", BGM_TENSION_TARGET_DB, TENSION_FADE_DURATION)
	else:
		_tension_tween.tween_property(_tension, "volume_db", SILENCE_DB, TENSION_FADE_DURATION)
		_tension_tween.chain().tween_callback(func() -> void:
			_tension.stop()
		)

## Plays a one-shot SFX at the given [param sfx_path] resource path.
## Creates a temporary AudioStreamPlayer freed on completion.
## [param volume_db] is an offset applied to the SFX player's volume.
## Missing resources are logged and skipped silently (GDD EC-3).
func play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if sfx_path.is_empty():
		return
	var stream: AudioStream = _load_stream(sfx_path)
	if stream == null:
		push_error("[AudioManager] play_sfx: resource not found — '%s'" % sfx_path)
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(maxf(SettingsStore.get_sfx_volume(), 0.001))
	player.finished.connect(player.queue_free)
	player.play()

## Plays a stinger track (victory/defeat) over the current BGM.
## BGM ducks by [constant BGM_DUCK_DB] for the stinger duration.
## Missing resources are logged and skipped silently.
func play_stinger(track_path: String) -> void:
	if track_path.is_empty():
		return
	var stream: AudioStream = _load_stream(track_path)
	if stream == null:
		push_error("[AudioManager] play_stinger: resource not found — '%s'" % track_path)
		return

	_stinger.stream = stream
	_stinger.volume_db = linear_to_db(maxf(SettingsStore.get_music_volume(), 0.001))

	# Duck BGM.
	var bgm_db: float = _bgm_a.volume_db
	var ducked_db: float = bgm_db + BGM_DUCK_DB
	var duck_tween: Tween = create_tween()
	duck_tween.tween_property(_bgm_a, "volume_db", ducked_db, STINGER_DUCK_FADE)
	_stinger.play()
	_stinger.finished.connect(func() -> void:
		var restore_tween: Tween = create_tween()
		restore_tween.tween_property(_bgm_a, "volume_db", bgm_db, STINGER_DUCK_FADE)
	, CONNECT_ONE_SHOT)

# ── Private — Volume ──────────────────────────────────────────────────────────

## Reads volume settings from SettingsStore and applies them to all players.
## Called on startup and on every settings_changed signal.
func _apply_volumes() -> void:
	var music_vol: float = SettingsStore.get_music_volume()

	# GDD Rule 7: stop BGM players when volume == 0.0 to save battery.
	if music_vol <= 0.0:
		if _bgm_a.playing or _bgm_b.playing:
			_bgm_a.stop()
			_bgm_b.stop()
			_bgm_muted_stop = true
		_bgm_a.volume_db = SILENCE_DB
		_bgm_b.volume_db = SILENCE_DB
		_tension.stop()
		_tension.volume_db = SILENCE_DB
	else:
		var music_db: float = linear_to_db(music_vol)
		# Only update playing players; let tween-controlled ones run.
		if _bgm_a.playing and (_crossfade_tween == null or not _crossfade_tween.is_valid()):
			_bgm_a.volume_db = music_db
		# Restore from muted stop.
		if _bgm_muted_stop and not _current_track_id.is_empty():
			_bgm_muted_stop = false
			play_bgm(_current_track_id, VOLUME_RESTORE_FADE)

# ── Private — Players ─────────────────────────────────────────────────────────

func _create_players() -> void:
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.name = "BgmA"
	add_child(_bgm_a)

	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.name = "BgmB"
	add_child(_bgm_b)

	_tension = AudioStreamPlayer.new()
	_tension.name = "Tension"
	_tension.volume_db = SILENCE_DB
	add_child(_tension)

	_stinger = AudioStreamPlayer.new()
	_stinger.name = "Stinger"
	add_child(_stinger)

# ── Private — Manifest + Stream Loading ──────────────────────────────────────

func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("[AudioManager] Manifest not found: %s" % MANIFEST_PATH)
		return
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file:
		push_warning("[AudioManager] Could not open manifest: %s" % MANIFEST_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("[AudioManager] JSON parse error in manifest: %s" % json.get_error_message())
		return
	if json.data is not Dictionary:
		push_warning("[AudioManager] Manifest root must be a Dictionary.")
		return
	_manifest = json.data as Dictionary

## Loads an AudioStream resource from a res:// path.
## Returns null if the path is invalid or the resource cannot be loaded.
func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is not AudioStream:
		return null
	return res as AudioStream

# ── Private — Crossfade Completion ───────────────────────────────────────────

func _on_crossfade_complete() -> void:
	# Stop the outgoing player and swap roles.
	_bgm_a.stop()
	var temp: AudioStreamPlayer = _bgm_a
	_bgm_a = _bgm_b
	_bgm_b = temp

# ── Signal Callbacks ──────────────────────────────────────────────────────────

func _on_settings_changed(_key: String) -> void:
	_apply_volumes()
