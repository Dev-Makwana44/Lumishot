class_name Bullet
extends CharacterBody2D

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
#@onready var collision_box: Area2D = $"Collision Box"
@onready var explosion_radius: Area2D = $"Explosion Radius"

func _physics_process(delta):
	self.velocity = Vector2(SPEED * cos(self.rotation), SPEED * sin(self.rotation))
	#self.move_and_collide(self.velocity * delta)
	
	#if self.move_and_slide():
		#self.queue_free()
	print(self.move_and_collide(self.velocity * delta))
	#if self.move_and_collide(self.velocity):
		#self.queue_free()

func set_bullet_type(type: int):
	self.bullet_type = type
	self.sprite.texture = self.bullet_textures[self.bullet_type].item_texture

func collision(area: Area2D):
	var parent = area.get_parent()
	if parent is Enemy and self.is_in_group("player_bullets"):
		if bullet_type == 0:
			parent.damage(10)
		elif bullet_type == 1:
			for enemy in explosion_radius.get_overlapping_areas():
				if enemy.get_parent() is Enemy:
					enemy.get_parent().damage(10)
		elif bullet_type == 2:
			parent.damage(10)
			parent.slow()
		elif bullet_type == 3:
			if parent.is_in_group("robots"):
				parent.damage(5)
			else:
				parent.damage(20)
		elif bullet_type == 4:
			if parent.is_in_group("robots"):
				parent.damage(20)
			else:
				parent.damage(5)
		print(1)
		self.queue_free()
		
