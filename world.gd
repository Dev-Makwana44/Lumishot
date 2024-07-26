extends Node2D

const NUMBER_OF_ROOMS_GENERATED: int = 50
#const NUMBER_OF_ROOMS_GENERATED: int = 2
const SPACE_BETWEEN_ROOMS: int = 1000
const PERCENTAGE_OF_MAIN_ROOMS: float = 0.3
#const PERCENTAGE_OF_MAIN_ROOMS: float = 1
const NORMAL_ROOM: int = 1
const BOSS_ROOM: int = 2
const LOOT_ROOM: int = 3
const STARTING_ROOM: int = 4

var rng = RandomNumberGenerator.new()

class Room extends Area2D:
	var size: Vector2
	var room_type: int
	#var room_connection_locations: Array[bool]
	
	func _init(width: int, height: int, x_pos: int, y_pos: int):
		self.size = Vector2(width, height)
		self.position = Vector2(x_pos, y_pos)
		self.room_type = NORMAL_ROOM
		var collision_box: CollisionShape2D = CollisionShape2D.new()
		collision_box.shape = RectangleShape2D.new()
		collision_box.shape.size = self.size
		self.add_child(collision_box)
		#self.room_connection_locations = [false, false, false, false]
		
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

class Hallway extends Area2D:
	const RIGHT: int = 0
	const UP: int = 1
	const LEFT: int = 2
	const DOWN: int = 3
	
	var a: Room
	var b: Room
	var lines: Array
	
	func _init(a: Room, b: Room) -> void: # from a to b
		self.a = a
		self.b = b
		#self.a.room_connection_locations[direction] = true
		self.lines = []
		#self._create_path(line_width, direction)
	
	func _create_path(line_width: int, starting_direction: int) -> void:
		if starting_direction % 2 == 0: # starts horizontal
			var overlap: int = self._overlap(a.position.y, a.position.y + a.size.y, b.position.y, b.position.y + b.size.y)
			if overlap >= line_width:
				var line_node: Line2D = Line2D.new()
				line_node.default_color = Color.BLACK
				line_node.width = line_width
				line_node.z_index = 2
				if b._get_center().y < a._get_center().y:
					if starting_direction == LEFT:
						line_node.points = PackedVector2Array([Vector2(a.position.x, b.position.y + b.size.y - overlap / 2), Vector2(b.position.x + b.size.x, b.position.y + b.size.y - overlap / 2)])
					else:
						line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x, b.position.y + b.size.y - overlap / 2), Vector2(b.position.x, b.position.y + b.size.y - overlap / 2)])
				else:
					if starting_direction == LEFT:
						line_node.points = PackedVector2Array([Vector2(a.position.x, a.position.y + a.size.y - overlap / 2), Vector2(b.position.x + b.size.x, a.position.y + a.size.y - overlap / 2)])
					else:
						line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x, a.position.y + a.size.y - overlap / 2), Vector2(b.position.x, a.position.y + a.size.y - overlap / 2)])
				lines.append(line_node)
			else: # has to turn
				var line_node: Line2D = Line2D.new()
				line_node.default_color = Color.BLACK
				line_node.width = line_width
				line_node.z_index = 2
				var second_line_node: Line2D = Line2D.new()
				second_line_node.default_color = Color.BLACK
				second_line_node.width = line_width
				second_line_node.z_index = 2
				if starting_direction == LEFT:
					line_node.points = PackedVector2Array([Vector2(a.position.x, a.position.y + a.size.y / 2), Vector2(b._get_center().x - line_width / 2, a.position.y + a.size.y / 2)])
					second_line_node.points = PackedVector2Array([line_node.points[1] + Vector2(line_width / 2, line_width / 2), Vector2(b._get_center().x, b.position.y if b._get_center().y > a._get_center().y else b.position.y + b.size.y)])
				else:
					line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x, a.position.y + a.size.y / 2), Vector2(b._get_center().x + line_width / 2, a.position.y + a.size.y / 2)])
					second_line_node.points = PackedVector2Array([line_node.points[1] - Vector2(line_width / 2, line_width / 2), Vector2(b._get_center().x, b.position.y if b._get_center().y > a._get_center().y else b.position.y + b.size.y)])
				lines.append(line_node)
				lines.append(second_line_node)
		else:
			var overlap: int = self._overlap(a.position.x, a.position.x + a.size.x, b.position.x, b.position.x + b.size.x)
			if overlap >= line_width:
				var line_node: Line2D = Line2D.new()
				line_node.default_color = Color.BLACK
				line_node.width = line_width
				line_node.z_index = 2
				if b._get_center().x < a._get_center().x:
					if starting_direction == DOWN:
						line_node.points = PackedVector2Array([Vector2(b.position.x + b.size.x - overlap / 2, a.position.y + a.size.y), Vector2(b.position.x + b.size.x - overlap / 2, b.position.y)])
					else:
						line_node.points = PackedVector2Array([Vector2(b.position.x + b.size.x - overlap / 2, a.position.y), Vector2(b.position.x + b.size.x - overlap / 2, b.position.y + b.size.y)])
				else:
					if starting_direction == DOWN:
						line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x - overlap / 2, a.position.y + a.size.y), Vector2(a.position.x + a.size.x - overlap / 2, b.position.y)])
					else:
						line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x - overlap / 2, a.position.y), Vector2(a.position.x + a.size.x - overlap / 2, b.position.y + b.size.y)])
				lines.append(line_node)
			else:
				var line_node: Line2D = Line2D.new()
				line_node.default_color = Color.BLACK
				line_node.width = line_width
				line_node.z_index = 2
				var second_line_node: Line2D = Line2D.new()
				second_line_node.default_color = Color.BLACK
				second_line_node.width = line_width
				second_line_node.z_index = 3
				if starting_direction == DOWN:
					line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x / 2, a.position.y + a.size.y), Vector2(a.position.x + a.size.x / 2, b.position.y + b.size.y / 2 + line_width / 2)])
					second_line_node.points = PackedVector2Array([line_node.points[1] - Vector2(line_width / 2 * (-1 if b.position.x < a.position.x else 1), line_width / 2), Vector2(b.position.x if b.position.x > a.position.x else b.position.x + b.size.x, b.position.y + b.size.y / 2)])
				else:
					line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x / 2, a.position.y), Vector2(a.position.x + a.size.x / 2, b.position.y + b.size.y / 2 - line_width / 2)])
					second_line_node.points = PackedVector2Array([line_node.points[1] + Vector2(line_width / 2 * (-1 if b.position.x > a.position.x else 1), line_width / 2), Vector2(b.position.x if b.position.x > a.position.x else b.position.x + b.size.x, b.position.y + b.size.y / 2)])
				lines.append(line_node)
				lines.append(second_line_node)
	
	func _create_collision_polygon():
		var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
		var right_points: PackedVector2Array = self._get_right_points()
		right_points.reverse()
		collision_polygon.polygon = self._get_left_points() + right_points
		self.add_child(collision_polygon)
		var temp: Line2D = Line2D.new()
		temp.default_color = Color.DARK_GOLDENROD
		temp.width = 100
		temp.z_index = 6
		temp.points = collision_polygon.polygon
		return temp
	
	func _overlap(min1, max1, min2, max2):
		return max(0, min(max1, max2) - max(min1, min2))
	
	func _get_left_points() -> PackedVector2Array:
		if len(self.lines) == 1:
			var angle = self.lines[0].points[0].angle_to_point(self.lines[0].points[1])
			if angle < 0:
				angle += 2 * PI
			angle = 2 * PI - angle
			var direction: int = snapped(angle / (PI / 2), 1) % 4
			
			var vec: Vector2
			if direction == UP:
				vec = Vector2(-self.lines[0].width / 2, 0)
			elif direction == DOWN:
				vec = Vector2(self.lines[0].width / 2, 0)
			elif direction == LEFT:
				vec = Vector2(0, self.lines[0].width / 2)
			else:
				vec = Vector2(0, -self.lines[0].width / 2)
			return PackedVector2Array([self.lines[0].points[0] + vec, self.lines[0].points[1] + vec])

		else:
			var angle = self.lines[0].points[0].angle_to_point(self.lines[0].points[1])
			if angle < 0:
				angle += 2 * PI
			angle = 2 * PI - angle
			var direction1: int = snapped(angle / (PI / 2), 1) % 4
			
			angle = self.lines[1].points[0].angle_to_point(self.lines[1].points[1])
			if angle < 0:
				angle += 2 * PI
			angle = 2 * PI - angle
			var direction2: int = snapped(angle / (PI / 2), 1) % 4
			

			if direction1 == LEFT and direction2 == UP:
				return PackedVector2Array([(self.lines[0].points[0] + Vector2(0, self.lines[0].width / 2)), (self.lines[0].points[1] + Vector2(0, self.lines[0].width / 2)), (self.lines[1].points[1] - Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == LEFT and direction2 == DOWN:
				return PackedVector2Array([(self.lines[0].points[0] + Vector2(0, self.lines[0].width / 2)), (self.lines[0].points[1] + Vector2(self.lines[0].width, self.lines[0].width / 2)), (self.lines[1].points[1] + Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == RIGHT and direction2 == UP:
				return PackedVector2Array([(self.lines[0].points[0] - Vector2(0, self.lines[0].width / 2)), (self.lines[0].points[1] - Vector2(self.lines[0].width, self.lines[0].width / 2)), (self.lines[1].points[1] - Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == RIGHT and direction2 == DOWN:
				return PackedVector2Array([(self.lines[0].points[0] - Vector2(0, self.lines[0].width / 2)), (self.lines[0].points[1] - Vector2(0, self.lines[0].width / 2)), (self.lines[1].points[1] + Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == UP and direction2 == LEFT:
				return PackedVector2Array([(self.lines[0].points[0] - Vector2(self.lines[0].width / 2, 0)), (self.lines[0].points[1] - Vector2(self.lines[0].width / 2, -self.lines[0].width)), (self.lines[1].points[1] + Vector2(0, self.lines[1].width / 2))])
			elif direction1 == UP and direction2 == RIGHT:
				return PackedVector2Array([(self.lines[0].points[0] - Vector2(self.lines[0].width / 2, 0)), (self.lines[0].points[1] - Vector2(self.lines[0].width / 2, 0)), (self.lines[1].points[1] - Vector2(0, self.lines[1].width / 2))])
			elif direction1 == DOWN and direction2 == LEFT:
				return PackedVector2Array([(self.lines[0].points[0] + Vector2(self.lines[0].width / 2, 0)), (self.lines[0].points[1] + Vector2(self.lines[0].width / 2, 0)), (self.lines[1].points[1] + Vector2(0, self.lines[1].width / 2))])
			else: #down1 and right2
				return PackedVector2Array([(self.lines[0].points[0] + Vector2(self.lines[0].width / 2, 0)), (self.lines[0].points[1] + Vector2(self.lines[0].width / 2, -self.lines[0].width)), (self.lines[1].points[1] - Vector2(0, self.lines[1].width / 2))])

	
	func _get_right_points() -> PackedVector2Array:
		if len(self.lines) == 1:
			var angle = self.lines[0].points[0].angle_to_point(self.lines[0].points[1])
			if angle < 0:
				angle += 2 * PI
			angle = 2 * PI - angle
			var direction: int = snapped(angle / (PI / 2), 1) % 4
			
			var vec: Vector2
			if direction == UP:
				vec = Vector2(self.lines[0].width / 2, 0)
			elif direction == DOWN:
				vec = Vector2(-self.lines[0].width / 2, 0)
			elif direction == LEFT:
				vec = Vector2(0, -self.lines[0].width / 2)
			else:
				vec = Vector2(0, self.lines[0].width / 2)
			return PackedVector2Array([self.lines[0].points[0] + vec, self.lines[0].points[1] + vec])
		else:
			var angle = self.lines[0].points[0].angle_to_point(self.lines[0].points[1])
			if angle < 0:
				angle += 2 * PI
			angle = 2 * PI - angle
			var direction1: int = snapped(angle / (PI / 2), 1) % 4
			
			angle = self.lines[1].points[0].angle_to_point(self.lines[1].points[1])
			if angle < 0:
				angle += 2 * PI
			angle = 2 * PI - angle
			var direction2: int = snapped(angle / (PI / 2), 1) % 4
			#var dct = {}
			#dct[0] = "RIGHT"
			#dct[1] = "UP"
			#dct[2] = "LEFT"
			#dct[3] = "DOWN"
			#print(dct[direction1])
			#print(dct[direction2])
			
			if direction1 == LEFT and direction2 == UP:
				return PackedVector2Array([(self.lines[0].points[0] - Vector2(0, self.lines[0].width / 2)), (self.lines[0].points[1] + Vector2(self.lines[0].width, -self.lines[0].width / 2)), (self.lines[1].points[1] + Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == LEFT and direction2 == DOWN:
				return PackedVector2Array([Vector2(self.lines[0].points[0] - Vector2(0, self.lines[0].width / 2)), Vector2(self.lines[0].points[1] - Vector2(0, self.lines[0].width / 2)), Vector2(self.lines[1].points[1] - Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == RIGHT and direction2 == UP:
				return PackedVector2Array([Vector2(self.lines[0].points[0] + Vector2(0, self.lines[0].width / 2)), Vector2(self.lines[0].points[1] + Vector2(0, self.lines[0].width / 2)), Vector2(self.lines[1].points[1] + Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == RIGHT and direction2 == DOWN:
				return PackedVector2Array([Vector2(self.lines[0].points[0] + Vector2(0, self.lines[0].width / 2)), Vector2(self.lines[0].points[1] - Vector2(self.lines[0].width, -self.lines[0].width / 2)), Vector2(self.lines[1].points[1] - Vector2(self.lines[1].width / 2, 0))])
			elif direction1 == UP and direction2 == LEFT:
				return PackedVector2Array([Vector2(self.lines[0].points[0] + Vector2(self.lines[0].width / 2, 0)), Vector2(self.lines[0].points[1] + Vector2(self.lines[0].width / 2, 0)), Vector2(self.lines[1].points[1] - Vector2(0, self.lines[1].width / 2))])
			elif direction1 == UP and direction2 == RIGHT:
				return PackedVector2Array([Vector2(self.lines[0].points[0] + Vector2(self.lines[0].width / 2, 0)), Vector2(self.lines[0].points[1] + Vector2(self.lines[0].width / 2, self.lines[0].width)), Vector2(self.lines[1].points[1] + Vector2(0, self.lines[1].width /2))])
			elif direction1 == DOWN and direction2 == LEFT:
				return PackedVector2Array([Vector2(self.lines[0].points[0] - Vector2(self.lines[0].width / 2, 0)), Vector2(self.lines[0].points[1] - Vector2(self.lines[0].width / 2, self.lines[0].width)), Vector2(self.lines[1].points[1] - Vector2(0, self.lines[1].width / 2))])
			else: #down1 and right2
				return PackedVector2Array([Vector2(self.lines[0].points[0] - Vector2(self.lines[0].width / 2, 0)), Vector2(self.lines[0].points[1] - Vector2(self.lines[0].width / 2, 0)), Vector2(self.lines[1].points[1] + Vector2(0, self.lines[1].width / 2))])

class CustomAStar:
	extends AStar2D
	
	func _compute_cost(from_id, to_id):
		var diff: Vector2 = (self.get_point_position(from_id) - self.get_point_position(to_id)).abs()
		return diff.x + diff.y
	
	func _estimate_cost(from_id, to_id):
		return self._compute_cost(from_id, to_id)

# Called when the node enters the scene tree for the first time.
func _ready():
	var starting_time: int = Time.get_ticks_msec()
	while not _generate_dungeon():
		print("Restarting dungeon generation process")
	print("Time to generate level: " + str(Time.get_ticks_msec() - starting_time) + " milliseconds")
	var times: Array[int] = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _generate_dungeon() -> bool:
	var rooms: Array[Room] = []
	
	# Create Rooms
	
	for i in range(NUMBER_OF_ROOMS_GENERATED):
		var width : int = rng.randi_range(200, 1000) * 1.5
		var height : int = rng.randi_range(200, 1000) * 1.5
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
				#if room_index != other_room_index and (rooms[other_room_index]._get_center() - rooms[room_index]._get_center()).length() < 150:
				#if room_index != other_room_index and Rect2(rooms[room_index].position, rooms[room_index].size).intersects(Rect2(rooms[other_room_index].position, rooms[other_room_index].size)):
				if room_index != other_room_index and rooms[room_index]._is_too_close(rooms[other_room_index]):
					separation_vec = separation_vec - (rooms[other_room_index]._get_center() - rooms[room_index]._get_center())
					rooms_moved = true
			var room_velocity = rooms[room_index].transform.y * -1 * separation_speed + separation_vec
			rooms[room_index].position += room_velocity * 0.3
	
	# Separate main rooms
	
	rooms.sort_custom(_room_comparison)
	var room_positions: Dictionary = {} # position -> Room
	var main_rooms: Array[Room] = []
	var number_of_main_rooms: int = int(len(rooms) * PERCENTAGE_OF_MAIN_ROOMS)
	for i in range(number_of_main_rooms):
		main_rooms.append(rooms.pop_back())
		room_positions[main_rooms[-1]._get_center()] = main_rooms[-1]
	
	var mst_path: CustomAStar = _create_mst(room_positions.keys())
	
	#Create Room -> path id dict
	var room_id_dict: Dictionary = {} # Room -> id
	for p in mst_path.get_point_ids():
		room_id_dict[room_positions[mst_path.get_point_position(p)]] = p
	
	#Confirm that no room has more than four connections
	for p: int in mst_path.get_point_ids():
		if len(mst_path.get_point_connections(p)) > 4:
			return false
	
	#Identify boss room
	var outer_rooms: Dictionary = {} # position -> id
	for p in mst_path.get_point_ids():
		if len(mst_path.get_point_connections(p)) == 1:
			outer_rooms[mst_path.get_point_position(p)] = p
	var boss_room_position: Vector2 = outer_rooms.keys()[rng.randi_range(0, len(outer_rooms) - 1)]
	room_positions[boss_room_position].room_type = BOSS_ROOM
	
	#Identify spawn room
	var room_distances: Dictionary = {}
	for p: int in mst_path.get_point_ids():
		var room_distance: int = len(mst_path.get_point_path(p, outer_rooms[boss_room_position]))
		if room_distance in room_distances:
			room_distances[room_distance].append(room_positions[mst_path.get_point_position(p)])
		else:
			room_distances[room_distance] = [room_positions[mst_path.get_point_position(p)]]
	for room: Room in room_distances[room_distances.keys().max()]:
		room.room_type = STARTING_ROOM
	
	#Create hallways:

	var hallways: Array[Hallway] = []
	var hallway_connections: Dictionary = {}
	for room: Room in main_rooms:
		var room_connections: Array = [[], [], [], []]
		for connecting_room_id in mst_path.get_point_connections(room_id_dict[room]):
			var connected_room: Room = room_positions[mst_path.get_point_position(connecting_room_id)]
			if [connected_room, room] not in hallway_connections:
				var angle = room._get_center().angle_to_point(connected_room._get_center())
				if angle < 0:
					angle += 2 * PI
				var direction: int = snapped((2 * PI - angle) / (PI / 2), 1) % 4
				#room_connections[snapped(angle / (PI / 2), 1) % 4].append(connected_room)
				if len(room_connections[direction]) == 1:
					if direction % 2 == 0: # originally horizontal
						if connected_room._get_center().y < room._get_center().y:
							if len(room_connections[1]) == 1:
								return false
							else:
								room_connections[1].append(connected_room)
						else:
							if len(room_connections[3]) == 1:
								return false
							else:
								room_connections[3].append(connected_room)
					else:
						if connected_room._get_center().x > room._get_center().x:
							if len(room_connections[0]) == 1:
								return false
							else:
								room_connections[0].append(connected_room)
						else:
							if len(room_connections[2]) == 1:
								return false
							else:
								room_connections[2].append(connected_room)
				else:
					room_connections[direction].append(connected_room)
				hallway_connections[[room, connected_room]] = true
		for direction: int in range(len(room_connections)):
			if room_connections[direction]:
				hallways.append(Hallway.new(room, room_connections[direction][0]))#, rng.randi_range(300, 500), direction))
				hallways[-1]._create_path(rng.randi_range(300, 500), direction)
				hallways[-1]._create_collision_polygon()
				if hallways[-1].has_overlapping_areas():
					return false
	
	_create_room_nodes([], main_rooms, mst_path)
	#_draw_mst(mst_path)
	_draw_hallways(hallways)
	_draw_hallway_walls(hallways)
	return true

func _create_room_nodes(rooms: Array[Room], main_rooms: Array[Room], path: AStar2D) -> void:
	for room in rooms:
		var room_node = ColorRect.new()
		room_node.size.x = room.size.x
		room_node.size.y = room.size.y
		room_node.position.x = room.position.x
		room_node.position.y = room.position.y
		add_child(room_node)
	
	var final_position: Vector2 = path.get_point_position(path.get_point_ids()[-1])
	
	for room in main_rooms:
		var room_node = ColorRect.new()
		room_node.size.x = room.size.x
		room_node.size.y = room.size.y
		room_node.position.x = room.position.x
		room_node.position.y = room.position.y
		#room_node.color = Color(0, 255, 0)
		if room.room_type == BOSS_ROOM:
			room_node.color = Color(255, 0, 0)
		elif room.room_type == STARTING_ROOM:
			room_node.color = Color(0, 0, 255)
		else:
			room_node.color = Color(0, 255, 0)
		add_child(room_node)

func _draw_mst(path: CustomAStar) -> void:
	for p in path.get_point_ids():
		for c in path.get_point_connections(p):
			var p_pos: Vector2 = path.get_point_position(p)
			var c_pos: Vector2 = path.get_point_position(c)
			#draw_line(p_pos, c_pos, Color(255, 0, 0), 15, true)
			var line_node: Line2D = Line2D.new()
			line_node.points = PackedVector2Array([p_pos, c_pos])
			line_node.default_color = Color(255, 0, 0)
			#line_node.width = rng.randi_range(300, 500)
			line_node.width = 100
			line_node.z_index = 1
			add_child(line_node)

func _draw_hallways(hallways: Array[Hallway]) -> void:
	#var number_of_lines: int = 0
	for hallway: Hallway in hallways:
		for line_node: Line2D in hallway.lines:
			add_child(line_node)
			#number_of_lines += 1
	#print("Number of hallways: " + str(number_of_lines))

func _draw_hallway_walls(hallways: Array[Hallway]) -> void:
	for hallway: Hallway in hallways:
		var left_line_node: Line2D = Line2D.new()
		left_line_node.default_color = Color.BROWN
		left_line_node.width = 100
		left_line_node.z_index = 5
		left_line_node.points = hallway._get_left_points()
		add_child(left_line_node)
		var right_line_node: Line2D = Line2D.new()
		right_line_node.default_color = Color.WHITE
		right_line_node.width = 100
		right_line_node.z_index = 5
		right_line_node.points = hallway._get_right_points()
		add_child(right_line_node)
		#var temp: Line2D = Line2D.new()
		#temp.default_color = Color.DARK_GOLDENROD
		#temp.width = 100
		#temp.z_index = 6
		#var right = hallway._get_right_points()
		#right.reverse()
		#temp.points = hallway._get_left_points() + right
		#add_child(temp)

func _room_comparison(a: Room, b: Room) -> bool:
	return a.size.x * a.size.y < b.size.x * b.size.y

#func _create_mst(rooms: Array[Vector2]) -> CustomAStar:
func _create_mst(rooms: Array) -> CustomAStar:
	# Prim's algorithm
	var path: CustomAStar = CustomAStar.new()
	path.add_point(path.get_available_point_id(), rooms.pop_back())
	while rooms:
		var min_dist: float = INF
		var min_p: Vector2 # position of that node
		var p: Vector2
		
		for existing_point_id: int in path.get_point_ids():
			var existing_point: Vector2 = path.get_point_position(existing_point_id)
			for new_point: Vector2 in rooms:
				var distance: int = existing_point.distance_to(new_point)
				if distance < min_dist:
					min_dist = distance
					min_p = new_point
					p = existing_point
		
		var n: int = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		rooms.erase(min_p)
	return path
