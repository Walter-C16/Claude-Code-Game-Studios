# Quick Design Spec: Turn Timer (Action Combat)

> **Type**: Optional combat mechanic — adds urgency on a per-encounter basis
> **Author**: game-designer
> **Created**: 2026-04-15
> **Status**: Implemented in Phase G (v1 of this spec)
> **Cross refs**: design/quick-specs/companion-battle-stats.md, design/gdd/poker-combat.md (deprecated parent — action combat replaces poker for story fights)

---

## Problem

Action combat as shipped in Phase A-F is fully turn-based with no urgency. Players can stop and think indefinitely, which is fine for normal fights but undercuts the tension of boss encounters or fights against fast/agile enemies. The narrative has lore-fast enemies (Hermes-blessed creatures, void-wraiths, etc.) that should *feel* fast on the input layer, not just on the AGI stat.

The player wants:
1. A turn timer mechanic that is **off by default** (most fights stay casual).
2. **Per-encounter opt-in** — bosses or specific enemies declare a timer in their data.
3. Timer values like **60s for bosses, 30s for fast enemies, 15s for very fast enemies**.
4. **Auto-cast a normal attack** when the timer expires (the turn isn't lost).
5. **Accessibility-friendly** — a global toggle disables the timer for players who find timed turns stressful.

## Solution

Add a per-enemy `turn_timer_seconds` field to `character_battle_stats.json`. At battle setup, `BattleManager` reads the **maximum** value across all enemies in the encounter (charitable to the player when fighting mixed enemies). If that max is > 0, the encounter is timed.

On each player turn, a countdown bar appears above the action buttons and drains linearly. If it reaches 0, the system auto-casts a normal attack against a random living enemy. Enemy turns hide the bar entirely — the AI doesn't need a timer.

A global accessibility setting `combat_disable_timers: bool` overrides everything and disables the timer regardless of enemy data.

## Detailed rules

### Per-enemy data field

`character_battle_stats.json` enemies gain a new optional integer field:

```json
"gaia_spirit": {
  "element": "Earth",
  ...,
  "turn_timer_seconds": 60
}
```

| Value | Meaning |
|---|---|
| 0 (default if missing) | No timer. Casual pacing. |
| 15 | Very fast enemy (lightning-blessed, hermes-touched). Stressful — use sparingly. |
| 30 | Fast enemy (warrior, hunter). Reasonable urgency. |
| 45 | Mid-difficulty enemy. Boss of a regular zone. |
| 60 | Boss enemy. Generous but enforced. |
| 90+ | Reserved for very long ult-heavy bosses where multi-target planning matters. |

### Encounter timer = max of enemies

```
encounter_timer = 0
for enemy in enemies:
    encounter_timer = max(encounter_timer, enemy.turn_timer_seconds)
```

This is intentionally charitable: a slow boss + a fast adds gives the player the boss's slower timer. Punishing the player for AI-side variety makes the mechanic feel unfair.

### Player turn behavior

1. On `turn_started(actor)` where actor is in the player party:
   - If `encounter_timer > 0` and `combat_disable_timers == false`:
     - Show the timer bar above the action buttons.
     - Set `BattleTurnTimer.start(encounter_timer)`.
2. Each frame in `_process(delta)`:
   - If the timer is active and the current actor is still the player:
     - `BattleTurnTimer.tick(delta)`.
     - Update the bar's `value = time_remaining / encounter_timer`.
3. When the timer expires (`expired` signal):
   - Call `BattleManager.auto_normal_attack()`.
   - Run the same animation pipeline as a manual cast (`_animate_hit_results`).

### Enemy turn behavior

- Hide the timer bar.
- Do NOT tick the timer.
- Enemy AI runs at its normal pace (existing 0.8s `ENEMY_AI_DELAY`).

### Auto-attack on timeout

`BattleManager.auto_normal_attack()`:

1. Pick a random living enemy from `live_enemies()`.
2. If none, return — battle's already over.
3. Call `execute_move("normal", [target])`.
4. Same energy / charge / blessing math as a player-initiated normal attack.

The player's turn ends through the normal `_end_turn` path. No special handling.

### Accessibility override

A new field `combat_disable_timers: bool` (default `false`) lives on the settings store. When `true`:
- The timer bar is never shown.
- The timer never starts.
- Enemy timer values are still **read** (no harm), but ignored at runtime.

The settings UI to toggle this is out of scope for v1 — the field ships and is read by combat. Settings UI can flip it in a later pass.

### Tutorial override

The first combat (`_story_node == "ch01_n00"`) ignores the timer **regardless** of enemy data. The tutorial fight is teaching mechanics; timed turns would be hostile.

## v1 enemy timer assignments

| Enemy | turn_timer_seconds | Lore reason |
|---|---|---|
| `forest_monster` | 0 | Tutorial fodder — no timer ever. |
| `mountain_beast` | 45 | Lumbering brute but with a reasonable threat clock. |
| `amazon_challenger` | 30 | Trained warrior — reads the player and strikes fast. |
| `gaia_spirit` | 60 | Boss. Generous, but enforced for the climax of Chapter 1. |
| `sardis_card_master` | 0 | Tavern poker reskin — no timer ever. |

## Formulas

### Bar fill

```
bar_value = time_remaining / encounter_timer    # range [0, 1]
```

ProgressBar widget with `min_value = 0`, `max_value = 1`, `step = 0.001` for smooth tween.

### Tick

```
on _process(delta):
    if not timer.enabled:
        return
    if current_actor.is_enemy:
        return
    timer.time_remaining -= delta
    if timer.time_remaining <= 0:
        timer.time_remaining = 0
        timer.enabled = false
        emit_signal("expired")
```

The `enabled` flag gates the signal so it fires exactly once per timeout (no spam).

## Edge cases

- **Player ends turn before timer expires**: `BattleTurnTimer.reset()` zeroes the timer. Next player turn calls `start()` again with a fresh full bar.
- **Timer expires during animation**: not possible — UI animations block input but don't pause `_process`. If it happens, the auto-attack queues after the current animation completes.
- **Player loses focus / app backgrounded**: Godot pauses `_process` when the app is suspended. Timer will resume from where it stopped on resume. Acceptable — single-player game, no leaderboards.
- **All enemies dead before timer expires**: turn ends normally, timer resets.
- **`combat_disable_timers` toggled mid-battle**: takes effect on the next `turn_started` — the current turn keeps whatever state it had.
- **Timer = 0 enemy in a mixed encounter**: encounter timer is the MAX, so a single non-zero enemy still arms the encounter. A pure 0/0 encounter has `encounter_timer = 0` and the bar is hidden.
- **Tutorial fight with timer-armed enemy**: tutorial override wins. Timer hidden.

## Dependencies

- **BattleStats** — `turn_timer_seconds: int` field in `from_dict`.
- **BattleManager** — reads max timer at setup, exposes `turn_time_limit`, provides `auto_normal_attack()`.
- **battle.gd (UI)** — drives the timer in `_process`, owns the bar widget.
- **`character_battle_stats.json`** — per-enemy values.
- **SettingsStore (or GameStore)** — `combat_disable_timers` field.
- **BattleTurnTimer** (new RefCounted) — pure timer logic class.
- **Localization** — bar label, timeout message.

## Tuning knobs

| Knob | Default | Safe range | Effect |
|---|---|---|---|
| Per-enemy `turn_timer_seconds` | 0 | 15–120 | The single most important knob. Set per encounter. |
| `combat_disable_timers` | false | true/false | Global accessibility kill switch. |
| Bar drain visual smoothing | linear | linear / ease-in | Currently linear; could ease for drama. |

## Acceptance criteria

- AC-TIMER-01: An enemy with `turn_timer_seconds: 0` produces no timer bar in combat. (Forest monster.)
- AC-TIMER-02: An enemy with `turn_timer_seconds: 60` produces a 60-second timer bar at the start of every player turn. (Gaia spirit.)
- AC-TIMER-03: A mixed encounter (30s + 60s enemies) uses the 60-second timer (max).
- AC-TIMER-04: When the timer hits 0 on a player turn, a normal attack is auto-cast against a random living enemy and the turn advances.
- AC-TIMER-05: The timer bar is hidden on enemy turns.
- AC-TIMER-06: `combat_disable_timers = true` hides the bar regardless of enemy data.
- AC-TIMER-07: The tutorial fight (`ch01_n00`) never shows a timer regardless of enemy data.
- AC-TIMER-08: `BattleTurnTimer` unit tests cover start/tick/expired/reset/no-tick-when-disabled.
- AC-TIMER-09: `BattleManager` unit tests cover `setup` reading the max enemy timer and `auto_normal_attack` consuming a turn.
- AC-TIMER-10: Battle suite passes after the changes (52 tests + ~7 new = 59 tests).
