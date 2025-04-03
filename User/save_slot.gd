extends Panel

var save_data : SaveData:
	set(value):
		save_data=value
		if save_data!=null:
			$Label.text=save_data.title

signal pressed(panel)


func _ready() -> void:
	$Line2D.hide()



func _process(_delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	$Line2D.show()


func _on_mouse_exited() -> void:
	$Line2D.hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			pressed.emit(self)
