# Stories: Dialogue Epic

> **Epic**: Dialogue
> **Layer**: Core
> **Governing ADRs**: ADR-0008, ADR-0006
> **Control Manifest Version**: 2026-04-09
> **Story Count**: 9

---

### STORY-DIALOGUE-001: JSON Script Parser and Sequence Gate Check

- **Type**: Logic
- **TR-IDs**: TR-dialogue-001, TR-dialogue-002, TR-dialogue-003, TR-dialogue-009, TR-dialogue-010, TR-dialogue-015, TR-dialogue-023
- **ADR Guidance**: ADR-0008 — DialogueRunner loads `res://assets/data/dialogue/{chapter_id}/{sequence_id}.json`. Node schema: speaker, speaker_type, text_key, mood, choices, next. Root-level gates: requires_met, requires_romance_stage, requires_flag. Gate fail emits `dialogue_blocked(sequence_id, reason)` via EventBus. Stateless between sequences — no carryover from prior run.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a valid JSON file at the expected path, WHEN `DialogueRunner.start_dialogue(chapter_id, sequence_id)` is called, THEN the script is loaded, parsed, and `current_node_id = "start"` is set. State transitions to Displaying.
  - [ ] AC2: GIVEN a missing JSON file, WHEN `start_dialogue()` is called, THEN a descriptive error is logged, `EventBus.dialogue_blocked.emit(sequence_id, "file_not_found")` is emitted, and state returns to Idle.
  - [ ] AC3: GIVEN a JSON file with no `"start"` node, WHEN loaded, THEN `dialogue_blocked` is emitted with reason `"missing_start_node"`.
  - [ ] AC4: GIVEN `requires_met: "artemis"` in script root and `companion.met == false`, WHEN gates are evaluated, THEN `EventBus.dialogue_blocked.emit(sequence_id, "requires_met")` is emitted with no UI shown.
  - [ ] AC5: GIVEN `requires_romance_stage: {companion: "artemis", min: 2}` and current stage is 1, WHEN gates evaluated, THEN `dialogue_blocked` emitted with reason `"requires_romance_stage"`.
  - [ ] AC6: GIVEN `requires_flag: "gaia_defeated"` and that flag is not set in GameStore, WHEN gates evaluated, THEN `dialogue_blocked` emitted with reason `"requires_flag"`.
  - [ ] AC7: GIVEN all root gates pass, WHEN `start_dialogue()` is called, THEN no `dialogue_blocked` signal is emitted.
  - [ ] AC8: GIVEN DialogueRunner is in Displaying state with an active sequence, WHEN `start_dialogue()` is called with a different sequence ID, THEN the call is rejected (logged warning), the active sequence continues, and state remains unchanged.
  - [ ] AC9: GIVEN a node with both `choices` and `next` populated, WHEN the node is processed, THEN `choices` takes priority, `next` is ignored, and a data warning is logged.
  - [ ] AC10: GIVEN a sequence has just ended (Ended state), WHEN `start_dialogue()` is called again, THEN it succeeds (DialogueRunner returns to Idle before accepting new sequences).
