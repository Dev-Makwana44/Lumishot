extends Node2D

const NUMBER_OF_ROOMS_GENERATED: int = 50
const PERCENTAGE_OF_MAIN_ROOMS: float = 0.3
const ROOM_SIZE_MIN: int = 300 * 1.5
const ROOM_SIZE_MAX: int = 1500 * 1.5
const NORMAL_ROOM: int = 1
const BOSS_ROOM: int = 2
const LOOT_ROOM: int = 3
const STARTING_ROOM: int = 4


var rng = RandomNumberGenerator.new()

class CustomAStar:
	extends AStar2D
	
	func _compute_cost(from_id, to_id):
		var diff: Vector2 = (self.get_point_position(from_id) - self.get_point_position(to_id)).abs()
		return diff.x + diff.y
	
	func _estimate_cost(from_id, to_id):
		return self._compute_cost(from_id, to_id)

var hallways: Array[Hallway] = []
@onready var player = get_node("Player")
func _ready():
	var starting_time: int = Time.get_ticks_msec()
	#while not _generate_dungeon():
		#print("Restarting dungeon generation process")
	while true:
		print("generating dungeon")
		if _generate_dungeon():
			break
	print("Time to generate level: " + str(Time.get_ticks_msec() - starting_time) + " milliseconds")
	#var times: Array[int] = []
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	for hallway: Hallway in hallways:
		if hallway.has_overlapping_areas() or hallway.has_overlapping_bodies():
			print("COLLISION")

func _generate_dungeon() -> bool:
	var rooms: Array[Room] = []
	
	# Create Rooms
	
	for i in range(NUMBER_OF_ROOMS_GENERATED):
		var width : int = rng.randi_range(ROOM_SIZE_MIN, ROOM_SIZE_MAX)
		var height : int = rng.randi_range(ROOM_SIZE_MIN, ROOM_SIZE_MAX)
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

	hallways = []
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
			if len(room_connections[direction]) > 1:
				return false
			if room_connections[direction]:
				hallways.append(Hallway.new(room, room_connections[direction][0]))
				if not hallways[-1]._create_path(rng.randi_range(300, 500), direction):
					return false
				var temp = hallways[-1]._create_collision_polygon()
				var polygon: Polygon2D = Polygon2D.new()
				polygon.polygon = temp.points
				#add_child(polygon)
				if hallways[-1].has_overlapping_areas():
					print("HALLWAY COLLISION")
					return false
	var starting_room_chosen: bool = false
	for room in main_rooms:
		if room.room_type == STARTING_ROOM:
			if not starting_room_chosen:
				player.position = room._get_center()
				starting_room_chosen = true
				break
			else:
				room.room_type = LOOT_ROOM
	
	for i in range(20):
		var collectable: Resource = load("res://Collectables/collectable.tscn")
		var collectable_instance = collectable.instantiate()
		collectable_instance.position = player.position + Vector2(100 * (i + 1), 0)
		add_child(collectable_instance)
		if i % 3 == 0:
			collectable_instance._set_collectable_data(load("res://Resources/Items/CraftingItems/Bioluminescent_Bacteria.tres"))
		elif i % 3 == 1:
			collectable_instance._set_collectable_data(load("res://Resources/Items/CraftingItems/Mutated_Blood.tres"))
		else:
			collectable_instance._set_collectable_data(load("res://Resources/Items/CraftingItems/Rabbit_Foot.tres"))
	
	_create_room_nodes([], main_rooms, mst_path)
	#_draw_mst(mst_path)
	_draw_hallways(hallways)
	#_draw_hallway_walls(hallways)
	return true

func _create_room_nodes(rooms: Array[Room], main_rooms: Array[Room], path: AStar2D) -> void:
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
	for hallway: Hallway in hallways:
		for line_node: Line2D in hallway.lines:
			add_child(line_node)

func _draw_hallway_walls(hallways: Array[Hallway]) -> void:
	for hallway: Hallway in hallways:
		var left_line_node: Line2D = Line2D.new()
		left_line_node.default_color = Color.DIM_GRAY
		left_line_node.width = 100
		left_line_node.z_index = 5
		left_line_node.points = hallway._get_left_points()
		add_child(left_line_node)
		var right_line_node: Line2D = Line2D.new()
		right_line_node.default_color = Color.DIM_GRAY
		right_line_node.width = 100
		right_line_node.z_index = 5
		right_line_node.points = hallway._get_right_points()
		add_child(right_line_node)
		
		#var polygon_node: Polygon2D = Polygon2D.new()
		#var left_points = hallway._get_left_points()
		#var right_points = hallway._get_right_points()
		#right_points.reverse()
		#polygon_node.polygon = left_points +  right_points
		#add_child(polygon_node)

func _room_comparison(a: Room, b: Room) -> bool:
	return a.size.x * a.size.y < b.size.x * b.size.y

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
