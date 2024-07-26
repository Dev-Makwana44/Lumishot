extends CharacterBody2D


#const SPEED: float = 500.0
const SPEED: float = 1000.0
const JUMP_VELOCITY: float = -400.0


@onready var anim = get_node("AnimatedSprite2D")
@onready var camera = get_node("Camera2D")

func _ready():
	anim.play("Idle")

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#
	#var x_direction: int = Input.get_axis("ui_left", "ui_right")
	#if x_direction:
#
		#velocity.x = move_toward(velocity.x, x_direction * SPEED, SPEED / 5)
		#if x_direction == 1:
			#anim.flip_h = false
		#elif x_direction == -1:
			#anim.flip_h = true
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED / 10)
	#
	#var y_direction: int = Input.get_axis("ui_up", "ui_down") 
	#if y_direction:
		#velocity.y = move_toward(velocity.y, y_direction * SPEED, SPEED / 5)
	#else:
		#velocity.y = move_toward(velocity.y, 0, SPEED / 10)
	#
	#if x_direction or y_direction:
		#anim.play("Run")
	#else:
		#anim.play("Idle")

	var v: Vector2 = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized()
	if v.x > 0:
		anim.flip_h = false
	elif v.x < 0:
		anim.flip_h = true
	if v: 
		anim.play("Run")
	else:
		anim.play("Idle")
		
	velocity.x = move_toward(velocity.x, v.x * SPEED, SPEED / 10)
	velocity.y = move_toward(velocity.y, v.y * SPEED, SPEED / 10)

	move_and_slide()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			camera.zoom += Vector2(0.1, 0.1)
		elif event.pressed and event.keycode == KEY_O:
			camera.zoom -= Vector2(0.1, 0.1)

