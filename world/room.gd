class_name Room
extends Node2D

const NORMAL_ROOM: int = 1
const BOSS_ROOM: int = 2
const LOOT_ROOM: int = 3
const STARTING_ROOM: int = 4

static var room_scene: PackedScene = load("res://world/room.tscn")

@onready var color_rect: ColorRect = $ColorRect
@onready var door_container: Node2D = $"Door Container"

var room_type: int
var room_connection_locations: Array[Array]
var rect: Rect2
var door_points: PackedVector2Array

var enemies: Dictionary = {}

static func new_room(width: int, height: int, x_pos: int, y_pos: int, level: int) -> Room:
	var room: Room = room_scene.instantiate()
	room.rect = Rect2(x_pos, y_pos, width, height)
	room.room_type = NORMAL_ROOM
	room.room_connection_locations = [[], [], [], []]
	room.position = room.rect.position
	return room

func setup_room() -> void:
	self.position = self.rect.position
	self.color_rect.size = self.rect.size
	self.set_color_from_type()
	self.color_rect.visible = true
	self.create_walls()

func create_walls() -> void:
	var points: PackedVector2Array = []
	self.door_points = PackedVector2Array()
	
	points.append(Vector2.ZERO)
	for hallway: Hallway in self.room_connection_locations[Hallway.UP]:
		if self == hallway.a:
			points.append_array([Vector2(hallway._get_left_points()[0].x - self.rect.position.x, 0), Vector2(hallway._get_right_points()[0].x - self.rect.position.x, 0)])
			door_points.append_array([Vector2(hallway._get_left_points()[0].x - self.rect.position.x, 0), Vector2(hallway._get_right_points()[0].x - self.rect.position.x, 0)])
		else:
			points.append_array([Vector2(hallway._get_right_points()[-1].x - self.rect.position.x, 0), Vector2(hallway._get_left_points()[-1].x - self.rect.position.x, 0)])
			door_points.append_array([Vector2(hallway._get_right_points()[-1].x - self.rect.position.x, 0), Vector2(hallway._get_left_points()[-1].x - self.rect.position.x, 0)])
	points.append(Vector2(self.rect.size.x, 0))
	points.append(Vector2(self.rect.size.x, 0))
	for hallway: Hallway in self.room_connection_locations[Hallway.RIGHT]:
		if self == hallway.a:
			points.append_array([Vector2(self.rect.size.x, hallway._get_left_points()[0].y - self.rect.position.y), Vector2(self.rect.size.x, hallway._get_right_points()[0].y - self.rect.position.y)])
			door_points.append_array([Vector2(self.rect.size.x, hallway._get_left_points()[0].y - self.rect.position.y), Vector2(self.rect.size.x, hallway._get_right_points()[0].y - self.rect.position.y)])
		else:
			points.append_array([Vector2(self.rect.size.x, hallway._get_right_points()[-1].y - self.rect.position.y), Vector2(self.rect.size.x, hallway._get_left_points()[-1].y - self.rect.position.y)])
			door_points.append_array([Vector2(self.rect.size.x, hallway._get_right_points()[-1].y - self.rect.position.y), Vector2(self.rect.size.x, hallway._get_left_points()[-1].y - self.rect.position.y)])
	points.append(self.rect.size)
	points.append(self.rect.size)
	for hallway: Hallway in self.room_connection_locations[Hallway.DOWN]:
		if self == hallway.a:
			points.append_array([Vector2(hallway._get_left_points()[0].x - self.rect.position.x, self.rect.size.y), Vector2(hallway._get_right_points()[0].x - self.rect.position.x, self.rect.size.y)])
			door_points.append_array([Vector2(hallway._get_left_points()[0].x - self.rect.position.x, self.rect.size.y), Vector2(hallway._get_right_points()[0].x - self.rect.position.x, self.rect.size.y)])
		else:
			points.append_array([Vector2(hallway._get_right_points()[-1].x - self.rect.position.x, self.rect.size.y), Vector2(hallway._get_left_points()[-1].x - self.rect.position.x, self.rect.size.y)])
			door_points.append_array([Vector2(hallway._get_right_points()[-1].x - self.rect.position.x, self.rect.size.y), Vector2(hallway._get_left_points()[-1].x - self.rect.position.x, self.rect.size.y)])
	points.append(Vector2(0, self.rect.size.y))
	points.append(Vector2(0, self.rect.size.y))
	for hallway: Hallway in self.room_connection_locations[Hallway.LEFT]:
		if self == hallway.a:
			points.append_array([Vector2(0, hallway._get_left_points()[0].y - self.rect.position.y), Vector2(0, hallway._get_right_points()[0].y - self.rect.position.y)])
			door_points.append_array([Vector2(0, hallway._get_left_points()[0].y - self.rect.position.y), Vector2(0, hallway._get_right_points()[0].y - self.rect.position.y)])
		else:
			points.append_array([Vector2(0, hallway._get_right_points()[-1].y - self.rect.position.y), Vector2(0, hallway._get_left_points()[-1].y - self.rect.position.y)])
			door_points.append_array([Vector2(0, hallway._get_right_points()[-1].y - self.rect.position.y), Vector2(0, hallway._get_left_points()[-1].y - self.rect.position.y)])
	points.append(Vector2.ZERO)
	
	for i in range(0, len(points), 2):
		var polygon: PackedVector2Array = PackedVector2Array([points[i], points[i + 1]])
		var static_body: StaticBody2D = StaticBody2D.new()
		static_body.set_collision_mask_value(4, true)
		var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
		collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		collision_polygon.polygon = polygon
		static_body.add_child(collision_polygon)
		var line: Line2D = Line2D.new()
		line.width = 25
		line.z_index = 6
		line.default_color = Color.GRAY
		line.points = polygon
		var occluder: LightOccluder2D = LightOccluder2D.new()
		occluder.occluder = OccluderPolygon2D.new()
		occluder.occluder.closed = false
		occluder.occluder.polygon = polygon
		self.add_child(static_body)
		self.add_child(line)
		self.add_child(occluder)
	
	for i in range(0, len(self.door_points), 2):
		var polygon: PackedVector2Array = PackedVector2Array([self.door_points[i], self.door_points[i + 1]])
		var static_body: StaticBody2D = StaticBody2D.new()
		static_body.set_collision_mask_value(4, true)
		static_body.set_collision_layer_value(1, false)
		static_body.set_collision_layer_value(6, true)
		var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
		collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		collision_polygon.polygon = polygon
		static_body.add_child(collision_polygon)
		var line: Line2D = Line2D.new()
		line.width = 25
		line.z_index = 6
		line.default_color = Color.GRAY
		line.points = polygon
		var occluder: LightOccluder2D = LightOccluder2D.new()
		occluder.occluder = OccluderPolygon2D.new()
		occluder.occluder.closed = false
		occluder.occluder.polygon = polygon
		occluder.visible = false
		self.door_container.add_child(static_body)
		self.door_container.add_child(line)
		self.door_container.add_child(occluder)
		var area: Area2D = Area2D.new()
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		area.position = (polygon[0] + polygon[1]) / 2
		if polygon[0].y - polygon[1].y == 0: # door is horizontal
			collision_shape.shape = RectangleShape2D.new()
			collision_shape.shape.size = Vector2(abs(polygon[1].x - polygon[0].x), 25)
		else:
			collision_shape.shape = RectangleShape2D.new()
			collision_shape.shape.size = Vector2(25, abs(polygon[1].y - polygon[0].y))
		area.add_child(collision_shape)
		area.set_collision_mask_value(1, false)
		area.set_collision_mask_value(3, true)
		area.area_exited.connect(door_area_exited)
		self.add_child(area)

func door_area_exited(area: Area2D) -> void:
	if self.rect.has_point(area.get_parent().position):
		area.get_parent().room = self
		if self.enemies:
			self.door_container.visible = true
			for child in self.door_container.get_children():
				if child is StaticBody2D:
					child.set_collision_layer_value(1, true)
				elif child is LightOccluder2D:
					child.visible = true
	else:
		self.door_container.visible = false
		for child in self.door_container.get_children():
			if child is StaticBody2D:
				child.set_collision_layer_value(1, false)
			elif child is LightOccluder2D:
				child.visible = false

func set_color_from_type() -> void:
	match self.room_type:
		NORMAL_ROOM:
			color_rect.color = Color.DIM_GRAY
		BOSS_ROOM:
			color_rect.color = Color.RED
		STARTING_ROOM:
			color_rect.color = Color.BLUE

func enemy_defeated() -> void:
	if len(enemies) == 1:
		for child in self.door_container.get_children():
			self.door_container.remove_child(child)
		self.door_container.visible = false
