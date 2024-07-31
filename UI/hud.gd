class_name HUD
extends PanelContainer

@onready var ammo_slot: InventorySlot = %"Ammo Slot"
@onready var ammo_label: Label = %"Ammo Label"

@onready var grenade_slot: InventorySlot = %"Grenade Slot"
@onready var grenade_label: Label = %"Grenade Label"

@onready var potion_slot: InventorySlot = %"Potion Slot"
@onready var potion_label: Label = %"Potion Label"

@onready var health_label: Label = %"Health Label"

func set_ammo(item: ItemData, amount: int):
	if item == null:
		ammo_slot.set_item_data(null, 1)
		ammo_label.text = "Empty"
	else:
		ammo_slot.set_item_data(item, amount)
		ammo_label.text = item.item_name

func set_grenade(item: ItemData, amount: int):
	if item == null:
		grenade_slot.set_item_data(null, 1)
		grenade_label.text = "Empty"
	else:
		grenade_slot.set_item_data(item, amount)
		grenade_label.text = item.item_name

func set_potion(item: ItemData, amount: int):
	if item == null:
		potion_slot.set_item_data(null, 1)
		potion_label.text = "Empty"
	else:
		potion_slot.set_item_data(item, amount)
		potion_label.text = item.item_name
