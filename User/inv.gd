extends PanelContainer

#------------------------------grid-uri--------------------------------------------------------------
@onready var grid_container = $MarginContainer/GridContainer
@onready var grid = $"../../TileMap/Grid_ogor"  # Referința la grid

#-------------------------------diverse---------------------------------------------------------------
@onready var texture_rect = $MarginContainer/TextureRect
@export var plin:int =0
@onready var info_label = $"../InfoLabel"
@onready var hand_sprite = $"../PanelContainer/Sprite2D/item_mana/sprite"
@onready var color_rect = $"../ColorRect"

#--------------------------noduri-principale--------------------------------------------------------
var selected_slot: Slot = null  # Slotul selectat
@onready var tilemap = $"../../TileMap"
@onready var player = $"../../player"

#-----------------------------Semnale----------------------------------------------------------------
signal plantSeed
signal attacking

#---------------------------------------add_item()-----------------------------------------------------
func add_item(ID="", item_cantita=1):
	var item_texture = load("res://assets/" + ItemData.get_texture(ID))
	var item_nume=ItemData.get_nume(ID)
	var item_number = ItemData.get_number(ID)
	var item_cantitate=item_cantita
	print("cantitate: ", item_cantitate)
	var item_data = {"TEXTURE": item_texture, "CANTITATE": item_cantitate, "NUMBER": item_number,"NUME":item_nume}
	if ID=="0":
		item_cantitate=0
	# 1. Verifică dacă există deja un item cu același ID în inventar
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot:
			if child.filled and child.get_id() == ID:
				# 2. Stivuiește itemele dacă găsești un slot cu același ID
				child.cantitate += item_cantitate
				child.set_property({"TEXTURE": item_texture, "CANTITATE": child.cantitate, "NUMBER": item_number,"NUME":item_nume})
				plin=plin
			
				return
	
	# 3. Dacă nu există un slot cu același ID, caută un slot gol și adaugă itemul acolo
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot:
			if not child.filled:
				child.set_property(item_data)
				child.filled = true
				plin+=1
				return
	# Dacă inventarul este plin și nu există sloturi libere
	print("Inventarul este plin!")


#--------------------------------_ready()----------------------------------------------------------------
func _ready():
	for child in grid_container.get_children():
		if child is Slot:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))

	
	  # Selectează automat primul slot
	if grid_container.get_child_count() > 0:
		var first_slot = grid_container.get_child(0)
		if first_slot is Slot:
			_on_slot_selected(first_slot)
	$"../../Item7".item_cantitate=3


#-----------------------------------selectie-slot----------------------------------------------------
func _on_slot_selected(slot: Slot):
	if selected_slot:
		selected_slot.deselect() 
	selected_slot = slot  
	selected_slot.select()

	hand_sprite.texture = null
	info_label.clear()
	color_rect.visible = false
	info_label.visible = false
	
	
	# Dacă slotul selectat are un item (este plin), actualizează sprite-ul și eticheta
	if slot.get_texture() != null:

		hand_sprite.texture = slot.get_texture()
		hand_sprite.visible = true
		hand_sprite.scale = Vector2(0.5, 0.5)
		
		info_label.text = "[center]ITEM: " + slot.get_nume() + "[/center]"
		info_label.visible = false
		color_rect.visible = false

	# Actualizează poziția selectorului
	update_selector_position(slot)
	
	# Echipează itemul la jucător
	#var player = get_node("/root/world/player")
	if player and slot.get_texture() != null:
		player.equip_item(slot.get_texture(), slot.get_nume())
	


func update_selector_position(slot: Slot):
	var slot_position = slot.get_global_position()
	texture_rect.global_position = slot_position


#---------------------------------------input-uri-diverse----------------------------------------------------
func _input(_event):
	if Input.is_action_just_pressed("drop"):
		drop_selected_item()
	if Input.is_action_just_pressed("drop_1"):
		drop_selected_item_1()
	if Input.is_action_just_pressed("plantSeed"):
		plantare()
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("eat"):
		eat()


#---------------------------------drop-item-selected-----------------------------------------------------
func drop_selected_item():
	print("Funcția drop_selected_item a fost apelată")
	if selected_slot:
		var ID = selected_slot.get_id()  # Obține ID-ul itemului din slotul selectat
		if ID == "0":
			selected_slot.clear_item()
		if ID:
			print("ID-ul itemului este: ", ID)
			#var item_cantitate = selected_slot.get_cantitate()
			#var cantitate_de_drop = 1  # Cantitatea pe care vrei să o dai la drop
			#var player = get_node("/root/world/player")
			
			# Obține poziția mouse-ului în coordonate globale
			#var mouse = get_global_mouse_position()
			var _world = get_node("/root/world/")
			var cantiti=selected_slot.get_cantitate()
			# Convertește coordonatele mouse-ului în coordonatele locale ale TileMap
			#var mouse_position_global = get_viewport().get_mouse_position()
			#var mouse_position_local = world.to_local(mouse_position_global)
			# Drop itemul la poziția exactă a mouse-ului

			drop_item(ID,cantiti)
			
			#print("Poziția calculată pentru drop: ", drop_position)
			
			# Curăță și deselectează slotul
			selected_slot.clear_item()
			selected_slot.deselect()
			selected_slot = null  # Deselectează slotul după drop
		
			update_inventory_status()
			print(plin)
			
			player.inequip_item()
			
			
			
		else:
			print("ID-ul itemului nu a fost găsit în slotul selectat.")
	else:
		print("Niciun slot nu este selectat")
		
