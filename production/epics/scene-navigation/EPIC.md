# Epic: Scene Navigation

> **Layer**: Foundation
> **GDD**: design/gdd/scene-navigation.md
> **Architecture Module**: UI / Core (scene lifecycle, transitions)
> **Governing ADRs**: ADR-0003, ADR-0006
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories scene-navigation`

## Overview

SceneManager is an autoload that centralizes all scene transitions. It provides change_scene(SceneId, TransitionType, context) as the sole entry point -- raw SceneTree.change_scene_to_file() calls outside scene_manager.gd are forbidden. The system uses a SceneId enum registry mapping all 16+ screens to .tscn paths, animated fade-to-black transitions (0.3s out + 0.3s in), a state machine transition guard against double-taps, input blocking via MOUSE_FILTER_STOP on a CanvasLayer 100 overlay, read-once context payloads for inter-scene data, and Settings as a CanvasLayer 50 overlay (not a scene change). Hub tabs use keep-alive hide/show internally. Boot position #6.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Scene Management -- SceneId Registry + Transitions | SceneManager autoload with SceneId enum, fade transitions, state machine guard, input blocking, context payload, Settings overlay, Hub keep-alive tabs | MEDIUM |
| ADR-0006: Autoload Boot Order + Layer Dependency Rules | SceneManager is autoload #6; creates transition overlay CanvasLayer in _ready() | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-scene-nav-001 | SceneManager autoload with SceneId enum registry mapping all scenes to res:// paths | ADR-0003 |
| TR-scene-nav-002 | Hub tab bar uses keep-alive hide/show for tabs 1-4; no SceneManager call | ADR-0003 |
| TR-scene-nav-003 | Settings as CanvasLayer overlay at layer 50; underlying scene not freed | ADR-0003 |
| TR-scene-nav-004 | Transition guard: silently drop change_scene() calls during active transition | ADR-0003 |
| TR-scene-nav-005 | Input blocking during transitions via MOUSE_FILTER_STOP on overlay | ADR-0003 |
| TR-scene-nav-006 | Context payload dictionary on change_scene(); read-once via get_arrival_context() | ADR-0003 |
| TR-scene-nav-007 | Signal contract: scene_changed(scene_id) after fade-in; transition_started before fade-out | ADR-0003 |
| TR-scene-nav-008 | Android back button per-scene handling; SceneManager intercepts during OVERLAY_OPEN | ADR-0003 |
| TR-scene-nav-009 | Scene state destroyed on full change; persistent state in autoload stores only | ADR-0003 |
| TR-scene-nav-010 | Fade transition overlay on CanvasLayer 100 parented to SceneManager autoload | ADR-0003 |
| TR-scene-nav-011 | Error recovery: if .tscn load fails, fade back to previous scene, emit navigation_error | ADR-0003 |
| TR-scene-nav-012 | Transition duration under 1.5s; no frame drops below 30fps during fades | ADR-0003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories scene-navigation` to break this epic into implementable stories.
