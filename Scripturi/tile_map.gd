extends TileMap
class_name tilemap

@onready var grid = $Grid_ogor
@onready var grid_land = $Grid_land
var last_direction = Vector2(0, 1)
@onready var animation_player=get_node_or_null("/root/world/player/AnimationPlayer")
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var selected_slot: Slot = null  
@onready var player = get_node_or_null("/root/world/player")
#@onready var seminte_grid: Sprite2D = $Seminte
var drop=1
var cell
var planting_mode = false
var curentSeed=preload("res://Flowers/grau.tscn")
var plantedFlower:Dictionary={}
var plantedGard:Dictionary={}
@onready var animatie_sapa: Timer = $animatie_sapa
#@onready var hido = $"../hide"
var placing_gard_mode = false  
var placing_house=false
@export var gard_tile_id: int = 3  
@onready var grid_gard = $Grid_gard
@onready var arma_colisiune= get_node_or_null("/root/world/player/arma/arma_colisiune")
@onready var grid_house: Sprite2D = $Grid_house
var house_tiles = [Vector2(0,0), Vector2(0,1), Vector2(0,2),Vector2(1,0),Vector2(1,2),Vector2(2,0),Vector2(2,1),Vector2(2,2),Vector2(4,2),Vector2(3,2)] # Diferite variante de tile
var roof_tiles=[Vector2(0,0),Vector2(1,0),Vector2(2,0),Vector2(0,1),Vector2(1,1),Vector2(2,1),Vector2(0,2),Vector2(1,2),Vector2(2,2),Vector2(0,3),Vector2(1,3),Vector2(2,3),Vector2(0,4),Vector2(1,4),Vector2(2,4),]
var house_tile_index = 0  # Indexul tile-ului curent
var roof_tile_index=0
var extra_house_tiles = [Vector2(0,0), Vector2(5,0)] # Set nou de tile-uri
var extra_tile_index = 0  # Indexul pentru setul nou
var ogor_tile_tiles=[Vector2(1,1),Vector2(0,0),Vector2(0,1),Vector2(0,2),Vector2(1,0),Vector2(2,0),Vector2(2,1),Vector2(2,2),Vector2(1,2)]
var ogor_tile_index=0
var placing_podea=false
var placing_roof=false
@onready var fantana_bar = get_node_or_null("/root/world/Fantana/CanvasLayer/ProgressBar")



#-------------------------------_ready--------------------------------------------------------------------------
#func _ready():
	#grid_land.visible=false
	#grid_gard.visible = false
	#seminte_grid.visible=false


#-------------------------schimbare tile-uri + griduri---------------------------------------------------------------
func _process(_delta):
	watering_ogor()
	handle_grid_display()
	handle_gard_and_house_placement()
	handle_harvesting()
	#handle_roof_transparency()

	
func change_existing_house_tile(grid_cell: Vector2):
	if Input.is_action_pressed("shift"):  # Dacă ținem Shift, schimbăm tile-urile adiționale
		var selected_tile = extra_house_tiles[extra_tile_index]
		$items.set_cell(grid_cell, 13, selected_tile)  # Layer 13 pentru noul set de tile-uri
		print("Additional house tile modificat la varianta:", selected_tile, "la:", grid_cell)
	else:  # Dacă nu e Shift apăsat, schimbăm tile-urile normale

		var selected_tile = house_tiles[house_tile_index]
		$items.set_cell(grid_cell, 7, selected_tile)  
		print("House tile modificat la varianta:", selected_tile, "la:", grid_cell)




func change_existing_roof_tile(grid_cell: Vector2):
	var selected_tile = roof_tiles[roof_tile_index]
	$cliff.set_cell( grid_cell, 8, selected_tile)  
	print( "Roof tile modificat la varianta:", selected_tile, "la:", grid_cell)



