extends Control

@onready var button1: Button = $TextureRect3/Button
@onready var button2: Button = $TextureRect2/Button
@onready var button3: Button = $TextureRect4/Button
@onready var button4: Button = $TextureRect5/Button

var toggled1 := false
var toggled2 := false
var toggled3 := false
var toggled4 := false

func _ready():
	$TextureRect3/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	$TextureRect2/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	$TextureRect4/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	$TextureRect5/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	update_buttons()

func _on_button1_pressed():
	toggled1 = !toggled1
	if toggled1:
		$TextureRect3/TextureRect.z_index=1
		$TextureRect3/TextureRect.visible=true
		$TextureRect3/TextureRect.mouse_filter=MOUSE_FILTER_PASS
	else:
		$TextureRect3/TextureRect.z_index=-1
		$TextureRect3/TextureRect.visible=false
		$TextureRect3/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	update_button_visual(button1, toggled1)

func _on_button2_pressed():
	toggled2 = !toggled2
	if toggled2:
		$TextureRect2/TextureRect.z_index=1
		$TextureRect2/TextureRect.visible=true
		$TextureRect2/TextureRect.mouse_filter=MOUSE_FILTER_PASS
	else:
		$TextureRect2/TextureRect.z_index=-1
		$TextureRect2/TextureRect.visible=false
		$TextureRect2/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	update_button_visual(button2, toggled2)

func _on_button3_pressed():
	toggled3 = !toggled3
	if toggled3:
		$TextureRect4/TextureRect.z_index=1
		$TextureRect4/TextureRect.visible=true
		$TextureRect4/TextureRect.mouse_filter=MOUSE_FILTER_PASS
	else:
		$TextureRect4/TextureRect.z_index=-1
		$TextureRect4/TextureRect.visible=false
		$TextureRect4/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	update_button_visual(button3, toggled3)

func _on_button4_pressed():
	toggled4 = !toggled4
	if toggled4:
		$TextureRect5/TextureRect.z_index=1
		$TextureRect5/TextureRect.visible=true
		$TextureRect5/TextureRect.mouse_filter=MOUSE_FILTER_PASS
	else:
		$TextureRect5/TextureRect.z_index=-1
		$TextureRect5/TextureRect.visible=false
		$TextureRect5/TextureRect.mouse_filter=MOUSE_FILTER_IGNORE
	update_button_visual(button4, toggled4)

func update_buttons():
	update_button_visual(button1, toggled1)
	update_button_visual(button2, toggled2)
	update_button_visual(button3, toggled3)
	update_button_visual(button4, toggled4)

func update_button_visual(button: Button, toggled: bool):
	if toggled:
		button.modulate = Color(0,1,0) # Verde
	else:
		button.modulate = Color(1,1,1) # Alb normal
