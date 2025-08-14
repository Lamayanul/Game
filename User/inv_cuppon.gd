extends PanelContainer

#------------------------------grid-uri--------------------------------------------------------------
@onready var grid_container = $MarginContainer/GridContainer
@onready var grid = $"../../TileMap/Grid_ogor"  # Referința la grid



#-------------------------------diverse---------------------------------------------------------------
@onready var texture_rect = $MarginContainer/TextureRect
@export var plin:int =0
@onready var info_label = $"../PanelContainer/VBoxContainer".get_node("InfoLabel")
@onready var hand_sprite = $"../PanelContainer".get_node("sprite")
#@onready var color_rect = $"../ColorRect"

#--------------------------noduri-principale--------------------------------------------------------
var selected_slot: Slot_Cup = null  # Slotul selectat
@onready var tile_map = $"../../TileMap"
#@onready var player = $"../../player"
@onready var player = get_node_or_null("/root/world/player")
var timp_ramas=0
#@onready var label: Label = get_node("/root/world/CanvasLayer/Felinar/Label")
@onready var timer: Timer = $Timer
@onready var player_light = get_node_or_null("/root/world/player/PointLight2D")
#@onready var light: PointLight2D = $PointLight2D
#@onready var slot_container12: Slot = get_node("/root/world/CanvasLayer/Felinar/SlotContainer")
var id=""

var index=0
var buton = null
#-----------------------------Semnale----------------------------------------------------------------

signal plantSeed
signal attacking



#func instantiate_chest():
	#var world = get_node("/root/world")
	#chest = chest_scene.instantiate()
	#chest.position = Vector2(40, 0)
	#world.add_child.call_deferred(chest)
#
	## La fel, după ce adaugi în scenă, poți accesa copiii
	#slot_container_chest = chest.get_node("CanvasLayer/GridContainer/SlotContainer")
	#slot_container_chest_2 = chest.get_node("CanvasLayer/GridContainer/SlotContainer2")
	#slot_container_chest_3 = chest.get_node("CanvasLayer/GridContainer/SlotContainer3")
	#slot_container_chest_4 = chest.get_node("CanvasLayer/GridContainer/SlotContainer4")
	#
#func instantiate_oven():
	#oven = oven_scene.instantiate()
	#oven.position = Vector2(200, 200)
	#add_child(oven)
#
	## Acum că oven e în scenă, poți accesa nodurile din interiorul lui
	#slot_container_5 = oven.get_node("CanvasLayer/Recipe/HBoxContainer/SlotContainer5")
	#slot_container_6 = oven.get_node("CanvasLayer/Recipe/HBoxContainer/SlotContainer")
	#slot_container_7 = oven.get_node("CanvasLayer/Recipe/HBoxContainer/SlotContainer2")
	#
	#
#func instantiate_pillar():
	#var world = get_node("/root/world")
	#pillar = pillar_scene.instantiate()
	#pillar.position = Vector2(280, 50)+Vector2(index+5,index)
	#index-=5
	#world.add_child.call_deferred(pillar)
	#slot_container_8= pillar.get_node("CanvasLayer/GridContainer/SlotContainer")
	#slot_container_9 = pillar.get_node("CanvasLayer/GridContainer/SlotContainer2")
#
#
#func instantiate_generator():
	#var world = get_node("/root/world")
	#gen = gen_scene.instantiate()
	#gen.position = Vector2(300, 30)+Vector2(0,index)
	#index-=40
	#world.add_child.call_deferred(gen)


