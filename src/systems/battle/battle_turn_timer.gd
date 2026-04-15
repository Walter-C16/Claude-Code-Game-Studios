class_name BattleTurnTimer
extends RefCounted

## BattleTurnTimer — Per-turn countdown for action combat encounters.
##
## Pure logic. No node access, no _process binding. The battle scene drives
## tick(delta) from its own _process loop and listens for the `expired` signal
## to decide what to do (auto-attack, end turn, etc.).
##
## Lifecycle:
##   start(seconds) → enabled = true, time_remaining = seconds
##   tick(delta)    → only ticks when enabled; emits `expired` when reaching 0
##   reset()        → enabled = false, time_remaining = 0; clears the latch
##
## The `expired` signal fires exactly once per timeout — the internal
## enabled flag latches false on expiry so subsequent tick() calls are no-ops
## until the next start(). This prevents UI from being spammed if the
## consumer doesn't call reset() immediately.

signal expired

var time_remaining: float = 0.0
var enabled: bool = false


## Arms the timer with [param seconds] of countdown. A non-positive value is
## treated as a no-op so callers can safely pass an unconfigured encounter.
func start(seconds: float) -> void:
	if seconds <= 0.0:
		enabled = false
		time_remaining = 0.0
		return
	time_remaining = seconds
	enabled = true


## Drains the timer by [param delta] seconds. No-op when disabled. Emits
## `expired` exactly once on the tick that crosses zero.
func tick(delta: float) -> void:
	if not enabled:
		return
	if delta <= 0.0:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		enabled = false
		expired.emit()


## True when the timer has finished its countdown but reset() has not yet been
## called. Meant for UI polling — the signal is the canonical "fire once"
## hook.
func is_expired() -> bool:
	return not enabled and time_remaining <= 0.0


## Clears the timer state. Safe to call repeatedly.
func reset() -> void:
	enabled = false
	time_remaining = 0.0
