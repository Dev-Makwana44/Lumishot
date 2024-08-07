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
var room_connection_locations: Array[Hallway]
var rect: Rect2


var enemies: Dictionary = {}

#func _init(width: int, height: int, x_pos: int, y_pos: int, level: int):
	#self.rect = Rect2(x_pos, y_pos, width, height)
	#self.room_type = NORMAL_ROOM
	#self.room_connection_locations = [null, null, null, null]
	#self.position = self.rect.position
	#self.size = self.rect.size

static func new_room(width: int, height: int, x_pos: int, y_pos: int, level: int) -> Room:
	var room: Room = room_scene.instantiate()
	room.rect = Rect2(x_pos, y_pos, width, height)
	room.room_type = NORMAL_ROOM
	room.room_connection_locations = [null, null, null, null]
	room.position = room.rect.position
	#room.color_rect.size = room.rect.size
	return room

func setup_room() -> void:
	self.position = self.rect.position
	self.color_rect.size = self.rect.size
	self.set_color_from_type()
	var area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = self.rect.size
	collision_shape.position = self.rect.size / 2
	area.add_child(collision_shape)
	area.set_collision_layer_value(1, false)
	area.set_collision_layer_value(6, true)
	area.set_collision_mask_value(1, false)
	area.set_collision_mask_value(3, true)
	self.add_child(area)
	area.area_entered.connect(_room_entered)
	self.create_walls()
	self.color_rect.visible = true

func create_walls() -> void:
	var collision_polygons: Array[PackedVector2Array] = []
	if self.room_connection_locations[Hallway.UP] == null:
		collision_polygons.append(PackedVector2Array([Vector2.ZERO, Vector2(self.rect.size.x, 0)]))
	else:
		if self == self.room_connection_locations[Hallway.UP].a:
			collision_polygons.append(PackedVector2Array([Vector2.ZERO, Vector2(self.room_connection_locations[Hallway.UP]._get_left_points()[0].x - self.rect.position.x, 0)]))
			collision_polygons.append(PackedVector2Array([Vector2(self.room_connection_locations[Hallway.UP]._get_right_points()[0].x - self.rect.position.x, 0), Vector2(self.rect.size.x, 0)]))
		else:
			collision_polygons.append(PackedVector2Array([Vector2.ZERO, Vector2(self.room_connection_locations[Hallway.UP]._get_right_points()[-1].x - self.rect.position.x, 0)]))
			collision_polygons.append(PackedVector2Array([Vector2(self.room_connection_locations[Hallway.UP]._get_left_points()[-1].x - self.rect.position.x, 0), Vector2(self.rect.size.x, 0)]))
	if self.room_connection_locations[Hallway.RIGHT] == null:
		collision_polygons.append(PackedVector2Array([Vector2(self.rect.size.x, 0), self.rect.size]))
	else:
		if self == self.room_connection_locations[Hallway.RIGHT].a:
			collision_polygons.append(PackedVector2Array([Vector2(self.rect.size.x, 0), Vector2(self.rect.size.x, self.room_connection_locations[Hallway.RIGHT]._get_left_points()[0].y - self.rect.position.y)]))
			collision_polygons.append(PackedVector2Array([Vector2(self.rect.size.x, self.room_connection_locations[Hallway.RIGHT]._get_right_points()[0].y - self.rect.position.y), self.rect.size]))
		else:
			collision_polygons.append(PackedVector2Array([Vector2(self.rect.size.x, 0), Vector2(self.rect.size.x, self.room_connection_locations[Hallway.RIGHT]._get_right_points()[-1].y - self.rect.position.y)]))
			collision_polygons.append(PackedVector2Array([Vector2(self.rect.size.x, self.room_connection_locations[Hallway.RIGHT]._get_left_points()[-1].y - self.rect.position.y), self.rect.size]))
	if self.room_connection_locations[Hallway.DOWN] == null:
		collision_polygons.append(PackedVector2Array([self.rect.size, Vector2(0, self.rect.size.y)]))
	else:
		if self == self.room_connection_locations[Hallway.DOWN].a:
			collision_polygons.append(PackedVector2Array([self.rect.size, Vector2(self.room_connection_locations[Hallway.DOWN]._get_left_points()[0].x - self.rect.position.x, self.rect.size.y)]))
			collision_polygons.append(PackedVector2Array([Vector2(self.room_connection_locations[Hallway.DOWN]._get_right_points()[0].x - self.rect.position.x, self.rect.size.y), Vector2(0, self.rect.size.y)]))
		else:
			collision_polygons.append(PackedVector2Array([self.rect.size, Vector2(self.room_connection_locations[Hallway.DOWN]._get_right_points()[-1].x - self.rect.position.x, self.rect.size.y)]))
			collision_polygons.append(PackedVector2Array([Vector2(self.room_connection_locations[Hallway.DOWN]._get_left_points()[-1].x - self.rect.position.x, self.rect.size.y), Vector2(0, self.rect.size.y)]))
	if self.room_connection_locations[Hallway.LEFT] == null:
		collision_polygons.append(PackedVector2Array([Vector2(0, self.rect.size.y), Vector2.ZERO]))
	else:
		if self == self.room_connection_locations[Hallway.LEFT].a:
			collision_polygons.append(PackedVector2Array([Vector2(0, self.rect.size.y), Vector2(0, self.room_connection_locations[Hallway.LEFT]._get_left_points()[0].y - self.rect.position.y)]))
			collision_polygons.append(PackedVector2Array([Vector2(0, self.room_connection_locations[Hallway.LEFT]._get_right_points()[0].y - self.rect.position.y), Vector2.ZERO]))
		else:
			collision_polygons.append(PackedVector2Array([Vector2(0, self.rect.size.y), Vector2(0, self.room_connection_locations[Hallway.LEFT]._get_right_points()[-1].y - self.rect.position.y)]))
			collision_polygons.append(PackedVector2Array([Vector2(0, self.room_connection_locations[Hallway.LEFT]._get_left_points()[-1].y - self.rect.position.y), Vector2.ZERO]))
	
	for polygon: PackedVector2Array in collision_polygons:
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
		

func _room_entered(area) -> void:
	print("room entered")

func set_color_from_type() -> void:
	match self.room_type:
		NORMAL_ROOM:
			color_rect.color = Color.DIM_GRAY
		BOSS_ROOM:
			color_rect.color = Color.RED
		STARTING_ROOM:
			color_rect.color = Color.BLUE

