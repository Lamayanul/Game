extends PanelContainer

#------------------------------grid-uri--------------------------------------------------------------
@onready var grid_container = $MarginContainer/GridContainer

var ditto_repeat=0
var fantana = null
var slot_container_8: Node = null
var slot_container_9: Node = null

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


#-------------------------------diverse--------------------------------------------------------------
@onready var texture_rect = $MarginContainer/TextureRect
@export var plin:int =0

#--------------------------noduri-principale--------------------------------------------------------
var selected_slot: Slot = null  # Slotul selectat
@onready var tile_map = get_node_or_null("/root/world/Tilemap")

# Owner logic
var owner_node: Node = null

var timp_ramas=0
@onready var timer: Timer = $Timer
var player_light = null 

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
@onready var tray_container = get_node_or_null("/root/world/CanvasLayer/Masa/TextureRect")

# AI Timer
var ai_timer: Timer = null
var ai_loadout: Resource = null # Referință la EnemyLoadout
var ai_active: bool = true # Master switch for AI

var _is_syncing: bool = false # Guard flag for recursion

#---------------------------------------Helper Functions------------------------------------------------
func _find_owner():
	var node = self
	# Traverse up to find the character
	for i in range(5): # Check up to 5 levels up
		var p = node.get_parent()
		if not p: break
		if p.is_in_group("enemy") or p.is_in_group("player"):
			return p
		node = p
	return get_node_or_null("/root/world/player") # Fallback

#---------------------------------------add_item()-----------------------------------------------------
func add_item(ID="", item_cantita=1, curse=null, effects=null, ditto=false) -> bool:
	# Debug print
	# print("Attempting to add item: ", ID, " to owner: ", owner_node.name if owner_node else "null")

	var item_texture = load("res://assets/" + ItemData.get_texture(ID))
	var item_nume    = ItemData.get_nume(ID)
	var item_number  = ItemData.get_number(ID)
	var item_raritate = ItemData.get_raritate(ID)
	var item_curse   = curse
	var item_effects = _normalize_effects(effects)
	var item_type = ItemData.get_type(ID)
	var item_ditto = ditto
	var item_durability = ItemData.get_durability(ID)

	var item_data = {
		"TEXTURE": item_texture,
		"CANTITATE": int(item_cantita),
		"NUMBER": item_number,
		"NUME": item_nume,
		"RARITATE": item_raritate,
		"CURSE": item_curse,
		"EFFECTS": item_effects,
		"TYPE": item_type,
		"DITTO":item_ditto,
		"DURABILITY":item_durability,
	}

	# 1) stack existing
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot and child.filled:
			if _can_stack_slot_with(child, ID, item_curse, item_effects):
				child.cantitate += int(item_cantita)
				child.set_property({
					"TEXTURE": child.get_texture(),
					"CANTITATE": child.cantitate,
					"NUMBER": item_number,
					"NUME": item_nume,
					"RARITATE": item_raritate,
					"CURSE": item_curse,
					"EFFECTS": item_effects,
					"TYPE": item_type,
					"DITTO": item_ditto,
					"DURABILITY":item_durability,
				})
				_apply_to_player_from_slot(child)
				return true

	# 2) empty slot
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot and not child.filled:
			child.set_property(item_data)
			child.filled = true
			plin += 1
			_apply_to_player_from_slot(child)
			
			if owner_node and owner_node.has_node("StatusEffects"):
				var se = owner_node.get_node("StatusEffects")
				se.apply_from_slot(child)
				se.refresh_holding(grid_container)
			return true

	return false


func _normalize_effects(v) -> Array:
	if v == null: return []
	if v is Array: return v
	if v is Dictionary: return [v]
	return []

func _effect_fingerprint(e: Dictionary) -> String:
	var id      := String(e.get("id","")).to_lower()
	var mode    := String(e.get("mode",""))
	var amount  := str(e.get("amount", 0))
	var dur     := str(e.get("duration", 0)) 
	var period  := str(e.get("period", 1))
	var tags    := ""
	if e.has("tags") and e["tags"] is Array:
		var t := []
		for x in e["tags"]: t.append(String(x).to_lower())
		t.sort()
		tags = ",".join(t)
	return "%s|%s|%s|%s|%s|%s" % [id, mode, amount, dur, period, tags]

