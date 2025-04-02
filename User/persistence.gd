extends Node2D

@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var chest = get_node("/root/world/Chest")
@onready var world = get_node("/root/world") 
var scor = 0


func save():
	var save_data = SaveData.new()
	
	var item_scene = get_tree().get_nodes_in_group("item")
	if item_scene.size() > 0:
		save_data.item_positions = []  # Inițializăm lista de iteme
		for item in item_scene:
			var item_data = {
				"ID": item.ID,
				"POSITION": item.position,
				"CANTITATE": item.item_cantitate,
				"TEXTURE": item.item_texture,  # Stocăm textura ca string
				"NUMBER": item.ID
			}
			save_data.item_positions.append(item_data)  # Adăugăm în listă
			print("✔️ Item salvat:", item_data)  # Debugging



	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:  
		save_data.player_position = player[0].position
		print(player[0].position)
		
		
		
	for i in range(inv.grid_container.get_child_count()):
		var child = inv.grid_container.get_child(i)
		if child is Slot and child.filled:
			var item_data = {
				"ID": child.get_id(),
				"CANTITATE": child.cantitate,
				"NUME": child.get_nume(),
				"TEXTURE": ItemData.get_texture(child.get_id())}
			save_data.inv_item.append(item_data)
		
		
	var slot_list = [chest.slot_container, chest.slot_container_2, chest.slot_container_3, chest.slot_container_4]
	for slot in slot_list:
		if slot.get_cantitate() > 0:
			save_data.chest_items.append({
				"NUMBER": slot.get_number(),
				"NUME": slot.get_nume(),
				"CANTITATE": slot.get_cantitate(),
				"TEXTURE": ItemData.get_texture(slot.get_id())
			})
	print("DEBUG - chest - sloturi", save_data.chest_items)
	
	
	
	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("save_data"):
			object.save_data()

func load_data(data : SaveData):
	print("📤 Încărcăm JSON:", data)
	print("📤 Încărcăm cufărul:", data.chest_items)
	
	var player = get_tree().get_nodes_in_group("player") 
	if player:
		player[0].position = data.player_position  # 🔥 Luăm primul nod și îi setăm poziția
	print(player[0].position)
	
	
	var item_scene = get_tree().get_nodes_in_group("item")
	for item in item_scene:
		item.queue_free()
	for item_data in data.item_positions:
			var new_item = preload("res://User/Item.tscn").instantiate()  # Instanțiem scena itemului
			
			new_item.ID = item_data["ID"]
			new_item.position = item_data["POSITION"]
			new_item.item_cantitate = item_data["CANTITATE"]

			if "TEXTURE" in item_data and item_data["TEXTURE"] is String:
				var texture_path = "res://assets/" + item_data["TEXTURE"]
				if ResourceLoader.exists(texture_path):  
					var texture = load(texture_path)
					new_item.item_texture = texture
					new_item.texture = texture  # Aplicăm textura
				else:
					print("⚠️ Textura nu există:", texture_path)
			else:
				print("⚠️ Eroare: TEXTURE nu este un string valid!", item_data["TEXTURE"])
			world.add_child(new_item)
			print("✔️ Item încărcat:", new_item)


	for i in range(min(inv.grid_container.get_child_count(),data.inv_item.size())):
		var child = inv.grid_container.get_child(i)
		if child is Slot: 
			child.clear_item()
			var item_data= data.inv_item[i]
			print("DEBUG - Item data:", item_data,"i: ",i)
			var item_id = str(item_data.get("NUMBER", item_data.get("ID")))  # Convertim în string
			var item_cantitate = int(item_data.get("CANTITATE", 1))  # Asigurăm că e int
		
			child.inv.add_item(item_id, item_cantitate)
			child.filled = true
			print("Inventar încărcat cu succes!")
		else:
			print("Eroare la încărcarea inventarului.")
			
	
	if data.chest_items.size() > 0:
		print("Încărcăm itemele salvate în cufăr:", data.chest_items)
		var slot_list = [chest.slot_container, chest.slot_container_2, chest.slot_container_3, chest.slot_container_4]
		for slot in slot_list:
				slot.clear_item()
		for i in range(min(data.chest_items.size(), slot_list.size())):
			var slot =slot_list[i]
			var item_data = data.chest_items[i]
			#print("DEBUG - CHEST - Item data chest:", item_data,"i: ",i)
			var texture_path = "res://assets/" + item_data["TEXTURE"]
			var texture = load(texture_path)
			if texture == null:
				print("Textura lipsă pentru", item_data["NUME"])
				continue

			slot.set_property({
				"TEXTURE": texture,
				"CANTITATE": item_data["CANTITATE"],
				"NUMBER": item_data["NUMBER"],
				"NUME": item_data["NUME"]
			})

	else:
		print("Generăm iteme noi pentru cufăr...")


	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("load_data"):
			object.load_data()


func get_save_data():
	var save_data=SaveData.new()
	save_data.scor=scor
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:  # ✅ Verificăm dacă avem noduri
		save_data.player_position = player[0].position
		
	var item_scene = get_tree().get_nodes_in_group("item")
	if item_scene.size() > 0:
		save_data.item_positions = []  # Inițializăm lista de iteme
		for item in item_scene:
			var item_data = {
				"ID": item.ID,
				"POSITION": item.position,
				"CANTITATE": item.item_cantitate,
				"TEXTURE": item.item_texture,  # Stocăm textura ca string
				"NUMBER": item.ID
			}
			save_data.item_positions.append(item_data)  # Adăugăm în listă
			print("✔️ Item salvat:", item_data)  # Debugging


	for i in range(inv.grid_container.get_child_count()):
		var child = inv.grid_container.get_child(i)
		if child is Slot and child.filled:
			var item_data = {
				"ID": child.get_id(),
				"CANTITATE": child.cantitate,
				"NUME": child.get_nume(),
				"TEXTURE": ItemData.get_texture(child.get_id())}
			save_data.inv_item.append(item_data)


	var slot_list = [chest.slot_container, chest.slot_container_2, chest.slot_container_3, chest.slot_container_4]
	for slot in slot_list:
		if slot.get_cantitate() > 0:
			save_data.chest_items.append({
				"NUMBER": slot.get_number(),
				"NUME": slot.get_nume(),
				"CANTITATE": slot.get_cantitate(),
				"TEXTURE": ItemData.get_texture(slot.get_id())
			})
	print("DEBUG - chest - sloturi", save_data.chest_items)

	return save_data
	
	
	#var slot_list = [chest.slot_container, chest.slot_container_2, chest.slot_container_3, chest.slot_container_4]

	#for slot in save_data.chest_items:
		#if slot.get_cantitate() > 0:
			#save_data.chest_items.append({
				#"NUMBER": slot.get_number(),
				#"NUME": slot.get_nume(),
				#"CANTITATE": slot.get_cantitate(),
				#"TEXTURE": ItemData.get_texture(slot.get_id())
			#})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
