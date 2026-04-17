# Dark Olympus — Art Prompt Checklist

> Copy-paste prompts for every image asset. Based on the approved Artemis reference style.
> For design philosophy, palettes, and LoRA training, see `art-generation-guide.md`.
>
> **Base style (all character prompts follow this structure):**
> - Skin + archetype + hair + eyes
> - Outfit with worn/weathered details
> - Body features + elemental symbols on skin + elemental particles
> - Facial details (freckles, scars, marks)
> - Weighted expression, eye mood, looking at viewer, cowboy shot
> - White background
> - `masterpiece, best quality, highest quality, intricate details`
>
> **Global negative (include in ALL character prompts):**
> ```
> low quality, blurry, bad anatomy, extra limbs, text, watermark,
> deformed eyes, flat eyes, dull eyes, poorly drawn eyes,
> modern clothing, sci-fi
> ```

---

## 1. Companion Portraits (768x1024, PNG)

Path: `assets/images/companions/{id}/{id}_{mood}.png`
Moods: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`

**Total: 75 images**

---

### Artemis (6 images)

**Base prompt:**
```
Smooth skinned fallen huntress goddess with twin braids platinum-blonde
hair, yellow eyes, wearing worn leather archer outfit, battered quiver
on back, scuffed arm guards, weathered leather boots. Her body features:
big breasts, fading green mystic symbols along her arms, dim green
magical particles drift around her. She has faint freckles.
(smile:0.3), melancholic eyes, looking at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(smile:0.3), melancholic eyes, looking at viewer, cowboy shot,` |
| `happy` | `(gentle smile:0.7), warm soft eyes, looking at viewer, cowboy shot,` |
| `sad` | `(frown:0.3), downcast teary eyes looking down, cowboy shot,` |
| `angry` | `(scowl:0.6), fierce glaring eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(parted lips:0.5), wide eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(smirk:0.5), half-lidded bedroom eyes, looking at viewer, cowboy shot,` |

---

### Hippolyta (6 images)

**Base prompt:**
```
Smooth skinned fierce Amazon warrior queen with wild untamed long
crimson hair, amber eyes with orange ring around pupil, wearing
battered bronze breastplate over bare scarred midriff, crimson leather
battle skirt with bronze studs, heavy bronze arm band on left arm only,
weathered leather sandals with bronze shin guards. Her body features:
muscular athletic build, big breasts, battle scars across abdomen and
arms, spiraling burn scar up right arm, fading red-orange mystic fire
symbols across her shoulders, dim ember particles drift around her.
She has red war paint stripe across right cheekbone and nose, notched
left ear.
(fierce grin:0.4), burning determined eyes, looking at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(fierce grin:0.4), burning determined eyes, looking at viewer, cowboy shot,` |
| `happy` | `(wide grin:0.8), triumphant blazing eyes, looking at viewer, cowboy shot,` |
| `sad` | `(closed mouth:0.3), grieving distant eyes looking down, cowboy shot,` |
| `angry` | `(snarl:0.7), furious blazing eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(parted lips:0.4), wide alert eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(predatory smirk:0.5), intense half-lidded eyes, looking at viewer, cowboy shot,` |

---

### Atenea (6 images)

**Base prompt:**
```
Smooth skinned regal goddess of wisdom with long black hair with two
silver-white lightning-bolt streaks framing her face, storm-grey eyes
with violet electric ring around pupil, wearing elegant deep indigo
chiton with geometric silver embroidery, asymmetric silver shoulder cape
on left side, bare right shoulder showing branching Lichtenberg scar
markings, silver owl brooch with violet gems at collar. Her body
features: tall slender build, big breasts, fading violet electric
mystic symbols tracing along her right arm and shoulder scars, dim
violet lightning particles crackle around her fingertips. She has cool
olive skin, silver-white streaks in hair that faintly glow.
(subtle knowing smile:0.3), analytical piercing eyes, looking at viewer,
cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(subtle knowing smile:0.3), analytical piercing eyes, looking at viewer, cowboy shot,` |
| `happy` | `(warm smile:0.5), bright interested eyes, looking at viewer, cowboy shot,` |
| `sad` | `(slight frown:0.3), sorrowful downcast eyes, looking away, cowboy shot,` |
| `angry` | `(cold fury expression:0.6), intense glowing violet eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(raised eyebrows:0.5), wide startled eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(coy smirk:0.4), direct half-lidded violet-bright eyes, looking at viewer, cowboy shot,` |

---

### Nyx (6 images)

**Base prompt:**
```
Smooth skinned ethereal primordial goddess of night with long flowing
midnight-black to deep-violet hair floating weightlessly, galaxy eyes
with swirling violet cosmos and pinpoints of light instead of pupils,
wearing flowing black star-field robe with tiny moving points of light
on fabric, hem dissolving into dark mist, bare translucent shoulders,
crown of black crystallized thorns in her floating hair. Her body
features: ethereal otherworldly build, translucent pale luminescent skin
with visible blue veins on neck and collarbones, fading deep violet
cosmic mystic symbols along her arms, dim star-like particles orbit
slowly around her. She has a permanent dark cosmic tear track under
her left eye, single black ring on left index finger.
(distant enigmatic expression:0.3), ancient unknowable galaxy eyes,
looking at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(distant enigmatic expression:0.3), ancient unknowable galaxy eyes, looking at viewer, cowboy shot,` |
| `happy` | `(rare soft smile:0.5), warm brightened galaxy eyes, looking at viewer, cowboy shot,` |
| `sad` | `(melancholic expression:0.4), dimming sorrowful galaxy eyes, cosmic tear forming, cowboy shot,` |
| `angry` | `(cold wrath expression:0.6), blazing violet-white galaxy eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(parted lips:0.4), widened galaxy eyes flaring bright, looking at viewer, cowboy shot,` |
| `seductive` | `(veiled alluring gaze:0.4), intimate glowing galaxy eyes, looking at viewer, cowboy shot,` |

---

### Priestess (5 images — no seductive)

**Base prompt:**
```
Smooth skinned ethereal priestess of Gaia with long emerald-green hair
flowing like living vines, glowing bioluminescent green eyes, wearing
a robe woven from living leaves and silver thread that still seems to
grow, vine crown with small white flowers blooming, bark-textured
hands. Her body features: semi-translucent skin with green veins
visible beneath, slender ethereal build, fading emerald mystic nature
symbols along her arms and neck, dim green bioluminescent particles
float gently around her. She has roots extending from her bare feet,
a serene ageless face.
(serene peaceful expression:0.3), softly glowing wise eyes, looking at
viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(serene peaceful expression:0.3), softly glowing wise eyes, looking at viewer, cowboy shot,` |
| `happy` | `(benevolent warm smile:0.5), bright glowing kind eyes, looking at viewer, cowboy shot,` |
| `sad` | `(sorrowful expression:0.4), dimmed sad eyes, head slightly bowed, cowboy shot,` |
| `angry` | `(stern commanding expression:0.5), blazing green fierce eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(wide open expression:0.4), bright startled glowing eyes, looking at viewer, cowboy shot,` |

---

### Daphne (6 images)

**Base prompt:**
```
Smooth skinned shy young forest nymph herbalist with soft green
shoulder-length wavy hair with small leaves and a white flower tangled
in it, warm moss-gold eyes, wearing simple cream linen dress with
hand-embroidered wildflower patterns at the hem, sage-green herb-stained
apron with oversized pockets, bare feet with grass stains. Her body
features: petite gentle build, small breasts, dirt under her nails and
herb-stained green fingertips, fading soft green mystic leaf symbols
along her forearms, dim golden pollen particles drift lazily around her.
She has a spray of freckles across her nose and cheeks, pink-flushed
fair skin.
(shy half-smile:0.3), gentle downcast warm eyes, looking at viewer,
cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(shy half-smile:0.3), gentle downcast warm eyes, looking at viewer, cowboy shot,` |
| `happy` | `(beaming smile:0.7), bright sparkling excited eyes, looking at viewer, cowboy shot,` |
| `sad` | `(small frown:0.3), watery sad eyes looking down, cowboy shot,` |
| `angry` | `(tearful fierce expression:0.4), defiant glaring eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(open mouth gasp:0.5), wide startled eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(gentle inviting smile:0.4), warm direct eyes, looking at viewer, cowboy shot,` |

---

### Circe (6 images)

**Base prompt:**
```
Smooth skinned powerful greek sorceress enchantress with long dark
sleek hair with a faint violet sheen, glowing amber-gold cat-like eyes,
wearing fitted deep purple robes with glowing golden arcane symbols
embroidered throughout, bare right shoulder with golden chain and small
rune tattoo, heavy gold chain belt with three small potion vials,
golden circlet with glowing violet central gem. Her body features:
stunning curvaceous build, big breasts, violet-stained lips from years
of potion tasting, fading golden-violet mystic arcane symbols tracing
along both arms, dim violet lightning sparks crackle between her
fingertips. She has warm olive luminous flawless skin, a small rune
tattoo behind right shoulder.
(knowing smirk:0.4), mesmerizing cat-like predatory eyes, looking at
viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(knowing smirk:0.4), mesmerizing cat-like predatory eyes, looking at viewer, cowboy shot,` |
| `happy` | `(genuine delighted laugh:0.6), bright crinkling playful eyes, looking at viewer, cowboy shot,` |
| `sad` | `(closed lips:0.3), reflective distant sad eyes, looking away, cowboy shot,` |
| `angry` | `(cold fury expression:0.7), blazing white-gold terrifying eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(parted lips startled:0.5), wide caught-off-guard eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(inviting lips:0.5), heavy-lidded smoky alluring eyes, looking at viewer, cowboy shot,` |

---

### Thetis (6 images)

**Base prompt:**
```
Smooth skinned ancient sea nymph goddess with long silver-blue hair
flowing as if perpetually underwater with three thin pearl chains woven
through, deep ocean-blue eyes with bioluminescent teal ring around
pupil, wearing a flowing dress that appears made of translucent ocean
water with rippling layers and sea foam edges, bare shoulders with
iridescent scale-shimmer patches, pearl choker at throat, single pearl
drop earring on left ear. Her body features: ageless ethereal build,
big breasts, pale blue-tinted iridescent skin that shimmers like fish
scales in light, fading deep blue-teal mystic ocean symbols along her
collarbones and arms, dim floating water droplets rise slowly upward
around her. She has slightly webbed bare feet, iridescent scale patches
on upper arms.
(melancholic distant expression:0.3), deep sorrowful ocean eyes, looking
at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(melancholic distant expression:0.3), deep sorrowful ocean eyes, looking at viewer, cowboy shot,` |
| `happy` | `(rare gentle smile:0.5), warm softened ocean eyes, looking at viewer, cowboy shot,` |
| `sad` | `(trembling lips:0.3), tear-filled glistening eyes, tears becoming pearls, cowboy shot,` |
| `angry` | `(commanding stern expression:0.6), blazing teal fierce eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(parted lips:0.4), wide startled ocean eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(alluring gaze:0.4), direct teal-bright intimate eyes, looking at viewer, cowboy shot,` |

---

### Echo (6 images)

**Base prompt:**
```
Smooth skinned haunting cursed greek nymph bard with very long
near-black straight hair falling like a wet curtain partially covering
the right side of her face, pale luminous silver-grey eyes that are
slightly too large for her face, wearing a simple white linen shift
dress that is torn at the hem and fraying at the edges, one shoulder
slipping revealing collarbone, bare dirty feet. Her body features:
slender fragile build, small breasts, marble-pale skin with a blue
undertone that is almost luminous, fading silver mystic sound-wave
symbols faintly tracing along her throat and collarbones, dim silver
mist particles cling around her feet and drift behind her. She has a
thin silver scar encircling her throat, mouth slightly open as if
about to speak.
(haunting silent expression:0.3), pleading luminous too-large eyes,
looking at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(haunting silent expression:0.3), pleading luminous too-large eyes, looking at viewer, cowboy shot,` |
| `happy` | `(rare genuine tearful smile:0.6), bright relieved shining eyes, looking at viewer, cowboy shot,` |
| `sad` | `(anguished expression:0.4), devastated glistening eyes, hair covering face, cowboy shot,` |
| `angry` | `(silent scream wide open mouth:0.6), fierce blazing silver eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(startled gasp:0.5), wide shocked eyes full face revealed, looking at viewer, cowboy shot,` |
| `seductive` | `(vulnerable inviting expression:0.4), direct warm silver eyes, looking at viewer, cowboy shot,` |

---

### Lyra (6 images)

**Base prompt:**
```
Smooth skinned warm greek tavern keeper barmaid with auburn-copper hair
in a messy bun held with a wooden pin with strands escaping to frame
her face, warm honey-brown eyes crinkled at the corners, wearing a
russet-brown linen blouse with rolled-up sleeves showing strong
forearms, cream well-worn stained apron tied at waist, sturdy scuffed
leather shoes. Her body features: strong curvy build, big breasts,
calloused warm hands, a small bronze key on a leather cord around her
neck, fading warm orange-amber mystic hearth-flame symbols along her
forearms, dim warm amber hearth-glow particles softly emanate around
her hands. She has ruddy permanently flushed cheeks and nose, faint
freckles on nose bridge, warm tan skin.
(open friendly grin:0.5), warm welcoming crinkled eyes, looking at
viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(open friendly grin:0.5), warm welcoming crinkled eyes, looking at viewer, cowboy shot,` |
| `happy` | `(full belly laugh:0.8), eyes squeezed shut with joy, cowboy shot,` |
| `sad` | `(tight-lipped expression:0.3), tired lonely distant eyes, looking down, cowboy shot,` |
| `angry` | `(furious glare:0.6), flashing fierce eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(open mouth shock:0.5), wide startled eyes, cowboy shot,` |
| `seductive` | `(warm knowing smile:0.5), inviting half-lidded eyes, looking at viewer, cowboy shot,` |

---

### Melina (6 images)

**Base prompt:**
```
Smooth skinned young greek village scholar girl with warm chestnut-brown
hair in twin braids reaching mid-chest with flyaway hairs, large warm
brown doe eyes, wearing a modest olive-green ankle-length linen dress
with rolled-up sleeves revealing ink-stained forearms, cream undershirt
visible at the collar, worn-thin leather sandals. Her body features:
petite youthful build, small breasts, ink-stained fingertips, a worn
brown leather journal clutched to her chest, quill tucked behind her
right ear, fading soft earth-gold mystic script symbols along her
forearms mixed with ink stains, dim golden-green mote particles drift
faintly near her journal. She has an ink smudge on her right cheek,
warm olive youthful skin, a braided grass ring on her left pinky.
(curious defiant expression:0.4), bright intelligent doe eyes, looking
at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(curious defiant expression:0.4), bright intelligent doe eyes, looking at viewer, cowboy shot,` |
| `happy` | `(excited beaming smile:0.7), sparkling bright eyes, looking at viewer, cowboy shot,` |
| `sad` | `(tight worried expression:0.3), watery sad doe eyes, looking down, cowboy shot,` |
| `angry` | `(defiant clenched jaw:0.5), fierce stubborn eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(gasping expression:0.5), wide shocked doe eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(shy inviting smile:0.4), warm direct eyes with ink on lips, looking at viewer, cowboy shot,` |

---

### Naida (6 images)

**Base prompt:**
```
Smooth skinned shy river water nymph with blue-green hair that flows
like liquid water even when dry with light reflections rippling through
it, iridescent shifting aqua-silver eyes, wearing a simple wrap that
appears made of flowing translucent river water that ripples and shifts,
single freshwater pearl on a thin silver chain necklace, bare feet with
slight webbing between toes. Her body features: slender ethereal build,
medium breasts, translucent blue-green tinted skin with scattered
iridescent scale patches on shoulders and ribs, slender elongated
slightly translucent fingertips, fading aqua-teal mystic water-current
symbols flowing along her arms and ribs, dim floating water droplet
particles orbit slowly around her hair. She has slightly pointed ears
barely visible through her water-hair, puddles form at her bare feet.
(shy tentative expression:0.3), iridescent shifting nervous eyes,
looking at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(shy tentative expression:0.3), iridescent shifting nervous eyes, looking at viewer, cowboy shot,` |
| `happy` | `(surprised gentle smile:0.5), bright prismatic sparkling eyes, looking at viewer, cowboy shot,` |
| `sad` | `(forlorn expression:0.4), dull still iridescent eyes, looking down, cowboy shot,` |
| `angry` | `(fierce commanding expression:0.6), blazing full-iridescent eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(startled gasp:0.4), wide flashing iridescent eyes, looking at viewer, cowboy shot,` |
| `seductive` | `(vulnerable open expression:0.4), warm direct glowing iridescent eyes, looking at viewer, cowboy shot,` |

---

### Old Kostas (5 images — no seductive)

**Base prompt:**
```
Weathered old greek fisherman with bushy grey beard, deeply tanned
sun-wrinkled face, kind crinkled eyes, wearing a patched wide-brimmed
straw hat with a fishing hook stuck in the brim, sleeveless rough linen
shirt with sweat stains, worn leather vest with brass buckle, wooden
fishing rod over right shoulder with dangling line. His features:
stocky weathered build, thick calloused hands with fishing scars, a
small brass hip flask at his belt, missing front tooth. He has deeply
lined face, sun spots on his arms.
(easy grin:0.4), kind squinting eyes, looking at viewer, cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(easy grin:0.4), kind squinting eyes, looking at viewer, cowboy shot,` |
| `happy` | `(belly laugh:0.8), eyes squeezed shut head thrown back, cowboy shot,` |
| `sad` | `(closed mouth:0.3), distant tired eyes looking at water, cowboy shot,` |
| `angry` | `(grumpy scowl:0.5), fierce squinting eyes, looking up at sky, cowboy shot,` |
| `surprised` | `(wide open mouth:0.6), shocked wide eyes, cowboy shot,` |

---

### Thalos (5 images — no seductive)

**Base prompt:**
```
Wise old greek village elder with long white beard braided at the tip,
kind but exhausted eyes with deep crow's feet, wearing cream linen robe
with a simple dark leather belt, dull tarnished gold circlet on his
brow, bronze leaf-shaped clasp at the collar, leaning on a gnarled
carved walking staff of dark wood. His features: tall but stooped
posture, thin weathered hands with prominent veins, age spots on his
temples. He has a deeply lined dignified face, the weight of years
visible in his posture.
(thoughtful expression:0.3), tired wise knowing eyes, looking at viewer,
cowboy shot,
white background,
masterpiece, best quality, highest quality, intricate details
```

| Mood | Replace expression line with |
|------|------------------------------|
| `neutral` | `(thoughtful expression:0.3), tired wise knowing eyes, looking at viewer, cowboy shot,` |
| `happy` | `(warm grandfatherly smile:0.6), crinkling kind eyes, looking at viewer, cowboy shot,` |
| `sad` | `(bowed head:0.4), heavy sorrowful eyes, looking down, cowboy shot,` |
| `angry` | `(stern commanding expression:0.6), sharp authoritative eyes, looking at viewer, cowboy shot,` |
| `surprised` | `(startled expression:0.4), wide alarmed eyes, cowboy shot,` |

---

## 2. Enemy Portraits (512x512, PNG)

Path: `assets/images/enemies/{enemy_id}.png`

**Total: 6 images**

### forest_monster
```
Twisted corrupted wolf creature, matted dark fur dripping with black
ooze, glowing red eyes with slit pupils, exposed fangs, corrupted
earth-brown energy crackling along its spine, crouched attack pose,
white background,
masterpiece, best quality, highest quality, intricate details
```

### mountain_beast
```
Massive stone-and-muscle bear creature, cracked granite hide with
glowing orange magma fissures, standing on hind legs roaring, huge
claws, glowing orange eyes,
white background,
masterpiece, best quality, highest quality, intricate details
```

### amazon_challenger
```
Fierce Amazon warrior sparring opponent, short-cropped red hair,
confident smirk, practical bronze chest armor and leather wraps,
iron short sword in guard stance, athletic muscular build, battle scars,
white background,
masterpiece, best quality, highest quality, intricate details
```

### gaia_spirit
```
Massive corrupted earth elemental boss, body of cracked stone and dying
twisted roots, emerald fissures leaking dark corrupted purple energy,
ancient screaming face half-formed in the rock surface, towering scale,
white background,
masterpiece, best quality, highest quality, intricate details
```

### sardis_bandit
```
Lean scrappy human bandit, rough cloth mask over lower face, patched
leather jerkin, rusty short blade, crouching ambush pose, desperate
wild eyes,
white background,
masterpiece, best quality, highest quality, intricate details
```

### corrupted_nymph
```
Once-beautiful water nymph twisted by corruption, skin cracked like
dried riverbed, hair frozen into black crystal shards, glowing
corrupted violet eyes, tattered remains of a water-dress,
white background,
masterpiece, best quality, highest quality, intricate details
```

---

## 3. CG Intimacy Scenes (1024x1024 or 1280x720, PNG)

Path: `assets/images/cg/{id}_intimate_{n}.png`

**Total: 26 images**

> CGs use environmental backgrounds (not white). Add the quality suffix to each.

**Suffix for all CGs:**
```
painterly, intimate romantic scene, tasteful, cinematic composition,
masterpiece, best quality, highest quality, intricate details
```

### Artemis (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Artemis (platinum-blonde twin braids, yellow eyes, worn leather archer outfit) and protagonist sitting by a forest campfire at night, her head on his shoulder, bow set aside, moonlight and firelight on faces, warm intimate mood` |
| 2 | `Artemis (platinum-blonde hair unbraided loose for first time, yellow eyes, bare shoulders) at a moonlit forest pool, looking back with rare unguarded soft smile, silver moonlight on water` |
| 3 | `Artemis and protagonist embracing on a cliff at dawn, silver moonlight fading into gold sunrise, wind in platinum-blonde hair, tender moment` |

