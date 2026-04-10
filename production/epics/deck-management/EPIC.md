# Epic: Deck Manager

> **Layer**: Feature
> **GDD**: design/gdd/deck-management.md
> **Architecture Module**: DeckManager (scene-local Node)
> **Governing ADRs**: ADR-0014
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories deck-management`

## Overview

Deck Management lets the player choose a captain companion before combat and view their 52-card deck. In Story Mode the deck is a standard unmodified set; Abyss Mode will add mutable deck editing. The captain's STR/INT stats produce combat bonuses (chips and mult). The system follows a state machine from captain selection through confirmation and emits `combat_configured` via EventBus to initialize CombatSystem. Signature cards are tagged with companion portraits. Last captain selection is persisted across sessions.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0014: Deck Management -- Captain Selection + Handoff | Scene-local Node managing captain selection, deck building, stat bonus computation, and combat_configured signal emission | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-deck-mgmt-001 | Captain selection flow: highlight -> confirm -> lock; only met companions selectable | ADR-0014 |
| TR-deck-mgmt-002 | combat_configured signal: captain_id, captain_chip_bonus, captain_mult_bonus, deck | ADR-0014 |
| TR-deck-mgmt-003 | Deck Viewer: 52 cards sorted by suit-then-value; signature cards distinguished; read-only in Story Mode | ADR-0014 |
| TR-deck-mgmt-004 | Deck shuffled once at handoff (randomize() + shuffle()); not re-shuffled on viewer | ADR-0014 |
| TR-deck-mgmt-005 | Abyss Mode extension contract: mutable deck API (get_deck, remove_card, add_card, enhance_card) | ADR-0014 |
| TR-deck-mgmt-006 | last_captain_id persisted to SaveData; pre-selected on reopen | ADR-0014 |
| TR-deck-mgmt-007 | Story Mode / Abyss Mode flag read on init to determine edit controls visibility | ADR-0014 |
| TR-deck-mgmt-008 | CardData schema: suit, value, element, enhancement, is_signature, companion_id | ADR-0014 |
| TR-deck-mgmt-009 | State machine: CAPTAIN_SELECT -> COMPANION_HIGHLIGHTED -> CAPTAIN_CONFIRMED -> DECK_VIEWER -> HANDOFF_EMITTED | ADR-0014 |
| TR-deck-mgmt-010 | No captain confirmed = Confirm button disabled; player cannot proceed to combat without captain | ADR-0014 |
| TR-deck-mgmt-011 | Unmet companions visually greyed and non-tappable; all 4 shown | ADR-0014 |
| TR-deck-mgmt-012 | Cancel returns to previous screen without emitting combat_configured | ADR-0014 |
| TR-deck-mgmt-013 | Captain stat bonus computed by Deck Management using Poker Combat formulas and passed in signal | ADR-0014 |
| TR-deck-mgmt-014 | Signature card cosmetic overlay: companion portrait + element glow on matching suit+value card | ADR-0014 |

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, closed via `/story-done`
- All GDD acceptance criteria verified
- Logic/Integration stories have passing tests in `tests/`
- Visual/UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories deck-management` to break this epic into implementable stories.
