class_name UI_CONTAINER
extends CanvasLayer

@onready var player: Player = $"../Player"
@onready var crafting_ui: Crafting_UI = %"Crafting UI"
@onready var help_menu_ui = %"Help Menu"
@onready var hud = %HUD


var bullets_data: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/ExplosiveBullet.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/CryoBullet.tres") as ItemData,
	3: load("res://Resources/Items/CraftableItems/NeurotoxicBullet.tres") as ItemData,
	4: load("res://Resources/Items/CraftableItems/ElectricBullet.tres") as ItemData
}

func _ready() -> void:
	hud.set_ammo(bullets_data[0], player.ammo[0])

func _process(delta) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		if not crafting_ui.visible:
			player.game_paused = true
			hud.hide()
			crafting_ui.show()
			crafting_ui.inventory = player.inventory
			crafting_ui.populate_inventory()
		else:
			player.game_paused = false
			hud.show()
			crafting_ui.hide()
			crafting_ui.clear_crafting_grid()
			player.set_inventory(crafting_ui.inventory)
	if Input.is_action_just_pressed("help"):
		if not help_menu_ui.visible:
			help_menu_ui.show()
		else:
			help_menu_ui.hide()
	
	if Input.is_action_just_pressed("select_ammo_up"):
		#var current_index: int = (player.selected_ammo_index + 1) % len(player.ammo)
		#while player.ammo[current_index] == 0:
			#current_index = (current_index + 1) % len(player.ammo)
		#player.selected_ammo_index = current_index
		#hud.set_ammo(bullets_data[current_index], player.ammo[current_index])
		select_ammo_up()
		
	if Input.is_action_just_pressed("select_ammo_down"):
		#var current_index: int = player.selected_ammo_index - 1
		#if current_index == -1:
			#current_index = len(player.ammo) - 1
		#while player.ammo[current_index] == 0:
			#current_index = current_index - 1
			#if current_index == -1:
				#current_index = len(player.ammo) - 1
		#player.selected_ammo_index = current_index
		#hud.set_ammo(bullets_data[current_index], player.ammo[current_index])
		select_ammo_down()

func select_ammo_up() -> void:
	var current_index: int = (player.selected_ammo_index + 1) % len(player.ammo)
	while player.ammo[current_index] == 0:
		current_index = (current_index + 1) % len(player.ammo)
	player.selected_ammo_index = current_index
	hud.set_ammo(bullets_data[current_index], player.ammo[current_index])

func select_ammo_down() -> void:
	var current_index: int = player.selected_ammo_index - 1
	if current_index == -1:
		current_index = len(player.ammo) - 1
	while player.ammo[current_index] == 0:
		current_index = current_index - 1
		if current_index == -1:
			current_index = len(player.ammo) - 1
	player.selected_ammo_index = current_index
	hud.set_ammo(bullets_data[current_index], player.ammo[current_index])
