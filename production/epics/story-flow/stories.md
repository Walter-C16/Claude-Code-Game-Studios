# Stories: Story Flow

> **Epic**: story-flow
> **Layer**: Feature
> **ADR**: ADR-0011
> **Manifest Version**: 2026-04-09
> **Total Stories**: 8

---

### STORY-SF-001: Chapter JSON Data — Schema, Loading, and Validation

- **Type**: Logic
- **TR-IDs**: TR-story-flow-001, TR-story-flow-011, TR-story-flow-012, TR-story-flow-013, TR-story-flow-014
- **ADR Guidance**: Chapter files at `res://assets/data/story/ch{NN}.json`. Schema: id, type, title_key, sequence_id, enemy_id, defeat_mode, post_combat_sequence_id, requires_flags, sets_flags, unlocks_companions, reward, next. No reward values, flag names, or node sequences hardcoded outside JSON. Parse within 50ms for 12-node chapter.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `load_chapter("ch01")` is called, WHEN the file exists and is valid JSON, THEN a chapter dict is returned with an `id` and a `nodes` array within 50ms.
  - [ ] AC2: GIVEN a chapter file with all 14 schema fields, WHEN parsed, THEN each node dict exposes all fields (absent fields default to null/empty rather than crashing).
  - [ ] AC3: GIVEN `load_chapter("ch99")` is called and the file does not exist, WHEN parsing fails, THEN `get_chapter_state()` returns a "to_be_continued" state and no crash occurs.
  - [ ] AC4: GIVEN a node's `reward` field contains `{"gold": 10, "xp": 30}`, WHEN the chapter is loaded, THEN neither the gold value nor the xp value appears as a literal in any `.gd` file.
  - [ ] AC5: GIVEN Chapter 1 is loaded, THEN exactly 10 nodes (ch01_n00 through ch01_n09) are present.
- **Test Evidence**: `tests/unit/story_flow/chapter_json_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-SF-002: Node State Machine — Transitions and GameStore Persistence

- **Type**: Logic
- **TR-IDs**: TR-story-flow-003, TR-story-flow-004, TR-story-flow-005, TR-story-flow-010, TR-story-flow-016
- **ADR Guidance**: Node states: not_started → in_progress → completed (terminal). No backward transitions. `node_states` dict, `current_node_id`, `story_flags`, `player_gold`, `player_xp` persisted in GameStore. Mixed/combat nodes resume from beginning on force-quit (in_progress state is checkpointed).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a node in `not_started` state, WHEN `enter_node(node_id)` is called, THEN state transitions to `in_progress` and `current_node_id` is written to GameStore.
  - [ ] AC2: GIVEN a node in `in_progress` state, WHEN completion conditions are met, THEN state transitions to `completed` and the transition is persisted atomically with reward distribution.
  - [ ] AC3: GIVEN a node already in `completed` state, WHEN `enter_node(node_id)` is called, THEN no transition occurs and no rewards are re-distributed.
  - [ ] AC4: GIVEN the app is force-quit while a node is `in_progress`, WHEN the game reloads, THEN the node is still `in_progress` and re-execution begins from the node's start (not mid-node).
  - [ ] AC5: GIVEN story_flags are stored as write-once strings, WHEN a flag that already exists is set again, THEN `GameStore.set_flag()` is idempotent (no duplicate, no error).
- **Test Evidence**: `tests/unit/story_flow/node_state_machine_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SF-001

---

### STORY-SF-003: Flag Gating and Prerequisite Checking

- **Type**: Logic
- **TR-IDs**: TR-story-flow-003, TR-story-flow-005, TR-story-flow-015, TR-story-flow-017
- **ADR Guidance**: `get_available_nodes()` checks `requires_flags` + previous node completed. Write-once flags in `GameStore.story_flags`. Dialogue `set_flag` effects may only set flags declared in the active node's `sets_flags`; undeclared flags are dropped with a warning. Chapter 1 defines 11 canonical flags.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN node requires_flags=["forest_monster_defeated"] and the flag is not set, WHEN `get_available_nodes()` is evaluated, THEN this node is not included in the available set.
  - [ ] AC2: GIVEN all `requires_flags` are present and the previous node is completed, WHEN `get_available_nodes()` is evaluated, THEN the node is included.
  - [ ] AC3: GIVEN a dialogue effect attempts `set_flag("undeclared_flag")` where "undeclared_flag" is not in the active node's `sets_flags`, WHEN the effect fires, THEN the flag is dropped and a warning is logged.
  - [ ] AC4: GIVEN Chapter 1 fully completes, WHEN all flags are inspected, THEN exactly 11 canonical flags are set (none more, none fewer).
  - [ ] AC5: GIVEN `requires_flags=[]` (empty), WHEN `get_available_nodes()` runs, THEN the flag prerequisite check passes unconditionally.
