extends ColorRect

# Trage nodul Player-ului tău din panoul Scene aici!
@export var player_node: Node2D 

func _process(_delta):
	if is_instance_valid(player_node):
		# --- ACEASTA ESTE PARTEA CHEIE ---
		# Calculăm unde se află playerul în coordonate globale de ecran (pixeli)
		var player_global_pos = player_node.get_global_transform_with_canvas().get_origin()
		# Obținem dimensiunea curentă a Viewport-ului (ecranului)
		var viewport_size = get_viewport_rect().size
		# Normalizăm poziția (o transformăm într-un număr între 0.0 și 1.0)
		var normalized_pos = player_global_pos / viewport_size
		
		# Trimitem coordonatele normalizate către Shader
		material.set_shader_parameter("player_screen_pos", normalized_pos)
