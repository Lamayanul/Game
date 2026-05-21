extends TextureRect

@onready var tile_map = get_node("/root/world/ota")
@onready var character: CharacterBody2D = get_parent().get_parent()

const SPRITE_HEIGHT = -5
const SPRITE_WIDTH = 7.8

func _process(delta: float) -> void:
	var water_y = get_water_surface_y()
	
	if water_y == INF:
		position = Vector2(-SPRITE_WIDTH / 2, -SPRITE_HEIGHT)
		size = Vector2(SPRITE_WIDTH, SPRITE_HEIGHT)
		return
	
	var local_water_y = water_y - character.global_position.y
	position = Vector2(-SPRITE_WIDTH / 2, -SPRITE_HEIGHT)
	size = Vector2(SPRITE_WIDTH, SPRITE_HEIGHT + local_water_y)
	

func get_water_surface_y() -> float:
	var tile_pos = tile_map.local_to_map(
		character.global_position - tile_map.global_position
	)
	var tile_data = tile_map.get_cell_tile_data(tile_pos)
	if tile_data:
		return tile_map.to_global(
			tile_map.map_to_local(tile_pos)
		).y - tile_map.tile_set.tile_size.y / 2.0
	return INF
