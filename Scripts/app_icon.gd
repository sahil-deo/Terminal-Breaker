extends TextureRect

@onready var window: TextureRect = $Window

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_gui_input(event: InputEvent) -> void:
	if(event.is_action_pressed("mouseLeft")):
		window.visible = true
	pass # Replace with function body.
