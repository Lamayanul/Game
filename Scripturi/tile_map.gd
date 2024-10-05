extends TileMap


@onready var grid = $Grid_ogor
@onready var grid_land = $Grid_land

@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var selected_slot: Slot = null  
@onready var player = get_node("/root/world/player")
var drop=1
var cell
var planting_mode = false
var curentSeed=preload("res://Flowers/grau.tscn")
var plantedFlower:Dictionary={}


#-------------------------------_ready--------------------------------------------------------------------------
func _ready():
	grid_land.visible=false



#-------------------------schimbare tile-uri + griduri---------------------------------------------------------------
func _process(_delta):
	var mouse_pos = get_global_mouse_position()  # Obține poziția mouse-ului în coordonatele globale
	var grid_cell = local_to_map(mouse_pos)  # Convertește poziția mouse-ului la coordonatele TileMap-ului

	# Obținem datele pentru ambele straturi de tile-uri (2 = "ogor", 1 = "land")
	var tile_data = get_cell_tile_data(2, grid_cell)  # Stratul pentru "ogor"
	var tile_data_land = get_cell_tile_data(1, grid_cell)  # Stratul pentru "land"

	# Resetăm vizibilitatea gridurilor
	grid.visible = false
	grid_land.visible = false

	# Verificăm întâi dacă tile-ul este de tip "ogor"
	if tile_data != null and tile_data.get_custom_data("ogor"):
		grid.visible = true  # Afișăm grid-ul pentru "ogor"
		grid.position = map_to_local(grid_cell)  # Plasăm grid-ul pe tile-ul "ogor"
	else:
		grid.position = Vector2(-1, -1)  # Ascundem grid-ul pentru "ogor"
		
	
	if tile_data_land != null and tile_data_land.get_custom_data("land") and not grid.visible:
		grid_land.visible = false  #gridul de land
		grid_land.position = map_to_local(grid_cell)  # Plasăm grid-ul pe tile-ul "land"
	else:
		grid_land.position = Vector2(-1, -1)  # Ascundem grid-ul pentru "land"
		
	  # Adaugă "plant_ogor" în Input Map
	planting_mode = true
		
	if planting_mode and grid_land.visible and Input.is_action_just_pressed("plant_ogor"):
		# Înlocuiește tile-ul de "land" cu un tile de "ogor"
		replace_land_with_ogor(grid_cell)
		planting_mode = false  # Dezactivăm modulul de plantare după plantare
		
	if Input.is_action_just_pressed("harvest"):
		if plantedFlower.has(local_to_map(grid.position)) and is_harvestable(local_to_map(grid.position)):
			print("da")
			harvest_plant(local_to_map(grid.position))



#------------------------------schimbare tile din land in ogor--------------------------------------------------------
func replace_land_with_ogor(grid_cell: Vector2):
	# Asigură-te că coordonatele sunt corecte și că tile-ul este de tip "land"
	var tile_data_land = get_cell_tile_data(1, grid_cell)

	
	if tile_data_land != null and tile_data_land.get_custom_data("land"):
		# Eliminăm tile-ul de "land" de pe stratul de "land" (Layer 1)
		#set_cell(1, grid_cell, -1)  # -1 înseamnă că tile-ul este șters
		
		# Plasăm tile-ul de "ogor" pe stratul de "ogor" (Layer 2)
		set_cell(2,grid_cell,2,Vector2(1,1))
		set_cells_terrain_connect(2, [grid_cell], 0 ,0,true)  # Înlocuiește cu ID-ul corect pentru tile-ul de "ogor"
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
			return  # Ieși din funcție pentru a evita plantarea din nou
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
		return plant.harvest_ready  # Sau metoda din clasa plantei care verifică maturitatea
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
		
		
		
