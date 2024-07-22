extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


@onready var anim = get_node("AnimatedSprite2D")

func _ready():
	anim.play("Idle")

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var x_direction = Input.get_axis("ui_left", "ui_right")
	if x_direction:
		#velocity.x = x_direction * SPEED
		velocity.x = move_toward(velocity.x, x_direction * SPEED, SPEED / 5)
		if x_direction == 1:
			anim.flip_h = false
		elif x_direction == -1:
			anim.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED / 10)
	
	var y_direction = Input.get_axis("ui_up", "ui_down")
	if y_direction:
		#velocity.y = y_direction * SPEED
		velocity.y = move_toward(velocity.y, y_direction * SPEED, SPEED / 5)
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED / 10)
	
	if x_direction or y_direction:
		anim.play("Run")
	else:
		anim.play("Idle")

	move_and_slide()
