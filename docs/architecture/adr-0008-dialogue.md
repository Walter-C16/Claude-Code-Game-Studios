# ADR-0008: Dialogue — Script Format + Playback Engine

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI / Core (text display, input handling) |
| **Knowledge Risk** | MEDIUM — Dual-focus (4.6) may affect touch input on choice panels. AccessKit (4.5) enables screen reader support for dialogue text. |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/modules/input.md` |
| **Post-Cutoff APIs Used** | AccessKit screen reader integration (4.5) — optional a11y feature. |
| **Verification Required** | Verify choice panel touch targets work correctly under 4.6 dual-focus. Verify typewriter animation with RichTextLabel `visible_characters`. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0004 (EventBus: emits dialogue_ended, relationship_changed, trust_changed), ADR-0005 (Localization: all text via get_text()) |
| **Enables** | ADR-0011 (Story Flow: orchestrates dialogue sequences), ADR-0010 (Romance: receives relationship signals) |
| **Blocks** | Story epic, Camp interaction epic (both need dialogue playback) |
| **Ordering Note** | Core layer. Implement after Foundation ADRs and in parallel with Poker Combat. |

## Context

### Problem Statement

Dark Olympus is a visual novel-hybrid. Dialogue is not a menu between combats — it IS gameplay (Pillar 2). The dialogue engine must support: JSON-driven script files with branching choices, typewriter text display, 4 speaker types with portrait rendering, effect execution on choice selection (relationship changes, flag sets), and sequence-level gating (romance stage, met status, story flags).

### Requirements

- JSON dialogue scripts at `res://assets/data/dialogue/{chapter_id}/{sequence_id}.json`
- Node-based script graph with `"start"` entry point
- 4 speaker types: companion (portrait + mood), npc (portrait, no state), narrator (no portrait), environment (distinct panel)
- Typewriter text at configurable CPS with `{pause:N}` markers
- Branching choices (max 4) with condition evaluation at render time
- 3 choice tiers: standard, insight (flag-gated, invisible if not earned), cost (consequence preview)
- Effects: relationship, trust, flag_set, flag_clear, item_grant, mood_set
- Signals emitted via EventBus, not applied directly
- Root-level gating: requires_met, requires_romance_stage, requires_flag

## Decision

**DialogueRunner is a Node that loads JSON scripts, plays them node-by-node with typewriter text and portrait rendering, presents branching choices, and emits effects via EventBus.** It is stateless between sequences — no dialogue state persists. It can be an autoload (for convenience) or scene-local (for isolation). Recommend autoload for MVP (callable from any scene).

### Script Format

```json
{
  "id": "ch01_n02_artemisa",
  "requires_met": "artemisa",
  "nodes": {
    "start": {
      "speaker": "artemisa",
      "speaker_type": "companion",
      "text_key": "CH1_ARTEMISA_01",
      "mood": "neutral",
      "next": "node_2"
    },
    "node_2": {
      "speaker": "narrator",
      "speaker_type": "narrator",
      "text_key": "CH1_NARRATOR_01",
      "choices": [
        {
          "id": "kind",
          "text_key": "CH1_CHOICE_KIND",
          "effects": [{"type": "relationship", "companion": "artemisa", "delta": 3}],
          "next": "node_3a"
        },
        {
          "id": "cold",
          "text_key": "CH1_CHOICE_COLD",
          "tier": "cost",
          "effects": [{"type": "trust", "companion": "artemisa", "delta": -2}],
          "next": "node_3b"
        }
      ]
    }
  }
}
```

### State Machine

```
IDLE → LOADING → DISPLAYING → WAITING → DISPLAYING (loop)
                                    ↘ CHOOSING → RESOLVING → DISPLAYING
LOADING → BLOCKED (gate failure) → IDLE
DISPLAYING/WAITING/CHOOSING → ENDED → IDLE
```

### Effect Emission Pattern

DialogueRunner does NOT apply state changes. It emits via EventBus:

```gdscript
func _resolve_effects(effects: Array) -> void:
    for effect in effects:
        match effect.type:
            "relationship":
                EventBus.relationship_changed.emit(effect.companion, effect.delta)
            "trust":
                EventBus.trust_changed.emit(effect.companion, effect.delta)
            "flag_set":
                GameStore.set_flag(effect.flag)  # GameStore is Foundation — allowed
            "mood_set":
                _update_portrait(effect.companion, effect.mood)
```

Flag effects write to GameStore directly (Foundation layer, allowed by ADR-0006). Relationship/trust emit via EventBus for RomanceSocial to handle (Feature layer, no upward import).

### Key Interfaces

```gdscript
extends Node

func start_dialogue(chapter_id: String, sequence_id: String) -> void
# Loads JSON, checks gates, begins playback.
# Emits dialogue_blocked via EventBus if gate fails.
# Emits dialogue_ended via EventBus when sequence completes.
```