func _effects_signature(v) -> String:
	var arr := _normalize_effects(v)
	var sigs := []
	for e in arr:
		if e is Dictionary: sigs.append(_effect_fingerprint(e))
	sigs.sort()
	return "|".join(sigs)

func _curse_signature(v) -> String:
	if v == null or not (v is Dictionary): return ""
	var id   := String(v.get("id","")).to_lower()
	var mode := String(v.get("mode",""))
	var tags := ""
	if v.has("tags") and v["tags"] is Array:
		var t := []
		for x in v["tags"]: t.append(String(x).to_lower())
		t.sort()
		tags = ",".join(t)
	var mods_sig := ""
	if v.has("modifiers") and v["modifiers"] is Dictionary:
		var keys = v["modifiers"].keys()
		keys.sort()
		var parts := []
		for k in keys: parts.append("%s=%s" % [String(k), str(v["modifiers"][k])])
		mods_sig = "|".join(parts)
	return "%s|%s|%s|%s" % [id, mode, mods_sig, tags]

func _can_stack_slot_with(child: Slot, item_id: String, curse, effects) -> bool:
	if child.get_id() != item_id: return false
	var cur_sig_child := _curse_signature(child.get_curse())
	var cur_sig_new   := _curse_signature(curse)
	if cur_sig_child != cur_sig_new: return false
	var eff_sig_child := _effects_signature(child.get_effects())
	var eff_sig_new   := _effects_signature(effects)
	return eff_sig_child == eff_sig_new

#--------------------------------_ready()----------------------------------------------------------------
func _ready():
	owner_node = _find_owner()
	
	fantana = get_node_or_null("/root/world/Fantana")
	if owner_node:
		player_light = owner_node.get_node_or_null("PointLight2D")

	for child in grid_container.get_children():
		if child is Slot:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))
			child.connect("item_activated", Callable(self, "_on_item_activated"))
	
	if texture_rect:
		texture_rect.top_level = false 
		texture_rect.z_index = 5
		texture_rect.custom_minimum_size = Vector2(64, 64)
		texture_rect.size = Vector2(64, 64)
		texture_rect.visible = false 
	
	slots = [slot_container, slot_container_2, slot_container_3, slot_container_4]
	
	for slot in grid_container.get_children():
		if slot.has_signal("request_tray_spawn"):
			slot.connect("request_tray_spawn", Callable(self, "_on_slot_right_clicked"))

	# Start AI logic if this inventory belongs to an enemy
	var is_enemy = false
	if owner_node:
		if owner_node.is_in_group("enemy") or owner_node.name.contains("Jake") or owner_node.name.contains("Caracter"):
			is_enemy = true
			
	if is_enemy:
		equip_random_items()
		
		ai_timer = Timer.new()
		ai_timer.wait_time = 2.5 
		ai_timer.one_shot = false
		ai_timer.connect("timeout", Callable(self, "_on_ai_tick"))
		add_child(ai_timer)
		ai_timer.start() 
		
	# Select a slot (any slot) if possible to ensure selection state
	if grid_container.get_child_count() > 0:
		var first_slot = grid_container.get_child(0)
		if first_slot is Slot:
			# Deferred to ensure global_position is correct after layout
			call_deferred("_on_slot_selected", first_slot)

func _on_slot_right_clicked(item_data):
	if tray_container:
		var tray_slot = SlotTrayScene.instantiate()
		tray_slot.get_node("TextureHolder/TextureRect2").texture=null
		tray_slot.slot_type="tray"
		tray_container.add_child(tray_slot)
		tray_slot.set_property(item_data)  

#-----------------------------------selectie-slot----------------------------------------------------
func _on_slot_selected(slot: Slot):
	if _is_syncing: return
	
	# If player, hide info
	if selected_slot and is_instance_valid(owner_node) and owner_node.get("info"):
		selected_slot.deselect()
		owner_node.info=""
	
	selected_slot = slot  
	selected_slot.select()
	
	update_selector_position(slot)
	
	# Refresh Status Effects for the owner (Jake card)
	if owner_node and owner_node.has_node("StatusEffects"):
		var se = owner_node.get_node("StatusEffects")
		se.refresh_holding(grid_container)
	
	# Equip logic
	if slot.get_texture() != null and is_instance_valid(owner_node):
		_is_syncing = true
		if owner_node.has_method("equip_item"):
			owner_node.equip_item(slot.get_texture(), slot.get_nume(), slot.get_raritate())
		else:
			# Fallback if method missing
			_enemy_equip_visuals(slot.get_id())
		_is_syncing = false

	var wid = _weapon_id_from_slot(slot)
	if wid != "":
		emit_signal("weapon_equip_request", wid)

