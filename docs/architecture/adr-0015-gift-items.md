# ADR-0015: Gift Items — Purchase Flow + Gold Economy

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (economy, data) |
| **Knowledge Risk** | LOW — JSON loading, Dictionary operations. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore: player_gold), ADR-0010 (RomanceSocial: do_gift integrates purchase) |
| **Enables** | Camp gift picker UI |
| **Blocks** | Gold sink functionality |
| **Ordering Note** | Feature layer. Deferrable — Camp can be built with placeholder gift data. |

## Context

Gold is awarded across Chapter 1 (270 total) with no spending mechanism in the original design. The gift items quick spec (`design/quick-specs/gift-items.md`) defined 6 purchasable gift items to create a gold sink and provide Camp's gift picker with an item source.

## Decision

**GiftItems is a stateless utility class that loads gift item definitions from JSON and provides lookup/validation methods.** Purchase flow: player selects item in Camp gift picker → GiftItems validates gold → GameStore.spend_gold() → RomanceSocial.do_gift() processes the relationship outcome.

### Data Source

`res://assets/data/gift_items.json`:
```json
[
  {"id": "wildflowers", "name_key": "GIFT_WILDFLOWERS", "category": "romantic", "gold_cost": 10},
  {"id": "training_sword", "name_key": "GIFT_TRAINING_SWORD", "category": "active", "gold_cost": 15},
  {"id": "ancient_scroll", "name_key": "GIFT_ANCIENT_SCROLL", "category": "intellectual", "gold_cost": 20},
  {"id": "woven_blanket", "name_key": "GIFT_WOVEN_BLANKET", "category": "domestic", "gold_cost": 10},
  {"id": "explorers_map", "name_key": "GIFT_EXPLORERS_MAP", "category": "adventure", "gold_cost": 15},
  {"id": "painted_stone", "name_key": "GIFT_PAINTED_STONE", "category": "artistic", "gold_cost": 20}
]
```

### Key Interfaces

```gdscript
class_name GiftItems
extends RefCounted

static func get_items() -> Array[Dictionary]
static func get_item(id: String) -> Dictionary
static func can_afford(item_id: String, player_gold: int) -> bool
static func get_cost(item_id: String) -> int
```

### Purchase Flow

```
Camp gift picker → player selects item
  → GiftItems.can_afford(item_id, GameStore.get_gold()) → if false, greyed
  → GameStore.spend_gold(cost) → returns true
  → RomanceSocial.do_gift(companion_id, item_id) → RL gain, mood change, buff
```

No inventory. Purchase = immediate gift. Gold is the only cost.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| quick-specs/gift-items.md | 6 gift items with gold costs | JSON data file |
| quick-specs/gift-items.md | Immediate purchase+gift (no inventory) | Camp → GiftItems → GameStore → R&S flow |
| quick-specs/gift-items.md | Gold deduction on purchase | GameStore.spend_gold() |
| quick-specs/gift-items.md | Category maps to date preferences | Category field matches R&S preference system |
| camp.md | Gift picker reads item list | GiftItems.get_items() |

## Related Decisions

- ADR-0001: GameStore — gold storage
- ADR-0010: Romance & Social — do_gift() processes the relationship outcome
- `design/quick-specs/gift-items.md` — design spec
