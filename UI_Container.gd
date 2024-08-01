class_name UI_CONTAINER
extends CanvasLayer

@onready var player: Player = $"../Player"
@onready var crafting_ui: Crafting_UI = %"Crafting UI"
@onready var help_menu_ui = %"Help Menu"
@onready var hud: HUD = %HUD
@onready var loss_screen: LossScreen = %"Loss Screen"
@onready var level_completion_screen: LevelCompletionScreen = %"Level Completion Screen"


var bullets_data: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/ExplosiveBullet.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/CryoBullet.tres") as ItemData,
	3: load("res://Resources/Items/CraftableItems/NeurotoxicBullet.tres") as ItemData,
	4: load("res://Resources/Items/CraftableItems/ElectricBullet.tres") as ItemData
}

var grenade_data: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Grenade.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/CryoGrenade.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/FlareGrenade.tres") as ItemData
}

var potion_data: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/HealthPotion.tres"),
	1: load("res://Resources/Items/CraftableItems/EnergyBoostPotion.tres"),
	2: load("res://Resources/Items/CraftableItems/InvisibilityPotion.tres"),
	3: load("res://Resources/Items/CraftableItems/ShieldingPotion.tres"),
	4: load("res://Resources/Items/CraftableItems/QuantumBlinkPotion.tres")
}

func _ready() -> void:
	hud.set_ammo(bullets_data[0], player.ammo[0])
	hud.set_grenade(null, 1)
	hud.set_potion(null, 1)

func _process(delta) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		if (player.room == null or len(player.room.enemies) == 0):
			if not crafting_ui.visible and not level_completion_screen.visible and not loss_screen.visible:
				player.game_paused = true
				hud.hide()
				help_menu_ui.hide()
				crafting_ui.show()
				crafting_ui.inventory = player.inventory
				crafting_ui.populate_inventory()
			else:
				player.game_paused = false
				hud.show()
				crafting_ui.hide()
				crafting_ui.clear_crafting_grid()
				player.set_inventory(crafting_ui.inventory)
				hud.set_ammo(bullets_data[player.selected_ammo_index], player.ammo[player.selected_ammo_index])
			
	if Input.is_action_just_pressed("help") and not level_completion_screen.visible and not loss_screen.visible:
		if not help_menu_ui.visible:
			help_menu_ui.show()
		else:
			help_menu_ui.hide()
	
	if Input.is_action_just_pressed("select_ammo_up"):
		select_ammo_up()
		
	if Input.is_action_just_pressed("select_ammo_down"):
		select_ammo_down()
	
	if Input.is_action_just_pressed("select_grenade"):
		select_grenade()
	
	if Input.is_action_just_pressed("select_potion"):
		select_potion()

func select_ammo_up() -> void:
	if player.ammo != [0, 0, 0, 0, 0]:
		var current_index: int = (player.selected_ammo_index + 1) % len(player.ammo)
		while player.ammo[current_index] == 0:
			current_index = (current_index + 1) % len(player.ammo)
		player.selected_ammo_index = current_index
		hud.set_ammo(bullets_data[current_index], player.ammo[current_index])
	else:
		hud.set_ammo(null, 1)

func select_ammo_down() -> void:
	if player.ammo != [0, 0, 0, 0, 0]:
		var current_index: int = player.selected_ammo_index - 1
		if current_index == -1:
			current_index = len(player.ammo) - 1
		while player.ammo[current_index] == 0:
			current_index = current_index - 1
			if current_index == -1:
				current_index = len(player.ammo) - 1
		player.selected_ammo_index = current_index
		hud.set_ammo(bullets_data[current_index], player.ammo[current_index])
	else:
		hud.set_ammo(null, 1)

func select_grenade() -> void:
	if player.grenades != [0, 0, 0]:
		var current_index: int = (player.selected_grenade_index + 1) % len(player.grenades)
		while player.grenades[current_index] == 0:
			current_index = (current_index + 1) % len(player.grenades)
		player.selected_grenade_index = current_index
		hud.set_grenade(grenade_data[current_index], player.grenades[current_index])
	else:
		hud.set_grenade(null, 1)

func select_potion() -> void:
	if player.potions != [0, 0, 0, 0, 0]:
		var current_index: int = (player.selected_potion_index + 1) % len(player.potions)
		while player.potions[current_index] == 0:
			current_index = (current_index + 1) % len(player.potions)
		player.selected_potion_index = current_index
		hud.set_potion(potion_data[current_index], player.potions[current_index])
	else:
		hud.set_potion(null, 1)
