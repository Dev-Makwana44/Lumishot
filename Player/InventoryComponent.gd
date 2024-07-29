class_name InventoryComponent
extends RefCounted

var inventory_contents: Dictionary = {}
signal update_inventory_ui


func add_item(item: ItemData) -> void:
	if inventory_contents.has(item):
		if inventory_contents[item] < item.item_stack_size:
			inventory_contents[item] += 1
	else:
		inventory_contents[item] = 1

	update_inventory_ui.emit()

func check_inventory_contents(item: ItemData) -> bool:
	if inventory_contents.has(item):
		return inventory_contents[item] < item.item_stack_size
	return true

func get_inventory_contents() -> Dictionary:
	return inventory_contents

