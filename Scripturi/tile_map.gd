extends TileMap


@onready var grid = $Grid
@onready var player = $"../player"


func _process(_delta):
	var mouse_pos = get_global_mouse_position()  # Obține poziția mouse-ului în coordonatele globale
	var grid_cell = local_to_map(mouse_pos)  # Convertește poziția mouse-ului la coordonatele TileMap-ului
	var tile_data = get_cell_tile_data(2, grid_cell)  # Obține datele tile-ului la poziția respectivă
	
	if tile_data != null and tile_data.get_custom_data("ogor"):  # Verifică dacă tile-ul este "ogor"
		grid.visible = true  # Afișează gridul
		grid.position = map_to_local(grid_cell)  # Plasează gridul pe tile-ul respectiv
	else:
		grid.visible = false  # Ascunde gridul


#func _on_player_plant_seed():
#	var cellLocalCoord=local_to_map(grid.position)
#	var tile:TileData=get_cell_tile_data(2,cellLocalCoord)
