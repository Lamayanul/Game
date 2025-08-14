extends Sprite2D

var float_amplitude: float = 2.0  
var float_speed: float = 2.0 
var original_position: Vector2 
var time_passed: float = 0.0  
@onready var sprite =$"."
@onready var player = get_tree().get_first_node_in_group("player")

func _process(delta: float):
	time_passed += delta
	position.y = original_position.y + sin(time_passed * float_speed) * float_amplitude * 10
	
	



func _on_panel_container_mouse_entered() -> void:
	$"../VBoxContainer/InfoLabel".visible=true
	#color_rect.visible=true
	$"../VBoxContainer/InfoLabel".text=player.info
	print("intrare")


func _on_panel_container_mouse_exited() -> void:
	$"../VBoxContainer/InfoLabel".visible=true
	$"../VBoxContainer/InfoLabel".text=""
	#color_rect.visible=false
	print("iesire")
