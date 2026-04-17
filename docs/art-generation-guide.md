# Dark Olympus — Art Generation Guide (v2)

> **Target**: ComfyUI (SDXL / Flux / Pony checkpoints)
> **Viewport**: 430x932 portrait mobile
> **Visual anchor**: "Mythological dark fantasy with warmth — fallen grandeur, hope breaking through"
> **Last updated**: 2026-04-17

---

## 1. Global Style Constraints

### Aesthetic Pillars

- Dark mythology, fallen gods, Greek bronze age
- Muted palette: deep browns, near-black backgrounds, burnished gold (#D4A843), cream (#F5E6C8)
- Painterly / semi-realistic, NOT anime. Reference: "Hades" (Supergiant) meets Genshin Impact splash art
- Dramatic chiaroscuro, oil-painting texture, single warm light source
- Greek / Bronze Age wardrobe (chitons, bronze armor, leather wraps)
- Divine details: subtle ambient VFX tied to character element

### Global Negative Prompt (always include)

```
anime, cel shading, cartoon, flat colors, modern clothing, sci-fi,
low quality, blurry, bad anatomy, extra limbs, text, watermark,
bright saturated colors, clean background, symmetrical face,
generic fantasy, medieval european armor
```

### Global Positive Suffix (always append)

```
painterly, oil painting texture, dramatic chiaroscuro lighting,
dark mythology, bronze age greek, muted earth palette, gold accents,
cinematic composition, masterpiece, highly detailed, depth of field
```

---

## 2. Character Design Philosophy

Every character in Dark Olympus must be instantly recognizable at **64px thumbnail size** — the size they appear in deck slots, party HUD, and gacha reveals. We achieve this through five Genshin-Impact-inspired design principles:

### P1 — Color Triangle

Each character owns a **dominant + complement + accent** color set. No two characters share the same dominant. The element color appears as the accent, never the dominant (so the character reads as a person first, an element second).

### P2 — Signature Silhouette

One unique shape defines the character at a glance: Artemis's bow arc, Nyx's floating hair, Circe's crystal staff. This shape must be readable in a 64px square. Asymmetry is mandatory — no character is perfectly symmetric.

### P3 — Storytelling Detail

Every character has one wardrobe piece that tells their backstory without dialogue: Hipolita's battle scars, Echo's torn dress, Thetis's pearl-tear necklace. New players should be able to guess the character's history from a single portrait.

### P4 — Element Expression

Element doesn't just color the border — it lives on the character: in their eye color, ambient motes, weapon glow, or clothing pattern. But it's always secondary to personality.

### P5 — Rank Legibility

S-rank characters have more visual complexity (floating elements, glow, elaborate clothing). B-rank characters are simpler and grounded (practical clothes, fewer VFX). This creates an intuitive visual hierarchy that mirrors power level.

---

## 3. Companion Portraits

**Dimensions**: 768x1024 (tall portrait, cropped to 430x600 display)
**Format**: PNG with transparent background preferred
**Output path**: `assets/images/companions/{id}/{id}_{mood}.png`
**Moods per character**: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`

---

### 3.1 Artemis — Goddess of the Hunt

> *"The moonlit huntress who chose the forest over Olympus."*

**Role**: DPS / Crit Assassin | **Element**: Earth | **Rank**: S

#### Design DNA

Artemis rejected divine luxury for the wild. Her design is **practical elegance** — everything she wears is functional hunting gear, but cut with divine precision that betrays her godhood. She moves like a predator. Her beauty is incidental and dangerous, like a silver blade.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Forest green | `#2D5A3D` | Chiton, leather straps, quiver |
| Complement | Moonlit silver | `#C0C8D4` | Hair, circlet, arrow tips, skin glow |
| Accent (element) | Earth gold-green | `#8BA84A` | Eye iris, leaf motifs, ambient motes |

#### Signature Silhouette

The **recurve bow arc** rising above her right shoulder. Even at 64px, the bow's curve is unmistakable. Her silver braid sweeps left, creating asymmetry against the bow line.

#### Wardrobe Breakdown

- **Top**: Short dark-green hunting chiton, one shoulder bare (right), the other secured with a hammered silver clasp shaped like a crescent moon
- **Strapping**: Crossed leather chest straps holding quiver to her back; the leather is worn and scarred from use
- **Lower**: Chiton cuts above the knee, asymmetric hem — shorter on the right for running mobility
- **Legs**: Leather-wrapped greaves from knee to mid-calf, bare feet with earth stains (she feels the ground)
- **Circlet**: Thin silver band with a single moonstone at the temple — not a crown, a practical way to keep hair from her eyes
- **Quiver**: Dark leather, holds 7 arrows (not full — she never wastes shots)

#### Hair & Face

- **Hair**: Silver-white with a cool blue sheen, long single braid thrown over left shoulder, loose strands framing face
- **Eyes**: Sharp, almond-shaped, gold-green iris with a faint inner glow like sunlight through leaves
- **Expression baseline**: Watchful, slightly furrowed brow — she's always tracking something
- **Distinguishing mark**: Thin diagonal scar across her left cheekbone (from the fall of Olympus)
- **Skin**: Sun-kissed, warm olive tone with a faint silver moonlight glow on exposed surfaces

#### Element Expression

Earth motes: tiny floating leaves and pollen particles drift around her hair and shoulders in a lazy orbit. When she draws her bow, root-like energy patterns trace along her arms.

#### Prompt Base

```
portrait of Artemis greek goddess of the hunt, silver-white hair in a
long braid over left shoulder with loose strands, gold-green glowing
almond eyes, thin scar on left cheekbone, athletic olive-skinned young
woman early 20s, short dark forest green hunting chiton with one bare
right shoulder, hammered silver crescent moon clasp on left shoulder,
crossed leather chest straps worn and scarred, dark leather quiver with
7 arrows on her back, silver recurve bow rising above right shoulder,
thin silver circlet with moonstone at temple, leather-wrapped greaves
bare feet with earth stains, floating leaf and pollen motes around her,
faint silver moonlight glow on skin, dense forest canopy background
with filtered golden light
```

#### Mood Variations

- `neutral`: Watchful, bow at rest across back, slight frown of focus, scanning the treeline
- `happy`: Soft asymmetric smile (left corner higher), relaxed shoulders, one hand resting on bow
- `sad`: Bow lowered to ground, looking down at the scar on her hand, braid fallen forward
- `angry`: Teeth bared, bow drawn to full extension, gold-green eyes blazing, earth motes swirling fast
- `surprised`: Wide eyes, lips parted, hand snap-reaching for an arrow, braid swinging
- `seductive`: Half-lidded direct gaze, chin tilted down, one strap slipped from shoulder, moonlit clearing

#### LoRA Training Anchors

`darkolympus_artemis` — silver braid, gold-green eyes, cheekbone scar, crescent clasp, forest green chiton, recurve bow, leather quiver, floating leaf motes

---

### 3.2 Hippolyta — Queen of the Amazons

> *"Burns so bright she scares the gods. Her scars are trophies."*

**Role**: Berserker DPS | **Element**: Fire | **Rank**: A

#### Design DNA

Hippolyta is **war made beautiful**. Every mark on her body is a victory. Her design screams "conqueror" — heavy bronze armor but only where it matters (protecting the heart), leaving arms and legs bare to show battle scars she wears with pride. She is fire incarnate: wild, hungry, and magnetic.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | War crimson | `#8B2020` | Hair, war paint, leather wraps |
| Complement | Burnished bronze | `#B87333` | Breastplate, arm bands, spear tip |
| Accent (element) | Ember orange | `#D4651A` | Eye iris, fire motes, scar glow |

#### Signature Silhouette

The **iron spear** held diagonally across her body, and her **wild lion-mane hair** creating a massive, untamed shape. At 64px, the spear diagonal + hair volume are unmistakable.

#### Wardrobe Breakdown

- **Torso**: Hammered bronze breastplate covering only the chest, leaving midriff bare — exposing a map of battle scars across her abdomen and ribs
- **Under**: Dark crimson leather wraps beneath the breastplate
- **Arms**: Bare from shoulder to wrist. Heavy bronze arm bands (left only — asymmetry). Right arm has a spiraling burn scar from wrist to shoulder
- **Lower**: Short crimson leather battle skirt with bronze studs, split for movement
- **Legs**: Bare thighs showing more scars, bronze shin guards over sandals
- **War paint**: Single thick red stripe across right cheekbone and bridge of nose — reapplied before every fight
- **Spear**: Iron-tipped, ash-wood shaft wrapped in red leather at the grip. Her grandmother's weapon.

#### Hair & Face

- **Hair**: Wild, untamed crimson — somewhere between auburn and blood red. Falls past shoulders in a chaotic mane. No braids, no pins — she doesn't tame it
- **Eyes**: Fierce amber with fire-orange ring around the pupil
- **Expression baseline**: Steel grin — mouth set in a "try me" half-smile
- **Distinguishing mark**: The red war paint stripe, plus a notch in her left ear (sliced in combat)
- **Skin**: Deep bronze-olive with visible battle scars, slightly ruddy from constant proximity to fire

#### Element Expression

Ember motes: tiny glowing fire particles drift from her hair and around the spear tip. When she's emotional, the ember density increases. Her scars faintly glow orange in combat, as if the fire lives inside her.

#### Prompt Base

```
portrait of Hippolyta Amazon warrior queen, wild untamed crimson
lion-mane hair past shoulders, fierce amber eyes with orange ring,
muscular battle-scarred bronze-olive woman mid 20s, hammered bronze
breastplate over bare midriff showing battle scars, crimson leather
wraps and battle skirt with bronze studs, heavy bronze arm band on
left arm only, spiraling burn scar up right arm, red war paint stripe
across right cheekbone and nose bridge, notched left ear, iron-tipped
ash-wood spear with red leather grip held diagonally, bare muscular
thighs with scars, bronze shin guards and sandals, floating ember
motes around hair and spear tip, burning war camp background
```

#### Mood Variations

- `neutral`: Commanding stance, spear planted beside her, weight on back foot, chin raised
- `happy`: Full fierce grin showing teeth, spear raised in victory salute, embers surging
- `sad`: Hand pressed flat over the scars on her abdomen, spear resting on ground, staring at flames
- `angry`: Snarling, spear in mid-thrust position, embers becoming full flames around her
- `surprised`: Eyes wide, spear snapped up to guard position, hair flung back
- `seductive`: Predatory half-smile, leaning on spear shaft, one hand on bare hip, firelit

#### LoRA Training Anchors

`darkolympus_hipolita` — wild crimson hair, amber eyes, red war paint stripe, bronze breastplate over bare midriff, battle scars, iron spear, ember motes, notched ear

---

### 3.3 Atenea — Goddess of Wisdom

> *"Lightning is just truth moving too fast to dodge."*

**Role**: Burst DPS / Debuffer | **Element**: Lightning | **Rank**: S

#### Design DNA

Atenea is **controlled devastation**. Where Hippolyta is chaos, Atenea is precision. She dresses like a scholar but strikes like a storm. Her design plays on the contrast between her composed, regal exterior and the violent electrical power barely contained beneath the surface. One hand holds a scroll; the other crackles with lightning.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Deep indigo | `#2E1A47` | Chiton, hair accents, owl brooch |
| Complement | Silver-white | `#D8D8E8` | Embroidery, hair streaks, skin highlights |
| Accent (element) | Electric violet | `#9B59D0` | Eye iris, lightning arcs, finger glow |

#### Signature Silhouette

The **owl brooch** at her collar and the **scroll in her left hand** create a compact, regal shape. At 64px, the indigo + silver streaks in her hair and the electric glow on her fingertips read clearly.

#### Wardrobe Breakdown

- **Top**: Floor-length indigo chiton with geometric silver embroidery along the hem and collar — the patterns are mathematical (fractals, golden ratios)
- **Shoulders**: Asymmetric — left shoulder has a draped silver cape-piece, right shoulder bare with visible lightning-vein markings (like Lichtenberg figures burned into her skin)
- **Waist**: Thin silver chain belt with a small owl pendant
- **Hands**: Left hand holds a half-read scroll; right hand is bare with visible electric arcs jumping between fingertips
- **Feet**: Silver sandals, hidden beneath the chiton's length
- **Brooch**: Silver owl with violet gem eyes, clasped at the left collar — her divine symbol

#### Hair & Face

- **Hair**: Black as ink with two symmetric silver-white streaks framing her face (like lightning bolts frozen in her hair). Worn loose to mid-back, slightly wavy
- **Eyes**: Storm-grey with a violet electric ring that brightens when she's emotional
- **Expression baseline**: Calm analysis — one eyebrow slightly raised, mouth neutral, watching and measuring
- **Distinguishing mark**: Lichtenberg-figure scars on right shoulder and upper arm (branching like tree roots, from channeling too much lightning)
- **Skin**: Cool olive, porcelain-smooth except for the lightning scars

#### Element Expression

Electric arcs: thin violet lightning jumps between her fingertips on the right hand, intensifying with emotion. Her silver hair streaks faintly glow during combat. The embroidery patterns on her chiton occasionally pulse with dim light.

#### Prompt Base

```
portrait of Athena goddess of wisdom as burst DPS mage, long black hair
with two silver-white lightning-bolt streaks framing face, storm grey eyes
with violet electric ring, cool olive skin, tall regal woman late 20s,
deep indigo chiton with geometric silver fractal embroidery, asymmetric
silver cape draped on left shoulder, bare right shoulder with branching
Lichtenberg scar markings, silver owl brooch with violet gem eyes at
collar, thin silver chain belt with owl pendant, rolled scroll in left
hand, violet electric arcs crackling between right fingertips, dark
library with storm-lit columns in background
```

#### Mood Variations

- `neutral`: Serene, scroll half-read, right hand hovering with faint arcs, analyzing
- `happy`: Subtle knowing smile, eyes brightening (literally — violet glow intensifies), leaning forward with interest
- `sad`: Scroll closed, hand covering Lichtenberg scars, lightning dimmed, looking away
- `angry`: Cold fury, electric arcs expanding from hand into full bolts, hair streaks blazing white, pupils constricting
- `surprised`: Both eyebrows up (rare), scroll dropped, hand reflexively raised, sparks scattering
- `seductive`: Scroll set aside deliberately, chin resting on hand, direct violet-bright eye contact, faint smile

#### LoRA Training Anchors

`darkolympus_atenea` — black hair with silver streaks, storm-grey violet eyes, indigo chiton, silver embroidery, Lichtenberg scars on right shoulder, owl brooch, scroll, lightning finger arcs

---

### 3.4 Nyx — Primordial Goddess of Night

> *"She doesn't enter the room. The room becomes night."*

**Role**: Evasion DPS / Assassin | **Element**: Water | **Rank**: S

#### Design DNA

Nyx is **the void given form**. She's the oldest being in the cast and it shows — her design is uncanny and otherworldly. Nothing about her is entirely solid: her hair floats independently, her robe dissolves into star-field at the edges, and her skin has a translucent quality as if she's projecting herself from somewhere else. She is hauntingly beautiful in a way that makes you uneasy.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Void black | `#0A0812` | Robe, hair core, background void |
| Complement | Star-silver | `#B8C4D8` | Star motes, skin highlights, thorn crown |
| Accent (element) | Deep cosmic violet | `#6B3FA0` | Eye galaxies, robe stars, ambient glow |

#### Signature Silhouette

**Floating hair** that defies gravity, spreading upward and outward like dark wings, with star points glinting in it. At 64px, the dark void shape with bright star-dots is unmistakable.

#### Wardrobe Breakdown

- **Robe**: Floor-length black, but the fabric itself contains a moving star-field — tiny points of light drift across the surface like a planetarium projected on cloth. The hem dissolves into dark mist rather than ending cleanly
- **Shoulders**: Bare, with faint blue-violet veins visible beneath translucent skin
- **Crown**: A crown of dark thorns (not metal — actual black crystallized thorns) nestled in her floating hair
- **Hands**: Long pale fingers, slightly translucent, with dark-violet nail polish. A single black ring on her left index finger
- **Feet**: Not visible — the robe pools into darkness at the ground. She may not have feet
- **Jewelry**: None except the black ring. Nyx predates the concept of decoration

#### Hair & Face

- **Hair**: Midnight black at the roots, blending to deep violet at the tips. Floats in zero-gravity tendrils as if underwater. Star motes drift within the hair mass
- **Eyes**: No iris/pupil division — her eyes are tiny galaxies, deep violet with swirling pinpoints of light. Looking into them is disorienting
- **Expression baseline**: Ancient unknowable calm — not cold, not warm, simply beyond mortal emotional register
- **Distinguishing mark**: A single dark tear-track stain under her left eye, permanent, cosmic in color
- **Skin**: Pale to the point of translucency, with a faint blue-silver luminescence. Veins visible on neck and collarbones

#### Element Expression

Star motes: dozens of tiny lights orbit her body slowly, congregating around her hair and fingertips. When emotional, they scatter outward or pull in tight. Her Water element manifests as a deep cosmic-ocean quality — not sea-water but the primordial waters of creation.

#### Prompt Base

```
portrait of Nyx primordial goddess of night, midnight black to deep
violet hair floating weightlessly in zero gravity with star points
within it, galaxy eyes with no pupils just swirling violet cosmos,
translucent pale luminescent skin with visible blue veins on neck,
permanent dark cosmic tear track under left eye, ethereal ageless
otherworldly woman, flowing black star-field robe with moving pinpoints
of light on fabric, hem dissolving into dark mist, bare translucent
shoulders, crown of black crystallized thorns in floating hair, single
black ring on left index finger, orbiting star motes around body,
cosmic void background with distant nebula
```

#### Mood Variations

- `neutral`: Distant gaze, hair drifting slowly, star motes in gentle orbit — unknowable
- `happy`: Rare soft smile that humanizes her, star motes brighten and orbit faster, eyes warm slightly
- `sad`: Single new cosmic tear forming, hair drifting downward, motes dimming
- `angry`: Black flames erupt from her hands, galaxy eyes blazing violet-white, thorns growing, motes scattered
- `surprised`: Hair flares outward, motes scatter in all directions, lips parted — she rarely experiences surprise
- `seductive`: Veil-like wisps of dark energy frame her face, robe parting at collarbone, direct galaxy-eye contact, intimate

#### LoRA Training Anchors

`darkolympus_nyx` — floating black-violet hair, galaxy eyes, translucent pale skin, cosmic tear track, star-field robe, thorn crown, star motes, no feet visible

---

### 3.5 Priestess — Gaia Fragment (NPC)

> *"What remains when a goddess chooses to become a garden."*

**Role**: Quest Giver / Oracle | **Element**: None (Gaia) | **Type**: NPC (no combat)

#### Design DNA

The Priestess is **nature remembering it was once divine**. She is partially translucent, woven from plant matter and light, existing at the boundary between woman and ecosystem. Her design should feel reverent and slightly unreal — not a person wearing leaves, but leaves that remember being a person.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Living emerald | `#2E7D4F` | Hair, robe leaves, aura |
| Complement | Silver bark | `#A8A89C` | Thread in robe, vine crown |
| Accent | Bioluminescent green | `#7CFC00` | Eye glow, aura pulses |

#### Signature Silhouette

**Vine crown** with upward-reaching tendrils, framing her head like a small tree. At 64px, the green glow + crown shape reads clearly.

#### Wardrobe Breakdown

- **Robe**: Woven from living leaves and silver thread — the leaves are still growing, still slightly moving
- **Crown**: Living vine crown that sprouts small white flowers that bloom and wilt on a slow cycle
- **Hands**: Clasped in prayer or extended in blessing. Bark-like texture on the backs of her hands
- **Skin**: Semi-translucent, with green bioluminescent veins visible beneath
- **Feet**: Bare, with roots extending into the ground (she is literally rooted when standing still)

#### Prompt Base

```
portrait of ancient priestess of Gaia earth mother, long emerald green
hair flowing like vines, glowing bioluminescent green eyes, ethereal
semi-translucent woman with green veins visible, robe woven from living
leaves and silver thread still growing, vine crown with small white
flowers blooming, bark-textured hands clasped in prayer, roots extending
from bare feet, soft green bioluminescent aura, ancient tree roots and
temple columns behind her
```

#### Mood Variations

- `neutral`: Serene, hands clasped, eyes softly glowing, small flowers blooming
- `happy`: Benevolent smile, leaves rustle and new buds appear, aura brightens
- `sad`: Flowers wilting in crown, head bowed, leaves curling, glow dimming
- `angry`: Thorns sprout from vines, stern green-blazing eyes, roots cracking stone
- `surprised`: Leaves scatter, eyes wide, flowers burst into sudden bloom
- `seductive`: NOT NEEDED (NPC, reuse neutral)

#### LoRA Training Anchors

`darkolympus_priestess` — emerald hair-vines, glowing green eyes, leaf-and-silver robe, vine crown with white flowers, semi-translucent skin, root-feet

---

### 3.6 Daphne — Herbalist Nymph

> *"She talks to flowers because people make her blush."*

**Role**: Healer / Support | **Element**: Earth | **Rank**: B

#### Design DNA

Daphne is **gentle wildness** — a forest nymph who'd rather tend her garden than talk to strangers. Her design is deliberately the most grounded and simple in the cast (B-rank = visual simplicity). She's approachable, warm, and a little messy — dirt under her nails, leaves in her hair, a shy smile that makes you want to protect her.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Warm sage | `#7A8B6A` | Dress, basket, hair leaves |
| Complement | Cream linen | `#E8DCC8` | Dress base, skin tone |
| Accent (element) | Moss gold | `#9B8A44` | Eye iris, pollen motes, flower details |

#### Signature Silhouette

The **woven herb basket** on her left hip and the leaves tangled in her hair. At 64px, the basket shape is her identifier.

#### Wardrobe Breakdown

- **Dress**: Simple cream linen shift with hand-embroidered wildflower patterns at the hem — the embroidery is slightly uneven (she did it herself)
- **Apron**: Loose sage-green apron with oversized pockets, stained with grass and herb juices
- **Hair accessories**: 3-4 leaves and a small white flower naturally tangled in (not placed — they just accumulate as she works)
- **Basket**: Woven wicker basket always at her left hip, overflowing with fresh herbs, tied with twine to an apron strap
- **Feet**: Bare, with grass stains between the toes and earth around the nails
- **Hands**: Small, gentle, with dirt under the nails and herb-stained fingertips (green-yellow)

#### Hair & Face

- **Hair**: Soft green, shoulder-length, naturally wavy, perpetually slightly tangled with leaves and pollen
- **Eyes**: Warm moss-gold, large and round, slightly downcast (shy)
- **Expression baseline**: Gentle half-smile directed at the ground, avoiding direct eye contact
- **Distinguishing mark**: A spray of freckles across her nose and cheeks, like scattered seeds
- **Skin**: Fair with warm undertone, flushed pink at cheeks and nose tips

#### Element Expression

Pollen and seed motes drift lazily around her, especially concentrated near the basket. Small flowers in her vicinity lean toward her. Very subtle — her earth connection is gentle, not dramatic.

#### Prompt Base

```
portrait of young shy forest nymph herbalist, soft green shoulder-length
wavy hair with leaves and small white flower tangled in, large warm
moss-gold eyes slightly downcast, spray of freckles across nose and
cheeks, fair pink-flushed skin, gentle late teens girl, simple cream
linen dress with hand-embroidered wildflower hem, sage green herb-stained
apron with big pockets, woven wicker basket overflowing with fresh herbs
on left hip, bare feet with grass stains and earth, dirt under nails,
herb-stained green fingertips, lazy floating pollen motes, soft golden
sunlit forest garden background
```

#### Mood Variations

- `neutral`: Shy half-smile, clutching basket protectively, looking slightly away
- `happy`: Beaming up from the basket holding a perfect bloom, freckles emphasized by flush
- `sad`: Wilting flower in hand, looking away, basket set down, shoulders hunched
- `angry`: Rare — eyes fierce and tear-filled, thorns pushing up from the ground around her feet
- `surprised`: Basket dropped, herbs spilling, hands to mouth, wide-eyed
- `seductive`: Flower crown she braided, bare shoulders, moonlit garden, looking directly at viewer for once

#### LoRA Training Anchors

`darkolympus_daphne` — soft green wavy hair with leaves, freckles, moss-gold eyes, cream dress with flower embroidery, sage apron, woven herb basket, bare grass-stained feet

---

### 3.7 Circe — Sorceress of Thebes

> *"Every transformation she inflicts is a confession about herself."*

**Role**: Burst DPS / Debuffer | **Element**: Lightning | **Rank**: S

#### Design DNA

Circe is **dangerous knowledge**. She's the most beautiful person in any room and she knows it — and that's the distraction while she rewrites reality. Her design is regal, deliberate, and slightly menacing: every jewel is an arcane battery, every symbol on her robe is a live spell. She's a walking arsenal dressed as a queen.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Royal purple | `#4A1A6B` | Robes, staff wrappings, nail color |
| Complement | Ritual gold | `#C9A84C` | Arcane symbols, circlet, chain belt |
| Accent (element) | Lightning white-violet | `#C8A0FF` | Eye glow, staff crystal, finger sparks |

#### Signature Silhouette

The **crystal staff** rising above her right shoulder, its orb glowing. At 64px, the staff orb + the golden circlet against purple are unmistakable.

#### Wardrobe Breakdown

- **Robes**: Deep purple, floor-length, with active golden arcane symbols embroidered throughout — the symbols shift and glow faintly (they're live enchantments)
- **Fit**: Robes are deliberately fitted at the waist and loose at the sleeves — a mix of allure and dramatic gesture potential
- **Right shoulder**: Bare, with a golden chain connecting to the collar. A small tattooed rune behind the shoulder
- **Belt**: Heavy golden chain belt with three small vials hanging from it (potions — red, violet, black)
- **Circlet**: Golden with a central violet gem that glows in response to magic use
- **Staff**: Dark wood wrapped in purple leather, topped with a cracked crystal orb that contains a tiny contained lightning storm
- **Feet**: Gold-strapped sandals visible when she walks, dark purple pedicure

#### Hair & Face

- **Hair**: Rich dark brown to black, long and sleek, worn loose and flowing. Faintly shimmers with an oily-violet sheen in certain light
- **Eyes**: Amber-gold with a supernatural inner glow, slightly cat-like in shape — she looks at people the way a cat looks at prey
- **Expression baseline**: Knowing smirk, one eyebrow slightly raised, head slightly tilted — perpetually amused
- **Distinguishing mark**: Small rune tattoo behind the right shoulder, and violet-stained lips (from years of potion-tasting)
- **Skin**: Warm olive-brown, luminous, flawless (maintained by magic)

#### Element Expression

Lightning: tiny arcs crackle between her fingertips at rest, and her staff crystal pulses. The golden symbols on her robes pulse in sequence, tracing spellwork patterns. Her circlet gem glows brighter near other magic users.

#### Prompt Base

```
portrait of powerful greek sorceress enchantress, long dark sleek hair
with violet sheen, glowing amber-gold cat-like eyes, knowing smirk,
violet-stained lips, warm olive luminous skin, beautiful dangerous woman
early 30s, fitted deep purple robes with glowing golden arcane symbols,
bare right shoulder with golden chain and small rune tattoo, heavy gold
chain belt with three potion vials, golden circlet with glowing violet
central gem, dark wood staff wrapped in purple leather topped with
cracked crystal orb containing tiny lightning storm, lightning arcs
between fingertips, dark mysterious chamber with floating spell circles
in background
```

#### Mood Variations

- `neutral`: Knowing smirk, staff resting in the crook of her arm, one hand with arcs between fingers
- `happy`: Genuine delighted laugh (rare and disarming), magic sparking playfully around her, eyes crinkling
- `sad`: Staring into the cracked crystal, seeing something painful in it, smirk gone, lips pressed
- `angry`: Staff raised, crystal blazing white, ALL robe symbols lit at once, eyes white-gold, terrifying
- `surprised`: Crystal cracks further, both eyebrows up, genuinely caught off-guard (she hates it)
- `seductive`: Robes parted at the chest, one potion vial uncorked and held to her lips, candlelit, heavy-lidded

#### LoRA Training Anchors

`darkolympus_circe` — dark hair violet sheen, amber cat-eyes, purple robes with gold symbols, crystal storm staff, golden circlet violet gem, potion vials on belt, lightning finger arcs

---

### 3.8 Thetis — Sea Nymph

> *"The ocean doesn't forget. Neither does she."*

**Role**: Tank / Shielder | **Element**: Water | **Rank**: A

#### Design DNA

Thetis is **melancholy made magnificent**. She's an ancient sea goddess trapped in a mortal form, and every detail of her design communicates the weight of that loss. Her dress literally flows like water. Her skin shimmers like scales. She is heartbreakingly beautiful in the way the ocean is — vast, deep, and slightly terrifying.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Deep ocean blue | `#1A3A5C` | Dress, hair depths, skin tones |
| Complement | Pearl white | `#E8E4D8` | Pearls, foam details, skin highlights |
| Accent (element) | Bioluminescent teal | `#4CE0D2` | Eye glow, scale shimmer, water motes |

#### Signature Silhouette

The **flowing water-dress** that doesn't have clean edges — it merges with mist at the bottom. And her pearl hair-chains. At 64px, the blue-to-white gradient of the water-dress reads distinctly.

#### Wardrobe Breakdown

- **Dress**: Appears to be made of actual flowing ocean water — translucent blue-to-white layers that ripple and flow even when she's still. Foam patterns at the edges
- **Shoulders**: Bare, with iridescent scale-shimmer patches on the upper arms and collarbones
- **Pearls**: Three thin chains of freshwater pearls woven through her hair. A pearl choker at her throat. One large pearl drop earring (left ear only — asymmetry)
- **Wrists**: Pearl bracelet on right wrist. Left wrist has a thin blue-green scale band (part of her body, not jewelry)
- **Feet**: Bare and slightly webbed between the toes. Stands in a perpetual thin layer of mist/foam
- **No prop**: She carries nothing — she IS her power

#### Hair & Face

- **Hair**: Silver-blue, long to mid-back, flows as if perpetually underwater even on dry land. Individual strands catch light like fiber optics
- **Eyes**: Deep ocean blue with bioluminescent teal ring, slightly larger than human normal — uncanny and beautiful
- **Expression baseline**: Distant melancholy, lips slightly parted, looking at something far away that no one else can see
- **Distinguishing mark**: Iridescent scale patches on collarbones and upper arms that shimmer in light
- **Skin**: Pale blue-tinted, with an iridescent fish-scale sheen when light catches it at angles

#### Element Expression

Water mist: a thin layer of mist pools at her feet permanently. Tiny water droplets float upward around her body (reverse rain). Her dress ripples with invisible currents. When she shields allies, a dome of water briefly appears.

#### Prompt Base

```
portrait of ancient sea nymph goddess, long silver-blue hair flowing as
if underwater with three pearl chains woven through, deep ocean blue eyes
with bioluminescent teal ring, pale blue-tinted iridescent skin with
scale shimmer on collarbones and upper arms, ageless melancholic ethereal
beauty, flowing dress made of actual ocean water translucent rippling
layers with sea foam edges, bare shoulders with scale patches, pearl
choker at throat, single pearl drop earring on left ear, pearl bracelet
on right wrist, blue-green scale band on left wrist, bare slightly
webbed feet in mist, tiny water droplets floating upward around her,
underwater grotto with bioluminescent coral background
```

#### Mood Variations

- `neutral`: Distant gaze past the viewer, pearl choker clasped, perpetual sadness
- `happy`: Rare warmth breaks through, ocean mist sparkles prismatically, a genuine soft smile
- `sad`: Tears that crystallize into pearls rolling down cheeks, hair going still, mist thickening
- `angry`: Ocean surge behind her, tidal wall rising, eyes fully teal-blazing, commanding presence
- `surprised`: Water splashes outward from her, pearls scatter, eyes wide, hair flaring
- `seductive`: Emerging from moonlit water, wet iridescent skin glistening, direct teal-bright gaze

#### LoRA Training Anchors

`darkolympus_thetis` — silver-blue underwater hair, pearl chains, ocean-blue teal eyes, iridescent scale-skin patches, water-dress, pearl choker, floating water droplets, mist feet

---

### 3.9 Echo — Cursed Bard

> *"She lost her voice. She found a song."*

**Role**: Buffer / Utility | **Element**: Neutral | **Rank**: B

#### Design DNA

Echo is **silence made visible**. Cursed to only repeat others' words, her design is deliberately desaturated — she's the only character whose color palette is nearly monochrome. She exists in the gray space between. Her design tells her tragedy: the torn dress, the absence of an instrument (until her quest resolves), the silver mist that is her voice trying to escape.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Ghost white | `#E8E4E0` | Shift dress, skin, mist |
| Complement | Ash dark | `#3A3638` | Hair, column shadows, torn edges |
| Accent (element) | Silver mist | `#B8B8C8` | Ambient mist, eye gleam, lyre strings (post-quest) |

#### Signature Silhouette

**Hair curtain** — her long dark hair falls like a veil partially covering her face. The **broken column** she leans against is always in frame. At 64px, the pale figure against dark ruins reads clearly.

#### Wardrobe Breakdown

- **Dress**: Simple white linen shift, once fine, now torn at the hem and fraying at the edges — she's been wandering the ruins for a long time
- **Fit**: Loose, slightly too large for her, as if she's shrinking inside it
- **Shoulders**: One shoulder always slipping off (right side), revealing a pale collarbone
- **Feet**: Bare, dirty from the ruins, but her steps leave no imprint (she weighs nothing)
- **Prop (pre-quest)**: Nothing. Her hands hover near her throat or reach out empty
- **Prop (post-quest)**: A silver lyre, ornate, appears in her hands. The lyre's strings glow faintly silver

#### Hair & Face

- **Hair**: Near-black, very long (to her hips), straight and heavy, partially covering the right side of her face like a curtain. Always has the quality of wet hair clinging
- **Eyes**: Pale silver-grey, luminous, too large for her face — haunting and pleading
- **Expression baseline**: Mouth slightly open as if about to speak but catching herself, eyes communicating everything words can't
- **Distinguishing mark**: A thin silver scar encircling her throat — the mark of the curse
- **Skin**: Pale as marble, almost luminous, with a blue undertone — she barely looks alive

#### Element Expression

Silver mist: the only Neutral-element character. Her ambient VFX is a faint silver mist that clings to her feet and trails behind her. When she "speaks" (uses abilities), the mist forms brief word-shapes that dissolve. Post-quest, the lyre strings shimmer with silver light.

#### Prompt Base

```
portrait of haunting greek nymph cursed bard, very long near-black hair
falling like a wet curtain partially covering right side of face, pale
luminous silver-grey eyes too large for face, marble-pale skin with blue
undertone, thin silver scar encircling her throat, hauntingly beautiful
young woman early 20s, simple white linen shift dress torn at hem and
fraying, right shoulder slip revealing collarbone, bare dirty feet,
mouth slightly open as if about to speak, hands reaching out empty,
faint silver mist clinging to her feet, broken marble columns and
forest ruins in moonlight background, desaturated nearly monochrome
color palette
```

#### Mood Variations

- `neutral`: Near a broken column, mouth slightly open, hands reaching toward nothing, silver mist pooling
- `happy`: Rare genuine smile, silver light brightening around her, holding the lyre (post-quest), tears of relief
- `sad`: Kneeling among ruins, hair covering face completely, silver mist thick and low, no hands visible
- `angry`: Mist darkens to grey-black, columns behind her crack, silent scream — mouth wide open, no sound
- `surprised`: Mist scatters violently, hair blown back revealing her full face, hand at throat
- `seductive`: White shift slipping off both shoulders, ruins at warm sunset (only time she gets warm light), direct eye contact

#### LoRA Training Anchors

`darkolympus_echo` — near-black hair curtain over right face, silver-grey eyes, throat scar ring, white torn shift, marble-pale skin, silver mist, broken columns, monochrome palette

---

### 3.10 Lyra — Tavern Keeper

> *"The world's burning? Sit down. Have a drink. We'll figure it out."*

**Role**: Support / Crit Buffer | **Element**: Fire | **Rank**: B

#### Design DNA

Lyra is **warmth incarnate** — the hearth you come home to. She's the most "normal" person in a cast of gods and nymphs, and that's exactly her power. Her design is cozy, inviting, and grounded: practical tavern wear, strong hands, a smile that makes you feel safe. She's not glamorous, she's real, and that's why she matters.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Warm russet | `#8B4726` | Blouse, hair, wood tones |
| Complement | Cream apron | `#F0E6D0` | Apron, mug foam, firelight reflections |
| Accent (element) | Hearth orange | `#D4843A` | Eye warmth, fire glow, ruddy cheeks |

#### Signature Silhouette

The **messy bun** and the **cream apron** over russet. At 64px, the warm round shape of the messy bun + the apron stripe are her identifiers.

#### Wardrobe Breakdown

- **Blouse**: Russet-brown linen with rolled-up sleeves showing strong forearms — she carries kegs
- **Apron**: Cream-colored, well-worn, slightly stained with wine and grease, tied at the waist with a double knot
- **Skirt**: Simple dark brown, practical length (mid-calf), with deep pockets
- **Shoes**: Sturdy leather shoes with scuffs — she's on her feet all day
- **Accessories**: A small bronze key on a leather cord around her neck (the tavern cellar key — it was her mother's)
- **Hands**: Strong, calloused, warm — always carrying something (mug, bottle, towel)

#### Hair & Face

- **Hair**: Auburn-copper, always in a messy bun held with a wooden pin. Strands constantly escape and frame her face
- **Eyes**: Warm honey-brown, crinkled at the corners from constant smiling
- **Expression baseline**: Open friendly grin, head slightly tilted, as if inviting you to sit down
- **Distinguishing mark**: Ruddy permanently-flushed cheeks and nose (from years beside the hearth fire)
- **Skin**: Warm tan with permanent flush, a few faint freckles on the nose bridge

#### Element Expression

Hearth glow: a warm amber light seems to emanate from around her, especially her hands. When she uses fire abilities, flames manifest as hearth-fire (controlled, warming) not wildfire. Faint heat shimmer around her hands when she buffs allies.

#### Prompt Base

```
portrait of warm greek tavern keeper barmaid, auburn-copper messy bun
with wooden pin and escaped strands, warm honey-brown crinkled eyes,
ruddy permanently flushed cheeks and nose, warm tan skin with faint
freckles, strong friendly young woman mid 20s, russet brown linen blouse
with rolled up sleeves showing strong forearms, cream well-worn stained
apron tied at waist, small bronze key on leather cord necklace, sturdy
scuffed leather shoes, holding a ceramic mug of mead, open welcoming
grin, warm amber hearth glow around her, tavern interior with firelight
wooden beams hanging oil lamps background
```

#### Mood Variations

- `neutral`: Hands on hips, friendly grin, mug nearby on the counter, towel over shoulder
- `happy`: Full belly laugh, holding up two mugs sloshing with mead, eyes squeezed shut with joy
- `sad`: Wiping the counter slowly in an empty tavern, fire burned low, staring at the key necklace
- `angry`: Broken mug on the floor, pointing at the door, eyes flashing — she's terrifying when pushed
- `surprised`: Mug spilling, eyes wide, catching a falling tray one-handed, messy bun unraveling
- `seductive`: Apron untied and loose, leaning on the bar, candlelit back room, warm knowing smile

#### LoRA Training Anchors

`darkolympus_lyra` — auburn messy bun with wooden pin, honey-brown eyes, ruddy cheeks, russet blouse, cream stained apron, bronze key necklace, strong forearms, hearth glow

---

### 3.11 Melina — Village Leader's Daughter

> *"She reads about the world because they won't let her see it."*

**Role**: Support / Healer | **Element**: Earth | **Rank**: B

#### Design DNA

Melina is **curiosity caged**. She's the sheltered daughter of Thalos, the village leader, and everything about her screams "I want to be anywhere but here." Her design is modest village clothing that she's subtly personalized — ink stains on her cuffs, a journal she never puts down, sandals worn thin from sneaking to the restricted section of the library. She's the youngest in the cast and the most human.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Olive green | `#6B7A4F` | Dress, ink tones |
| Complement | Parchment cream | `#E8D9C0` | Journal pages, undershirt |
| Accent (element) | Earth warm brown | `#A0784C` | Eye color, leather journal, sandals |

#### Signature Silhouette

**Twin braids** + the **leather journal** clutched to her chest. At 64px, the two braid lines and the rectangular journal shape are clear identifiers.

#### Wardrobe Breakdown

- **Dress**: Modest olive-green linen, ankle-length, high neckline — chosen by her father, not by her
- **Personalization**: She's rolled the sleeves up past her elbows (rebellion), revealing ink-stained forearms
- **Under**: Cream linen undershirt visible at the collar
- **Journal**: Worn brown leather, bulging with pressed flowers, loose pages, and ribbon bookmarks. She clutches it like a lifeline
- **Quill**: Tucked behind her right ear when not in use, occasionally dripping ink on her shoulder
- **Sandals**: Simple leather, worn nearly through at the soles from sneaking around at night
- **No jewelry**: Her father considers it vanity. She tied a braided grass ring on her left pinky (secret)

#### Hair & Face

- **Hair**: Warm chestnut brown, in twin braids that reach mid-chest. Small flyaway hairs from impatient braiding
- **Eyes**: Large, round, warm brown — "doe eyes" that make everyone underestimate her
- **Expression baseline**: Curious, slightly defiant, chin angled up despite being short
- **Distinguishing mark**: Perpetual ink smudge on her right cheek (she rests her face on her writing hand)
- **Skin**: Warm olive, soft, youthful — she hasn't spent years in the sun like Lyra or Hippolyta

#### Element Expression

Very subtle. Pressed flowers in her journal occasionally glow faintly with green light. When she heals allies, faint script (like her handwriting) appears briefly in the air before dissolving into golden-green motes.

#### Prompt Base

```
portrait of young greek village scholar girl, warm chestnut brown twin
braids to mid-chest with flyaway hairs, large warm brown doe eyes,
ink smudge on right cheek, warm olive youthful skin, curious defiant
late teens girl, modest olive green ankle-length linen dress with
rolled up sleeves revealing ink-stained forearms, cream undershirt at
collar, worn brown leather journal clutched to chest bulging with
pressed flowers and bookmarks, quill tucked behind right ear, worn-thin
leather sandals, braided grass ring on left pinky, village square with
ancient library columns background
```

#### Mood Variations

- `neutral`: Reading journal, one hand turning a page, chin raised, curious expression
- `happy`: Showing an open book excitedly with both hands, eyes bright, braids bouncing
- `sad`: Journal closed and hugged tight to chest, looking at a locked gate, braids limp
- `angry`: Journal slammed shut, defiant stance, ink-stained fists clenched, chin jutting
- `surprised`: Quill dropped, gasping, loose pages flying from the journal, braids swinging wide
- `seductive`: Dress loosened at the collar, reading by candlelight in the forbidden library, ink on her lips

#### LoRA Training Anchors

`darkolympus_melina` — chestnut twin braids, doe eyes, ink smudge on right cheek, olive green dress, ink-stained forearms, leather journal, quill behind ear, grass ring on pinky

---

### 3.12 Naida — River Nymph

> *"She speaks in the sound water makes on stone — if you're patient enough to listen."*

**Role**: Tank / Support Hybrid | **Element**: Water | **Rank**: A

#### Design DNA

Naida is **shyness as a defense mechanism**. A river nymph who lost her river, she's perpetually half-hidden — behind reeds, partially submerged, hair covering her face. Her design is translucent and fragile, like something you'd see for a second in a twilight reflection and then doubt you saw at all. She's beautiful in a way that makes you hold your breath.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | River blue-green | `#4A8B7A` | Skin tint, hair, water-wrap |
| Complement | Twilight silver | `#C4C0C8` | Pearl, skin highlights, reed mist |
| Accent (element) | Iridescent aqua | `#66D4C4` | Eye iridescence, water drops, glow |

#### Signature Silhouette

**Hair flowing like liquid water** even on dry land, and the **single pearl necklace**. At 64px, the liquid-blue hair shape against pale skin is distinct.

#### Wardrobe Breakdown

- **Wrap**: A simple wrap that appears to be made of flowing river water — translucent, shifting, revealing and concealing in ripples. No seams, no edges — it just... is
- **Skin**: Translucent blue-green tinted, with a faint scale-like shimmer on the shoulders and ribs
- **Necklace**: A single freshwater pearl on a thread-thin silver chain — the only solid object she owns
- **Feet**: Bare, with slightly webbed toes. Puddles form around her feet involuntarily
- **Hands**: Slender, fingers slightly elongated, translucent at the fingertips
- **Ears**: Slightly pointed, barely visible through her water-hair — hints at her inhuman nature

#### Hair & Face

- **Hair**: Blue-green, flows like actual liquid water even when dry, shimmering with light reflections. Falls past her shoulders in a curtain
- **Eyes**: Iridescent — shifting between aqua, silver, and green depending on the angle. No visible pupils when in water
- **Expression baseline**: Shy, partially hidden — peeking from behind her own hair or from behind reeds
- **Distinguishing mark**: Translucent blue-green skin that reveals the suggestion of structure beneath (not bones — more like river stones under shallow water)
- **Skin**: Pale blue-green, translucent, with scattered iridescent scale-patches on shoulders

#### Element Expression

Water: puddles appear at her feet spontaneously. Her wrap ripples with invisible currents. When she uses abilities, the river rises around her — water surges from nowhere, responds to her emotions. Tiny water drops orbit her hair like Nyx's star motes, but fewer and calmer.

#### Prompt Base

```
portrait of shy river water nymph, blue-green hair flowing like liquid
water even dry with light reflections, iridescent shifting aqua-silver
eyes, translucent blue-green skin with scale shimmer on shoulders, pale
ethereal ageless beauty looking early 20s, simple wrap made of flowing
river water translucent and rippling, single freshwater pearl on thin
silver chain necklace, bare feet with slight webbing and puddles forming,
slender elongated translucent fingertips, slightly pointed ears, shy
expression partially hidden behind hair, scattered floating water
droplets, river bank with reeds and twilight mist background
```

#### Mood Variations

- `neutral`: Half-submerged, peeking from behind reeds, pearl glowing faintly, tentative
- `happy`: Emerging from water with droplets catching prismatic light, genuine surprised smile
- `sad`: Sitting on dry riverbank, hair flat and still (no longer flowing), looking at empty river bed
- `angry`: River churns and rises behind her, eyes fully iridescent-blazing, water cocoon forming, no longer shy
- `surprised`: Splash outward from her, ripples spreading in all directions, hair flaring
- `seductive`: Fully emerged in twilight, wet iridescent skin glistening, pearl glowing warm, direct eye contact at last

#### LoRA Training Anchors

`darkolympus_naida` — liquid blue-green water-hair, iridescent eyes, translucent blue-green skin, water-wrap, single pearl necklace, webbed toes, puddle feet, reed setting

---

### 3.13 Old Kostas — Fisherman (Side NPC)

> *"Fish don't care about gods. That's why I like them."*

**Role**: Side NPC (no combat, no romance) | **Type**: side_no_romance

#### Design DNA

Kostas is **the world before it broke**. An old fisherman who survived the fall of the gods by not caring about the gods. His design is entirely mundane — no magic, no glow, no divine anything. He's the realest person in the game, and that grounds the entire cast.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Sun-bleached tan | `#B8A080` | Skin, hat, linen |
| Complement | River-water grey | `#7A8088` | Beard, vest, rod |
| Accent | Brass warm | `#C0943C` | Buckle, flask, fish scales |

#### Prompt Base

```
portrait of old greek fisherman, bushy grey beard, deeply tanned and
sun-wrinkled face with kind crinkled eyes, patched wide-brimmed straw
hat with fishing hook stuck in brim, sleeveless rough linen shirt with
sweat stains, worn leather vest with brass buckle, wooden fishing rod
over right shoulder with dangling line, missing front tooth visible in
easy grin, small brass hip flask, thick calloused hands with fishing
scars, river bank with morning mist and reeds background
```

#### Mood Variations

- `neutral`: Squinting at the water, rod over shoulder, easy grin
- `happy`: Belly laugh head thrown back, holding up a fish proudly, missing tooth on display
- `sad`: Staring at the empty river, line slack, no grin
- `angry`: Shaking fist at the sky, hat askew (he's yelling at a god)
- `surprised`: Rod bending hard, both hands on it, eyes wide — something big
- `seductive`: NOT NEEDED

#### LoRA Training Anchors

`darkolympus_kostas` — grey beard, patched straw hat with hook, missing tooth, leather vest brass buckle, wooden fishing rod, river mist

---

### 3.14 Thalos — Village Leader (Side NPC)

> *"He carries the village the way the great tree carries its branches — silently, and for longer than anyone knows."*

**Role**: Side NPC (no combat, no romance) | **Type**: side_no_romance

#### Design DNA

Thalos is **authority worn thin by responsibility**. He's not a king, he's a caretaker. His design communicates wisdom, exhaustion, and a stubborn refusal to let go. He leans on his staff not for show but because he needs it. The gold circlet is dull — he hasn't polished it in years.

#### Color Triangle

| Role | Color | Hex | Where |
|------|-------|-----|-------|
| Dominant | Aged cream | `#D8CDB8` | Robes, beard, skin |
| Complement | Dark root brown | `#4A3828` | Staff, belt, shadows |
| Accent | Tarnished gold | `#A89050` | Circlet, clasp, wisdom |

#### Prompt Base

```
portrait of wise old greek village elder, long white beard braided at
the tip, kind but exhausted eyes with deep crow's feet, tall but
stooped posture, cream linen robe with simple dark leather belt, dull
tarnished gold circlet on brow, bronze clasp at the collar shaped like
a leaf, gnarled carved walking staff of dark sacred-tree wood, thin
weathered hands with prominent veins, village square with the massive
sacred tree spreading behind him
```

#### Mood Variations

- `neutral`: Leaning on staff, thoughtful gaze toward the sacred tree, weight on the wood
- `happy`: Warm grandfatherly smile, eyes crinkling almost shut, hand on your shoulder
- `sad`: Head bowed, both hands on staff supporting full weight, circlet dipping
- `angry`: Standing fully upright (rare), staff raised, commanding voice — suddenly not frail at all
- `surprised`: Staff clutched, eyes wide, circlet sliding
- `seductive`: NOT NEEDED

#### LoRA Training Anchors

`darkolympus_thalos` — white braided beard, tarnished gold circlet, cream robes, leaf bronze clasp, gnarled dark wood staff, sacred tree background

---

## 4. Enemy Portraits

**Dimensions**: 512x512 | **Format**: PNG | **Path**: `assets/images/enemies/{enemy_id}.png`

### 4.1 forest_monster (Tutorial)
```
twisted corrupted wolf creature with glowing red eyes, body of matted
dark fur and black ooze, corrupted earth-brown energy dripping from
fangs, crouched attack pose, bronze age dark forest setting,
painterly dark fantasy, menacing but not overwhelming (tutorial enemy)
```

### 4.2 mountain_beast
```
massive stone-and-muscle bear creature, cracked granite hide with
glowing orange fissures, standing on hind legs roaring, mountain pass
with pine trees, bronze age dark fantasy painterly, boss-level scale
```

### 4.3 amazon_challenger
```
fierce Amazon warrior sparring opponent, short-cropped red hair,
confident smirk, practical bronze chest armor and leather wraps,
iron short sword in guard stance, training arena torch-lit background,
painterly bronze age, she looks like she's enjoying this
```

### 4.4 gaia_spirit (Chapter 1 Boss)
```
massive corrupted earth elemental, body of cracked stone and dying
roots twisted together, emerald fissures leaking dark corrupted energy,
ancient face half-formed in the rock surface screaming silently,
temple ruins background with shattered columns, dark painterly epic
fantasy boss, towering over the viewer, tragic not evil
```

### 4.5 sardis_bandit
```
lean scrappy human bandit with improvised weapons, rough cloth mask
over lower face, leather jerkin patched with mismatched scraps, rusty
short blade, crouching in ambush pose, dusty road with olive trees,
painterly bronze age, desperate not villainous
```

### 4.6 corrupted_nymph
```
once-beautiful water nymph twisted by dark divine corruption, skin
cracked like dried riverbed, hair that was once flowing water now
frozen into black crystal shards, glowing corrupted violet eyes,
ruined river shrine background, painterly dark fantasy, tragic
```

---

## 5. CG / Intimacy Scenes

**Dimensions**: 1024x1024 or 1280x720 | **Format**: PNG
**Path**: `assets/images/cg/{id}_intimate_{n}.png`
**Style**: Tasteful, painterly, romantic visual novel. NOT explicit.

Each romanceable companion has **3 intimacy scenes** (one per relationship milestone).

### CG Prompt Template
```
[scene description], [companion] described as [core visual features from
section 3], intimate romantic scene, painterly oil painting style, dark
mythology, dramatic chiaroscuro lighting, tasteful, cinematic composition,
[lighting type: golden hour / candlelight / moonlight], highly detailed
```

### 5.1 Artemis CGs
1. **intimate_1** — Sitting together by a forest campfire at night, her head resting on your shoulder, bow set aside, moonlight and fire mixing on their faces
2. **intimate_2** — Moonlit pool, she's washing her hair (silver braid undone for the first time), looking back at you with a rare unguarded soft smile
3. **intimate_3** — Standing on a cliff at dawn, embracing, silver moonlight fading into gold sunrise on both of them

### 5.2 Hippolyta CGs
1. **intimate_1** — Sharing wine at a rowdy Amazon feast, her arm thrown around your shoulders, full laugh, spear propped against the wall
2. **intimate_2** — A training spar that became a kiss, both sweaty, spears dropped on sandy ground, her hand behind your neck
3. **intimate_3** — Bronze armor removed for the first time, sitting at the foot of a bed, foreheads touching, scars exposed

### 5.3 Atenea CGs
1. **intimate_1** — Night library, studying scrolls side by side, your hands touching over a book, candlelight, lightning arcs softened to a glow
2. **intimate_2** — Rooftop during a lightning storm, she's pointing at constellations, rain on both faces, not flinching from the thunder
3. **intimate_3** — She's writing something for you, quill in hand, blushing (rare), Lichtenberg scars visible on bare shoulder

### 5.4 Nyx CGs
1. **intimate_1** — Floating together in a cosmic void, stars all around, she's reaching toward you, her form more solid than usual
2. **intimate_2** — Garden of black roses at midnight, she's offering you a single flower, star motes concentrated between your hands
3. **intimate_3** — Dream realm, silhouetted together against a blood moon, her hair wrapping protectively around both of you

### 5.5 Quest Companion CGs (post-quest unlock)

Each quest companion who becomes romanceable gets **2 CGs** (unlocked at intimacy milestones):

| Companion | CG 1 | CG 2 |
|-----------|-------|-------|
| Daphne | Planting a garden together at dawn, hands in earth | Her weaving a flower crown for you in a moonlit meadow |
| Circe | Potion-making lesson, her guiding your hands, faces close | Rooftop of her tower, watching her city, her head on your shoulder |
| Thetis | Walking the shoreline at twilight, waves parting for her | Underwater grotto, her showing you bioluminescent coral, sharing air |
| Echo | She sings for the first time (post-quest), tears on her face, you listening | Sitting in ruins at sunrise, her head on your lap, lyre beside her |
| Lyra | Closing time, dancing alone in the empty tavern, firelight | Dawn on the tavern roof, sharing breakfast, her hair down for once |
| Melina | Sneaking into the forbidden library together, candlelight, stifling giggles | Sitting under the great tree reading her journal to you, sunset |
| Naida | She emerges fully from the river for the first time, reaching for your hand | Twilight river, floating together, her not hiding for once |

---

## 6. Scene Backgrounds

**Dimensions**: 430x932 (portrait) or 1080x1920 (will be scaled)
**Format**: PNG or JPG | **Path**: `assets/images/backgrounds/{area_id}.png`

### 6.1 magical_forest
```
dark ancient forest at night, massive trees with glowing root systems,
moonlight filtering through dense canopy creating god-rays, luminescent
mushrooms on fallen columns covered in moss, low mist, bronze age
greek wilderness feel, painterly, portrait orientation, room for UI
overlay at bottom
```

### 6.2 sardis_village
```
ancient greek village in a forest clearing, stone cottages with
thatched roofs, massive sacred tree dominating the background reaching
into amber clouds, warm torchlight along paths, dusk golden hour,
painterly bronze age, portrait orientation
```

### 6.3 golden_fleece_tavern
```
dim bronze age tavern interior, heavy wooden beams, hanging oil lamps
casting warm pools, amphorae of wine on shelves, low wooden tables
with benches, warriors drinking in shadow, large stone hearth with
roaring fire, painterly dark fantasy, portrait orientation
```

### 6.4 mount_tmolus
```
ancient greek mountain pass at dawn, gnarled pine trees clinging to
wind-swept cliffs, waterfall catching first light in the distance,
misty valley below, bronze age stone markers along path, painterly
dramatic landscape, portrait orientation
```

### 6.5 amazon_camp
```
circular Amazon training arena with packed sand floor, stone columns
around the edges hung with bronze shields, weapon racks with spears
and swords, torches at dusk casting long shadows, war banners, bronze
age greek, painterly, portrait orientation
```

### 6.6 gaia_tree_temple
```
hidden temple beneath massive sacred tree, living roots twisted into
walls and arches, emerald bioluminescent runes carved in ancient stone,
moss carpet, ethereal green light filtering down through root gaps,
sense of deep earth and ancient power, painterly, portrait orientation
```

### 6.7 coastal_grotto
```
sea cave grotto opening to twilight ocean, bioluminescent coral and
anemones on cave walls, pearl-like formations, tide pools reflecting
starlight, ocean mist, dark blue-green palette with silver highlights,
painterly, portrait orientation
```

### 6.8 sardis_ruins
```
crumbling marble temple ruins in moonlight, broken columns casting long
shadows, overgrown with ivy and small white flowers, silver mist pooling
on stone floor, sense of lost grandeur, desaturated almost monochrome,
painterly, portrait orientation
```

### 6.9 sardis_river
```
gentle river at twilight, reeds and water grasses along the banks,
stepping stones across shallow water, weeping willows, fireflies,
warm-to-cool gradient sky (amber horizon to deep blue), painterly,
portrait orientation
```

### 6.10 splash_title
```
wide cinematic view of fallen Olympus at dusk, shattered marble
columns and broken god-statues, golden clouds with dark storm beneath,
a single beam of golden light breaking through, epic scale with room
for title text at top third, painterly, portrait orientation
```

### 6.11 camp_hub
```
cozy camp beneath the sacred tree at evening, stone hearth with warm
fire, rough wooden benches with blankets, scattered personal items,
stars visible through canopy gaps, warm amber light, peaceful safe
feeling, painterly, portrait orientation
```

---

## 7. UI Icons

**Dimensions**: 128x128 or 256x256 | **Format**: PNG transparent
**Path**: `assets/images/icons/{icon_id}.png`

**Prompt template:**
```
[description], game UI icon, bronze age greek style, gold and dark
brown palette, flat painterly, centered on transparent background,
clean crisp edges
```

| Icon ID | Description |
|---------|-------------|
| `gold_coin` | Ancient drachma coin, gold with worn embossed owl, subtle glow |
| `element_fire` | Stylized flame, red-orange core, ember particles |
| `element_water` | Stylized water drop, deep blue with inner glow |
| `element_earth` | Stylized leaf-and-root knot, emerald green |
| `element_lightning` | Stylized jagged bolt, yellow-gold with violet outline |
| `element_neutral` | Silver circle with subtle mist wisps |
| `bond_shard` | Crystalline shard, purple-gold facets, divine glow |
| `blessing_star` | Divine gold five-pointed star with soft rays |
| `heart_intimacy` | Painted heart, warm red, slightly worn texture |
| `rank_b` | Bronze circle with "B" embossed |
| `rank_a` | Silver circle with "A" embossed |
| `rank_s` | Gold circle with "S" embossed, subtle shimmer |
| `rank_ss` | Gold circle with "SS" embossed, strong divine glow |

---

## 8. Combat Cards

**Dimensions**: 256x384 | **Format**: PNG
**Path**: `assets/images/cards/{suit}_{value}.png`

52 cards (4 suits x 13 values). Template approach recommended.

**Card back:**
```
ancient greek playing card back, central gold medallion featuring the
sacred tree of Sardis, bronze frame with geometric greek key border,
dark brown leather parchment texture, mystical atmosphere
```

**Card face per suit:**
```
ancient greek playing card, [element motif] as central illustration
(hearts=fire, diamonds=lightning, clubs=earth, spades=water),
bronze frame, [value] in greek-styled numerals at corners, aged
parchment background, painterly
```

---

## 9. VFX Sprites

**Dimensions**: 512x512 transparent | **Path**: `assets/vfx/{effect_id}.png`

| Effect | Prompt |
|--------|--------|
| `fire_burst` | Explosion of embers and flame, orange-red, radial, transparent bg |
| `water_splash` | Stylized wave crest with spray and foam, deep blue, transparent bg |
| `earth_crack` | Rock shatter with debris and dust, brown-green, transparent bg |
| `lightning_arc` | Jagged electric bolt, white-violet, branching, transparent bg |
| `gold_sparkle` | Divine gold particle cluster, warm shimmer, transparent bg |
| `heal_motes` | Rising green-gold leaf particles, gentle, transparent bg |
| `shield_dome` | Translucent golden hemisphere, greek key pattern at edge |
| `level_up_ring` | Expanding ring of warm white light with gold particles |

---

## 10. Generation Workflow

### Pipeline per Asset Type

| Asset | Technique | Notes |
|-------|-----------|-------|
| Character sheet (1/companion) | Manual curation | Best of 20+ at 768x1024 |
| Mood portraits (6/companion) | IPAdapter FaceID + img2img | Weight 0.8, denoise 0.4-0.55 on sheet |
| Intimate CGs | Character LoRA + OpenPose ControlNet | Best outfit + face consistency |
| Multi-character CGs | LoRA per char + Regional Prompter | One region per character |
| Backgrounds | Direct prompt | Batch similar locations for consistency |
| Icons/Cards | Template + inpainting | Generate per-suit template, inpaint values |

### Character Consistency Techniques (priority order)

1. **Character LoRA** (gold standard) — Train on 10-20 curated images per character using Kohya_ss. SDXL: 2000-4000 steps at lr 1e-4. Use trigger word at weight 0.8-1.0. Captures face + outfit + body.

2. **IPAdapter FaceID Plus v2** (fast, no training) — Feed one reference portrait into `ip-adapter-faceid-plusv2_sdxl.bin` at weight 0.7-0.9. Face locks hard; clothes drift slightly.

3. **PuLID** (fastest) — Lightweight face-ID preservation. Good for mood variants. Less outfit consistency than LoRA.

4. **OpenPose ControlNet** (for posed shots) — Extract pose skeleton, combine with IPAdapter or LoRA for CG scenes.

5. **Regional Prompter** (multi-character) — `ComfyUI Impact Pack` to prompt different image regions independently. Essential for 2+ characters.

### Checkpoints (2025-2026)

- **Juggernaut XL v9** + painterly LoRA — best match for dark mythology aesthetic
- **Flux.1 dev** — best prompt following, slower generation
- **RealVisXL v4** — alternative to Juggernaut, softer rendering

### Minimum Viable Pipeline

1. Install ComfyUI + ComfyUI-IPAdapter-plus
2. Generate character sheet per companion (best of 20+)
3. Use sheet as IPAdapter FaceID reference for all mood variants
4. Repeat for each companion, batch similar backgrounds

---

## 11. Priority Order

Generate in this order if time-constrained:

1. **Artemis** neutral + happy + sad (90% of Chapter 1)
2. **Forest background** (first scene)
3. **Hippolyta** neutral + angry (Ch1 boss buildup)
4. **Sardis Village** background
5. **Priestess** neutral (temple scenes)
6. **Gaia Spirit** boss enemy
7. Artemis + Hippolyta full mood sets (6 each)
8. Remaining backgrounds (tavern, mountains, ruins, river, grotto)
9. **Atenea + Nyx** full mood sets (Ch2-3)
10. Quest companions by quest availability (Daphne/Lyra/Echo first)
11. Card faces (52 cards)
12. CG intimacy scenes (late-game content, lowest priority)

---

## 12. File Naming Reference

```
assets/images/companions/{id}/{id}_{mood}.png
assets/images/cg/{id}_intimate_{n}.png
assets/images/enemies/{enemy_id}.png
assets/images/backgrounds/{area_id}.png
assets/images/icons/{icon_id}.png
assets/images/cards/{suit}_{value}.png
assets/vfx/{effect_id}.png
```

**Companion IDs**: `artemis`, `hipolita`, `atenea`, `nyx`, `priestess`, `daphne`, `circe`, `thetis`, `echo_bard`, `lyra`, `melina`, `old_kostas`, `village_leader`, `naida`

**Moods**: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`

**Enemies**: `forest_monster`, `mountain_beast`, `amazon_challenger`, `gaia_spirit`, `sardis_bandit`, `corrupted_nymph`
