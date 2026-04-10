# UI Theme

> **Status**: Designed
> **Author**: game-designer + art-director
> **Last Updated**: 2026-04-08
> **Implements Pillar**: Pillar 1 (Sensation — gold/mythological UI theme)

## Summary

The UI Theme system defines the shared visual language for every screen in Dark Olympus -- a gold-on-dark-brown mythological aesthetic applied through a single Godot Theme resource. It specifies the color palette, typography, element colors, button/panel styles, and touch-target sizing that all 18+ screens inherit. The theme is the first thing players perceive and the last thing they should consciously notice -- when it works, the UI feels like ancient parchment and divine gold; when it fails, the illusion of a mythological world breaks.

> **Quick reference** -- Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

The UI Theme system is the centralized visual definition for all player-facing interface elements. It is both infrastructure -- a single `.tres` Theme resource that every Control node inherits from -- and a design pillar delivery mechanism, ensuring the game's mythological dark-fantasy-with-warmth tone is present in every button, label, panel, and dialog box the player touches.

The system defines five visual layers: (1) the core color palette (background browns, gold accents, cream text, element-specific colors), (2) typography rules (Cinzel for display/titles, Nunito Sans for body text, with size scales for mobile readability), (3) panel and container styles (bordered panels with gold trim evoking ancient parchment), (4) interactive element styles (buttons, toggles, sliders with clear touch states), and (5) element-color mapping (Fire red, Water blue, Earth green, Lightning gold) used across combat, companions, and deck UI.

All 18+ game screens inherit from this single theme. Screens may override specific style properties (e.g., combat screen uses darker panels for tension), but the base palette, fonts, and touch-target minimums are enforced globally. No screen creates its own color constants or font assignments -- the theme is the single source of truth.

## Player Fantasy

The gods have fallen, but their grandeur hasn't disappeared -- it's dimmed. Gold accents against deep brown panels feel like candlelight in a temple that hasn't been abandoned. The visual theme carries hope in its palette -- not bright optimism, but the enduring kind, like embers that refuse to go cold.

Gold is not decoration; it marks authority. It appears on active choices, earned blessings, and scored hands -- every place where the player is restoring divine power. When you open the Camp screen and see gold borders framing your companions against warm brown, or when a poker hand scores in gold numerals, the theme tells the same story the narrative does: this world is waiting to be restored, and you are the one doing it.

The cream-on-brown foundation is the mortal world, humble and warm. Gold is the divine breaking through. The player should never think "nice UI" -- they should feel that this world was once magnificent, and that warmth still lives inside the ruin.

## Detailed Design

### Core Rules

**1. Color Palette**

The palette has semantic meaning. Every color communicates something about the world.

| Token | Hex | Role |
|-------|-----|------|
| `BG_PRIMARY` | `#2A1F14` | The mortal world. Base of every screen. |
| `BG_SECONDARY` | `#201710` | Deeper shadow. Nested containers, list items. |
| `BG_TERTIARY` | `#150F09` | Near-black. Overlays behind modals. |
| `BG_ELEVATED` | `#352A1C` | Warmer than primary. Modals and popups. |
| `BG_SURFACE` | `#3D2E1E` | Selected/active list rows, highlight state. |
| `TEXT_PRIMARY` | `#F5E6C8` | Cream. All readable prose and dialogue. |
| `TEXT_SECONDARY` | `#C4A97A` | Muted gold-tan. Metadata, stat labels. |
| `TEXT_DISABLED` | `#6B5940` | Dark amber. Locked/unavailable content. |
| `TEXT_ACCENT` | `#D4A843` | Full gold. Scored hands, milestone announcements. |
| `TEXT_INVERSE` | `#2A1F14` | Text on gold fills (inside primary buttons). |
| `ACCENT_GOLD` | `#D4A843` | The divine. Primary interactive color. |
| `ACCENT_GOLD_BRIGHT` | `#E8C060` | Pressed state, scoring highlights. |
| `ACCENT_GOLD_DIM` | `#9A7A2E` | Inactive tabs, secondary gold elements. |
| `ACCENT_BORDER` | `#D4A843` @ 60% | Standard panel border (gold, translucent). |
| `INTERACTIVE_DISABLED` | `#4A3A24` | Disabled button fill. |
| `STATUS_SUCCESS` | `#5DBB3F` | Victory, unlock, milestone reached. |
| `STATUS_ERROR` | `#D94040` | Damage, failure, blocked action. |
| `STATUS_WARNING` | `#D4882A` | Low resources, time pressure. |
| `STATUS_INFO` | `#3A8FD4` | Tutorials, informational tooltips. |
| `OVERLAY_MODAL` | `#150F09` @ 80% | Behind modals. |
| `OVERLAY_DIALOGUE` | `#150F09` @ 50% | Behind dialogue, preserving VN art. |

