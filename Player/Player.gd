class_name Player
extends CharacterBody2D

signal player_health_changed

const bullet_indices: Dictionary = {
	'Bullet' : 0,
	'Explosive Bullet' : 1,
	'Cryo Bullet' : 2,
	'Neurotoxic Bullet' : 3,
	'Electric Bullet' : 4
}

const grenade_indices: Dictionary = {
	'Grenade' : 0,
	'Cryo Grenade' : 1,
	'Flare Grenade' : 2
}

const potion_indices: Dictionary = {
	'Health Potion' : 0,
	'Energy Boost Potion' : 1,
	'Invisibility Potion' : 2,
	'Shielding Potion' : 3,
	'Quantum Blink Potion' : 4
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gun: Sprite2D = $Gun
@onready var camera: Camera2D = $Camera2D
@onready var light: PointLight2D = $"Cone Light2"
@onready var footstep: AudioStreamPlayer2D = $footstep
@onready var hurt: AudioStreamPlayer2D = $hurt
@onready var area: Area2D = $Area2D

@onready var dash_cooldown_timer: Timer = $"Dash Cooldown"
@onready var dash_timer: Timer = $"Dash Timer"
@onready var quantum_blink_timer: Timer = $"Quantum Blink Timer"
@onready var shielding_timer: Timer = $"Shielding Timer"
@onready var invisibility_timer: Timer = $"Invisibility Timer"
@onready var speed_boost_timer: Timer = $"Speed Boost Timer"
@onready var damage_flash_timer: Timer = $"Damage Flash Timer"
@onready var frozen_timer: Timer = $"Frozen Timer"


var SPEED: float = 500.0
var FRICTION: float = SPEED / 10 # Dictates how fast the player accelerates. Usually going to be SPEED / 10 but might change if player is on different surfaces
var DASH_SPEED: float = 2000.0
#const FROZEN_DURATION: float = 2.0
var FIRE_RATE: float = 0.1
const MAX_HEALTH: int = 100

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var dash_available: bool = true
var time_since_shooting: float = FIRE_RATE
#var time_since_frozen: float = FROZEN_DURATION
var inventory: InventoryComponent = InventoryComponent.new()
var game_paused: bool = false
var ammo: Array[int] = [0, 0, 0, 0, 0]
var grenades: Array[int] = [0, 0, 0]
var potions: Array[int] = [0, 0, 0, 0, 0]
var selected_ammo_index: int = 0
var selected_grenade_index: int = 0
var selected_potion_index: int = 0
#var frozen: bool = false
var health: int = MAX_HEALTH
var room: Room = null

func _ready():
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData, 300)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/HealthPotion.tres") as ItemData, 3)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/ShieldingPotion.tres") as ItemData, 3)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/EnergyBoostPotion.tres") as ItemData, 3)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/InvisibilityPotion.tres") as ItemData, 3)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/QuantumBlinkPotion.tres") as ItemData, 3)
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/CryoGrenade.tres") as ItemData, 3)
	set_inventory(self.inventory)

func _physics_process(delta):
	#if frozen:
		#time_since_frozen += delta
		#if time_since_frozen >= FROZEN_DURATION:
			#frozen = false
			#self.modulate.r *= 2
			#sprite.speed_scale = 1
	if not game_paused and self.frozen_timer.is_stopped():
		var global_mouse_pos: Vector2 = get_global_mouse_position()
		gun.look_at(global_mouse_pos)
		light.look_at(global_mouse_pos)
		
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
			if sprite.frame % 2 == 1:
				footstep.pitch_scale = rng.randfn(1.0, 0.1)
				footstep.play()
		else:
			sprite.play("Idle")
		
		if Input.is_action_just_pressed("dash") and self.dash_available:
			self.velocity = v * DASH_SPEED
			dash_timer.start()
		
		if dash_timer.is_stopped():
			self.velocity.x = min(self.velocity.x, v.x * SPEED)
			self.velocity.y = min(self.velocity.y, v.y * SPEED)
			self.velocity.x = move_toward(velocity.x, v.x * SPEED, FRICTION)
			self.velocity.y = move_toward(velocity.y, v.y * SPEED, FRICTION)
		
		time_since_shooting += delta
		
		move_and_slide()		

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			camera.zoom *= 1.1
		elif event.pressed and event.keycode == KEY_O:
			camera.zoom *= 0.9
			
func damage(damage: int) -> void:
	if self.quantum_blink_timer.is_stopped():
		self.health -= damage * (0.5 ** int(!self.shielding_timer.is_stopped()))
		self.health = max(self.health, 0)
		self.hurt.pitch_scale = rng.randfn(1.0, 0.05)
		self.hurt.play()
		self.player_health_changed.emit()
		if self.damage_flash_timer.is_stopped():
			self.modulate.g /= 2
			self.modulate.b /= 2
		self.damage_flash_timer.start()

func set_inventory(inv: InventoryComponent) -> void:
	self.inventory = inv
	self.ammo = [0, 0, 0, 0, 0]
	self.grenades = [0, 0, 0]
	self.potions = [0, 0, 0, 0, 0]
	for item: ItemData in self.inventory.inventory_contents:
		if item.crafting_batch_size == 50:
			self.ammo[self.bullet_indices[item.item_name]] += self.inventory.inventory_contents[item]
		elif item.crafting_batch_size == 3:
			self.grenades[self.grenade_indices[item.item_name]] += self.inventory.inventory_contents[item]
		elif item.item_name.ends_with("Potion"):
			self.potions[self.potion_indices[item.item_name]] += self.inventory.inventory_contents[item]

func use_potion() -> bool:
	if selected_potion_index == 0 and self.health < self.MAX_HEALTH:
		self.health = min(self.health + 25, self.MAX_HEALTH)
		self.player_health_changed.emit()
		return true
	elif selected_potion_index == 1 and self.speed_boost_timer.is_stopped():
		SPEED *= 2
		DASH_SPEED *= 2
		FIRE_RATE /= 2
		self.speed_boost_timer.start()
		return true
	elif selected_potion_index == 2 and self.invisibility_timer.is_stopped():
		self.modulate.a /= 2
		self.invisibility_timer.start()
		return true
	elif selected_potion_index == 3 and self.shielding_timer.is_stopped():
		self.modulate.g /= 2
		self.modulate.b = 0
		self.shielding_timer.start()
		return true
	elif selected_potion_index == 4 and self.quantum_blink_timer.is_stopped():
		self.modulate.r /= 2
		self.quantum_blink_timer.start()
		return true
	return false

func freeze() -> void:
	#time_since_frozen = 0.0
	#if not frozen:
		#frozen = true
		#sprite.speed_scale = 0
		#self.modulate.r /= 2
	if self.frozen_timer.is_stopped():
		self.sprite.speed_scale = 0
		self.modulate.r /= 2
		self.frozen_timer.start()

func _on_dash_timer_timeout() -> void:
	self.dash_cooldown_timer.start()

func _on_dash_cooldown_timeout():
	self.dash_available = true

func _on_damage_flash_timer_timeout():
	self.modulate.g *= 2
	self.modulate.b *= 2

func _on_invisibility_timer_timeout():
	self.modulate.a *= 2

func _on_quantum_blink_timer_timeout():
	self.modulate.r *= 2

func _on_shielding_timer_timeout():
	self.modulate.g *= 2
	self.modulate.b = 1

func _on_speed_boost_timer_timeout():
	SPEED /= 2
	DASH_SPEED /= 2
	FIRE_RATE *= 2

func _on_frozen_timer_timeout():
	self.sprite.speed_scale = 1
	self.modulate.r *= 2
