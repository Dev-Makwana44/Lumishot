extends CharacterBody2D


#const SPEED: float = 500.0
var SPEED: float = 500.0
var FRICTION: float = SPEED / 10 # Dictates how fast the player accelerates. Usually going to be SPEED / 10 but might change if player is on different surfaces
var DASH_SPEED: float = 2000.0
var DASH_DURATION: float = 0.5
var DASH_COOLDOWN: float = 2.0


@onready var sprite = get_node("AnimatedSprite2D")
@onready var gun = get_node("Gun")
@onready var camera = get_node("Camera2D")
var time_since_dash: float = 3.0

func _ready():
	pass

func _physics_process(delta):
	
	var global_mouse_pos: Vector2 = get_global_mouse_position()
	gun.look_at(global_mouse_pos)
	
	if global_mouse_pos.x > self.position.x:
		sprite.flip_h = false
		gun.flip_h = false
		gun.position = Vector2(10, 0)
		gun.rotation_degrees += 45
	elif global_mouse_pos.x < self.position.x:
		sprite.flip_h = true
		gun.flip_h = true
		gun.position = Vector2(-10, 0)
		gun.rotation_degrees += 135
	
	
	var v: Vector2 = Vector2(int(Input.is_action_pressed("move_left")) * -1 + int(Input.is_action_pressed("move_right")), -1 * int(Input.is_action_pressed("move_up")) + int(Input.is_action_pressed("move_down")))
	v = v.normalized() # makes it so that strafing is not faster
	
	if v: 
		sprite.play("Run")
	else:
		sprite.play("Idle")
	
	if Input.is_action_pressed("dash") and time_since_dash > DASH_COOLDOWN:
		time_since_dash = 0.0
		self.velocity.x = v.x * DASH_SPEED
		self.velocity.y = v.y * DASH_SPEED
	
	#if time_since_dash < 0.5:
		#self.velocity.x = move_toward(velocity.x, v.x * DASH_SPEED, DASH_SPEED)
		#self.velocity.y = move_toward(velocity.y, v.y * DASH_SPEED, DASH_SPEED)
	#else:
		#self.velocity.x = move_toward(velocity.x, v.x * SPEED, FRICTION)
		#self.velocity.y = move_toward(velocity.y, v.y * SPEED, FRICTION)
	
	if time_since_dash >= DASH_DURATION:
		self.velocity.x = min(self.velocity.x, v.x * SPEED)
		self.velocity.y = min(self.velocity.y, v.y * SPEED)
		self.velocity.x = move_toward(velocity.x, v.x * SPEED, FRICTION)
		self.velocity.y = move_toward(velocity.y, v.y * SPEED, FRICTION)
	
	time_since_dash += delta

	move_and_slide()

func _unhandled_input(event): # temporary keybinds to zoom in and out using P and O
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			camera.zoom += Vector2(0.1, 0.1)
		elif event.pressed and event.keycode == KEY_O:
			camera.zoom -= Vector2(0.1, 0.1)