- 1a. `TEXT_PRIMARY` on `BG_PRIMARY` yields ~7.8:1 contrast (WCAG AAA).
- 1b. Gold (`TEXT_ACCENT`) is not used for body prose. It marks authority: scored hands, gold counts, milestone announcements.
- 1c. Dialogue text always uses `TEXT_PRIMARY`. Gold in dialogue is reserved for character names in speaker labels only.
- 1d. Status colors appear as text labels, icon tints, and narrow border accents (4px stripes). They never fill large backgrounds.
- 1e. Overlays are never pure black (except tutorial spotlights). Always use brown-black tones so the world still feels present.

**Element Colors (pre-baked background variants):**

| Element | Foreground | Background | Semantic |
|---------|-----------|------------|----------|
| Fire (Hipolita) | `#F24D26` | `#3D1208` | Strength, passion, conquest |
| Water (Nyx) | `#338CF2` | `#0A1F3D` | Depth, mystery, ancient patience |
| Earth (Artemisa) | `#73BF40` | `#182A0A` | Vitality, nature, loyalty |
| Lightning (Atenea) | `#CCAA33` | `#2D2408` | Intellect, revelation, precision |

- 1f. Element foreground colors: icons, health bars, suit symbols, companion name badges. Never as body text.
- 1g. Element background colors: companion portrait frames, element-tagged card fills, combat score tray. Never layer two element backgrounds.
- 1h. Lightning (`#CCAA33`) and `ACCENT_GOLD` (`#D4A843`) are adjacent. Lightning always appears paired with Atenea's portrait or a lightning-suit symbol; standalone gold is always `ACCENT_GOLD`.

**2. Typography**

| Token | Font | Size | Weight | Use |
|-------|------|------|--------|-----|
| `FONT_TITLE_XL` | Cinzel | 40px | Regular | Hand rank announcements |
| `FONT_TITLE_LG` | Cinzel | 32px | Regular | Screen titles |
| `FONT_TITLE_MD` | Cinzel | 24px | Regular | Section headers |
| `FONT_TITLE_SM` | Cinzel | 20px | Regular | Card headers, enemy names |
| `FONT_BODY_LG` | Nunito Sans | 18px | Regular | Dialogue text (always) |
| `FONT_BODY_MD` | Nunito Sans | 16px | Regular | Descriptions, body copy |
| `FONT_BODY_SM` | Nunito Sans | 14px | Regular | Secondary descriptors |
| `FONT_BODY_EMPHASIS` | Nunito Sans | 18px | SemiBold | Companion responses |
| `FONT_LABEL_MD` | Nunito Sans | 16px | SemiBold | Button labels |
| `FONT_LABEL_STAT` | Nunito Sans | 20px | Bold | Stat values (read fast) |
| `FONT_LABEL_SM` | Nunito Sans | 12px | Regular | Stat labels, captions |
| `FONT_NAV` | Nunito Sans | 11px | SemiBold | Navigation labels |