- **Test Evidence**: `tests/unit/dialogue/script_parser_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-DIALOGUE-002: Typewriter Text Animation and Tap Controls

- **Type**: Logic
- **TR-IDs**: TR-dialogue-005, TR-dialogue-011, TR-dialogue-013, TR-dialogue-020
- **ADR Guidance**: ADR-0008 — Typewriter via `RichTextLabel.visible_characters` at configurable CPS (default 40). `{pause:N}` markers stripped from visible output, executed as timed pauses. First tap during animation: completes text (tap consumed). Subsequent same-frame taps ignored. Text length limit 280 characters, truncate at word boundary with `[...]`. CPS loaded from config, not hardcoded.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN dialogue node with text resolved to 80 characters and CPS=40, WHEN display starts, THEN `RichTextLabel.visible_characters` increments at rate 40/sec (full reveal in ~2 seconds).
  - [ ] AC2: GIVEN typewriter is animating, WHEN player taps the dialogue area, THEN `visible_characters` is immediately set to full text length (tap-to-complete). That tap is consumed and does NOT also advance.
  - [ ] AC3: GIVEN multiple taps arrive in the same frame during typewriter animation, WHEN processed, THEN only the first tap is acted upon; subsequent same-frame taps are ignored.
  - [ ] AC4: GIVEN text node containing `{pause:0.5}`, WHEN typewriter reaches the marker, THEN animation pauses for 0.5 seconds, the marker is NOT shown in visible text, then animation continues.
  - [ ] AC5: GIVEN `{pause:5.0}` in text (outside 0.1-3.0 range), WHEN loaded, THEN value is clamped to 3.0 and a content warning is logged.
  - [ ] AC6: GIVEN resolved text of 320 characters (over 280 limit), WHEN the node is processed, THEN text is truncated at the nearest word boundary before 280 characters and `[...]` is appended. A content warning is logged.
  - [ ] AC7: GIVEN CPS value loaded from dialogue config file, WHEN `DialogueRunner` initializes, THEN the typewriter speed is NOT hardcoded in `dialogue_runner.gd`.
  - [ ] AC8: GIVEN typewriter is complete and no choices are present, WHEN player taps the dialogue area, THEN the system advances to the next node.
- **Test Evidence**: `tests/unit/dialogue/typewriter_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-001

---

### STORY-DIALOGUE-003: Speaker Types and Portrait Rendering

- **Type**: UI
- **TR-IDs**: TR-dialogue-006, TR-dialogue-016, TR-dialogue-025
- **ADR Guidance**: ADR-0008 — 4 speaker types: companion (portrait 200x400px left, mood variant, companion state lookup), npc (portrait same dimensions, no state lookup, name via get_text()), narrator (centered italic, no portrait, no name), environment (distinct panel, icon). Portrait crossfade 0.15s between mood changes. Priestess at `res://assets/images/npcs/priestess/priestess_{mood}.png`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a companion node for `"artemis"` with `mood="happy"`, WHEN displayed, THEN portrait at `res://assets/images/companions/artemis/artemis_happy.png` appears in the left portrait slot at 200x400 logical pixels.
  - [ ] AC2: GIVEN an NPC node for `"priestess"` with `mood="neutral"`, WHEN displayed, THEN portrait at `res://assets/images/npcs/priestess/priestess_neutral.png` is shown. Speaker name resolves to `Localization.get_text("COMP_PRIESTESS")`.
  - [ ] AC3: GIVEN a narrator node, WHEN displayed, THEN no portrait is shown, no speaker name label is visible, and text renders centered in italic style.
  - [ ] AC4: GIVEN an environment node, WHEN displayed, THEN no portrait is shown, no speaker name is shown, and text renders in a visually distinct panel with an environmental icon.
  - [ ] AC5: GIVEN two consecutive companion nodes where mood changes from `"neutral"` to `"angry"`, WHEN the second node is displayed, THEN the portrait crossfades over 0.15 seconds. Text rendering does NOT wait for the crossfade to complete.
  - [ ] AC6: GIVEN a companion node where `companion.met == false`, WHEN the node is processed, THEN a data error is logged, the node is skipped, and DialogueRunner advances to `next`.
  - [ ] AC7: GIVEN a portrait image file that does not exist at the resolved path, WHEN the node is displayed, THEN the portrait area is blank (empty), and a missing asset warning is logged. Text and speaker name still display normally.
  - [ ] AC8: GIVEN a companion node with `speaker_type="companion"` but speaker ID not in CompanionRegistry, WHEN processed, THEN a data error is logged, node is skipped.
- **Test Evidence**: `production/qa/evidence/dialogue-speaker-types.md`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-001, STORY-DIALOGUE-002

---

### STORY-DIALOGUE-004: Choice System — Rendering, Tiers, and Tap Handling

