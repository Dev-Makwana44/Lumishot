class_name Grenade
extends Node2D

@onready var light: PointLight2D = %PointLight2D

const SPEED: int = 1000

var grenade_textures: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Grenade.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/CryoGrenade.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/FlareGrenade.tres") as ItemData,
}

var grenade_type: int
var sprite: Sprite2D
var angle: float
var velocity: Vector2

func _ready():
	self.sprite = Sprite2D.new()
	self.add_child(self.sprite)
	self.grenade_type = 0
	self.sprite.texture = self.grenade_textures[self.grenade_type].item_texture

func _physics_process(delta):
	self.velocity = Vector2(SPEED * cos(self.angle) * delta, SPEED * sin(self.angle) * delta)
	if atan2(self.velocity.y, self.velocity.x) != angle:
		self.explode()
		self.queue_free()
	self.position += self.velocity

func set_grenade_type(type: int) -> void:
	self.grenade_type = type
	self.sprite.texture = self.grenade_textures[self.grenade_type].item_texture
	if type == 2:
		light.show()

func explode() -> void:
	#if grenade_type == 0:
	print("explode")