- 2a. Cinzel is never used below 18px (illegible on mobile).
- 2b. Cinzel titles max 2 lines before truncation.
- 2c. Dialogue text is always 18px. Never reduce for space -- if the text box needs to scroll, it scrolls.
- 2d. Line height: 1.6 for body text, 1.2-1.3 for titles and labels.
- 2e. Nothing below 11px. The mobile readability floor.
- 2f. Never mix Cinzel and Nunito Sans on the same line of text.
- 2g. All-caps button text is forbidden.

**3. Panel Styles**

- 3a. **Standard panel**: `BG_PRIMARY` fill, 1px `ACCENT_BORDER` (gold @ 60%), 8px corner radius, 16px padding, no shadow.
- 3b. **Elevated panel** (modals/popups): `BG_ELEVATED` fill, 2px solid `ACCENT_GOLD` (100% opacity), 12px corner radius, drop shadow (0 8px 24px black @ 50%). Max width 380px (88% viewport). Always has a close affordance.
- 3c. **Gold border tiers**: 1px/60% = ambient (standard panels), 2px/100% = speaking (modals, selected cards), 3px/100% = acting (scoring hand, milestone unlock). Max 3 thick-gold instances visible at once.
- 3d. Gold borders do not animate by default. Shimmer/pulse is VFX-layer, not theme-layer.

**4. Button Styles**

- 4a. **Primary** (divine path): `ACCENT_GOLD` fill, `TEXT_INVERSE` label, 52px min height, 120px min width, 8px radius. Pressed: `ACCENT_GOLD_BRIGHT` fill + scale 0.97 (80ms ease-out). One primary button per screen view.
- 4b. **Secondary** (alternative path): transparent fill, 1.5px `ACCENT_GOLD` border, `ACCENT_GOLD` label. Pressed: gold fill @ 15%. Appears left of or below primary.
- 4c. **Danger** (irreversible): transparent fill, 1.5px `STATUS_ERROR` border, `STATUS_ERROR` label. Always in a confirmation dialog, always paired with "Cancel."
- 4d. **Disabled** (any type): `INTERACTIVE_DISABLED` fill/border, `TEXT_DISABLED` label. No touch events. Must have adjacent explanation of why.
- 4e. **No ripple effect.** Scale-compression + color-shift is the feedback pattern. Ripple is Material Design and breaks the mythological aesthetic.

**5. Touch Targets**

- 5a. Minimum touch target: 44x44px for any interactive element. Visual may be smaller; hitbox must not.
- 5b. Primary buttons: 52px height minimum.
- 5c. List item rows: 64px height minimum.
- 5d. Poker cards in hand: 64x90px minimum tap target.
- 5e. Bottom nav items: 60px height, equal-width across 430px viewport.
- 5f. Minimum 8px gap between touch targets. 12px for horizontally adjacent buttons.
- 5g. No interactive content within 8px of screen edges.

**6. Thumb Zones (430x932 portrait)**

- 6a. Bottom 560px (60%): primary thumb zone. All primary actions here.
- 6b. 560-750px from bottom: secondary zone. Tab navigation, section headers.
- 6c. Top 182px: passive zone. Display only (screen title, gold balance, back button).
- 6d. Dialogue tap-to-advance area covers bottom 40% of screen.
- 6e. Bottom nav bar sits at very bottom, above safe area.

**7. Touch Feedback**

- 7a. Pressed feedback within 1 frame (16ms) of touch contact.
- 7b. Scale 0.97 + color shift on press, revert in 80ms ease-out on release.
- 7c. Haptics: light (15ms) on standard buttons, medium (30ms) on card selection, heavy (50ms) on score confirmation.

**8. Screen Transitions**

- 8a. Standard: fade through black, 200ms out + 200ms in.
- 8b. Dialogue-to-combat: fast cut, 100ms fade.
- 8c. Tab bar switches: instant, no transition.
- 8d. Back navigation: 200ms fade. No slide.

