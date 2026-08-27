extends Control
@onready var gc = get_node("../../.")
@onready var window: TextureRect = $Window
@onready var taskbar_icon: TextureRect = $TaskbarIcon

var dragging = false
var offsetX: float = 0.0
func _on_button_button_up() -> void:
	gc.showWindow(null, null)

func _ready():
	window.visibility_changed.connect(_on_visibility_changed)


func _on_icon_button_up() -> void:
	gc.showWindow(window, taskbar_icon)

func _physics_process(delta: float) -> void:
	if dragging:
		window.position = get_local_mouse_position()
		window.position.x += offsetX
		
		
		if window.position.x < 0.0: 
			window.position.x = 0
			
		if window.position.y < 0.0: 
			window.position.y = 0
		
		var ws = get_window().size
		if window.position.x > ws.x:
			window.position.x = ws.x - 100
		
		if window.position.y > ws.y:
			window.position.y = ws.y - 100
	pass




func _on_visibility_changed():
	window.position = Vector2(360, 135)
	pass

func _on_menu_bar_button_up() -> void:
	dragging = false
	offsetX = 0

func _on_menu_bar_button_down() -> void:
	offsetX = window.position.x - get_local_mouse_position().x
	dragging = true
