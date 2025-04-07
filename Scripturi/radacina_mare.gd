extends Area2D

var is_cutting=false;
var index_taiere=0;
# Called when the node enters the scene tree for the first time.
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var player = get_node_or_null("/root/world/player")

func _ready() -> void:
	pass # Replace with function body.


func _on_area_2d_area_entered(area):
	if area.is_in_group("arma"):
		if inv.selected_slot.get_id()=="2":
			call_deferred("play_taiere_animation")

func play_taiere_animation():
	index_taiere += 1
	print("Index taiere: ", index_taiere)

	if index_taiere == 4:
		var drop_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var drop_position = global_position + drop_offset 
		
		inv.drop_item_everywhere("6", 1, drop_position) 
		queue_free();
		index_taiere=0;
	
	
