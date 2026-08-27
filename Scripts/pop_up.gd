extends Control

@export var defaultText: String
@onready var label: Label = $window/Label

func _ready() -> void:
	#setMessage(defaultText)
	pass

func setMessage(message: String):
	label.text = message

func _on_close_button_up() -> void:
	print("xx")
	queue_free()

func setPosition(x: float, y: float):
	position.x = x
	position.y = y
