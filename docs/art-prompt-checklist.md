# Dark Olympus — Art Prompt Checklist

> Copy-paste prompts for every image asset. Based on the approved Artemis reference style.
> For design philosophy, palettes, and LoRA training, see `art-generation-guide.md`.
>
> **Two base shots per character:**
> - **Cowboy shot** — waist-up, used for mood portraits (6 moods each)
> - **Full body shot** — head to toe, used for LoRA training angles
>
> **Global negative (include in ALL character prompts):**
> ```
> low quality, blurry, bad anatomy, extra limbs, text, watermark,
> deformed eyes, flat eyes, dull eyes, poorly drawn eyes,
> modern clothing, sci-fi
> ```

---

## 1. Companion Portraits — Cowboy Shot (768x1024, PNG)

Path: `assets/images/companions/{id}/{id}_{mood}.png`
Moods: `neutral`, `happy`, `sad`, `angry`, `surprised`, `seductive`

**Total: 75 images**

---

### Artemis — Cowboy Shot (6 images)

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

### Hippolyta — Cowboy Shot (6 images)

```
Smooth skinned fierce Amazon warrior queen with long flowing crimson
hair past her shoulders, amber eyes with orange ring around pupil,
wearing battered bronze breastplate over bare midriff, crimson leather
battle skirt with bronze studs, heavy bronze arm band on left arm only,
weathered leather sandals with bronze shin guards. Her body features:
muscular athletic build, big breasts, fading red-orange mystic fire
symbols across her shoulders and arms, dim ember particles drift around
her. She has red war paint stripe across right cheekbone and nose.
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

### Atenea — Cowboy Shot (6 images)

```
Smooth skinned regal goddess of wisdom with long black hair with two
silver-white lightning-bolt streaks framing her face, storm-grey eyes
with violet electric ring around pupil, wearing elegant deep indigo
chiton with geometric silver embroidery, asymmetric silver shoulder cape
on left side, bare right shoulder showing branching Lichtenberg scar
markings, silver owl brooch with violet gems at collar. Her body
features: tall slender build, big breasts, fading violet electric
mystic symbols tracing along her right arm and shoulder, dim violet
lightning particles crackle around her fingertips. She has cool olive
skin, silver-white streaks in hair that faintly glow.
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

### Nyx — Cowboy Shot (6 images)

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

### Priestess — Cowboy Shot (5 images — no seductive)

```
Smooth skinned ethereal priestess of Gaia with long emerald-green hair
flowing like living vines, glowing bioluminescent green eyes, wearing
a robe woven from living leaves and silver thread that still seems to
grow, vine crown with small white flowers blooming, bark-textured
hands. Her body features: semi-translucent skin with green veins
visible beneath, slender ethereal build, fading emerald mystic nature
symbols along her arms and neck, dim green bioluminescent particles
float gently around her. She has a serene ageless face.
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

### Daphne — Cowboy Shot (6 images)

```
Smooth skinned shy young forest nymph herbalist with soft green
shoulder-length wavy hair with small leaves and a white flower tangled
in it, warm moss-gold eyes, wearing simple cream linen dress with
hand-embroidered wildflower patterns at the hem, sage-green herb-stained
apron with oversized pockets. Her body features: petite gentle build,
small breasts, dirt under her nails and herb-stained green fingertips,
fading soft green mystic leaf symbols along her forearms, dim golden
pollen particles drift lazily around her. She has a spray of freckles
across her nose and cheeks, pink-flushed fair skin.
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

### Circe — Cowboy Shot (6 images)

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
fingertips. She has warm olive luminous flawless skin.
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

### Thetis — Cowboy Shot (6 images)

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
around her. She has iridescent scale patches on upper arms.
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

### Echo — Cowboy Shot (6 images)

