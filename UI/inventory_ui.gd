class_name InventoryUI
extends PanelContainer

@export var inventory_slot: PackedScene = null
@onready var grid_container: GridContainer = get_node("MarginContainer/VBoxContainer/GridContainer")

func _ready():
	hide()

func populate_inventory(inventory: InventoryComponent):
	#print(inventory.get_inventory_contents())
	for item in inventory.get_inventory_contents():
		#print(item)
		var new_slot: InventorySlot = inventory_slot.instantiate() as InventorySlot
		grid_container.add_child(new_slot)
		await new_slot.ready
		new_slot.set_item_data(item, inventory.get_inventory_contents()[item])
	
	if not inventory.update_inventory_ui.is_connected(populate_inventory):
		inventory.update_inventory_ui.connect(populate_inventory.bind(inventory))

func clean_inventory() -> void:
	for item_slot in grid_container.get_children():
		item_slot.queue_free()

func _on_exit_button_button_down():
	clean_inventory()
	hide()