**9. Modals**

- 9a. Overlay: `OVERLAY_MODAL` behind panel.
- 9b. Bottom sheet: slide up 250ms ease-out. Swipe-down-to-dismiss at 40% drag threshold.
- 9c. Confirmation dialogs: center-screen, not bottom sheet. No touch-outside-to-dismiss.
- 9d. All modal panels carry 2px gold border.

**10. Safe Zones**

- 10a. Top: reserve 44px (status bar + notch).
- 10b. Bottom: reserve 34px (home indicator). Nav bar sits above this.
- 10c. Sides: 8px minimum gutter.
- 10d. Read `DisplayServer.get_display_safe_area()` at runtime to adjust.

### States and Transitions

The UI Theme is a static resource -- it has no runtime states. It is loaded once and applied globally. Individual UI elements have interactive states (normal, pressed, disabled) defined in the button and touch rules above.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **All 18+ screens** | Screens inherit from this | Theme `.tres` resource on root Control node | Every screen inherits palette, fonts, and base styles. |
| **Localization** | Theme supports Localization | `locale_changed` signal triggers text re-resolve | Theme defines text colors/fonts; Localization provides text content. Auto-wrap required for variable-length translations. |
| **Dialogue** | Dialogue uses theme | Dialogue box uses `BG_PRIMARY`, `TEXT_PRIMARY`, `FONT_BODY_LG` | Speaker labels use `TEXT_ACCENT` (gold) for character names. |
| **Poker Combat** | Combat uses theme + element colors | Score display uses `TEXT_ACCENT`, element colors for suit indicators | Scoring moment uses `ACCENT_GOLD_BRIGHT` and thick gold border. |
| **Companion Data** | Element colors mapped to companions | Fire=Hipolita, Water=Nyx, Earth=Artemisa, Lightning=Atenea | Portrait frames use element background colors. |
| **Settings Screen** | Settings overrides nothing | Standard panel + button styles | Language selector, volume sliders, toggle switches. |

## Formulas

This system defines visual constants, not calculations. No formulas apply. The performance contract is: the Theme `.tres` resource must load within 1 frame (16.6ms) at startup. Font files (Cinzel + Nunito Sans) must be bundled as `.tres` FontFile resources, not loaded from disk at runtime.

## Edge Cases

- **If a screen overrides the base theme with custom colors**: The override must only affect that screen's Control subtree. Never modify the shared Theme resource at runtime -- clone it per-screen if overrides are needed.

- **If a localized string is 50% longer than English and overflows a fixed-width button**: Button labels must use auto-sizing with a minimum width of 120px. If the label still overflows, truncate with ellipsis. Never wrap button text to two lines.

- **If Lightning element color (`#CCAA33`) is displayed without companion context**: It will be visually confused with `ACCENT_GOLD` (`#D4A843`). Lightning must always appear paired with Atenea's portrait or a lightning-suit icon. If the context is ambiguous, add a small lightning-bolt icon.

- **If a screen places a primary action button in the top 182px (passive zone)**: This violates Rule 6c. The button must be moved to the primary thumb zone (bottom 560px) or paired with a gesture shortcut.

- **If two thick-gold borders (3px/100%) are visible simultaneously beyond the 3-instance limit**: The lowest-priority gold border must be downgraded to medium (2px). Priority order: scoring hand highlight > active equipment slot > milestone card.

- **If the device safe area inset is larger than the reserved 44px top / 34px bottom**: Use the device's actual inset (from `DisplayServer.get_display_safe_area()`), not the theme's minimum. The minimums are floors, not caps.

- **If haptic feedback is unavailable (web export, older devices)**: Degrade gracefully. Visual feedback (scale + color shift) must be sufficient on its own. Never block an action because haptics failed.

## Dependencies

