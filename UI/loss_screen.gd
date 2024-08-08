class_name LossScreen
extends PanelContainer

signal restart_game

func _on_button_button_down():
	restart_game.emit()
