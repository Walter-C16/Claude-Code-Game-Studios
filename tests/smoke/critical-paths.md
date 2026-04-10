# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to splash screen without crash
2. New Game starts a fresh session; Continue loads existing save
3. Hub screen displays with all 4 tab navigation working

## Core Mechanic (update per sprint)

4. Poker combat: deal hand, play cards, score resolves correctly
5. Dialogue: typewriter text displays, choices appear, effects apply
6. Camp: companion grid shows met companions, talk interaction works

## Data Integrity

7. Save game completes without error (dirty-flag flush)
8. Load game restores correct companion state and story progress
9. New Game with existing save shows confirmation dialog

## Performance

10. No visible frame rate drops below 30fps during transitions
11. No memory growth over 5 minutes of hub navigation
