extends StaticBody2D

@onready var tilemap = get_node("/root/world/TileMap")  # Schimbă cu calea corectă
var item_instance = self  # Dacă ești deja în scriptul obiectului

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