func _enemy_equip_visuals(id: String):
	if owner_node.has_node("arma"):
		var arma = owner_node.get_node("arma")
		if id in ["2", "9", "10", "13", "14"]:
			arma.visible = true
		else:
			arma.visible = false

# ... Helper format functions ...
func _join(arr: Array, sep: String) -> String:
	var out := ""
	for i in arr.size():
		out += str(arr[i])
		if i < arr.size() - 1:
			out += sep
	return out

func _fmt_any(v: Variant) -> String:
	if v == null: return "null"
	if v is Dictionary:
		var kv := []
		for k in v.keys(): kv.append("%s=%s" % [str(k), _fmt_any(v[k])])
		kv.sort()
		return _join(kv, ", ")
	if v is Array:
		var items := []
		for it in v: items.append(_fmt_any(it))
		return _join(items, ", ")
	return str(v)

func _fmt_modifiers(mods: Dictionary) -> String:
	var kv := []
	for k in mods.keys(): kv.append("%s=%s" % [str(k), str(mods[k])])
	kv.sort()
	return _join(kv, ", ")

func _fmt_curse(c: Variant) -> String:
	if c == null: return "—"
	if c is Dictionary:
		var id := String(c.get("id", "?"))
		var parts := []
		if c.has("mode"): parts.append("mode=" + String(c["mode"]))
		if c.has("duration"): parts.append("duration=" + str(c["duration"]))
		if c.has("period"): parts.append("period=" + str(c["period"]))
		if c.has("modifiers") and c["modifiers"] is Dictionary and not c["modifiers"].is_empty():
			parts.append("modifiers: " + _fmt_modifiers(c["modifiers"]))
		var skip := ["id","mode","duration","period","modifiers"]
		for k in c.keys():
			if k in skip: continue
			parts.append("%s=%s" % [str(k), _fmt_any(c[k])])
		var tail := "" if parts.is_empty() else " (" + _join(parts, ", ") + ")"
		return "\n• " + id + tail
	return str(c)

func _fmt_effects(eff: Variant) -> String:
	if eff == null: return "—"
	var arr: Array = []
	if eff is Array: arr = eff
	elif eff is Dictionary: arr = [eff]
	else: return str(eff)
	if arr.is_empty(): return "—"
	var lines: Array[String] = []
	for e in arr:
		if e is Dictionary:
			var id := String(e.get("id", "?"))
			var parts: Array[String] = []
			for k in e.keys():
				if k == "id": continue
				parts.append("%s = %s" % [str(k), str(e[k])])
			var tail := " (" + _join(parts, ", ") + ")" if parts.size() > 0 else ""
			lines.append("\n• %s%s" % [id, tail])
		else:
			lines.append("\n• " + str(e))
	return _join(lines, "\n")


const ITEMID_TO_WEAPONID := {
	"0":"FIST", "2": "AXE01", "9": "SWORD01",
}


func _apply_to_player_from_slot(slot: Slot) -> void:
	if not is_instance_valid(owner_node): return
	var se = owner_node.get_node_or_null("StatusEffects") as StatusEffects
	if se == null:
		return
	se.remove_from_slot(slot)
	se.apply_from_slot(slot)


func _weapon_id_from_slot(slot: Slot) -> String:
	var item_id = slot.get_id()
	if ItemData.has_method("get_weapon_ref"):
		return String(ItemData.get_weapon_ref(item_id))
	if ITEMID_TO_WEAPONID.has(item_id):
		return ITEMID_TO_WEAPONID[item_id]
	return ""

func update_selector_position(slot: Slot):
	if not texture_rect or not slot: return
	texture_rect.position = slot.position + grid_container.position
	texture_rect.visible = true

@onready var slot_container: Slot = $MarginContainer/GridContainer/SlotContainer
@onready var slot_container_2: Slot = $MarginContainer/GridContainer/SlotContainer2
@onready var slot_container_4: Slot = $MarginContainer/GridContainer/SlotContainer4
@onready var slot_container_3: Slot = $MarginContainer/GridContainer/SlotContainer3

var slots = []

