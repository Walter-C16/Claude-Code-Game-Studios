extends Control

## Deck Viewer — Displays the player's full 52-card poker-combat deck.
##
## Builds a DeckManager instance to produce the canonical unshuffled deck,
## groups cards by suit with section headers, and stagger-animates the list
## on entry. Read-only view (Story Mode).

# ── Constants ─────────────────────────────────────────────────────────────────

## Unicode suit glyphs.
const SUIT_GLYPHS: Dictionary = {
	"Hearts": "♥",
	"Diamonds": "♦",
	"Clubs": "♣",
	"Spades": "♠",
}

## Face-value display names for J/Q/K/A.
const VALUE_NAMES: Dictionary = {
	11: "J",
	12: "Q",
	13: "K",
	14: "A",
}

## Enhancement badge colors.
const ENHANCEMENT_COLORS: Dictionary = {
	"Foil": Color("#00E5FF"),
	"Holographic": Color("#CC88FF"),
	"Polychrome": Color("#E8C860"),
}

## Minimum height per card row (touch target).
const CARD_ROW_HEIGHT: float = 44.0

# ── @onready node references ──────────────────────────────────────────────────

@onready var title_label: Label = %TitleLabel
@onready var card_list: VBoxContainer = %CardList
@onready var deck_size_label: Label = %DeckSizeLabel
@onready var back_btn: Button = %BackBtn

# ── Private state ─────────────────────────────────────────────────────────────

var _deck_manager: Node

# ── Built-in virtual methods ──────────────────────────────────────────────────

func _ready() -> void:
	# Clear placeholder from scene file.
	for child: Node in card_list.get_children():
		child.queue_free()

	# Build deck via a scene-local DeckManager so _ready() restores captain.
	_deck_manager = DeckManager.new()
	add_child(_deck_manager)
	# One frame so DeckManager._ready() runs and restores captain ID.
	await get_tree().process_frame

	var deck: Array[Dictionary] = _deck_manager.build_deck()
	deck_size_label.text = "%d cards" % deck.size()

	_populate_list(deck)

	# Captain info header.
	var captain_id: String = GameStore.get_last_captain_id()
	if not captain_id.is_empty():
		var profile: Dictionary = CompanionRegistry.get_profile(captain_id)
		title_label.text = "%s's Deck" % profile.get("display_name", captain_id.capitalize())
	else:
		title_label.text = "MY DECK"

	# One frame for layout, then stagger entrance.
	await get_tree().process_frame
	Fx.stagger_children(card_list, 0.02, 16.0)


## Navigate back to the hub.
func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── Private methods ───────────────────────────────────────────────────────────

## Populates %CardList with suit section headers and card rows.
func _populate_list(deck: Array[Dictionary]) -> void:
	var current_suit: String = ""

	for card: Dictionary in deck:
		var suit: String = card.get("suit", "")

		# Emit a section header whenever the suit changes.
		if suit != current_suit:
			current_suit = suit
			card_list.add_child(_make_section_header(suit, card.get("element", "")))

		card_list.add_child(_make_card_row(card))


## Creates a styled section header Label for a suit group.
func _make_section_header(suit: String, element: String) -> Label:
	var header: Label = Label.new()
	header.custom_minimum_size = Vector2(0.0, 36.0)
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	header.add_theme_font_size_override("font_size", 13)
	var glyph: String = SUIT_GLYPHS.get(suit, "?")
	header.text = "  %s  %s  -  %s" % [glyph, suit.to_upper(), element.to_upper()]
	header.modulate = _element_color(element)
	return header


## Creates a styled HBoxContainer row for a single card.
func _make_card_row(card: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, CARD_ROW_HEIGHT)
	row.add_theme_constant_override("separation", 8)

	# Suit glyph.
	var suit_label: Label = Label.new()
	suit_label.custom_minimum_size = Vector2(24.0, 0.0)
	suit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	suit_label.add_theme_font_size_override("font_size", 18)
	var suit: String = card.get("suit", "")
	var element: String = card.get("element", "")
	suit_label.text = SUIT_GLYPHS.get(suit, "?")
	suit_label.modulate = _element_color(element)
	row.add_child(suit_label)

	# Value + suit name.
	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", UIConstants.TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 15)
	var value: int = card.get("value", 0)
	name_label.text = "%s of %s" % [_value_name(value), suit]
	row.add_child(name_label)

	# Element badge.
	var elem_badge: Label = Label.new()
	elem_badge.text = element
	elem_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	elem_badge.add_theme_color_override("font_color", _element_color(element))
	elem_badge.add_theme_font_size_override("font_size", 11)
	row.add_child(elem_badge)

	# Enhancement badge (if any).
	var enhancement: String = card.get("enhancement", "")
	if not enhancement.is_empty():
		var enh_color: Color = ENHANCEMENT_COLORS.get(enhancement, UIConstants.TEXT_SECONDARY)
		var enh_label: Label = Label.new()
		enh_label.text = enhancement
		enh_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		enh_label.add_theme_color_override("font_color", enh_color)
		enh_label.add_theme_font_size_override("font_size", 11)
		row.add_child(enh_label)
		if enhancement == "Polychrome":
			Fx.gold_shimmer(enh_label, 2.0)

	# Signature star indicator.
	var is_signature: bool = card.get("is_signature", false)
	if is_signature:
		var star: Label = Label.new()
		star.text = "★"
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
		star.add_theme_font_size_override("font_size", 16)
		row.add_child(star)

	return row


## Returns the display name string for a card value integer.
func _value_name(value: int) -> String:
	if VALUE_NAMES.has(value):
		return VALUE_NAMES[value]
	return str(value)


## Returns the element foreground Color for a given element name.
func _element_color(element: String) -> Color:
	match element:
		"Fire": return UIConstants.ELEM_FIRE_FG
		"Water": return UIConstants.ELEM_WATER_FG
		"Earth": return UIConstants.ELEM_EARTH_FG
		"Lightning": return UIConstants.ELEM_LIGHTNING_FG
		_: return UIConstants.TEXT_SECONDARY
