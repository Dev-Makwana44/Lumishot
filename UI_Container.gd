extends CanvasLayer

@onready var crafting_ui: Crafting_UI = %"Crafting UI"
@onready var player: Player = $"../Player"

func _process(delta):
	if Input.is_action_just_pressed("open_inventory"):
		if not crafting_ui.visible:
			player.game_paused = true
			crafting_ui.show()
			crafting_ui.inventory = player.inventory
			crafting_ui.populate_inventory()
		else:
			player.game_paused = false
			crafting_ui.hide()
			crafting_ui.clear_crafting_grid()
			player.inventory = crafting_ui.inventory