#---------------------------------------input-uri-diverse----------------------------------------------------
func _input(event):
	if owner_node and owner_node.is_in_group("player") and not owner_node.is_in_group("enemy"):
		if Input.is_action_just_pressed("drop"): drop_selected_item()
		if Input.is_action_just_pressed("drop_1"): drop_selected_item_1()
		if Input.is_action_just_pressed("plantSeed"): plantare()
		if Input.is_action_just_pressed("attack"): attack()
		if Input.is_action_just_pressed("eat"): eat()

func transfer_item_to_slot(item_data: Dictionary, slot_container_aici: Node) -> bool:
	if typeof(item_data) == TYPE_DICTIONARY and item_data.has("NUMBER"):
		if slot_container_aici.get_id() == str(item_data["NUMBER"]):
			slot_container_aici.set_property({
				"TEXTURE": item_data["TEXTURE"],
				"CANTITATE": slot_container_aici.get_cantitate() + item_data["CANTITATE"],
				"NUMBER": item_data["NUMBER"],
				"NUME": item_data["NUME"]
			})
			return true
		elif slot_container_aici.get_id() == "0":
			slot_container_aici.set_property({
				"TEXTURE": item_data["TEXTURE"],
				"CANTITATE": item_data["CANTITATE"],
				"NUMBER": item_data["NUMBER"],
				"NUME": item_data["NUME"]
			})
			return true
	return false

func select_slot_by_index(indexx: int):
	if _is_syncing: return
	deselect_all()
	if indexx >= 0 and indexx < grid_container.get_child_count():
		var slot = grid_container.get_child(indexx)
		if slot is Slot:
			_on_slot_selected(slot)
			if is_instance_valid(fantana):
				fantana.afisare_fill()

func deselect_all():
	for child in grid_container.get_children():
		if child is Slot:
			child.deselect()
	if texture_rect:
		texture_rect.visible = false

#---------------------------------drop-item-selected-----------------------------------------------------
func drop_selected_item():
	if selected_slot:
		var ID = selected_slot.get_id()
		if ID == "0": selected_slot.clear_item()
		
		if ID and is_instance_valid(owner_node):
			var cantiti=selected_slot.get_cantitate()
			var curse = selected_slot.get_curse()
			var effects = selected_slot.get_effects()

			if owner_node.has_node("StatusEffects"):
				var se = owner_node.get_node("StatusEffects") as StatusEffects
				se.remove_from_slot(selected_slot)
				se.refresh_holding(grid_container)
				if not se.can_drop_slot(selected_slot):
					return
			
			drop_item(ID,cantiti,curse, effects)
			
			selected_slot.clear_item()
			selected_slot.deselect()
			selected_slot = null
			
			if owner_node.has_method("inequip_item"):
				owner_node.inequip_item()
			else:
				if owner_node.has_node("arma"): owner_node.get_node("arma").visible = false
			
			if owner_node.is_in_group("enemy"):
				print("Enemy [AI] Dropped item: ", ID)

func update_inventory_status():
	plin = 0
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot and child.filled:
			plin += 1


func drop_item(ID: String, cantiti: int, curse: Variant, effects: Variant):
	if cantiti==0: return
	
	var item_cantitate = cantiti
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	var item_curse = curse
	var item_effects = effects
	
	var item_scene = load("res://User/Item.tscn") as PackedScene
	if item_scene and is_instance_valid(owner_node):
		var world_node = get_node("/root/world/")
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		item_instance.set_curse(item_curse)
		item_instance.set_effects(item_effects)
		item_instance.ID = ID
		item_instance.type="slot"
		
		var player_position = owner_node.global_position
		# Use last_direction or moveDirection
		var direction = Vector2.DOWN
		if owner_node.get("last_direction"):
			direction = owner_node.last_direction.normalized()
		elif owner_node.get("moveDirection"):
			direction = owner_node.moveDirection.normalized()
		
		var drop_distance = 20
		var drop_position = player_position + (direction * drop_distance)
		
		item_instance.position = drop_position 
		world_node.add_child(item_instance)
		
		if owner_node.has_method("inequip_item"):
			owner_node.inequip_item()

