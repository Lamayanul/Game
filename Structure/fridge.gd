extends StaticBody2D

@onready var grid_container: GridContainer = $CanvasLayer/GridContainer
@onready var fridge_light: PointLight2D = $PointLight2D
@onready var light: Node2D = $Light

@onready var player = get_node("/root/world/player")
var player_in_zone = false

func _ready() -> void:
	grid_container.visible = false
	$open_fridge.visible = false
	$close_fridge.visible = true
	fridge_light.enabled = false
	light.visible=false

func _process(_delta: float) -> void:
	if player_in_zone and Input.is_action_just_pressed("interact"):
		grid_container.visible = !grid_container.visible
		$open_fridge.visible = grid_container.visible
		$close_fridge.visible = !grid_container.visible
		fridge_light.enabled = $open_fridge.visible
		light.visible=$open_fridge.visible

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and player.is_high==false:
		player_in_zone = true
		if $open_fridge.visible:
			grid_container.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false
		grid_container.visible = false # Close fridge when walking away
