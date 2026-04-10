# Stories: Enemy Data Epic

> **Epic**: Enemy Data
> **Layer**: Core
> **Governing ADRs**: ADR-0016
> **Control Manifest Version**: 2026-04-09
> **Story Count**: 3

---

### STORY-ENEMY-001: EnemyRegistry Autoload — Static Profile Loading and Typed Getters

- **Type**: Logic
- **TR-IDs**: TR-enemy-data-001, TR-enemy-data-002, TR-enemy-data-003, TR-enemy-data-006, TR-enemy-data-007
- **ADR Guidance**: ADR-0016 — EnemyRegistry is autoload #8 in boot order. Loads `res://assets/data/enemies.json` at `_ready()`. Exposes `get_enemy(id)`, `get_all_ids()`, `get_enemies_by_chapter(chapter)`. Enemy type is an enum: Normal, Boss, Duel, Abyss. Display names are i18n keys, resolved by callers via Localization. Must not reference autoloads later than #8.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `enemies.json` exists at `res://assets/data/enemies.json`, WHEN EnemyRegistry `_ready()` runs, THEN all Chapter 1 enemies (forest_monster, mountain_beast, amazon_challenger, gaia_spirit) are loaded into the internal dictionary.
  - [ ] AC2: GIVEN enemy ID `"mountain_beast"`, WHEN `get_enemy("mountain_beast")` is called, THEN returns a Dictionary with: `id="mountain_beast"`, `hp=80`, `score_threshold=50`, `element=null`, `type="Normal"`, `name_key="ENEMY_MOUNTAIN_BEAST"`.
  - [ ] AC3: GIVEN enemy ID `"amazon_challenger"`, WHEN `get_enemy("amazon_challenger")` is called, THEN `element="Fire"` and `type="Duel"`.
  - [ ] AC4: GIVEN an unknown enemy ID `"cronos"`, WHEN `get_enemy("cronos")` is called, THEN returns empty Dictionary `{}` (no crash).
  - [ ] AC5: GIVEN EnemyRegistry is loaded, WHEN `get_all_ids()` is called, THEN returns an `Array[String]` of all registered enemy IDs.
  - [ ] AC6: GIVEN chapter string `"chapter_1"`, WHEN `get_enemies_by_chapter("chapter_1")` is called, THEN returns an array containing exactly the 4 Chapter 1 enemy profiles.
  - [ ] AC7: GIVEN any registered enemy ID, WHEN `get_enemy()` is called, THEN execution completes within 1ms.
  - [ ] AC8: GIVEN the `EnemyType` enum (or equivalent constants), WHEN enemy profiles are loaded, THEN the `type` field is stored as the enum value, not a raw string.
- **Test Evidence**: `tests/unit/enemy_data/enemy_registry_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-ENEMY-002: Attack Derivation and Data Validation

- **Type**: Logic
- **TR-IDs**: TR-enemy-data-004, TR-enemy-data-005
- **ADR Guidance**: ADR-0016 — `attack = floor(hp * ATTACK_RATIO)` where `ATTACK_RATIO` is loaded from the `config` block in `enemies.json` (default 0.1). Validation runs at load: clamp `score_threshold` to `hp` if exceeded; treat `hp <= 0` as data error (log + mark as instant-victory). Invalid `element` values default to `null`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN enemy with `hp=250` in JSON, WHEN EnemyRegistry loads, THEN `get_enemy("gaia_spirit").attack` equals `floor(250 * 0.1) = 25`.
  - [ ] AC2: GIVEN enemy with `hp=40`, WHEN loaded, THEN `attack = floor(40 * 0.1) = 4`.
  - [ ] AC3: GIVEN `ATTACK_RATIO=0.15` in `enemies.json` config block, WHEN EnemyRegistry loads, THEN attack values are derived using 0.15 (not the hardcoded default 0.1).
  - [ ] AC4: GIVEN enemy JSON with `score_threshold=300` and `hp=250`, WHEN loaded, THEN stored `score_threshold=250` (clamped) and a data warning is logged.
  - [ ] AC5: GIVEN enemy JSON with `hp=0`, WHEN loaded, THEN a data error is logged and the enemy is flagged for instant-victory behavior when instantiated in combat.
  - [ ] AC6: GIVEN enemy JSON with `element="InvalidElement"`, WHEN loaded, THEN `element` defaults to `null` and a data warning is logged.
  - [ ] AC7: GIVEN valid enemy data with `score_threshold <= hp`, WHEN loaded, THEN `score_threshold` is NOT modified (no erroneous clamp).
- **Test Evidence**: `tests/unit/enemy_data/enemy_validation_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ENEMY-001

---

### STORY-ENEMY-003: Localization Key Integration

- **Type**: Integration
- **TR-IDs**: TR-enemy-data-002
- **ADR Guidance**: ADR-0016 — Enemy display names are stored as i18n keys (`ENEMY_*` prefix). EnemyRegistry does not resolve them directly — callers pass the `name_key` to `Localization.get_text()`. Raw key is valid fallback per GDD. This story verifies the integration contract between EnemyRegistry and Localization autoload.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN EnemyRegistry loaded and Localization autoload active with `en.json`, WHEN `Localization.get_text(get_enemy("forest_monster").name_key)` is called, THEN returns `"Forest Monster"` (not the raw key).
  - [ ] AC2: GIVEN a `name_key` with no entry in `en.json` (e.g., `"ENEMY_CYCLOPS"` for a not-yet-translated enemy), WHEN `Localization.get_text()` is called, THEN returns the raw key `"ENEMY_CYCLOPS"` as fallback (no crash, no empty string).
  - [ ] AC3: GIVEN Chapter 2 enemies in `enemies.json` but Chapter 2 content not installed, WHEN EnemyRegistry loads, THEN Chapter 2 enemies are registered without error and their name_keys are stored correctly.
  - [ ] AC4: GIVEN EnemyRegistry and Localization both initialized per ADR-0006 boot order (#8 after #4), WHEN EnemyRegistry `_ready()` calls `get_enemy()`, THEN Localization is already initialized (no null-ref on Localization from EnemyRegistry `_ready()`).
- **Test Evidence**: `tests/integration/enemy_data/localization_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ENEMY-001
