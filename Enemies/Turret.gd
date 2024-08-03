class_name Turret
extends Enemy

@onready var turret_face: AnimatedSprite2D = $Face
@onready var search_area: Area2D = $"Face/Search Area"
@onready var collision_box: Area2D = $"Collision Box"
@onready var bullet_spawn_locations: Line2D = $"Face/Bullet Spawn Locations"
@onready var health_bar: Line2D = $"Health Bar"
@onready var sentry_turn = $sentry_turn
@onready var shape: CollisionShape2D = $CollisionShape2D2

const COLLECTABLE_ITEM: PackedScene = preload("res://Collectables/collectable.tscn")
const BULLET_SCENE: PackedScene = preload("res://bullet.tscn")

var loot_items: Array[ItemData] = [
	load("res://Resources/Items/CraftingItems/Bioluminescent_Bacteria.tres"),
	load("res://Resources/Items/CraftingItems/Camouflage_Cell.tres"),
	load("res://Resources/Items/CraftingItems/Combustion_Node.tres"),
	load("res://Resources/Items/CraftingItems/Cryo_Cell.tres"),
	load("res://Resources/Items/CraftingItems/Electronics.tres"),
	load("res://Resources/Items/CraftingItems/Heavy_Plate.tres"),
	load("res://Resources/Items/CraftingItems/Iron.tres"),
	load("res://Resources/Items/CraftingItems/Mutated_Blood.tres"),
	load("res://Resources/Items/CraftingItems/Rabbit_Foot.tres")
]

const TIME_BETWEEN_ROTATIONS: float = 2.5
const SLOWNESS_DURATION: float = 5.0
var HEALTH_BAR_SIZE: float

var health: int = 100
var speed: float
var target_location
var rotation_speed: float = PI * 2/3
var time_since_last_rotation: float = 0.0
var current_rotation: float = 0.0
var fired_this_animation: bool = false

var time_since_slowed: float = SLOWNESS_DURATION
var slowed: bool = false

var run: bool = false
var room: Room

func _ready():
	turret_face.play("idle")
	turret_face.rotation = 0.0 + [0, PI/2, PI, PI * 3/2].pick_random()
	current_rotation = turret_face.rotation
	HEALTH_BAR_SIZE = (health_bar.points[1] - health_bar.points[0]).length()

func _process(_delta):
	if run:
		target_location = null
		for area in search_area.get_overlapping_areas():
			if area.get_parent() is Player and !area.get_parent().invisible and area.get_parent().room != null and area.get_parent().room == self.room:
				target_location = area.get_parent().position
		if target_location == null:
			turret_face.play("idle")
		else:
			turret_face.play("firing")

func _physics_process(delta):
	if run:
		if slowed:
			time_since_slowed += delta
			if time_since_slowed >= SLOWNESS_DURATION:
				slowed = false
				rotation_speed = PI * 2/3
				turret_face.speed_scale = 1
				self.modulate.r = 1
		
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
		sentry_turn.play()

func _on_face_frame_changed():
	if turret_face.frame == 7 and not fired_this_animation:
		fired_this_animation = true
		for location: Vector2 in bullet_spawn_locations.points:
			var bullet: Bullet = BULLET_SCENE.instantiate()
			add_sibling(bullet)
			await bullet.ready
			bullet.position = self.position + location.rotated(turret_face.rotation) * self.scale
			bullet.rotation = turret_face.rotation
			bullet.z_index = 10
			bullet.add_to_group("enemy_bullets")
	elif turret_face.frame == 0:
		fired_this_animation = false

func damage(damage: int):
	self.health -= damage
	#health_bar.add_point(health_bar.points[-1] + Vector2(damage / 100 * HEALTH_BAR_SIZE, 0))
	#print(health_bar.points[-1])
	var node: Line2D = Line2D.new()
	node.points = PackedVector2Array([health_bar.points[1], health_bar.points[0] + Vector2(health / 100.0 * HEALTH_BAR_SIZE, 0)])
	node.width = 2
	node.default_color = Color.RED
	node.z_index = 2
	self.add_child(node)

func slow() -> void:
	time_since_slowed = 0.0
	rotation_speed /= 2
	turret_face.speed_scale /= 2
	self.modulate.r /= 2

func freeze() -> void:
	time_since_slowed = 0.0
	rotation_speed = 0
	turret_face.speed_scale = 0
	self.modulate.r /= 2

func drop_loot() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for i in rng.randi_range(3, 6):
		var pos = self.position + Vector2(rng.randi_range(-15, 15), rng.randi_range(-15, 15))
		var item: Collectable = COLLECTABLE_ITEM.instantiate()
		add_sibling(item)
		item.z_index = 8
		item.position = pos
		var item_data: ItemData = loot_items.pick_random()
		item._set_collectable_data(item_data)
		item.add_to_group("dungeon")

func get_size() -> Vector2:
	return self.shape.shape.size