```
Smooth skinned haunting cursed greek nymph bard with very long
near-black straight hair falling like a wet curtain partially covering
the right side of her face, pale luminous silver-grey eyes that are
slightly too large for her face, wearing a simple white linen shift
dress that is torn at the hem and fraying at the edges, one shoulder
slipping revealing collarbone. Her body features: slender fragile
build, small breasts, marble-pale skin with a blue undertone that is
almost luminous, fading silver mystic sound-wave symbols faintly tracing
along her throat and collarbones, dim silver mist particles cling
around her feet. She has a thin silver scar encircling her throat,
mouth slightly open as if about to speak.
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

### Lyra — Cowboy Shot (6 images)

```
Smooth skinned warm greek tavern keeper barmaid with auburn-copper hair
in a messy bun held with a wooden pin with strands escaping to frame
her face, warm honey-brown eyes crinkled at the corners, wearing a
russet-brown linen blouse with rolled-up sleeves showing strong
forearms, cream well-worn stained apron tied at waist. Her body
features: strong curvy build, big breasts, calloused warm hands, a
small bronze key on a leather cord around her neck, fading warm
orange-amber mystic hearth-flame symbols along her forearms, dim warm
amber hearth-glow particles softly emanate around her hands. She has
ruddy permanently flushed cheeks and nose, faint freckles on nose
bridge, warm tan skin.
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

### Melina — Cowboy Shot (6 images)

```
Smooth skinned young greek village scholar girl with warm chestnut-brown
hair in twin braids reaching mid-chest with flyaway hairs, large warm
brown doe eyes, wearing a modest olive-green ankle-length linen dress
with rolled-up sleeves revealing ink-stained forearms, cream undershirt
visible at the collar. Her body features: petite youthful build, small
breasts, ink-stained fingertips, a worn brown leather journal clutched
to her chest, quill tucked behind her right ear, fading soft earth-gold
mystic script symbols along her forearms mixed with ink stains, dim
golden-green mote particles drift faintly near her journal. She has an
ink smudge on her right cheek, warm olive youthful skin, a braided
grass ring on her left pinky.
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

### Naida — Cowboy Shot (6 images)

```
Smooth skinned shy river water nymph with blue-green hair that flows
like liquid water even when dry with light reflections rippling through
it, iridescent shifting aqua-silver eyes, wearing a simple wrap that
appears made of flowing translucent river water that ripples and shifts,
single freshwater pearl on a thin silver chain necklace. Her body
features: slender ethereal build, medium breasts, translucent blue-green
tinted skin with scattered iridescent scale patches on shoulders and
ribs, slender elongated slightly translucent fingertips, fading
aqua-teal mystic water-current symbols flowing along her arms and ribs,
dim floating water droplet particles orbit slowly around her hair. She
has slightly pointed ears barely visible through her water-hair.
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

### Old Kostas — Cowboy Shot (5 images — no seductive)

```
Weathered old greek fisherman with bushy grey beard, deeply tanned
sun-wrinkled face, kind crinkled eyes, wearing a patched wide-brimmed
straw hat with a fishing hook stuck in the brim, sleeveless rough linen
shirt with sweat stains, worn leather vest with brass buckle, wooden
fishing rod over right shoulder with dangling line. His features:
stocky weathered build, thick calloused hands with fishing scars, a
small brass hip flask at his belt, missing front tooth.
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

### Thalos — Cowboy Shot (5 images — no seductive)

```
Wise old greek village elder with long white beard braided at the tip,
kind but exhausted eyes with deep crow's feet, wearing cream linen robe
with a simple dark leather belt, dull tarnished gold circlet on his
brow, bronze leaf-shaped clasp at the collar, leaning on a gnarled
carved walking staff of dark wood. His features: tall but stooped
posture, thin weathered hands with prominent veins.
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

## 2. Companion Portraits — Full Body (768x1024, PNG)

Path: `assets/images/companions/{id}/{id}_full.png`

> Same character description as cowboy shot, but with full outfit + legs/feet visible.
> Used for LoRA training and character reference sheets.

**Total: 14 images** (1 per character)

---

### Artemis — Full Body

```
Smooth skinned fallen huntress goddess with twin braids platinum-blonde
hair, yellow eyes, wearing worn leather archer outfit, battered quiver
on back, scuffed arm guards, weathered leather boots with worn soles.
Her body features: big breasts, athletic toned legs, fading green mystic
symbols along her arms and thighs, dim green magical particles drift
around her. She has faint freckles, bare skin visible between leather
straps.
(smile:0.3), melancholic eyes, looking at viewer, full body shot,
standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Hippolyta — Full Body

```
Smooth skinned fierce Amazon warrior queen with long flowing crimson
hair past her shoulders, amber eyes with orange ring around pupil,
wearing battered bronze breastplate over bare midriff, crimson leather
battle skirt with bronze studs, heavy bronze arm band on left arm only,
weathered leather sandals with bronze shin guards, strong muscular legs.
Her body features: muscular athletic build, big breasts, fading
red-orange mystic fire symbols across her shoulders and legs, dim ember
particles drift around her. She has red war paint stripe across right
cheekbone and nose.
(fierce grin:0.4), burning determined eyes, looking at viewer, full body
shot, standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Atenea — Full Body

