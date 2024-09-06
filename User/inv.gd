extends PanelContainer

@onready var grid_container = $MarginContainer/GridContainer
var selected_slot: Slot = null  # Slotul selectat
@onready var texture_rect = $MarginContainer/TextureRect
@onready var grid = $"../../TileMap/Grid"  # Referința la grid
@export var plin:int =0
@onready var info_label = $"../InfoLabel"
@onready var hand_sprite = $"../PanelContainer/Sprite2D/item_mana/sprite"
@onready var color_rect = $"../ColorRect"
@onready var tilemap = $"../../TileMap"


signal plantSeed

# Dimensiunea unui tile (ajustează după caz)
#var tile_size = Vector2(16, 16)

#func add_item(ID="0"):
#
	#var item_texture = load("res://assets/" + ItemData.get_texture(ID))
	#var item_cantitate = ItemData.get_cantitate(ID)
	#var item_number = ItemData.get_number(ID)
	#
	#var item_data = {"TEXTURE": item_texture, "CANTITATE": item_cantitate, "NUMBER":item_number}
	#
	#var start_index = 0
	#var index = start_index
#
	#for i in range(start_index, grid_container.get_child_count()):
		#var child = grid_container.get_child(i)
		#if child != null and child.has_method("set_property"):
			#if not child.filled:
				#index = i
				#break
			#elif child.get_id() == ID:
				#child.set_property(item_data)
				#return
				#
			#
	#var slot = grid_container.get_child(index)
	#if slot != null and slot.has_method("set_property"):
		#slot.set_property(item_data)
	#else:
		#print("Eroare: Slotul este null sau nu are metoda set_property.")

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

func _on_slot_selected(slot: Slot):
	selected_slot = slot  # Setează slotul selectat
	
	# Resetează sprite-ul și eticheta
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
	var player = get_node("/root/world/player")
	if player and slot.get_texture() != null:
		player.equip_item(slot.get_texture(), slot.get_nume())
	


func update_selector_position(slot: Slot):
	var slot_position = slot.get_global_position()
	texture_rect.global_position = slot_position


func _input(_event):
	if Input.is_action_just_pressed("drop"):
		drop_selected_item()
	if Input.is_action_just_pressed("drop_1"):
		drop_selected_item_1()
	if Input.is_action_just_pressed("plantSeed"):
		plantare()



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
			var player = get_node("/root/world/player")
			
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
			plin-=1
			print(plin)
			
			player.inequip_item()
			
			
			
		else:
			print("ID-ul itemului nu a fost găsit în slotul selectat.")
	else:
		print("Niciun slot nu este selectat")



# În funcția de drop
func drop_item(ID: String, cantiti: int):
	# Obține textura și cantitatea din ItemData
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
		var position_drop=Vector2(100,100)

		item_instance.position = position_drop  # Folosește 'position' pentru coordonate locale
		#global_cantiti=cantiti
		world_node.add_child(item_instance)
		
		#item_instance.scale = Vector2(2, 2)  # Asigură-te că este vizibil
		#item_instance.modulate = Color(1, 1, 1, 1)  # Asigură-te că nu este transparent
		#item_instance.visible = true  # Asigură-te că este vizibil
		
		
		#item_instance.set_texture1(item_texture)
		#item_instance.set_cantitate(item_cantitate)
		
		
		#item_instance.scale = Vector2(2, 2)  # Asigură-te că este vizibil
		#item_instance.modulate = Color(1, 1, 1, 1)  # Asigură-te că nu este transparent
		#item_instance.visible = true  # Asigură-te că este vizibil
		
		# Adaugă instanța itemului în nodul world
		#var items_node = get_node("/root/world/")
		#if items_node:
			#items_node.add_child(load("res://User/item.tscn").instantiate()) 
			#items_node.add_child(item_instance)
	
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
			var player = get_node("/root/world/player")
			#var cantiti=selected_slot.get_cantitate()
			# Convertește coordonatele mouse-ului în coordonatele locale ale TileMap
			var _local_mouse_position = world.to_local(mouse_position)

			if selected_slot.decrease_cantitate(cantitate_de_drop): 
				
				selected_slot.clear_item()
				selected_slot.deselect()
				selected_slot = null
				plin -= 1
				player.inequip_item()  # Dez-echipează itemul
				
			if ID=="0":
				cantitate_de_drop=0
			drop_item(ID , cantitate_de_drop)
			player.inequip_item() 

		else:
			print("ID-ul itemului nu a fost găsit în slotul selectat.")
	else:
		print("Niciun slot nu este selectat")

func plantare():
	var _tilemap=get_node("/root/world/TileMap")
	if selected_slot:
		var ID=selected_slot.get_id()
		if ID=="3":
			emit_signal("plantSeed")
			#tilemap._on_player_plant_seed()
			#if selected_slot.decrease_cantitate(drop): 
				#selected_slot.clear_item()
				#selected_slot.deselect()
				#selected_slot = null
				#plin -= 1
				#var player = get_node("/root/world/player")
				#player.inequip_item()
		
		
		
		
		
