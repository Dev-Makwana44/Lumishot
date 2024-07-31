class_name MainMenu
extends Control

@onready var start_button = $"MarginContainer/HBoxContainer/VBoxContainer/Start Button"
@onready var quit_button = $"MarginContainer/HBoxContainer/VBoxContainer/Quit Button"
@onready var start_level = preload("res://world.tscn") as PackedScene
@onready var open = $open
@onready var close = $close

func _on_start_button_button_up():
	
	open.play()
	get_tree().change_scene_to_packed(start_level)

func _on_quit_button_button_up():
	
	close.play()
	get_tree().quit()