### Hippolyta (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Hippolyta (wild crimson hair, amber eyes, bronze breastplate) at rowdy feast, arm thrown around protagonist, full laugh, wine cups, warm torchlight` |
| 2 | `Hippolyta and protagonist after training spar turned kiss, both sweaty, spears dropped on sand, her hand behind his neck, dusk amber light` |
| 3 | `Hippolyta with armor removed, sitting at foot of bed, foreheads touching, scars exposed, vulnerable, warm candlelight` |

### Atenea (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Atenea (black hair with silver streaks, storm-grey eyes, indigo chiton) and protagonist in night library, hands touching over a book, candlelight, soft violet glow` |
| 2 | `Atenea on rooftop during lightning storm, pointing at constellations, rain on both faces, dramatic storm light` |
| 3 | `Atenea writing with quill, blushing, Lichtenberg scars visible on bare shoulder, looking up at viewer, warm candlelight` |

### Nyx (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Nyx (floating black-violet hair, galaxy eyes, star-field robe) and protagonist floating in cosmic void, stars around them, her reaching toward him, her form more solid than usual` |
| 2 | `Nyx in midnight garden of black roses, offering a single flower, star motes concentrated between their hands, moonlight` |
| 3 | `Nyx and protagonist silhouetted against blood moon in dream realm, her hair wrapping protectively around both` |

