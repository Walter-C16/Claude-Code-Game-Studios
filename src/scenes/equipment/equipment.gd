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
	title_label.text = "EQUIPMENT"

	for child: Node in slot_list.get_children():
		child.queue_free()

	_build_ui()
	await get_tree().process_frame
	Fx.stagger_children(slot_list, 0.05, 20.0)


func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.SceneId.HUB)


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_build_slot_section("weapon", "Weapon — Chip Bonus")
	_build_slot_section("amulet", "Amulet — Mult Bonus")
	_build_pending_section()


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
		item_btn.text = "[ Empty Slot ]"
		item_btn.add_theme_color_override("font_color", UIConstants.TEXT_DISABLED)
		item_btn.disabled = true
	else:
		var name_key: String = equipped.get("name_key", equipped.get("id", ""))
		var rarity: String = equipped.get("rarity", "common")
		var bonus_text: String = ""
		if slot == "weapon":
			bonus_text = "+%d chips" % int(equipped.get("chip_bonus", 0))
		else:
			bonus_text = "+%.2f mult" % float(equipped.get("mult_bonus", 0.0))
		item_btn.text = "%s  [%s]  %s" % [Localization.get_text(name_key), rarity.capitalize(), bonus_text]
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


## Builds the pending items queue section.
func _build_pending_section() -> void:
	var pending_ids: Array[String] = _equip_sys.get_pending()
	if pending_ids.is_empty():
		return

	var header: Label = Label.new()
	header.text = "Pending Items (%d/5)" % pending_ids.size()
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