- **Type**: UI
- **TR-IDs**: TR-dialogue-007, TR-dialogue-012, TR-dialogue-021, TR-dialogue-022
- **ADR Guidance**: ADR-0008 — Choice panel: vertically stacked, 44px min height per target, max 4 visible choices. Three tiers: standard (always visible unless gated), insight (invisible if condition fails — no "locked" UI), cost (consequence preview text below label). Panel slide-in 0.25s ease-out; tap during animation buffered until complete. All-fail conditions: log warning, emit `dialogue_ended`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a node with 3 choices and all conditions passing, WHEN the choice panel renders, THEN 3 vertically stacked tap targets appear, each at minimum 44px height.
  - [ ] AC2: GIVEN a choice panel is sliding in (0.25s animation), WHEN player taps a choice during the animation, THEN the tap is buffered and processed only after the animation completes.
  - [ ] AC3: GIVEN a `tier="insight"` choice whose condition fails, WHEN the choice panel renders, THEN that choice is completely absent from the panel (not greyed, not locked, not visible).
  - [ ] AC4: GIVEN a `tier="cost"` choice, WHEN rendered, THEN a consequence preview text appears below the choice label text.
  - [ ] AC5: GIVEN 6 choices all passing conditions, WHEN rendered, THEN only the first 4 are shown and a content warning is logged.
  - [ ] AC6: GIVEN all choices on a node fail their conditions, WHEN the panel would render, THEN no panel is shown, a content warning is logged, and `EventBus.dialogue_ended.emit(sequence_id)` is called.
  - [ ] AC7: GIVEN a choice panel is visible, WHEN player taps a choice, THEN the choice panel is dismissed and `DialogueRunner` transitions to Resolving state.
  - [ ] AC8: GIVEN a `tier="standard"` choice with no condition, WHEN rendered, THEN the choice is always visible (no condition evaluation needed).
- **Test Evidence**: `production/qa/evidence/dialogue-choice-panel.md`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-003

---

### STORY-DIALOGUE-005: Choice Condition Evaluation

- **Type**: Logic
- **TR-IDs**: TR-dialogue-018
- **ADR Guidance**: ADR-0008 — Conditions evaluated at render time (not at load). Supported types: romance_stage (companion + min), met (companion), flag_set (flag), flag_not_set (flag), trust_min (companion + value). Conditions read from CompanionState (via GameStore) and Story flags. Failing condition hides choice entirely.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN condition `{type: "romance_stage", companion: "artemis", min: 2}` and Artemis at stage 2, WHEN evaluated, THEN condition PASSES and choice is visible.
  - [ ] AC2: GIVEN same condition but Artemis at stage 1, WHEN evaluated, THEN condition FAILS and choice is hidden.
  - [ ] AC3: GIVEN condition `{type: "met", companion: "nyx"}` and Nyx `met=true`, WHEN evaluated, THEN condition PASSES.
  - [ ] AC4: GIVEN condition `{type: "flag_set", flag: "gaia_defeated"}` and flag is set in GameStore, WHEN evaluated, THEN condition PASSES.
  - [ ] AC5: GIVEN condition `{type: "flag_not_set", flag: "gaia_defeated"}` and flag IS set, WHEN evaluated, THEN condition FAILS.
  - [ ] AC6: GIVEN condition `{type: "trust_min", companion: "hipolita", value: 30}` and Hipolita trust=35, WHEN evaluated, THEN condition PASSES.
  - [ ] AC7: GIVEN condition `{type: "trust_min", companion: "hipolita", value: 30}` and Hipolita trust=29, WHEN evaluated, THEN condition FAILS.
  - [ ] AC8: GIVEN a flag is SET by an earlier node's effect within the same sequence, WHEN a later node's choice condition checks `flag_set` for that same flag, THEN the condition evaluates against the CURRENT flag state (render-time evaluation, not load-time snapshot).
  - [ ] AC9: GIVEN a choice with no `condition` field, WHEN evaluated, THEN the choice always passes (visible by default).
