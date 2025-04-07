extends Node2D

@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var chest = get_tree().get_nodes_in_group("chest")
@onready var world = get_node("/root/world") 
var scor = 0
@onready var tile_map = get_node("/root/world/TileMap")
@onready var enemy = get_tree().get_nodes_in_group("enemy")
@onready var panel = get_node("/root/world/CanvasLayer/PanelContainer")
@onready var ovens = get_tree().get_nodes_in_group("oven")
@onready var elec = get_tree().get_nodes_in_group("LightSource")

var power_generator=null
#var pillar=null
func save():
	var save_data = SaveData.new()
	
	#La save/load local: itemele luate in inventar dupa ce a fost dat save,
	#raman in inventar la load, la save/load global: totul merge bine
	
	
	#--------------------------------------SAVE ITEM-----------------------------------------------------------------------------------------
	
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

#--------------------------------------------------------------------------------------------------------------------------------------------





#--------------------------------------SAVE RECIPE-----------------------------------------------------------------------------------------
	
	#var ovens = get_tree().get_nodes_in_group("oven")
	#var oven_data = {}
	#for oven in ovens:
		#oven_data[oven.name] = {
		#"position":oven.position,
		#}
	#save_data.oven_data = oven_data
	#
	#for i in range(oven.get_child_count()):
		#var child = oven.get_child(i)
		#if child is Slot :
			#var recipe_data = {
				#"ID": child.get_id(),
				#"CANTITATE": child.cantitate,
				#"NUME": child.get_nume(),
				#"TEXTURE": ItemData.get_texture(child.get_id())}
			#save_data.recipe_item.append(recipe_data)
	#print("OVEN DEBUG: ",save_data.recipe_item)
	
	
	for oven in ovens:
		var oven_items = []
		var recipe_slots = oven.get_tree().get_nodes_in_group("recipe")

		for slot in recipe_slots:
			if oven.is_ancestor_of(slot):  # ca să iei doar sloturile acestui oven
					var recipe_data = {
						"ID": slot.get_id(),
						"CANTITATE": slot.cantitate,
						"NUME": slot.get_nume(),
						"TEXTURE": ItemData.get_texture(slot.get_id())
					}
					oven_items.append(recipe_data)

		save_data.oven_data[oven.name] = {
			"position": oven.position,
			"items": oven_items
		}
		print("oven::::::::",oven_items)

#--------------------------------------------------------------------------------------------------------------------------------------------








#----------------------------------------------SAVE ELECTRICITY THINGS-----------------------------------------------------------------------------

	var pillars = get_tree().get_nodes_in_group("LightSource")
	save_data.elec_pillar_data = {}  # Resetăm datele

	for pillar in pillars:
		var pillar_items = []
		var recipe_slots = pillar.get_tree().get_nodes_in_group("elec_slot")

		for slot in recipe_slots:
			if pillar.is_ancestor_of(slot):  # doar sloturile din acest pillar
				var elec_data = {
					"ID": slot.get_id(),
					"CANTITATE": slot.cantitate,
					"NUME": slot.get_nume(),
					"TEXTURE": ItemData.get_texture(slot.get_id())
				}
				pillar_items.append(elec_data)

		save_data.elec_pillar_data[pillar.name] = {
			"position": pillar.position,
			"conect": pillar.conect,
			"items": pillar_items
		}
		print("PILLAR DEBUG:", pillar_items)


#----------------------------------------------------------------------------------------------------------------------------------










#----------------------------------------------SAVE POWER GENERATOR----------------------------------------------------------------------------------
	
	#for power in get_tree().get_nodes_in_group("pow_gen"):
		#if power is StaticBody2D:
			#var slot = power.get_node("CanvasLayer/SlotContainer")
			#print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",slot)
			#if slot is Slot:
				#var slot_gen_data = {
				#"ID": slot.get_id(),
				#"CANTITATE": slot.cantitate,
				#"NUME": slot.get_nume(),
				#"TEXTURE": ItemData.get_texture(slot.get_id())}
				#save_data.power_generator_slot.append(slot_gen_data)
	#print("ggggggggggggggggggggggggggggggggggggggggggggggggggggggg",save_data.power_generator_slot)
	#

#--------------------------------------------------------------------------------------------------------------------------------------------







