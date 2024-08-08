class_name BattleMech
extends Enemy

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var laser_sprite: AnimatedSprite2D = $"Laser Sprite"

var health = 200


func _ready():
	pass