#---------------------------------------add_item()-----------------------------------------------------
func add_item(ID="", item_cantita=1) -> bool:
	
	var item_texture = load("res://assets/" + DatabaseCuppon.get_texture(ID))
	var item_nume = DatabaseCuppon.get_nume(ID)
	var item_number = DatabaseCuppon.get_number(ID)
	var item_cantitate = item_cantita
	var item_raritate = DatabaseCuppon.get_raritate(ID)
	var item_data = {"TEXTURE": item_texture, "CANTITATE": item_cantitate, "NUMBER": item_number, "NUME": item_nume, "RARITATE":item_raritate}

	#print("Încerc să adaug item ID:", ID, " Cantitate:", item_cantitate)

	# 1. Încearcă să stivuiască itemul dacă există deja în inventar
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot_Cup:
			#print("Slot", i, " - ID:", child.get_id(), " Filled:", child.filled)
			if child.filled and child.get_id() == ID:
				#print("Item găsit în slot", i, ". Stivuiesc...")
				child.cantitate += item_cantitate
				child.set_property({"TEXTURE": item_texture, "CANTITATE": child.cantitate, "NUMBER": item_number, "NUME": item_nume, "RARITATE":item_raritate})
				return true  # A reușit să adauge obiectul, returnează `true`
	
	# 2. Dacă nu există un slot cu același ID, caută un slot gol
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot_Cup:
			#print("Verific slot gol:", i, " - Filled:", child.filled)
			if not child.filled:
				#print("Am găsit slot gol la", i, ". Adaug itemul.")
				child.set_property(item_data)
				child.filled = true
				plin += 1
				return true  # A reușit să adauge obiectul, returnează `true`

	# 3. Dacă inventarul este plin și nu există sloturi libere
	#print("Inventarul este plin! Nu pot adăuga itemul.")
	return false  # Nu a reușit să adauge obiectul


#--------------------------------_ready()----------------------------------------------------------------
func _ready():
	
	for child in grid_container.get_children():
		if child is Slot_Cup:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))
			
	for child in grid_container.get_children():
		if child is Slot_Cup:
			# Accesezi TextureHolder, apoi Button (presupunem că se numește "Button")
			buton = child.get_node("TextureHolder/TextureRect/Button")
			if buton:
				buton.connect("pressed", Callable(self, "_on_buton_apasat"))
	

	
	  # Selectează automat primul slot
	if grid_container.get_child_count() > 0:
		var first_slot = grid_container.get_child(0)
		if first_slot is Slot_Cup:
			_on_slot_selected(first_slot)
	slots = [slot_container, slot_container_2, slot_container_3, slot_container_4]
	#print("Slots list:", slots)  # Verifică dacă toate sunt valide
	#
#func _process(_delta: float) -> void:
	#lamp()
	##has_backpack()
	
#-----------------------------------selectie-slot----------------------------------------------------
func _on_slot_selected(slot: Slot_Cup):
	if selected_slot and is_instance_valid(player):
		selected_slot.deselect()
		player.info=""
	
	
	selected_slot = slot  
	if slot.get_texture()!=null:
		selected_slot.select()

	
	
	
	hand_sprite.texture = null
	info_label.clear()
	#color_rect.visible = false
	info_label.visible = true
	
	
	# Dacă slotul selectat are un item (este plin), actualizează sprite-ul și eticheta
	if slot.get_texture() != null:

		hand_sprite.texture = slot.get_texture()
		hand_sprite.visible = true
		hand_sprite.scale = Vector2(0.5, 0.5)
		
		var nume     = slot.get_nume()
		var raritate = slot.get_raritate()

		
		info_label.bbcode_text = "[center]\nITEM: %s\nRARITATE: %s[/center]" % [nume, raritate]
		info_label.visible = true
		#color_rect.visible = false

	# Actualizează poziția selectorului
	update_selector_position(slot)
	
	# Echipează itemul la jucător
	#var player = get_node("/root/world/player")
	if  slot.get_texture() != null and is_instance_valid(player):
		player.equip_item(slot.get_texture(), slot.get_nume(), slot.get_raritate())



func update_selector_position(slot: Slot_Cup):
	var slot_position = slot.get_global_position()
	texture_rect.global_position = slot_position
	
	
# Referințe la sloturile din inventar
@onready var slot_container: Slot_Cup = $MarginContainer/GridContainer/SlotContainer
@onready var slot_container_2: Slot_Cup = $MarginContainer/GridContainer/SlotContainer2
@onready var slot_container_4: Slot_Cup = $MarginContainer/GridContainer/SlotContainer4
@onready var slot_container_3: Slot_Cup = $MarginContainer/GridContainer/SlotContainer3

# Sloturile tale
var slots = []

