extends Node2D

@export var collectable_data: ItemData = null
@onready var sprite: Sprite2D = $Sprite2D

func _on_area_2d_body_entered(body):
	if body is Player:
		if body.inventory.check_inventory_contents(collectable_data):
			body.inventory.add_item(collectable_data)
			queue_free()
		else:
			print("Max stacks")

func _set_collectable_data(item: ItemData) -> void:
	collectable_data = item
	sprite.texture = collectable_data.item_texture