func place_gard(grid_cell: Vector2):
	var tile_data_gard =$items. get_cell_tile_data(grid_cell)
	if tile_data_gard != null:
		print("Gardul nu poate fi plasat aici, există deja un gard la poziția:", grid_cell)
		return 
	var tile_data_land =$land. get_cell_tile_data( grid_cell)
	if  tile_data_land != null and tile_data_land.get_custom_data("land-gard"):
	
		$items.set_cell( grid_cell, 5, Vector2(0, 3))  # Plasează gardul
		$items.set_cells_terrain_connect( [grid_cell], 1 ,0,true) 
		print("Gard plasat la:", grid_cell)
		inventory.selected_slot.decrease_cantitate(1)
	
func place_gard_deal(grid_cell: Vector2):
	var tile_data_gard = $"cliff-H".get_cell_tile_data( grid_cell)
	if tile_data_gard != null:
		print("Gardul nu poate fi plasat aici, există deja un gard la poziția:", grid_cell)
		return 
	var tile_data_cliff_gard =$cliff.get_cell_tile_data( grid_cell)
	if  tile_data_cliff_gard != null and tile_data_cliff_gard.get_custom_data("place_gard_deal"):
	
		$"cliff-H".set_cell( grid_cell, 12, Vector2(0, 3))  # Plasează gardul
		$"cliff-H".set_cells_terrain_connect( [grid_cell], 2 ,0,true) 
		print("Gard plasat la:", grid_cell)
		inventory.selected_slot.decrease_cantitate(1)

func place_house(grid_cell: Vector2):
	print("house")
	var tile_data = $items.get_cell_tile_data( grid_cell)
	if tile_data != null:
		print("House nu poate fi plasat aici, există deja un gard la poziția:", grid_cell)
		return 
	var tile_data_house = $land.get_cell_tile_data( grid_cell)
	if  tile_data_house != null and tile_data_house.get_custom_data("house"):
	
		$items.set_cell( grid_cell, 7, Vector2(1, 2))  # Plasează gardul

		print("House plasat la:", grid_cell)
		inventory.selected_slot.decrease_cantitate(1)

func place_podea(grid_cell: Vector2):
	print("house")
	var tile_data = $ogor.get_cell_tile_data( grid_cell)
	if tile_data != null:
		print("House nu poate fi plasat aici, există deja un gard la poziția:", grid_cell)
		return 
	var tile_data_house = $land.get_cell_tile_data( grid_cell)
	if  tile_data_house != null and tile_data_house.get_custom_data("floor"):
	
		$ogor.set_cell( grid_cell, 7, Vector2(1, 1))  # Plasează gardul

		print("Podea plasat la:", grid_cell)
		inventory.selected_slot.decrease_cantitate(1)


func place_roof(grid_cell: Vector2):
	var tile_data = $cliff.get_cell_tile_data( grid_cell)
	if tile_data != null:
		print("House nu poate fi plasat aici, există deja un gard la poziția:", grid_cell)
		return 
	var tile_data_roof = $cliff.get_cell_tile_data( grid_cell)
	if  tile_data_roof == null :
	
		$cliff.set_cell( grid_cell, 8, Vector2(0, 2))  # Plasează gardul

		print("House plasat la:", grid_cell)
		inventory.selected_slot.decrease_cantitate(1)





func remove_gard(grid_cell:Vector2):
	set_cell(3, grid_cell, -1)
	set_cell(4, grid_cell, -1)
	

	

#------------------------------schimbare tile din land in ogor--------------------------------------------------------
func replace_land_with_ogor(grid_cell: Vector2):
	#var tile_data_land = $land.get_cell_tile_data( grid_cell)
	#if tile_data_land != null and tile_data_land.get_custom_data("land"):
		#$ogor.set_cell(grid_cell,2,Vector2(1,1))
		#$ogor.set_cells_terrain_connect( [grid_cell], 0 ,0,true)  
		#print("Tile-ul de 'ogor' a fost plantat la:", grid_cell)
	var ogor_data_tiles = $land.get_cell_tile_data( grid_cell)  # Check the house tile layer (layer 3)
	if ogor_data_tiles != null and ogor_data_tiles.get_custom_data("land"): 
		ogor_tile_index = (ogor_tile_index + 1) % ogor_tile_tiles.size()
		var selected_tile = ogor_tile_tiles[ogor_tile_index]
		$ogor.set_cell( grid_cell, 2, selected_tile)  
		print( "Ogor tile modificat la varianta:", selected_tile, "la:", grid_cell)
		Persistence.saved_ogor_tiles.append({
			"pos": grid_cell,
			"tile": selected_tile
		})