#---------------------------------------input-uri-diverse----------------------------------------------------
func _input(_event):
	if Input.is_action_just_pressed("drop_cup"):
		drop_selected_item()
	if Input.is_action_just_pressed("drop_1"):
		drop_selected_item_1()
	#if Input.is_action_just_pressed("plantSeed"):
		#plantare()
	#if Input.is_action_just_pressed("attack"):
		#attack()
	#if Input.is_action_just_pressed("eat"):
		#eat()
	#if Input.is_action_just_pressed("consola"):
		#pass
		
	#if Input.is_action_just_pressed("slot_1"):
		#select_slot_by_index(0)
	#if Input.is_action_just_pressed("slot_2"):
		#select_slot_by_index(1)
	#if Input.is_action_just_pressed("slot_3"):
		#select_slot_by_index(2)
	#if Input.is_action_just_pressed("slot_4"):
		#select_slot_by_index(3)



# Funcție pentru a transfera un item într-un slot specific
func transfer_item_to_slot(item_data: Dictionary, slot_container_aici: Node) -> bool:
	# Verifică dacă slotul conține deja acest tip de item
	if typeof(item_data) == TYPE_DICTIONARY and item_data.has("NUMBER"):
		if slot_container_aici.get_id() == str(item_data["NUMBER"]):
			# Adaugă cantitatea la itemul existent
			slot_container_aici.set_property({
				"TEXTURE": item_data["TEXTURE"],
				"CANTITATE": slot_container_aici.get_cantitate() + item_data["CANTITATE"],
				"NUMBER": item_data["NUMBER"],
				"NUME": item_data["NUME"]
			})
			return true  # Itemul a fost transferat cu succes
		elif slot_container_aici.get_id() == "0":  # Verifică dacă slotul este gol
			# Adaugă itemul în slotul gol
			slot_container_aici.set_property({
				"TEXTURE": item_data["TEXTURE"],
				"CANTITATE": item_data["CANTITATE"],
				"NUMBER": item_data["NUMBER"],
				"NUME": item_data["NUME"]
			})
			return true  # Itemul a fost transferat cu succes
	return false  # Slotul este ocupat și nu conține același tip de item
	



#-----------------------------------select_slot_by_index------------------------------------------------
func select_slot_by_index(indexx: int):
	if indexx >= 0 and indexx < grid_container.get_child_count():
		var slot = grid_container.get_child(indexx)
		if slot is Slot_Cup:
			_on_slot_selected(slot)

#---------------------------------drop-item-selected-----------------------------------------------------
func drop_selected_item():
	#print("Funcția drop_selected_item a fost apelată")
	if selected_slot:
		var ID = selected_slot.get_id()  # Obține ID-ul itemului din slotul selectat
		if ID == "0":
			selected_slot.clear_item()
		
		if ID  and is_instance_valid(player):
			#print("ID-ul itemului este: ", ID)
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
			#print(plin)
			
			player.inequip_item()
			info_label.text=""
			
			
		#else:
			#print("ID-ul itemului nu a fost găsit în slotul selectat.")
	#else:
		#print("Niciun slot nu este selectat")
		
func update_inventory_status():
	plin = 0
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot_Cup and child.filled:
			plin += 1



#--------------------------------functie-drop-default--------------------------------------------------
func drop_item(ID: String, cantiti: int):
	# Obține textura și cantitatea din ItemData
	if cantiti==0:
		return
	
	var item_cantitate = cantiti
	var item_texture_path = "res://assets/" + DatabaseCuppon.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	
	# Încarcă scena itemului
	var item_scene = load("res://User/Item.tscn") as PackedScene
	if item_scene and is_instance_valid(player) :
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		item_instance.ID = ID
		item_instance.type="slot_cup"
		#item_instance.set_lumina(ID)
		var player_position = player.global_position
		var player_direction = player.last_direction.normalized()  # Direcția „în față”
		var drop_distance = 20  # Ajustează distanța conform nevoilor tale
		var drop_position = player_position + (player_direction * drop_distance)
		
		item_instance.position = drop_position 
		world_node.add_child(item_instance)
		player.inequip_item()
		info_label.text=""
		#if ID=="18":
			#var backpack = get_tree().root.get_node("world/CanvasLayer/Backpack-afis")  
			#backpack.visible = false
	
