extends TileMap
class_name tilemap

@onready var grid = $Grid_ogor
@onready var grid_land = $Grid_land
var last_direction = Vector2(0, 1)
@onready var animation_player=get_node("/root/world/player/AnimationPlayer")
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var selected_slot: Slot = null  
@onready var player = get_node("/root/world/player")
var drop=1
var cell
var planting_mode = false
var curentSeed=preload("res://Flowers/grau.tscn")
var plantedFlower:Dictionary={}
@onready var animatie_sapa: Timer = $animatie_sapa
@onready var hido = $"../hide"
var placing_gard_mode = false  
@export var gard_tile_id: int = 3  
@onready var grid_gard = $Grid_gard



#-------------------------------_ready--------------------------------------------------------------------------
func _ready():
	grid_land.visible=false
	grid_gard.visible = false



#-------------------------schimbare tile-uri + griduri---------------------------------------------------------------
func _process(_delta):
	if player and is_instance_valid(player):
		var player_position = player.global_position
		var player_direction = player.last_direction.normalized()  # Direcția „în față”
		var drop_distance = 10  # Ajustează distanța conform nevoilor tale
		var _drop_position = player_position + (player_direction * drop_distance)#####################
		var mouse_pos = player_position + (player_direction * drop_distance)  # Obține poziția mouse-ului în coordonatele globale
		var grid_cell = local_to_map(mouse_pos)  # Convertește poziția mouse-ului la coordonatele TileMap-ului

		# Obținem datele pentru ambele straturi de tile-uri (2 = "ogor", 1 = "land")
		var tile_data = get_cell_tile_data(2, grid_cell)  # Stratul pentru "ogor"
		var tile_data_land = get_cell_tile_data(1, grid_cell)  # Stratul pentru "land"
		var tile_data_gard = get_cell_tile_data(3, grid_cell)

		# Resetăm vizibilitatea gridurilor
		grid.visible = false
		grid_land.visible = false
		grid_gard.visible=false

		# Verificăm întâi dacă tile-ul este de tip "ogor"
		if tile_data != null and tile_data.get_custom_data("ogor"):
			grid.visible = true  # Afișăm grid-ul pentru "ogor"
			grid.position = map_to_local(grid_cell)  # Plasăm grid-ul pe tile-ul "ogor"
		else:
			grid.position = Vector2(-1, -1)  # Ascundem grid-ul pentru "ogor"
			
		
		if tile_data_land != null and tile_data_land.get_custom_data("land") and not grid.visible:
			#grid_land.visible = true  #gridul de land
			grid_land.position = map_to_local(grid_cell)  # Plasăm grid-ul pe tile-ul "land"
		else:
			grid_land.position = Vector2(-1, -1)  # Ascundem grid-ul pentru "land"
			
		  # Adaugă "plant_ogor" în Input Map
		planting_mode = true
		if inventory.selected_slot:
			var ID=inventory.selected_slot.get_id()
			if ID=="9":
				grid_land.visible=true
				if planting_mode and grid_land.visible and hido.can_plant==true and Input.is_action_just_pressed("plant_ogor"):
					inventory.attack()
					#animatie_sapa.start() ------------------------probleme de timing
					replace_land_with_ogor(grid_cell)
					planting_mode = false 
				
			
		if Input.is_action_just_pressed("harvest"):
			if plantedFlower.has(local_to_map(grid.position)) and is_harvestable(local_to_map(grid.position)):
				print("da")
				harvest_plant(local_to_map(grid.position))

		if inventory.selected_slot and inventory.selected_slot.get_id() == "12": # Folosim ID-ul itemului gard
			grid_gard.visible = true
			grid_gard.position = map_to_local(grid_cell)
			placing_gard_mode = true
		else:
			grid_gard.visible = false
			placing_gard_mode = false

			
		if Input.is_action_just_pressed("place_gard") and placing_gard_mode:
			place_gard(grid_cell)
			
func place_gard(grid_cell: Vector2):
		set_cell(3, grid_cell, 5, Vector2(0, 3))  # Plasează gardul
		set_cells_terrain_connect(4, [grid_cell], 0 ,0,true) 
		print("Gard plasat la:", grid_cell)
		inventory.selected_slot.decrease_cantitate(1)
		
		


#------------------------------schimbare tile din land in ogor--------------------------------------------------------
func replace_land_with_ogor(grid_cell: Vector2):
	var tile_data_land = get_cell_tile_data(1, grid_cell)

	if tile_data_land != null and tile_data_land.get_custom_data("land"):
		set_cell(2,grid_cell,2,Vector2(1,1))
		set_cells_terrain_connect(2, [grid_cell], 0 ,0,true)  
		print("Tile-ul de 'ogor' a fost plantat la:", grid_cell)



#----------------------------------plantare plante-----------------------------------------------------------
func _on_player_plant_seed():
	var cellLocalCoord=local_to_map(grid.position)
	var tile:TileData=get_cell_tile_data(2,cellLocalCoord)
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
