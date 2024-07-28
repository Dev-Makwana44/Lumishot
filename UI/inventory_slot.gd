class_name InventorySlot
extends Panel

@onready var texture_rect: TextureRect = $TextureRect
@onready var stack_label: Label = %StackLabel

var item_data: ItemData = null

func set_item_data(item: ItemData, stack_size: int) -> void:
	print(stack_size)
	item_data = item
	texture_rect.texture = item_data.item_texture
	set_current_stack_size(stack_size)

func set_current_stack_size(stack: int) -> void:
	if stack > 1:
		stack_label.show()
		stack_label.text = str(stack)
	else:
		stack_label.hide()
