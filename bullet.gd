class_name Bullet
extends CharacterBody2D

static var BULLET_WIDTH: int = 14
const SPEED: int = 1000

var bullet_textures: Dictionary = {
	0: load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData,
	1: load("res://Resources/Items/CraftableItems/ExplosiveBullet.tres") as ItemData,
	2: load("res://Resources/Items/CraftableItems/CryoBullet.tres") as ItemData,
	3: load("res://Resources/Items/CraftableItems/NeurotoxicBullet.tres") as ItemData,
	4: load("res://Resources/Items/CraftableItems/ElectricBullet.tres") as ItemData
}

var bullet_type: int
@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_radius: Area2D = $"Explosion Radius"

func _physics_process(delta):
	self.velocity = Vector2(SPEED * cos(self.rotation), SPEED * sin(self.rotation))
	if self.move_and_slide():
		var collider = self.get_last_slide_collision().get_collider()
		if collider.get_collision_layer_value(1): # collider is a wall
			self.queue_free()
		elif collider.get_collision_layer_value(2): # collider is an enemy
			if self.is_in_group("player_bullets"):
				self.damage(collider, false)
				self.queue_free()
		elif collider.get_collision_layer_value(3): # collider is the player
			if self.is_in_group("enemy_bullets"):
				self.damage(collider, true)
				self.queue_free()
		else:
			print('bullet collided with unknown object')

func set_bullet_type(type: int):
	self.bullet_type = type
	self.sprite.texture = self.bullet_textures[self.bullet_type].item_texture

func damage(collider, collider_is_player: bool) -> void:
	if collider_is_player:
		collider.damage(5)
	else:
		if bullet_type == 0:
			collider.damage(10)
		elif bullet_type == 1:
			for enemy in explosion_radius.get_overlapping_areas():
				if !enemy.get_parent() is Bullet:
					enemy.get_parent().damage(10)
		elif bullet_type == 2:
			collider.damage(10)
			collider.slow()
		elif bullet_type == 3:
			if collider.is_in_group("robots"):
				collider.damage(5)
			else:
				collider.damage(20)
		elif bullet_type == 4:
			if collider.is_in_group("robots"):
				collider.damage(20)
			else:
				collider.damage(5)