func drop_selected_item_1():
	if selected_slot:
		var ID = selected_slot.get_id()
		if ID == "0": selected_slot.clear_item()
		if ID and is_instance_valid(owner_node):
			var cantitate_de_drop = 1
			var curse = selected_slot.get_curse()
			var effects = selected_slot.get_effects()
			
			if selected_slot.decrease_cantitate(cantitate_de_drop): 
				selected_slot.clear_item()
				selected_slot.deselect()
				selected_slot = null
				plin -= 1
				if owner_node.has_method("inequip_item"):
					owner_node.inequip_item()
			
			if ID=="0": cantitate_de_drop=0
			drop_item(ID , cantitate_de_drop, curse, effects)
			update_inventory_status()
			
			if owner_node.is_in_group("enemy"):
				print("Enemy [AI] Dropped 1 unit of item: ", ID)

func plantare():
	var _tilemap=get_node("/root/world/TileMap")
	if selected_slot:
		var ID=selected_slot.get_id()
		if ID=="3":
			emit_signal("plantSeed")

func attack():
	if selected_slot:
		var ID=selected_slot.get_id()
		if ID=="2" || ID=="9" || ID=="10" || ID=="13" || ID=="22" || ID=="3":
			emit_signal("attacking",ID)

func drop_item_harvest(ID: String, cantiti: int,location:Vector2):
	var item_cantitate = cantiti
	if cantiti==0:
		plin=0
		return
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	var item_scene = load("res://User/item.tscn") as PackedScene
	if item_scene:
		var world_node = get_node("/root/world/")
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		item_instance.ID = ID
		var global_position1=tile_map.map_to_local(location)
		item_instance.position = global_position1
		world_node.add_child(item_instance)

func eat():
	# Permitem mâncatul în combat pentru Jake card
	if owner_node and owner_node.get("is_in_combat") and not (owner_node.name.contains("Jake") or owner_node.name.contains("Caracter")): 
		return
		
	if selected_slot == null: return
	var ID = selected_slot.get_id()
	
	# Verificăm dacă e mâncare (ID sau Tip)
	var is_food = false
	if ID in ["1", "3", "4", "5", "7", "8", "15", "24"]: is_food = true
	var types = selected_slot.get_type()
	if types and "food" in types: is_food = true
	
	if is_food:
		if owner_node.has_node("StatusEffects"):
			var se = owner_node.get_node("StatusEffects") as StatusEffects
			se.apply_on_use_from_slot(selected_slot)
			se.refresh_holding(grid_container)
		else:
			# Vindecăm Jake card
			if "current_hp" in owner_node:
				owner_node.current_hp = min(owner_node.current_hp + 20, owner_node.max_hp)
				if owner_node.has_method("_update_ui_elements"):
					owner_node._update_ui_elements()
			# Vindecăm inamicul din lume
			elif owner_node.get("health") != null:
				owner_node.health = min(owner_node.health + 20, 100)
				if owner_node.get("healthbar"): owner_node.healthbar.value = owner_node.health
		
		if selected_slot.decrease_cantitate(1):
			if owner_node.has_node("StatusEffects"):
				var se = owner_node.get_node("StatusEffects")
				se.remove_from_slot(selected_slot)
				se.refresh_holding(grid_container)
			selected_slot.clear_item()
			plin -= 1
			if owner_node.has_method("inequip_item"):
				owner_node.inequip_item()
		
		print("[Combat AI] Ate item: ", ItemData.get_nume(ID), " for owner: ", owner_node.name)

func drop_item_everywhere(ID: String, cantiti: int,location:Vector2):
	var item_cantitate = cantiti
	if cantiti==0:
		plin=0
		return
	var item_texture_path = "res://assets/" + ItemData.get_texture(ID)
	var item_texture = load(item_texture_path) as Texture
	var item_scene = load("res://User/Item.tscn") as PackedScene
	if item_scene:
		var world_node = get_node("/root/world/")
		var item_instance = item_scene.instantiate()
		item_instance.set_cantitate(item_cantitate)
		item_instance.set_texture1(item_texture)
		item_instance.ID = ID
		item_instance.position = location
		world_node.add_child(item_instance)

func has_shield() -> bool:
	if owner_node.is_in_group("player") and not owner_node.is_in_group("enemy"):
		owner_node.scut.visible=true
		owner_node.shield_touch.disabled=false
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		if slot is Slot:
			if slot.filled and slot.get_id() == "13":
				return true
	return false

func format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var secs = seconds % 60
	return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