#----------------------------------------------SAVE PLAYER----------------------------------------------------------------------------------
	
	var players = get_tree().get_nodes_in_group("player")
	var player_data = {
	"health":0,
	"position": Vector2.ZERO,
	"speed":50,
	}

	if players.size() > 0:  # Verificăm dacă există un player
		var player = players[0]  # Luăm primul player
		player_data = {
		"position": player.position,
		"health":player.health,
		"speed":player.speed,
		}
	save_data.player_data = player_data

#-------------------------------------------------------------------------------------------------------------------------------------------







#----------------------------------------------SAVE GENERATOR THINGS----------------------------------------------------------------------------------
	
	#var generatori = get_tree().get_nodes_in_group("pow_gen")
	#var generator_things = {}
	#print("GENERATOR THINGS:", save_data["generator_things"])
	#for generator in generatori:
		#generator_things[generator.name] = {
		#"position":generator.position,
		#"progress_bar":generator.progress_bar.value,
		#"timp_ramas":generator.timp_ramas,
		#"generator_on":false,
		#"legat":generator.legat,
		#}
	#save_data.generator_things = generator_things
	#print("POOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",save_data.generator_things)


#-------------------------------------------------------------------------------------------------------------------------------------------

	var generatori = get_tree().get_nodes_in_group("pow_gen")
	var generator_data = {}

	for generator in generatori:
		var name = generator.name
		var slot = generator.get_node_or_null("CanvasLayer/SlotContainer")
		var slot_data = {}

		if slot and slot is Slot:
			slot_data = {
				"ID": slot.get_id(),
				"CANTITATE": slot.cantitate,
				"NUME": slot.get_nume(),
				"TEXTURE": ItemData.get_texture(slot.get_id())
			}

		generator_data[name] = {
			"position": generator.position,
			"progress_bar": generator.progress_bar.value,
			"timp_ramas": generator.timp_ramas,
			"generator_on": generator.generator_on,
			"legat": generator.legat,
			"slot": slot_data
		}

	save_data.generator_things = generator_data
	print("🔋 Generator things saved:", save_data.generator_things)






#----------------------------------------------SAVE ENEMY------------------------------------------------------------------------------------
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:  
		save_data.enemy_position = enemies[0].position
		print(enemies[0].position)
		
#--------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------SAVE GAINA------------------------------------------------------------------------------------

	var gaini = get_tree().get_nodes_in_group("gaina")
	var gaini_data = {
	}
	
	for gaina in gaini:
		gaini_data[gaina.name] = {
		"position": gaina.position,
		"hrana": gaina.hrana,
		"timer": gaina.timer,
		"hungry": gaina.hungry,
		"hungry_timer": gaina.hungry_timer,
		"directionChangeTimer": gaina.direction_change_timer,
		}
	
	save_data.gaini_data = gaini_data

#--------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------SAVE CHEST ITEMS-------------------------------------------------------------------------------------



	#var cestan = get_tree().get_nodes_in_group("chest")
	#var chest_items_data = {
	#}
	#for ches in cestan:
		#chest_items_data[ches.name] = {
		#"position": ches.position,}
	#save_data.chest_items_data = chest_items_data
		#
	#for i in range(inv.grid_container.get_child_count()):
		#var child = inv.grid_container.get_child(i)
		#if child is Slot and child.filled:
			#var item_data = {
				#"ID": child.get_id(),
				#"CANTITATE": child.cantitate,
				#"NUME": child.get_nume(),
				#"TEXTURE": ItemData.get_texture(child.get_id())}
			#save_data.inv_item.append(item_data)
		#
#
	#for chesti in get_tree().get_nodes_in_group("chest"):
		#var chest_data=[]
		#var slot_list = [chesti.slot_container, chesti.slot_container_2, chesti.slot_container_3, chesti.slot_container_4]
		#for slot in slot_list:
			#if slot.get_cantitate() > 0:
				#chest_data.append({
					#"NUMBER": slot.get_number(),
					#"NUME": slot.get_nume(),
					#"CANTITATE": slot.get_cantitate(),
					#"TEXTURE": ItemData.get_texture(slot.get_id())
				#})
		#print("DEBUG - chest - sloturi", chest_data)
		#save_data.chest_items.append(chest_data)
	#print("DEBUG - chest - sloturi", save_data.chest_items)
	save_data.chest_items_data = {}  # Curățăm tot

	for chesti in get_tree().get_nodes_in_group("chest"):
		var slot_list = [chesti.slot_container, chesti.slot_container_2, chesti.slot_container_3, chesti.slot_container_4]
		var chest_data = []

		for slot in slot_list:
			if slot.get_cantitate() > 0:
				chest_data.append({
					"NUMBER": slot.get_number(),
					"NUME": slot.get_nume(),
					"CANTITATE": slot.get_cantitate(),
					"TEXTURE": ItemData.get_texture(slot.get_id())
				})

		save_data.chest_items_data[chesti.name] = {
		"position": chesti.position,
		"items": chest_data
	}
	for i in range(inv.grid_container.get_child_count()):
		var child = inv.grid_container.get_child(i)
		if child is Slot and child.filled:
			var item_data = {
				"ID": child.get_id(),
				"CANTITATE": child.cantitate,
				"NUME": child.get_nume(),
				"TEXTURE": ItemData.get_texture(child.get_id())}
			save_data.inv_item.append(item_data)

