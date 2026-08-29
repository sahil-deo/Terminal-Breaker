extends Control
@onready var gc = get_node("../../.")
@onready var window: TextureRect = $Window

func _on_button_button_up() -> void:
	gc.hideWindow(window)

func _ready():
	pass

func _on_icon_button_up() -> void:
	gc.showWindow(window)

func _physics_process(delta: float) -> void:
	pass


func _on_restart_button_button_down() -> void:
	gc.restartGame()
	
	
# this is actualy close game function
func _on_reboot_button_button_down() -> void:
	gc.closeGame()