### Quest Companions (2 CGs each)

| Companion | CG 1 | CG 2 |
|-----------|-------|-------|
| Daphne | `Daphne (green hair with leaves, freckles, cream dress) planting a garden with protagonist at dawn, hands in earth, soft smiles` | `Daphne weaving flower crown for protagonist in moonlit meadow, pollen particles glowing` |
| Circe | `Circe (dark hair violet sheen, amber eyes, purple robes) guiding protagonist's hands over bubbling cauldron, faces close, candlelight` | `Circe and protagonist on tower rooftop at night, watching city, her head on his shoulder, stars` |
| Thetis | `Thetis (silver-blue underwater hair, pearl chains, water-dress) walking shoreline at twilight, waves parting for her, holding hands` | `Thetis showing protagonist bioluminescent coral in underwater grotto, sharing air, teal glow` |
| Echo | `Echo (near-black hair, white shift, throat scar) singing for first time, tears on face, protagonist listening in awe, silver light` | `Echo with head on protagonist's lap in ruins at sunrise, silver lyre beside her, peaceful` |
| Lyra | `Lyra (auburn messy bun, cream apron, russet blouse) dancing with protagonist in empty tavern at closing time, firelight, intimate` | `Lyra and protagonist on tavern rooftop at dawn, sharing breakfast, her hair down for once, warm light` |
| Melina | `Melina (chestnut twin braids, olive dress, journal) sneaking into forbidden library with protagonist, single candle, stifling giggles` | `Melina reading journal aloud to protagonist under great sacred tree at sunset, golden light` |
| Naida | `Naida (blue-green water-hair, pearl necklace, water-wrap) emerging fully from river for first time, reaching for protagonist's hand, twilight` | `Naida and protagonist floating together in twilight river, her not hiding for once, peaceful, warm light` |

