extends Node2D

var NUMBER_OF_ROOMS_GENERATED: int = 50
const PERCENTAGE_OF_MAIN_ROOMS: float = 0.3
const ROOM_SIZE_MIN: int = 300 * 1.5
const ROOM_SIZE_MAX: int = 1500 * 1.5
const ROOM_SEPARATION_SPEED: int = 300
const MAIN_ROOM_SIZE_RATIO: float = 1.25

const TURRET_SCENE: PackedScene = preload("res://Enemies/turret.tscn")
const BULLET_SCENE: PackedScene = preload("res://bullet.tscn")

@onready var player: Player = %Player
@onready var hud: HUD = %HUD
@onready var ui_container: UI_CONTAINER = %UI_Container
@onready var loss_screen: LossScreen = %"Loss Screen"
@onready var level_completion_screen: LevelCompletionScreen = %"Level Completion Screen"
@onready var gunshot = $gunshot

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var new_walls: Array
var level: int = 1
var hallways: Array[Hallway] = []
var level_cleared: bool = false
var rooms: Array[Room] = []

class CustomAStar extends AStar2D:
	
	func _compute_cost(from_id, to_id):
		var diff: Vector2 = (self.get_point_position(from_id) - self.get_point_position(to_id)).abs()
		return diff.x + diff.y
	
	func _estimate_cost(from_id, to_id):
		return self._compute_cost(from_id, to_id)

func _ready():
	var starting_time: int = Time.get_ticks_msec()
	while true:
		print("generating dungeon")
		if generate_dungeon(level):
			break
	print("Time to generate level: " + str(Time.get_ticks_msec() - starting_time) + " milliseconds")
	
	loss_screen.hide()
	level_completion_screen.hide()

func _process(delta):
	if Input.is_action_pressed("fire_gun") and player.time_since_shooting > player.FIRE_RATE:
		if player.ammo[player.selected_ammo_index] > 0 and not player.game_paused:
			player.time_since_shooting = 0.0
			var bullet: Bullet = BULLET_SCENE.instantiate()
			self.add_child(bullet)
			await bullet.is_node_ready()
			bullet.set_collision_mask_value(2, true)
			bullet.position = player.position
			var bullet_path = get_global_mouse_position() - player.position
			bullet.set_bullet_type(player.selected_ammo_index)
			bullet.rotation = atan2(bullet_path.y, bullet_path.x) + rng.randfn(0.0, 0.025)
			bullet.z_index = 9
			bullet.add_to_group("player_bullets")
			player.ammo[player.selected_ammo_index] -= 1
			player.inventory.remove_items([bullet.bullet_textures[player.selected_ammo_index]])
			hud.set_ammo(bullet.bullet_textures[player.selected_ammo_index], player.ammo[player.selected_ammo_index])
			if player.ammo[player.selected_ammo_index] == 0:
				ui_container.select_ammo_up()
			gunshot.pitch_scale = rng.randfn(1.0, 0.01)
			gunshot.play()

	if Input.is_action_just_pressed("use_potion"):
		if player.potions[player.selected_potion_index] > 0 and not player.game_paused:
			if player.use_potion():
				player.potions[player.selected_potion_index] -= 1
				player.inventory.remove_items([hud.potion_slot.item_data])
				hud.set_potion(hud.potion_slot.item_data, player.potions[player.selected_potion_index])
				if player.potions[player.selected_potion_index] == 0:
					ui_container.select_potion()

	if Input.is_action_just_pressed("throw_grenade"):
		if player.grenades[player.selected_grenade_index] > 0 and not player.game_paused:
			var grenade_path = get_global_mouse_position() - player.position
			var grenade: Grenade = Grenade.new(player.selected_grenade_index, atan2(grenade_path.y, grenade_path.x))#, get_global_mouse_position())
			self.add_child(grenade)
			#await grenade.is_node_ready()
			grenade.position = player.position
			#grenade.set_grenade_type(player.selected_grenade_index)
			grenade.z_index = 10
			grenade.add_to_group("grenades")
			player.grenades[player.selected_grenade_index] -= 1
			player.inventory.remove_items([hud.grenade_slot.item_data])
			hud.set_grenade(hud.grenade_slot.item_data, player.grenades[player.selected_grenade_index])
			if player.grenades[player.selected_grenade_index] == 0:
				ui_container.select_grenade()

