extends Node2D

@export var collectable_data: ItemData = null
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = collectable_data.item_texture

func _on_area_2d_body_entered(body):
	if body is Player:
		if body.inventory.check_inventory_contents(collectable_data):
			body.inventory.add_item(collectable_data)
			#print(collectable_data.item_name + " picked up by player")
			queue_free()
		else:
			print("Max stacks")