---

## 4. Backgrounds (430x932 portrait, PNG/JPG)

Path: `assets/images/backgrounds/{area_id}.png`

**Total: 11 images**

> Backgrounds use environmental detail (not white background).

| Area | Prompt |
|------|--------|
| `magical_forest` | `Dark ancient forest at night, massive trees with glowing root systems, moonlight god-rays through dense canopy, luminescent mushrooms, low mist, portrait orientation, masterpiece, best quality, intricate details` |
| `sardis_village` | `Ancient greek village in forest clearing, stone cottages thatched roofs, massive sacred tree reaching into amber clouds, warm torchlight, dusk golden hour, portrait orientation, masterpiece, best quality, intricate details` |
| `golden_fleece_tavern` | `Dim bronze age tavern interior, heavy wooden beams, hanging oil lamps, amphorae on shelves, stone hearth roaring fire, warm pools of light, portrait orientation, masterpiece, best quality, intricate details` |
| `mount_tmolus` | `Greek mountain pass at dawn, gnarled pines on wind-swept cliffs, waterfall catching first light, misty valley below, stone markers, portrait orientation, masterpiece, best quality, intricate details` |
| `amazon_camp` | `Circular training arena packed sand floor, stone columns with hung bronze shields, weapon racks, torches at dusk, war banners, portrait orientation, masterpiece, best quality, intricate details` |
| `gaia_tree_temple` | `Hidden temple beneath massive sacred tree, living roots as walls, emerald bioluminescent runes in stone, moss carpet, ethereal green light, portrait orientation, masterpiece, best quality, intricate details` |
| `coastal_grotto` | `Sea cave grotto opening to twilight ocean, bioluminescent coral on walls, pearl formations, tide pools reflecting starlight, ocean mist, portrait orientation, masterpiece, best quality, intricate details` |
| `sardis_ruins` | `Crumbling marble temple ruins in moonlight, broken columns, overgrown ivy and white flowers, silver mist on stone floor, desaturated near-monochrome, portrait orientation, masterpiece, best quality, intricate details` |
| `sardis_river` | `Gentle river at twilight, reeds and water grasses, stepping stones, weeping willows, fireflies, amber-to-blue gradient sky, portrait orientation, masterpiece, best quality, intricate details` |
| `splash_title` | `Wide cinematic fallen Olympus at dusk, shattered marble columns and broken god-statues, golden clouds with dark storm, beam of golden light breaking through, room for title text top third, portrait orientation, masterpiece, best quality, intricate details` |
| `camp_hub` | `Cozy camp beneath sacred tree at evening, stone hearth warm fire, wooden benches with blankets, stars through canopy, warm amber light, peaceful, portrait orientation, masterpiece, best quality, intricate details` |

