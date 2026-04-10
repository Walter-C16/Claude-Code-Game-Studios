class_name UITypography
extends RefCounted

## UITypography — Font Size Scale (ADR-0013)
##
## Defines the 12 allowed font/size combinations for Dark Olympus.
## Cinzel is used for display/title text. Nunito Sans is used for body/UI text.
## Code must use these constants instead of raw integer literals for font sizes.
##
## Usage:
##   label.add_theme_font_size_override(&"font_size", UITypography.DISPLAY_MD)

# ── Display sizes — Cinzel ───────────────────────────────────────────────────

## Cinzel 20px — smallest title / section header.
const DISPLAY_SM: int = 20

## Cinzel 24px — section title / card header.
const DISPLAY_MD: int = 24

## Cinzel 32px — screen title / major heading.
const DISPLAY_LG: int = 32

## Cinzel 40px — hero title / splash screen wordmark.
const DISPLAY_XL: int = 40

# ── Body sizes — Nunito Sans ─────────────────────────────────────────────────

## Nunito Sans 11px — micro label, badge count, fine print.
const BODY_XS: int = 11

## Nunito Sans 13px — secondary body, list sub-items.
const BODY_SM: int = 13

## Nunito Sans 15px — primary body / dialogue text.
const BODY_MD: int = 15

## Nunito Sans 18px — large body / emphasis paragraph.
const BODY_LG: int = 18

# ── Caption / Label sizes ────────────────────────────────────────────────────

## 10px — smallest legal / disclaimer text.
const CAPTION_SM: int = 10

## 12px — standard caption / timestamp / tooltip.
const CAPTION_MD: int = 12

## 14px — small UI label / tab text.
const LABEL_SM: int = 14

## 16px — standard UI label / button text.
const LABEL_MD: int = 16

# ── Audit Allowlist ──────────────────────────────────────────────────────────

## Exhaustive list of every permitted font size in the project.
## Code review and static analysis should flag any integer literal used as a
## font size that does not appear in this array.
const VALID_SIZES: Array[int] = [10, 11, 12, 13, 14, 15, 16, 18, 20, 24, 32, 40]
