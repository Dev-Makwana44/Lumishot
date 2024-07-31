class_name Bullet
extends CharacterBody2D

const SPEED: int = 1000

var bullet_textures: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/ExplosiveBullet.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/CryoBullet.tres") as ItemData,
	3: load("res://Resources/Items/CraftableItems/NeurotoxicBullet.tres") as ItemData,
	4: load("res://Resources/Items/CraftableItems/ExplosiveBullet.tres") as ItemData
}

var bullet_type: int
var sprite: Sprite2D

func _ready():
	self.sprite = Sprite2D.new()
	self.add_child(self.sprite)
	self.bullet_type = 0
	self.sprite.texture = self.bullet_textures[self.bullet_type].item_texture
	self.rotation = 0

func _physics_process(delta):
	self.velocity = Vector2(SPEED * cos(self.rotation), SPEED * sin(self.rotation))
	self.move_and_slide()

func set_bullet_type(type: int):
	self.bullet_type = type
	self.sprite.texture = self.bullet_textures[self.bullet_type].item_texture