```
Smooth skinned regal goddess of wisdom with long black hair with two
silver-white lightning-bolt streaks framing her face, storm-grey eyes
with violet electric ring around pupil, wearing elegant deep indigo
chiton with geometric silver embroidery reaching to her ankles,
asymmetric silver shoulder cape on left side, bare right shoulder
showing branching Lichtenberg scar markings, silver owl brooch with
violet gems at collar, silver sandals. Her body features: tall slender
build, big breasts, fading violet electric mystic symbols tracing along
her right arm, dim violet lightning particles crackle around her
fingertips. She has cool olive skin.
(subtle knowing smile:0.3), analytical piercing eyes, looking at viewer,
full body shot, standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Nyx — Full Body

```
Smooth skinned ethereal primordial goddess of night with long flowing
midnight-black to deep-violet hair floating weightlessly, galaxy eyes
with swirling violet cosmos and pinpoints of light instead of pupils,
wearing flowing black star-field robe with tiny moving points of light
on fabric, hem dissolving into dark mist obscuring her feet, bare
translucent shoulders, crown of black crystallized thorns in her
floating hair. Her body features: ethereal otherworldly build,
translucent pale luminescent skin with visible blue veins on neck and
collarbones, fading deep violet cosmic mystic symbols along her arms,
dim star-like particles orbit slowly around her. She has a permanent
dark cosmic tear track under her left eye.
(distant enigmatic expression:0.3), ancient unknowable galaxy eyes,
looking at viewer, full body shot, standing floating pose,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Priestess — Full Body

```
Smooth skinned ethereal priestess of Gaia with long emerald-green hair
flowing like living vines, glowing bioluminescent green eyes, wearing
a robe woven from living leaves and silver thread that still seems to
grow reaching to the ground, vine crown with small white flowers
blooming, bark-textured hands, roots extending from her bare feet into
the ground. Her body features: semi-translucent skin with green veins
visible beneath, slender ethereal build, fading emerald mystic nature
symbols along her arms and neck, dim green bioluminescent particles
float gently around her.
(serene peaceful expression:0.3), softly glowing wise eyes, looking at
viewer, full body shot, standing pose, bare feet visible with roots,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Daphne — Full Body

```
Smooth skinned shy young forest nymph herbalist with soft green
shoulder-length wavy hair with small leaves and a white flower tangled
in it, warm moss-gold eyes, wearing simple cream linen dress with
hand-embroidered wildflower patterns at the hem reaching mid-calf,
sage-green herb-stained apron with oversized pockets, woven wicker
basket overflowing with herbs on left hip, bare feet with grass stains
and earth between toes. Her body features: petite gentle build, small
breasts, dirt under nails and herb-stained green fingertips, fading
soft green mystic leaf symbols along her forearms, dim golden pollen
particles drift lazily around her. She has a spray of freckles across
her nose and cheeks, pink-flushed fair skin.
(shy half-smile:0.3), gentle downcast warm eyes, looking at viewer,
full body shot, standing pose, bare feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Circe — Full Body

