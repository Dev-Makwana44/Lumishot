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
var sprite: Sprite2D
var collision_box: Area2D
var explosion_radius: Area2D

func _ready():
	self.sprite = Sprite2D.new()
	self.add_child(self.sprite)
	self.bullet_type = 0
	self.sprite.texture = self.bullet_textures[self.bullet_type].item_texture
	self.rotation = 0
	self.collision_box = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = Vector2(24, 15)
	self.collision_box.add_child(collision_shape)
	self.collision_box.area_entered.connect(collision)
	self.add_child(self.collision_box)
	self.collision_box.name = "Collision Box"
	
	self.explosion_radius = Area2D.new()
	var explosion_shape: CollisionShape2D = CollisionShape2D.new()
	explosion_shape.shape = CircleShape2D.new()
	explosion_shape.shape.radius = 150
	self.explosion_radius.add_child(explosion_shape)
	self.add_child(self.explosion_radius)
	self.explosion_radius.name = "Explosion Radius"

func _physics_process(delta):
	self.velocity = Vector2(SPEED * cos(self.rotation), SPEED * sin(self.rotation))
	self.move_and_slide()

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
		self.queue_free()
		
