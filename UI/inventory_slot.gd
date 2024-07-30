class_name InventorySlot
extends Panel

@onready var texture_rect: TextureRect = $TextureRect
@onready var stack_label: Label = %StackLabel
@onready var mouse_in_slot: bool = false

var item_data: ItemData = null

func set_item_data(item: ItemData, stack_size: int) -> void:
	item_data = item
	if item == null:
		texture_rect.texture = null
	else:
		texture_rect.texture = item_data.item_texture
	set_current_stack_size(stack_size)

func set_current_stack_size(stack: int) -> void:
	if stack > 1:
		stack_label.show()
		stack_label.text = str(stack)
	else:
		stack_label.hide()

func _on_mouse_entered():
	mouse_in_slot = true

func _on_mouse_exited():
	mouse_in_slot = false