```
Smooth skinned powerful greek sorceress enchantress with long dark
sleek hair with a faint violet sheen, glowing amber-gold cat-like eyes,
wearing fitted deep purple robes with glowing golden arcane symbols
embroidered throughout reaching to the floor, bare right shoulder with
golden chain and small rune tattoo, heavy gold chain belt with three
small potion vials, golden circlet with glowing violet central gem,
gold-strapped sandals. Her body features: stunning curvaceous build,
big breasts, violet-stained lips, fading golden-violet mystic arcane
symbols tracing along both arms, dim violet lightning sparks crackle
between her fingertips. She has warm olive luminous flawless skin.
(knowing smirk:0.4), mesmerizing cat-like predatory eyes, looking at
viewer, full body shot, standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Thetis — Full Body

```
Smooth skinned ancient sea nymph goddess with long silver-blue hair
flowing as if perpetually underwater with three thin pearl chains woven
through, deep ocean-blue eyes with bioluminescent teal ring around
pupil, wearing a flowing dress that appears made of translucent ocean
water with rippling layers and sea foam edges reaching to the ground,
bare shoulders with iridescent scale-shimmer patches, pearl choker at
throat, single pearl drop earring on left ear, bare slightly webbed
feet in a thin layer of mist. Her body features: ageless ethereal
build, big breasts, pale blue-tinted iridescent skin, fading deep
blue-teal mystic ocean symbols along her collarbones and arms, dim
floating water droplets rise slowly upward around her.
(melancholic distant expression:0.3), deep sorrowful ocean eyes, looking
at viewer, full body shot, standing pose, bare webbed feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Echo — Full Body

```
Smooth skinned haunting cursed greek nymph bard with very long
near-black straight hair falling like a wet curtain partially covering
the right side of her face, pale luminous silver-grey eyes that are
slightly too large for her face, wearing a simple white linen shift
dress that is torn at the hem and fraying at the edges reaching to
mid-calf, one shoulder slipping revealing collarbone, bare dirty feet
that leave no footprints. Her body features: slender fragile build,
small breasts, marble-pale skin with a blue undertone, fading silver
mystic sound-wave symbols faintly tracing along her throat and
collarbones, dim silver mist particles cling around her feet. She has
a thin silver scar encircling her throat.
(haunting silent expression:0.3), pleading luminous too-large eyes,
looking at viewer, full body shot, standing pose, bare feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Lyra — Full Body

```
Smooth skinned warm greek tavern keeper barmaid with auburn-copper hair
in a messy bun held with a wooden pin with strands escaping to frame
her face, warm honey-brown eyes crinkled at the corners, wearing a
russet-brown linen blouse with rolled-up sleeves showing strong
forearms, cream well-worn stained apron tied at waist, simple dark
brown skirt to mid-calf, sturdy scuffed leather shoes. Her body
features: strong curvy build, big breasts, calloused warm hands, a
small bronze key on a leather cord around her neck, fading warm
orange-amber mystic hearth-flame symbols along her forearms, dim warm
amber hearth-glow particles softly emanate around her hands. She has
ruddy permanently flushed cheeks and nose, faint freckles on nose
bridge, warm tan skin.
(open friendly grin:0.5), warm welcoming crinkled eyes, looking at
viewer, full body shot, standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Melina — Full Body

```
Smooth skinned young greek village scholar girl with warm chestnut-brown
hair in twin braids reaching mid-chest with flyaway hairs, large warm
brown doe eyes, wearing a modest olive-green ankle-length linen dress
with rolled-up sleeves revealing ink-stained forearms, cream undershirt
visible at the collar, worn-thin leather sandals with soles nearly
worn through. Her body features: petite youthful build, small breasts,
ink-stained fingertips, a worn brown leather journal clutched to her
chest, quill tucked behind her right ear, fading soft earth-gold mystic
script symbols along her forearms, dim golden-green mote particles
drift faintly near her journal. She has an ink smudge on her right
cheek, warm olive youthful skin, a braided grass ring on her left pinky.
(curious defiant expression:0.4), bright intelligent doe eyes, looking
at viewer, full body shot, standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Naida — Full Body

```
Smooth skinned shy river water nymph with blue-green hair that flows
like liquid water even when dry with light reflections rippling through
it, iridescent shifting aqua-silver eyes, wearing a simple wrap that
appears made of flowing translucent river water that ripples and shifts,
single freshwater pearl on a thin silver chain necklace, bare feet with
slight webbing between toes and small puddles forming around them. Her
body features: slender ethereal build, medium breasts, translucent
blue-green tinted skin with scattered iridescent scale patches on
shoulders and ribs, slender elongated slightly translucent fingertips,
fading aqua-teal mystic water-current symbols flowing along her arms
and ribs, dim floating water droplet particles orbit slowly around her
hair. She has slightly pointed ears.
(shy tentative expression:0.3), iridescent shifting nervous eyes,
looking at viewer, full body shot, standing pose, bare webbed feet
visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Old Kostas — Full Body