#--------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------SAVE ROCKS----------------------------------------------------------------------------------

	var rocks = get_tree().get_nodes_in_group("rock")
	if rocks.size() > 0:  
		for rock in rocks:
			save_data.rocks_position.append(rock.position)  # Adăugăm fiecare poziție
			print("✔️ Copac salvat la:", rock.position)

#--------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------SAVE COPACI----------------------------------------------------------------------------------

	var copaci = get_tree().get_nodes_in_group("copac")
	var copaci_data = {
	}
	
	for copac in copaci:
		copaci_data[copac.name] = {
		"position": copac.position,
		"index_taiere":copac.index_taiere,
		"fructe": copac.fructe,
		"respawn_tree": copac.respawn_tree,
		"respawn_fruits": {"wait_time": copac.respawn_fruits.wait_time,
							"time_left":copac.respawn_fruits.time_left}
		}
	
	save_data.copaci_data = copaci_data

#--------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE BUSH----------------------------------------------------------------------------------

	var bushi = get_tree().get_nodes_in_group("bush")
	var bush_data = {}

	for bush in bushi:
		var bush_fructe_sprite = bush.get_node("StaticBody2D/Bush_fructe")
		var bush_normal_sprite = bush.get_node("StaticBody2D/Bush_normal")

		bush_data[bush.name] = {
			"position": bush.position,
			"bush_fructe_visible": bush_fructe_sprite.visible,
			"bush_normal_visible": bush_normal_sprite.visible,
			"index_taiere": bush.index_taiere,
			"respawn_fruits": {
				"wait_time": bush.timer_respawn.wait_time,
				"time_left": bush.timer_respawn.time_left
			}
		}
	save_data.bush_data = bush_data

#--------------------------------------------------------------------------------------------------------------------------------------------


#----------------------------------------------SAVE RADACINI----------------------------------------------------------------------------------

	var radacini = get_tree().get_nodes_in_group("radacina")
	var radacina_data = {}
	for radacina in radacini:
		radacina_data[radacina.name] = {
			"position": radacina.position,
			"index_taiere": radacina.index_taiere,
			}
	save_data.radacina_data = radacina_data
	print("radacina---------: ", radacina_data)

#---------------------------------------------------------------------------------------------------------------------------------------------------



	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("save_data"):
			object.save_data()





func load_data(data : SaveData):
	print("📤 Încărcăm JSON:", data)
	print("📤 Încărcăm cufărul:", data.chest_items)



#----------------------------------------------LOAD PLAYER----------------------------------------------------------------------------------

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
		print("player_data =", data.get("player_data"))
		new_player.speed = data["player_data"]["speed"]

		print("NEW HEALTH: ",new_player.health)
		for enem in enemy:
			enem.player=new_player
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

#--------------------------------------------------------------------------------------------------------------------------------------------







#----------------------------------------------LOAD RECIPE----------------------------------------------------------------------------------

	for oven_name in data.oven_data.keys():
		var oven_data = data.oven_data[oven_name]
		var ovenss = get_tree().get_nodes_in_group("oven")
		var target_oven = null

		for o in ovenss:
			if o.name == oven_name:
				target_oven = o
				break

		if target_oven == null:
			print("Oven not found:", oven_name)
			continue

		target_oven.position = oven_data["position"]

		var all_recipe_slots = get_tree().get_nodes_in_group("recipe")
		var own_slots = []
		for slot in all_recipe_slots:
			if target_oven.is_ancestor_of(slot):
				own_slots.append(slot)

		for i in range(min(oven_data["items"].size(), own_slots.size())):
			var item = oven_data["items"][i]
			var texture_path = "res://assets/" + item["TEXTURE"]
			var texture=null
			if ResourceLoader.exists(texture_path):  
				texture = load(texture_path)

			var slot = own_slots[i]
			slot.set_property({
				"TEXTURE": texture,
				"CANTITATE": item["CANTITATE"],
				"NUMBER": int(item["ID"]),
				"NUME": item["NUME"]
			})
			slot.filled = true


