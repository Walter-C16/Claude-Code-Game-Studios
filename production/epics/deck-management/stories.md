# Stories: Deck Management

> **Epic**: deck-management
> **Layer**: Feature
> **ADR**: ADR-0014
> **Manifest Version**: 2026-04-09
> **Total Stories**: 6

---

### STORY-DM-001: CardData Schema and Deck Builder

- **Type**: Logic
- **TR-IDs**: TR-deck-mgmt-003, TR-deck-mgmt-004, TR-deck-mgmt-008
- **ADR Guidance**: DeckManager is a scene-local Node. `build_deck()` returns 52 cards sorted by suit-then-value in Story Mode. `CardData` schema: `suit`, `value`, `element`, `enhancement`, `is_signature`, `companion_id`. Deck shuffled once at handoff via `Array.shuffle()` — not on Deck Viewer open. Read-only in Story Mode.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `build_deck()` is called, WHEN the result is inspected, THEN exactly 52 dicts are returned covering 4 suits x 13 values (2-14).
  - [ ] AC2: GIVEN a built deck, WHEN each card dict is inspected, THEN all 6 schema fields are present: `suit`, `value`, `element`, `enhancement`, `is_signature`, `companion_id`.
  - [ ] AC3: GIVEN each companion has a signature card, WHEN the deck is built with captain="artemisa", THEN exactly one card has `is_signature=true` and `companion_id="artemisa"`.
  - [ ] AC4: GIVEN `build_deck()` returns an unshuffled deck (sorted by suit-then-value), WHEN `handoff()` is called, THEN `Array.shuffle()` is called exactly once on the deck before emitting the signal.
  - [ ] AC5: GIVEN the Deck Viewer is opened after handoff, THEN `Array.shuffle()` is not called again — viewer displays the deck in its current (post-shuffle) state.
- **Test Evidence**: `tests/unit/deck_management/deck_builder_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-DM-002: Captain Stat Bonus Computation

- **Type**: Logic
- **TR-IDs**: TR-deck-mgmt-002, TR-deck-mgmt-013
- **ADR Guidance**: `get_captain_chip_bonus(str_val)` = `floor(STR * 0.5)`. `get_captain_mult_bonus(int_val)` = `1.0 + (INT * 0.025)`. Formulas sourced from Poker Combat GDD. Bonuses passed in `combat_configured` signal payload.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `get_captain_chip_bonus(10)` is called, THEN it returns 5 (floor(10 * 0.5)).
  - [ ] AC2: GIVEN `get_captain_chip_bonus(7)` is called, THEN it returns 3 (floor(7 * 0.5) = floor(3.5) = 3).
  - [ ] AC3: GIVEN `get_captain_mult_bonus(8)` is called, THEN it returns 1.2 (1.0 + 8 * 0.025).
  - [ ] AC4: GIVEN `get_captain_mult_bonus(0)` is called, THEN it returns 1.0.
  - [ ] AC5: GIVEN these formulas are implemented, THEN no literals `0.5` or `0.025` appear as hardcoded values in the method body — they must come from config or a named constant defined in the data layer.
- **Test Evidence**: `tests/unit/deck_management/captain_bonus_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-DM-003: Captain Selection State Machine

- **Type**: Logic
- **TR-IDs**: TR-deck-mgmt-001, TR-deck-mgmt-006, TR-deck-mgmt-009, TR-deck-mgmt-010, TR-deck-mgmt-011, TR-deck-mgmt-012
- **ADR Guidance**: State machine: CAPTAIN_SELECT → COMPANION_HIGHLIGHTED → CAPTAIN_CONFIRMED → DECK_VIEWER ↕ → HANDOFF_EMITTED. Only `met` companions are selectable; unmet companions visible but greyed and non-tappable. No captain = Confirm disabled. Cancel returns without emitting. `last_captain_id` persisted to SaveData; pre-selected on reopen.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN state is CAPTAIN_SELECT and a met companion is tapped, WHEN the tap is handled, THEN state transitions to COMPANION_HIGHLIGHTED and that companion's card is highlighted.
  - [ ] AC2: GIVEN an unmet companion is tapped, WHEN the tap is handled, THEN state does not change and no highlight occurs.
  - [ ] AC3: GIVEN state is COMPANION_HIGHLIGHTED, WHEN the Confirm button is tapped, THEN state transitions to CAPTAIN_CONFIRMED and the Confirm button becomes active.
  - [ ] AC4: GIVEN state is CAPTAIN_SELECT (no companion highlighted), WHEN the Confirm button is inspected, THEN it is disabled (greyed, non-tappable).
  - [ ] AC5: GIVEN state is CAPTAIN_CONFIRMED, WHEN Cancel is tapped, THEN state returns to CAPTAIN_SELECT and no `combat_configured` signal is emitted.
  - [ ] AC6: GIVEN a captain was selected in a previous session, WHEN DeckManager initializes, THEN `last_captain_id` is read from SaveData and that companion starts highlighted (COMPANION_HIGHLIGHTED state).
