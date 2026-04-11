# Audio

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-10

## Summary

The Audio system manages BGM and SFX playback across all game screens. A 2-layer dynamic BGM system (base track + tension layer) responds to game state. SFX are organized into four categories (combat, UI, dialogue, ambient). Volume is controlled per-category via SettingsStore. BGM transitions use crossfade on scene change. The system is implemented as an AudioManager autoload using Godot's `AudioStreamPlayer` nodes.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha` · Key deps: none (standalone)

---

## Overview

Audio in Dark Olympus is managed by a singleton `AudioManager` autoload that persists across all scene changes. It maintains two BGM `AudioStreamPlayer` nodes (base layer and tension layer) and four SFX `AudioStreamPlayer` buses (combat, UI, dialogue, ambient). BGM tracks crossfade over a configurable duration when the active scene changes — the outgoing track fades out as the incoming track fades in. The tension layer is a separate audio track that blends in (volume increases) during high-stakes combat moments and blends out at rest. Volume levels per category are read from `SettingsStore` at startup and updated in real time when the settings screen changes a value. All audio asset paths are defined in `assets/data/audio_manifest.json`. The system makes no gameplay decisions — it is a pure audio service consumed by other systems via a clean API.

---

## Player Fantasy

**"The Myth Has a Voice"**

Audio in Dark Olympus is not decoration — it is atmosphere. The BGM shifts from the warm, low strings of Camp to the rhythmic tension of combat. When a blessing activates, a brief divine chord punctuates the scoring moment. When a companion delivers a key story line, silence holds for half a beat before the typewriter continues.

The 2-layer BGM system serves the fantasy of being in a living mythological world: the base track establishes the world's texture (ancient, golden, melancholic), and the tension layer rises when the stakes rise. The player should never consciously notice audio changes — they should only feel more tense in combat and more at ease in camp.

The SFX catalog serves the same function: card plays click with satisfying weight; score counters animate with rising pitch; the intimacy scene transition is softer and slower than a combat transition. Every audio event reinforces the emotional register of the moment it accompanies.

---

## Detailed Rules

### Rule 1 — AudioManager Autoload

`AudioManager` is a Godot autoload (singleton) that initializes when the game starts and persists for the session. It is not attached to any scene. It holds:

- `bgm_player_a`: `AudioStreamPlayer` — currently playing BGM
- `bgm_player_b`: `AudioStreamPlayer` — incoming BGM during crossfade
- `tension_player`: `AudioStreamPlayer` — tension layer overlay
- `sfx_players`: Dictionary of `AudioStreamPlayer` keyed by SFX category (combat, ui, dialogue, ambient)

The `AudioManager` exposes a public API (see Integration Contract). No other system directly accesses `AudioStreamPlayer` nodes — all playback requests go through the API.

### Rule 2 — BGM Tracks

BGM tracks are defined in `assets/data/audio_manifest.json` under the `bgm` key. Each track has:
- `track_id` (String) — unique key
- `file_path` (String) — `.ogg` file path relative to `assets/audio/bgm/`
- `tension_path` (String or null) — companion tension layer `.ogg` file path; null if no tension layer
- `loop` (bool) — whether the track loops

**Track catalog (placeholder IDs — final names to be assigned by audio production):**

| Track ID | Context | Has Tension Layer |
|----------|---------|------------------|
| `main_menu` | Main menu / title screen | No |
| `camp` | Camp hub, companion interactions | No |
| `dialogue` | Story dialogue sequences | No |
| `combat_standard` | Standard story fights | Yes |
| `combat_boss` | Boss encounters | Yes |
| `abyss` | Abyss Mode ambient | Yes |
| `intimacy` | Intimacy scenes | No |
| `victory` | Post-combat win stinger (short, non-looping) | No |
| `defeat` | Post-combat defeat stinger (short, non-looping) | No |

### Rule 3 — BGM Crossfade

When a scene change triggers a BGM swap (`play_bgm(track_id)`):

