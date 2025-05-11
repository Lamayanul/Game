extends Node2D

@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var chest = get_tree().get_nodes_in_group("chest")
@onready var world = get_node("/root/world") 
var scor = 0
@onready var tile_map = get_node("/root/world/TileMap")
@onready var enemies = get_tree().get_nodes_in_group("enemy")
@onready var panel = get_node("/root/world/CanvasLayer/PanelContainer")
@onready var ovens = get_tree().get_nodes_in_group("oven")
@onready var elec = get_tree().get_nodes_in_group("LightSource")
@onready var barci = get_tree().get_nodes_in_group("barca")
@onready var tile = get_node("/root/world/TileMap")
@onready var texture_rect_menu = get_tree().get_nodes_in_group("player_image")
@onready var cycle_zi_noapte = get_tree().get_nodes_in_group("cycle")
@onready var save_slot = get_tree().get_nodes_in_group("save_slot")

var textura_path= ""
var image_bytes: PackedByteArray = PackedByteArray()
var textura: ImageTexture =null 
var saved_ogor_tiles: Array=[]
var generator_data: Dictionary = {}
var data_dir=""
var ora_dir=""
@onready var label = $CanvasLayer/Control.get_node("Label")
@onready var progress_bar = $CanvasLayer/Control.get_node("ProgressBar")
#var power_generators = []
#var pillar=null

func show_loading():
	$CanvasLayer.visible = true
	label.text = "Se încarcă..."
	await get_tree().process_frame
	await $CanvasLayer/Control.pick_random_image()

func hide_loading():
	$CanvasLayer.visible = false

func step(label_text: String, current: int, total: int) -> void:
	update_progress(current, total,label_text)
	await get_tree().create_timer(0.1).timeout

func update_progress(current: int, total: int, label_text: String = ""):
	var percent = float(current) / total * 100.0
	progress_bar.max_value = 100
	progress_bar.value = percent
	label.text = label_text + " (" + str(round(percent)) + "%)"
	
	
func save():
	var save_data = SaveData.new()
	
	#La save/load local: itemele luate in inventar dupa ce a fost dat save,
	#raman in inventar la load, la save/load global: totul merge bine
	
	
	save_data.data= Time.get_date_string_from_system()
	save_data.ora= Time.get_time_string_from_system()

	

	
	
	
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
			#print("✔️ Item salvat:", item_data)  # Debugging

#--------------------------------------------------------------------------------------------------------------------------------------------




	#var cycle_data={}
	#for ciclu in cycle_zi_noapte:
		#var minute = ciclu.get_node("%Minute")
		#var hour = ciclu.get_node("%Hour")
		#print("save timp: ",hour.text,minute.text)
		#cycle_data = {
	#"hour": hour.text,
	#"minute": minute.text
	#}
	#save_data.cicli=cycle_data
#




	save_data.saved_ogor_tiles=saved_ogor_tiles
	#print("tilelelelele",save_data.saved_ogor_tiles)

	#var save_tilemap = {}
#
	#for layer_node in tile.get_children():
		#if layer_node is TileMapLayer:
			#var layer_data = []
			#for coord in layer_node.get_used_cells():  # presupunem o singură layer index per TileMap
				#var tile_id = layer_node.get_cell_source_id( coord)
				#var atlas_coords = layer_node.get_cell_atlas_coords( coord)
				#
				#var tile_info = {
					#"coord": coord,
					#"tile_id": tile_id,
					#"atlas_coords": atlas_coords
				#}
				#layer_data.append(tile_info)
			#
			## Folosim numele nodului ca identificator de layer
			#save_data.save_tilemap[layer_node.name] = layer_data




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
		#print("oven::::::::",oven_items)

