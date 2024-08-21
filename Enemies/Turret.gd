class_name Turret
extends Enemy

signal enemy_defeated

@onready var turret_face: AnimatedSprite2D = $Face
@onready var search_area: Area2D = $"Face/Search Area"
@onready var collision_box: Area2D = $"Collision Box"
@onready var bullet_spawn_locations: Line2D = $"Face/Bullet Spawn Locations"
@onready var health_bar: Line2D = $"Health Bar"
@onready var sentry_turn: AudioStreamPlayer2D = $sentry_turn
@onready var sentry_shoot: AudioStreamPlayer2D = $sentry_shoot
@onready var sentry_siren: AudioStreamPlayer2D = $sentry_siren
@onready var shape: CollisionShape2D = $CollisionShape2D2
@onready var shape_cast: ShapeCast2D = $Face/ShapeCast2D
@onready var light: PointLight2D = $"Face/Cone Light2"
@onready var siren1: AnimatedSprite2D = $"Siren Container/Siren 1"
@onready var siren_container: Node2D = $"Siren Container"
@onready var siren_lights_container: Node2D = $"Siren Lights Container"
@onready var predictor_lights_container: Node2D = $"Predictor Lights Container"
@onready var slow_timer: Timer = $"Slow Timer"
@onready var rotation_timer: Timer = $"Rotation Timer"

const COLLECTABLE_ITEM: PackedScene = preload("res://Collectables/collectable.tscn")
const BULLET_SCENE: PackedScene = preload("res://bullet.tscn")

const LIGHT_MODULE: int = 0
const INFRARED_LIGHT_MODULE: int = 1
const SIREN_MODULE: int = 2
const PREDICTOR_MODULE: int = 3

const LIGHT_MODULE_CHANCE: float = 0.5
const INFRARED_LIGHT_MODULE_CHANCE: float = 0.25
const SIREN_MODULE_CHANCE: float = 0.2
const PREDICTOR_MODULE_CHANCE: float = 0.1

const MAX_ROTATION_SPEED: float = PI * 2/3

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

var HEALTH_BAR_SIZE: float

var health: int = 100
var speed: float
var target: Player
var rotation_speed: float = self.MAX_ROTATION_SPEED
var current_rotation: float
var fired_this_animation: bool = false
var alert: bool = false
var active_modules: Array[bool] = [false, false, false, false]

var run: bool = true
var room: Room

func _ready():
	turret_face.rotation = 0.0 + [0, PI/2, PI, PI * 3/2].pick_random()
	current_rotation = turret_face.rotation
	HEALTH_BAR_SIZE = (health_bar.points[1] - health_bar.points[0]).length()
	shape_cast.add_exception(self)
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if rng.randf() < LIGHT_MODULE_CHANCE:
		active_modules[LIGHT_MODULE] = true
	if rng.randf() < INFRARED_LIGHT_MODULE_CHANCE:
		active_modules[INFRARED_LIGHT_MODULE] = true
	if rng.randf() < SIREN_MODULE_CHANCE:
		active_modules[SIREN_MODULE] = true
	if rng.randf() < PREDICTOR_MODULE_CHANCE:
		active_modules[PREDICTOR_MODULE] = true
	
	if active_modules[LIGHT_MODULE]:
		light.show()
	if active_modules[INFRARED_LIGHT_MODULE]:
		light.show()
		light.color = Color(1, 0, 0)
	if active_modules[SIREN_MODULE]:
		siren_container.visible = true
		siren_lights_container.visible = true
	if active_modules[PREDICTOR_MODULE]:
		predictor_lights_container.visible = true
	
	enemy_defeated.connect(room.enemy_defeated)
	self.add_to_group("robots")
	self.add_to_group("enemies")

func _on_search_area_area_entered(area: Area2D) -> void:
	if run and turret_face.speed_scale != 0 and (area.get_parent().invisibility_timer.is_stopped() or active_modules[INFRARED_LIGHT_MODULE]) and area.get_parent().room == self.room:
		if not alert:
			if active_modules[SIREN_MODULE]:
				sentry_siren.play()
				for enemy: Enemy in self.room.enemies:
					enemy.alert_enemy()
				for siren_sprite: AnimatedSprite2D in siren_container.get_children():
					siren_sprite.play("alert")
			alert = true
			rotation_timer.stop()
		var query = PhysicsRayQueryParameters2D.create(self.position + self.room.rect.position, area.get_parent().position)
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		if result and result.collider is Player:
			target = area.get_parent()
		turret_face.play("firing")

func _on_search_area_area_exited(area) -> void:
	if not active_modules[self.PREDICTOR_MODULE]:
		self.target = null
		self.turret_face.play("idle")

