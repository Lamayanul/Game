extends Area2D

@onready var light_panel = get_node("/root/world/TileMap/schelet/LightScene/CanvasLayer")
var is_here = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_here = true
	


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_here = false
		light_panel.visible =false

func _input(event) -> void:
	if Input.is_action_just_pressed("interact"):
		if is_here:
			light_panel.visible = !light_panel.visible
