# Quick Design Spec: Gift Items

> **Type**: MVP Gold Sink + Camp Gift Source
> **Author**: game-designer
> **Created**: 2026-04-09
> **Parent GDD**: design/gdd/romance-social.md (Rule 2 — Gift interaction)
> **Resolves**: Cross-GDD Review B-03 (Gold has no sink), W-10 (Camp gift inventory gap)

---

## Problem

Gold is awarded across Chapter 1 (270 total) with no spending mechanism. Camp's Gift interaction references an item inventory that no system defines. Both issues block architecture.

## Solution

Define 6 purchasable gift items available at Camp. Each item has a gold cost, maps to one of the 6 date activity categories (romantic, active, intellectual, domestic, adventure, artistic), and integrates with Romance & Social's existing gift preference system. Items are bought and gifted in the same Camp flow — no separate shop screen.

## Gift Item Registry

| ID | Display Name Key | Category | Gold Cost | Description |
|---|---|---|---|---|
| `wildflowers` | GIFT_WILDFLOWERS | romantic | 10 | A bundle of mountain wildflowers |
| `training_sword` | GIFT_TRAINING_SWORD | active | 15 | A wooden practice blade |
| `ancient_scroll` | GIFT_ANCIENT_SCROLL | intellectual | 20 | A fragment of pre-Kronos text |
| `woven_blanket` | GIFT_WOVEN_BLANKET | domestic | 10 | Handmade camp blanket |
| `explorers_map` | GIFT_EXPLORERS_MAP | adventure | 15 | A charted route through ruins |
| `painted_stone` | GIFT_PAINTED_STONE | artistic | 20 | A stone painted with old symbols |

## Rules

1. **Purchase location**: Camp gift picker overlay. Items display with gold cost. Tapping an item shows a buy confirmation if gold is sufficient.
2. **Immediate gifting**: Buying a gift immediately gifts it to the selected companion. No inventory storage — purchase IS the gift action. One token is still consumed per Rule 2 of Romance & Social.
3. **Gold deduction**: Gold deducted atomically on purchase confirmation. If gold < item cost, the item is greyed out and non-tappable.
4. **Unlimited stock**: Items are always available. No scarcity or per-day limits.
5. **Category → Preference mapping**: Gift category maps to companion preference weights from the Date system. A companion who likes "romantic" date activities also likes "romantic" gifts. This reuses the existing preference discovery system (Rule 5 of R&S).
6. **Gift outcome**: Follows R&S Rule 2 exactly — liked (+2 RL), neutral (+1 RL), disliked (0 RL). Mood and buff effects per R&S Rules 2 and 6.
7. **Preference hints**: At romance_stage >= 2, Camp gift picker shows hint icons on items matching `known_likes` categories — per existing Camp Rule 8 (AC-CAMP-08).

## Data Format

Gift items defined in `res://assets/data/gift_items.json`:

```json
[
  { "id": "wildflowers", "name_key": "GIFT_WILDFLOWERS", "category": "romantic", "gold_cost": 10 },
  { "id": "training_sword", "name_key": "GIFT_TRAINING_SWORD", "category": "active", "gold_cost": 15 },
  { "id": "ancient_scroll", "name_key": "GIFT_ANCIENT_SCROLL", "category": "intellectual", "gold_cost": 20 },
  { "id": "woven_blanket", "name_key": "GIFT_WOVEN_BLANKET", "category": "domestic", "gold_cost": 10 },
  { "id": "explorers_map", "name_key": "GIFT_EXPLORERS_MAP", "category": "adventure", "gold_cost": 15 },
  { "id": "painted_stone", "name_key": "GIFT_PAINTED_STONE", "category": "artistic", "gold_cost": 20 }
]
```

## Economy Validation

- Ch1 total gold: 270
- Average gift cost: 15 gold
- Max purchases from Ch1 gold: ~18 gifts
- At 3 tokens/day, a player spends up to 3 gifts/day = 45 gold/day max
- 270 gold sustains ~6 days of max gifting — aligns with Ch1 expected play duration
- Gold is not exhausted in one session, creating a natural pacing constraint

## Tuning Knobs

| Knob | Value | Safe Range | Effect |
|---|---|---|---|
| Per-item gold cost | 10-20 | [5, 50] | Lower = gold drains faster, gifting feels cheap. Higher = fewer gifts, each feels weighty. |
| Item count | 6 | [4, 10] | More items = more preference variety. Fewer = simpler choice. |

## Dependencies

| System | Direction | Interface |
|---|---|---|
| **Romance & Social** | Gift items feeds R&S | R&S `do_gift(companion_id, item_id)` — item_id maps to category, category maps to preference |
| **Camp** | Gift items feeds Camp | Camp gift picker reads `gift_items.json` for display. Gold cost shown per item. |
| **Save System** | Gold persisted via GameStore | `player_gold` deducted on purchase. Already persisted. |

## Acceptance Criteria

- [ ] **GIVEN** player has 25 gold, **WHEN** gift picker opens, **THEN** items costing <= 25 are tappable, items costing > 25 are greyed.
- [ ] **GIVEN** player buys `wildflowers` (10 gold) for Artemis, **WHEN** confirmed, **THEN** gold decreases by 10, token decreases by 1, R&S `do_gift("artemis", "wildflowers")` is called.
- [ ] **GIVEN** `wildflowers` category is "romantic" and Artemis likes "romantic", **WHEN** gifted, **THEN** RL +2, mood -> Happy.
- [ ] **GIVEN** player has 0 gold, **WHEN** gift picker opens, **THEN** all items greyed, "Not enough gold" label shown.
- [ ] **GIVEN** player at romance_stage >= 2 with `known_likes: ["romantic"]`, **WHEN** gift picker shows `wildflowers` (romantic), **THEN** preference hint icon is displayed.
- [ ] All item IDs, costs, and categories are data-driven from `gift_items.json`.