| System | Direction | Nature | Hard/Soft |
|--------|-----------|--------|-----------|
| **All UI screens** | Screens depend on this | Theme resource inherited by every Control node | Hard (MVP) |
| **Localization** | Theme supports Localization | Auto-wrap and text sizing accommodate variable string lengths | Soft |
| **Dialogue** | Dialogue uses theme styles | Text box, speaker label, choice buttons | Hard (MVP) |
| **Poker Combat** | Combat uses element colors | Suit indicators, score display, hand rank text | Hard (MVP) |
| **Companion Data** | Element-to-companion mapping | Portrait frames, name badges, blessing icons | Hard (MVP) |
| **Scene Navigation** | Transitions use theme spec | Fade timing (200ms), transition color (black) | Soft |
| **Camp** | Camp uses theme styles | Companion cards, daily interaction buttons | Hard (Vertical Slice) |

**Bidirectional notes:**
- Localization GDD already references UI Theme for `locale_changed` signal pattern (see `design/gdd/localization.md` Cross-References).
- Companion Data GDD defines element-to-companion mapping; this GDD defines the color values for those elements.
- Every downstream screen GDD must reference this GDD's palette and typography tokens, not define its own.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `ACCENT_GOLD` hex | `#D4A843` | Hue shift within ±15 degrees | Warmer/cooler gold feel | -- |
| `BG_PRIMARY` hex | `#2A1F14` | Lightness ±10% | Lighter = less moody, more readable | Darker = moodier, risk contrast loss |
| `FONT_BODY_LG` size | 18px | 16-22px | Larger = more readable, less text per screen | Smaller = more text, harder to read |
| `FONT_TITLE_LG` size | 32px | 28-40px | More dramatic headers | More subtle headers |
| Touch target minimum | 44px | 40-56px | Easier to tap, less screen content | Harder to tap |
| Transition duration | 200ms | 100-400ms | More cinematic but slower-feeling | Snappier but abrupt |
| Panel corner radius | 8px | 4-16px | Rounder = softer, modern | Sharper = harder, archaic |
| Gold border opacity | 60% | 30-100% | More visible gold = more decorative | More subtle gold = more understated |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Button press | Scale 0.97 + color shift (80ms) | Light haptic (15ms) | MVP |
| Card selection | Scale 0.97 + gold border activate | Medium haptic (30ms) | MVP |
| Score confirmation | `ACCENT_GOLD_BRIGHT` flash + thick border | Heavy haptic (50ms) | MVP |
| Screen transition | Fade through black (200ms + 200ms) | Optional whoosh SFX (defer to Audio GDD) | MVP |
| Modal appear | Overlay dim + slide-up (250ms) | Soft stone-slide SFX (defer to Audio GDD) | Vertical Slice |
| Error state | `STATUS_ERROR` 4px left-border stripe | Error tone (defer to Audio GDD) | MVP |
| Milestone unlock | Thick gold border + shimmer VFX | Fanfare (defer to Audio GDD) | Vertical Slice |

**Visual style constraints:**
- All UI feedback uses flat color shifts and scale transforms. No 3D effects, no gradients, no glass/blur.
- Gold shimmer on milestone events is the only animated border effect. It is VFX-layer, implemented by technical-artist, not embedded in the theme resource.
- Panel backgrounds are solid flat fills, never textured. The "ancient parchment" feel comes from the warm brown palette and gold borders, not from texture overlays.

## UI Requirements

The UI Theme system IS the UI requirement specification. Every screen references this GDD's palette, typography, panel styles, button styles, touch targets, and interaction patterns. No separate UI requirements section is needed -- this entire GDD is the UI spec.

