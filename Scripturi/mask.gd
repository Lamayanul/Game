extends AnimatedSprite2D

@onready var water_tilemap: TileMapLayer = get_node("/root/world/ota")
@onready var character: CharacterBody2D = get_parent()
var mat: ShaderMaterial

func _ready() -> void:
	mat = ShaderMaterial.new()
	mat.shader = preload("res://Shaders/water_mask.gdshader")
	material = mat

func _process(_delta: float) -> void:
	var water_y = get_water_surface_y()
	
	if water_y == INF:
		# Dezactivăm efectul complet când nu suntem în apă
		mat.set_shader_parameter("is_active", false)
		return
	
	mat.set_shader_parameter("is_active", true)
	
	# Calculăm Y-ul local corect
	var local_water_pos = to_local(Vector2(character.global_position.x, water_y))
	
	# Obținem textura curentă pentru a ști înălțimea sprite-ului în acest cadru de animație
	var tex = sprite_frames.get_frame_texture(animation, frame)
	if not tex: return
	
	var sprite_height = tex.get_size().y 
	
	# Normalizăm: 0.0 e sus, 1.0 e jos în interiorul sprite-ului
	# Adăugăm 0.5 deoarece originea (0,0) la AnimatedSprite2D este în centrul texturii
	var normalized_y = (local_water_pos.y / sprite_height) + 0.5
	
	mat.set_shader_parameter("cutoff_y", normalized_y)

func get_water_surface_y() -> float:
	# Verificăm la nivelul picioarelor (offset de 8 pixeli în jos față de centrul caracterului)
	var feet_pos = character.global_position + Vector2(0, 8) 
	var local_pos_in_tilemap = water_tilemap.to_local(feet_pos)
	var map_pos = water_tilemap.local_to_map(local_pos_in_tilemap)
	var tile_data = water_tilemap.get_cell_tile_data(map_pos)
	
	if tile_data:
		# Returnăm marginea de sus a tile-ului în coordonate globale
		var tile_local_center = water_tilemap.map_to_local(map_pos)
		var tile_top_y_local = tile_local_center.y - (water_tilemap.tile_set.tile_size.y / 2.0)
		# Transformăm coordonata Y locală a tilemap-ului în coordonată globală
		return water_tilemap.to_global(Vector2(0, tile_top_y_local)).y
		
	return INF