#--------------------------------------------------------------------------------------------------------------------------------------------








#----------------------------------------------LOAD GAINA----------------------------------------------------------------------------------

	var gaina_nodes = get_tree().get_nodes_in_group("gaina")
	for g in gaina_nodes:
		g.queue_free()

	for chicken_name in data["gaini_data"].keys():  # Parcurge toate cheile din "gaini_data"
		var chicken_data = data["gaini_data"][chicken_name]  # Obține datele fiecărei găini 
		var new_gaina = preload("res://Scene/gaina.tscn").instantiate()
		new_gaina.position = chicken_data["position"]  # Setează poziția găinii
		new_gaina.hrana = chicken_data["hrana"]  # Setează hrana pentru găină
		new_gaina.timer = chicken_data["timer"]
		new_gaina.hungry = chicken_data["hungry"] 
		new_gaina.hungry_timer = chicken_data["hungry_timer"] 
		new_gaina.direction_change_timer = chicken_data["directionChangeTimer"] 
		world.add_child(new_gaina)
		new_gaina.call_deferred("seeker_setup")

#---------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------LOAD ENEMY----------------------------------------------------------------------------------

	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:  
		enemies[0].position = data.enemy_position
		print(enemies[0].position)

#--------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------LOAD ITEMS----------------------------------------------------------------------------------

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

#--------------------------------------------------------------------------------------------------------------------------------------------








#----------------------------------------------LOAD POWER GENERATOR THINGS----------------------------------------------------------------------------------

	#var generatori = get_tree().get_nodes_in_group("pow_gen")
	#for g in generatori:
		#g.queue_free()
##
	#for pow_name in data["generator_things"].keys():  
		#var pow_data = data["generator_things"][pow_name]  
		#var new_gen = preload("res://Scene/power_generator.tscn").instantiate()
		#new_gen.position = pow_data["position"]  
		#new_gen.generator_on = pow_data["generator_on"] 
		#new_gen.timp_ramas = pow_data["timp_ramas"]
		#new_gen.legat = pow_data["legat"] 
		#world.add_child(new_gen)
		#Persistence.power_generator=new_gen
		#print("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",power_generator)
		#if is_instance_valid(new_gen):
			#new_gen.progress_bar.value = new_gen.timp_ramas/60
			
#-----------------------------------------------------------------------------------------------------------------------------------------------








#----------------------------------------------LOAD POWER GENERATOR----------------------------------------------------------------------------------

#
	#for poww in get_tree().get_nodes_in_group("pow_gen"):
		#if poww is StaticBody2D:
			## Dacă `pow` este un StaticBody2D, caută SlotContainer
			#var slot_gen = poww.get_node("CanvasLayer/SlotContainer")
			#
			#if data.power_generator_slot.size() > 0:
				#print("Încărcăm itemele salvate în cufăr:", data.power_generator_slot)
				#
				#for i in range(data.power_generator_slot.size()):
					#var item_data = data.power_generator_slot[i]
					#var texture_path = "res://assets/" + item_data["TEXTURE"]
					#var texture = load(texture_path)
					#if texture == null:
						#print("Textura lipsă pentru", item_data["NUME"])
						#continue
#
					## Aici presupunem că SlotContainer are o metodă set_property
					#slot_gen.set_property({
						#"TEXTURE": texture,
						#"CANTITATE": item_data["CANTITATE"],
						#"NUMBER": int(item_data["ID"]),
						#"NUME": item_data["NUME"]
					#})
#