func watering_ogor():
	var cellLocalCoord=local_to_map(grid.position)
	var tile:TileData=$ogor.get_cell_tile_data(cellLocalCoord)
	if tile==null  or curentSeed==null:
		return
	if tile.get_custom_data("ogor") and fantana_bar.value>=0:
		if plantedFlower.has(cellLocalCoord):
			if inventory.selected_slot:
				var ID=inventory.selected_slot.get_id()
				if ID=="22" and player.farming_on and player:
					var player_position = player.global_position
					var player_direction = player.last_direction.normalized()  # Direcția „în față”
					var drop_distance = 10  # Ajustează distanța conform nevoilor tale
					var _drop_position = player_position + (player_direction * drop_distance)#####################
					var mouse_pos = player_position + (player_direction * drop_distance)  # Obține poziția mouse-ului în coordonatele globale
					var grid_cell = local_to_map(mouse_pos)
					$ogor.set_cell( grid_cell, 14, Vector2(0,0))  
					$umezeala.start()
#----------------------------------plantare plante-----------------------------------------------------------
func _on_player_plant_seed():
	var cellLocalCoord=local_to_map(grid.position)
	var tile:TileData=$ogor.get_cell_tile_data(cellLocalCoord)
	cell=cellLocalCoord
	if tile==null  or curentSeed==null:
		return
		
	if tile.get_custom_data("ogor"):
		if plantedFlower.has(cellLocalCoord):
			print("A plant already exists at:", cellLocalCoord)
			return  
		plant_seed(cellLocalCoord)
		
	if inventory.selected_slot!=null:
		print(inventory.selected_slot)
		if inventory.selected_slot.decrease_cantitate(drop): 
			inventory.selected_slot.clear_item()
			inventory.selected_slot.deselect()
			inventory.selected_slot = null
			inventory.plin-=1
			player.inequip_item()


func plant_seed(coord)->void:
	if plantedFlower.has(coord):
		print("Seed already planted at: ", coord)
		return
	
	var plant=curentSeed.instantiate()
	print("Plant instance created:", plant)
	add_child(plant)
	plantedFlower[coord]=plant
	plant.position=map_to_local(coord)




#------------------------------harvest plante---------------------------------------------------------------------
func is_harvestable(coord)->bool:
	var plant = plantedFlower.get(coord)
	print("harvest",coord)
	print(plant)
	if plant != null:
		return plant.harvest_ready 
	return false
	
	
func harvest_plant(coord)->void:
	var plant:Flower=plantedFlower.get(coord)
	print(coord)
	if plant.has_method("harvest"):
		plant.harvest()
		plantedFlower.erase(coord)
		plant.queue_free()
		print("Plant harvested at:", coord)
		#inventory.add_item("4",2)
		inventory.drop_item_harvest("4",2,coord)
		
		
func _on_animatie_sapa_timeout() -> void:
	animation_player.stop()
	animatie_sapa.stop()


func _on_umezeala_timeout() -> void:
	var cellLocalCoord=local_to_map(grid.position)
	var tile:TileData=$ogor.get_cell_tile_data(cellLocalCoord)
	if tile:
		if tile.get_custom_data("umed") and player:
			var player_position = player.global_position
			var player_direction = player.last_direction.normalized()  # Direcția „în față”
			var drop_distance = 10  # Ajustează distanța conform nevoilor tale
			var _drop_position = player_position + (player_direction * drop_distance)#####################
			var mouse_pos = player_position + (player_direction * drop_distance)  # Obține poziția mouse-ului în coordonatele globale
			var grid_cell = local_to_map(mouse_pos)
			print("nu merge")
			$ogor.set_cell( grid_cell, 2, Vector2(1,1))  

