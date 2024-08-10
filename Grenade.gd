class_name Grenade
extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var area: Area2D = $Area2D

const SPEED: int = 1000
const FLARE_DECAY: float = 0.0003
const GRENADE: int = 0
const CRYO_GRENADE: int = 1
const FLARE: int = 2

static var scene = load("res://grenade.tscn") as PackedScene

var grenade_textures: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Grenade.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/CryoGrenade.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/FlareGrenade.tres") as ItemData,
}

var grenade_type: int
var angle: float
var distance_from_target: float = 500.0
var exploded: bool = false

#func _init(type: int, starting_angle: float):
	#
	#self.grenade_type = type
	#self.angle = starting_angle

static func new_grenade(type: int, starting_angle: float):
	var grenade: Grenade = scene.instantiate()
	grenade.grenade_type = type
	grenade.angle = starting_angle
	return grenade

func _ready():
	self.sprite.texture = self.grenade_textures[self.grenade_type].item_texture
	self.velocity = Vector2(SPEED * cos(self.angle), SPEED * sin(self.angle))
	if not self.grenade_type == FLARE:
		self.light.visible = false

var temp: int = 0
func _physics_process(delta):
	temp += 1
	if not exploded:
		self.rotation += delta
		self.distance_from_target -= (self.velocity * delta).length()
		if self.distance_from_target <= 0:
			if self.grenade_type == FLARE:
				self.exploded = true
			else:
				self.explode()
				self.queue_free()
		var vel = self.velocity
		if self.move_and_slide():
			self.velocity = vel.bounce(self.get_last_slide_collision().get_normal())
			print(self.get_last_slide_collision().get_normal())
		
	if self.grenade_type == FLARE and self.light.energy > 0:
		self.light.energy -= FLARE_DECAY
	

func explode() -> void:
	if grenade_type == GRENADE:
		for enemy in self.area.get_overlapping_areas():
			if enemy.get_parent() is Enemy:
				enemy.get_parent().damage(50)
	elif grenade_type == CRYO_GRENADE:
		for enemy in self.area.get_overlapping_areas():
			if enemy.get_parent() is Enemy:
				enemy.get_parent().damage(25)
				enemy.get_parent().freeze()
