class_name Room
extends Area2D

const NORMAL_ROOM: int = 1
const BOSS_ROOM: int = 2
const LOOT_ROOM: int = 3
const STARTING_ROOM: int = 4
var SPACE_BETWEEN_ROOMS: int = 250

var room_type: int
var room_connection_locations: Array[Hallway]
var rect: Rect2

var enemies: Dictionary = {}

func _init(width: int, height: int, x_pos: int, y_pos: int, level: int):
	self.rect = Rect2(x_pos, y_pos, width, height)
	self.room_type = NORMAL_ROOM
	self.room_connection_locations = [null, null, null, null]
	SPACE_BETWEEN_ROOMS += 50 * level

func is_too_close(other: Room) -> bool:
	if self.rect.intersects(other.rect):
		return true
	return (self.rect.get_center() - other.rect.get_center()).length() < (self.rect.get_center() - self.rect.position).length() + (other.rect.get_center() - other.rect.position).length()

func _is_too_close(other: Room):
	if self.rect.intersects(other.rect):
		return true
	var left: bool = other.rect.position.x + other.rect.size.x < self.rect.position.x
	var right: bool = self.rect.position.x + self.rect.size.x < other.rect.position.x
	var bottom: bool = other.rect.position.y + other.rect.size.y < self.rect.position.y
	var top: bool = self.rect.position.y + self.rect.size.y < other.rect.position.y
	var dist: float
	if top and left:
		dist = (Vector2(self.rect.position.x, self.rect.position.y + self.rect.size.y) - Vector2(other.rect.position.x + other.rect.size.x, other.rect.position.y)).length()
	elif left and bottom:
		dist = (Vector2(self.rect.position.x, self.rect.position.y) - Vector2(other.rect.position.x + other.rect.size.x, other.rect.position.y + other.rect.size.y)).length()
	elif right and bottom:
		dist = (Vector2(self.rect.position.x + self.rect.size.x, self.rect.position.y) - Vector2(other.rect.position.x, other.rect.position.y + other.rect.size.y)).length()
	elif right and top:
		dist = (Vector2(self.rect.position.x + self.rect.size.x, self.rect.position.y + self.rect.size.y) - Vector2(other.rect.position.x, other.rect.position.y)).length()
	elif left:
		dist = self.rect.position.x - (other.rect.position.x + other.rect.size.x)
	elif right:
		dist = other.rect.position.x - (self.rect.position.x + self.rect.size.x)
	elif bottom:
		dist = self.rect.position.y - (other.rect.position.y + other.rect.size.y)
	elif top:
		dist = other.rect.position.y - (self.rect.position.y + self.rect.size.y)
	else:
		print("ERROR: Room._is_too_close()")
		#return true
	return dist < SPACE_BETWEEN_ROOMS