---

## 5. UI Icons (128x128, PNG transparent)

Path: `assets/images/icons/{icon_id}.png`

**Total: 13 images**

| Icon | Prompt |
|------|--------------------|
| `gold_coin` | `Ancient drachma coin, gold with worn embossed owl, subtle glow, game icon, transparent background, masterpiece, best quality` |
| `element_fire` | `Stylized flame icon, red-orange core, ember particles, game icon, transparent background, masterpiece, best quality` |
| `element_water` | `Stylized water drop icon, deep blue with inner glow, game icon, transparent background, masterpiece, best quality` |
| `element_earth` | `Stylized leaf-and-root knot icon, emerald green, game icon, transparent background, masterpiece, best quality` |
| `element_lightning` | `Stylized jagged bolt icon, yellow-gold with violet outline, game icon, transparent background, masterpiece, best quality` |
| `element_neutral` | `Silver circle with subtle mist wisps icon, game icon, transparent background, masterpiece, best quality` |
| `bond_shard` | `Crystalline shard with purple-gold facets, divine glow, game icon, transparent background, masterpiece, best quality` |
| `blessing_star` | `Divine gold five-pointed star with soft rays, game icon, transparent background, masterpiece, best quality` |
| `heart_intimacy` | `Painted heart warm red slightly worn texture, game icon, transparent background, masterpiece, best quality` |
| `rank_b` | `Bronze circle medal with embossed B, game icon, transparent background, masterpiece, best quality` |
| `rank_a` | `Silver circle medal with embossed A, game icon, transparent background, masterpiece, best quality` |
| `rank_s` | `Gold circle medal with embossed S subtle shimmer, game icon, transparent background, masterpiece, best quality` |
| `rank_ss` | `Gold circle medal with embossed SS strong divine glow, game icon, transparent background, masterpiece, best quality` |