#--------------------------------------------------------------------------------------------------------------------------------------------

	var generatori = get_tree().get_nodes_in_group("pow_gen")
	for g in generatori:
		g.queue_free()
	for generator in get_tree().get_nodes_in_group("pow_gen"):
		if generator.name in data.generator_things:
			var info = data.generator_things[generator.name]

			generator.position = info["position"]
			generator.progress_bar.value = info["progress_bar"]
			generator.timp_ramas = info["timp_ramas"]
			generator.generator_on = info["generator_on"]
			generator.legat = info["legat"]
			#Persistence.power_generator=generator
			var slot_data = info.get("slot", {})
			var slot = generator.get_node_or_null("CanvasLayer/SlotContainer")
			if slot and slot is Slot and slot_data:
				var texture_path = "res://assets/" + slot_data["TEXTURE"]
				var texture=null
				if ResourceLoader.exists(texture_path): 
					texture = load(texture_path)
				if texture == null:
					print("⚠️ Textura lipsă pentru:", slot_data.get("TEXTURE", ""))

				slot.set_property({
					"TEXTURE": texture,
					"CANTITATE": slot_data["CANTITATE"],
					"NUMBER": int(slot_data["ID"]),
					"NUME": slot_data["NUME"]
				})






#----------------------------------------------LOAD CHEST ITEMS----------------------------------------------------------------------------------


	#var chestane = get_tree().get_nodes_in_group("chest")
	#for g in chestane:
		#g.queue_free()
#
	#for ches in data["chest_items_data"].keys():  
		#var ches_data = data["chest_items_data"][ches]  
		#var new_chest= preload("res://Scene/chest.tscn").instantiate()
		#new_chest.position = ches_data["position"]  
		#world.add_child(new_chest)
#
#
	#for i in range(min(inv.grid_container.get_child_count(),data.inv_item.size())):
		#var child = inv.grid_container.get_child(i)
		#if child is Slot: 
			#child.clear_item()
			#var item_data= data.inv_item[i]
			#print("DEBUG - Item data:", item_data,"i: ",i)
			#var item_id = str(item_data.get("NUMBER", item_data.get("ID")))  # Convertim în string
			#var item_cantitate = int(item_data.get("CANTITATE", 1))  # Asigurăm că e int
		#
			#child.inv.add_item(item_id, item_cantitate)
			#child.filled = true
			#print("Inventar încărcat cu succes!")
		#else:
			#print("Eroare la încărcarea inventarului.")
			#
	#
	#for j in range(min(data.chest_items.size(), get_tree().get_nodes_in_group("chest").size())):
		#var chest_data = data.chest_items[j]
		#var chesti = get_tree().get_nodes_in_group("chest")[j]
		#var slot_list = [chesti.slot_container, chesti.slot_container_2, chesti.slot_container_3, chesti.slot_container_4]
#
		#for slot in slot_list:
				#slot.clear_item()
		#for i in range(min(chest_data.size(), slot_list.size())):
			#var slot =slot_list[i]
			#var item_data = chest_data[i]
			##print("DEBUG - CHEST - Item data chest:", item_data,"i: ",i)
			#var texture_path = "res://assets/" + item_data["TEXTURE"]
			#var texture = load(texture_path)
			#if texture == null:
				#print("Textura lipsă pentru", item_data["NUME"])
				#continue
#
			#slot.set_property({
				#"TEXTURE": texture,
				#"CANTITATE": item_data["CANTITATE"],
				#"NUMBER": item_data["NUMBER"],
				#"NUME": item_data["NUME"]
			#})
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
			#
	for ches_name in data.chest_items_data.keys():
		var ches_data = data.chest_items_data[ches_name]
		var chest_node = get_tree().get_nodes_in_group("chest").filter(func(c): return c.name == ches_name).front()

		# Dacă nu există în scenă, îl instanțiem
		if chest_node == null:
			chest_node = preload("res://Scene/chest.tscn").instantiate()
			chest_node.name = ches_name
			chest_node.position = ches_data["position"]
			world.add_child(chest_node)
		else:
			chest_node.position = ches_data["position"]

		# Curățăm sloturile
		var slot_list = [chest_node.slot_container, chest_node.slot_container_2, chest_node.slot_container_3, chest_node.slot_container_4]
		for slot in slot_list:
			slot.clear_item()

		# Setăm itemele
		var items = ches_data.get("items", [])
		for i in range(min(items.size(), slot_list.size())):
			var slot = slot_list[i]
			var item_data = items[i]
			var texture = load("res://assets/" + item_data["TEXTURE"])
			if texture == null:
				print("Textura lipsă pentru", item_data["NUME"])
				continue

			slot.set_property({
				"TEXTURE": texture,
				"CANTITATE": item_data["CANTITATE"],
				"NUMBER": item_data["NUMBER"],
				"NUME": item_data["NUME"]
			})
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
			

#---------------------------------------------------------------------------------------------------------------------------------------------





