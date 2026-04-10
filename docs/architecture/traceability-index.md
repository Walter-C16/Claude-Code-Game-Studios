# Architecture Traceability Index

> **Last Updated:** 2026-04-10
> **Engine:** Godot 4.6
> **Source:** /architecture-review (full mode — verification rerun)
> **TR Registry Version:** 3

## Coverage Summary

- **Total requirements:** 202
- **Covered:** 202 (100%) — all systems have Accepted ADRs
- **Partial:** 0
- **Gaps:** 0

## Full Matrix

| System | Layer | TR Count | ADR(s) | ADR Status | Coverage |
|--------|-------|----------|--------|------------|----------|
| companion-data | Foundation | 14 | ADR-0001, ADR-0009 | Accepted | Covered |
| enemy-data | Foundation | 9 | ADR-0016 | Accepted | Covered |
| save-system | Foundation | 16 | ADR-0001, ADR-0002 | Accepted | Covered |
| localization | Foundation | 15 | ADR-0005 | Accepted | Covered |
| ui-theme | Foundation | 20 | ADR-0013 | Accepted | Covered |
| scene-nav | Foundation | 17 | ADR-0003 | Accepted | Covered |
| poker-combat | Core | 33 | ADR-0007 | Accepted | Covered |
| dialogue | Core | 25 | ADR-0008 | Accepted | Covered |
| deck-mgmt | Core | 14 | ADR-0014 | Accepted | Covered |
| romance-social | Feature | 28 | ADR-0010 | Accepted | Covered |
| story-flow | Feature | 21 | ADR-0011 | Accepted | Covered |
| divine-blessings | Feature | 17 | ADR-0012 | Accepted | Covered |
| camp | Feature | 14 | ADR-0010, ADR-0015 | Accepted | Covered |

Cross-cutting ADRs: ADR-0001 (GameStore), ADR-0004 (EventBus), ADR-0006 (Boot Order)

## ADR Implementation Order

| Tier | ADRs | Can Parallel |
|------|------|-------------|
| 0 (no deps) | ADR-0001 GameStore, ADR-0004 EventBus, ADR-0013 UI Theme | Yes |
| 1 (Foundation) | ADR-0002 Save, ADR-0003 Scene, ADR-0005 Localization | Yes |
| 2 (Core) | ADR-0006 Boot, ADR-0009 Companion, ADR-0016 Enemy, ADR-0008 Dialogue | Yes |
| 3 (Core+Feature) | ADR-0007 Combat, ADR-0010 Romance | Yes |
| 4 (Feature) | ADR-0011 Story, ADR-0012 Blessings, ADR-0014 Deck, ADR-0015 Gifts | Yes |

## Known Gaps

None. All 202 requirements covered by Accepted ADRs.

## Non-Blocking Observations

1. ADR-0009 code sample references `GameStore.set_relationship_level()` (should be `_set_relationship_level()`)
2. ADR-0014 Context paragraph stale re: EventBus routing
3. architecture.md has 4 stale sections (ADR Audit, Required ADRs, Open Questions, TR baseline)

## Superseded Requirements

None. No requirements deprecated or superseded.

## History

| Date | Total | Covered % | Registry Version | Verdict | Notes |
|------|-------|-----------|-----------------|---------|-------|
| 2026-04-09 | 202 | 95.5% | v3 | CONCERNS | 3 blocking conflicts, ADR-0016 Proposed |
| 2026-04-10 | 202 | 100% | v3 | **PASS** | All fixes verified, 0 conflicts |