func _on_item_activated(slot: Slot):
	if ditto_repeat==1: return
	var current_id = slot.get_id()
	var new_id = ""
	var all_ids = ItemData.content.keys()
	if slot.get_ditto():
		if all_ids.size() > 0:
			var random_id = all_ids.pick_random()
			print("Ditto transformat! ID vechi: ", current_id, " -> ID nou: ", random_id)
			new_id=random_id
			change_slot_item(slot, new_id)
			ditto_repeat=1
			return

func change_slot_item(slot: Slot, new_id: String):
	var new_tex = load("res://assets/" + ItemData.get_texture(new_id))
	var new_name = ItemData.get_nume(new_id)
	var new_number = ItemData.get_number(new_id)
	var new_raritate = ItemData.get_raritate(new_id)
	var new_type = ItemData.get_type(new_id)
	var old_quantity = slot.get_cantitate()
	
	slot.set_property({
		"TEXTURE": new_tex,
		"CANTITATE": old_quantity,
		"NUMBER": new_number,
		"NUME": new_name,
		"RARITATE": new_raritate,
		"TYPE": new_type,
		"EFFECTS": [],
		"CURSE": null,
		"DITTO":true,
		"DURABILITY":20,
	})
	
	if selected_slot == slot:
		_on_slot_selected(slot)

#=============================================================================
# AI LOGIC & RANDOM EQUIP
#=============================================================================

func equip_random_items():
	# Clear current
	for child in grid_container.get_children():
		if child is Slot: child.clear_item()
	
	print("Enemy [Init] Equipping random items for: ", owner_node.name)
	
	# Add some random items
	var possible_items = ["1", "2", "3", "7", "8", "9", "10", "13", "14", "15", "18", "25"]
	var count = randi_range(2, 5)
	
	for i in range(count):
		var id = possible_items.pick_random()
		add_item(id, 1)
	
	# Select a random slot (simulate equip)
	var slots_filled = []
	for i in range(grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child is Slot and child.filled:
			slots_filled.append(child)
	
	if slots_filled.size() > 0:
		var s = slots_filled.pick_random()
		_on_slot_selected(s)
		print("Enemy [Init] Auto-equipped: ", s.get_nume())

func _on_ai_tick():
	if not ai_active: return
	if not owner_node or not is_instance_valid(owner_node): return
	
	var in_combat = owner_node.get("is_in_combat") == true
	
	# Detectăm viața
	var current_h = 100.0
	var max_h = 100.0
	
	if "current_hp" in owner_node:
		current_h = owner_node.current_hp
		max_h = owner_node.max_hp
	elif "health" in owner_node:
		current_h = owner_node.health
	
	# În combat, AI-ul schimbă armele, dar poate selecta și mâncare dacă are HP scăzut
	if in_combat:
		var low_hp = current_h < (max_h * 0.5)
		_ai_switch_item(not low_hp) # Dacă are HP scăzut, allow_all (false), altfel only_weapons (true)
		return

	# În afara combat-ului, poate mânca automat
	var should_eat = false
	if ai_loadout:
		if current_h < (max_h * ai_loadout.heal_threshold):
			if randf() < ai_loadout.heal_chance:
				should_eat = true
	else:
		if current_h < (max_h * 0.4) and randf() < 0.2:
			should_eat = true
			
	if should_eat:
		if _ai_try_eat():
			return 

	if randf() < 0.6:
		_ai_switch_item(false) # Orice

func _ai_try_eat() -> bool:
	# Căutăm mâncare după tip
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		if slot is Slot and slot.filled:
			var types = slot.get_type()
			if types and "food" in types:
				_on_slot_selected(slot)
				eat()
				return true
	
	# Fallback ID-uri
	var food_ids = ["1", "3", "4", "5", "7", "8", "15", "24"]
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		if slot is Slot and slot.filled:
			if slot.get_id() in food_ids:
				_on_slot_selected(slot)
				eat()
				return true
	return false

func _ai_switch_item(only_weapons: bool = false):
	var candidates = []
	var weapon_ids = ["2", "9", "10", "13", "14", "22", "25"]
	
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		if slot is Slot and slot.filled:
			if only_weapons:
				if slot.get_id() in weapon_ids:
					candidates.append(slot)
			else:
				candidates.append(slot)
	
	print("[Combat AI] Switch Tick -> Candidates: ", candidates.size(), " (OnlyWeps: ", only_weapons, ")")
	
	if candidates.size() > 0:
		var s = candidates.pick_random()
		_on_slot_selected(s)
		print("Enemy [AI] Switched selection to: ", s.get_nume())
