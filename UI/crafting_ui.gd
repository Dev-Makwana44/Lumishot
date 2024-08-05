class_name Crafting_UI
extends PanelContainer

@export var recipe_array: Array[ItemRecipe] = []

@onready var recipe_tree: Tree = %RecipeTree
@onready var inventory_tree: Tree = %InventoryTree
@onready var title_label: Label = %TitleLabel
@onready var crafting_slots: Array[InventorySlot] = [%CraftingSlot1, %CraftingSlot2, %CraftingSlot3]
@onready var item_texture: TextureRect = %ItemTexture
@onready var broken = $broken
@onready var craft = $craft
@onready var select = $select
@onready var unsuccessful = $unsuccessful
@onready var place = $place
@onready var unlock = $unlock
@onready var open = $open
@onready var close = $close

var cross_mark = load("res://Resources/Images/Cross.png") as CompressedTexture2D
var check_mark = load("res://Resources/Images/Check.png") as CompressedTexture2D
var question_mark = load("res://Resources/Images/Question Mark.png") as CompressedTexture2D
var inventory: InventoryComponent = null
var recipe_dictionary: Dictionary = {}
var discovered_recipes: Dictionary = {}

func _ready() -> void:
	hide()
	recipe_tree.hide_root = true
	recipe_tree.select_mode = Tree.SELECT_ROW
	recipe_tree.scroll_horizontal_enabled = false
	inventory_tree.hide_root = true
	inventory_tree.select_mode = Tree.SELECT_ROW
	build_recipe_dictionary()
	build_recipe_tree()
	build_discovered_dictionary()
	
	open.play()
	
	for slot: InventorySlot in crafting_slots:
		slot.set_item_data(null, 1)

func build_recipe_dictionary() -> void:
	for recipe: ItemRecipe in recipe_array:
		var inventory_component: InventoryComponent = InventoryComponent.new()
		for item: ItemData in recipe.recipe_materials:
			inventory_component.add_item(item)
		recipe_dictionary[inventory_component] = recipe.recipe_final_item

func build_discovered_dictionary() -> void:
	for recipe: ItemRecipe in recipe_array:
		discovered_recipes[recipe.recipe_final_item.item_name] = false

func custom_item_sort(a: ItemData, b: ItemData) -> bool:
	return a.item_id < b.item_id

func build_recipe_tree() -> void:
	var tree_root: TreeItem = recipe_tree.create_item()
	
	for recipe: ItemRecipe in recipe_array:
		var new_recipe_slot: TreeItem = recipe_tree.create_item(tree_root)
		new_recipe_slot.set_icon(0, recipe.recipe_final_item.item_texture)
		new_recipe_slot.set_text(0, recipe.recipe_final_item.item_name)
		new_recipe_slot.set_icon(1, cross_mark)
		new_recipe_slot.set_icon_max_width(1, 40)
		#new_recipe_slot.set_selectable(0, false)
			

func build_recipe_material_window(selected_recipe: ItemRecipe) -> void:
	title_label.text = selected_recipe.recipe_final_item.item_name
	item_texture.texture = selected_recipe.recipe_final_item.item_texture
	inventory.remove_items(selected_recipe.recipe_materials)
	for i in range(3):
		crafting_slots[i].set_item_data(selected_recipe.recipe_materials[i], 1)

func populate_inventory() -> void:
	inventory_tree.clear()
	var tree_root: TreeItem = inventory_tree.create_item()
	
	for item: ItemData in inventory.get_inventory_contents():
		var new_inventory_slot: TreeItem = inventory_tree.create_item(tree_root)
		new_inventory_slot.set_text(0, str(item.item_name))
		new_inventory_slot.set_icon(0, item.item_texture)
		new_inventory_slot.set_text(1, str(inventory.get_inventory_contents()[item]))

func clear_crafting_grid() -> void:
	for slot: InventorySlot in crafting_slots:
		if slot.item_data != null:
			inventory.add_item(slot.item_data)
			slot.set_item_data(null, 1)

func check_crafting_recipes() -> ItemData:
	var crafting_slot_items: InventoryComponent = InventoryComponent.new()
	for slot: InventorySlot in crafting_slots:
		if slot.item_data == null:
			return null
		crafting_slot_items.add_item(slot.item_data)
	for recipe: InventoryComponent in recipe_dictionary:
		if recipe.get_inventory_contents() == crafting_slot_items.get_inventory_contents():
			return recipe_dictionary[recipe]
	return null

func _on_recipe_tree_item_selected() -> void:
	var cell_recipe_name: String = recipe_tree.get_selected().get_text(0)
	if discovered_recipes[cell_recipe_name]:
		clear_crafting_grid()
		for recipe: ItemRecipe in recipe_array:
			if recipe.recipe_final_item.item_name == cell_recipe_name and inventory.inventory_has_items(recipe.recipe_materials):
				build_recipe_material_window(recipe)
				populate_inventory()
				break
	recipe_tree.deselect_all()

func _on_inventory_tree_item_selected() -> void:
	var cell_item_name: String = inventory_tree.get_selected().get_text(0)
	for item: ItemData in inventory.get_inventory_contents():
		if item.item_name == cell_item_name:
			var slot_used: bool = false
			for slot: InventorySlot in crafting_slots:
				if slot.item_data == null:
					slot.set_item_data(item, 1)
					slot_used = true
					break
			if slot_used:
				inventory.get_inventory_contents()[item] -= 1
				inventory_tree.get_selected().set_text(1, str(inventory.get_inventory_contents()[item]))
				if inventory.get_inventory_contents()[item] == 0:
					inventory.get_inventory_contents().erase(item)
					inventory_tree.get_selected().free()
				var all_slots_full: bool = true
				for slot in crafting_slots:
					if slot.item_data == null:
						all_slots_full = false
						break
				if all_slots_full:
					var crafting_item: ItemData = check_crafting_recipes()
					if crafting_item != null:
						if discovered_recipes[crafting_item.item_name]:
							title_label.text = crafting_item.item_name
							item_texture.texture = crafting_item.item_texture
				place.play()
			break
	inventory_tree.deselect_all()

func _on_crafting_slot_1_gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		crafting_slot_click(0)

func _on_crafting_slot_2_gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		crafting_slot_click(1)

func _on_crafting_slot_3_gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		crafting_slot_click(2)

func crafting_slot_click(index: int) -> void:
	if crafting_slots[index].item_data != null:
		inventory.add_item(crafting_slots[index].item_data)
		populate_inventory()
		
	place.play()
		
	crafting_slots[index].set_item_data(null, 1)
	title_label.text = ""
	item_texture.texture = question_mark
	#recipe_tree.deselect_all()

func _on_craft_button_button_down():
	
	select.play()
	
	var craftable_item: ItemData = check_crafting_recipes()
	if craftable_item != null:
		inventory.add_crafted_item(craftable_item)
		populate_inventory()
		for slot in crafting_slots:
			slot.set_item_data(null, 1)
			
		craft.play()
			
		item_texture.texture = question_mark
		if discovered_recipes[craftable_item.item_name] == false:
			discovered_recipes[craftable_item.item_name] = true
			
			unlock.play()
			
			var tree_item: TreeItem = recipe_tree.get_root()
			while true:
				if tree_item == null:
					break
				if tree_item.get_text(0) == craftable_item.item_name:
					tree_item.set_icon(1, check_mark)
					break
				tree_item = tree_item.get_next_in_tree()
				
	else:
		
		unsuccessful.play()
