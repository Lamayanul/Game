extends Node2D

var player: CharacterBody2D
var ota_layer: TileMapLayer
@onready var line_2d = get_node_or_null("SubViewport/Line2D")

func _ready() -> void:
	# Initial visibility is false until we find the player in water
	visible = false

func _physics_process(_delta: float) -> void:
	# Find player if not cached or if it became invalid
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			visible = false
			return
	
	# Find ota_layer if not cached
	if not ota_layer or not is_instance_valid(ota_layer):
		ota_layer = get_parent().get_node_or_null("ota")
		if not ota_layer:
			# Absolute path fallback if needed
			ota_layer = get_node_or_null("/root/world/ota")
			if not ota_layer:
				return

	# Check if player is on a water tile in the "ota" layer
	var local_pos = ota_layer.to_local(player.global_position)
	var map_pos = ota_layer.local_to_map(local_pos)
	var tile_data = ota_layer.get_cell_tile_data(map_pos)
	
	if tile_data:
		# Player is in water
		if not visible:
			visible = true
			if line_2d and line_2d.has_method("reset_line"):
				line_2d.reset_line()
		
		# Update trail position to follow player
		global_position = player.global_position
	else:
		# Player is not in water
		if visible:
			visible = false
			if line_2d and line_2d.has_method("reset_line"):
				line_2d.reset_line()
