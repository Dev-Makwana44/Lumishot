class_name Player
extends CharacterBody2D

const bullet_indices: Dictionary = {
	'Bullet' : 0,
	'Explosive Bullet' : 1,
	'Cryo Bullet' : 2,
	'Neurotoxic Bullet' : 3,
	'Electric Bullet' : 4
}

#const SPEED: float = 500.0
const SPEED: float = 500.0
const FRICTION: float = SPEED / 10 # Dictates how fast the player accelerates. Usually going to be SPEED / 10 but might change if player is on different surfaces
const DASH_SPEED: float = 2000.0
const DASH_DURATION: float = 0.25
const DASH_COOLDOWN: float = 1.0
const FIRE_RATE: float = 0.1


@onready var sprite = get_node("AnimatedSprite2D")
@onready var gun = get_node("Gun")
@onready var camera = get_node("Camera2D")

var time_since_dash: float = DASH_COOLDOWN
var time_since_shooting: float = FIRE_RATE
var inventory: InventoryComponent = InventoryComponent.new()
var game_paused: bool = false
var ammo: Array[int] = [0, 0, 0, 0, 0]
var selected_ammo_index = 0

func _ready():
	ammo[0] += 100
	ammo[1] += 100
	ammo[2] += 100
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData, 10)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/ExplosiveBullet.tres") as ItemData, 100)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/CryoBullet.tres") as ItemData, 100)
	set_inventory(self.inventory)

func _physics_process(delta):
	if not game_paused:
		var global_mouse_pos: Vector2 = get_global_mouse_position()
		gun.look_at(global_mouse_pos)
		
		if global_mouse_pos.x > self.position.x:
			sprite.flip_h = false
			gun.flip_h = false
			gun.position = Vector2(10, 0)
			gun.rotation_degrees += 45
		elif global_mouse_pos.x < self.position.x:
			sprite.flip_h = true
			gun.flip_h = true
			gun.position = Vector2(-10, 0)
			gun.rotation_degrees += 135
		
		
		var v: Vector2 = Vector2(int(Input.is_action_pressed("move_left")) * -1 + int(Input.is_action_pressed("move_right")), -1 * int(Input.is_action_pressed("move_up")) + int(Input.is_action_pressed("move_down")))
		v = v.normalized() # makes it so that strafing is not faster
		
		if v: 
			sprite.play("Run")
		else:
			sprite.play("Idle")
		
		if Input.is_action_just_pressed("dash") and time_since_dash > DASH_COOLDOWN:
			time_since_dash = 0.0
			self.velocity.x = v.x * DASH_SPEED
			self.velocity.y = v.y * DASH_SPEED
		
		if time_since_dash >= DASH_DURATION:
			self.velocity.x = min(self.velocity.x, v.x * SPEED)
			self.velocity.y = min(self.velocity.y, v.y * SPEED)
			self.velocity.x = move_toward(velocity.x, v.x * SPEED, FRICTION)
			self.velocity.y = move_toward(velocity.y, v.y * SPEED, FRICTION)
		
		time_since_dash += delta
		time_since_shooting += delta

		move_and_slide()
		
		

func _unhandled_input(event): # temporary keybinds to zoom in and out using P and O
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			camera.zoom += Vector2(0.1, 0.1)
		elif event.pressed and event.keycode == KEY_O:
			camera.zoom -= Vector2(0.1, 0.1)

func set_inventory(inv: InventoryComponent) -> void:
	self.inventory = inv
	self.ammo = [0, 0, 0, 0, 0]
	for item: ItemData in self.inventory.inventory_contents:
		if item.crafting_batch_size == 50:
			#ammo.add_item_with_amount(item, self.inventory.inventory_contents[item])
			self.ammo[self.bullet_indices[item.item_name]] += self.inventory.inventory_contents[item]