- **Test Evidence**: `tests/unit/dialogue/choice_condition_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-001

---

### STORY-DIALOGUE-006: Effect System — Signal Emission and Flag Writes

- **Type**: Logic
- **TR-IDs**: TR-dialogue-008, TR-dialogue-019
- **ADR Guidance**: ADR-0008 — Effects execute in array order after choice selection. Supported types: relationship (emit EventBus.relationship_changed), trust (emit EventBus.trust_changed), flag_set/flag_clear (write to GameStore directly — Foundation layer allowed), item_grant (emit EventBus.item_granted), mood_set (update portrait immediately). DialogueRunner does NOT apply state changes directly for relationship/trust. Unknown effect types: skip + log warning.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN choice with effect `{type: "relationship", companion: "artemis", delta: 3}`, WHEN the choice is selected, THEN `EventBus.relationship_changed.emit("artemis", 3)` is called.
  - [ ] AC2: GIVEN choice with effect `{type: "trust", companion: "hipolita", delta: -2}`, WHEN selected, THEN `EventBus.trust_changed.emit("hipolita", -2)` is called (not applied directly to GameStore by DialogueRunner).
  - [ ] AC3: GIVEN choice with effect `{type: "flag_set", flag: "gaia_defeated"}`, WHEN selected, THEN GameStore story flags now contains `"gaia_defeated": true`.
  - [ ] AC4: GIVEN choice with effect `{type: "flag_clear", flag: "gaia_defeated"}`, WHEN selected, THEN GameStore story flag `"gaia_defeated"` is cleared (removed or set false).
  - [ ] AC5: GIVEN choice with effect `{type: "item_grant", item_id: "ambrosia", quantity: 2}`, WHEN selected, THEN `EventBus.item_granted.emit("ambrosia", 2)` is called.
  - [ ] AC6: GIVEN choice with effect `{type: "mood_set", companion: "artemis", mood: "happy"}`, WHEN selected, THEN the portrait updates immediately to `artemis_happy.png` within the same dialogue beat (before advancing to next node).
  - [ ] AC7: GIVEN a choice with 3 effects in array, WHEN selected, THEN all 3 effects execute in order (0, 1, 2) before DialogueRunner advances to the next node.
  - [ ] AC8: GIVEN effect array containing an unknown type `{type: "teleport"}`, WHEN processing, THEN that effect is skipped, a warning is logged, and the remaining effects still execute.
  - [ ] AC9: GIVEN Romance & Social is NOT connected to EventBus signals, WHEN relationship signal is emitted, THEN DialogueRunner does not throw an error (fire-and-forget, no listener required).
- **Test Evidence**: `tests/unit/dialogue/effect_system_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-001, STORY-DIALOGUE-005

---

### STORY-DIALOGUE-007: Sequence End and EventBus Signal Integration

- **Type**: Integration
- **TR-IDs**: TR-dialogue-017, TR-dialogue-015
- **ADR Guidance**: ADR-0008 — `dialogue_ended(sequence_id)` and `dialogue_blocked(sequence_id, reason)` emitted via EventBus. DialogueRunner is stateless between sequences — no state carries over. Story Flow listens to these signals to advance narrative nodes.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a sequence where the last node has `next: "END"`, WHEN that node advances, THEN `EventBus.dialogue_ended.emit(sequence_id)` is called and DialogueRunner returns to Idle.
  - [ ] AC2: GIVEN a root gate fails during Loading, WHEN DialogueRunner handles it, THEN `EventBus.dialogue_blocked.emit(sequence_id, reason)` is called and state returns to Idle (no UI shown).
  - [ ] AC3: GIVEN dialogue completes (Ended state), WHEN inspected, THEN all dialogue UI is cleared (portrait hidden, text box empty, choice panel gone).
  - [ ] AC4: GIVEN a mock Story Flow listener connected to `EventBus.dialogue_ended`, WHEN a sequence ends, THEN the mock listener receives the signal with the correct `sequence_id`.
  - [ ] AC5: GIVEN DialogueRunner has just emitted `dialogue_ended` for sequence A, WHEN `start_dialogue()` is called immediately for sequence B, THEN DialogueRunner accepts the call and begins loading sequence B (Idle state reached after Ended).
  - [ ] AC6: GIVEN a forced end triggered externally (e.g., scene transition fires during Displaying), WHEN `DialogueRunner.force_end()` is called, THEN `dialogue_ended` is emitted, UI clears, and any in-flight effects are discarded.
  - [ ] AC7: GIVEN DialogueRunner is Idle between sequences, WHEN GameStore is inspected, THEN no dialogue session state (current_node_id, loaded_script, etc.) persists across sequences.
