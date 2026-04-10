---
name: Dark Olympus Project Context
description: Core identity, tech stack, pillars, and companion data for Dark Olympus — needed every session
type: project
---

Dark Olympus is a narrative RPG / dating sim / poker combat game in Greek mythology setting. Migrated from React Native to Godot 4.6 (portrait mobile, 430x932).

**Four Pillars:**
1. Balatro-inspired poker combat (chips x mult scoring, 52-card deck, 10 hand ranks)
2. Visual novel dialogue with consequences
3. Companion romance as mechanical investment (romance -> divine blessings -> combat power)
4. Roguelike Abyss for replayability

**Four Companions:**
| ID | Name | Element | Suit | STR | INT | Card Value | Signature Card |
|----|------|---------|------|-----|-----|-----------|----------------|
| artemisa | Artemisa | Earth | Clubs | 17 | 13 | 13 | King of Clubs |
| hipolita | Hipolita | Fire | Hearts | 20 | 9 | 14 | Ace of Hearts |
| atenea | Atenea | Lightning | Spades | 13 | 19 | 14 | Ace of Spades |
| nyx | Nyx | Water | Diamonds | 18 | 19 | 14 | Ace of Diamonds |

**Captain stat formulas:**
- `captain_chip_bonus = floor(STR * 0.5)`
- `captain_mult_bonus = 1.0 + (INT * 0.025)`

**Why:** Needed every session to cross-check companion data and formula constants without re-reading GDDs.
**How to apply:** Verify any formula or companion stat against this table before drafting GDD content. Cross-reference with companion-data.md for additional fields.
