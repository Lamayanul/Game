# CardsScroller.gd
extends ScrollContainer

@onready var rail: HBoxContainer = $Rail

var dragging := false
var last_pos := Vector2.ZERO

var card_w   := 300.0  # lățimea cardului (sau citește dintr-un card)
var card_width   := 600.0

func _gui_input(event: InputEvent) -> void:
	# drag cu mouse-ul/touch ca să derulezi
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_pos = (event as InputEventMouseButton).position
		if dragging: accept_event()
	elif event is InputEventMouseMotion and dragging:
		var dx := (event as InputEventMouseMotion).relative.x
		scroll_horizontal = clamp(scroll_horizontal - dx, 0, max(0, rail.size.x - size.x))
		accept_event()
	# rotiță pentru scroll orizontal
	elif event is InputEventMouseButton and event.pressed:
		var step := 60
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_horizontal = max(0, scroll_horizontal - step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_horizontal = min(rail.size.x - size.x, scroll_horizontal + step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			scroll_horizontal = max(0, scroll_horizontal - step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			scroll_horizontal = min(rail.size.x - size.x, scroll_horizontal + step)

#func scroll_next_card() -> void:
	#var maxv = max(0.0, rail.size.x - size.x)
	#var idx  := int(floor(scroll_horizontal / card_width)) + 1
	#var to   = clamp(float(idx) * card_width, 0.0, maxv)
	#scroll_horizontal = to
#
#func scroll_prev_card() -> void:
	#var idx  := int(ceil(scroll_horizontal / card_width)) - 1
	#var maxv = max(0.0, rail.size.x - size.x)
	#var to   = clamp(float(idx) * card_width, 0.0, maxv)
	#scroll_horizontal = to
#
#func _on_button_right_pressed() -> void: scroll_next_card()
#func _on_button_left_pressed()  -> void: scroll_prev_card()
