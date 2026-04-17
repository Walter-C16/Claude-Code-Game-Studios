# Dark Olympus — Art Prompt Checklist

> Quick-reference sheet: every image asset the game needs, with copy-paste prompts.
> For design philosophy, color palettes, and LoRA training details, see `art-generation-guide.md`.
>
> **Global suffix (append to ALL prompts):**
> ```
> painterly, oil painting texture, dramatic chiaroscuro lighting,
> dark mythology, bronze age greek, muted earth palette, gold accents,
> cinematic composition, masterpiece, highly detailed, depth of field
> ```
>
> **Global negative (include in ALL prompts):**
> ```
> anime, cel shading, cartoon, flat colors, modern clothing, sci-fi,
> low quality, blurry, bad anatomy, extra limbs, text, watermark,
> bright saturated colors, clean background, symmetrical face,
> generic fantasy, medieval european armor
> ```

---

## 1. Companion Portraits (768x1024, PNG transparent)

Path: `assets/images/companions/{id}/{id}_{mood}.png`
Moods: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`

**Total: 14 characters x 6 moods = 78 images** (minus 3 NPCs with no seductive = **75 images**)

---

### Artemis (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | watchful expression, bow at rest across back, slight frown of focus, scanning the treeline |
| `happy` | soft asymmetric smile left corner higher, relaxed shoulders, one hand resting on bow |
| `sad` | bow lowered to ground, looking down at scar on her hand, braid fallen forward |
| `angry` | teeth bared, bow drawn to full extension, gold-green eyes blazing, earth motes swirling fast |
| `surprised` | wide eyes, lips parted, hand snap-reaching for an arrow, braid swinging |
| `seductive` | half-lidded direct gaze, chin tilted down, one strap slipped from shoulder, moonlit clearing |

---

### Hippolyta (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | commanding stance, spear planted beside her, weight on back foot, chin raised |
| `happy` | full fierce grin showing teeth, spear raised in victory salute, embers surging |
| `sad` | hand pressed flat over scars on abdomen, spear resting on ground, staring at flames |
| `angry` | snarling, spear in mid-thrust position, embers becoming full flames around her |
| `surprised` | eyes wide, spear snapped up to guard position, hair flung back |
| `seductive` | predatory half-smile, leaning on spear shaft, one hand on bare hip, firelit |

---

### Atenea (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | serene expression, scroll half-read, right hand hovering with faint arcs, analyzing |
| `happy` | subtle knowing smile, eyes brightening violet glow intensifies, leaning forward with interest |
| `sad` | scroll closed, hand covering Lichtenberg scars, lightning dimmed, looking away |
| `angry` | cold fury, electric arcs expanding into full bolts, hair streaks blazing white, pupils constricting |
| `surprised` | both eyebrows up, scroll dropped, hand reflexively raised, sparks scattering |
| `seductive` | scroll set aside deliberately, chin resting on hand, direct violet-bright eye contact, faint smile |

---

### Nyx (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | distant gaze, hair drifting slowly, star motes in gentle orbit, unknowable expression |
| `happy` | rare soft smile that humanizes her, star motes brighten and orbit faster, eyes warm slightly |
| `sad` | single new cosmic tear forming, hair drifting downward, motes dimming |
| `angry` | black flames erupting from hands, galaxy eyes blazing violet-white, thorns growing, motes scattered |
| `surprised` | hair flares outward, motes scatter in all directions, lips parted |
| `seductive` | veil-like wisps of dark energy framing face, robe parting at collarbone, direct galaxy-eye contact |

---

### Priestess (5 images — no seductive)

**Base prompt:**
```
portrait of ancient priestess of Gaia earth mother, long emerald green
hair flowing like vines, glowing bioluminescent green eyes, ethereal
semi-translucent woman with green veins visible, robe woven from living
leaves and silver thread still growing, vine crown with small white
flowers blooming, bark-textured hands clasped in prayer, roots extending
from bare feet, soft green bioluminescent aura, ancient tree roots and
temple columns behind her
```

| Mood | Add to prompt |
|------|---------------|
| `neutral` | serene, hands clasped, eyes softly glowing, small flowers blooming in crown |
| `happy` | benevolent smile, leaves rustle and new buds appear, aura brightens |
| `sad` | flowers wilting in crown, head bowed, leaves curling, glow dimming |
| `angry` | thorns sprout from vines, stern green-blazing eyes, roots cracking stone |
| `surprised` | leaves scatter outward, eyes wide, flowers burst into sudden bloom |

---

### Daphne (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | shy half-smile, clutching basket protectively, looking slightly away |
| `happy` | beaming up from basket holding a perfect bloom, freckles emphasized by flush |
| `sad` | wilting flower in hand, looking away, basket set down, shoulders hunched |
| `angry` | eyes fierce and tear-filled, thorns pushing up from ground around her feet |
| `surprised` | basket dropped herbs spilling, hands to mouth, wide-eyed |
| `seductive` | flower crown she braided, bare shoulders, moonlit garden, looking directly at viewer |

---

### Circe (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | knowing smirk, staff resting in crook of arm, one hand with arcs between fingers |
| `happy` | genuine delighted laugh, magic sparking playfully around her, eyes crinkling |
| `sad` | staring into cracked crystal, seeing something painful, smirk gone, lips pressed |
| `angry` | staff raised crystal blazing white, ALL robe symbols lit at once, eyes white-gold, terrifying |
| `surprised` | crystal cracks further, both eyebrows up, genuinely caught off-guard |
| `seductive` | robes parted at chest, one potion vial uncorked held to lips, candlelit, heavy-lidded |

---

### Thetis (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | distant gaze past the viewer, pearl choker clasped, perpetual sadness |
| `happy` | rare warmth breaking through, ocean mist sparkles prismatically, genuine soft smile |
| `sad` | tears crystallizing into pearls rolling down cheeks, hair going still, mist thickening |
| `angry` | ocean surge behind her, tidal wall rising, eyes fully teal-blazing, commanding |
| `surprised` | water splashes outward, pearls scatter, eyes wide, hair flaring |
| `seductive` | emerging from moonlit water, wet iridescent skin glistening, direct teal-bright gaze |

---

### Echo (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | near a broken column, mouth slightly open, hands reaching toward nothing, silver mist pooling |
| `happy` | rare genuine smile, silver light brightening, holding a silver lyre, tears of relief |
| `sad` | kneeling among ruins, hair covering face completely, silver mist thick and low |
| `angry` | mist darkens to grey-black, columns cracking behind her, silent scream mouth wide open |
| `surprised` | mist scatters violently, hair blown back revealing full face, hand at throat |
| `seductive` | white shift slipping off both shoulders, ruins at warm sunset, direct eye contact |

---

### Lyra (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | hands on hips, friendly grin, mug nearby on counter, towel over shoulder |
| `happy` | full belly laugh eyes squeezed shut, holding up two mugs sloshing with mead |
| `sad` | wiping counter slowly in empty tavern, fire burned low, staring at key necklace |
| `angry` | broken mug on floor, pointing at the door, eyes flashing |
| `surprised` | mug spilling, eyes wide, catching falling tray one-handed, messy bun unraveling |
| `seductive` | apron untied and loose, leaning on bar, candlelit back room, warm knowing smile |

---

### Melina (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | reading journal one hand turning page, chin raised, curious expression |
| `happy` | showing open book excitedly with both hands, eyes bright, braids bouncing |
| `sad` | journal closed hugged tight to chest, looking at locked gate, braids limp |
| `angry` | journal slammed shut, defiant stance, ink-stained fists clenched, chin jutting |
| `surprised` | quill dropped, gasping, loose pages flying from journal, braids swinging wide |
| `seductive` | dress loosened at collar, reading by candlelight in forbidden library, ink on lips |

---

### Naida (6 images)

**Base prompt:**
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

| Mood | Add to prompt |
|------|---------------|
| `neutral` | half-submerged peeking from behind reeds, pearl glowing faintly, tentative |
| `happy` | emerging from water with droplets catching prismatic light, genuine surprised smile |
| `sad` | sitting on dry riverbank, hair flat and still no longer flowing, looking at empty river bed |
| `angry` | river churns and rises behind her, eyes fully iridescent-blazing, water cocoon forming |
| `surprised` | splash outward, ripples spreading in all directions, hair flaring |
| `seductive` | fully emerged in twilight, wet iridescent skin glistening, pearl glowing warm, direct eye contact |

---

### Old Kostas (5 images — no seductive)

**Base prompt:**
```
portrait of old greek fisherman, bushy grey beard, deeply tanned and
sun-wrinkled face with kind crinkled eyes, patched wide-brimmed straw
hat with fishing hook stuck in brim, sleeveless rough linen shirt with
sweat stains, worn leather vest with brass buckle, wooden fishing rod
over right shoulder with dangling line, missing front tooth visible in
easy grin, small brass hip flask, thick calloused hands with fishing
scars, river bank with morning mist and reeds background
```

| Mood | Add to prompt |
|------|---------------|
| `neutral` | squinting at water, rod over shoulder, easy grin |
| `happy` | belly laugh head thrown back, holding up a fish proudly, missing tooth on display |
| `sad` | staring at empty river, line slack, no grin |
| `angry` | shaking fist at sky, hat askew |
| `surprised` | rod bending hard, both hands on it, eyes wide |

---

### Thalos (5 images — no seductive)

**Base prompt:**
```
portrait of wise old greek village elder, long white beard braided at
the tip, kind but exhausted eyes with deep crow's feet, tall but
stooped posture, cream linen robe with simple dark leather belt, dull
tarnished gold circlet on brow, bronze clasp at collar shaped like
a leaf, gnarled carved walking staff of dark sacred-tree wood, thin
weathered hands with prominent veins, village square with massive
sacred tree spreading behind him
```

| Mood | Add to prompt |
|------|---------------|
| `neutral` | leaning on staff, thoughtful gaze toward sacred tree |
| `happy` | warm grandfatherly smile, eyes crinkling almost shut, hand on your shoulder |
| `sad` | head bowed, both hands on staff supporting full weight, circlet dipping |
| `angry` | standing fully upright, staff raised, commanding, suddenly not frail at all |
| `surprised` | staff clutched, eyes wide, circlet sliding |

---

## 2. Enemy Portraits (512x512, PNG)

Path: `assets/images/enemies/{enemy_id}.png`

**Total: 6 images**

### forest_monster
```
twisted corrupted wolf creature with glowing red eyes, body of matted
dark fur and black ooze, corrupted earth-brown energy dripping from
fangs, crouched attack pose, bronze age dark forest setting,
painterly dark fantasy, menacing but not overwhelming
```

### mountain_beast
```
massive stone-and-muscle bear creature, cracked granite hide with
glowing orange fissures, standing on hind legs roaring, mountain pass
with pine trees, bronze age dark fantasy painterly, boss-level scale
```

### amazon_challenger
```
fierce Amazon warrior sparring opponent, short-cropped red hair,
confident smirk, practical bronze chest armor and leather wraps,
iron short sword in guard stance, training arena torch-lit background,
painterly bronze age, she looks like she's enjoying this
```

### gaia_spirit
```
massive corrupted earth elemental, body of cracked stone and dying
roots twisted together, emerald fissures leaking dark corrupted energy,
ancient face half-formed in the rock surface screaming silently,
temple ruins background with shattered columns, dark painterly epic
fantasy boss, towering over the viewer, tragic not evil
```

### sardis_bandit
```
lean scrappy human bandit with improvised weapons, rough cloth mask
over lower face, leather jerkin patched with mismatched scraps, rusty
short blade, crouching in ambush pose, dusty road with olive trees,
painterly bronze age, desperate not villainous
```

### corrupted_nymph
```
once-beautiful water nymph twisted by dark divine corruption, skin
cracked like dried riverbed, hair that was once flowing water now
frozen into black crystal shards, glowing corrupted violet eyes,
ruined river shrine background, painterly dark fantasy, tragic
```

---

## 3. CG Intimacy Scenes (1024x1024 or 1280x720, PNG)

Path: `assets/images/cg/{id}_intimate_{n}.png`

**Total: 4 main companions x 3 CGs + 7 quest companions x 2 CGs = 26 images**

**Template — wrap each scene prompt with:**
```
[scene below], painterly oil painting style, dark mythology, dramatic
chiaroscuro lighting, tasteful romantic scene, cinematic composition,
[lighting], highly detailed, masterpiece
```

### Artemis (3 CGs)

| # | Scene | Lighting |
|---|-------|----------|
| 1 | Artemis and protagonist sitting by a forest campfire at night, her head on your shoulder, bow set aside, silver braid undone, moonlight and firelight mixing on faces | moonlight + firelight |
| 2 | Artemis at a moonlit forest pool, washing her silver hair (braid undone), looking back at viewer with rare unguarded soft smile | cold moonlight |
| 3 | Artemis and protagonist embracing on a cliff at dawn, silver moonlight fading into gold sunrise on both of them | sunrise golden hour |

### Hippolyta (3 CGs)

| # | Scene | Lighting |
|---|-------|----------|
| 1 | Hippolyta at a rowdy Amazon feast, arm thrown around protagonist's shoulders, full laugh, spear propped against wall, wine cups | warm torchlight |
| 2 | Hippolyta and protagonist after a training spar turned kiss, both sweaty, spears dropped on sandy ground, her hand behind your neck | dusk amber |
| 3 | Hippolyta with bronze armor removed for the first time, sitting at foot of a bed, foreheads touching, scars exposed and vulnerable | candlelight |

### Atenea (3 CGs)

| # | Scene | Lighting |
|---|-------|----------|
| 1 | Atenea and protagonist in a night library, studying scrolls side by side, hands touching over a book, lightning arcs softened to glow | candlelight + faint violet |
| 2 | Atenea on a rooftop during a lightning storm, pointing at constellations, rain on both faces, not flinching from thunder | storm light + flashes |
| 3 | Atenea writing something personal, quill in hand, blushing, Lichtenberg scars visible on bare shoulder, looking up at viewer | warm candlelight |

### Nyx (3 CGs)

| # | Scene | Lighting |
|---|-------|----------|
| 1 | Nyx and protagonist floating in cosmic void, stars all around, she reaching toward you, her form more solid than usual | starlight cosmic glow |
| 2 | Nyx in a midnight garden of black roses, offering a single flower, star motes concentrated between their hands | moonlight + star motes |
| 3 | Nyx and protagonist silhouetted together against a blood moon in dream realm, her hair wrapping protectively around both | blood moon red + violet |

### Quest Companions (2 CGs each)

| Companion | CG 1 | CG 2 |
|-----------|-------|-------|
| Daphne | Planting a garden together at dawn, hands in earth, soft smiles | Daphne weaving a flower crown for protagonist in moonlit meadow |
| Circe | Potion-making lesson, Circe guiding protagonist's hands over bubbling cauldron, faces close | Rooftop of her tower at night, watching the city lights, her head on protagonist's shoulder |
| Thetis | Walking the shoreline at twilight, waves parting for her, holding hands | Underwater grotto, Thetis showing protagonist bioluminescent coral, sharing air |
| Echo | Echo singing for the first time post-quest, tears on her face, protagonist listening in awe | Sitting in ruins at sunrise, Echo's head on protagonist's lap, silver lyre beside her |
| Lyra | Closing time, dancing alone together in empty tavern, firelight | Dawn on the tavern rooftop, sharing breakfast, Lyra's hair down for once |
| Melina | Sneaking into forbidden library together, single candle, stifling giggles | Under the great sacred tree at sunset, Melina reading her journal aloud to protagonist |
| Naida | Naida emerging fully from the river for the first time, reaching for protagonist's hand | Floating together in twilight river, Naida not hiding for once, peaceful |

---

## 4. Backgrounds (430x932 portrait or 1080x1920, PNG/JPG)

Path: `assets/images/backgrounds/{area_id}.png`

**Total: 11 images**

### magical_forest
```
dark ancient forest at night, massive trees with glowing root systems,
moonlight filtering through dense canopy creating god-rays, luminescent
mushrooms on fallen columns covered in moss, low mist, bronze age
greek wilderness, painterly, portrait orientation, room for UI at bottom
```

### sardis_village
```
ancient greek village in forest clearing, stone cottages with thatched
roofs, massive sacred tree dominating background reaching into amber
clouds, warm torchlight along paths, dusk golden hour, painterly,
portrait orientation
```

### golden_fleece_tavern
```
dim bronze age tavern interior, heavy wooden beams, hanging oil lamps
casting warm pools, amphorae of wine on shelves, low wooden tables,
large stone hearth with roaring fire, painterly, portrait orientation
```

### mount_tmolus
```
ancient greek mountain pass at dawn, gnarled pine trees clinging to
wind-swept cliffs, waterfall catching first light, misty valley below,
bronze age stone markers along path, painterly, portrait orientation
```

### amazon_camp
```
circular Amazon training arena packed sand floor, stone columns with
hung bronze shields, weapon racks with spears and swords, torches at
dusk casting long shadows, war banners, painterly, portrait orientation
```

### gaia_tree_temple
```
hidden temple beneath massive sacred tree, living roots twisted into
walls and arches, emerald bioluminescent runes in ancient stone, moss
carpet, ethereal green light filtering through root gaps, painterly,
portrait orientation
```

### coastal_grotto
```
sea cave grotto opening to twilight ocean, bioluminescent coral on cave
walls, pearl formations, tide pools reflecting starlight, ocean mist,
dark blue-green palette with silver highlights, painterly, portrait
```

### sardis_ruins
```
crumbling marble temple ruins in moonlight, broken columns casting long
shadows, overgrown with ivy and small white flowers, silver mist on
stone floor, lost grandeur, desaturated near-monochrome, painterly,
portrait orientation
```

### sardis_river
```
gentle river at twilight, reeds and water grasses along banks, stepping
stones, weeping willows, fireflies, warm-to-cool gradient sky amber
horizon to deep blue, painterly, portrait orientation
```

### splash_title
```
wide cinematic view of fallen Olympus at dusk, shattered marble columns
and broken god-statues, golden clouds with dark storm beneath, single
beam of golden light breaking through, room for title text at top third,
painterly epic, portrait orientation
```

### camp_hub
```
cozy camp beneath sacred tree at evening, stone hearth with warm fire,
rough wooden benches with blankets, scattered personal items, stars
through canopy gaps, warm amber light, peaceful, painterly, portrait
```

---

## 5. UI Icons (128x128 or 256x256, PNG transparent)

Path: `assets/images/icons/{icon_id}.png`

**Total: 13 images**

**Template:**
```
[description], game UI icon, bronze age greek style, gold and dark
brown palette, flat painterly, centered transparent background, crisp
```

| Icon | Prompt description |
|------|--------------------|
| `gold_coin` | ancient drachma coin gold with worn embossed owl subtle glow |
| `element_fire` | stylized flame red-orange core with ember particles |
| `element_water` | stylized water drop deep blue with inner glow |
| `element_earth` | stylized leaf-and-root knot emerald green |
| `element_lightning` | stylized jagged bolt yellow-gold with violet outline |
| `element_neutral` | silver circle with subtle mist wisps |
| `bond_shard` | crystalline shard purple-gold facets divine glow |
| `blessing_star` | divine gold five-pointed star with soft rays |
| `heart_intimacy` | painted heart warm red slightly worn texture |
| `rank_b` | bronze circle with B embossed |
| `rank_a` | silver circle with A embossed |
| `rank_s` | gold circle with S embossed subtle shimmer |
| `rank_ss` | gold circle with SS embossed strong divine glow |

---

## 6. Combat Cards (256x384, PNG)

Path: `assets/images/cards/{suit}_{value}.png`

**Total: 52 card faces + 1 card back = 53 images**

### Card back
```
ancient greek playing card back, central gold medallion featuring sacred
tree of Sardis, bronze frame with geometric greek key border, dark brown
leather parchment texture, mystical
```

### Card face template (per suit)
```
ancient greek playing card, [SUIT MOTIF] as central illustration,
bronze frame, [VALUE] in greek-styled numerals at corners, aged
parchment background, painterly
```

| Suit | Motif |
|------|-------|
| Hearts | fire flame motif, warm red-orange |
| Diamonds | lightning bolt motif, yellow-gold with violet |
| Clubs | earth leaf-root motif, emerald green |
| Spades | water wave motif, deep blue |

Values: A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K

---

## 7. VFX Sprites (512x512, PNG transparent)

Path: `assets/vfx/{effect_id}.png`

**Total: 8 images**

| Effect | Prompt |
|--------|--------|
| `fire_burst` | explosion of embers and flame, orange-red, radial burst, transparent background |
| `water_splash` | stylized wave crest with spray and foam, deep blue, transparent background |
| `earth_crack` | rock shatter with debris and dust cloud, brown-green, transparent background |
| `lightning_arc` | jagged electric bolt, white-violet, branching tendrils, transparent background |
| `gold_sparkle` | divine gold particle cluster, warm shimmer radiating, transparent background |
| `heal_motes` | rising green-gold leaf particles, gentle upward drift, transparent background |
| `shield_dome` | translucent golden hemisphere with greek key pattern edge, transparent background |
| `level_up_ring` | expanding ring of warm white light with gold particles, transparent background |

---

## Summary — Total Asset Count

| Category | Count |
|----------|-------|
| Companion portraits | 75 |
| Enemy portraits | 6 |
| CG intimacy scenes | 26 |
| Backgrounds | 11 |
| UI icons | 13 |
| Combat cards | 53 |
| VFX sprites | 8 |
| **TOTAL** | **192** |