1. Identify `bgm_player_a` (currently playing) and `bgm_player_b` (inactive)
2. Load the new track into `bgm_player_b` and begin playback at volume 0
3. Tween `bgm_player_a` volume from current volume → -80 dB (silence) over `BGM_CROSSFADE_DURATION`
4. Tween `bgm_player_b` volume from -80 dB → target volume over `BGM_CROSSFADE_DURATION`
5. After tween completes: stop `bgm_player_a`, swap roles (`bgm_player_a = bgm_player_b`)

If `play_bgm` is called while a crossfade is already in progress, the in-progress tween is cancelled and the new crossfade starts immediately from current volumes. This prevents cascading crossfades from rapid scene changes.

Victory and defeat stingers (`victory`, `defeat`) are short non-looping tracks. They play over the current BGM without crossfade using a separate `stinger_player` node. The BGM continues playing underneath at reduced volume (`BGM_DUCK_DB`) during the stinger.

### Rule 4 — Tension Layer

The tension layer is a second audio track that plays at the same time as the base BGM. It is volume-controlled independently. Its purpose is to add musical tension during dangerous combat moments without changing the main track.

Tension layer is engaged when:
- `hands_remaining <= 1` during combat (last hand)
- Score is below 50% of threshold with `hands_remaining <= 2`

Tension layer is disengaged when:
- Combat ends (victory or defeat)
- The player discards (not plays) — brief reprieve
- Scene changes away from combat

Tension layer volume transitions use a short tween (`TENSION_FADE_DURATION`, default 1.0 second) to prevent jarring cuts.

If the active BGM has `tension_path = null`, the tension layer is not engaged (Camp, Dialogue, Intimacy tracks have no tension layer).

### Rule 5 — SFX Categories and Playback

Four SFX categories, each with a dedicated bus:

| Category | Bus Name | Example Events |
|----------|---------|----------------|
| `combat` | "Combat" | Card select click, card play whoosh, score counter tick, element spark, hand rank announce, victory chime, defeat thud |
| `ui` | "UI" | Button tap, menu open/close, notification pop, tab switch |
| `dialogue` | "Dialogue" | Typewriter tick (per character), choice node appear, companion voice grunt/sigh |
| `ambient` | "Ambient" | Camp background birds, Abyss background hum, wind |

SFX are played via `play_sfx(sfx_id, category)`. The SFX ID looks up a file path in `audio_manifest.json` under `sfx`. Multiple SFX in the same category can play simultaneously (each uses its own temporary `AudioStreamPlayer` node instanced at call time and freed on completion).

### Rule 6 — Volume Control

Volume per-category is stored as a linear percentage (0.0 to 1.0) in `SettingsStore`:
- `settings.volume_bgm` — applies to `bgm_player_a`, `bgm_player_b`, `tension_player`
- `settings.volume_sfx_combat` — applies to combat SFX bus
- `settings.volume_sfx_ui` — applies to UI SFX bus
- `settings.volume_sfx_dialogue` — applies to dialogue SFX bus
- `settings.volume_sfx_ambient` — applies to ambient SFX bus

Volume is converted to dB for Godot's audio bus: `volume_db = linear_to_db(linear_volume)`.

`AudioManager` connects to `SettingsStore`'s `settings_changed` signal and updates bus volumes in real time. Changes in the Settings screen are reflected immediately without restarting the game or the current track.

### Rule 7 — Silence State

When `settings.volume_bgm == 0.0`, BGM players are stopped (not just muted) to conserve battery on mobile. When volume is restored above 0.0, the appropriate track resumes. SFX buses are muted at 0.0 but the system still processes play calls (they are inaudible but not skipped).

---

## Formulas

### Volume Conversion

```
volume_db = linear_to_db(linear_volume)
```

Where `linear_volume` is in range [0.0, 1.0] and `linear_to_db` is Godot's built-in conversion. At `linear_volume = 0.0`, result is `-INF` dB (silence). At `linear_volume = 1.0`, result is `0.0 dB` (full volume).

