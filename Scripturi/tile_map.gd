extends TileMap


@onready var grid = $Grid
@onready var player = $"../player"
var selected_slot: Slot = null
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var pos:Vector2
var suprapune:Vector2


var curentSeed=preload("res://Flowers/grau.tscn")
var plantedFlower:Dictionary={}


func _process(_delta):
	var mouse_pos = get_global_mouse_position()  # Obține poziția mouse-ului în coordonatele globale
	var grid_cell = local_to_map(mouse_pos)  # Convertește poziția mouse-ului la coordonatele TileMap-ului
	var tile_data = get_cell_tile_data(2, grid_cell)  # Obține datele tile-ului la poziția respectivă
	
	if tile_data != null and tile_data.get_custom_data("ogor"):  # Verifică dacă tile-ul este "ogor"
		grid.visible = true  # Afișează gridul
		grid.position = map_to_local(grid_cell)  # Plasează gridul pe tile-ul respectiv
		pos=grid_cell
	else:
		grid.visible = false  # Ascunde gridul


func _on_player_plant_seed():
	var cellLocalCoord=local_to_map(grid.position)
	var tile:TileData=get_cell_tile_data(2,cellLocalCoord)
	
	if tile==null  or curentSeed==null:
		return
		
	if tile.get_custom_data("ogor"):
		if plantedFlower.has(cellLocalCoord):
			return
		plant_seed(cellLocalCoord)
		
		#if selected_slot.decrease_cantitate(1): 
			#selected_slot.clear_item()
			#selected_slot.deselect()
			#selected_slot = null
			#var player = get_node("/root/world/player")
			#player.inequip_item()

func plant_seed(coord)->void:
	if plantedFlower.has(coord):
		return
	
	var plant=curentSeed.instantiate()
	add_child(plant)
	plantedFlower[coord]=plant
	plant.position=map_to_local(coord)