---

## 6. Combat Cards (256x384, PNG)

Path: `assets/images/cards/{suit}_{value}.png`

**Total: 53 images** (52 faces + 1 back)

### Card back
```
Ancient greek playing card back, central gold medallion with sacred tree,
bronze frame greek key border, dark brown leather texture, mystical,
masterpiece, best quality, intricate details
```

### Card face template
```
Ancient greek playing card, [SUIT MOTIF] central illustration, bronze
frame, [VALUE] greek-styled numerals at corners, aged parchment,
masterpiece, best quality, intricate details
```

Suits: Hearts=fire, Diamonds=lightning, Clubs=earth, Spades=water
Values: A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K

---

## 7. VFX Sprites (512x512, PNG transparent)

Path: `assets/vfx/{effect_id}.png`

**Total: 8 images**

| Effect | Prompt |
|--------|--------|
| `fire_burst` | `Explosion of embers and flame, orange-red, radial burst, transparent background, best quality` |
| `water_splash` | `Stylized wave crest with spray and foam, deep blue, transparent background, best quality` |
| `earth_crack` | `Rock shatter with debris and dust, brown-green, transparent background, best quality` |
| `lightning_arc` | `Jagged electric bolt, white-violet, branching, transparent background, best quality` |
| `gold_sparkle` | `Divine gold particle cluster, warm shimmer, transparent background, best quality` |
| `heal_motes` | `Rising green-gold leaf particles, gentle upward drift, transparent background, best quality` |
| `shield_dome` | `Translucent golden hemisphere, greek key edge pattern, transparent background, best quality` |
| `level_up_ring` | `Expanding ring warm white light with gold particles, transparent background, best quality` |

---

## 8. LoRA Training Sheets (768x1024, PNG, white background)

Path: `assets/lora_training/{id}/{id}_{angle}.png`

> Generate 5 angles per character for LoRA consistency training.
> Use the same base prompt as section 1 but swap the expression + shot line.
> All on white background. Aim for 10-20 images per character (5 angles x 2-4 seed variations).