func generate_dungeon(level: int) -> bool:
	rooms = []
	
	# Create rooms
	for i in range(NUMBER_OF_ROOMS_GENERATED + 7 * level):
		var width: int = rng.randi_range(ROOM_SIZE_MIN, ROOM_SIZE_MAX)
		var height: int = rng.randi_range(ROOM_SIZE_MIN, ROOM_SIZE_MAX)
		var new_position: Vector2i = random_point_in_circle(5000 + 50 * level)
		rooms.append(Room.new_room(width, height, new_position.x, new_position.y, level))
	
	# separate rooms
	rooms = separate_rooms(rooms, ROOM_SEPARATION_SPEED)
	
	# identify main rooms using ratio
	
	rooms.sort_custom(room_comparison) # sorts them in ascending order
	
	var main_rooms: Array[Room] = []
	var room_positions: Dictionary = {} # position -> Room
	for i in range(len(rooms) * PERCENTAGE_OF_MAIN_ROOMS):
		main_rooms.append(rooms.pop_back())
		room_positions[main_rooms[-1].rect.get_center()] = main_rooms[-1]
		add_child(main_rooms[-1])

	var mst_path: CustomAStar = create_astar(room_positions.keys())
	
	#Create Room -> path id dict
	var room_id_dict: Dictionary = {} # Room -> id
	var outer_rooms: Dictionary = {} # position -> id
	
	for p: int in mst_path.get_point_ids():
	
		#Confirm that no room has more than four connections
		if len(mst_path.get_point_connections(p)) > 4:
			return false
			
		# set room id dict value
		room_id_dict[room_positions[mst_path.get_point_position(p)]] = p
		
		#Identify boss room

		if len(mst_path.get_point_connections(p)) == 1:
			outer_rooms[mst_path.get_point_position(p)] = p

	var outer_room_positions = outer_rooms.keys()
	var max_position_distance: float = 0
	var farthest_position = null
	#outer_room_positions.sort_custom(func (a: Vector2, b: Vector2) : a.length() > b.length())
	for position: Vector2 in outer_room_positions:
		if position.length() > max_position_distance:
			farthest_position = position
			max_position_distance = position.length()
	var boss_room_position: Vector2 = farthest_position
	room_positions[boss_room_position].room_type = Room.BOSS_ROOM
	
	#Identify spawn room
	var room_distances: Dictionary = {}
	for p: int in mst_path.get_point_ids():
		var room_distance: int = len(mst_path.get_point_path(p, outer_rooms[boss_room_position]))
		if room_distance in room_distances:
			room_distances[room_distance].append(room_positions[mst_path.get_point_position(p)])
		else:
			room_distances[room_distance] = [room_positions[mst_path.get_point_position(p)]]
	var starting_room_chosen: bool = false
	for room: Room in room_distances[room_distances.keys().max()]:
		if not starting_room_chosen:
			room.room_type = Room.STARTING_ROOM
			player.position = room.rect.get_center()
			starting_room_chosen = true
		else:
			room.room_type = Room.NORMAL_ROOM
	
	#Create hallways:

	hallways = []
	var hallway_connections: Dictionary = {}
	for room: Room in main_rooms:
		var room_connections: Array = [[], [], [], []]
		for connecting_room_id in mst_path.get_point_connections(room_id_dict[room]):
			var connected_room: Room = room_positions[mst_path.get_point_position(connecting_room_id)]
			if [connected_room, room] not in hallway_connections:
				var angle = room.rect.get_center().angle_to_point(connected_room.rect.get_center())
				if angle < 0:
					angle += 2 * PI
				var direction: int = snapped((2 * PI - angle) / (PI / 2), 1) % 4
				if len(room_connections[direction]) == 1:
					if direction % 2 == 0: # originally horizontal
						if connected_room.rect.get_center().y < room.rect.get_center().y:
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
						if connected_room.rect.get_center().x > room.rect.get_center().x:
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
					#print("Hallways intersected")
					return false
	
	for room in main_rooms:
		# check for hallway-room collisions
		var room_polygon = PackedVector2Array([room.rect.position, Vector2(room.rect.end.x, room.rect.position.y), room.rect.end, Vector2(room.rect.position.x, room.rect.end.y)])
		for hallway: Hallway in hallways:
			var hallway_polygon: PackedVector2Array = hallway._get_left_points()
			var right_points: PackedVector2Array = hallway._get_right_points()
			right_points.reverse()
			hallway_polygon.append_array(right_points)
			if Geometry2D.intersect_polygons(hallway_polygon, room_polygon):
				return false
		
		# spawn enemies
		if room.room_type == Room.NORMAL_ROOM:
			#spawn_enemies(room, level)
			room.spawn_enemies(level + 4)
			#room.spawn_enemies(level + 14)
		elif room.room_type == Room.BOSS_ROOM:
			#spawn_enemies(room, level + 5)
			room.spawn_enemies(level + 9)
			#room.spawn_enemies(level + 19)
		
		# setup rooms
		room.setup_room()

	for room: Room in main_rooms:
		if room.room_type == Room.STARTING_ROOM:
			room.activate_enemies_in_adjacent_rooms()
	rooms = main_rooms
	draw_hallways(hallways)
	create_dungeon_borders([], hallways)
	return true

