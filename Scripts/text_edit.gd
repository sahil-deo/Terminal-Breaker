extends TextEdit

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE:
		var caret_col := get_caret_column()
		if caret_col == 0:
			accept_event()  # consume it, prevents merging with previous line