### Typewriter Implementation

```gdscript
# Uses RichTextLabel.visible_characters for character-by-character reveal
var _char_timer: float = 0.0
var _target_chars: int = 0

func _process(delta: float) -> void:
    if _state != State.DISPLAYING:
        return
    _char_timer += delta
    var chars_to_show := int(_char_timer * _cps)
    _text_label.visible_characters = mini(chars_to_show, _target_chars)
    if _text_label.visible_characters >= _target_chars:
        _on_typewriter_complete()
```

Tap-to-complete: on touch during DISPLAYING, set `visible_characters = _target_chars` immediately.

## Alternatives Considered

### Alternative 1: Godot Dialogue Manager Addon

- **Description**: Use an existing addon like Dialogue Manager or Dialogic.
- **Pros**: Feature-rich. Community-maintained. Editor integration.
- **Cons**: External dependency. May not support our specific JSON format, choice tiers, or effect system. Addon updates may break compatibility with Godot 4.6. Adds complexity for features we don't need.
- **Rejection Reason**: Our dialogue requirements are specific (4 speaker types, 3 choice tiers, effect emission via EventBus). A custom DialogueRunner is ~300 lines and gives full control. No addon dependency.

### Alternative 2: Ink/Yarn Integration

- **Description**: Use Ink or Yarn narrative scripting languages with a Godot integration.
- **Pros**: Industry-standard narrative tools. Writer-friendly syntax.
- **Cons**: Requires a runtime integration addon. Different data format from the rest of the project (everything else is JSON). Writers would need to learn Ink/Yarn syntax. Integration may not support our specific effect types.
- **Rejection Reason**: Consistency — all game data is JSON. Adding a second scripting language for narrative adds tooling complexity. The JSON node-graph format is simple enough for the solo developer who is also the writer.

## Consequences

### Positive

- **Consistent data format**: Dialogue scripts are JSON, like chapters, enemies, and gift items.
- **Testable**: Load a script, step through nodes, verify effects — all automatable.
- **Decoupled**: DialogueRunner knows nothing about Romance, Story Flow, or Combat. It plays scripts and emits signals.

### Negative

- **No visual editor**: Dialogue graphs are authored in JSON, not a visual node editor. Mitigation: acceptable for solo dev. Consider a visual editor tool if team grows.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| dialogue.md | JSON script format with start entry point (Rule 1) | Node-based JSON graph |
| dialogue.md | 4 speaker types with distinct rendering (Rule 3) | companion, npc, narrator, environment handlers |
| dialogue.md | Typewriter text at configurable CPS (Rule 6) | RichTextLabel.visible_characters + timer |
| dialogue.md | Branching choices max 4 with conditions (Rule 4) | Choice rendering with condition eval at display time |
| dialogue.md | 3 choice tiers: standard, insight, cost (Rule 4b) | Tier-based rendering and gating |
| dialogue.md | Effects: relationship, trust, flag, mood (Rule 5) | _resolve_effects() emits via EventBus |
| dialogue.md | Root-level sequence gating (Rule 7) | Gate check before any UI displays |
| dialogue.md | dialogue_ended / dialogue_blocked signals (Rule 2h/7b) | Emitted via EventBus |
| dialogue.md | Portrait crossfade on mood change (Rule 3e) | _update_portrait() with alpha tween |

## Performance Implications

- **CPU**: JSON parse per sequence: <1ms. Typewriter: 1 visible_characters update per frame. Negligible.
- **Memory**: One Dictionary per loaded script (~5-20KB). One portrait texture loaded at a time (~50KB).
- **Load Time**: Script load: <2ms. Portrait load: <5ms (cached by Godot resource loader).

## Migration Plan

Existing DialogueRunner prototype exists. Refactor: remove internal `_translations` cache (delegate to Localization), emit signals via EventBus, add choice tier support, add root-level gating.

## Validation Criteria

1. **Unit test**: Load script with `"start"` node → state transitions to DISPLAYING.
2. **Unit test**: Script with `requires_met: "artemisa"` and `artemisa.met == false` → `dialogue_blocked` emitted, no UI shown.
3. **Unit test**: Choice with `condition: {type: "flag_set", flag: "test"}` and flag not set → choice hidden.
4. **Unit test**: Effect `{type: "relationship", companion: "artemisa", delta: 5}` → `EventBus.relationship_changed` emitted with correct args.
5. **Integration test**: Full sequence: start → display → choice → effect → next node → END → dialogue_ended emitted.

## Related Decisions

- ADR-0004: EventBus — dialogue signals declared there
- ADR-0005: Localization — all text via get_text()
- ADR-0011 (planned): Story Flow — orchestrates when dialogue sequences play
- `design/gdd/dialogue.md` — complete design spec
