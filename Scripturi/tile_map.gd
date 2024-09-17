extends TileMap


@onready var grid = $Grid
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var selected_slot: Slot = null  # Slotul selectat
@onready var player = get_node("/root/world/player")
var drop=1
var cell

var curentSeed=preload("res://Flowers/grau.tscn")
var plantedFlower:Dictionary={}



func _process(_delta):
	var mouse_pos = get_global_mouse_position()  # Obține poziția mouse-ului în coordonatele globale
	var grid_cell = local_to_map(mouse_pos)  # Convertește poziția mouse-ului la coordonatele TileMap-ului
	var tile_data = get_cell_tile_data(2, grid_cell)  # Obține datele tile-ului la poziția respectivă
	
	if tile_data != null and tile_data.get_custom_data("ogor"):  # Verifică dacă tile-ul este "ogor"
		grid.visible = true  # Afișează gridul
		grid.position = map_to_local(grid_cell)  # Plasează gridul pe tile-ul respectiv
	else:
		grid.visible = false  # Ascunde gridul
		grid.position = Vector2(-1, -1) 
	if Input.is_action_just_pressed("harvest"):
		if plantedFlower.has(local_to_map(grid.position)) and is_harvestable(local_to_map(grid.position)):
			print("da")
			harvest_plant(local_to_map(grid.position))

	

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
		
		
		

func plant_seed(coord)->void:
	if plantedFlower.has(coord):
		print("Seed already planted at: ", coord)
		return
	
	var plant=curentSeed.instantiate()
	print("Plant instance created:", plant)
	add_child(plant)
	plantedFlower[coord]=plant
	plant.position=map_to_local(coord)