func handle_grid_display():
	if not is_instance_valid(player):
		return
	var player_position = player.global_position
	var player_direction = player.last_direction.normalized()
	var drop_distance = 10
	var mouse_pos = player_position + (player_direction * drop_distance)
	var grid_cell = local_to_map(mouse_pos)
	var tile_data = $ogor.get_cell_tile_data(grid_cell)
	var tile_data_land = $land.get_cell_tile_data(grid_cell)

	grid.visible = false
	grid_land.visible = false
	grid_gard.visible = false

	if tile_data != null and tile_data.get_custom_data("ogor"):
		grid.visible = true
		grid.position = map_to_local(grid_cell)
	else:
		grid.position = Vector2(-1, -1)

	if tile_data_land != null and tile_data_land.get_custom_data("land") and not grid.visible:
		grid_land.position = map_to_local(grid_cell)
	else:
		grid_land.position = Vector2(-1, -1)

func handle_gard_and_house_placement():
	if not is_instance_valid(player):
		return
	if not inventory.selected_slot:
		grid_gard.visible = false
		placing_gard_mode = false
		grid_house.visible = false
		placing_house = false
		placing_podea = false
		placing_roof = false
		return

	var player_position = player.global_position
	var player_direction = player.last_direction.normalized()
	var drop_distance = 10
	var mouse_pos = player_position + (player_direction * drop_distance)
	var grid_cell = local_to_map(mouse_pos)
	var selected_id = inventory.selected_slot.get_id()

	if selected_id == "12":
		grid_gard.visible = true
		grid_gard.position = map_to_local(grid_cell)
		placing_gard_mode = true
	else:
		grid_gard.visible = false
		placing_gard_mode = false

	if selected_id in ["6", "16", "17"]:
		grid_house.visible = true
		grid_house.position = map_to_local(grid_cell)
		placing_house = selected_id == "6"
		placing_podea = selected_id == "16"
		placing_roof = selected_id == "17"
	else:
		grid_house.visible = false
		placing_house = false
		placing_podea = false
		placing_roof = false

	handle_house_and_gard_input(grid_cell)
	
func handle_house_and_gard_input(grid_cell):
	if placing_house and Input.is_action_just_pressed("cycle_house"):
		var tile_data_house = $items.get_cell_tile_data(grid_cell)
		if tile_data_house != null and tile_data_house.get_custom_data("house"):
			house_tile_index = (house_tile_index + 1) % house_tiles.size()
			change_existing_house_tile(grid_cell)

	if placing_roof and Input.is_action_just_pressed("cycle_house"):
		var tile_data_roof = $cliff.get_cell_tile_data(grid_cell)
		if tile_data_roof != null and tile_data_roof.get_custom_data("roof"):
			roof_tile_index = (roof_tile_index + 1) % roof_tiles.size()
			change_existing_roof_tile(grid_cell)

	if placing_house and Input.is_action_just_pressed("cycle_house"):
		var tile_data_extra = $items.get_cell_tile_data(grid_cell)
		if tile_data_extra != null and tile_data_extra.get_custom_data("extra"):
			extra_tile_index = (extra_tile_index + 1) % extra_house_tiles.size()
			change_existing_house_tile(grid_cell)

	if Input.is_action_just_pressed("place_gard"):
		if placing_gard_mode:
			place_gard(grid_cell)
			place_gard_deal(grid_cell)
		elif placing_house:
			place_house(grid_cell)
		elif placing_podea:
			place_podea(grid_cell)
		elif placing_roof:
			place_roof(grid_cell)

func handle_harvesting():
	if Input.is_action_just_pressed("harvest"):
		var celll = local_to_map(grid.position)
		if plantedFlower.has(celll) and is_harvestable(celll):
			harvest_plant(celll)

#func handle_roof_transparency():
	#if not is_instance_valid(player):
		#return
	#var player_pos = player.global_position
	#var player_cell = local_to_map(player_pos)
	#var tile_data_player = $cliff.get_cell_tile_data(player_cell)
	#if tile_data_player and tile_data_player.get_custom_data("roof"):
		#$cliff.modulate = Color(1, 1, 1, 0.3)
	#else:
		#$cliff.modulate = Color(1, 1, 1, 1)