func generate_mst(vertices: Array, edges: Array) -> Array[Delaunay.Edge]:
	#var mst_edges: Array[Delaunay.Edge] = [] # set of edges in the mst
	var mst_edges: Dictionary = {}
	var mst_vertices: Dictionary = {} # set of vertices that have been added to the mst
	var available_edges: Dictionary = {} # set of edges that are available to be added to the mst
	var connections: Dictionary = {} # dictinary where vertex -> array of edges connected to it
	for vertex: Vector2 in vertices:
		for edge: Delaunay.Edge in edges:
			if vertex == edge.a or vertex == edge.b:
				connections[vertex] = connections.get(vertex, []) + [edge]
	
	# choose a random vertex as the starting vertex of the mst
	var random_vertex: Vector2 = vertices.pick_random()
	mst_vertices[random_vertex] = true
	for edge: Delaunay.Edge in connections[random_vertex]:
		available_edges[edge] = true
	
	while len(mst_vertices) < len(vertices):
		var best_edges = available_edges.keys()
		best_edges.sort_custom(edges_comparison)
		for edge: Delaunay.Edge in best_edges:
			if edge.a not in mst_vertices or edge.b not in mst_vertices:
				#mst_edges.append(edge)
				mst_edges[edge] = true
				available_edges.erase(edge)
				mst_vertices[edge.a] = true
				mst_vertices[edge.b] = true
				for new_edge in connections[edge.a if edge.a not in mst_vertices else edge.b]:
					available_edges[new_edge] = true
				break
	return mst_edges.keys()

func separate_rooms(rooms: Array[Room], separation_speed: int):
	var not_done: bool = true
	while not_done:
		not_done = false
		for current: int in range(len(rooms)):
			for other: int in range(len(rooms)):
				if current != other and rooms[current].rect.intersects(rooms[other].rect):
					var direction: Vector2 = (rooms[other].rect.get_center() - rooms[current].rect.get_center()).normalized().round()
					rooms[current].rect.position -= direction * separation_speed
					rooms[other].rect.position += direction * separation_speed
					not_done = true
	return rooms

func random_point_in_circle(radius: float) -> Vector2i:
	var theta: float = 2 * PI * rng.randf()
	var rand: float = rng.randf() + rng.randf()
	var r: float = rand if rand <= 1 else 2 - rand
	return Vector2i(radius * r * cos(theta), radius * r * sin(theta))

func draw_mst(path: CustomAStar) -> void:
	for p in path.get_point_ids():
		for c in path.get_point_connections(p):
			var p_pos: Vector2 = path.get_point_position(p)
			var c_pos: Vector2 = path.get_point_position(c)
			#draw_line(p_pos, c_pos, Color(255, 0, 0), 15, true)
			var line_node: Line2D = Line2D.new()
			line_node.points = PackedVector2Array([p_pos, c_pos])
			line_node.default_color = Color.RED
			#line_node.width = rng.randi_range(300, 500)
			line_node.width = 100
			line_node.z_index = 15
			add_child(line_node)

