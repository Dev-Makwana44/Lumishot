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

#const SPEED: float = 500.0
var SPEED: float = 500.0
var FRICTION: float = SPEED / 10 # Dictates how fast the player accelerates. Usually going to be SPEED / 10 but might change if player is on different surfaces
var DASH_SPEED: float = 2000.0
const DASH_DURATION: float = 0.25
const DASH_COOLDOWN: float = 1.0
const QUANTUM_BLINK_DURATION: float = 5.0
const SHIELDING_DURATION: float = 10.0
const INVISIBILITY_DURATION: float = 15.0
const SPEED_BOOST_DURATION: float = 10.0
const DAMAGE_FLASH_DURATION: float = 1.0
var FIRE_RATE: float = 0.1
const MAX_HEALTH: int = 100


@onready var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")
@onready var gun: Sprite2D = get_node("Gun")
@onready var camera: Camera2D = get_node("Camera2D")
@onready var light: PointLight2D = get_node("Cone Light2")

@onready var footstep = $footstep
@onready var hurt = $hurt
@onready var area: Area2D = get_node("Area2D")
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var time_since_dash: float = DASH_COOLDOWN
var time_since_shooting: float = FIRE_RATE
var time_since_quantum_blink: float = QUANTUM_BLINK_DURATION
var time_since_shielding: float = SHIELDING_DURATION
var time_since_invisibility: float = INVISIBILITY_DURATION
var time_since_speed_boost: float = SPEED_BOOST_DURATION
var time_since_damage: float = DAMAGE_FLASH_DURATION
var inventory: InventoryComponent = InventoryComponent.new()
var game_paused: bool = false
var ammo: Array[int] = [0, 0, 0, 0, 0]
var grenades: Array[int] = [0, 0, 0]
var potions: Array[int] = [0, 0, 0, 0, 0]
var selected_ammo_index: int = 0
var selected_grenade_index: int = 0
var selected_potion_index: int = 0
var invisible: bool = false
var shielding: bool = false
var quantum_blinking: bool = false
var speed_boost: bool = false
var damage_flash: bool = false

var health: int = MAX_HEALTH
var room: Room = null

func _ready():
	self.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData, 300)
	set_inventory(self.inventory)

func _physics_process(delta):
	if not game_paused:
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
		
		if Input.is_action_just_pressed("dash") and time_since_dash > DASH_COOLDOWN:
			time_since_dash = 0.0
			self.velocity.x = v.x * DASH_SPEED
			self.velocity.y = v.y * DASH_SPEED
		
		if time_since_dash >= DASH_DURATION:
			self.velocity.x = min(self.velocity.x, v.x * SPEED)
			self.velocity.y = min(self.velocity.y, v.y * SPEED)
			self.velocity.x = move_toward(velocity.x, v.x * SPEED, FRICTION)
			self.velocity.y = move_toward(velocity.y, v.y * SPEED, FRICTION)
		
		if self.damage_flash:
			time_since_damage += delta
			if time_since_damage >= DAMAGE_FLASH_DURATION:
				self.modulate.g *= 2
				self.modulate.b *= 2
				self.damage_flash = false
		
		time_since_dash += delta
		time_since_shooting += delta
		
		if self.speed_boost:
			self.time_since_speed_boost += delta
			if self.time_since_speed_boost >= SPEED_BOOST_DURATION:
				speed_boost = false
				SPEED /= 2
				DASH_SPEED /= 2
				FIRE_RATE *= 2
		
		if self.invisible:
			self.time_since_invisibility += delta
			if time_since_invisibility >= INVISIBILITY_DURATION:
				self.invisible = false
				self.modulate.a *= 2
		
		if self.shielding:
			self.time_since_shielding += delta
			if time_since_shielding >= SHIELDING_DURATION:
				self.shielding = false
				self.modulate.g *= 2
				self.modulate.b = 1
		
		if self.quantum_blinking:
			self.time_since_quantum_blink += delta
			if time_since_quantum_blink >= QUANTUM_BLINK_DURATION:
				self.quantum_blinking = false
				self.modulate.r *= 2
		
		move_and_slide()		

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			camera.zoom *= 1.1
		elif event.pressed and event.keycode == KEY_O:
			camera.zoom *= 0.9
			
func damage(damage: int) -> void:
	if not quantum_blinking:
		self.health -= damage if not shielding else int(damage * 0.5)
		self.health = max(self.health, 0)
		time_since_damage = 0.0
		hurt.pitch_scale = rng.randfn(1.0, 0.05)
		hurt.play()
		self.player_health_changed.emit()
		if not self.damage_flash:
			self.modulate.g /= 2
			self.modulate.b /= 2
			self.damage_flash = true

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
	if selected_potion_index == 0 and self.health < MAX_HEALTH:
		self.health = min(self.health + 25, MAX_HEALTH)
		self.player_health_changed.emit()
		return true
	elif selected_potion_index == 1 and not speed_boost:
		speed_boost = true
		time_since_speed_boost = 0.0
		SPEED *= 2
		DASH_SPEED *= 2
		FIRE_RATE /= 2
		return true
	elif selected_potion_index == 2 and not invisible:
		invisible = true
		time_since_invisibility = 0.0
		self.modulate.a /= 2
		return true
	elif selected_potion_index == 3 and not shielding:
		shielding = true
		time_since_shielding = 0.0
		self.modulate.g /= 2
		self.modulate.b = 0
		return true
	elif selected_potion_index == 4 and not quantum_blinking:
		quantum_blinking = true
		time_since_quantum_blink = 0.0
		self.modulate.r /= 2
		return true
	return false

#func _on_area_2d_area_entered(other):
	#if other.get_parent() is Bullet and other.get_parent().is_in_group("enemy_bullets") and other.name == "Collision Box":
		#other.get_parent().queue_free()
		#self.take_damage(5)
