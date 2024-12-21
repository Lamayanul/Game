extends CharacterBody2D
@onready var grid_container: GridContainer = $CanvasLayer/Recipe
@onready var inv: PanelContainer = $"../CanvasLayer/Inv"
var in_zona=false

func _ready():
	grid_container.hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_zona=true
		grid_container.show()
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_zona=false
		grid_container.hide()
