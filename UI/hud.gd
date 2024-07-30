class_name HUD
extends PanelContainer

@onready var inventory_slot: InventorySlot = %"Ammo Slot"
@onready var ammo_label: Label = %"Ammo Label"

func set_ammo(item: ItemData, amount: int):
	inventory_slot.set_item_data(item, amount)
	ammo_label.text = item.item_name
