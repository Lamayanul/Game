extends Sprite2D

var float_amplitude: float = 2.0  
var float_speed: float = 2.0 
var original_position: Vector2 
var time_passed: float = 0.0  
@onready var sprite = $"."


func _process(delta: float):
	time_passed += delta
	position.y = original_position.y + sin(time_passed * float_speed) * float_amplitude * 0.5
