extends Control
@onready var gc = get_node("../../.")
@onready var window: TextureRect = $Window
@onready var taskbar_icon: TextureRect = $TaskbarIcon


func _on_button_button_up() -> void:
	print("X")
	gc.showWindow(null, null)

func _on_icon_button_up() -> void:
	print("Icon")
	gc.showWindow(window, taskbar_icon)
