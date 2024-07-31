class_name Room
extends Area2D

const NORMAL_ROOM: int = 1
const BOSS_ROOM: int = 2
const LOOT_ROOM: int = 3
const STARTING_ROOM: int = 4
const SPACE_BETWEEN_ROOMS: int = 250

var size: Vector2
var room_type: int
var room_connection_locations: Array[Hallway]

var enemies: Dictionary = {}

func _init(width: int, height: int, x_pos: int, y_pos: int):
	self.size = Vector2(width, height)
	self.position = Vector2(x_pos, y_pos)
	self.room_type = NORMAL_ROOM
	var collision_box: CollisionShape2D = CollisionShape2D.new()
	collision_box.shape = RectangleShape2D.new()
	collision_box.shape.size = self.size
	self.add_child(collision_box)
	self.room_connection_locations = [null, null, null, null]
	
func _get_center():
	return Vector2(self.position.x + (0.5 * self.size.x), self.position.y + (0.5 * self.size.y))

func _point_inside(point: Vector2) -> bool:
	return point.x > self.position.x and point.x < self.position.x + self.size.x and point.y > self.position.y and point.y < self.position.y + self.size.y

func _is_too_close(other: Room):
	if Rect2(self.position, self.size).intersects(Rect2(other.position, other.size)):
		return true
	var left: bool = other.position.x + other.size.x < self.position.x
	var right: bool = self.position.x + self.size.x < other.position.x
	var bottom: bool = other.position.y + other.size.y < self.position.y
	var top: bool = self.position.y + self.size.y < other.position.y
	var dist: float
	if top and left:
		dist = (Vector2(self.position.x, self.position.y + self.size.y) - Vector2(other.position.x + other.size.x, other.position.y)).length()
	elif left and bottom:
		dist = (Vector2(self.position.x, self.position.y) - Vector2(other.position.x + other.size.x, other.position.y + other.size.y)).length()
	elif right and bottom:
		dist = (Vector2(self.position.x + self.size.x, self.position.y) - Vector2(other.position.x, other.position.y + other.size.y)).length()
	elif right and top:
		dist = (Vector2(self.position.x + self.size.x, self.position.y + self.size.y) - Vector2(other.position.x, other.position.y)).length()
	elif left:
		dist = self.position.x - (other.position.x + other.size.x)
	elif right:
		dist = other.position.x - (self.position.x + self.size.x)
	elif bottom:
		dist = self.position.y - (other.position.y + other.size.y)
	elif top:
		dist = other.position.y - (self.position.y + self.size.y)
	else:
		print("ERROR: Room._is_too_close()")
	return dist < SPACE_BETWEEN_ROOMS