#----------------------------------------------LOAD COPACI----------------------------------------------------------------------------------

	var copaci_nodes = get_tree().get_nodes_in_group("copac")
	for c in copaci_nodes:
		c.queue_free()

	for copac_name in data["copaci_data"].keys(): 
		var copac_data = data["copaci_data"][copac_name] 
		var new_copac = preload("res://Scene/copac.tscn").instantiate()
		new_copac.position = copac_data["position"] 
		new_copac.index_taiere=copac_data["index_taiere"]
		new_copac.fructe = copac_data["fructe"]  
		var time_left = copac_data["respawn_fruits"]["time_left"]
		var timer = new_copac.get_node("Respawn_fruits") # sau calea exactă către timer
		timer.wait_time = max(time_left, 0.1)
		print("Timer la load pentru ", copac_name, ": ", copac_data["respawn_fruits"]["time_left"])
		#new_copac.respawn_fruits.is_stopped = copac_data["respawn_fruits"]["is_stopped"]
		#new_copac.respawn_fruits.time_left = copac_data["respawn_fruits"]["time_left"]
		world.add_child(new_copac)

#----------------------------------------------------------------------------------------------------------------------------------------------






#---------------------------------------LOAD BUSH------------------------------------------------------------------------------------------------------

	for bush in get_tree().get_nodes_in_group("bush"):
		if bush.name in data.bush_data:
			var info = data.bush_data[bush.name]

			bush.position = info["position"]
			bush.index_taiere = info["index_taiere"]
			bush.timer_respawn.wait_time = info["respawn_fruits"]["wait_time"]

			#var bush_fructe_sprite = bush.get_node("StaticBody2D/Bush_fructe")
			#var bush_normal_sprite = bush.get_node("StaticBody2D/Bush_normal")

#----------------------------------------------------------------------------------------------------------------------------------------------







#---------------------------------------LOAD RADACINA------------------------------------------------------------------------------------------------------

# Mai întâi, ștergem toate radăcinile existente
	for old_rad in get_tree().get_nodes_in_group("radacina"):
		old_rad.queue_free()

	# Apoi, recreăm toate din save
	for radacina_name in data.radacina_data.keys():
		var info = data.radacina_data[radacina_name]

		# Instanțiem radăcina
		var new_radacina = preload("res://Scene/radacina_mare.tscn").instantiate()
		new_radacina.name = radacina_name
		new_radacina.position = info["position"]
		new_radacina.index_taiere = info["index_taiere"]

		world.add_child(new_radacina)


#----------------------------------------------------------------------------------------------------------------------------------------------








#----------------------------------------------LOAD ELECTRICITY THINGS-----------------------------------------------------------------------------------------------

	for namae in data.elec_pillar_data.keys():
		var pillar_info = data.elec_pillar_data[namae]
		var new_pillar = preload("res://Scene/electricity_pillar.tscn").instantiate()
		new_pillar.position = pillar_info["position"]
		new_pillar.conect = pillar_info["conect"]
		#Persistence.pillar=new_pillar
		world.add_child(new_pillar)
		var slot_index = 0
		var slots = new_pillar.get_tree().get_nodes_in_group("elec_slot")
		for slot_data in pillar_info["items"]:
			while slot_index < slots.size() and not new_pillar.is_ancestor_of(slots[slot_index]):
				slot_index += 1
			if slot_index >= slots.size():
				break

			var slot = slots[slot_index]
			var texture_path = "res://assets/" + slot_data["TEXTURE"]
			var texture=null
			if ResourceLoader.exists(texture_path): 
				texture = load(texture_path)

			slot.set_property({
				"TEXTURE": texture,
				"CANTITATE": slot_data["CANTITATE"],
				"NUMBER": int(slot_data["ID"]),
				"NUME": slot_data["NUME"]
			})
			slot_index += 1
			print("elec_slot: ",slot_data,)
		print("elec_data: ", data.elec_pillar_data,)
#----------------------------------------------------------------------------------------------------------------------------------------------





	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("load_data"):
			object.load_data()







func get_save_data():
	var save_data=SaveData.new()
	save_data.scor=scor




#----------------------------------------------SAVE PLAYER----------------------------------------------------------------------------------

	var players = get_tree().get_nodes_in_group("player")
	var player_data = {
	"health":0,
	"position": Vector2.ZERO,
	"speed":50,
	}

	if players.size() > 0:  # Verificăm dacă există un player
		var player = players[0]  # Luăm primul player
		player_data = {
		"position": player.position,
		"health":player.health,
		"speed":player.speed,
		}

	save_data.player_data = player_data
	