- **Test Evidence**: `tests/unit/story_flow/flag_gating_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SF-002

---

### STORY-SF-004: Reward Distribution — Atomic Gold, XP, and Flag Setting on Completion

- **Type**: Logic
- **TR-IDs**: TR-story-flow-007, TR-story-flow-012
- **ADR Guidance**: Rewards granted atomically when node transitions to COMPLETED. Gold and XP added to GameStore. Autosave triggered. Node reward values are flat from chapter JSON — no formulas. No reward values hardcoded outside JSON.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a node completes with reward `{"gold": 10, "xp": 30}`, WHEN the completion handler fires, THEN `GameStore.add_gold(10)` and `GameStore.add_xp(30)` are both called before the next node is made available.
  - [ ] AC2: GIVEN a node completes, WHEN rewards are distributed, THEN `sets_flags` entries are written to GameStore atomically in the same operation as the reward.
  - [ ] AC3: GIVEN a node completes with reward `{"gold": 0, "xp": 0}`, WHEN the completion handler fires, THEN no crash and state remains consistent.
  - [ ] AC4: GIVEN reward distribution completes, WHEN checked, THEN SaveManager autosave is triggered within the same frame.
  - [ ] AC5: GIVEN the reward values for any node, THEN no numeric literal matching those values appears in any `.gd` file — all sourced from chapter JSON.
- **Test Evidence**: `tests/unit/story_flow/reward_distribution_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SF-002

---

### STORY-SF-005: Node Type Execution — Dialogue, Combat, and Companion Unlock

- **Type**: Integration
- **TR-IDs**: TR-story-flow-002, TR-story-flow-006, TR-story-flow-008, TR-story-flow-009, TR-story-flow-018, TR-story-flow-021
- **ADR Guidance**: StoryFlow calls DialogueRunner for `dialogue` nodes, SceneManager for `combat` nodes, and sets `met=true` for `companion_unlock` nodes. Listens for `combat_completed` and `dialogue_ended` via EventBus to advance. Combat defeat with `defeat_mode: retry` keeps node in_progress. Boss nodes signal boss music + boss HP bar activation. Chapter completion sets flag + writes `current_chapter` + emits `chapter_completed`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a `dialogue` node is entered, WHEN `enter_node()` runs, THEN `DialogueRunner.start_dialogue(sequence_id)` is called and StoryFlow awaits `dialogue_ended` via EventBus.
  - [ ] AC2: GIVEN a `combat` node is entered, WHEN `enter_node()` runs, THEN `SceneManager.change_scene(SceneId.COMBAT, config)` is called with the node's `enemy_id`.
  - [ ] AC3: GIVEN a `combat` node with `defeat_mode: retry` and combat_completed fires with result.victory=false, WHEN handled, THEN node state remains `in_progress` and the Chapter Map is shown with a retry prompt.
  - [ ] AC4: GIVEN a `companion_unlock` node completes, WHEN the handler fires, THEN `CompanionState.set_met(companion_id, true)` is called and the reveal animation plays.
  - [ ] AC5: GIVEN a `boss` node is entered, WHEN `enter_node()` runs, THEN EventBus emits a boss music signal and a boss HP bar activation signal.
  - [ ] AC6: GIVEN all nodes in a chapter reach `completed`, WHEN evaluated, THEN `chapter_completed` is emitted via EventBus, the chapter flag is set, and `GameStore.current_chapter` is updated.
