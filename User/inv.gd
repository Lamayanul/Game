extends PanelContainer

#------------------------------grid-uri--------------------------------------------------------------
@onready var grid_container = $MarginContainer/GridContainer
@onready var grid = $"../../TileMap/Grid_ogor"  # Referința la grid
#@onready var slot_container_5 = get_node("/root/world/oven/CanvasLayer/Recipe/HBoxContainer/SlotContainer5")
#@onready var slot_container_7 = get_node("/root/world/oven/CanvasLayer/Recipe/HBoxContainer/SlotContainer2")
#@onready var slot_container_6 = get_node("/root/world/oven/CanvasLayer/Recipe/HBoxContainer/SlotContainer")
#
#
#@onready var slot_container_chest = get_node("/root/world/Chest/CanvasLayer/GridContainer/SlotContainer")
#@onready var slot_container_chest_2 = get_node("/root/world/Chest/CanvasLayer/GridContainer/SlotContainer2")
#@onready var slot_container_chest_3 = get_node("/root/world/Chest/CanvasLayer/GridContainer/SlotContainer3")
#@onready var slot_container_chest_4 = get_node("/root/world/Chest/CanvasLayer/GridContainer/SlotContainer4")
#
#@onready var slot_container_8: Slot = get_node("/root/world/Electricity_pillar/CanvasLayer/GridContainer/SlotContainer")
#@onready var slot_container_9: Slot = get_node("/root/world/Electricity_pillar/CanvasLayer/GridContainer/SlotContainer2")
#
#

var fantana = null
var slot_container_8: Node = null
var slot_container_9: Node = null
#@onready var oven = get_node("/root/world/oven")

#@onready var chest = get_node("/root/world/Chest")
var slot_container_5: Node = null
var slot_container_6: Node = null
var slot_container_7: Node = null

var chest: Node = null
var oven: Node = null
var pillar: Node =null
var gen:Node = null

var slot_container_chest: Node = null
var slot_container_chest_2: Node = null
var slot_container_chest_3: Node = null
var slot_container_chest_4: Node = null

#@onready var pillar = get_tree().get_nodes_in_group("LightSource")

#-------------------------------diverse---------------------------------------------------------------
@onready var texture_rect = $MarginContainer/TextureRect
@export var plin:int =0
@onready var info_label = $"../PanelContainer/VBoxContainer".get_node("InfoLabel")
@onready var hand_sprite = $"../PanelContainer".get_node("sprite")
#@onready var color_rect = $"../ColorRect"

#--------------------------noduri-principale--------------------------------------------------------
var selected_slot: Slot = null  # Slotul selectat
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
@export var chest_scene: PackedScene
@export var oven_scene: PackedScene
@export var pillar_scene : PackedScene
@export var gen_scene: PackedScene
#-----------------------------Semnale----------------------------------------------------------------

signal plantSeed
signal attacking
signal weapon_equip_request(weapon_id: String)
var SlotTrayScene = preload("res://User/slot_container.tscn") 
@onready var tray_container = get_node("/root/world/CanvasLayer/Masa/TextureRect")

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
func add_item(ID="", item_cantita=1, curse=null, effects=null) -> bool:
	
	var item_texture = load("res://assets/" + ItemData.get_texture(ID))
	var item_nume = ItemData.get_nume(ID)
	var item_number = ItemData.get_number(ID)
	var item_cantitate = item_cantita
	var item_raritate = ItemData.get_raritate(ID)
	var item_curse = curse
	var item_effects = effects
	var item_data = {"TEXTURE": item_texture, "CANTITATE": item_cantitate, "NUMBER": item_number, "NUME": item_nume, "RARITATE":item_raritate, "CURSE":item_curse, "EFFECTS":item_effects}

	#print("Încerc să adaug item ID:", ID, " Cantitate:", item_cantitate)

	# 1. Încearcă să stivuiască itemul dacă există deja în inventar
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot:
			#print("Slot", i, " - ID:", child.get_id(), " Filled:", child.filled)
			if child.filled and child.get_id() == ID:
				#print("Item găsit în slot", i, ". Stivuiesc...")
				child.cantitate += item_cantitate
				child.set_property({"TEXTURE": item_texture, "CANTITATE": child.cantitate, "NUMBER": item_number, "NUME": item_nume, "RARITATE":item_raritate, "CURSE":item_curse, "EFFECTS":item_effects})
				return true  # A reușit să adauge obiectul, returnează `true`
	
	# 2. Dacă nu există un slot cu același ID, caută un slot gol
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot:
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
	fantana = get_node_or_null("/root/world/Fantana")
	for child in grid_container.get_children():
		if child is Slot:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))

	
	  # Selectează automat primul slot
	if grid_container.get_child_count() > 0:
		var first_slot = grid_container.get_child(0)
		if first_slot is Slot:
			_on_slot_selected(first_slot)
	slots = [slot_container, slot_container_2, slot_container_3, slot_container_4]
	#print("Slots list:", slots)  # Verifică dacă toate sunt valide
	#