```
Weathered old greek fisherman with bushy grey beard, deeply tanned
sun-wrinkled face, kind crinkled eyes, wearing a patched wide-brimmed
straw hat with a fishing hook stuck in the brim, sleeveless rough linen
shirt with sweat stains, worn leather vest with brass buckle, patched
linen trousers rolled up at the calves, worn leather sandals. His
features: stocky weathered build, thick calloused hands with fishing
scars, wooden fishing rod over right shoulder, a small brass hip flask
at his belt, missing front tooth, hairy tanned forearms.
(easy grin:0.4), kind squinting eyes, looking at viewer, full body shot,
standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

### Thalos — Full Body

```
Wise old greek village elder with long white beard braided at the tip,
kind but exhausted eyes with deep crow's feet, wearing cream linen robe
reaching to his ankles with a simple dark leather belt, dull tarnished
gold circlet on his brow, bronze leaf-shaped clasp at the collar,
leaning on a gnarled carved walking staff of dark wood, simple leather
sandals. His features: tall but stooped posture, thin weathered hands
with prominent veins, age spots on temples.
(thoughtful expression:0.3), tired wise knowing eyes, looking at viewer,
full body shot, standing pose, feet visible,
white background,
masterpiece, best quality, highest quality, intricate details
```

---

## 3. LoRA Training Angles (768x1024, PNG, white background)

Path: `assets/lora_training/{id}/{id}_{angle}.png`

> Use the **full body prompt** from section 2 as base.
> Replace the expression/shot line with the angle tag below.
> Generate 3-4 seed variations per angle, pick best 15-20 per character.

| Angle | Replace shot line with |
|-------|----------------------|
| `front_full` | `neutral expression, looking at viewer, full body shot, standing pose, feet visible, white background,` |
| `front_upper` | `neutral expression, looking at viewer, upper body shot, white background,` |
| `face_closeup` | `neutral expression, looking at viewer, close-up face portrait, detailed eyes detailed face, white background,` |
| `three_quarter` | `neutral expression, looking slightly to the side, three-quarter view, upper body, white background,` |
| `from_behind` | `looking away from viewer, from behind, full body back view, showing outfit details from back, white background,` |
| `side_profile` | `neutral expression, side profile view, full body, white background,` |
| `sitting` | `neutral expression, sitting pose, looking at viewer, full body, white background,` |

**LoRA Training Tips:**
- Generate 3-4 seeds per angle = 21-28 images per character
- Pick the best 15-20 for training
- Caption each: `darkolympus_[id], [key features from prompt]`
- Kohya_ss: SDXL 2000-4000 steps, lr 1e-4
- Use LoRA at weight 0.8-1.0 in mood/CG prompts

---

## 4. Enemy Portraits (512x512, PNG)

Path: `assets/images/enemies/{enemy_id}.png` | **Total: 6 images**

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
iron short sword in guard stance, athletic muscular build,
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

## 5. CG Intimacy Scenes (1024x1024 or 1280x720, PNG)

Path: `assets/images/cg/{id}_intimate_{n}.png` | **Total: 26 images**

> CGs use environmental backgrounds (not white). Append quality suffix to each.

**Suffix:**
```
painterly, intimate romantic scene, tasteful, cinematic composition,
masterpiece, best quality, highest quality, intricate details
```

### Artemis (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Artemis (platinum-blonde twin braids, yellow eyes, worn leather archer outfit) and protagonist sitting by a forest campfire at night, her head on his shoulder, bow set aside, moonlight and firelight on faces` |
| 2 | `Artemis (platinum-blonde hair unbraided loose, yellow eyes, bare shoulders) at a moonlit forest pool, looking back with rare unguarded soft smile` |
| 3 | `Artemis and protagonist embracing on a cliff at dawn, silver moonlight fading into gold sunrise, wind in platinum-blonde hair` |

### Hippolyta (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Hippolyta (wild crimson hair, amber eyes, bronze breastplate) at rowdy feast, arm thrown around protagonist, full laugh, wine cups, warm torchlight` |
| 2 | `Hippolyta and protagonist after training spar turned kiss, both sweaty, spears dropped on sand, her hand behind his neck, dusk amber` |
| 3 | `Hippolyta with armor removed, sitting at foot of bed, foreheads touching, scars exposed, candlelight` |

