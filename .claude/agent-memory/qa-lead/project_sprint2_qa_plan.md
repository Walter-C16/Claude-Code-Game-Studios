---
name: Sprint 2 QA Plan
description: Sprint 2 covers the Core layer — 29 stories across Companion Data, Enemy Data, Poker Combat, and Dialogue epics. QA plan written 2026-04-10.
type: project
---

Sprint 2 QA plan generated 2026-04-10 at production/qa/qa-plan-sprint-2-2026-04-10.md.

29 stories: 19 Logic (BLOCKING unit tests), 7 Integration (BLOCKING integration tests), 3 UI (ADVISORY manual evidence).

Gate breakdown:
- Logic: COMPANION-001 to 004, ENEMY-001 to 002, COMBAT-001 to 009, DIALOGUE-001, 002, 005, 006
- Integration: COMPANION-005, ENEMY-003, COMBAT-010, 012, DIALOGUE-007, 008, 009
- UI: COMBAT-011, DIALOGUE-003, 004

DIALOGUE-009 (AccessKit) is elevated to BLOCKING despite being Integration type — requires lead sign-off due to HIGH Godot 4.5+ API risk.

**Why:** Core layer introduces the first playable poker-combat loop and dialogue system. All math (scoring pipeline, element interactions, hand evaluation) requires BLOCKING automated tests before the layer is considered stable.

**How to apply:** At sprint review, block completion of any Logic or Integration story that lacks its test file. Do not accept "tests coming in follow-up" for these story types.