#func _process(_delta: float) -> void:
	#lamp()
	##has_backpack()
	for slot in grid_container.get_children():
		if slot.has_signal("request_tray_spawn"):
			slot.connect("request_tray_spawn", Callable(self, "_on_slot_right_clicked"))
	
func _on_slot_right_clicked(item_data):
		var tray_slot = SlotTrayScene.instantiate()
		tray_slot.get_node("TextureHolder/TextureRect2").texture=null
		tray_slot.slot_type="tray"
		tray_container.add_child(tray_slot)
		tray_slot.set_property(item_data)  
	
#-----------------------------------selectie-slot----------------------------------------------------
func _on_slot_selected(slot: Slot):
	if selected_slot and is_instance_valid(player):
		selected_slot.deselect()
		player.info=""
	
	
	selected_slot = slot  
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
		
		#slot.add_effect_dict({
	#"id": "regen",
	#"amount": 5,
	#"duration": 10.0
#})
		#slot.set_curse_dict({
	#"id": "fragile",
	#"modifiers": {"def_mult": 0.8}
#})

		var nume     = slot.get_nume()
		var raritate = slot.get_raritate()
		var curse = slot.get_curse()
		var effects = slot.get_effects()
		var curse_txt   = _fmt_curse(slot.get_curse())
		var effects_txt = _fmt_effects(slot.get_effects())


		
		info_label.bbcode_text = "[center]\nITEM: %s\nRARITATE: %s \nCURSE: %s \nEFFECTS: %s[/center]" % [nume, raritate, curse_txt, effects_txt]
		info_label.visible = true
		#color_rect.visible = false

	# Actualizează poziția selectorului
	update_selector_position(slot)
	
	# Echipează itemul la jucător
	#var player = get_node("/root/world/player")
	if  slot.get_texture() != null and is_instance_valid(player):
		player.equip_item(slot.get_texture(), slot.get_nume(), slot.get_raritate())
	var wid = _weapon_id_from_slot(slot)
	if wid != "":
		emit_signal("weapon_equip_request", wid)

# Mic utilitar pentru join (merge cu orice array)
func _join(arr: Array, sep: String) -> String:
	var out := ""
	for i in arr.size():
		out += str(arr[i])
		if i < arr.size() - 1:
			out += sep
	return out

func _fmt_curse(c: Variant) -> String:
	if c == null:
		return "—"
	if c is Dictionary:
		var id := String(c.get("id","?"))
		var mods := ""
		if c.has("modifiers") and c["modifiers"] is Dictionary:
			var kv := []
			for k in c["modifiers"].keys():
				kv.append("%s = %s" % [k, str(c["modifiers"][k])])
			mods = _join(kv, ", ")
		return "\n• "+id + ("" if mods == "" else " (" + mods + ")")
	return str(c)

	# Normalizează la Array