- **Test Evidence**: `tests/integration/dialogue/eventbus_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-001, STORY-DIALOGUE-006

---

### STORY-DIALOGUE-008: Localization Integration and Text Resolution

- **Type**: Integration
- **TR-IDs**: TR-dialogue-004
- **ADR Guidance**: ADR-0008 — All text resolved via `Localization.get_text(key, params)`. No internal translation cache in DialogueRunner. Raw key returned as fallback if key missing. Control Manifest: never use Godot's built-in `tr()` — always `Localization.get_text()`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a node with `text_key: "CH1_ARTEMISA_01"` and a valid entry in `en.json`, WHEN the node displays, THEN the resolved English text is shown (not the raw key).
  - [ ] AC2: GIVEN a node with `text_key: "CH1_MISSING_KEY"` and no entry in any locale, WHEN displayed, THEN the raw key `"CH1_MISSING_KEY"` is shown as fallback and a localization error is logged.
  - [ ] AC3: GIVEN `text_key` resolves to empty string `""`, WHEN displayed, THEN an empty text box appears, typewriter completes instantly, and advance indicator is shown. A localization warning is logged.
  - [ ] AC4: GIVEN a node with `text_params: {name: "Artemis"}` and `text_key` using an interpolation placeholder, WHEN `get_text(key, params)` is called, THEN the returned string has the parameter substituted.
  - [ ] AC5: GIVEN DialogueRunner source code, WHEN inspected, THEN no calls to `tr()` or direct `i18n/*.json` reads exist — only `Localization.get_text()` is used.
  - [ ] AC6: GIVEN Localization autoload is initialized (boot order #4) before DialogueRunner is used (boot order #9), WHEN text resolution occurs in `_ready()` or on first display, THEN Localization is always ready (no null-ref on Localization).
  - [ ] AC7: GIVEN a choice with `text_key: "CH1_CHOICE_KIND"` and valid locale entry, WHEN the choice renders, THEN the localized string is shown as the tap target label.
- **Test Evidence**: `tests/integration/dialogue/localization_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-001, STORY-DIALOGUE-004

---

### STORY-DIALOGUE-009: Accessibility — AccessKit Screen Reader Support

- **Type**: Integration
- **TR-IDs**: TR-dialogue-014
- **ADR Guidance**: ADR-0008 — Screen reader support via AccessKit (Godot 4.5+). Dialogue text and choice labels must be accessible to screen readers. MEDIUM engine knowledge risk (AccessKit is post-cutoff API — verify behavior on Godot 4.6 before shipping).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a screen reader is active on the test device, WHEN a dialogue node displays, THEN the typewriter text is accessible (RichTextLabel exposes text to AccessKit).
  - [ ] AC2: GIVEN a choice panel is visible, WHEN a screen reader is active, THEN each choice tap target is announced with its localized label text.
  - [ ] AC3: GIVEN the speaker name label is visible, WHEN a screen reader is active, THEN the speaker name is announced before the dialogue text.
  - [ ] AC4: GIVEN portrait images displayed, WHEN a screen reader is active, THEN portraits have a descriptive `alt_text` (or equivalent AccessKit property) set to speaker name + mood (e.g., "Artemis, happy expression").
  - [ ] AC5: GIVEN narrator or environment nodes (no portrait, no name label), WHEN a screen reader is active, THEN the text content is still announced correctly without crashing on a missing speaker label node.
- **Test Evidence**: `production/qa/evidence/dialogue-accessibility.md`
- **Status**: Ready
- **Depends On**: STORY-DIALOGUE-003, STORY-DIALOGUE-004