### BGM Duck During Stinger

```
bgm_volume_during_stinger = current_bgm_volume_db + BGM_DUCK_DB
```

Where `BGM_DUCK_DB = -6.0` (default, reduces BGM by 6 dB under stingers). Applied as a tween over `STINGER_DUCK_FADE` (0.2 seconds). Restored on stinger end.

### Tension Layer Volume

```
tension_volume_db = BGM_TENSION_TARGET_DB   (when engaged)
tension_volume_db = -80.0                   (when disengaged / silent)
```

Both transitions are tweened over `TENSION_FADE_DURATION`.

---

## Edge Cases

**EC-1: `play_bgm` called with the same track that is already playing.**
No action taken. Early return check: `if current_track_id == track_id: return`. Prevents unnecessary crossfade restarts on repeated calls.

**EC-2: BGM file missing from disk.**
`AudioStreamPlayer.stream` will be null if the resource path is invalid. Guard: check stream after load; if null, log an error and skip playback. Other systems are not blocked. A missing BGM is non-fatal.

**EC-3: SFX file missing.**
Same guard as EC-2. Missing SFX is silently skipped with an error log. Gameplay proceeds. The missing sound is logged to a buffer for review — not shown to the player.

**EC-4: Rapid scene changes (faster than `BGM_CROSSFADE_DURATION`).**
The in-progress crossfade tween is killed and a new one starts from current volumes. Volume never drops below -80 dB or above 0 dB during this process. The `bgm_player_a/b` role swap happens correctly regardless of how many rapid changes occur.

**EC-5: App backgrounded mid-crossfade (mobile).**
Godot's audio engine pauses automatically when the app loses focus on mobile. The tween (if using `SceneTree`-based tweens) also pauses. On foreground restore, both resume. If the tween is complete by the time the app returns, the final volume state is correct regardless.

**EC-6: Tension layer engaged in a scene with `tension_path = null`.**
`AudioManager` checks `tension_path` before attempting to engage. If null, the engage call is ignored. No error, no sound.

**EC-7: Volume set to 0 then restored mid-track.**
BGM is stopped at volume 0. On restore, `AudioManager` calls `play_bgm(current_track_id)` with a short (0.5 second) fade-in from silence. The track restarts from the beginning (not from a saved position). This is a deliberate simplification — resuming mid-track requires storing playback position, which is lower priority for the mobile use case.

---

## Dependencies

### Systems this depends on

None. Audio is a standalone Foundation-layer system with no gameplay dependencies. It reads volume settings from `SettingsStore` and asset paths from `assets/data/audio_manifest.json`.

### Systems that depend on this

| System | How |
|--------|-----|
| **Poker Combat** | Calls `play_sfx("card_select", "combat")`, `play_sfx("card_play", "combat")`, `play_sfx("score_tick", "combat")`, `play_bgm("combat_standard")` / `"combat_boss"`, `play_stinger("victory")` / `"defeat"`, and tension layer engage/disengage |
| **Dialogue** | Calls `play_sfx("typewriter_tick", "dialogue")` per character, `play_sfx("choice_appear", "dialogue")`, `play_bgm("dialogue")` on dialogue scene entry |
| **Intimacy** | Calls `play_bgm("intimacy")` on scene start; silence or dialogue SFX during scene |
| **Camp** | Calls `play_bgm("camp")` on camp screen entry, `play_sfx("ambient_birds", "ambient")` |
| **Abyss Mode** | Calls `play_bgm("abyss")` on run entry; tension layer engaged as in standard combat |
| **Scene Navigation** | Calls `play_bgm(track_id)` on each scene transition based on destination screen |
| **Settings Screen** | Writes volume values to `SettingsStore`; `AudioManager` receives `settings_changed` signal and updates bus volumes in real time |

### Integration Contract

**Public API (all other systems call these):**