#--------------------------------------------------------------------------------------------------------------------------------------------



	if textura:
		var image = textura.get_image()
		var image_bytess = image.save_png_to_buffer()  # <--- în loc de save_png(path)

		save_data.image_bytes = image_bytess  # Salvezi bytes, nu path
		save_data.textura = textura
		save_data.textura_path =textura_path  # Nu mai ai nevoie de path





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
		#print("PILLAR DEBUG:", pillar_items)


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
	#"light_visible": false
	}

	if players.size() > 0:  # Verificăm dacă există un player
		var player = players[0]  # Luăm primul player
		player_data = {
		"position": player.position,
		"health":player.health,
		"speed":player.speed,
		#"light_visible": player.light.visible
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
	#var generator_data = {}

	for generator in generatori:
		var nname = "gen_" + str(generator.get_instance_id())  # ID unic aici
		var slot = generator.get_node_or_null("CanvasLayer/SlotContainer")
		var slot_data = {}

		if slot and slot is Slot:
			slot_data = {
				"ID": slot.get_id(),
				"CANTITATE": slot.cantitate,
				"NUME": slot.get_nume(),
				"TEXTURE": ItemData.get_texture(slot.get_id())
			}

		generator_data[nname] = {
			"position": generator.position,
			"progress_bar": generator.progress_bar.value,
			"timp_ramas": generator.timp_ramas,
			"generator_on": generator.generator_on,
			"legat": generator.legat,
			"slot": slot_data
		}

	save_data.generator_things = generator_data
	#print("🔋 Generator things saved:", save_data.generator_things)







#----------------------------------------------SAVE ENEMY------------------------------------------------------------------------------------

	var enemy_list = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_data = {
			"scene_path": enemy.scene_path,  # Salvezi calea scenei originale (sau un "enemy_type")
			"position": enemy.position,
			"health": enemy.health,
			"speed": enemy.Speed
		}
		enemy_list.append(enemy_data)
	save_data.enemy_data = enemy_list
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




	var boats = get_tree().get_nodes_in_group("barca")
	var barca_data = {
	}

	for barca in boats:
		barca_data[barca.name] = {
		"position": barca.position,
		"is_anchored":barca.is_anchored,
		"ancorare":barca.ancorare,
		"miscare":barca.miscare,
		"random_move_active":barca.random_move_active,
		"player_in_proximity":barca.player_in_proximity,
		"change_direction_timer":barca.change_direction_timer

		}
	
	save_data.barca_data = barca_data




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
			#print("✔️ Copac salvat la:", rock.position)

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
	#print("radacina---------: ", radacina_data)

#---------------------------------------------------------------------------------------------------------------------------------------------------



	for object in get_tree().get_nodes_in_group("Persist"):
		if object.has_method("save_data"):
			object.save_data()


func load_data(data : SaveData)->void:
	var steps = 14  # numărul total de pași (update dacă adaugi altele)
	var current_step = 0
	
	current_step += 1
	await step("Se încarcă ora...", current_step, steps)
	data_ora(data)
	await get_tree().create_timer(0.2).timeout
	
	current_step += 1
	await step("Player...", current_step, steps)
	load_player(data)
	await get_tree().create_timer(0.2).timeout
	
	current_step += 1
	await step("Enemy...", current_step, steps)
	load_enemy(data)
	await get_tree().create_timer(0.2).timeout
	
	current_step += 1
	await step("Rețete...", current_step, steps)
	load_recipe(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Găini...", current_step, steps)
	load_gaina(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Iteme...", current_step, steps)
	load_items(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Generator...", current_step, steps)
	load_generator(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Cufere...", current_step, steps)
	load_chest(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Stâlpi...", current_step, steps)
	load_pilar(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Copaci...", current_step, steps)
	load_copaci(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Tufișuri...", current_step, steps)
	load_bush(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Bărci...", current_step, steps)
	load_barci(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Rădăcini...", current_step, steps)
	load_radacini(data)
	await get_tree().create_timer(0.1).timeout
	
	current_step += 1
	await step("Texturi...", current_step, steps)
	load_textura(data)
	await get_tree().create_timer(0.1).timeout
	
	await get_tree().create_timer(0.1).timeout
	
	
	#MenuSaveLoad.data=data.data
	#MenuSaveLoad.ora=data.ora
	
   # sau save_data.ora
#--------------------------------------------------------------------------------------------------------------------------------------------


	#var loaded_data = data["cicli"]
	#for ciclu in cycle_zi_noapte:
		#var minute = ciclu.get_node("%Minute")
		#var hour = ciclu.get_node("%Hour")
		#hour.text = str(loaded_data["hour"])
		#minute.text = str(loaded_data["minute"])
		#print("ora si minutul: ",hour.text,minute.text)



	for entry in data.saved_ogor_tiles:
		print("tilemap",entry)
		var pos = entry["pos"]
		var tile_ogor = entry["tile"]
		get_node("/root/world/TileMap/ogor").set_cell(pos, 2, tile_ogor)



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
	#"light_visible": false
	}

	if players.size() > 0:  # Verificăm dacă există un player
		var player = players[0]  # Luăm primul player
		player_data = {
		"position": player.position,
		"health":player.health,
		"speed":player.speed,
		#"light_visible": player.light.visible
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


	var enemy_list = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_data = {
			"scene_path": enemy.scene_path,  # Salvezi calea scenei originale (sau un "enemy_type")
			"position": enemy.position,
			"health": enemy.health,
			"speed": enemy.Speed
		}
		enemy_list.append(enemy_data)
	save_data.enemy_data = enemy_list

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
			#print("✔️ Item salvat:", item_data)  # Debugging
			
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
		#print("oven::::::::",oven_items)

#-----------------------------------------------------------------------------------------------------------------------------------------------







#---------------------------------------------SAVE ROCKS---------------------------------------------------------------------------------------

	var rocks = get_tree().get_nodes_in_group("rock")
	if rocks.size() > 0:  
		for rock in rocks:
			save_data.rocks_position.append(rock.position)  # Adăugăm fiecare poziție
			#print("✔️ Copac salvat la:", rock.position)

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
	

	for generator in generatori:
		var namee = "gen_" + str(generator.get_instance_id())  # ID unic aici
		var slot = generator.get_node_or_null("CanvasLayer/SlotContainer")
		var slot_data = {}

		if slot and slot is Slot:
			slot_data = {
				"ID": slot.get_id(),
				"CANTITATE": slot.cantitate,
				"NUME": slot.get_nume(),
				"TEXTURE": ItemData.get_texture(slot.get_id())
			}

		generator_data[namee] = {
			"position": generator.position,
			"progress_bar": generator.progress_bar.value,
			"timp_ramas": generator.timp_ramas,
			"generator_on": generator.generator_on,
			"legat": generator.legat,
			"slot": slot_data
		}

	save_data.generator_things = generator_data
	#print("🔋 Generator things saved:", save_data.generator_things)





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
		#print("PILLAR DEBUG:", pillar_items)


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



	var boats = get_tree().get_nodes_in_group("barca")
	var barca_data = {
	}

	for barca in boats:
		barca_data[barca.name] = {
		"position": barca.position,
		"is_anchored":barca.is_anchored,
		"ancorare":barca.ancorare,
		"miscare":barca.miscare,
		"random_move_active":barca.random_move_active,
		"player_in_proximity":barca.player_in_proximity,
		"change_direction_timer":barca.change_direction_timer

		}
	
	save_data.barca_data = barca_data
	


#----------------------------------------------SAVE RADACINI----------------------------------------------------------------------------------

	var radacini = get_tree().get_nodes_in_group("radacina")
	var radacina_data = {}
	for radacina in radacini:
		radacina_data[radacina.name] = {
			"position": radacina.position,
			"index_taiere": radacina.index_taiere,
			}
	save_data.radacina_data = radacina_data



	
	
	
	
	
	save_data.saved_ogor_tiles=saved_ogor_tiles
	
	#var save_tilemap = {}
#
	#for layer_node in tile.get_children():
		#if layer_node is TileMap:
			#var layer_data = []
			#for coord in layer_node.get_used_cells(0):  # presupunem o singură layer index per TileMap
				#var tile_id = layer_node.get_cell_source_id(0, coord)
				#var atlas_coords = layer_node.get_cell_atlas_coords(0, coord)
				#
				#var tile_info = {
					#"coord": coord,
					#"tile_id": tile_id,
					#"atlas_coords": atlas_coords
				#}
				#layer_data.append(tile_info)
			#
			## Folosim numele nodului ca identificator de layer
			#save_data.save_tilemap[layer_node.name] = layer_data
			
			
	if textura:
		var image = textura.get_image()
		var image_bytess = image.save_png_to_buffer()  # <--- în loc de save_png(path)

		save_data.image_bytes = image_bytess  # Salvezi bytes, nu path
		save_data.textura = textura
		save_data.textura_path =textura_path  # Nu mai ai nevoie de path
		
		
		
	save_data.data=  Time.get_date_string_from_system()
	save_data.ora= Time.get_time_string_from_system()


		
	#var cycle_data={}
	#for ciclu in cycle_zi_noapte:
		#var minute = ciclu.get_node("%Minute")
		#var hour = ciclu.get_node("%Hour")
		#cycle_data = {
	#"hour": hour.text,
	#"minute": minute.text
	#}
	#save_data.cicli=cycle_data
	
#---------------------------------------------------------------------------------------------------------------------------------------------------


	return save_data

func load_player(data:SaveData):
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
		#new_player.light.visible=data["player_data"]["light"]
		print("NEW HEALTH: ",new_player.health)
		tile_map.player=new_player
		inv.player = new_player
		new_player.add_to_group("player")
		inv.connect("attacking", Callable(new_player, "_on_inv_attacking"))
		world.add_child(new_player)
		await get_tree().process_frame
		if is_instance_valid(new_player):
			panel.connect("mouse_entered", Callable(new_player, "_on_panel_container_mouse_entered"))
			panel.connect("mouse_exited", Callable(new_player, "_on_panel_container_mouse_exited"))
			new_player.healthbar_player.value = new_player.health
			var player_camera = new_player.get_node_or_null("Camera2D")  
			if player_camera:
				player_camera.make_current()
		var stat = MenuSaveLoad.get_node("info/VBoxContainer/HBoxContainer/GridContainer")
		stat.player_reference=new_player
		stat.update_stats()
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.player = new_player

func load_enemy(data:SaveData):
	# Ștergem EXISTENȚII înamici înainte de a încărca
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()

	# Aducem înapoi fiecare enemy din salvare
	for enemy_data in data["enemy_data"]:
		if enemy_data.has("scene_path"):
			var enemy_scene = load(enemy_data["scene_path"])
			var new_enemy = enemy_scene.instantiate()
			
			new_enemy.position = enemy_data["position"]
			new_enemy.health = enemy_data["health"]
			new_enemy.Speed = enemy_data["speed"]

			world.add_child(new_enemy)

	
func load_recipe(data:SaveData):
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


func load_gaina(data:SaveData):
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
		

func load_items(data:SaveData):
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
				#else:
					#print("⚠️ Textura nu există:", texture_path)
			#else:
				#print("⚠️ Eroare: TEXTURE nu este un string valid!", item_data["TEXTURE"])
			world.add_child(new_item)
			#print("✔️ Item încărcat:", new_item)


func load_generator(data:SaveData):
	for child in get_tree().get_nodes_in_group("pow_gen"):
		child.queue_free()
		
	for namee in data.generator_things.keys():
		print("11111111111111111111111111111111111111111111111111",data.generator_things )
		var info = data.generator_things[namee]
		var new_gen = load("res://Scene/power_generator.tscn").instantiate()
		new_gen.name = namee
		#print("🔁 Loaded generator:", new_gen.namee)
		new_gen.position = info["position"]
		if is_instance_valid(new_gen.progress_bar):
			new_gen.progress_bar.value = info["progress_bar"]
		new_gen.timp_ramas = info["timp_ramas"]
		new_gen.generator_on = info["generator_on"]
		new_gen.legat = info["legat"]
		world.add_child(new_gen)
		
		for pillar in get_tree().get_nodes_in_group("LightSource"):
			if pillar.has_method("assign_closest_generator"):
				pillar.assign_closest_generator()
				
		# slot setup (cum aveai tu deja)
		var slot = new_gen.get_node("CanvasLayer/SlotContainer")
		if slot and info.has("slot"):
			var texture_path = "res://assets/" + info["slot"]["TEXTURE"]
			var texture = null
			if ResourceLoader.exists(texture_path): 
				texture = load(texture_path)
			slot.set_property({
				"TEXTURE": texture,
				"CANTITATE": info["slot"]["CANTITATE"],
				"NUMBER": int(info["slot"]["ID"]),
				"NUME": info["slot"]["NUME"]
			})

		new_gen.add_to_group("pow_gen")


func load_chest(data:SaveData):
	for i in range(min(inv.grid_container.get_child_count(),data.inv_item.size())):
		var child = inv.grid_container.get_child(i)
		if child is Slot: 
			child.clear_item()
			var item_data= data.inv_item[i]
			#print("DEBUG - Item data:", item_data,"i: ",i)
			var item_id = str(item_data.get("NUMBER", item_data.get("ID")))  # Convertim în string
			var item_cantitate = int(item_data.get("CANTITATE", 1))  # Asigurăm că e int
		
			child.inv.add_item(item_id, item_cantitate)
			child.filled = true
			#print("Inventar încărcat cu succes!")
		#else:
			#print("Eroare la încărcarea inventarului.")
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
				#print("Textura lipsă pentru", item_data["NUME"])
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
			#print("Inventar încărcat cu succes!")
		#else:
			#print("Eroare la încărcarea inventarului.")
			

func load_pilar(data:SaveData):
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
			#print("elec_slot: ",slot_data,)
		#print("elec_data: ", data.elec_pillar_data,)

func load_copaci(data:SaveData):
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
		#print("Timer la load pentru ", copac_name, ": ", copac_data["respawn_fruits"]["time_left"])
		#new_copac.respawn_fruits.is_stopped = copac_data["respawn_fruits"]["is_stopped"]
		#new_copac.respawn_fruits.time_left = copac_data["respawn_fruits"]["time_left"]
		world.add_child(new_copac)


func load_bush(data:SaveData):
	for bush in get_tree().get_nodes_in_group("bush"):
		if bush.name in data.bush_data:
			var info = data.bush_data[bush.name]

			bush.position = info["position"]
			bush.index_taiere = info["index_taiere"]
			bush.timer_respawn.wait_time = info["respawn_fruits"]["wait_time"]

			#var bush_fructe_sprite = bush.get_node("StaticBody2D/Bush_fructe")
			#var bush_normal_sprite = bush.get_node("StaticBody2D/Bush_normal")


func load_barci(data: SaveData):
	# Ștergem bărcile existente
	for ba in barci:
		if is_instance_valid(ba):  # verificăm dacă barca mai există
			ba.queue_free()

	barci.clear()  # 💥 foarte important: curățăm lista de referințe vechi!

	# Creăm bărcile noi
	for barca_name in data["barca_data"].keys(): 
		var boat_data = data["barca_data"][barca_name]
		var new_boat = preload("res://Scene/barca.tscn").instantiate()

		new_boat.position = boat_data["position"]
		new_boat.is_anchored = boat_data["is_anchored"]
		new_boat.miscare = boat_data["miscare"]
		new_boat.random_move_active = boat_data["random_move_active"]
		new_boat.player_in_proximity = boat_data["player_in_proximity"]

		world.add_child(new_boat)

		# Adăugăm noua barcă în lista barci!
		barci.append(new_boat)



func load_radacini(data:SaveData):
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
		



func load_textura(data: SaveData):
	if data.image_bytes.size() > 0:
		var image = Image.new()
		if image.load_png_from_buffer(data.image_bytes) == OK:
			textura = ImageTexture.create_from_image(image)
			for txt in texture_rect_menu:
				txt.texture = textura
			print("✅ Textura încărcată din bytes.")
		else:
			print("❌ Eroare la reconstruirea texturii din bytes.")
	else:
		print("⚠️ Nu există date pentru textură.")



func data_ora(data:SaveData):
	data_dir=data.data
	ora_dir=data.ora
	



func _ready() -> void:
	#inv.instantiate_chest()
	pass



func _process(_delta: float) -> void:
	pass