**Angles per character:**

| Angle tag | Replace shot line with |
|-----------|----------------------|
| `front_full` | `neutral expression, looking at viewer, full body shot, standing pose, white background,` |
| `front_upper` | `neutral expression, looking at viewer, upper body shot, white background,` |
| `face_closeup` | `neutral expression, looking at viewer, close-up face portrait, detailed eyes detailed face, white background,` |
| `three_quarter` | `neutral expression, looking slightly to the side, three-quarter view, upper body, white background,` |
| `from_behind` | `looking away from viewer, from behind, full body back view, showing outfit details from back, white background,` |
| `side_profile` | `neutral expression, side profile view, full body, white background,` |
| `sitting` | `neutral expression, sitting pose, looking at viewer, full body, white background,` |

---

### Artemis LoRA (7 angles)

Use the Artemis base prompt from section 1, replace the expression/shot line:

```
Smooth skinned fallen huntress goddess with twin braids platinum-blonde
hair, yellow eyes, wearing worn leather archer outfit, battered quiver
on back, scuffed arm guards, weathered leather boots. Her body features:
big breasts, fading green mystic symbols along her arms, dim green
magical particles drift around her. She has faint freckles.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Hippolyta LoRA (7 angles)

```
Smooth skinned fierce Amazon warrior queen with wild untamed long
crimson hair, amber eyes with orange ring around pupil, wearing
battered bronze breastplate over bare scarred midriff, crimson leather
battle skirt with bronze studs, heavy bronze arm band on left arm only,
weathered leather sandals with bronze shin guards. Her body features:
muscular athletic build, big breasts, battle scars across abdomen and
arms, spiraling burn scar up right arm, fading red-orange mystic fire
symbols across her shoulders, dim ember particles drift around her.
She has red war paint stripe across right cheekbone and nose, notched
left ear.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Atenea LoRA (7 angles)

```
Smooth skinned regal goddess of wisdom with long black hair with two
silver-white lightning-bolt streaks framing her face, storm-grey eyes
with violet electric ring around pupil, wearing elegant deep indigo
chiton with geometric silver embroidery, asymmetric silver shoulder cape
on left side, bare right shoulder showing branching Lichtenberg scar
markings, silver owl brooch with violet gems at collar. Her body
features: tall slender build, big breasts, fading violet electric
mystic symbols tracing along her right arm and shoulder scars, dim
violet lightning particles crackle around her fingertips. She has cool
olive skin, silver-white streaks in hair that faintly glow.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Nyx LoRA (7 angles)

```
Smooth skinned ethereal primordial goddess of night with long flowing
midnight-black to deep-violet hair floating weightlessly, galaxy eyes
with swirling violet cosmos and pinpoints of light instead of pupils,
wearing flowing black star-field robe with tiny moving points of light
on fabric, hem dissolving into dark mist, bare translucent shoulders,
crown of black crystallized thorns in her floating hair. Her body
features: ethereal otherworldly build, translucent pale luminescent skin
with visible blue veins on neck and collarbones, fading deep violet
cosmic mystic symbols along her arms, dim star-like particles orbit
slowly around her. She has a permanent dark cosmic tear track under
her left eye, single black ring on left index finger.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Priestess LoRA (7 angles)

```
Smooth skinned ethereal priestess of Gaia with long emerald-green hair
flowing like living vines, glowing bioluminescent green eyes, wearing
a robe woven from living leaves and silver thread that still seems to
grow, vine crown with small white flowers blooming, bark-textured
hands. Her body features: semi-translucent skin with green veins
visible beneath, slender ethereal build, fading emerald mystic nature
symbols along her arms and neck, dim green bioluminescent particles
float gently around her. She has roots extending from her bare feet,
a serene ageless face.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Daphne LoRA (7 angles)

```
Smooth skinned shy young forest nymph herbalist with soft green
shoulder-length wavy hair with small leaves and a white flower tangled
in it, warm moss-gold eyes, wearing simple cream linen dress with
hand-embroidered wildflower patterns at the hem, sage-green herb-stained
apron with oversized pockets, bare feet with grass stains. Her body
features: petite gentle build, small breasts, dirt under her nails and
herb-stained green fingertips, fading soft green mystic leaf symbols
along her forearms, dim golden pollen particles drift lazily around her.
She has a spray of freckles across her nose and cheeks, pink-flushed
fair skin.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Circe LoRA (7 angles)

```
Smooth skinned powerful greek sorceress enchantress with long dark
sleek hair with a faint violet sheen, glowing amber-gold cat-like eyes,
wearing fitted deep purple robes with glowing golden arcane symbols
embroidered throughout, bare right shoulder with golden chain and small
rune tattoo, heavy gold chain belt with three small potion vials,
golden circlet with glowing violet central gem. Her body features:
stunning curvaceous build, big breasts, violet-stained lips from years
of potion tasting, fading golden-violet mystic arcane symbols tracing
along both arms, dim violet lightning sparks crackle between her
fingertips. She has warm olive luminous flawless skin, a small rune
tattoo behind right shoulder.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Thetis LoRA (7 angles)

```
Smooth skinned ancient sea nymph goddess with long silver-blue hair
flowing as if perpetually underwater with three thin pearl chains woven
through, deep ocean-blue eyes with bioluminescent teal ring around
pupil, wearing a flowing dress that appears made of translucent ocean
water with rippling layers and sea foam edges, bare shoulders with
iridescent scale-shimmer patches, pearl choker at throat, single pearl
drop earring on left ear. Her body features: ageless ethereal build,
big breasts, pale blue-tinted iridescent skin that shimmers like fish
scales in light, fading deep blue-teal mystic ocean symbols along her
collarbones and arms, dim floating water droplets rise slowly upward
around her. She has slightly webbed bare feet, iridescent scale patches
on upper arms.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Echo LoRA (7 angles)

