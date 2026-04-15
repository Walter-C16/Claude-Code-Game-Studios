class_name CompanionLevel
extends RefCounted

## CompanionLevel — XP → Level → stat-bonus utility for party members.
##
## Pure static logic. No autoload access, no node tree coupling, so the
## formulas are unit-testable in isolation and cannot drift from the design
## spec at `design/quick-specs/companion-leveling.md`.
##
## Level is always derived from XP. Never store level separately — XP is the
## single source of truth on GameStore._companion_xp.
##
## Layering in BattleManager.setup:
##   base stats → level bonuses (this class) → blessings → Epithets (v2)

# ── Constants ────────────────────────────────────────────────────────────────

## Hard ceiling. XP past the level 20 threshold plateaus — the counter keeps
## accumulating but the level stops climbing.
const LEVEL_CAP: int = 20

## Coefficient for the XP curve `xp_total_for_level(L) = XP_COEFFICIENT * L * (L - 1)`.
## Delta between two adjacent levels is `2 * XP_COEFFICIENT * L`.
const XP_COEFFICIENT: int = 25

## Per-level stat bonuses (additive, applied after base stats, before blessings).
const HP_PER_LEVEL: int = 6
const ATK_PER_LEVEL: int = 1

## DEF grows by 1 every 2 levels (+0.5 per level amortized).
const DEF_LEVELS_PER_POINT: int = 2

## AGI grows by 1 every 5 levels.
const AGI_LEVELS_PER_POINT: int = 5

## Crit chance grows by 1 percentage point every 5 levels.
const CRIT_CHANCE_LEVELS_PER_POINT: int = 5
const CRIT_CHANCE_PER_MILESTONE: float = 1.0

## Crit damage grows by 5 percentage points every 10 levels.
const CRIT_DMG_LEVELS_PER_POINT: int = 10
const CRIT_DMG_PER_MILESTONE: float = 5.0


# ── XP ↔ Level ────────────────────────────────────────────────────────────────

## Cumulative XP required to reach [param level]. Level 1 starts at 0 XP.
## Clamped at the cap — requesting a level above LEVEL_CAP returns the cap's
## threshold (so UI bars don't overflow on grinders).
static func xp_total_for_level(level: int) -> int:
	var l: int = clampi(level, 1, LEVEL_CAP)
	return XP_COEFFICIENT * l * (l - 1)


## Derives the level for [param xp]. Returns 1 at xp=0, 20 at or above the
## cap's threshold. Uses an iterative walk instead of the quadratic inverse
## to avoid float rounding on exact thresholds.
static func xp_to_level(xp: int) -> int:
	if xp <= 0:
		return 1
	var level: int = 1
	while level < LEVEL_CAP and xp >= xp_total_for_level(level + 1):
		level += 1
	return level


## XP needed to reach the next level. Returns 0 when the companion is at cap.
static func xp_needed_for_next(current_level: int) -> int:
	if current_level >= LEVEL_CAP:
		return 0
	return xp_total_for_level(current_level + 1) - xp_total_for_level(current_level)


## XP earned into the current level (i.e. distance above the current level's
## threshold). Returns 0 at cap so the UI can show "MAX".
static func xp_into_current_level(xp: int) -> int:
	var level: int = xp_to_level(xp)
	if level >= LEVEL_CAP:
		return 0
	return xp - xp_total_for_level(level)


# ── Stat bonuses ─────────────────────────────────────────────────────────────

static func hp_bonus_for_level(level: int) -> int:
	return (clampi(level, 1, LEVEL_CAP) - 1) * HP_PER_LEVEL


static func atk_bonus_for_level(level: int) -> int:
	return (clampi(level, 1, LEVEL_CAP) - 1) * ATK_PER_LEVEL


static func def_bonus_for_level(level: int) -> int:
	return (clampi(level, 1, LEVEL_CAP) - 1) / DEF_LEVELS_PER_POINT


static func agi_bonus_for_level(level: int) -> int:
	return (clampi(level, 1, LEVEL_CAP) - 1) / AGI_LEVELS_PER_POINT


static func crit_chance_bonus_for_level(level: int) -> float:
	var steps: int = (clampi(level, 1, LEVEL_CAP) - 1) / CRIT_CHANCE_LEVELS_PER_POINT
	return float(steps) * CRIT_CHANCE_PER_MILESTONE


static func crit_damage_bonus_for_level(level: int) -> float:
	var steps: int = (clampi(level, 1, LEVEL_CAP) - 1) / CRIT_DMG_LEVELS_PER_POINT
	return float(steps) * CRIT_DMG_PER_MILESTONE


## Mutates [param stats] in place, stacking level bonuses onto the base
## values read from JSON. Snaps current_hp to the new max so a freshly-built
## combatant enters battle at full HP (same pattern as blessings).
## Safe to call with level 1 — all bonuses are 0 and nothing changes.
static func apply_to_stats(stats: BattleStats, level: int) -> void:
	if stats == null:
		return
	var l: int = clampi(level, 1, LEVEL_CAP)
	stats.max_hp += hp_bonus_for_level(l)
	stats.atk += atk_bonus_for_level(l)
	stats.def_stat += def_bonus_for_level(l)
	stats.agi += agi_bonus_for_level(l)
	stats.crit_chance += crit_chance_bonus_for_level(l)
	stats.crit_damage += crit_damage_bonus_for_level(l)
	stats.current_hp = stats.max_hp
