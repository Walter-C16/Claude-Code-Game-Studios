# Accessibility Requirements: Dark Olympus

> **Status**: Committed
> **Author**: gate-check / user
> **Last Updated**: 2026-04-10
> **Accessibility Tier Target**: Basic
> **Platform(s)**: Android / iOS / Web (HTML5)
> **External Standards Targeted**:
> - WCAG 2.1 Level A
> - Apple / Google Accessibility Guidelines: Partial (mobile-first)
> **Accessibility Consultant**: None engaged
> **Linked Documents**: `design/gdd/systems-index.md`, `design/gdd/ui-theme.md`

---

## Accessibility Tier Definition

### This Project's Commitment

**Target Tier**: Basic

**Rationale**: Dark Olympus is a turn-based poker combat / visual novel / dating sim
with no real-time input requirements. The turn-based structure eliminates the most
severe motor barriers. The game is text-heavy (dialogue, card names, scoring), making
visual legibility the primary accessibility concern. As a solo-developer indie project
targeting itch.io and Patreon distribution (not app stores requiring certification),
Basic tier is achievable without dedicated accessibility engineering. The UI Theme GDD
already specifies WCAG AA contrast (4.5:1), minimum touch targets (44x44px), and
element icons that pair color with shape (never color-only). These design decisions
cover the most impactful Basic-tier requirements by default.

**Features explicitly in scope (beyond tier baseline)**:
- Touch targets already at 44x44px minimum (exceeds Basic requirement)
- Element icons use shape+color (fire=flame, water=drop, earth=leaf, lightning=bolt)
- WCAG AA contrast ratios enforced via UI Theme token system

**Features explicitly out of scope**:
- Input remapping (touch-only game with no rebindable inputs)
- Colorblind modes (element icons already shape-differentiated; no color-only indicators)
- Screen reader support (Godot 4.5+ AccessKit available as future opportunity)
- Subtitle customization (no voice acting in MVP)

---

## Visual Accessibility

| Feature | Tier | Scope | Status | Notes |
|---------|------|-------|--------|-------|
| Minimum text size | Basic | All UI | Designed | Cinzel never below 18px; nothing below 11px (ui-theme.md) |
| Text contrast (4.5:1 AA) | Basic | All text | Designed | Enforced via theme tokens (TR-ui-theme-011) |
| Color-as-only-indicator audit | Basic | All UI/gameplay | Designed | Element icons pair color+shape (TR-poker-combat-032) |
| Screen flash / strobe | Basic | All VFX | Not Started | Max 4 GPU particle emitters; no bloom/glow (Mobile renderer) |
| Brightness controls | Basic | Global | Not Started | Expose in Settings screen |

### Color-as-Only-Indicator Audit

| Location | Color Signal | Non-Color Backup | Status |
|----------|-------------|-----------------|--------|
| Element types (combat) | Fire=red, Water=blue, Earth=green, Lightning=yellow | Shape icons: flame, drop, leaf, bolt | Designed |
| Companion elements | Color-coded borders | Element icon + companion name | Designed |
| HP bar | Red fill | Numeric score overlay + gold score marker | Designed |
| Relationship level | Stage-colored bar | Numeric RL value + stage name | Not Started |

---

## Motor Accessibility

| Feature | Tier | Scope | Status | Notes |
|---------|------|-------|--------|-------|
| Pause anywhere | Basic | All gameplay | Not Started | Turn-based combat has no time pressure; dialogue has tap-to-advance |
| No timed inputs | Basic | All gameplay | Designed | No QTEs, no timed choices, no rapid input. Fully turn-based. |
| Touch target size | Basic | All interactive elements | Designed | 44x44px minimum, primary buttons 52px (TR-ui-theme-004) |

---

## Cognitive Accessibility

| Feature | Tier | Scope | Status | Notes |
|---------|------|-------|--------|-------|
| Text speed control | Basic | Dialogue | Designed | Configurable CPS in Settings (TR-dialogue-005) |
| Tap to complete text | Basic | Dialogue | Designed | Tap skips typewriter to full text (TR-dialogue-005) |
| Card sorting | Basic | Combat hand | Designed | Toggle by Value or Suit (TR-poker-combat-016) |
| Scoring breakdown | Basic | Combat | Designed | Per-card resolution visible in scoring tray |

---

## Auditory Accessibility

| Feature | Tier | Scope | Status | Notes |
|---------|------|-------|--------|-------|
| Independent volume controls | Basic | Music / SFX buses | Not Started | Expose in Settings screen |
| No audio-only gameplay info | Basic | All systems | Designed | Turn-based; all state visible on screen. BGM is atmospheric only. |

---

## Known Intentional Limitations

| Feature | Why Not Included | Risk | Mitigation |
|---------|-----------------|------|------------|
| Input remapping | Touch-only; no rebindable inputs | Low — standard touch gestures only | N/A |
| Colorblind modes | All color-coded elements have shape/icon backup | Low | Audit at implementation |
| Screen reader | Solo dev scope; Godot AccessKit is opportunity for post-launch | Medium for visually impaired players | Menu text is large and high-contrast |
| Subtitle customization | No voice acting in MVP | N/A | Re-evaluate if VA is added |

---

## Audit History

| Date | Type | Scope | Findings |
|------|------|-------|----------|
| 2026-04-10 | Gate check | Tier commitment | Basic tier committed; UI Theme GDD covers most visual requirements by design |
