extends Node2D

class Room extends Node2D:
	var size: Vector2
	var mobs: Array
	
	func _init(width: int, height: int, x_pos: int, y_pos: int):
		self.size = Vector2(width, height)
		self.position = Vector2(x_pos, y_pos)
		self.mobs = []
		
	func _get_center():
		return Vector2(self.position.x + (0.5 * self.size.x), self.position.y + (0.5 * self.size.y))
		
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

const NUMBER_OF_ROOMS_GENERATED: int = 50
const SPACE_BETWEEN_ROOMS: int = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	var starting_time: int = Time.get_ticks_msec()
	_generate_dungeon()
	print(Time.get_ticks_msec() - starting_time)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _generate_dungeon() -> void:
	var rooms = []
	
	# Create Rooms
	
	var rng = RandomNumberGenerator.new()
	for i in range(NUMBER_OF_ROOMS_GENERATED):
		var width : int = rng.randi_range(200, 1000)
		var height : int = rng.randi_range(200, 1000)
		var x_pos: int = rng.randi_range(-100, 100)
		var y_pos: int = rng.randi_range(-100, 100)
		rooms.append(Room.new(width, height, x_pos, y_pos))
	
	# Separate Rooms
	
	var separation_speed: int = 100
	var rooms_moved: bool = true
	while rooms_moved:
		rooms_moved = false
		for room_index in range(len(rooms)):
			var separation_vec: Vector2
			for other_room_index in range(len(rooms)):
				#if room_index != other_room_index and (rooms[other_room_index]._get_center() - rooms[room_index]._get_center()).length() < 500:
				#if room_index != other_room_index and Rect2(rooms[room_index].position, rooms[room_index].size).intersects(Rect2(rooms[other_room_index].position, rooms[other_room_index].size)):
				if room_index != other_room_index and rooms[room_index]._is_too_close(rooms[other_room_index]):
					separation_vec = separation_vec - (rooms[other_room_index]._get_center() - rooms[room_index]._get_center())
					rooms_moved = true
			var room_velocity = rooms[room_index].transform.y * -1 * separation_speed + separation_vec
			rooms[room_index].position += room_velocity * 0.3
	
	_create_room_nodes(rooms)

func _create_room_nodes(rooms: Array) -> void:
	var number_of_main_rooms: int = int(len(rooms) * 0.3)
	rooms.sort_custom(_room_comparison)
	for room in rooms:
		var room_node = ColorRect.new()
		room_node.size.x = room.size.x
		room_node.size.y = room.size.y
		room_node.position.x = room.position.x
		room_node.position.y = room.position.y
		if number_of_main_rooms > 0:
			room_node.color = Color(0, 255, 0)
		number_of_main_rooms -= 1
		add_child(room_node)

func _room_comparison(a: Room, b: Room):
	return a.size.x * a.size.y > b.size.x * b.size.y