```
AudioManager.play_bgm(track_id: String) -> void
AudioManager.play_sfx(sfx_id: String, category: String) -> void
AudioManager.play_stinger(stinger_id: String) -> void
AudioManager.set_tension(engaged: bool) -> void
AudioManager.stop_bgm() -> void
```

**Internal only (not called externally):**

```
_apply_volume_settings() -> void    # updates bus volumes from SettingsStore
_crossfade_to(track_id: String) -> void
_duck_bgm(duck: bool) -> void
```

---

## Tuning Knobs

| Knob | Category | Default | Range | Notes |
|------|----------|---------|-------|-------|
| `BGM_CROSSFADE_DURATION` | Feel | 1.5 seconds | 0.5–3.0 | Duration of BGM crossfade on scene change. Shorter = snappier transitions. |
| `TENSION_FADE_DURATION` | Feel | 1.0 second | 0.3–2.0 | Duration of tension layer fade in/out. |
| `BGM_DUCK_DB` | Feel | -6.0 dB | -3.0 to -12.0 | BGM volume reduction under victory/defeat stingers. |
| `STINGER_DUCK_FADE` | Feel | 0.2 seconds | 0.1–0.5 | Time to ramp BGM duck on stinger start. |
| `BGM_TENSION_TARGET_DB` | Feel | -12.0 dB | -6.0 to -18.0 | Tension layer volume when engaged. At -12 it blends under the base track. |
| `VOLUME_RESTORE_FADE` | Feel | 0.5 seconds | 0.2–1.0 | Fade-in duration when BGM restored after mute. |

All knobs live in `assets/data/audio_config.json`.

---

## Acceptance Criteria

### Functional Criteria

- [ ] **AC-1**: `play_bgm(track_id)` crossfades from the current track to the new track over `BGM_CROSSFADE_DURATION` seconds. The outgoing track reaches silence and the incoming track reaches full volume at the end of the tween.
- [ ] **AC-2**: Calling `play_bgm` with the same track ID that is already playing does nothing — no crossfade is initiated, playback continues uninterrupted.
- [ ] **AC-3**: The tension layer engages (`set_tension(true)`) when `hands_remaining <= 1` in combat. It disengages when combat ends or scene changes away from combat. Engagement and disengagement use the `TENSION_FADE_DURATION` tween.
- [ ] **AC-4**: `play_sfx(sfx_id, category)` plays the specified audio file on the correct bus. Multiple SFX calls in rapid succession (e.g., typewriter ticks) do not block each other — each uses its own temporary `AudioStreamPlayer`.
- [ ] **AC-5**: Volume settings from `SettingsStore` are applied to all relevant buses on `settings_changed`. A change in the Settings screen is audible within one frame.
- [ ] **AC-6**: A missing audio file (resource returns null) logs an error and skips playback silently without crashing or blocking the calling system.
- [ ] **AC-7**: When `settings.volume_bgm == 0.0`, BGM players are stopped (not just muted at -80 dB). When volume is restored above 0.0, `play_bgm(current_track_id)` is called with a `VOLUME_RESTORE_FADE` second fade-in.
- [ ] **AC-8**: Rapid scene changes (3 scene changes within 1 second) result in only the final target BGM playing. Intermediate crossfades are cancelled cleanly. No volume stacking or stuck-silent state occurs.

### Experiential Criteria

- [ ] **EX-1** (Playtest): Players do not consciously notice BGM crossfades — the transition between Camp and Combat BGM is perceived as "smooth" or "natural" in debrief, not as a jarring cut. Target: fewer than 15% of playtesters mention the transition negatively.
- [ ] **EX-2** (Playtest): The tension layer during low-hands combat is perceived as increasing tension — playtesters report feeling "more stressed" or "more focused" on last-hand plays compared to no-tension sessions (A/B test with tension layer disabled).
- [ ] **EX-3** (Playtest): Typewriter SFX is not mentioned as annoying or distracting. Default volume balance between dialogue SFX and BGM keeps both audible without either overwhelming the other.