- **Test Evidence**: `tests/unit/deck_management/captain_state_machine_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DM-001, STORY-DM-002

---

### STORY-DM-004: combat_configured Signal Emission and Handoff

- **Type**: Integration
- **TR-IDs**: TR-deck-mgmt-002, TR-deck-mgmt-004, TR-deck-mgmt-006, TR-deck-mgmt-007
- **ADR Guidance**: `combat_configured` signal emitted via EventBus with payload: `{captain_id, captain_chip_bonus, captain_mult_bonus, deck: Array[Dictionary]}`. Deck shuffled at handoff. `last_captain_id` persisted to SaveData before emission. Story Mode / Abyss Mode flag read on init to determine edit controls visibility.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN state is CAPTAIN_CONFIRMED and the player confirms, WHEN `handoff()` is called, THEN `EventBus.combat_configured` is emitted with a payload containing `captain_id`, `captain_chip_bonus`, `captain_mult_bonus`, and `deck`.
  - [ ] AC2: GIVEN the signal payload, WHEN `deck` is inspected, THEN it contains exactly 52 cards and the order is shuffled (not sorted by suit-then-value).
  - [ ] AC3: GIVEN the signal is emitted, WHEN GameStore is checked, THEN `last_captain_id` was written before the signal fired.
  - [ ] AC4: GIVEN the game is in Story Mode, WHEN DeckManager initializes, THEN deck edit controls (add/remove/enhance card buttons) are hidden or absent.
  - [ ] AC5: GIVEN the game is in Abyss Mode, WHEN DeckManager initializes, THEN deck edit controls are visible (stub implementation acceptable for this milestone).
- **Test Evidence**: `tests/integration/deck_management/combat_configured_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DM-003

---

### STORY-DM-005: Deck Viewer UI — 52-Card Display and Signature Card Overlay

- **Type**: UI
- **TR-IDs**: TR-deck-mgmt-003, TR-deck-mgmt-014
- **ADR Guidance**: Deck Viewer is a read-only overlay in Story Mode. Cards sorted by suit-then-value in viewer (display order, not shuffle order). Signature card cosmetic overlay: companion portrait + element glow on matching suit+value card. All Control nodes inherit shared Theme .tres. Touch targets >= 44x44px.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Deck Viewer opens, WHEN the card grid renders, THEN all 52 cards are displayed sorted by suit-then-value.
  - [ ] AC2: GIVEN the captain's signature card, WHEN the viewer renders, THEN that card shows a companion portrait overlay and an element glow (color matching the companion's element).
  - [ ] AC3: GIVEN Story Mode is active, WHEN the Deck Viewer is open, THEN no edit actions (remove, enhance) are available — the view is read-only.
  - [ ] AC4: GIVEN all UI elements in the Deck Viewer, THEN no hardcoded color values exist; all reference theme tokens.
  - [ ] AC5: GIVEN the DECK_VIEWER state is active and the player taps Back, THEN state returns to CAPTAIN_CONFIRMED and the Deck Viewer overlay closes.
- **Test Evidence**: `production/qa/evidence/deck-management/deck-viewer-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-DM-003

---

### STORY-DM-006: Captain Selection UI — Companion Grid and Confirmation Screen

- **Type**: UI
- **TR-IDs**: TR-deck-mgmt-001, TR-deck-mgmt-011
- **ADR Guidance**: All 4 companions shown regardless of met status. Unmet companions visually greyed and non-tappable (not hidden). Met companions fully interactive. Confirm button state reflects selection. All Control nodes inherit shared Theme .tres. Touch targets >= 44x44px. Primary actions in bottom 560px.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Captain Select screen opens, WHEN rendered, THEN all 4 companions are visible (met and unmet alike).
  - [ ] AC2: GIVEN an unmet companion card, WHEN displayed, THEN it is visually greyed and tap events do not trigger highlight.
  - [ ] AC3: GIVEN a met companion is highlighted, WHEN the Confirm button is inspected, THEN it is enabled and tappable.
  - [ ] AC4: GIVEN the Confirm button and Back button, THEN both are positioned within the bottom 560px of the 430x932 viewport.
  - [ ] AC5: GIVEN all interactive touch targets on this screen, THEN each is >= 44x44px.
  - [ ] AC6: GIVEN all UI elements on this screen, THEN no hardcoded color values exist; all reference theme tokens.
- **Test Evidence**: `production/qa/evidence/deck-management/captain-select-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-DM-003