func draw_hallways(hallways: Array[Hallway]) -> void:
	for hallway: Hallway in hallways:
		for line_node: Line2D in hallway.lines:
			add_child(line_node)
			line_node.add_to_group("dungeon")

func create_dungeon_borders(rooms: Array[Room], hallways: Array[Hallway]):
	for room: Room in rooms:
		if room.room_connection_locations[Hallway.UP] == null:
			var static_body: StaticBody2D = StaticBody2D.new()
			static_body.set_collision_mask_value(4, true)
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			collision_polygon.polygon = PackedVector2Array([room.rect.position, Vector2(room.rect.end.x, room.rect.position.y)])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
		else:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.UP][0].a:
				collision_polygon.polygon = PackedVector2Array([room.rect.position, room.room_connection_locations[Hallway.UP][0]._get_left_points()[0]])
			else:
				collision_polygon.polygon = PackedVector2Array([room.rect.position, room.room_connection_locations[Hallway.UP][0]._get_right_points()[-1]])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var static_body2: StaticBody2D = StaticBody2D.new()
			var collision_polygon2: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon2.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.UP][0].a:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.UP][0]._get_right_points()[0], Vector2(room.rect.end.x, room.rect.position.y)])
			else:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.UP][0]._get_left_points()[-1], Vector2(room.rect.end.x, room.rect.position.y)])
			static_body2.add_child(collision_polygon2)
			add_child(static_body2)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var line2: Line2D = Line2D.new()
			line2.width = 25
			line2.z_index = 6
			line2.default_color = Color.GRAY
			line2.points = collision_polygon2.polygon
			add_child(line2)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			var occluder2: LightOccluder2D = LightOccluder2D.new()
			occluder2.occluder = OccluderPolygon2D.new()
			occluder2.occluder.closed = false
			occluder2.occluder.polygon = collision_polygon2.polygon
			add_child(occluder2)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
			static_body2.add_to_group("dungeon")
			line2.add_to_group("dungeon")
			occluder2.add_to_group("dungeon")
		
		if room.room_connection_locations[Hallway.RIGHT] == null:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			collision_polygon.polygon = PackedVector2Array([Vector2(room.rect.end.x, room.rect.position.y), room.rect.end])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
		else:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.RIGHT][0].a:
				collision_polygon.polygon = PackedVector2Array([Vector2(room.rect.end.x, room.rect.position.y), room.room_connection_locations[Hallway.RIGHT][0]._get_left_points()[0]])
			else:
				collision_polygon.polygon = PackedVector2Array([Vector2(room.rect.end.x, room.rect.position.y), room.room_connection_locations[Hallway.RIGHT][0]._get_right_points()[-1]])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var static_body2: StaticBody2D = StaticBody2D.new()
			var collision_polygon2: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon2.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.RIGHT][0].a:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.RIGHT][0]._get_right_points()[0], room.rect.end])
			else:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.RIGHT][0]._get_left_points()[-1], room.rect.end])
			static_body2.add_child(collision_polygon2)
			add_child(static_body2)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var line2: Line2D = Line2D.new()
			line2.width = 25
			line2.z_index = 6
			line2.default_color = Color.GRAY
			line2.points = collision_polygon2.polygon
			add_child(line2)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			var occluder2: LightOccluder2D = LightOccluder2D.new()
			occluder2.occluder = OccluderPolygon2D.new()
			occluder2.occluder.closed = false
			occluder2.occluder.polygon = collision_polygon2.polygon
			add_child(occluder2)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
			static_body2.add_to_group("dungeon")
			line2.add_to_group("dungeon")
			occluder2.add_to_group("dungeon")
		
		if room.room_connection_locations[Hallway.DOWN] == null:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			collision_polygon.polygon = PackedVector2Array([room.rect.end, Vector2(room.rect.position.x, room.rect.end.y)])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
		else:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.DOWN][0].a:
				collision_polygon.polygon = PackedVector2Array([room.rect.end, room.room_connection_locations[Hallway.DOWN][0]._get_left_points()[0]])
			else:
				collision_polygon.polygon = PackedVector2Array([room.rect.end, room.room_connection_locations[Hallway.DOWN][0]._get_right_points()[-1]])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var static_body2: StaticBody2D = StaticBody2D.new()
			var collision_polygon2: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon2.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.DOWN][0].a:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.DOWN][0]._get_right_points()[0], Vector2(room.rect.position.x, room.rect.end.y)])
			else:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.DOWN][0]._get_left_points()[-1], Vector2(room.rect.position.x, room.rect.end.y)])
			static_body2.add_child(collision_polygon2)
			add_child(static_body2)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var line2: Line2D = Line2D.new()
			line2.width = 25
			line2.z_index = 6
			line2.default_color = Color.GRAY
			line2.points = collision_polygon2.polygon
			add_child(line2)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			var occluder2: LightOccluder2D = LightOccluder2D.new()
			occluder2.occluder = OccluderPolygon2D.new()
			occluder2.occluder.closed = false
			occluder2.occluder.polygon = collision_polygon2.polygon
			add_child(occluder2)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
			static_body2.add_to_group("dungeon")
			line2.add_to_group("dungeon")
			occluder2.add_to_group("dungeon")
		
		if room.room_connection_locations[Hallway.LEFT] == null:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			collision_polygon.polygon = PackedVector2Array([Vector2(room.rect.position.x, room.rect.end.y), room.rect.position])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
		else:
			var static_body: StaticBody2D = StaticBody2D.new()
			var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.LEFT][0].a:
				collision_polygon.polygon = PackedVector2Array([Vector2(room.rect.position.x, room.rect.end.y), room.room_connection_locations[Hallway.LEFT][0]._get_left_points()[0]])
			else:
				collision_polygon.polygon = PackedVector2Array([Vector2(room.rect.position.x, room.rect.end.y), room.room_connection_locations[Hallway.LEFT][0]._get_right_points()[-1]])
			static_body.add_child(collision_polygon)
			add_child(static_body)
			var static_body2: StaticBody2D = StaticBody2D.new()
			var collision_polygon2: CollisionPolygon2D = CollisionPolygon2D.new()
			collision_polygon2.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			if room == room.room_connection_locations[Hallway.LEFT][0].a:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.LEFT][0]._get_right_points()[0], room.rect.position])
			else:
				collision_polygon2.polygon = PackedVector2Array([room.room_connection_locations[Hallway.LEFT][0]._get_left_points()[-1], room.rect.position])
			static_body2.add_child(collision_polygon2)
			add_child(static_body2)
			var line: Line2D = Line2D.new()
			line.width = 25
			line.z_index = 6
			line.default_color = Color.GRAY
			line.points = collision_polygon.polygon
			add_child(line)
			var line2: Line2D = Line2D.new()
			line2.width = 25
			line2.z_index = 6
			line2.default_color = Color.GRAY
			line2.points = collision_polygon2.polygon
			add_child(line2)
			var occluder: LightOccluder2D = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.closed = false
			occluder.occluder.polygon = collision_polygon.polygon
			add_child(occluder)
			var occluder2: LightOccluder2D = LightOccluder2D.new()
			occluder2.occluder = OccluderPolygon2D.new()
			occluder2.occluder.closed = false
			occluder2.occluder.polygon = collision_polygon2.polygon
			add_child(occluder2)
			static_body.add_to_group("dungeon")
			line.add_to_group("dungeon")
			occluder.add_to_group("dungeon")
			static_body2.add_to_group("dungeon")
			line2.add_to_group("dungeon")
			occluder2.add_to_group("dungeon")

	for hallway: Hallway in hallways:
		for side: PackedVector2Array in [hallway._get_left_points(), hallway._get_right_points()]:
			for index: int in range(len(side) - 1):
				var static_body: StaticBody2D = StaticBody2D.new()
				var collision: CollisionPolygon2D = CollisionPolygon2D.new()
				collision.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
				collision.polygon = PackedVector2Array([side[index], side[index + 1]])
				static_body.add_child(collision)
				add_child(static_body)
				var line: Line2D = Line2D.new()
				line.width = 25
				line.z_index = 6
				line.default_color = Color.GRAY
				line.points = PackedVector2Array([side[index], side[index + 1]])
				add_child(line)
				var occluder: LightOccluder2D = LightOccluder2D.new()
				occluder.occluder = OccluderPolygon2D.new()
				occluder.occluder.closed = false
				occluder.occluder.polygon = collision.polygon
				add_child(occluder)
				static_body.add_to_group("dungeon")
				line.add_to_group("dungeon")
				occluder.add_to_group("dungeon")

