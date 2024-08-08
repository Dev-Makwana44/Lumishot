class_name LevelCompletionScreen
extends PanelContainer

signal level_complete

func _on_button_button_down():
	level_complete.emit()