**UX Flag -- UI Theme**: Every screen in the game has UI requirements defined by this GDD. In Phase 4 (Pre-Production), run `/ux-design` to create per-screen UX specs that reference these theme tokens by name. Stories that reference UI should cite `design/ux/[screen].md` and this GDD, not define their own visual constants.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Element-to-companion mapping | `design/gdd/companion-data.md` | Element enum (Fire, Water, Earth, Lightning) per companion | Data dependency |
| Locale-changed signal for text refresh | `design/gdd/localization.md` | `locale_changed` signal, `get_text()` API | State trigger |
| Font tokens for dialogue rendering | `design/gdd/dialogue.md` | `FONT_BODY_LG` for dialogue text, `TEXT_ACCENT` for speaker names | Rule dependency |
| Element colors for combat scoring | `design/gdd/poker-combat.md` | Foreground/background element hex values for suit indicators | Data dependency |
| Screen transition timing | `design/gdd/scene-navigation.md` | 200ms fade standard, 100ms fast cut | Rule dependency |

## Acceptance Criteria

- [ ] **AC-UT01** -- **GIVEN** the theme resource is loaded, **WHEN** `TEXT_PRIMARY` (#F5E6C8) is rendered on `BG_PRIMARY` (#2A1F14), **THEN** contrast ratio is >= 4.5:1 (WCAG AA minimum). Actual target: ~7.8:1.

- [ ] **AC-UT02** -- **GIVEN** any button on any screen, **WHEN** the button is tapped, **THEN** visual pressed feedback (scale 0.97 + color shift) appears within 16ms.

- [ ] **AC-UT03** -- **GIVEN** a primary button, **WHEN** rendered, **THEN** it has `ACCENT_GOLD` fill, `TEXT_INVERSE` label, minimum 52px height, minimum 120px width.

- [ ] **AC-UT04** -- **GIVEN** any interactive element, **WHEN** measured, **THEN** its touch hitbox is at least 44x44px.

- [ ] **AC-UT05** -- **GIVEN** a screen with a primary action, **WHEN** the screen is displayed on a 430x932 viewport, **THEN** the primary action button is within the bottom 560px (primary thumb zone).

- [ ] **AC-UT06** -- **GIVEN** a standard screen transition, **WHEN** triggered, **THEN** it fades through black in 200ms out + 200ms in.

- [ ] **AC-UT07** -- **GIVEN** a modal dialog, **WHEN** displayed, **THEN** it has `BG_ELEVATED` fill, 2px solid `ACCENT_GOLD` border, 12px corner radius, and an overlay behind it.

- [ ] **AC-UT08** -- **GIVEN** an element color (Fire/Water/Earth/Lightning), **WHEN** used as a foreground color, **THEN** it matches the exact hex from the palette table and is not used as body text.

- [ ] **AC-UT09** -- **GIVEN** a device with a notch or home indicator, **WHEN** the app runs, **THEN** no interactive element overlaps the device safe area insets.

- [ ] **AC-UT10** -- **GIVEN** dialogue text, **WHEN** rendered, **THEN** it uses `FONT_BODY_LG` (Nunito Sans 18px Regular) and `TEXT_PRIMARY` color. Never `TEXT_ACCENT`.

- [ ] **AC-UT11** -- **GIVEN** the theme `.tres` file, **WHEN** loaded at startup, **THEN** load completes within 16.6ms (one frame at 60fps).

- [ ] No hardcoded color values in any scene file -- all colors reference theme tokens.
- [ ] No font assignments outside the theme -- all text uses theme-defined font tokens.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should panel backgrounds eventually use subtle noise/parchment textures, or stay flat? | Art Director | Before art bible | Current design is flat fills. Textures would add warmth but cost draw calls on mobile. |
| Should Cinzel be replaced with a custom mythological display font? | Art Director | Before art bible | Cinzel works well but is widely used. A custom font would be more distinctive. |
| Should dark mode / light mode be offered, or is the gold-on-brown theme fixed? | Game Designer | Before Vertical Slice | Current: fixed theme. A light mode would undermine the mythological tone. |
| How should the theme handle landscape orientation if web players rotate their browser? | Technical Director | Before web export | Current: portrait-only. Landscape could show letterboxing or a rotated layout. |
