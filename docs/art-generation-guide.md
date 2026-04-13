# Dark Olympus — Art Generation Guide for ComfyUI

This document lists all visual assets the game needs, with suggested prompts for ComfyUI (SDXL / Flux / Pony-based checkpoints). All assets should target the **430x932 portrait mobile viewport** and follow the **Dark Mythology** aesthetic.

---

## Global Style Reference

**Aesthetic pillars:**
- Dark mythology, fallen gods, Greek bronze age
- Muted palette: deep browns, near-black backgrounds, burnished gold accents (#D4A843), muted cream text (#F5E6C8)
- Painterly / semi-realistic, NOT anime. Think "Hades" (Supergiant) meets "Darkest Dungeon"
- Dramatic chiaroscuro lighting, oil-painting texture
- Greek / Bronze Age wardrobe (chitons, bronze armor, leather wraps)
- Divine details (subtle glow, floating motes, element-themed effects)

**Negative prompts (always include):**
```
anime, cel shading, cartoon, flat colors, modern clothing, sci-fi,
low quality, blurry, bad anatomy, extra limbs, text, watermark,
bright saturated colors, clean background
```

**Base positive suffix (always append):**
```
painterly, oil painting texture, dramatic chiaroscuro lighting,
dark mythology, bronze age greek, muted palette, gold accents,
cinematic composition, masterpiece, highly detailed
```

---

## 1. Companion Portraits

**Dimensions:** 768x1024 (tall portrait, will be cropped to 430x600 display area)
**Format:** PNG with transparent background preferred (or solid dark bg)
**Output path:** `src/assets/images/companions/{companion_id}/{companion_id}_{mood}.png`

Each companion needs **6 moods**: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`

**Generation tip:** Use the neutral version as a reference/img2img seed for the other 5 moods to keep facial features consistent. Or use the same seed with just the expression changed in the prompt.

### 1.1 Artemis — Goddess of the Hunt

**Core description:**
Silver-haired huntress, early 20s, athletic build, sharp green eyes. Wearing a short dark-green hunting chiton with leather straps, silver circlet, a recurve bow slung over her shoulder. Quiver visible. Subtle moonlight glow on her skin.

**Prompt base:**
```
portrait of Artemis greek goddess of the hunt, silver hair in a long braid,
sharp green eyes, athletic young woman, dark green hunting chiton,
leather straps, bronze circlet, recurve bow over shoulder, leather quiver,
subtle silver moonlight glow, forest canopy background, dark painterly style
```

**Mood variations:**
- `neutral`: calm, watchful, slight frown of concentration
- `happy`: soft smile, softer eyes, relaxed posture
- `sad`: downcast eyes, bow lowered, melancholy
- `angry`: teeth bared, bow drawn, furious glare
- `surprised`: wide eyes, lips parted, bow half-raised
- `seductive`: half-smile, direct gaze at viewer, one strap slipped off shoulder

### 1.2 Hipolita — Queen of the Amazons

**Core description:**
Crimson-haired warrior queen, mid 20s, muscular and scarred, amber eyes. Bronze breastplate over red leather, spear in hand, war paint on one cheek. Fierce and unbowed. Fire motes around her.

**Prompt base:**
```
portrait of Hipolita Amazon queen, long wild crimson hair, amber eyes,
muscular warrior woman with battle scars, bronze breastplate armor,
red leather and wraps, iron spear, red war paint stripe on cheek,
subtle fire ember motes around her, burning village in distance,
dark painterly style
```

**Mood variations:**
- `neutral`: commanding stance, spear planted
- `happy`: cut-steel grin, spear raised in salute
- `sad`: hand on chest, spear lowered, grief in her eyes
- `angry`: snarling, spear mid-swing, fire glow intensifies
- `surprised`: wide eyes, spear half-raised in guard
- `seductive`: predatory smile, leaning on spear, one hand on hip

### 1.3 Atenea — Goddess of Wisdom

**Core description:**
Black-haired strategist, late 20s, tall and regal, storm-gray eyes. Wearing an elegant indigo chiton with silver embroidery, owl brooch, scroll in one hand. Lightning motes crackle around her fingers.

**Prompt base:**
```
portrait of Athena greek goddess of wisdom, long black hair with silver streaks,
storm gray eyes, tall regal woman, indigo chiton with silver embroidery,
silver owl brooch, rolled scroll in hand, electric lightning motes around fingers,
library columns in background, dark painterly style
```

**Mood variations:**
- `neutral`: serene, analytical, scroll half-read
- `happy`: subtle knowing smile, eyes bright with interest
- `sad`: downcast, hand covering mouth
- `angry`: cold fury, lightning crackling stronger
- `surprised`: one eyebrow raised, scroll forgotten
- `seductive`: coy smirk, scroll set aside, direct eye contact

### 1.4 Nyx — Primordial Goddess of Night

**Core description:**
Midnight-haired, age indeterminate, ethereal and otherworldly. Violet-black eyes like galaxies. Wearing a flowing black robe with star patterns, crown of dark thorns. Star motes float around her. She barely seems solid.

**Prompt base:**
```
portrait of Nyx primordial goddess of night, flowing midnight black hair,
deep violet eyes like galaxies, ethereal otherworldly woman,
flowing black star-patterned robe, dark thorn crown, semi-transparent form,
star motes floating around her, cosmic void background,
dark painterly style, hauntingly beautiful
```

**Mood variations:**
- `neutral`: distant, unreadable, floating hair
- `happy`: rare soft smile, star motes brighter
- `sad`: single cosmic tear, hair drifting lower
- `angry`: black flames around hands, eyes blazing violet
- `surprised`: lips parted, star motes scatter outward
- `seductive`: veiled come-hither look, robe slipping open at the collarbone

### 1.5 Priestess — Gaia Fragment

**Core description:**
Emerald-haired, age ambiguous, ethereal and partially translucent. Emerald-green eyes that glow faintly. Wearing a robe woven from leaves and silver thread. Soft green aura.

**Prompt base:**
```
portrait of ancient priestess of Gaia, long emerald green hair,
glowing emerald eyes, ethereal semi-transparent woman,
robe woven from living leaves and silver thread, crown of vines,
soft green bioluminescent aura, ancient tree roots behind her,
dark painterly style
```

**Mood variations:**
- `neutral`: serene, hands clasped in prayer
- `happy`: benevolent smile, leaves rustle
- `sad`: wilting leaves in her hair, bowed head
- `angry`: thorns grow from vines, stern glare
- `surprised`: leaves scatter, eyes wide
- `seductive`: ***NOT NEEDED*** (she's a non-romanceable NPC, just skip or reuse neutral)

---

## 2. Enemy Portraits

**Dimensions:** 512x512 (combat enemy display)
**Format:** PNG
**Output path:** `src/assets/images/enemies/{enemy_id}.png`

### 2.1 forest_monster (Tutorial)
```
twisted corrupted wolf creature with glowing red eyes,
bronze age forest setting, dark fur matted with black ooze,
dripping dark divine energy, painterly dark fantasy
```

### 2.2 mountain_beast
```
massive stone and muscle beast, bear-like but twisted,
glowing cracks in stone hide, mountain pass background,
bronze age dark fantasy, painterly
```

### 2.3 amazon_challenger
```
fierce Amazon warrior woman sparring opponent, bronze armor,
short red hair, confident smirk, leather wraps, iron sword,
dark training ground background, painterly bronze age
```

### 2.4 gaia_spirit (Chapter 1 Boss)
```
massive corrupted earth elemental, body of cracked stone and
dying roots, emerald cracks leaking dark energy, ancient face
half-formed in the rock, temple ruins background,
dark painterly fantasy boss, epic scale
```

---

## 3. CG / Intimacy Scene Art

**Dimensions:** 1024x1024 or 1280x720
**Format:** PNG
**Output path:** `src/assets/images/cg/{companion_id}_intimate_{1-3}.png`

Each companion has **3 intimacy scenes** (12 total CGs). These are tasteful, painterly scenes — NOT explicit. Think romance visual novel book covers.

### 3.1 Artemis CGs
1. **intimate_1** — Sitting together by a campfire in the forest at night, sharing a bow, her head on your shoulder
2. **intimate_2** — Moonlit pool, she's washing her hair, looking back at you with a soft smile
3. **intimate_3** — Standing on a cliff at dawn, embracing, silver light on both of you

### 3.2 Hipolita CGs
1. **intimate_1** — Sharing wine at a rowdy Amazon feast, her arm around your shoulders, laughing
2. **intimate_2** — Training spar that turned into a kiss, sweaty, spears dropped on the ground
3. **intimate_3** — Armor removed, sitting at the foot of a bed, forehead to forehead

### 3.3 Atenea CGs (Ch2+)
1. **intimate_1** — Library at night, studying scrolls together, candlelight
2. **intimate_2** — Rooftop under lightning storm, she's explaining constellations
3. **intimate_3** — She's writing a poem for you, quill in hand, blushing

### 3.4 Nyx CGs (Ch3+)
1. **intimate_1** — Floating in a cosmic void, stars behind you both, she's reaching out
2. **intimate_2** — Midnight garden of black roses, she's offering you a flower
3. **intimate_3** — Dream realm, both of you silhouetted against a blood moon

**Prompt template for CGs:**
```
[scene description], [companion name] described as [core description],
intimate romantic scene, painterly oil painting style, dark mythology,
dramatic chiaroscuro lighting, tasteful, cinematic composition,
golden hour / candlelight / moonlight, highly detailed, masterpiece
```

---

## 4. Scene Backgrounds

**Dimensions:** 430x932 (portrait) or 1080x1920 (will be scaled)
**Format:** PNG or JPG
**Output path:** `src/assets/images/backgrounds/{area_id}.png`

### 4.1 Forest (tutorial + Artemis rescue)
```
dark ancient forest at night, moonlight filtering through canopy,
glowing mushrooms, fallen columns covered in moss, mist,
bronze age greek wilderness, painterly dark fantasy background,
portrait orientation
```

### 4.2 Sardis Village
```
ancient greek village in a forest clearing, stone cottages with thatched roofs,
massive sacred tree in the background reaching into clouds,
warm torchlight, dusk, painterly bronze age, portrait orientation
```

### 4.3 Golden Fleece Tavern
```
dim bronze age tavern interior, wooden beams, hanging oil lamps,
amphorae of wine, low wooden tables, warriors drinking in shadow,
warm firelight, painterly dark fantasy, portrait orientation
```

### 4.4 Mount Tmolus
```
ancient greek mountain pass at dawn, pine trees clinging to cliffs,
waterfall in the distance, misty valley below, bronze age ruins,
painterly dramatic landscape, portrait orientation
```

### 4.5 Amazon Training Grounds
```
circular training arena with sand floor, stone columns around the edges,
weapon racks with bronze swords and spears, torchlight at dusk,
bronze age greek, painterly, portrait orientation
```

### 4.6 Gaia's Tree Temple
```
hidden temple at the base of a massive tree, roots twisting into walls,
emerald glowing runes carved in stone, bioluminescent moss,
ethereal green light, painterly dark fantasy, portrait orientation
```

### 4.7 Splash/Title Background
```
wide cinematic view of fallen Olympus at dusk, broken columns,
ancient statues of gods in ruins, golden clouds, dramatic sky,
painterly epic fantasy, portrait orientation, room for title text at top
```

### 4.8 Hub/Camp Background
```
cozy camp under the great tree of Sardis, stone hearth,
wooden benches, warm firelight, stars visible through canopy,
painterly bronze age, portrait orientation, peaceful mood
```

---

## 5. UI Icons

**Dimensions:** 128x128 or 256x256
**Format:** PNG with transparency
**Output path:** `src/assets/images/icons/{icon_id}.png`

Needed icons:
- `gold_coin` — bronze age drachma, gold glowing
- `element_fire` — stylized flame, red-orange
- `element_water` — stylized water drop, deep blue
- `element_earth` — stylized leaf/root, emerald green
- `element_lightning` — stylized bolt, yellow-gold
- `suit_hearts` — painted red heart, worn
- `suit_diamonds` — painted blue diamond, worn
- `suit_clubs` — painted green clover, worn
- `suit_spades` — painted black spade, gold trim
- `token` — bronze interaction token
- `streak_flame` — small flame for streak counter
- `blessing_star` — divine gold star for blessing slots
- `heart_relationship` — romance indicator

**Prompt template:**
```
[icon description], game UI icon, bronze age greek style,
gold and dark brown palette, flat painterly style,
centered on transparent background, clean edges
```

---

## 6. Combat Cards

**Dimensions:** 256x384 (card aspect ratio)
**Format:** PNG
**Output path:** `src/assets/images/cards/{suit}_{value}.png`

52 cards total (4 suits × 13 values). Use a template approach:

**Card back:**
```
ancient greek playing card back, painterly design with central gold
medallion featuring sacred tree, bronze frame, dark brown leather
texture, mystical, portrait card orientation
```

**Card face template:**
```
ancient greek playing card, [suit element] in the center
(fire/water/earth/lightning motif), bronze frame, [value] greek numerals
at top and bottom corners, aged parchment background,
painterly bronze age style, portrait orientation
```

Suggested approach: Generate one template per suit, then use img2img or inpainting to swap the value numeral.

---

## 7. VFX Sprites

**Dimensions:** 512x512 (will be scaled)
**Format:** PNG with transparency
**Output path:** `src/assets/vfx/{effect_id}.png`

- `fire_burst` — explosion of embers
- `water_splash` — stylized wave
- `earth_crack` — rock shatter effect
- `lightning_arc` — jagged electric bolt
- `gold_sparkle` — divine gold particles
- `heart_burst` — romance heart explosion
- `level_up_ring` — expanding ring of light

---

## Generation Workflow Tips

1. **Consistency first**: Generate all companion `neutral` portraits first using the same seed family. Lock in their face, hair, and outfit before moving to other moods.

2. **Use img2img for mood variants**: Take the neutral portrait and use low-denoise img2img (0.35-0.5) with the mood prompt added.

3. **Upscale at the end**: Generate at 768x1024, upscale 2x with a good upscaler (4x-UltraSharp or similar) to 1536x2048, then Godot can import and scale down cleanly.

4. **Batch similar assets**: All 4 elements → 4 similar icon prompts in a batch. All 4 suits → 4 similar card backs in a batch. Keeps visual consistency.

5. **Save prompts + seeds**: Keep a spreadsheet of prompt + seed + model for each asset so you can regenerate variations later.

6. **Color grade in post**: Even if ComfyUI output is slightly off-palette, a quick curves/color adjustment in Krita/GIMP can lock everything into the dark mythology palette. Target: deep browns (#2A1F14), gold accents (#D4A843), muted cream (#F5E6C8).

---

## Character Consistency (Face, Body, Clothes)

The game needs each companion to look identical across 6 moods, 3 CG scenes, and potentially multiple poses/angles. Naive prompting alone will not give you that. Here are the techniques that actually work in ComfyUI, ranked by reliability.

### Technique 1 — Character Sheet + IPAdapter FaceID (recommended first pass)

**What**: Generate one reference image that locks in the character's face, body, and outfit. Then use IPAdapter FaceID to transfer that identity into every subsequent generation.

**Steps:**
1. **Generate the character sheet.** Full-body shot, neutral pose, plain background, detailed prompt covering face + hair + eyes + outfit + body type. Pick the best out of ~20 generations. Save the seed.
2. **Install ComfyUI custom nodes**: `ComfyUI-IPAdapter-plus`, `ComfyUI-ReActor` (face swap), `ComfyUI_InstantID` (optional).
3. **Load IPAdapter FaceID Plus v2** (`ip-adapter-faceid-plusv2_sdxl.bin` for SDXL checkpoints).
4. **Build a workflow**: `Checkpoint → CLIPTextEncode → IPAdapter FaceID (with reference image) → KSampler → VAEDecode`. Weight around 0.7-0.9 for strong identity lock.
5. **For each new pose/mood**: keep the same reference image fed into IPAdapter, vary only the prompt (expression, pose, background). Face stays consistent.

**Why it works**: IPAdapter FaceID extracts an embedding from the reference face and injects it into every generation step. Clothes and body drift slightly but face is locked hard.

### Technique 2 — Character LoRA (gold standard if you can train)

**What**: Train a small LoRA on 10-20 reference images of the character. Works for SD 1.5, SDXL, Flux.

**Steps:**
1. Generate (or collect) 10-20 varied shots of the character: different angles, lighting, expressions. Keep face + clothes consistent across them.
2. Caption each with a consistent trigger word (e.g. `darkolympus_artemis, silver hair, green hunting chiton, bronze circlet`).
3. Train with **Kohya_ss** or **ComfyUI LoRA Trainer**. For SDXL, 2000-4000 steps at learning rate 1e-4 is usually enough. RunPod or a local 24GB GPU.
4. Use the LoRA at weight 0.8-1.0 in every prompt: `<lora:darkolympus_artemis:0.9>`.
5. The LoRA captures face **and** outfit, so body/clothes stay consistent across moods and CGs.

**When to use**: If IPAdapter alone isn't giving you outfit consistency, or if you need the character in dozens of scenes. Worth the 1-2 hour setup investment per main companion.

### Technique 3 — PuLID (fast, no training)

**What**: PuLID (2024) is a lightweight face-ID preservation node that's faster than IPAdapter and often better at blending the reference face into new poses.

**Steps:**
1. Install `ComfyUI_PuLID_Flux_ll` (for Flux) or `ComfyUI_PuLID` (for SDXL).
2. Load one or more reference face shots.
3. Chain: `Checkpoint → PuLID Apply → KSampler`.
4. PuLID blends face identity without freezing pose or clothes — good for mood variants on a fixed body.

**When to use**: Quick iteration. Not as strong for outfit consistency as a LoRA, but much faster setup.

### Technique 4 — Reference-Only ControlNet + OpenPose

**What**: For pose-specific shots (CGs, intimate scenes, action poses) combine:
- **Reference-Only ControlNet** — copies style/look from a reference image without training
- **OpenPose ControlNet** — locks the body pose from a pose-reference image

**Steps:**
1. Generate pose skeletons with OpenPose Editor (or extract from a stock photo).
2. Use your character sheet as the reference-only input.
3. ControlNet weight 0.7 for both, so the KSampler can still follow the prompt for facial expression.

**When to use**: CG scenes where you need the character in a specific pose (sitting by a fire, reaching out, etc.). Combines well with IPAdapter FaceID for maximum consistency.

### Technique 5 — Regional Prompting (for multi-character scenes)

**What**: Use `ComfyUI Impact Pack` or `Regional Prompter` to prompt different regions of the image independently. Lets you put Artemis on the left with her outfit and Hippolyta on the right with hers, without prompt bleed.

**When to use**: CG scenes with 2+ companions (e.g. final Ch1 threesome, tavern scene).

---

### Recommended Workflow per Asset

| Asset type | Technique | Notes |
|---|---|---|
| Character sheet (1 per companion) | Manual curation | Pick best of 20 at base resolution |
| Mood portraits (6 per companion) | IPAdapter FaceID + img2img on sheet | Weight 0.8, denoise 0.4-0.55 |
| Intimate CGs (3 per companion) | LoRA + OpenPose ControlNet | Best consistency for poses |
| Action/combat stills | IPAdapter FaceID + Reference-Only ControlNet | Face locked, pose free |
| Multi-character scenes | LoRA per character + Regional Prompter | One region per character |

### Checkpoint Recommendations (2025)

- **Flux.1 dev** — Best general coherence, great prompt following, but slower (~30s per image on 24GB)
- **Pony Diffusion XL** — Strong for characters but has an anime lean; good base for fantasy with proper negatives
- **Juggernaut XL v9** — Photorealistic fantasy, excellent for the dark mythology aesthetic
- **RealVisXL v4** — Alternative to Juggernaut, slightly softer

For Dark Olympus's painterly look, I'd start with **Juggernaut XL v9** + a painterly LoRA (search CivitAI for "oil painting SDXL") + IPAdapter FaceID.

### Minimum Viable Pipeline (if you only set up one thing)

1. Install ComfyUI + ComfyUI-IPAdapter-plus
2. Generate Artemis character sheet (best of 20 at 1024x1536)
3. Use that sheet as IPAdapter FaceID reference for all her mood portraits
4. Repeat for each companion

That alone gives you usable consistent portraits. The LoRA/ControlNet techniques add quality but aren't required.

---

## Priority Order for Generation

If time is limited, generate in this order:

1. **Artemis neutral + happy + sad** (she's in 90% of Chapter 1)
2. **Forest background** (first scene the player sees)
3. **Hipolita neutral + angry** (Chapter 1 boss fight buildup)
4. **Sardis Village background**
5. **Priestess neutral** (temple scenes)
6. **Gaia Spirit boss**
7. **Artemis + Hipolita full mood sets** (6 each)
8. **Remaining backgrounds** (tavern, mountains, arena, temple)
9. **Card faces** (52 cards)
10. **Atenea + Nyx full sets** (Chapter 2-3 content, can wait)
11. **CG intimate scenes** (locked behind late-game romance stages)

---

## File Naming Reference

All paths are relative to `src/`. The game expects:

```
assets/images/companions/{id}/{id}_{mood}.png
assets/images/cg/{id}_intimate_{n}.png
assets/images/enemies/{enemy_id}.png
assets/images/backgrounds/{area_id}.png
assets/images/icons/{icon_id}.png
assets/images/cards/{suit}_{value}.png
assets/vfx/{effect_id}.png
```

Where `{id}` is: `artemis`, `hipolita`, `atenea`, `nyx`, `priestess`
Where `{mood}` is: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`
