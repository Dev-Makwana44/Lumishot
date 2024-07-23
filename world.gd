extends Node2D

class Room extends Node2D:
	var size: Vector2
	
	func _init(width: int, height: int, x_pos: int, y_pos: int):
		self.size = Vector2(width, height)
		self.position = Vector2(x_pos, y_pos)
		
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


class MST_Edge:
	var src: int
	var dest: int
	var weight: int
	
	func _init(src: int, dest: int, weight: int):
		self.src = src
		self.dest = dest
		self.weight = weight

class MST_Subset:
	var parent: int
	var rank: int
	
	func _init(parent: int, rank: int):
		self.parent = parent
		self.rank = rank


const NUMBER_OF_ROOMS_GENERATED: int = 50
const SPACE_BETWEEN_ROOMS: int = 100
const PERCENTAGE_OF_MAIN_ROOMS: float = 0.3

# Called when the node enters the scene tree for the first time.
func _ready():
	var starting_time: int = Time.get_ticks_msec()
	_generate_dungeon()
	print("Time to generate level: " + str(Time.get_ticks_msec() - starting_time) + " milliseconds")
	var times: Array[int] = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _generate_dungeon() -> void:
	var rooms: Array[Room] = []
	
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
				#if room_index != other_room_index and (rooms[other_room_index]._get_center() - rooms[room_index]._get_center()).length() < 150:
				#if room_index != other_room_index and Rect2(rooms[room_index].position, rooms[room_index].size).intersects(Rect2(rooms[other_room_index].position, rooms[other_room_index].size)):
				if room_index != other_room_index and rooms[room_index]._is_too_close(rooms[other_room_index]):
					separation_vec = separation_vec - (rooms[other_room_index]._get_center() - rooms[room_index]._get_center())
					rooms_moved = true
			var room_velocity = rooms[room_index].transform.y * -1 * separation_speed + separation_vec
			rooms[room_index].position += room_velocity * 0.3
	
	# Separate main rooms
	
	rooms.sort_custom(_room_comparison)
	var main_rooms: Array[Room] = []
	var number_of_main_rooms: int = int(len(rooms) * PERCENTAGE_OF_MAIN_ROOMS)
	for i in range(number_of_main_rooms):
		main_rooms.append(rooms.pop_back())
	
	# Delaunay Triangulation
	var room_positions: Array[Vector2] = []
	var delaunay: Delaunay = Delaunay.new()
	for room in main_rooms:
		delaunay.add_point(room._get_center())
		room_positions.append(room._get_center())
	var triangles: Array = delaunay.triangulate()
	var edges: Array[Delaunay.Edge] = []
	for triangle: Delaunay.Triangle in triangles:
		if not delaunay.is_border_triangle(triangle):
			for new_edge in [triangle.edge_ab, triangle.edge_bc, triangle.edge_ca]:
				var already_inserted: bool = false
				for existing_edge in edges:
					if existing_edge.equals(new_edge):
						already_inserted = true
						break
				if not already_inserted:
					edges.append(new_edge)

	var mst_path: AStar2D = _create_mst(room_positions)

	_create_room_nodes(rooms, main_rooms)
	#_create_triangulation_lines(edges)
	_draw_mst(mst_path)

func _create_room_nodes(rooms: Array[Room], main_rooms: Array[Room]) -> void:
	for room in rooms:
		var room_node = ColorRect.new()
		room_node.size.x = room.size.x
		room_node.size.y = room.size.y
		room_node.position.x = room.position.x
		room_node.position.y = room.position.y
		add_child(room_node)
	
	for room in main_rooms:
		var room_node = ColorRect.new()
		room_node.size.x = room.size.x
		room_node.size.y = room.size.y
		room_node.position.x = room.position.x
		room_node.position.y = room.position.y
		room_node.color = Color(0, 255, 0)
		add_child(room_node)

func _create_triangulation_lines(edges: Array[Delaunay.Edge]):
	for edge: Delaunay.Edge in edges:
		var line_node = Line2D.new()
		line_node.points = PackedVector2Array([edge.a, edge.b])
		add_child(line_node)

func _draw_mst(path: AStar2D):
	for p in path.get_point_ids():
		for c in path.get_point_connections(p):
			var p_pos: Vector2 = path.get_point_position(p)
			var c_pos: Vector2 = path.get_point_position(c)
			#draw_line(p_pos, c_pos, Color(255, 0, 0), 15, true)
			var line_node: Line2D = Line2D.new()
			line_node.points = PackedVector2Array([p_pos, c_pos])
			line_node.default_color = Color(255, 0, 0)
			add_child(line_node)

func _room_comparison(a: Room, b: Room):
	return a.size.x * a.size.y < b.size.x * b.size.y

func _find_root(subsets: Array[MST_Subset], i: int):
	if subsets[i].parent == i:
		return subsets[i].parent
	subsets[i].parent = _find_root(subsets, subsets[i].parent)
	return subsets[i].parent

func _union(subsets: Array[MST_Subset], x: int, y: int):
	var rootX: int = _find_root(subsets, x)
	var rootY: int = _find_root(subsets, y)

	if subsets[rootY].rank < subsets[rootX].rank:
		subsets[rootY].parent = rootX
	elif subsets[rootX].rank < subsets[rootX].rank:
		subsets[rootY].parent = rootX
	else:
		subsets[rootY].parent = rootX
		subsets[rootX].rank += 1

func _create_mst(rooms: Array[Vector2]):
	# Prim's algorithm
	var path: AStar2D = AStar2D.new()
	path.add_point(path.get_available_point_id(), rooms.pop_back())
	while rooms:
		var min_dist: float = INF
		var min_p: Vector2 # position of that node
		var p: Vector2
		
		for existing_point_id: int in path.get_point_ids():
			var existing_point: Vector2 = path.get_point_position(existing_point_id)
			for new_point: Vector2 in rooms:
				var distance: int = existing_point.distance_to(new_point)
				#if existing_point.distance_to(new_point) < min_dist:
					#min_dist = existing_point.distance_to(new_point)
				if distance < min_dist:
					min_dist = distance
					min_p = new_point
					p = existing_point
		
		var n: int = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		rooms.erase(min_p)
	return path
