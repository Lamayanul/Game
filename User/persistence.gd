extends Node2D

@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var chest = get_node("/root/world/Chest")
@onready var world = get_node("/root/world") 
var scor = 0
@onready var tile_map = get_node("/root/world/TileMap")
@onready var enemy = get_node("/root/world/enemy")
@onready var panel = get_node("/root/world/CanvasLayer/PanelContainer")

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




	#var player_list = get_tree().get_nodes_in_group("player")
	#if player_list.size() > 0:
		#var player = player_list[0]  # Luăm primul jucător din listă
		#print("PLAYER HEALTH: ", player.health)
#
		#if player.health > 0:
			#save_data.player_position = player.position
			#save_data.player_health = player.health
			#print("✅ Salvăm jucătorul: Poziție:", player.position, "HP:", player.health)
		#else:
			#save_data.player_health = 0  # Marchez că jucătorul este eliminat
			#print("❌ Jucător eliminat, nu salvăm poziția.")
	#else:
		#print("⚠️ Nu există jucător în scenă, nu salvăm poziția sau viața.")
		
	var players = get_tree().get_nodes_in_group("player")
	var player_data = {
	"health":0,
	"position": Vector2.ZERO}

	if players.size() > 0:  # Verificăm dacă există un player
		var player = players[0]  # Luăm primul player
		player_data = {
		"position": player.position,
		"health":player.health,
		}
	save_data.player_data = player_data


	
	
		
	var enemy = get_tree().get_nodes_in_group("enemy")
	if enemy.size() > 0:  
		save_data.enemy_position = enemy[0].position
		print(enemy[0].position)
		
		
		
		
	var gaina = get_tree().get_nodes_in_group("gaina")
	if gaina.size() > 0:  
		save_data.gaina_position = gaina[0].position
		print(gaina[0].position)
		
		
		
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
	


	var rocks = get_tree().get_nodes_in_group("rock")
	if rocks.size() > 0:  
		for rock in rocks:
			save_data.rocks_position.append(rock.position)  # Adăugăm fiecare poziție
			print("✔️ Copac salvat la:", rock.position)


	var copaci = get_tree().get_nodes_in_group("copac")
	if copaci.size() > 0:  
		for copac in copaci:
			save_data.trees_position.append(copac.position)  # Adăugăm fiecare poziție
			print("✔️ Copac salvat la:", copac.position)


	
	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("save_data"):
			object.save_data()



func load_data(data : SaveData):
	print("📤 Încărcăm JSON:", data)
	print("📤 Încărcăm cufărul:", data.chest_items)

	
	

	#var player_list = get_tree().get_nodes_in_group("player")
#
	#if player_list.size() > 0:
		## Există deja un jucător în scenă → îi setăm poziția și viața salvate
		#var player = player_list[0]
		#player.position = data.player_position
		#player.health = data.player_health
		#print("✅ Jucătorul existent a fost actualizat: Poziție:", player.position, "HP:", player.health)
	#else:
#
		#print("🛠️ Nu există jucător, dar avem date salvate. Creăm unul nou.")
		#
			## Instanțiem jucătorul
		#var new_player = preload("res://Scene/player.tscn").instantiate()
		#new_player.position = data.player_position
