extends Control

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_mouse_pos = event.global_position  # 🟡 global, nu local
	elif event is InputEventMouseMotion and dragging:
		var scroll = get_parent() as ScrollContainer
		if scroll:
			var delta = event.global_position - last_mouse_pos
			scroll.scroll_horizontal -= delta.x
			scroll.scroll_vertical -= delta.y
			last_mouse_pos = event.global_position
