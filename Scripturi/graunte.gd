extends StaticBody2D

@onready var tile_map = get_node("/root/world/TileMap")  
var item_instance = self 
@onready var gaina_nodes = get_tree().get_nodes_in_group("gaina")
@onready var inv = get_node("/root/world/CanvasLayer/Inv")

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
	if body.is_in_group("player"):
		inv.add_item("24",1)
		self.queue_free()



func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("gaina_hitbox"):
		# Căutăm toate găinile din scenă și le actualizăm hrana
		for gaina in gaina_nodes:
			if is_instance_valid(gaina):
				gaina.hrana += 1  # Crește hrana pentru fiecare găină
		item_instance.queue_free()  # Eliberăm obiectul (itemul)