func drop_item_generare(ID: String, cantiti: int):
	# Obține textura și cantitatea din ItemData
	if cantiti==0:
		return
	
	var item_cantitate = cantiti
	var item_texture_path = "res://assets/" + DatabaseCuppon.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	
	# Încarcă scena itemului
	var item_scene = load("res://User/Item.tscn") as PackedScene
	if item_scene and is_instance_valid(player) :
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		item_instance.ID = ID
		item_instance.type="slot"
		#item_instance.set_lumina(ID)
		var player_position = player.global_position
		var player_direction = player.last_direction.normalized()  # Direcția „în față”
		var drop_distance = 20  # Ajustează distanța conform nevoilor tale
		var drop_position = player_position + (player_direction * drop_distance)
		
		item_instance.position = drop_position 
		world_node.add_child(item_instance)
		player.inequip_item()
		info_label.text=""
		#if ID=="18":
			#var backpack = get_tree().root.get_node("world/CanvasLayer/Backpack-afis")  
			#backpack.visible = false
#-----------------------------------drop-pt-cate-un-item----------------------------------------------
func drop_selected_item_1():
	#print("Funcția drop_selected_item_1 a fost apelată")
	if selected_slot:
		var ID = selected_slot.get_id()  # Obține ID-ul itemului din slotul selectat
		if ID == "0":
			selected_slot.clear_item()
		if ID and is_instance_valid(player):
			#print("ID-ul itemului este: ", ID)
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
		#else:
			#print("ID-ul itemului nu a fost găsit în slotul selectat.")
	#else:
		#print("Niciun slot nu este selectat")


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
		if ID=="2" || ID=="9" || ID=="10" || ID=="13" || ID=="22" || ID=="3":
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
		
		var global_position1=tile_map.map_to_local(location)
		item_instance.position = global_position1
		#drop_position=Vector2(100,100)
		# Folosește 'position' pentru coordonate locale
		#global_cantiti=cantiti
		world_node.add_child(item_instance)


#------------------------------------------functie-eat()-----------------------------------------------
func eat():
	# Verificăm dacă există un slot selectat
	if selected_slot == null:
		#print("Nu ai selectat nimic în inventar!")
		return
	
	var slot = selected_slot  # Slotul selectat
	if slot is Slot_Cup and slot.filled:
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
				#print("Ai mâncat un item, viața ta a crescut.")
			return
	#else:
		#print("Slotul selectat nu conține mâncare!")
#
	#print("Nu ai mâncare în inventar!")



#-------------------------------------drop-locatie-apropiata------------------------------------------
func drop_item_everywhere(ID: String, cantiti: int,location:Vector2):
	var item_cantitate = cantiti
	if cantiti==0:
		plin=0
		return
	var item_texture_path = "res://assets/" + DatabaseCuppon.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	
	# Încarcă scena itemului
	var item_scene = load("res://User/Item.tscn") as PackedScene
	if item_scene:
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		
		item_instance.ID = ID

		item_instance.position = location
		world_node.add_child(item_instance)

func has_shield() -> bool:
	player.scut.visible=true
	player.shield_touch.disabled=false
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		if slot is Slot_Cup:
			# Verifica daca slotul este plin si contine un scut
			if slot.filled and slot.get_id() == "13":  # presupunem ca ID-ul scutului este "13"
				return true
	return false
	
#func has_backpack():
	#var backpack = get_tree().root.get_node("world/CanvasLayer/Backpack-afis")  
	#if not backpack:  
		##print("EROARE: Nodul 'Backpack-afis' nu a fost găsit!")
		#return  
#
	## Verificăm dacă rucsacul există în orice slot din inventar
	#var has_backpack_1 = false
	#for slot in slots:
		 ## Presupun că ai un array `slots` în inventar
		#if slot is Slot  and slot.get_id() == "18":
#
			#has_backpack_1 = true
			#break  # Nu mai căutăm, am găsit rucsacul
	#
	#backpack.visible = has_backpack_1  # Devine invizibil doar dacă e scos complet din inventar