func room_comparison(a: Room, b: Room) -> bool: # sorts the rooms in ascending order by area
	return a.rect.get_area() < b.rect.get_area()

func edges_comparison(a, b) -> bool:
	return a.length() < b.length()

func create_astar(rooms: Array) -> CustomAStar:
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

func spawn_enemies(spawning_room: Room, level: int) -> void:
	for i in range(rng.randi_range(2 + level, 7 + level)):
		if rng.randi_range(0, 1) == 0:
			var turret: Turret = TURRET_SCENE.instantiate()
			turret.room = spawning_room
			self.add_child(turret)
			var x_pos = rng.randi_range(spawning_room.rect.position.x + turret.get_size().x, spawning_room.rect.end.x - turret.get_size().x)
			var y_pos = rng.randi_range(spawning_room.rect.position.y + turret.get_size().y, spawning_room.rect.end.y - turret.get_size().y)
			turret.position = Vector2(x_pos, y_pos)
			turret.add_to_group("robots")
			turret.add_to_group("enemies")
			turret.run = false
			turret.visible = false
			spawning_room.enemies[turret] = true
		else:
			var turret: Turret = TURRET_SCENE.instantiate()
			turret.room = spawning_room
			self.add_child(turret)
			var x_pos = rng.randi_range(spawning_room.rect.position.x + turret.get_size().x, spawning_room.rect.end.x - turret.get_size().x)
			var y_pos = rng.randi_range(spawning_room.rect.position.y + turret.get_size().y, spawning_room.rect.end.y - turret.get_size().y)
			turret.position = Vector2(x_pos, y_pos)
			turret.add_to_group("enemies")
			turret.add_to_group("robots")
			turret.run = false
			turret.visible = false
			spawning_room.enemies[turret] = true
	
	# use separation steering algorithm to prevent overlaps without having to 
	var not_done: bool = true
	var enemies = spawning_room.enemies.keys()
	while not_done:
		not_done = false
		for current: int in range(len(enemies)):
			var current_rect = Rect2(enemies[current].position - (enemies[current].get_size() / 2), enemies[current].get_size())
			for other: int in range(len(enemies)):
				var other_rect = Rect2(enemies[other].position - (enemies[other].get_size() / 2), enemies[other].get_size())
				if current != other and current_rect.intersects(other_rect):
					var direction: Vector2 = (enemies[other].position - enemies[current].position).normalized().round()
					enemies[current].position -= direction * 50
					enemies[other].position += direction * 50
					not_done = true

