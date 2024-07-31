class_name Turret
extends CharacterBody2D

@onready var turret_face: AnimatedSprite2D = %Face
@onready var search_area: Area2D = %"Search Area"
@onready var collision_box: Area2D = %"Collision Box"
@onready var bullet_spawn_locations: Line2D = %"Bullet Spawn Locations"

const TIME_BETWEEN_ROTATIONS: float = 2.5

var health: int = 100
var speed: float
var target_location
var rotation_speed: float = PI * 2/3
var time_since_last_rotation: float = 0.0
var current_rotation: float = 0.0
var fired_this_animation: bool = false

func _ready():
	turret_face.play("idle")
	turret_face.rotation = 0.0 + [0, PI/2, PI, PI * 3/2].pick_random()
	current_rotation = turret_face.rotation

func _process(delta):
	target_location = null
	for area in search_area.get_overlapping_areas():
		if area.get_parent() is Player:
			target_location = area.get_parent().position
	if target_location == null:
		turret_face.play("idle")
	else:
		turret_face.play("firing")

func _physics_process(delta):
	var target_rotation: float
	if target_location != null:
		target_rotation = atan2(target_location.y - self.position.y, target_location.x - self.position.x)
	else:
		time_since_last_rotation += delta
		if time_since_last_rotation >= TIME_BETWEEN_ROTATIONS:
			time_since_last_rotation = 0.0
			current_rotation += PI/2
			if current_rotation >= 2 * PI:
				current_rotation -= 2 * PI
		target_rotation = current_rotation
	var rotation_difference = target_rotation - turret_face.rotation
	if rotation_difference > PI:
		rotation_difference -= 2 * PI
	elif rotation_difference < -PI:
		rotation_difference += 2 * PI
	turret_face.rotation += min(rotation_speed * delta, abs(rotation_difference)) * sign(rotation_difference)


func _on_face_frame_changed():
	if turret_face.frame == 7 and not fired_this_animation:
		fired_this_animation = true
		for location: Vector2 in bullet_spawn_locations.points:
			var bullet: Bullet = Bullet.new()
			bullet.position = self.position + location.rotated(turret_face.rotation) * self.scale
			add_sibling(bullet)
			bullet.rotation = turret_face.rotation
			bullet.z_index = 10
			bullet.add_to_group("enemy_bullets")
	elif turret_face.frame == 0:
		fired_this_animation = false

func damage(damage: int):
	self.health -= damage