func _fmt_effects(eff: Variant) -> String:
	if eff == null:
		return "—"
	var arr: Array = []
	if eff is Array:
		arr = eff
	elif eff is Dictionary:
		arr = [eff]
	else:
		return str(eff)

	if arr.is_empty():
		return "—"

	var lines: Array[String] = []
	for e in arr:
		if e is Dictionary:
			var id := String(e.get("id", "?"))
			var parts: Array[String] = []
			for k in e.keys():
				if k == "id":
					continue
				parts.append("%s=%s" % [str(k), str(e[k])])
			var tail := " (" + _join(parts, ", ") + ")" if parts.size() > 0 else ""
			lines.append("\n• %s%s" % [id, tail])
		else:
			lines.append("\n• " + str(e))

	return _join(lines, "\n")




const ITEMID_TO_WEAPONID := {
	"0":"FIST",
	"2": "AXE01",
	"9": "SWORD01",
	# ...
}

func _weapon_id_from_slot(slot: Slot) -> String:
	var item_id = slot.get_id()        # ex: "2", "9", etc.
	# dacă ai așa ceva în ItemData, folosește-l:
	if ItemData.has_method("get_weapon_ref"):
		return String(ItemData.get_weapon_ref(item_id))
	# fallback: maparea locală
	if ITEMID_TO_WEAPONID.has(item_id):
		return ITEMID_TO_WEAPONID[item_id]
	return ""

func update_selector_position(slot: Slot):
	var slot_position = slot.get_global_position()
	texture_rect.global_position = slot_position
	
	
# Referințe la sloturile din inventar
@onready var slot_container: Slot = $MarginContainer/GridContainer/SlotContainer
@onready var slot_container_2: Slot = $MarginContainer/GridContainer/SlotContainer2
@onready var slot_container_4: Slot = $MarginContainer/GridContainer/SlotContainer4
@onready var slot_container_3: Slot = $MarginContainer/GridContainer/SlotContainer3

# Sloturile tale
var slots = []