- **Test Evidence**: `tests/integration/story_flow/node_type_execution_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SF-003, STORY-SF-004

---

### STORY-SF-006: Mixed and Boss Node Sequences — Multi-Phase Execution

- **Type**: Integration
- **TR-IDs**: TR-story-flow-002, TR-story-flow-010
- **ADR Guidance**: `mixed` node executes: dialogue → combat → post_combat_dialogue → rewards + flags. `boss` node: pre_dialogue → combat (boss music) → post_dialogue → rewards + flags. Force-quit during either causes resume from node start. StoryFlow is the orchestrator and must not be called back by combat/dialogue (they don't call StoryFlow).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a `mixed` node is entered, WHEN the sequence runs, THEN pre-combat dialogue fires first, then `SceneManager.change_scene(COMBAT)`, then post-combat dialogue after `combat_completed`, then rewards.
  - [ ] AC2: GIVEN a `boss` node is entered, WHEN the sequence runs, THEN pre-dialogue fires, then combat with boss music active, then post-dialogue after victory.
  - [ ] AC3: GIVEN a mixed node is in `in_progress` (force-quit recovery), WHEN `enter_node()` is called on load, THEN execution restarts from the node's beginning (pre-combat dialogue), not from mid-sequence.
  - [ ] AC4: GIVEN DialogueRunner and CombatSystem complete their phases, THEN neither system calls back into StoryFlow directly — all coordination flows through EventBus signals.
- **Test Evidence**: `tests/integration/story_flow/mixed_boss_node_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SF-005

---

### STORY-SF-007: Chapter Map UI — Node Display, State Gating, and Reward Panel

- **Type**: UI
- **TR-IDs**: TR-story-flow-019, TR-story-flow-020
- **ADR Guidance**: Presentation layer only. Completed nodes greyed and non-tappable (not hidden). Reward panel slides up with gold + XP display, 3s auto-dismiss or tap. All Control nodes inherit shared Theme .tres. Primary actions in bottom 560px. Touch targets >= 44x44px.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a node is in `completed` state, WHEN the Chapter Map renders, THEN the node card is visually greyed and tap events are ignored (not hidden).
  - [ ] AC2: GIVEN a node is available (prerequisites met, not completed), WHEN the player taps it, THEN `StoryFlow.enter_node(node_id)` is called.
  - [ ] AC3: GIVEN a node completes and rewards are distributed, WHEN the reward panel shows, THEN it slides up from the bottom, displays gold and XP amounts, and auto-dismisses after 3 seconds or on tap.
  - [ ] AC4: GIVEN the Chapter Map is displayed, THEN no hardcoded color values exist in the scene — all reference theme tokens.
  - [ ] AC5: GIVEN all tappable node cards, THEN each has a minimum 44x44px touch target hitbox.
- **Test Evidence**: `production/qa/evidence/story-flow/chapter-map-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-SF-005

---

### STORY-SF-008: StoryFlow Autoload — Boot Wiring and EventBus Integration

- **Type**: Integration
- **TR-IDs**: TR-story-flow-011, TR-story-flow-016
- **ADR Guidance**: StoryFlow is an autoload. Depends on ADR-0001, ADR-0003, ADR-0004, ADR-0008, ADR-0009 — most upstream dependencies of any Feature system. Must not reference later autoloads in `_ready()`. `node_states`, `current_node_id`, `story_flags`, `player_gold`, `player_xp` all in GameStore.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the game boots, WHEN StoryFlow's `_ready()` runs, THEN it connects to EventBus signals (`combat_completed`, `dialogue_ended`) without referencing any autoload placed after it in boot order.
  - [ ] AC2: GIVEN `load_chapter("ch01")` is called with a valid 12-node file, WHEN parsing completes, THEN it finishes within 50ms (measured via `Time.get_ticks_msec()`).
  - [ ] AC3: GIVEN story state (`node_states`, `current_node_id`, `story_flags`) is written to GameStore, WHEN a save/load cycle completes, THEN all fields round-trip correctly.
  - [ ] AC4: GIVEN StoryFlow is the orchestrator, THEN no other system (DialogueRunner, CombatSystem, Camp) holds a direct reference to StoryFlow — all communication is via EventBus signals.
- **Test Evidence**: `tests/integration/story_flow/autoload_wiring_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SF-005, STORY-SF-006