#--------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE GAINA----------------------------------------------------------------------------------

	var gaini = get_tree().get_nodes_in_group("gaina")
	var gaini_data = {
	}
	for gaina in gaini:
		gaini_data[gaina.name] = {
		"position": gaina.position,
		"hrana": gaina.hrana,
		"timer": gaina.timer,
		"hungry": gaina.hungry,
		"hungry_timer": gaina.hungry_timer,
		"directionChangeTimer": gaina.direction_change_timer,
		}
	save_data.gaini_data = gaini_data
		
#---------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE ENEMY----------------------------------------------------------------------------------

	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:  
		save_data.enemy_position = enemies[0].position
		print(enemies[0].position)

#--------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE ITEM--------------------------------------------------------------------------------------

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
			
#---------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE CHEST ITEMS----------------------------------------------------------------------------------

	save_data.chest_items_data = {}  # Curățăm tot

	for chesti in get_tree().get_nodes_in_group("chest"):
		var slot_list = [chesti.slot_container, chesti.slot_container_2, chesti.slot_container_3, chesti.slot_container_4]
		var chest_data = []

		for slot in slot_list:
			if slot.get_cantitate() > 0:
				chest_data.append({
					"NUMBER": slot.get_number(),
					"NUME": slot.get_nume(),
					"CANTITATE": slot.get_cantitate(),
					"TEXTURE": ItemData.get_texture(slot.get_id())
				})

		save_data.chest_items_data[chesti.name] = {
		"position": chesti.position,
		"items": chest_data
	}
	for i in range(inv.grid_container.get_child_count()):
		var child = inv.grid_container.get_child(i)
		if child is Slot and child.filled:
			var item_data = {
				"ID": child.get_id(),
				"CANTITATE": child.cantitate,
				"NUME": child.get_nume(),
				"TEXTURE": ItemData.get_texture(child.get_id())}
			save_data.inv_item.append(item_data)

#--------------------------------------------------------------------------------------------------------------------------------------------







#----------------------------------------------SAVE GENERATOR THINGS----------------------------------------------------------------------------------
	#
	#var generatori = get_tree().get_nodes_in_group("pow_gen")
	#var generator_things = {}
	#print("GENERATOR THINGS:", save_data["generator_things"])
	#for generator in generatori:
		#generator_things[generator.name] = {
		#"position":generator.position,
		#"progress_bar":generator.progress_bar.value,
		#"timp_ramas":generator.timp_ramas,
		#"generator_on":generator.generator_on,
		#"legat":generator.legat,
		#}
	#save_data.generator_things = generator_things
	#print("POOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",save_data.generator_things)

#-------------------------------------------------------------------------------------------------------------------------------------------







#---------------------------------------------SAVE RECIPE---------------------------------------------------------------------------------------

	for oven in ovens:
		var oven_items = []
		var recipe_slots = oven.get_tree().get_nodes_in_group("recipe")

		for slot in recipe_slots:
			if oven.is_ancestor_of(slot):  # ca să iei doar sloturile acestui oven
					var recipe_data = {
						"ID": slot.get_id(),
						"CANTITATE": slot.cantitate,
						"NUME": slot.get_nume(),
						"TEXTURE": ItemData.get_texture(slot.get_id())
					}
					oven_items.append(recipe_data)

		save_data.oven_data[oven.name] = {
			"position": oven.position,
			"items": oven_items
		}
		print("oven::::::::",oven_items)

#-----------------------------------------------------------------------------------------------------------------------------------------------







#---------------------------------------------SAVE ROCKS---------------------------------------------------------------------------------------

	var rocks = get_tree().get_nodes_in_group("rock")
	if rocks.size() > 0:  
		for rock in rocks:
			save_data.rocks_position.append(rock.position)  # Adăugăm fiecare poziție
			print("✔️ Copac salvat la:", rock.position)

#---------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE COPACI----------------------------------------------------------------------------------

	var copaci = get_tree().get_nodes_in_group("copac")
	var copaci_data = {
	}
	
	for copac in copaci:
		copaci_data[copac.name] = {
		"position": copac.position,
		"fructe": copac.fructe,
		"index_taiere":copac.index_taiere,
		"respawn_tree": copac.respawn_tree,
		"respawn_fruits": {"wait_time": copac.respawn_fruits.wait_time,
							"time_left":copac.respawn_fruits.time_left}
		}
	
	save_data.copaci_data = copaci_data

