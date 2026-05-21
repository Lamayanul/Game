extends TileMapLayer

var affected_tile_datas: Array[TileData] = []
@onready var player= get_node("/root/world/player")


func _ready() -> void:
	#set_collisions_enabled(self,false)
	# Colectăm toate obiectele TileData care au proprietatea "jos_perete"
	# Căutăm în TileSet-ul acestui strat și în straturile vecine/copii
	_collect_from_layer(self)
	if get_parent():
		for child in get_parent().get_children():
			if child is TileMapLayer:
				_collect_from_layer(child)

func _collect_from_layer(layer: TileMapLayer) -> void:
	var ts = layer.tile_set
	if not ts: return
	
	var custom_data_index = -1
	for i in range(ts.get_custom_data_layers_count()):
		if ts.get_custom_data_layer_name(i) == "jos_perete":
			custom_data_index = i
			break
			
	if custom_data_index == -1: return

	for s_index in range(ts.get_source_count()):
		var source_id = ts.get_source_id(s_index)
		var source = ts.get_source(source_id)
		if source is TileSetAtlasSource:
			for i in range(source.get_tiles_count()):
				var coords = source.get_tile_id(i)
				# Verificăm toate alternativele posibile
				for alt_idx in range(source.get_alternative_tiles_count(coords)):
					var alt_id = source.get_alternative_tile_id(coords, alt_idx)
					var data = source.get_tile_data(coords, alt_id)
					if data and data.get_custom_data("jos_perete") == true:
						if not data in affected_tile_datas:
							affected_tile_datas.append(data)

func set_collisions_enabled(node: Node, enabled: bool) -> void:
	if node.name== "usa_perete_jos":
		return
	if node is TileMapLayer:
		node.collision_enabled = enabled
	if node is CollisionObject2D:
		node.set_deferred("monitoring", enabled)
		node.set_deferred("monitorable", enabled)
		for child in node.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", !enabled)
	for child in node.get_children():
		set_collisions_enabled(child, enabled)
		
func _on_usa_perete_sus_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Când jucătorul intră în zona ușii, vrem să vedem interiorul (este sub perete)
		player.este_transparent = true
		actualizează_stare_vizibilitate()
				
func _on_usa_perete_sus_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Verificăm unde se află jucătorul când părăsește zona ușii.
		# Trebuie să ținem cont de poziția reală a "picioarelor" jucătorului (coliziunea),
		# nu doar de originea nodului (care e mai sus).
		var player_y = body.global_position.y
		if body.has_node("colisiune"):
			player_y += body.get_node("colisiune").position.y
			
		# Dacă picioarele jucătorului sunt sub ușă (Y mai mare), înseamnă că a ieșit afară
		if player_y > $usa_perete_jos.global_position.y:
			player.este_transparent = false
		else:
			# Altfel, este înăuntru
			player.este_transparent = true
		actualizează_stare_vizibilitate()
			
func actualizează_stare_vizibilitate() -> void:
	if player.este_transparent and player.is_high==false:
		aplică_vizibilitate(0.5, true)
		visible = true
		get_node("/root/world/TileMap/cliff-H").modulate = Color(1,1,1,0.5)
	else:
		aplică_vizibilitate(1.0, false)
		visible = false
		get_node("/root/world/TileMap/cliff-H").modulate = Color(1,1,1,1)

func aplică_vizibilitate(alpha: float, coliziuni_active: bool) -> void:
	for data in affected_tile_datas:
		if player.is_high==false:
			data.modulate.a = alpha
			
	set_collisions_enabled(self, coliziuni_active)
