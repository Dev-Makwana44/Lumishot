class_name Grenade
extends Node2D

#@onready var light: PointLight2D = %PointLight2D

const SPEED: int = 1000
const FLARE_DECAY: float = 0.0003

var grenade_textures: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Grenade.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/CryoGrenade.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/FlareGrenade.tres") as ItemData,
}

var grenade_type: int
var sprite: Sprite2D
var light: PointLight2D
var area: Area2D
var angle: float
var velocity: Vector2
var distance_from_target: float = 500.0
var exploded: bool = false

func _init(type: int, angle: float):
	self.grenade_type = type
	self.angle = angle

func _ready():
	self.sprite = Sprite2D.new()
	self.add_child(self.sprite)
	self.sprite.texture = self.grenade_textures[self.grenade_type].item_texture
	self.sprite.material = CanvasItemMaterial.new()
	self.sprite.material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	self.area = Area2D.new()
	self.add_child(area)
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 200
	self.area.add_child(shape)
	
	if self.grenade_type == 2:
		self.light = PointLight2D.new()
		self.light.texture = load("res://Resources/Lighting/circle.png") as CompressedTexture2D
		self.light.texture_scale = 5
		self.add_child(self.light)

func _physics_process(delta):
	if not exploded:
		self.velocity = Vector2(SPEED * cos(self.angle) * delta, SPEED * sin(self.angle) * delta)
		self.rotation += delta
		self.distance_from_target -= self.velocity.length()
		if self.distance_from_target <= 0:
			if self.grenade_type == 2:
				self.exploded = true
			else:
				self.explode()
				self.queue_free()
		self.position += self.velocity
		
	if self.grenade_type == 2 and self.light.energy > 0:
		self.light.energy -= FLARE_DECAY

func explode() -> void:
	if grenade_type == 0:
		for enemy in self.area.get_overlapping_areas():
			if enemy.get_parent() is Enemy:
				enemy.get_parent().damage(50)
	elif grenade_type == 1:
		for enemy in self.area.get_overlapping_areas():
			if enemy.get_parent() is Enemy:
				enemy.get_parent().damage(25)
				enemy.get_parent().freeze()
