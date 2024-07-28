extends CanvasLayer

@onready var inventory_ui: InventoryUI = %Inventory_UI
@onready var player: Player = $"../Player"

func _unhandled_input(event) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		if not inventory_ui.visible:
			inventory_ui.show()
			inventory_ui.populate_inventory(player.inventory)
		else:
			inventory_ui.hide()
			#inventory_ui.clean_inventory()
