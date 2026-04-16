# Art Bible: Dark Olympus

> **Status**: Complete
> **Last Updated**: 2026-04-10
> **Visual Identity Anchor**: "Mythological dark fantasy with warmth — not grimdark, but a fallen world with hope"
> **Engine**: Godot 4.6 (Mobile renderer)
> **Platform**: Portrait mobile 430x932, touch-only
> **Art Director Sign-Off (AD-ART-BIBLE)**: Pending (lean mode — AD-ART-BIBLE skipped)

---

## 1. Visual Identity Statement

### The One-Line Rule

**Every visual element must read as either "fallen grandeur" or "hope breaking through" — never purely bleak, never purely triumphant.**

### Supporting Principles

**Principle 1: Gold is divine authority in motion, not decoration.**
Gold (#D4A843) appears exclusively where the player or a deity is exercising power: a poker hand scoring, a blessing activating, a dialogue choice being made. It does not appear as trim, filigree, or visual noise.
*Design test: "Should this background panel have a gold pattern?" → No. Gold on an inert surface costs the currency gold earns.*
Pillar alignment: Pillar 1 (Poker Combat) + Pillar 3 (Romance as Investment)

**Principle 2: Warm contrast over cold contrast.**
The tonal poles are deep brown (mortality) and cream (preserved humanity). Darkness is expressed through depth of brown, never through desaturation or blue-grey. Light breaks through as amber-warm, not cool white.
*Design test: "Should this enemy aura be icy blue?" → No. Water element is the only blue, belonging to Nyx. Enemy menace is corrupted earth-brown or deep charcoal.*
Pillar alignment: Pillar 2 (Dialogue) — backgrounds must feel warm enough for intimacy.

**Principle 3: Mobile silhouette first — every element must communicate its purpose at 430px wide before it communicates its beauty.**
Artistic detail rewards close inspection. Functional clarity is mandatory at arm's length. A companion portrait, poker card, or button must carry full semantic meaning at render size.
*Design test: "Is this card's suit symbol legible at 64x90px?" → If not, enlarge or simplify the symbol.*
Pillar alignment: Pillar 1 (Poker Combat) — hand strength must be read instantly.

---

## 2. Mood & Atmosphere

### Combat
- **Emotion**: Focused tension with excitement — calculating a high-stakes bet with good odds
- **Lighting**: Deep amber, directional spotlight. 2700-3000K (candlelight warm). High contrast (7:1 min). Single intimate light source.
- **Descriptors**: tense, deliberate, illuminated, contained, charged
- **Energy**: Medium-high. Deliberate pacing with escalating urgency.
- **Note**: Combat backgrounds desaturated 15-20% vs dialogue variants. World recedes; cards advance.

### Dialogue
- **Emotion**: Intimacy and consequence — this person is paying attention, and what you say matters
- **Lighting**: Warm, even, soft. 3200K. No hard shadows on portraits. Studio-portrait warm.
- **Descriptors**: close, warm, consequential, alive, readable
- **Energy**: Low to medium. Typewriter pacing sets the rhythm.
- **Exception**: Confrontation nodes shift to storm/night background variant. Warmth cools — not cold, but embers dimmed.

### Camp
- **Emotion**: Anticipation and comfort — coming home to people glad to see you
- **Lighting**: Morning warmth or early evening gold. 3500K. Soft fill, no hard shadows.
- **Descriptors**: warm, routine, hopeful, grounded, unhurried
- **Energy**: Low. Decompression between combat and story.

### Chapter Map
- **Emotion**: Anticipation and orientation — knowing where you are in a journey
- **Lighting**: Elevated, overhead, golden-hour. 3800K. Parchment chart in candlelight.
- **Descriptors**: epic, oriented, purposeful, storied, legible
- **Energy**: Medium-low. Between actions, reviewing progress.

### Hub
- **Emotion**: Ownership and possibility — your base, everything opens from here
- **Lighting**: Stable, warm ambient. 3200K.
- **Descriptors**: centered, accessible, familiar, rich, open
- **Energy**: Low. Navigation infrastructure, not competing with content.

### Abyss Mode
- **Emotion**: Controlled danger — deliberately descending into risk
- **Lighting**: Deep, cool-shifted amber. 2200K (coals, not candles). Near-black fills permitted (deep brown-black #150F09, never pure black).
- **Descriptors**: descending, pressured, ritualistic, escalating, ancient
- **Energy**: High and climbing with each ante.

### Victory
- **Emotion**: Earned triumph — satisfaction, not cheap celebration
- **Lighting**: Burst warm gold. 4000K (bright but golden). Gold shimmer VFX at peak.
- **Energy**: High for 2-3 seconds, dropping to medium for rewards.

### Defeat
- **Emotion**: Dignified setback — honest acknowledgment, not punishment
- **Lighting**: Cooled amber, desaturated 25%. 2000K. STATUS_ERROR as narrow accent only.
- **Energy**: Low. Calm. "Failure returns to hub with no permanent loss."

---

## 3. Shape Language

### Character Silhouette Philosophy

Every companion's silhouette must be distinguishable at 120x160px as a flat black shape:

| Companion | Silhouette Anchor | Shape Character |
|-----------|-------------------|-----------------|
| **Artemis** (Earth) | Bow extending beyond body outline | Vertical, lean, asymmetric. Most elongated. |
| **Hipolita** (Fire) | Broad muscular shoulders, wild hair volume | Widest, heaviest. Mass over elegance. |
| **Atenea** (Lightning) | Staff with geometric edges, sharp posture | Structured, angular. Architecturally complex. |
| **Nyx** (Water) | Flowing cape/veil extending below figure | Longest fabric lines. Fluid, dissolving edges. |
| **Daphne** (Earth) | Basket of herbs, leaves in hair | Soft, rounded, organic curves. Smallest. |
| **Circe** (Lightning) | Crystal staff, billowing robes | Triangular — wide at robes, narrow at crown. |
| **Thetis** (Water) | Water-dress merging with ground line | No hard edges — body dissolves into flow. |
| **Echo** (Neutral) | Broken column behind, hair covering face | Asymmetric negative space. Haunting gap. |
| **Lyra** (Fire) | Apron, hands on hips, mug nearby | Compact, grounded, wide stance. Approachable. |
| **Melina** (Earth) | Journal and quill, braids | Small, bookish silhouette. Proportionally young. |
| **Naida** (Water) | Emerging from water line, pearl necklace | Half-visible — body fades below waist. |

**Mood variant rule**: All 6 mood variants maintain the same silhouette identity. Mood is expressed through face, posture, and color temperature — not costume or prop changes.

**LoRA training anchors**: Each character should have 3-5 visual anchors that stay consistent across all images for LoRA training. These are the features the model needs to learn as invariant: hairstyle + color, key prop (bow, staff, basket), costume signature (color + material), face structure (eye color, freckles, scars), and elemental accent (glow color, particle type).

### Card Visual Language

Cards are portrait rectangles with 8px corner radius (matching UI panels). Minimum size: 64x90px.

Three required visual zones:
1. **Rank zone** (top-left, bottom-right): Nunito Sans Bold 20px in element color
2. **Suit symbol zone** (center, ~40% of card): Element glyph (flame/wave/leaf/bolt), NOT standard pips
3. **Enhancement overlay** (VFX layer): Foil = metallic sheen 25%, Holographic = iridescent border, Polychrome = shifting edge

Card states: Unselected (1px gold 60%), Selected (2px gold 100%, +8px up), Discarded (40% opacity, -4px down).

**Face cards (MVP)**: Simplified — stylized rank numeral with element motif. Full mythological figures deferred to post-MVP.

### UI Shape Grammar

- **8px corner radius is universal** — panels, cards, buttons, portrait frames
- **Gold borders as hierarchy** — 1px/60% ambient, 2px/100% active, 3px/100% acting
- **Flat fills only** — no texture, no gradient on UI panels. World art is painterly; UI is architectural.
- **Forbidden shapes**: Circles as containers, hexagons, diagonal panel cuts

---

## 4. Color System

### Primary Palette

| Color | Hex | Semantic Role |
|-------|-----|---------------|
| Deep Brown (BG_PRIMARY) | #2A1F14 | The mortal world — fallen, imperfect, habitable |
| Near-Black Brown | #201710 / #150F09 | Shadow and depth — hidden, waiting, resting |
| Elevated Brown | #352A1C | Warmest background — surfaces approaching the player |
| Gold (ACCENT_GOLD) | #D4A843 | Divine authority — what remains of Olympus |
| Gold-Bright | #E8C060 | Active divine power — the moment of action |
| Cream (TEXT_PRIMARY) | #F5E6C8 | Preserved humanity — human voice that survived the fall |
| Muted Gold-Tan | #C4A97A | Supporting information — background hum of data |

### Element Colors

| Element | Hex | Mythology | Companion |
|---------|-----|-----------|-----------|
| Fire | #F24D26 | Orange-red combustion — aggressive, consuming | Hipolita |
| Water | #338CF2 | Royal blue depth — ocean at night, not daylit river | Nyx |
| Earth | #73BF40 | Yellow-green vitality — healthy leaf at noon | Artemis |
| Lightning | #CCAA33 | Electric gold — wisdom as divine revelation | Atenea |

### Companion Accent Tints

| Companion | Element | Accent | Shift Meaning |
|-----------|---------|--------|---------------|
| Artemis | Earth #73BF40 | #2A6A5A (teal) | Earth's intelligence, cooler than raw nature |
| Hipolita | Fire #F24D26 | #5A6A2A (olive) | Fire tempered by martial discipline |
| Atenea | Lightning #CCAA33 | #3A5A7A (slate blue) | Lightning refined into wisdom |
| Nyx | Water #338CF2 | #4A2A6A (deep violet) | Water at its coldest and deepest |

### Colorblind Safety

Problem pairs: Fire+Earth (red-green, ~8% male players), Lightning+Earth (yellow-green, ~0.5%).

**Non-negotiable rule**: Every element color paired with a distinct shape glyph:
- Hearts/Fire: Flame (upward, organic edges)
- Diamonds/Water: Wave/droplet (downward, fluid)
- Clubs/Earth: Trefoil/leaf cluster (organic growth)
- Spades/Lightning: Forked bolt (angular, split)

All element colors in UI include shape icon — no plain color fills without glyph backup.
WCAG 2.1 AA: TEXT_PRIMARY on BG_PRIMARY tests at ~7.8:1 (above 4.5:1 minimum).

---

## 5. Character Design Direction

### Portrait Specifications
- Canvas: 512x768px source. Displayed at max 390px width in dialogue.
- Framing: mid-thigh upward. Face occupies upper 40%. Eyes at y:170-200.
- Each companion has a dominant-side offset (bow/weapon side).
- Background: transparent PNG alpha. Portraits never bake in backgrounds.

### Expression and Pose Style
- High expressiveness on face; restrained on body.
- One clear gesture per mood, held as a beat (not frozen action).
- Companions are fallen gods — even joy has weight behind the eyes.
- Eyes: large pupils (anime-influenced), element color as subtle limbal ring.

### Companion Color and Detail Rules

| Companion | Skin Temp | Hair Base | Hair Highlight | Costume Temp |
|-----------|-----------|-----------|----------------|-------------|
| Artemis | Cool-neutral 3200K | Dark brown #3A2A1A | Green-tint #7A9A50 | Cool earth — greens, teal, olive |
| Hipolita | Warm 2800K | Deep red #6A1A0A | Amber-orange #E87A30 | Warm earth — rust, raw leather |
| Atenea | Neutral-cool 4000K | Platinum #D8D8E8 | Blue-silver #8A9AB8 | Grey-slate with geometric gold |
| Nyx | Cool 2200K | Near-black #1A1520 | Violet-white #C0A8E0 | Near-black with luminous edges |
| Daphne | Warm 3000K | Spring green #5A8A3A | Light green #A8D480 | Earth tones — linen, sage, brown |
| Circe | Cool-warm 3500K | Dark brown-black #2A1A18 | Purple tint #6A4A80 | Deep purple with gold symbols |
| Thetis | Cold 2000K | Silver-blue #8AABB8 | White-iridescent #D0E8F0 | Liquid blue — fluid, shimmering |
| Echo | Cool-pale 3800K | Near-black #1A1A20 | Silver-pale #B0B0C0 | White shift — minimal, torn |
| Lyra | Warm 2800K | Auburn #8A4020 | Golden-copper #D09040 | Cream apron over russet — tavern warm |
| Melina | Warm-neutral 3200K | Chestnut brown #5A3A28 | Honey #C8A860 | Olive green — bookish, modest |
| Naida | Cold-ethereal 1800K | Blue-green #3A7A7A | Cyan shimmer #80D8D0 | Translucent water — barely visible |

Detail density: Artemis medium (clean, functional), Hipolita low-medium (broad strokes, battle-scarred), Atenea high (geometric patterns, sharp edges), Nyx high-but-diffuse (detail dissolves into fabric, micro-star patterns), Daphne low (simple, organic), Circe high (arcane symbols, intricate robes), Thetis medium-fluid (shimmering, no hard edges), Echo low-haunting (minimal, negative space), Lyra low-warm (simple working clothes, tactile), Melina low (modest, readable at small size), Naida medium-ethereal (translucent skin, water effects).

### NPC: The Priestess
- Same canvas (512x768), same framing rules.
- Off-palette by design: warm-gold hair (#C8A840), temple white costume (#E8E0D0), gold-hazel eyes.
- 3 expression variants only: Receptive (default), Earnest (direct gaze), Transcendent (eyes upcast).
- Strict rule: never aggressive, afraid, or intimate. She is numinous.

### NPC: Thalos (Village Leader)
- Same canvas, same framing. White beard (#E0D8D0), cream robe, bronze clasp, carved staff.
- 4 expression variants: Thoughtful (default), Concerned, Commanding, Warm.
- Skin: warm 2600K, deeply aged and weathered. Kind eyes.

### NPC: Old Kostas (Fisherman)
- Same canvas, same framing. Grey beard, patched hat, leather vest, fishing rod.
- 4 expression variants: Squinting (default), Laughing, Wistful, Surprised.
- Skin: warm 2400K, deeply tanned and sun-wrinkled. Missing front tooth.

### Enemy Portraits
- Canvas: 384x512px (smaller than companions — visual hierarchy).
- Framing: chest upward (face-heavy, less individuated).
- Higher contrast (8:1 vs 5:1 for companions), harder shadows.
- Corrupted element treatment — element colors shifted toward near-black.
- Naming: `char_enemy_[id]_portrait_[variant].png` (idle, warning, defeated).

### Mood Variant Guidelines

| Variant | Emotion | Eyebrow | Eye | Mouth | Temp Shift |
|---------|---------|---------|-----|-------|------------|
| neutral | Present, observing | Relaxed | Open 80% | Closed, slight up | Baseline |
| happy | Genuine warmth | Raised | Wide 95% | Open smile | +200K |
| sad | Grief or hurt | Drawn, lowered | Half-lid 50% | Downturned | -200K |
| angry | Focused aggression | Low, furrowed | Narrowed 40% | Jaw set | -300K |
| surprised | Shock or delight | High, arched | Wide 100% | O-shape | +100K |
| intimate | Desire, closeness | Soft, lowered | Half-lid 60% | Soft, parted | +300K |

Locked across variants: silhouette, costume, props, hair, element accent, skin tone base.
Changes: face expression, posture lean (max +/-8px), skin color temperature.
Production rule: neutral authored first; all others defined as deltas from neutral.

### LOD at Game Camera Distance
- 390px wide (dialogue): full detail visible, painterly texture
- 120px wide (combat thumbnail): only shape, dominant color, face, weapon/prop readable
- No separate LOD assets — single source must work at both scales
- Minimum feature sizes at source: face 160x160px, eyes 24px wide, weapon 40px, glyph 36x36px

---

## 6. Environment Design Language

### Background Art Style
Painted illustration — storybook oil with simplified plane structure. Wide brushwork, selective detail.

Production approach per background:
1. Establish 3 depth planes: Near (0-15%), Mid (15-60%), Far (60-100%)
2. Focal point receives tight rendering (~200x300px area)
3. Remaining area is loose (wide brushstrokes, blocked colors)
4. Colors derive from Primary Palette — no new major hues in backgrounds
5. Source at 860x1864px (2x), export at 430x932px

### Location Signatures

| Location | Signature | Dominant Colors | Light Character |
|----------|-----------|----------------|-----------------|
| Forest | Tree canopy from below, light shafts | Deep brown, mid-green #4A6A30, amber shafts | Dappled, warm, scattered |
| Village | Tavern window glow against dark street | Deep brown, amber glow #E8AA50, cool sky #1A2535 | Dual: warm habitation vs cool night |
| Temple | Massive tree ascending beyond frame | Deep brown, gold luminescence, green ambient | Tree IS the light source |
| Camp | Tent ring around central fire | Near-black periphery, firelight amber center | Single warm source |
| Abyss | No horizon, deep darkness above and below | Near-black #150F09, charcoal, corrupted element | Minimal, cool-amber, no visible origin |
| Mountains | Cliff face, partial waterfall, visible sky | Grey-brown rock, waterfall blue-white, cold sky | Overcast, diffuse, coolest in game |

### Environmental Storytelling Rules
1. Every background has exactly one storytelling element — not two, not zero
2. Must be legible at 430px without zoom
3. Always in mid-plane (15-60% height)
4. Uses brown palette only (not element colors)

Established: Forest (roots reaching toward camera), Village (repaired damage on structures), Temple (tree outlasted stone temple), Camp (fire always lit), Abyss (tier-progressive buried artifacts).

### Background Variants
- `_day`: Default warm. `_night`: Cooled -300K, reduced saturation.
- `_combat`: Desaturated 15-20% + darkened (runtime CanvasModulate/shader)
- `_confrontation`: Additional cool shift (runtime parameter)
- Only 2 full illustrations per location; combat/confrontation are runtime post-process.

### Composition Rules for 430x932
- Horizon at 60-65% height (lower than standard)
- Vertical depth cue mandatory (element crossing 60% upward)
- No single object spans full 430px width below horizon
- Bottom 35% (thumb zone) clear of critical detail
- Full-bleed required with parallax buffer

---

## 7. UI/HUD Visual Direction

### Typography Hierarchy

| Role | Font | Size | Color | Where |
|------|------|------|-------|-------|
| Screen Title | Cinzel Regular | 32px | Cream | Hub tabs, Chapter Map, Combat |
| Section Header | Cinzel Regular | 24px | Cream | Panel headers |
| Enemy/Companion Name | Cinzel Regular | 20px | Cream | Combat, Dialogue speaker |
| Hand Rank Announce | Cinzel Regular | 40px | Gold | Combat scoring only |
| Dialogue Body | Nunito Sans Regular | 18px | Cream | All dialogue (never reduced) |
| Body Text | Nunito Sans Regular | 16px | Cream | Descriptions, settings |
| Metadata | Nunito Sans Regular | 14px | Muted gold-tan | Stat labels, captions |
| Button Label | Nunito Sans SemiBold | 16px | Gold/inverse | All buttons |
| Stat Value | Nunito Sans Bold | 20px | Gold | Score, chips/mult, HP |
| Nav Label | Nunito Sans SemiBold | 11px | Muted gold/cream | Tab bar |

Rules: Cinzel never below 18px. Gold text only for: hand ranks, scored values, speaker labels, currency. No all-caps. No text-shadow. No stroke.

### Iconography
Flat, single-weight, filled silhouettes. 24x24 base grid, exported 48x48 (2x). Single color fill — exported white, tinted via Godot modulate. Element glyphs are the only organic shapes; all others geometric.

### Button Types

| Type | Fill | Border | Label | Use |
|------|------|--------|-------|-----|
| Primary | Gold fill | None | Inverse brown | PLAY HAND, CONFIRM |
| Secondary | Transparent | 1.5px gold | Gold | DISCARD, VIEW DECK |
| Danger | Transparent | 1.5px red | Red | DELETE SAVE (in dialogs only) |
| Ghost | None | None | Muted gold-tan | Learn more, details |

All buttons: 52px height primary, 44px min, 8px radius, scale 0.97 on press.

### Combat HUD Zones (430x932)
- Enemy Zone (0-280px): portrait, name, HP bar
- Score Tray (280-420px): CHIPS x MULT = total (Cinzel 40px gold on score)
- Hand Area (420-650px): 5 card slots, 64x90px min
- Action Bar (650-720px): PLAY + DISCARD buttons, hands/discards counters
- Blessing Strip (720-870px): 32px blessing icons, long-press for detail
- Safe Area (870-932px)

### Dialogue Panel
- Portrait: 70%+ screen height, overlay gradient from bottom
- Text panel: lower 40%, BG_PRIMARY at 90% opacity, 1px gold top border
- Speaker: Cinzel 20px gold. Body: Nunito Sans 18px cream, typewriter at ~35 CPS.
- Choices: secondary-style buttons stacked vertically, max 4 visible.

### Tab Bar (Hub)
- Full-width, 60px height, BG_SECONDARY, 1px gold top border
- 4 equal tabs: Story | Combat | Camp | Profile
- Active: gold icon + cream label + 2px gold top. Inactive: dim gold + muted label.

---

## 8. Asset Standards

### File Formats

| Asset Type | Format | Rationale |
|---|---|---|
| Portraits, cards, UI sprites, VFX | PNG | Lossless, alpha channel |
| Backgrounds | WebP lossless | 25-34% smaller than PNG |
| Fonts | .tres wrapping .ttf | Precompiled, one-frame load |
| Icons | PNG (exported white, tinted in-engine) | Modulate-friendly |

### Naming Convention
`[category]_[name]_[variant]_[size].[ext]`

Prefixes: `char_` (portraits), `env_` (backgrounds), `card_` (cards), `ui_` (UI elements), `icon_` (icons), `vfx_` (effects), `fx_` (shader inputs), `font_` (fonts).

All lowercase, underscores only. Never abbreviate companion names.

### Resolution Tiers

| Tier | Dimensions | Asset Types |
|---|---|---|
| Full Background | 430x932px | Environment backgrounds |
| Portrait Full | 512x768px | Companion portraits (6 moods) |
| Portrait Compact | 160x240px | Hub companion cards |
| Card Art | 128x180px (2x of 64x90 display) | Playing cards |
| Icon Standard | 48x48px (2x of 24px) | Nav/UI icons |
| Icon Large | 96x96px (2x of 48px) | Blessing/element icons |

### Memory Budget

| Category | Compressed Target | Notes |
|---|---|---|
| Portraits (24 total) | ~4.8MB | 4 companions x 6 moods |
| Backgrounds (3 loaded) | ~1.2MB | WebP lossless |
| Cards (52 deck) | ~0.8MB | |
| Icons | ~0.3MB | Negligible |
| VFX sheets | ~5MB | Budget cap |
| Fonts | ~0.8MB | Cinzel + Nunito Sans |
| **Total art budget** | **~15.5MB** | Well within 80MB ceiling (512MB total) |

### Export Settings
- PNG: maximum compression (lossless). WebP: lossless mode.
- Color profile: sRGB. Mipmaps: disabled for UI, enabled for portraits/backgrounds.
- Filter: Linear for portraits/backgrounds, Nearest for icons/cards.
- All assets Texture2D. Repeat disabled.

---

## 9. Reference Direction

### How to Use These References
Each reference provides one technique to extract and one boundary to respect. The goal is additive synthesis, not style imitation. Dark Olympus must read as itself.

### Reference 1: Balatro (2024)
**Draw**: Card hand legibility under pressure — rank/suit instantly readable, scoring reveal cascade (chips x mult accumulating).
**Avoid**: Flat, desaturated casino-green palette. Sterile aesthetic. Do not import its palette, card backs, or UI chrome.

### Reference 2: Hades (2020, Supergiant Games)
**Draw**: Character portrait system — personality through silhouette, posture, and color temperature. Warm amber + deep shadow creating depth in 2D painterly art.
**Avoid**: High-saturation neon-on-dark (electric purples, magentas, cyan highlights). Dark Olympus is warmer and more earthen.

### Reference 3: Persona 5 (2017, Atlus)
**Draw**: Typographic momentum — aggressive size ratios (40px vs 12px), strategic whitespace, single accent color (gold here, red there) as sole saturated element on desaturated ground.
**Avoid**: Angular, diagonal, asymmetric panel geometry. Dark Olympus UI is architectural and calm — 8px radius, orthogonal, no diagonal cuts.

### Reference 4: Fire Emblem: Three Houses (2019)
**Draw**: Social intimacy of companion conversations — portrait scale, text positioning, ambient lighting creating private-conversation sensation. Emotional portrait variants with subtle expression shifts.
**Avoid**: Flat, overlit anime-screentone UI. Pastel blues/greens, clean white panels. Dark Olympus warmth is amber, not pastel.

### Reference 5: Inkle's 80 Days / Heaven's Vault
**Draw**: Visual patience of text-forward mobile design — generous line-height, measured padding, restrained accents that reward reading. Single strong illustration per scene.
**Avoid**: Hand-drawn, watercolor, sketch aesthetic. Dark Olympus is painterly with weight and depth, not light linework.