#
#
			## Adăugăm jucătorul în scenă (asigură-te că `world` este corect definit)
		#world.add_child(new_player)
		#new_player.health = data.player_health
		#print("✅ Jucător nou creat la poziția:", new_player.position, "HP:", new_player.health)
	await get_tree().create_timer(2.0).timeout
	var players = get_tree().get_nodes_in_group("player")
	if "player_data" in data :
		if players.size() > 0:
			var player = players[0]
			player.queue_free()  # Eliberăm jucătorul anterior
		else:
			print("⚠️ Nu există jucător în scenă!")
		var new_player = preload("res://Scene/player.tscn").instantiate()
		new_player.position = data["player_data"]["position"]
		new_player.health = data["player_data"]["health"]

		print("NEW HEALTH: ",new_player.health)
		enemy.player=new_player
		tile_map.player=new_player
		inv.player = new_player
		new_player.add_to_group("player")
		inv.connect("attacking", Callable(new_player, "_on_inv_attacking"))
		world.add_child(new_player)
		await get_tree().process_frame
		if is_instance_valid(new_player):
			panel.connect("mouse_entered", Callable(new_player, "_on_area_2d_mouse_entered"))
			panel.connect("mouse_exited", Callable(new_player, "_on_area_2d_mouse_exited"))
			new_player.healthbar_player.value = new_player.health
			var player_camera = new_player.get_node_or_null("Camera2D")  
			if player_camera:
				player_camera.make_current()
		


	
	
	
	
	var gaina = get_tree().get_nodes_in_group("gaina")
	if gaina.size() > 0:  
		gaina[0].position = data.gaina_position
		print(gaina[0].position)
		
		
		
	var enemy = get_tree().get_nodes_in_group("enemy")
	if enemy.size() > 0:  
		enemy[0].position = data.enemy_position
		print(enemy[0].position)
		
		
		
		
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



	var copaci = get_tree().get_nodes_in_group("copac")
	for copac in copaci:
		copac.queue_free()
	for position in data.trees_position:
		var new_copac = preload("res://Scene/copac.tscn").instantiate()  # Instanțiem un nou copac
		new_copac.position = position  # Setăm poziția corectă
		world.add_child(new_copac)  # Adăugăm copacul în scenă
	#if copaci.size() > 0:  
		#for i in range(min(copaci.size(), data.trees_position.size())):  
			#copaci[i].position = data.trees_position[i]  # Setăm poziția corectă pentru fiecare copac
			#print("✔️ Copac încărcat la:", copaci[i].position)





	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("load_data"):
			object.load_data()

	
func get_save_data():
	var save_data=SaveData.new()
	save_data.scor=scor


	#var player_list = get_tree().get_nodes_in_group("player")
	#if player_list.size() > 0:
		#var player = player_list[0]  # Luăm primul jucător din listă
		#print("PLAYER HEALTH: ", player.health)
#
		#if player.health > 0:
			#save_data.player_position = player.position
			#save_data.player_health = player.health
			#print("✅ Salvăm jucătorul: Poziție:", player.position, "HP:", player.health)
		#else:
			#save_data.player_health = 0  # Marchez că jucătorul este eliminat
			#print("❌ Jucător eliminat, nu salvăm poziția.")
	#else:
		#print("⚠️ Nu există jucător în scenă, nu salvăm poziția sau viața.")

	var players = get_tree().get_nodes_in_group("player")
	var player_data = {
	"health":0,
	"position": Vector2.ZERO}

	if players.size() > 0:  # Verificăm dacă există un player
		var player = players[0]  # Luăm primul player
		player_data = {
		"position": player.position,
		"health":player.health,
		}

	save_data.player_data = player_data

		
		
		
	var gaina = get_tree().get_nodes_in_group("gaina")
	if gaina.size() > 0:  
		save_data.gaina_position = gaina[0].position
		print(gaina[0].position)
		
		
	var enemy = get_tree().get_nodes_in_group("enemy")
	if enemy.size() > 0:  
		save_data.enemy_position = enemy[0].position
		print(enemy[0].position)
		
		
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


	var rocks = get_tree().get_nodes_in_group("rock")
	if rocks.size() > 0:  
		for rock in rocks:
			save_data.rocks_position.append(rock.position)  # Adăugăm fiecare poziție
			print("✔️ Copac salvat la:", rock.position)


	var copaci = get_tree().get_nodes_in_group("copac")
	if copaci.size() > 0:  
		for copac in copaci:
			save_data.trees_position.append(copac.position)  # Adăugăm fiecare poziție
			print("✔️ Copac salvat la:", copac.position)


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
func _process(_delta: float) -> void:
	pass