func room_cleared() -> void:
	for room: Room in rooms:
		if room.enemies:
			return
	if player.health > 0:
		level_completion_screen.show()

func _on_level_completion_screen_level_complete():
	level += 1
	for room: Room in rooms:
		self.remove_child(room)
	for node in self.get_tree().get_nodes_in_group("dungeon"):
		self.remove_child(node)
	for enemy in self.get_tree().get_nodes_in_group("enemies"):
		self.remove_child(enemy)
	_ready()
	player.game_paused = false

func _on_loss_screen_restart_game():
	player.health = player.MAX_HEALTH
	level = 1
	for room: Room in rooms:
		self.remove_child(room)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for node in get_tree().get_nodes_in_group("dungeon"):
		remove_child(node)
	for node in get_tree().get_nodes_in_group("player_bullets"):
		remove_child(node)
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		remove_child(node)
	player.inventory = InventoryComponent.new()
	player.inventory.add_item_with_amount(load("res://Resources/Items/CraftableItems/Bullet.tres") as ItemData, 300)
	player.set_inventory(player.inventory)
	_ready()
	player.game_paused = false

func _on_player_player_health_changed():
	ui_container.hud.health_label.text = str(player.health)
	if player.health <= 0:
		loss_screen.show()
		player.game_paused = true
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.run = false