#----------------------------------------------------------------------------------------------------------------------------------------------







#----------------------------------------------SAVE POWER GENERATOR----------------------------------------------------------------------------------
#
	#for power in get_tree().get_nodes_in_group("pow_gen"):
		#if power is StaticBody2D:
			#var slot = power.get_node("CanvasLayer/SlotContainer")
			#print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",slot)
			#if slot is Slot:
				#var slot_gen_data = {
				#"ID": slot.get_id(),
				#"CANTITATE": slot.cantitate,
				#"NUME": slot.get_nume(),
				#"TEXTURE": ItemData.get_texture(slot.get_id())}
				#save_data.power_generator_slot.append(slot_gen_data)
	#print("ggggggggggggggggggggggggggggggggggggggggggggggggggggggg",save_data.power_generator_slot)
#


#--------------------------------------------------------------------------------------------------------------------------------------------

	var generatori = get_tree().get_nodes_in_group("pow_gen")
	var generator_data = {}

	for generator in generatori:
		var name = generator.name
		var slot = generator.get_node_or_null("CanvasLayer/SlotContainer")
		var slot_data = {}

		if slot and slot is Slot:
			slot_data = {
				"ID": slot.get_id(),
				"CANTITATE": slot.cantitate,
				"NUME": slot.get_nume(),
				"TEXTURE": ItemData.get_texture(slot.get_id())
			}

		generator_data[name] = {
			"position": generator.position,
			"progress_bar": generator.progress_bar.value,
			"timp_ramas": generator.timp_ramas,
			"generator_on": generator.generator_on,
			"legat": generator.legat,
			"slot": slot_data
		}

	save_data.generator_things = generator_data
	print("🔋 Generator things saved:", save_data.generator_things)





#----------------------------------------------SAVE ELECTRICITY THINGS-----------------------------------------------------------------------------

	var pillars = get_tree().get_nodes_in_group("LightSource")
	save_data.elec_pillar_data = {}  # Resetăm datele

	for pillar in pillars:
		var pillar_items = []
		var recipe_slots = pillar.get_tree().get_nodes_in_group("elec_slot")

		for slot in recipe_slots:
			if pillar.is_ancestor_of(slot):  # doar sloturile din acest pillar
				var elec_data = {
					"ID": slot.get_id(),
					"CANTITATE": slot.cantitate,
					"NUME": slot.get_nume(),
					"TEXTURE": ItemData.get_texture(slot.get_id())
				}
				pillar_items.append(elec_data)

		save_data.elec_pillar_data[pillar.name] = {
			"position": pillar.position,
			"conect": pillar.conect,
			"items": pillar_items
		}
		print("PILLAR DEBUG:", pillar_items)


#----------------------------------------------------------------------------------------------------------------------------------







#----------------------------------------------SAVE BUSH----------------------------------------------------------------------------------

	var bushi = get_tree().get_nodes_in_group("bush")
	var bush_data = {}

	for bush in bushi:
		var bush_fructe_sprite = bush.get_node("StaticBody2D/Bush_fructe")
		var bush_normal_sprite = bush.get_node("StaticBody2D/Bush_normal")

		bush_data[bush.name] = {
			"position": bush.position,
			"bush_fructe_visible": bush_fructe_sprite.visible,
			"bush_normal_visible": bush_normal_sprite.visible,
			"index_taiere": bush.index_taiere,
			"respawn_fruits": {
				"wait_time": bush.timer_respawn.wait_time,
				"time_left": bush.timer_respawn.time_left
			}
		}
	save_data.bush_data = bush_data

#--------------------------------------------------------------------------------------------------------------------------------------------






#----------------------------------------------SAVE RADACINI----------------------------------------------------------------------------------

	var radacini = get_tree().get_nodes_in_group("radacina")
	var radacina_data = {}
	for radacina in radacini:
		radacina_data[radacina.name] = {
			"position": radacina.position,
			"index_taiere": radacina.index_taiere,
			}
	save_data.radacina_data = radacina_data

#---------------------------------------------------------------------------------------------------------------------------------------------------


	return save_data


func _ready() -> void:
	#inv.instantiate_chest()
	pass 


func _process(_delta: float) -> void:
	pass
