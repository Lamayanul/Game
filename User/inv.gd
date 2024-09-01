extends PanelContainer

@onready var grid_container = $MarginContainer/GridContainer
var selected_slot: Slot = null  # Slotul selectat
@onready var texture_rect = $MarginContainer/TextureRect
@onready var grid = $"../../TileMap/Grid"  # Referința la grid
@export var plin:int =0



# Dimensiunea unui tile (ajustează după caz)
#var tile_size = Vector2(16, 16)

func add_item(ID="0"):

	var item_texture = load("res://assets/" + ItemData.get_texture(ID))
	var item_cantitate = ItemData.get_cantitate(ID)
	var item_number = ItemData.get_number(ID)
	
	var item_data = {"TEXTURE": item_texture, "CANTITATE": item_cantitate, "NUMBER":item_number}
	
	var start_index = 0
	var index = start_index

	for i in range(start_index, grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child != null and child.has_method("set_property"):
			if not child.filled:
				index = i
				break
			#elif child.get_id() == ID:
				#child.set_property(item_data)
				#return
				
			
	var slot = grid_container.get_child(index)
	if slot != null and slot.has_method("set_property"):
		slot.set_property(item_data)
	else:
		print("Eroare: Slotul este null sau nu are metoda set_property.")

func _ready():
	for child in grid_container.get_children():
		if child is Slot:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))
	
	  # Selectează automat primul slot
	if grid_container.get_child_count() > 0:
		var first_slot = grid_container.get_child(0)
		if first_slot is Slot:
			_on_slot_selected(first_slot)

func _on_slot_selected(slot: Slot):
	if selected_slot:
		selected_slot.deselect()  # Deselectează slotul anterior
	
	selected_slot = slot
	selected_slot.select()
	update_selector_position(selected_slot)
	var player = get_node("/root/world/player")  # Referința la nodul player
	if player and slot.get_texture() != null:
		player.equip_item(slot.get_texture())

func update_selector_position(slot: Slot):
	var slot_position = slot.get_global_position()
	texture_rect.global_position = slot_position


func _input(_event):
	if Input.is_action_just_pressed("drop"):
		drop_selected_item()



func drop_selected_item():
	print("Funcția drop_selected_item a fost apelată")
	if selected_slot:
		var ID = selected_slot.get_id()  # Obține ID-ul itemului din slotul selectat
		if ID == "0":
			selected_slot.clear_item()
		if ID:
			print("ID-ul itemului este: ", ID)
			
			# Obține poziția mouse-ului în coordonate globale
			var mouse_position = Vector2(100,100)
			var world = get_node("/root/world/")
			
			# Convertește coordonatele mouse-ului în coordonatele locale ale TileMap
			var _local_mouse_position = world.to_local(mouse_position)
			# Drop itemul la poziția exactă a mouse-ului
			drop_item(ID, mouse_position)
			
			print("Poziția calculată pentru drop: ", mouse_position)
			
			# Curăță și deselectează slotul
			selected_slot.clear_item()
			selected_slot.deselect()
			selected_slot = null  # Deselectează slotul după drop
			plin-=1
			print(plin)
		else:
			print("ID-ul itemului nu a fost găsit în slotul selectat.")
	else:
		print("Niciun slot nu este selectat")



# În funcția de drop
func drop_item(ID: String, position: Vector2):
	# Obține textura și cantitatea din ItemData
	var item_cantitate = ItemData.get_cantitate(ID)
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
		
		item_instance.ID = selected_slot.get_id()
		var local_position = world_node.to_local(position)
		item_instance.position = local_position  # Folosește 'position' pentru coordonate locale
		
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
	