func update_inventory_status():
	plin = 0
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot and child.filled:
			plin += 1



#--------------------------------functie-drop-default--------------------------------------------------
func drop_item(ID: String, cantiti: int):
	# Obține textura și cantitatea din ItemData
	if cantiti==0:
		return
	var item_cantitate = cantiti
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	
	# Încarcă scena itemului
	var item_scene = load("res://User/item.tscn") as PackedScene
	if item_scene:
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		
		item_instance.ID = ID
		var player_position = player.global_position
		var player_direction = player.last_direction.normalized()  # Direcția „în față”
		var drop_distance = 20  # Ajustează distanța conform nevoilor tale
		var drop_position = player_position + (player_direction * drop_distance)
		
		item_instance.position = drop_position 
		world_node.add_child(item_instance)
		
	
#-----------------------------------drop-pt-cate-un-item----------------------------------------------
func drop_selected_item_1():
	print("Funcția drop_selected_item_1 a fost apelată")
	if selected_slot:
		var ID = selected_slot.get_id()  # Obține ID-ul itemului din slotul selectat
		if ID == "0":
			selected_slot.clear_item()
		if ID:
			print("ID-ul itemului este: ", ID)
			#var item_cantitate = selected_slot.get_cantitate()
			var cantitate_de_drop = 1  # Cantitatea pe care vrei să o dai la drop
			# Obține poziția mouse-ului în coordonate globale
			var mouse_position = Vector2(100,100)
			var world = get_node("/root/world/")
			#var player = get_node("/root/world/player")
			#var cantiti=selected_slot.get_cantitate()
			# Convertește coordonatele mouse-ului în coordonatele locale ale TileMap
			var _local_mouse_position = world.to_local(mouse_position)
		
			if selected_slot.decrease_cantitate(cantitate_de_drop): 
				
				selected_slot.clear_item()
				selected_slot.deselect()
				selected_slot = null
				plin -= 1
				info_label.text=""
				player.inequip_item()  # Dez-echipează itemul
			
			if ID=="0":
				cantitate_de_drop=0
			
			drop_item(ID , cantitate_de_drop)
			#player.inequip_item() 
			update_inventory_status()
		else:
			print("ID-ul itemului nu a fost găsit în slotul selectat.")
	else:
		print("Niciun slot nu este selectat")


#----------------------------------apelare-plantare()-------------------------------------------------
func plantare():
	var _tilemap=get_node("/root/world/TileMap")
	if selected_slot:
		var ID=selected_slot.get_id()
		if ID=="3":
			emit_signal("plantSeed")

#---------------------select-arma-atac---------------------------------------------------------------
func attack():
	if selected_slot:
		var ID=selected_slot.get_id()
		if ID=="2" || ID=="9":
			emit_signal("attacking",ID)
		
#---------------------------harvest-drop------------------------------------------------------------
func drop_item_harvest(ID: String, cantiti: int,location:Vector2):
	# Obține textura și cantitatea din ItemData
	var item_cantitate = cantiti
	if cantiti==0:
		plin=0
		return
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	
	# Încarcă scena itemului
	var item_scene = load("res://User/item.tscn") as PackedScene
	if item_scene:
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		
		item_instance.ID = ID
		
		var global_position1=tilemap.map_to_local(location)
		item_instance.position = global_position1
		#drop_position=Vector2(100,100)
		# Folosește 'position' pentru coordonate locale
		#global_cantiti=cantiti
		world_node.add_child(item_instance)


#------------------------------------------functie-eat()-----------------------------------------------
func eat():
	# Verificăm dacă există un slot selectat
	if selected_slot == null:
		print("Nu ai selectat nimic în inventar!")
		return
	
	var slot = selected_slot  # Slotul selectat
	if slot is Slot and slot.filled:
		var ID = slot.get_id()
		
		if ID == "1" || ID=="8":  # Verificăm dacă itemul este de tip mâncare
			var cantitate_de_mancat = 1  # Cantitatea de mâncare consumată
			player.health += 10  # Creștem sănătatea jucătorului
			player.healthbar_player.value = player.health  # Actualizăm bara de sănătate
			if player.health > 100:  # Asigurăm că sănătatea nu trece peste 100
				player.health = 100 

			# Reducem cantitatea din item și dacă rămâne 0, golim slotul
			if slot.decrease_cantitate(cantitate_de_mancat):
				slot.clear_item()  # Golim slotul
				slot.deselect()  # Deselectăm slotul după ce itemul a fost consumat
				plin -= 1  # Reducem numărul de sloturi pline din inventar
				player.inequip_item()  # Scoatem itemul din echipare dacă era echipat
				print("Ai mâncat un item, viața ta a crescut.")
			return
	else:
		print("Slotul selectat nu conține mâncare!")

	print("Nu ai mâncare în inventar!")



#-------------------------------------drop-locatie-apropiata------------------------------------------
func drop_item_everywhere(ID: String, cantiti: int,location:Vector2):
	var item_cantitate = cantiti
	if cantiti==0:
		plin=0
		return
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	
	# Încarcă scena itemului
	var item_scene = load("res://User/item.tscn") as PackedScene
	if item_scene:
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		
		item_instance.ID = ID

		item_instance.position = location
		world_node.add_child(item_instance)