func _physics_process(delta) -> void:
	if run and turret_face.speed_scale != 0:
		var target_rotation: float
		if target != null:
			if active_modules[self.PREDICTOR_MODULE]:
				target_rotation = self.predict_firing_direction(self.position + self.room.rect.position, target.position, target.velocity)
			else:
				target_rotation = (self.position + self.room.rect.position).angle_to_point(target.position)
			turret_face.rotation = lerp_angle(turret_face.rotation, target_rotation, 0.05)
		
		elif alert:
			target_rotation = turret_face.rotation + 0.075
			turret_face.rotation = lerp_angle(turret_face.rotation, target_rotation, 0.05)
			
		else:
			turret_face.rotation = lerp_angle(turret_face.rotation, current_rotation, 0.005)
		
func predict_firing_direction(starting_position: Vector2, target_position: Vector2, target_vector: Vector2) -> float:
	var est_pos: Vector2 = target_position
	var est_dist: float
	var est_time: float
	for i in range(2):
		est_dist = starting_position.distance_to(est_pos)
		est_time = est_dist / Bullet.SPEED
		var old_est_pos = est_pos
		est_pos = target_position + (target_vector * est_time)
		if old_est_pos.distance_to(est_pos) < 50:
			break
	return starting_position.angle_to_point(est_pos)

func damage(damage: int) -> void:
	self.health -= damage
	if self.health <= 0:
		self.room.enemies.erase(self)
		self.drop_loot()
		enemy_defeated.emit()
		self.queue_free()
	
	var node: Line2D = Line2D.new()
	node.points = PackedVector2Array([health_bar.points[1], health_bar.points[0] + Vector2(health / 100.0 * HEALTH_BAR_SIZE, 0)])
	node.width = 2
	node.default_color = Color.RED
	node.z_index = 2
	self.add_child(node)
	if not alert and rotation_speed != 0:
		if active_modules[SIREN_MODULE]:
			sentry_siren.play()
			for enemy: Enemy in room.enemies:
				enemy.alert_enemy()
			for siren_sprite in siren_container.get_children():
				siren_sprite.play("alert")
		alert = true
		rotation_timer.stop()

func slow() -> void:
	self.rotation_speed = min(self.rotation_speed, self.MAX_ROTATION_SPEED / 2)
	self.turret_face.speed_scale = min(self.turret_face.speed_scale, 0.6)
	self.modulate.r = 0.5
	slow_timer.start()

func freeze() -> void:
	rotation_speed = 0
	turret_face.speed_scale = 0
	self.modulate.r = 0.5
	target = null
	turret_face.play("idle")
	slow_timer.start()

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
	return self.shape.shape.size * self.scale

func alert_enemy() -> void:
	alert = true
	rotation_timer.stop()
	if active_modules[SIREN_MODULE]:
		for siren in siren_container.get_children():
			siren.play("alert")
	
func _on_siren_1_frame_changed() -> void:
	if siren1.animation == "alert":
		for light in siren_lights_container.get_children():
			light.enabled = (siren1.frame == 1)

func _on_face_frame_changed() -> void:
	if turret_face.animation == "firing":
		if turret_face.frame == 7 and not fired_this_animation:
			shape_cast.force_shapecast_update()
			if shape_cast.collision_result and !shape_cast.collision_result[0].collider is Player:
				turret_face.frame = 6
				return
				
			fired_this_animation = true
			for location: Vector2 in bullet_spawn_locations.points:
				var bullet: Bullet = BULLET_SCENE.instantiate()
				add_sibling(bullet)
				await bullet.is_node_ready()
				bullet.set_bullet_type(0)
				bullet.set_collision_mask_value(2, true)
				bullet.set_collision_mask_value(3, true)
				bullet.position = self.position + location.rotated(turret_face.rotation) * self.scale
				bullet.rotation = turret_face.rotation
				bullet.z_index = 9
				bullet.add_to_group("enemy_bullets")
				bullet.add_to_group("player_bullets")
				bullet.add_collision_exception_with(self)
			sentry_shoot.play()
			
		elif turret_face.frame == 0:
			fired_this_animation = false
	else:
		if turret_face.frame == 0:
			#sentry_turn.play()
			pass

func _on_slow_timer_timeout():
	rotation_speed = self.MAX_ROTATION_SPEED
	turret_face.speed_scale = 1
	self.modulate.r = 1
	if not alert:
		if active_modules[SIREN_MODULE]:
			sentry_siren.play()
			for enemy: Enemy in room.enemies:
				enemy.alert_enemy()
			for siren_sprite in siren_container.get_children():
				siren_sprite.play("alert")
		alert = true
		rotation_timer.stop()
	self.recheck_search_area()

func _on_rotation_timer_timeout():
	self.current_rotation += PI/2

func recheck_search_area() -> void:
	target = null
	self.turret_face.play("idle")
	for area: Area2D in self.search_area.get_overlapping_areas():
		self._on_search_area_area_entered(area)