```
Smooth skinned haunting cursed greek nymph bard with very long
near-black straight hair falling like a wet curtain partially covering
the right side of her face, pale luminous silver-grey eyes that are
slightly too large for her face, wearing a simple white linen shift
dress that is torn at the hem and fraying at the edges, one shoulder
slipping revealing collarbone, bare dirty feet. Her body features:
slender fragile build, small breasts, marble-pale skin with a blue
undertone that is almost luminous, fading silver mystic sound-wave
symbols faintly tracing along her throat and collarbones, dim silver
mist particles cling around her feet and drift behind her. She has a
thin silver scar encircling her throat, mouth slightly open as if
about to speak.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Lyra LoRA (7 angles)

```
Smooth skinned warm greek tavern keeper barmaid with auburn-copper hair
in a messy bun held with a wooden pin with strands escaping to frame
her face, warm honey-brown eyes crinkled at the corners, wearing a
russet-brown linen blouse with rolled-up sleeves showing strong
forearms, cream well-worn stained apron tied at waist, sturdy scuffed
leather shoes. Her body features: strong curvy build, big breasts,
calloused warm hands, a small bronze key on a leather cord around her
neck, fading warm orange-amber mystic hearth-flame symbols along her
forearms, dim warm amber hearth-glow particles softly emanate around
her hands. She has ruddy permanently flushed cheeks and nose, faint
freckles on nose bridge, warm tan skin.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Melina LoRA (7 angles)

```
Smooth skinned young greek village scholar girl with warm chestnut-brown
hair in twin braids reaching mid-chest with flyaway hairs, large warm
brown doe eyes, wearing a modest olive-green ankle-length linen dress
with rolled-up sleeves revealing ink-stained forearms, cream undershirt
visible at the collar, worn-thin leather sandals. Her body features:
petite youthful build, small breasts, ink-stained fingertips, a worn
brown leather journal clutched to her chest, quill tucked behind her
right ear, fading soft earth-gold mystic script symbols along her
forearms mixed with ink stains, dim golden-green mote particles drift
faintly near her journal. She has an ink smudge on her right cheek,
warm olive youthful skin, a braided grass ring on her left pinky.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Naida LoRA (7 angles)

```
Smooth skinned shy river water nymph with blue-green hair that flows
like liquid water even when dry with light reflections rippling through
it, iridescent shifting aqua-silver eyes, wearing a simple wrap that
appears made of flowing translucent river water that ripples and shifts,
single freshwater pearl on a thin silver chain necklace, bare feet with
slight webbing between toes. Her body features: slender ethereal build,
medium breasts, translucent blue-green tinted skin with scattered
iridescent scale patches on shoulders and ribs, slender elongated
slightly translucent fingertips, fading aqua-teal mystic water-current
symbols flowing along her arms and ribs, dim floating water droplet
particles orbit slowly around her hair. She has slightly pointed ears
barely visible through her water-hair, puddles form at her bare feet.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Old Kostas LoRA (7 angles)

```
Weathered old greek fisherman with bushy grey beard, deeply tanned
sun-wrinkled face, kind crinkled eyes, wearing a patched wide-brimmed
straw hat with a fishing hook stuck in the brim, sleeveless rough linen
shirt with sweat stains, worn leather vest with brass buckle, wooden
fishing rod over right shoulder with dangling line. His features:
stocky weathered build, thick calloused hands with fishing scars, a
small brass hip flask at his belt, missing front tooth. He has deeply
lined face, sun spots on his arms.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

### Thalos LoRA (7 angles)

```
Wise old greek village elder with long white beard braided at the tip,
kind but exhausted eyes with deep crow's feet, wearing cream linen robe
with a simple dark leather belt, dull tarnished gold circlet on his
brow, bronze leaf-shaped clasp at the collar, leaning on a gnarled
carved walking staff of dark wood. His features: tall but stooped
posture, thin weathered hands with prominent veins, age spots on his
temples. He has a deeply lined dignified face, the weight of years
visible in his posture.
[ANGLE LINE FROM TABLE ABOVE]
masterpiece, best quality, highest quality, intricate details
```

---

**LoRA Training Tips:**
- Generate 3-4 seed variations per angle = 21-28 images per character
- Pick the best 15-20 for training consistency
- Caption each with trigger word: `darkolympus_[id], [key features]`
- Train with Kohya_ss: SDXL 2000-4000 steps, lr 1e-4
- Use at weight 0.8-1.0 in all subsequent mood/CG prompts

---

## Summary

| Category | Count |
|----------|-------|
| Companion portraits (moods) | 75 |
| LoRA training angles (7/char x 14) | 98 |
| Enemy portraits | 6 |
| CG intimacy scenes | 26 |
| Backgrounds | 11 |
| UI icons | 13 |
| Combat cards | 53 |
| VFX sprites | 8 |
| **TOTAL** | **290** |