#---------------------------------------input-uri-diverse----------------------------------------------------
func _input(event):
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
	if Input.is_action_just_pressed("consola"):
		pass
		
	if Input.is_action_just_pressed("slot_1"):
		select_slot_by_index(0)
	if Input.is_action_just_pressed("slot_2"):
		select_slot_by_index(1)
	if Input.is_action_just_pressed("slot_3"):
		select_slot_by_index(2)
	if Input.is_action_just_pressed("slot_4"):
		select_slot_by_index(3)
	if is_instance_valid(oven):
		if event is InputEventMouseButton and oven.in_zona == true:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				if selected_slot==null:
					return
				if selected_slot.get_item() != null:
					# Obține detaliile itemului din slotul selectat
					var item_data = selected_slot.get_item()

					# Încearcă să transferi itemul în slotul 6
					if transfer_item_to_slot(item_data, slot_container_6):
						# Dacă transferul este reușit, curăță itemul din slotul selectat
						selected_slot.clear_item()
						plin -= 1
						#print("Item transferat cu succes în slotul de crafting 6.")

					# Dacă transferul în slotul 6 a eșuat, încearcă în slotul 7
					elif transfer_item_to_slot(item_data, slot_container_7):
						# Dacă transferul este reușit, curăță itemul din slotul selectat
						selected_slot.clear_item()
						plin -= 1
						#print("Item transferat cu succes în slotul de crafting 7.")

					# Dacă niciun slot nu este disponibil, afișează un mesaj
					#else:
						#print("Ambele sloturi de crafting sunt deja pline. Nu mai există locuri libere.")
				#else:
					#print("Nu este niciun item selectat pentru transfer.")
					
		if event is InputEventMouseButton and chest.player_in_area == true:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				if selected_slot and selected_slot.get_item() != null:
					# Obține detaliile itemului din slotul selectat
					var item_data = selected_slot.get_item()

					# Încearcă să transferi itemul în slotul 6
					if transfer_item_to_slot(item_data, slot_container_chest):
						# Dacă transferul este reușit, curăță itemul din slotul selectat
						selected_slot.clear_item()
						plin -= 1
						#print("Item transferat cu succes în slotul de chest1.")

					# Dacă transferul în slotul 6 a eșuat, încearcă în slotul 7
					elif transfer_item_to_slot(item_data, slot_container_chest_2):
						# Dacă transferul este reușit, curăță itemul din slotul selectat
						selected_slot.clear_item()
						plin -= 1
						#print("Item transferat cu succes în slotul de chest2.")
						
					elif transfer_item_to_slot(item_data, slot_container_chest_3):
						# Dacă transferul este reușit, curăță itemul din slotul selectat
						selected_slot.clear_item()
						plin -= 1
						#print("Item transferat cu succes în slotul de chest3.")
						
					elif transfer_item_to_slot(item_data, slot_container_chest_4):
						# Dacă transferul este reușit, curăță itemul din slotul selectat
						selected_slot.clear_item()
						plin -= 1
						#print("Item transferat cu succes în slotul de chest4.")
					# Dacă niciun slot nu este disponibil, afișează un mesaj
					#else:
						#print("Toate sloturile sunt pline de chest.")
						#
				#else:
					#print("Nu este niciun item selectat pentru transfer.")
		#for p in pillar:
			#if p.pillar_area:
				#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
					#if selected_slot and selected_slot.get_item() != null:
						## Obține detaliile itemului din slotul selectat
						#var item_data = selected_slot.get_item()
	#
						## Încearcă să transferi itemul în slotul 6
						#if transfer_item_to_slot(item_data, slot_container_8):
							## Dacă transferul este reușit, curăță itemul din slotul selectat
							#selected_slot.clear_item()
							#plin -= 1
							#print("Item transferat cu succes în slotul de chest1.")
	#
						## Dacă transferul în slotul 6 a eșuat, încearcă în slotul 7
						#elif transfer_item_to_slot(item_data, slot_container_9):
							## Dacă transferul este reușit, curăță itemul din slotul selectat
							#selected_slot.clear_item()
							#plin -= 1
							#print("Item transferat cu succes în slotul de chest2.")


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
		if slot is Slot:
			_on_slot_selected(slot)
			if is_instance_valid(fantana):
				fantana.afisare_fill()

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
			var curse = selected_slot.get_curse()
			var effects = selected_slot.get_effects()
			# Convertește coordonatele mouse-ului în coordonatele locale ale TileMap
			#var mouse_position_global = get_viewport().get_mouse_position()
			#var mouse_position_local = world.to_local(mouse_position_global)
			# Drop itemul la poziția exactă a mouse-ului

			#drop_item(ID,cantiti)
			drop_item(ID,cantiti,curse, effects)
			
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
		if child is Slot and child.filled:
			plin += 1



#--------------------------------functie-drop-default--------------------------------------------------
func drop_item(ID: String, cantiti: int, curse: Variant, effects: Variant):
	# Obține textura și cantitatea din ItemData
	if cantiti==0:
		return
	
	var item_cantitate = cantiti
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	var item_curse = curse
	var item_effects = effects
	# Încarcă scena itemului
	var item_scene = load("res://User/Item.tscn") as PackedScene
	if item_scene and is_instance_valid(player) :
		# Instanțiază scena
		var world_node = get_node("/root/world/")
		
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		item_instance.set_curse(item_curse)
		item_instance.set_effects(item_effects)
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
			var curse = selected_slot.get_curse()
			var effects = selected_slot.get_effects()
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
			
			drop_item(ID , cantitate_de_drop, curse, effects)
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
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
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
		if slot is Slot:
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
		


func format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var secs = seconds % 60
	return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

#func lamp_inv():
	#if not timer.is_stopped():
		#var items = get_tree().get_nodes_in_group("item")
		#for item in items:
			#if item.ID=="23":
				#item.set_lumina("23")
