extends PanelContainer

@onready var grid_container = $MarginContainer/GridContainer
var selected_slot: Slot = null  # Slotul selectat
@onready var texture_rect = $MarginContainer/TextureRect
@onready var grid = $"../../TileMap/Grid"  # Referința la grid




# Dimensiunea unui tile (ajustează după caz)
var tile_size = Vector2(16, 16)

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
	
	var slot = grid_container.get_child(index)
	if slot != null and slot.has_method("set_property"):
		slot.set_property(item_data)
	else:
		print("Eroare: Slotul este null sau nu are metoda set_property.")

func _ready():
	for child in grid_container.get_children():
		if child is Slot:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))

func _on_slot_selected(slot: Slot):
	if selected_slot:
		selected_slot.deselect()  # Deselectează slotul anterior
	
	selected_slot = slot
	selected_slot.select()
	update_selector_position(selected_slot)

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
		if ID:
			print("ID-ul itemului este: ", ID)
			
			# Obține textura și cantitatea din baza de date
			#var item_texture = ItemData.get_texture(ID)
			#var item_cantitate = ItemData.get_cantitate(ID)
			
			# Obține poziția mouse-ului relativ la grid
			var mouse_position = get_global_mouse_position()
			var local_mouse_position = mouse_position - grid.global_position
			
			# Calculează poziția pe grid
			var grid_position = Vector2(
				floor(local_mouse_position.x / tile_size.x),
				floor(local_mouse_position.y / tile_size.y)
			)
			
			# Convertim grid_position în coordonate globale pentru plasare
			var drop_position = grid.global_position + grid_position * tile_size
			
			print("Poziția calculată pentru drop: ", drop_position)
		   
			# Plasează itemul la poziția calculată
			drop_item(ID, drop_position)
			
			# Curăță și deselectează slotul
			selected_slot.clear_item()
			selected_slot.deselect()
			selected_slot = null  # Deselectează slotul după drop
		else:
			print("ID-ul itemului nu a fost găsit în slotul selectat.")
	else:
		print("Niciun slot nu este selectat")


# În funcția de drop
func drop_item(ID: String, position: Vector2):
	
	var item_cantitate = ItemData.get_cantitate(ID)
	var item_texture = load("res://assets/"+ItemData.get_texture(ID)) as Texture
	var item_scene = load("res://User/item.tscn")
	
	
	var item_instance = item_scene.instantiate()
	item_instance.global_position = position
	item_instance.ID = ID
		
		# Setează textura și cantitatea pe item_instance
	item_instance.set_texture1(item_texture)
	item_instance.set_cantitate(item_cantitate)
		
	var items_node = get_node("/root/world/")
	#items_node.add_child(load("res://User/item.tscn").instantiate())
	items_node.add_child(item_instance)
		
	
