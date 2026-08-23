extends TextEdit

var _restoring := false

func _ready() -> void:
	caret_changed.connect(_on_caret_changed)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_BACKSPACE:
				if get_caret_column() == 0:
					accept_event()
			KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN:
				accept_event()

func _on_caret_changed() -> void:
	if _restoring:
		return
	var last_line := get_line_count() - 1
	if get_caret_line() != last_line:
		_restoring = true
		set_caret_line(last_line)
		set_caret_column(get_line(last_line).length())
		_restoring = false