#func lamp():
	#var item_23_gasit = false
	#lamp_inv()
	#for i in range(grid_container.get_child_count()):
			#var slot = grid_container.get_child(i)
			#if slot is Slot:
				## Verifica daca slotul este plin si contine un scut
				#if slot.get_id() == "23":
					#id=slot.get_id()
					#item_23_gasit = true
					#$"../Felinar".visible = true
					#lumina_pe_player()
					#if slot_container12.get_id()=="7":
						#var cantitate= slot_container12.get_cantitate()
						#if cantitate>0:
							#timp_ramas=cantitate*60
							#label.text = format_time(timp_ramas)
							#timer.start()
							#slot_container12.clear_item()
							#
	#if player and not item_23_gasit and is_instance_valid(player_light):
		##$"../Felinar".visible = false
		#player_light.visible=false
		#player_light.enabled=false
#
#func lumina_pe_player():
	#if timp_ramas>0:
		#player_light.visible=true
		#player_light.enabled=true
		#
#func _on_timer_timeout() -> void:
	#if timp_ramas > 0:
		#timp_ramas -= 1  # Scade o secundă din timpul rămas
		#label.text = format_time(timp_ramas)  # 🔥 Actualizează UI-ul
#
		## Consumă 1 combustibil la fiecare 60 secunde
		#if timp_ramas % 60 == 0:
			#var cantitate = slot_container12.get_cantitate()
			#if cantitate > 0:
				#slot_container12.set_cantitate(cantitate - 1)  # 🔥 Consumă combustibil
				##print("Cantitatea rămasă: " + str(cantitate - 1))
#
			#if cantitate - 1 <= 0:
				#print("Combustibilul s-a epuizat!")
			#
	#else:
		##light.enabled=false
		#timer.stop()
		##print("Timpul a expirat!")
		


#func format_time(seconds: int) -> String:
	#@warning_ignore("integer_division")
	#var minutes = seconds / 60
	#var secs = seconds % 60
	#return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

#func lamp_inv():
	#if not timer.is_stopped():
		#var items = get_tree().get_nodes_in_group("item")
		#for item in items:
			#if item.ID=="23":
				#item.set_lumina("23")
				
func generate_cuppon_items(selected_id = null):
	var file = FileAccess.open("res://Autoload/database_cuppon.json", FileAccess.READ)
	if file == null:
		print("Nu s-a putut deschide fișierul JSON.")
		return

	var json_text = file.get_as_text()
	file.close()
	var json_data = JSON.parse_string(json_text)
	if typeof(json_data) != TYPE_DICTIONARY:
		print("Eroare la parsing sau structura JSON-ului!")
		return

	var items_dict = json_data
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var num_drops = 4

	var interval_min = 1
	var interval_max = 10

	var all_keys = items_dict.keys()
	var pool_keys = []

	if str(selected_id) == "27":
		for k in all_keys:
			var kid = int(k)
			if kid >= interval_min and kid <= interval_max:
				pool_keys.append(k)
	else:
		for k in all_keys:
			if k != "0":
				pool_keys.append(k)

	if pool_keys.size() < num_drops:
		print("Nu sunt suficiente iteme în interval pentru num_drops!")
		return

	for i in range(num_drops):
		var id_item = pool_keys[rng.randi_range(0, pool_keys.size() - 1)]
		var item_data = items_dict[str(id_item)]
		if item_data == null:
			print("Itemul nu a fost găsit pentru key:", id_item)
			continue

		var raritate = ""
		if item_data.has("raritate"):
			raritate = item_data["raritate"]
		else:
			raritate = "comuna"

		var random_quantity = 1
		match raritate:
			"comuna":
				random_quantity = rng.randi_range(5, 15)
			"rara":
				random_quantity = rng.randi_range(1, 10)
			"epica":
				random_quantity = rng.randi_range(1, 5)
			"legendara":
				random_quantity = 1
			_:
				random_quantity = 1  # fallback

		print("Drop ID: %s, Q: %s, raritate: %s" % [str(id_item), str(random_quantity), raritate])
		drop_item_generare(str(id_item), random_quantity)





		

func _on_buton_apasat():
	if selected_slot and selected_slot.get_id() == "27":
		generate_cuppon_items("27")
	else:
		generate_cuppon_items()
	if selected_slot:
		selected_slot.clear_item()
		selected_slot.deselect()
		selected_slot = null 
