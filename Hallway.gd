class_name Hallway
extends Area2D
const RIGHT: int = 0
const UP: int = 1
const LEFT: int = 2
const DOWN: int = 3

var a: Room
var b: Room
var lines: Array
var line_width: int

func _init(room_a: Room, room_b: Room) -> void: # from a to b
	self.a = room_a
	self.b = room_b
	self.lines = []

func _create_path(width: int, starting_direction: int) -> bool:
	self.line_width = width
	if a.room_connection_locations[starting_direction]:
		return false
	else:
		a.room_connection_locations[starting_direction] = self
	if starting_direction % 2 == 0: # starts horizontal
		if starting_direction == LEFT and b.room_connection_locations[RIGHT]:
			return false
		elif starting_direction == RIGHT and b.room_connection_locations[LEFT]:
			return false
		var overlap: float = self._overlap(a.position.y, a.position.y + a.size.y, b.position.y, b.position.y + b.size.y)
		if overlap >= width:
			b.room_connection_locations[RIGHT if starting_direction == LEFT else LEFT] = self
			var line_node: Line2D = Line2D.new()
			line_node.default_color = Color.DIM_GRAY
			line_node.width = width
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
			#if a.position.y > b.position.y and b.room_connection_locations[DOWN]:
				#return false
			#elif a.position.y < b.position.y and b.room_connection_locations[UP]:
				#return false
			if a.position.y > b.position.y:
				if b.room_connection_locations[DOWN]:
					return false
				else:
					b.room_connection_locations[DOWN] = self
			else:
				if b.room_connection_locations[UP]:
					return false
				else:
					b.room_connection_locations[UP] = self
			var line_node: Line2D = Line2D.new()
			line_node.default_color = Color.DIM_GRAY
			line_node.width = width
			line_node.z_index = 2
			var second_line_node: Line2D = Line2D.new()
			second_line_node.default_color = Color.DIM_GRAY
			second_line_node.width = width
			second_line_node.z_index = 2
			if starting_direction == LEFT:
				line_node.points = PackedVector2Array([Vector2(a.position.x, a.position.y + a.size.y / 2), Vector2(b._get_center().x - width / 2, a.position.y + a.size.y / 2)])
				second_line_node.points = PackedVector2Array([line_node.points[1] + Vector2(width / 2, width / 2), Vector2(b._get_center().x, b.position.y if b._get_center().y > a._get_center().y else b.position.y + b.size.y)])
			else:
				line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x, a.position.y + a.size.y / 2), Vector2(b._get_center().x + width / 2, a.position.y + a.size.y / 2)])
				second_line_node.points = PackedVector2Array([line_node.points[1] - Vector2(width / 2, width / 2), Vector2(b._get_center().x, b.position.y if b._get_center().y > a._get_center().y else b.position.y + b.size.y)])
			lines.append(line_node)
			lines.append(second_line_node)
	else:
		if starting_direction == DOWN and b.room_connection_locations[UP]:
			return false
		elif starting_direction == UP and b.room_connection_locations[DOWN]:
			return false
		var overlap: int = self._overlap(a.position.x, a.position.x + a.size.x, b.position.x, b.position.x + b.size.x)
		if overlap >= width:
			b.room_connection_locations[UP if starting_direction == DOWN else DOWN] = self
			var line_node: Line2D = Line2D.new()
			line_node.default_color = Color.DIM_GRAY
			line_node.width = width
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
			#if a.position.x > b.position.x and b.room_connection_locations[RIGHT]:
				#return false
			#elif a.position.x < b.position.x and b.room_connection_locations[LEFT]:
				#return false
			if a.position.x > b.position.x:
				if b.room_connection_locations[RIGHT]:
					return false
				else:
					b.room_connection_locations[RIGHT] = self
			else:
				if b.room_connection_locations[LEFT]:
					return false
				else:
					b.room_connection_locations[LEFT] = self
			var line_node: Line2D = Line2D.new()
			line_node.default_color = Color.DIM_GRAY
			line_node.width = width
			line_node.z_index = 2
			var second_line_node: Line2D = Line2D.new()
			second_line_node.default_color = Color.DIM_GRAY
			second_line_node.width = width
			second_line_node.z_index = 3
			if starting_direction == DOWN:
				line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x / 2, a.position.y + a.size.y), Vector2(a.position.x + a.size.x / 2, b.position.y + b.size.y / 2 + width / 2)])
				second_line_node.points = PackedVector2Array([line_node.points[1] - Vector2(width / 2 * (-1 if b.position.x < a.position.x else 1), width / 2), Vector2(b.position.x if b.position.x > a.position.x else b.position.x + b.size.x, b.position.y + b.size.y / 2)])
			else:
				line_node.points = PackedVector2Array([Vector2(a.position.x + a.size.x / 2, a.position.y), Vector2(a.position.x + a.size.x / 2, b.position.y + b.size.y / 2 - width / 2)])
				second_line_node.points = PackedVector2Array([line_node.points[1] + Vector2(width / 2 * (-1 if b.position.x > a.position.x else 1), width / 2), Vector2(b.position.x if b.position.x > a.position.x else b.position.x + b.size.x, b.position.y + b.size.y / 2)])
			lines.append(line_node)
			lines.append(second_line_node)
	return true

func _create_collision_polygon():
	var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
	var right_points: PackedVector2Array = self._get_right_points()
	right_points.reverse()
	collision_polygon.set_polygon(self._get_left_points() + right_points)
	self.monitorable = true
	self.collision_layer = 1
	self.collision_mask = 1
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