### Atenea (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Atenea (black hair silver streaks, storm-grey eyes, indigo chiton) and protagonist in night library, hands touching over a book, candlelight, violet glow` |
| 2 | `Atenea on rooftop during lightning storm, pointing at constellations, rain on both faces, storm light` |
| 3 | `Atenea writing with quill, blushing, Lichtenberg scars on bare shoulder, looking up at viewer, candlelight` |

### Nyx (3 CGs)

| # | Prompt |
|---|--------|
| 1 | `Nyx (floating black-violet hair, galaxy eyes, star-field robe) and protagonist floating in cosmic void, stars around them, reaching toward each other` |
| 2 | `Nyx in midnight garden of black roses, offering a single flower, star motes between their hands, moonlight` |
| 3 | `Nyx and protagonist silhouetted against blood moon, her hair wrapping protectively around both` |

### Quest Companions (2 CGs each)

| Companion | CG 1 | CG 2 |
|-----------|-------|-------|
| Daphne | `Daphne (green hair, freckles, cream dress) planting garden with protagonist at dawn, hands in earth, soft smiles` | `Daphne weaving flower crown for protagonist in moonlit meadow, pollen glowing` |
| Circe | `Circe (dark hair violet sheen, amber eyes, purple robes) guiding protagonist's hands over cauldron, faces close, candlelight` | `Circe and protagonist on tower rooftop at night, her head on his shoulder, stars` |
| Thetis | `Thetis (silver-blue hair, pearl chains, water-dress) walking shoreline at twilight, waves parting, holding hands` | `Thetis showing bioluminescent coral in underwater grotto, sharing air, teal glow` |
| Echo | `Echo (near-black hair, white shift, throat scar) singing for first time, tears on face, protagonist listening, silver light` | `Echo head on protagonist's lap in ruins at sunrise, silver lyre beside her` |
| Lyra | `Lyra (auburn messy bun, cream apron) dancing with protagonist in empty tavern at closing, firelight` | `Lyra and protagonist on tavern roof at dawn, breakfast, her hair down, warm light` |
| Melina | `Melina (chestnut braids, olive dress, journal) sneaking into forbidden library, candle, stifling giggles` | `Melina reading journal to protagonist under great tree at sunset` |
| Naida | `Naida (blue-green water-hair, pearl necklace) emerging fully from river, reaching for protagonist's hand, twilight` | `Naida and protagonist floating in twilight river, not hiding, peaceful` |

---

## 6. Backgrounds (430x932 portrait, PNG/JPG)

Path: `assets/images/backgrounds/{area_id}.png` | **Total: 11 images**

| Area | Prompt |
|------|--------|
| `magical_forest` | `Dark ancient forest at night, massive trees glowing roots, moonlight god-rays through canopy, luminescent mushrooms, low mist, portrait orientation, masterpiece, best quality, intricate details` |
| `sardis_village` | `Ancient greek village in forest clearing, stone cottages, massive sacred tree reaching into amber clouds, warm torchlight, dusk, portrait orientation, masterpiece, best quality, intricate details` |
| `golden_fleece_tavern` | `Dim bronze age tavern interior, wooden beams, hanging oil lamps, stone hearth roaring fire, warm light pools, portrait orientation, masterpiece, best quality, intricate details` |
| `mount_tmolus` | `Greek mountain pass at dawn, gnarled pines on cliffs, waterfall, misty valley below, stone markers, portrait orientation, masterpiece, best quality, intricate details` |
| `amazon_camp` | `Circular training arena sand floor, stone columns bronze shields, weapon racks, torches dusk, war banners, portrait orientation, masterpiece, best quality, intricate details` |
| `gaia_tree_temple` | `Hidden temple beneath massive tree, living roots as walls, emerald bioluminescent runes, moss carpet, green light, portrait orientation, masterpiece, best quality, intricate details` |
| `coastal_grotto` | `Sea cave grotto opening to twilight ocean, bioluminescent coral, pearl formations, tide pools starlight, ocean mist, portrait orientation, masterpiece, best quality, intricate details` |
| `sardis_ruins` | `Crumbling marble ruins in moonlight, broken columns, ivy and white flowers, silver mist, desaturated, portrait orientation, masterpiece, best quality, intricate details` |
| `sardis_river` | `Gentle river at twilight, reeds, stepping stones, weeping willows, fireflies, amber-to-blue sky, portrait orientation, masterpiece, best quality, intricate details` |
| `splash_title` | `Fallen Olympus at dusk, shattered columns broken god-statues, golden clouds dark storm, beam of light, room for title top third, portrait orientation, masterpiece, best quality, intricate details` |
| `camp_hub` | `Cozy camp beneath sacred tree evening, stone hearth fire, wooden benches blankets, stars through canopy, warm amber, portrait orientation, masterpiece, best quality, intricate details` |

