class_name InventoryComponent
extends RefCounted

var inventory_contents: Dictionary = {}
#signal update_inventory_ui


func add_item(item: ItemData) -> void:
	#if inventory_contents.has(item):
		#if inventory_contents[item] < item.item_stack_size:
			#inventory_contents[item] += 1
	#else:
		#inventory_contents[item] = 1
	inventory_contents[item] = inventory_contents.get(item, 0) + 1
	#update_inventory_ui.emit()

func add_item_with_amount(item: ItemData, amount: int) -> void:
	inventory_contents[item] = inventory_contents.get(item, 0) + amount

func add_crafted_item(item: ItemData) -> void:
	inventory_contents[item] = inventory_contents.get(item, 0) + item.crafting_batch_size

func check_inventory_contents(item: ItemData) -> bool:
	if inventory_contents.has(item):
		return inventory_contents[item] < item.item_stack_size
	return true

func get_inventory_contents() -> Dictionary:
	return inventory_contents
#
#func inventory_has_items(inventory: InventoryComponent) -> bool:
	#for item: ItemData in inventory.get_inventory_contents():
		#if inventory_contents.get(item, 0) < inventory.get_inventory_contents()[item]:
			#return false
	#return true

func inventory_has_items(inventory: Array[ItemData]) -> bool:
	var dct: Dictionary = {}
	for item: ItemData in inventory:
		dct[item] = dct.get(item, 0) + 1
	for item: ItemData in dct:
		if inventory_contents.get(item, 0) < dct[item]:
			return false
	return true

func remove_items(items: Array[ItemData]) -> void:
	for item: ItemData in items:
		inventory_contents[item] -= 1
		if inventory_contents[item] == 0:
			inventory_contents.erase(item)
