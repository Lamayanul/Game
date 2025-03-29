extends StaticBody2D

@onready var tile_map = get_node("/root/world/TileMap")  
var item_instance = self 
@onready var gaina = get_node("/root/world/gaina")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		if body.is_in_group("layer"):
			item_instance.queue_free()



func _on_area_2d_area_entered(area: Area2D) -> void:
		if area.is_in_group("gaina_hitbox"):
			item_instance.queue_free()
			gaina.hrana+=1