---

## 7. UI Icons (128x128, PNG transparent)

Path: `assets/images/icons/{icon_id}.png` | **Total: 13 images**

| Icon | Prompt |
|------|----|
| `gold_coin` | `Ancient drachma coin gold embossed owl glow, game icon, transparent bg, best quality` |
| `element_fire` | `Stylized flame red-orange ember particles, game icon, transparent bg, best quality` |
| `element_water` | `Stylized water drop deep blue inner glow, game icon, transparent bg, best quality` |
| `element_earth` | `Stylized leaf-root knot emerald green, game icon, transparent bg, best quality` |
| `element_lightning` | `Stylized bolt yellow-gold violet outline, game icon, transparent bg, best quality` |
| `element_neutral` | `Silver circle mist wisps, game icon, transparent bg, best quality` |
| `bond_shard` | `Crystalline shard purple-gold facets divine glow, game icon, transparent bg, best quality` |
| `blessing_star` | `Divine gold five-pointed star soft rays, game icon, transparent bg, best quality` |
| `heart_intimacy` | `Painted heart warm red worn texture, game icon, transparent bg, best quality` |
| `rank_b` | `Bronze circle embossed B, game icon, transparent bg, best quality` |
| `rank_a` | `Silver circle embossed A, game icon, transparent bg, best quality` |
| `rank_s` | `Gold circle embossed S shimmer, game icon, transparent bg, best quality` |
| `rank_ss` | `Gold circle embossed SS divine glow, game icon, transparent bg, best quality` |

---

## 8. Combat Cards (256x384, PNG)

Path: `assets/images/cards/{suit}_{value}.png` | **Total: 53 images**

**Card back:**
```
Ancient greek card back, gold medallion sacred tree, bronze frame greek
key border, dark brown leather texture, masterpiece, best quality
```

**Card face template:**
```
Ancient greek card, [SUIT MOTIF] central, bronze frame, [VALUE] greek
numerals corners, aged parchment, masterpiece, best quality
```

Suits: Hearts=fire, Diamonds=lightning, Clubs=earth, Spades=water

---

## 9. VFX Sprites (512x512, PNG transparent)

Path: `assets/vfx/{effect_id}.png` | **Total: 8 images**

| Effect | Prompt |
|--------|--------|
| `fire_burst` | `Ember flame explosion, orange-red, radial, transparent bg, best quality` |
| `water_splash` | `Wave crest spray foam, deep blue, transparent bg, best quality` |
| `earth_crack` | `Rock shatter debris dust, brown-green, transparent bg, best quality` |
| `lightning_arc` | `Jagged electric bolt, white-violet branching, transparent bg, best quality` |
| `gold_sparkle` | `Divine gold particles warm shimmer, transparent bg, best quality` |
| `heal_motes` | `Rising green-gold leaf particles, transparent bg, best quality` |
| `shield_dome` | `Golden translucent hemisphere greek key edge, transparent bg, best quality` |
| `level_up_ring` | `Expanding light ring gold particles, transparent bg, best quality` |

---

## Summary

| Category | Count |
|----------|-------|
| Companion portraits — cowboy shot (moods) | 75 |
| Companion portraits — full body | 14 |
| LoRA training angles (7/char x 14) | 98 |
| Enemy portraits | 6 |
| CG intimacy scenes | 26 |
| Backgrounds | 11 |
| UI icons | 13 |
| Combat cards | 53 |
| VFX sprites | 8 |
| **TOTAL** | **304** |
