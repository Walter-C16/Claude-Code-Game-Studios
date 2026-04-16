extends Control

## Equipment — Gear management screen. Two slots (weapon + amulet), pending queue.
##
## Uses EquipmentSystem (class_name, instantiated locally) to query items
## and manage equip/unequip. All persistence goes through GameStore.

# ── Node References ────────────────────────────────────────────────────────────

@onready var title_label: Label = %TitleLabel
@onready var slot_list: VBoxContainer = %SlotList
@onready var back_btn: Button = %BackBtn

# ── Private State ──────────────────────────────────────────────────────────────

var _equip_sys: EquipmentSystem

# ── Built-in Virtual Methods ───────────────────────────────────────────────────

func _ready() -> void:
	_equip_sys = EquipmentSystem.new()
	title_label.text = Localization.get_text("EQUIP_TITLE")

	for child: Node in slot_list.get_children():
		child.queue_free()

	_build_ui()
	await get_tree().process_frame
	Fx.stagger_children(slot_list, 0.05, 20.0)

	# First-visit tutorial explaining equipment slots, fragments, and tier-up.
	TutorialOverlay.show_once(self,
		"tutorial_equipment_shown",
		"TUTORIAL_EQUIP_TITLE",
		"TUTORIAL_EQUIP_BODY")


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_build_fragment_counter()
	_build_slot_section("weapon", Localization.get_text("EQUIP_WEAPON_HEADER"))
	_build_slot_section("amulet", Localization.get_text("EQUIP_AMULET_HEADER"))
	_build_pending_section()


## Shows the player's forge fragment balance at the top so they know
## whether they can afford a tier-up.
func _build_fragment_counter() -> void:
	var frag_label: Label = Label.new()
	frag_label.text = "%s: %d" % [
		Localization.get_text("EQUIP_FORGE_FRAGMENTS"),
		GameStore.get_forge_fragments(),
	]
	frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frag_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3, 1.0))
	frag_label.add_theme_font_size_override("font_size", 16)
	slot_list.add_child(frag_label)


## Builds a slot display: current item + unequip button.
func _build_slot_section(slot: String, label_text: String) -> void:
	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	slot_list.add_child(section)

	# Header.
	var header: Label = Label.new()
	header.text = label_text
	header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD)
	header.add_theme_font_size_override("font_size", 16)
	section.add_child(header)

	# Current equipped item.
	var equipped: Dictionary = _equip_sys.get_equipped(slot)
	var item_btn: Button = Button.new()
	item_btn.custom_minimum_size = Vector2(0.0, 60.0)
	item_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if equipped.is_empty():
		item_btn.text = Localization.get_text("EQUIP_EMPTY_SLOT")
		item_btn.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		item_btn.disabled = true
	else:
		var name_key: String = equipped.get("name_key", equipped.get("id", ""))
		var rarity: String = equipped.get("rarity", "common")
		var tier: int = GameStore.get_equipment_tier(slot)
		var tier_tag: String = " T%d" % tier if tier > 0 else ""
		var bonus_text: String = ""
		if slot == "weapon":
			bonus_text = "+%d chips" % int(equipped.get("chip_bonus", 0))
		else:
			bonus_text = "+%.2f mult" % float(equipped.get("mult_bonus", 0.0))
		item_btn.text = "%s%s  [%s]  %s" % [Localization.get_text(name_key), tier_tag, rarity.capitalize(), bonus_text]
		item_btn.add_theme_color_override("font_color", _rarity_color(rarity))
		item_btn.pressed.connect(func() -> void:
			_equip_sys.unequip(slot)
			_rebuild()
		)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIConstants.BG_SECONDARY
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = UIConstants.ACCENT_GOLD_DARK
	item_btn.add_theme_stylebox_override("normal", style)
	item_btn.add_theme_font_size_override("font_size", 14)
	section.add_child(item_btn)

	# Upgrade button — costs 5 forge fragments per tier, max tier 5.
	if not equipped.is_empty():
		var tier: int = GameStore.get_equipment_tier(slot)
		if tier < GameStore.MAX_EQUIPMENT_TIER:
			var cost: int = GameStore.TIER_UP_FRAGMENT_COST
			var can_afford: bool = GameStore.get_forge_fragments() >= cost
			var upgrade_btn: Button = Button.new()
			upgrade_btn.text = "%s (%d %s)" % [
				Localization.get_text("EQUIP_UPGRADE"),
				cost,
				Localization.get_text("EQUIP_FORGE_FRAGMENTS"),
			]
			upgrade_btn.custom_minimum_size = Vector2(0.0, 40.0)
			upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			upgrade_btn.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3, 1.0))
			upgrade_btn.add_theme_font_size_override("font_size", 13)
			upgrade_btn.disabled = not can_afford
			upgrade_btn.pressed.connect(func() -> void:
				if GameStore.upgrade_equipment_tier(slot):
					_rebuild()
			)
			section.add_child(upgrade_btn)
		else:
			var max_label: Label = Label.new()
			max_label.text = Localization.get_text("EQUIP_TIER_MAX")
			max_label.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
			max_label.add_theme_font_size_override("font_size", 12)
			section.add_child(max_label)


## Builds the pending items queue section.
func _build_pending_section() -> void:
	var pending_ids: Array[String] = _equip_sys.get_pending()
	if pending_ids.is_empty():
		return

	var header: Label = Label.new()
	header.text = Localization.get_text("EQUIP_PENDING_HEADER") % pending_ids.size()
	header.add_theme_color_override("font_color", UIConstants.ACCENT_GOLD_BRIGHT)
	header.add_theme_font_size_override("font_size", 16)
	header.custom_minimum_size = Vector2(0.0, 40.0)
	header.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	slot_list.add_child(header)

	for i: int in range(pending_ids.size()):
		var item_id: String = pending_ids[i]
		var item: Dictionary = _equip_sys.get_item(item_id)
		if item.is_empty():
			continue

		var slot: String = item.get("slot", "weapon")
		var rarity: String = item.get("rarity", "common")
		var name_key: String = item.get("name_key", item_id)
		var bonus_text: String = ""
		if slot == "weapon":
			bonus_text = "+%d chips" % int(item.get("chip_bonus", 0))
		else:
			bonus_text = "+%.2f mult" % float(item.get("mult_bonus", 0.0))

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0.0, 52.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = "EQUIP: %s [%s] %s" % [Localization.get_text(name_key), rarity.capitalize(), bonus_text]
		btn.add_theme_color_override("font_color", _rarity_color(rarity))
		btn.add_theme_font_size_override("font_size", 13)

		var pending_idx: int = i
		btn.pressed.connect(func() -> void:
			_equip_sys.equip(item_id, pending_idx)
			_rebuild()
		)

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = UIConstants.BG_TERTIARY
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = _rarity_color(rarity)
		btn.add_theme_stylebox_override("normal", style)
		slot_list.add_child(btn)


## Clears and rebuilds the entire UI.
func _rebuild() -> void:
	for child: Node in slot_list.get_children():
		child.queue_free()
	_build_ui()


## Returns color for item rarity.
func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return UIConstants.TEXT_PRIMARY
		"uncommon": return UIConstants.STATUS_SUCCESS
		"rare": return Color("#338CF2")
		"epic": return Color("#CC88FF")
		"legendary": return UIConstants.ACCENT_GOLD_BRIGHT
		_: return UIConstants.TEXT_SECONDARY
