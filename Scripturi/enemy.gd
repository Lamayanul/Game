extends CharacterBody2D

var Speed = 20
var health=100
var player_inattack_range=false
@onready var animated_sprite_2d = $AnimatedSprite2D
var can_take_damage=true
@onready var take_damage = $take_damage
var player_current_attack=false
var original_color = Color(1, 1, 1, 1)  # Culoarea originală
var hit_color = Color(1, 0, 0, 1) 
@onready var color = $color
var knockback_force = 1000
var moveDirection = Vector2.ZERO
@onready var healthbar = $healthbar
@onready var animation_player = $AnimationPlayer
@onready var arma = $arma

var player_chase=false
@export var MoveSpeed: float = 20.0
var lastPosition=Vector2(0,1)
@onready var detection = $detection
var is_attacking = false  
@onready var player_hitbox =null
@onready var enemy_icon = get_node_or_null("/root/world/CanvasLayer/healthbar_enemy/enemy_icon")
@export var stop_distance: float = 20
@onready var atack = $atack
var stare_atac= false
@onready var doge: Timer = $doge
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $arma/AudioStreamPlayer2D
var already_hit = false 
var is_fleeing = false 
var player_in_zone =false
@onready var hitboxex = get_tree().get_nodes_in_group("player_hitbox")
@onready var text_rich_name = $CanvasLayer/Control2/ai_name
@export var scene_path: String = "res://Scene/enemy.tscn"


@export var ai_personality: String = "You are a white hair boy who like to girls"

var possible_names = ["MeowSky", "Clawzor", "Grumpy", "ShadowFang", "Bitey", "Mr. Whiskers", "RageCat", "Snarlz"]
@onready var namae  = ""

@onready var image = $CanvasLayer/Control2/TextureRect

@onready var aiText: RichTextLabel = $CanvasLayer/Control2/PanelContainer/VBoxContainer/HBoxContainer/RichTextLabel
@onready var textEdit: TextEdit = $CanvasLayer/Control2/PanelContainer/VBoxContainer/TextEdit
var deplasare=false
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var happy=0;
var angry=0;
var dictator=0;
var info:String=""
@export var war_type = "enemy"
@export var loadout: EnemyLoadout # <-- Aici tragi resursa în Inspector

var ai_target_set = false
var is_in_combat = false
var is_night_mode: bool = false # Tracks if it is currently night for this enemy
var default_texture: Texture2D = null # Store original texture
var active_combat_card: Node = null # Reference to the Jake instance in combat
var active_combat_logic: Node = null # Reference to the combat controller (BattleRoot)

var ai_tasks = []

	#process_ai_tasks()

func _check_day_night_cycle():
	var cycle = get_node_or_null("/root/world/Cycle_d_n")
	if not cycle: return
	
	# Night is between 20:00 and 06:00
	var should_be_night = cycle.current_hour >= 20 or cycle.current_hour < 6
	
	if should_be_night != is_night_mode:
		is_night_mode = should_be_night
		if loadout:
			call_deferred("_populate_inventory_from_loadout")
			print("Time Changed! Switching Loadout for ", self.name, " NightMode: ", is_night_mode)
			
			# UPDATE COMBAT
			if is_instance_valid(active_combat_logic):
				# Heal logic in combat
				if is_night_mode:
					if "enemy" in active_combat_logic:
						var heal_val = loadout.night_heal_amount
						if heal_val == -1:
							heal_val = active_combat_logic.enemy.max_hp
						
						active_combat_logic.enemy.hp = heal_val
						if active_combat_logic.has_method("_update_hp_ui"):
							active_combat_logic._update_hp_ui()
			
			# UPDATE COMBAT CARD IF ACTIVE
			if is_instance_valid(active_combat_card):
				# Update visuals on card
				if active_combat_card.has_method("set_visuals"):
					var tex = loadout.night_texture if is_night_mode else default_texture
					var bg = loadout.night_background if is_night_mode else null 
					active_combat_card.set_visuals(tex, bg)
				
				# Refresh items on card
				call_deferred("transfer_inventory_to_combat", active_combat_card)

			# Update Visuals in World (Portrait/Icon)
			if is_night_mode:
				var heal_val = loadout.night_heal_amount
				if heal_val == -1: heal_val = 100 # Assuming 100 is base max for world entity
				health = heal_val # Heal world entity too
				
				if loadout.night_texture:
					if image: image.texture = loadout.night_texture
					if enemy_icon: enemy_icon.texture = loadout.night_texture
			else:
				# Revert to default
				if default_texture:
					if image: image.texture = default_texture
					if enemy_icon: enemy_icon.texture = default_texture

func _populate_inventory_from_loadout():
	print("Populating Inventory... Night Mode:", is_night_mode)
	# Find inventory via Group "enemy_inv" in children
	var world_inv = null
	var inv_nodes = find_children("*", "", true, false)
	for node in inv_nodes:
		if node.is_in_group("enemy_inv"):
			world_inv = node
			break
	
	if not world_inv:
		# Fallback
		world_inv = get_node_or_null("CanvasLayer3/Inv")
		if not world_inv: world_inv = get_node_or_null("CanvasLayer/Inv")
		
	if world_inv and world_inv.has_method("add_item"):
		# Curățăm inventarul default (dacă avea chestii random)
		var grid = world_inv.get_node_or_null("MarginContainer/GridContainer")
		if grid:
			for slot in grid.get_children():
				if slot.has_method("clear_item"): slot.clear_item()
		
		# Adaugăm itemele din resursă
		var items_to_add = loadout.items
		
		# Check for Night Mode (Internal Flag)
		if is_night_mode and not loadout.night_items.is_empty():
			items_to_add = loadout.night_items
			print("Populating Night Loadout Items: ", items_to_add)
			
		for item_id in items_to_add:
			world_inv.add_item(item_id, 1)
			
		# Trimitem configurația AI către inventar
		if "ai_loadout" in world_inv:
			world_inv.ai_loadout = loadout
		
		print("Enemy Inventory Populated from Loadout: ", items_to_add)

func start_combat():
	if is_in_combat: return
	is_in_combat = true
	deplasare = true # Stop movement
	
	# Stop World Inventory AI immediately using Group
	var world_inv = null
	var inv_nodes = find_children("*", "", true, false)
	for node in inv_nodes:
		if node.is_in_group("enemy_inv"):
			world_inv = node
			break
	
	if not world_inv:
		# Fallback
		world_inv = get_node_or_null("CanvasLayer3/Inv")
		if not world_inv: world_inv = get_node_or_null("CanvasLayer/Inv")
	
	if world_inv:
		# Disable AI Logic Switch
		if "ai_active" in world_inv:
			world_inv.ai_active = false
		# Stop Timer
		if world_inv.get("ai_timer") and world_inv.ai_timer is Timer:
			world_inv.ai_timer.stop()
		print("World Inventory AI Disabled for: ", world_inv.name)
	else:
		print("ERROR: Could not find World Inventory (Group: enemy_inv) to disable AI!")
	
	var combat_scene_res = load("res://Scene/combat.tscn")
	if combat_scene_res:
		var combat_instance = combat_scene_res.instantiate()
		active_combat_logic = combat_instance # SAVE LOGIC REFERENCE
		get_tree().root.add_child(combat_instance)
		
		# Setup Jake in Enemy_ele
		var enemy_ele = combat_instance.get_node_or_null("CanvasLayer/Enemy_ele")
		if enemy_ele:
			# Clear previous
			for c in enemy_ele.get_children():
				c.queue_free()
			
			var jake_res = load("res://Fights/Caracters/Jake.tscn")
			if jake_res:
				var jake_inst = jake_res.instantiate()
				jake_inst.add_to_group("enemy") # Asigură detectarea AI-ului în inventar
				if "is_in_combat" in jake_inst:
					jake_inst.is_in_combat = true
				
				enemy_ele.add_child(jake_inst)
				active_combat_card = jake_inst # SAVE REFERENCE
				
				# Mirror anchors of the player card (Creator)
				jake_inst.anchor_left = 0.6
				jake_inst.anchor_top = 0.07
				jake_inst.anchor_right = 0.955
				jake_inst.anchor_bottom = 0.495
				
				# Reset offsets to ensure it fills the anchored area
				jake_inst.offset_left = 0
				jake_inst.offset_top = 0
				jake_inst.offset_right = 0
				jake_inst.offset_bottom = 0
				
				call_deferred("transfer_inventory_to_combat", jake_inst)

		# Inject AI Data into Combat
		if loadout and is_instance_valid(combat_instance):
			if not combat_instance.get("enemy"): 
				combat_instance.enemy = {"name": namae, "hp": health, "max_hp": 100}
			
			combat_instance.enemy["heal_threshold"] = loadout.heal_threshold
			combat_instance.enemy["heal_chance"] = loadout.heal_chance
			combat_instance.enemy["name"] = namae
			combat_instance.enemy["hp"] = health
			
			print("[Combat Init] Injected AI Loadout: Thresh=", loadout.heal_threshold, " Chance=", loadout.heal_chance)
			var cycle = get_node_or_null("/root/world/Cycle_d_n")
			print("cat e ora",cycle.current_hour)
			if cycle and cycle.current_hour >= 20:
				if loadout.night_texture:
					combat_instance.enemy["TextureRect/TextureRect2"] = loadout.night_texture
				if loadout.night_background:
					combat_instance.enemy["TextureRect/TextureRect"] = loadout.night_background

func transfer_inventory_to_combat(jake_inst):
	print("STARTING INVENTORY TRANSFER...")
	
	# Find via Group
	var world_inv = null
	var inv_nodes = find_children("*", "", true, false)
	for node in inv_nodes:
		if node.is_in_group("enemy_inv"):
			world_inv = node
			break
			
	if not world_inv:
		# Fallback
		world_inv = get_node_or_null("CanvasLayer3/Inv")
		if not world_inv: world_inv = get_node_or_null("CanvasLayer/Inv")
	
	if world_inv:
		print("World Inventory Found: ", world_inv.name)
		# Double-check stop AI
		if "ai_active" in world_inv: world_inv.ai_active = false
		if world_inv.get("ai_timer") and world_inv.ai_timer is Timer:
			world_inv.ai_timer.stop()
			
		# Target path in Jake.tscn: TextureRect/Inv
		if jake_inst.has_node("TextureRect/Inv"):
			print("Combat Inventory Found.")
			var combat_inv = jake_inst.get_node("TextureRect/Inv")
			
			if "ai_loadout" in combat_inv:
				combat_inv.ai_loadout = loadout
			
			# CLEAR COMBAT INVENTORY BEFORE TRANSFER
			var c_grid = combat_inv.get_node_or_null("MarginContainer/GridContainer")
			if c_grid:
				for slot in c_grid.get_children():
					if slot.has_method("clear_item"): slot.clear_item()

			var items_for_combat = []
			# Transfer items
			var w_grid = world_inv.get_node_or_null("MarginContainer/GridContainer")
			if w_grid:
				for w_slot in w_grid.get_children():
					if w_slot.has_method("get_id") and w_slot.filled:
						print("Transferring Item: ", w_slot.get_nume(), " ID: ", w_slot.get_id())

						# Fill side inventory (legacy)
						combat_inv.add_item(
							w_slot.get_id(),
							w_slot.get_cantitate(),
							w_slot.get_curse(),
							w_slot.get_effects()
						)

						# Prepare for new 8-slot system
						items_for_combat.append({
							"id": w_slot.get_id(),
							"qty": w_slot.get_cantitate(),
							"curse": w_slot.get_curse(),
							"effects": w_slot.get_effects()
						})

			if jake_inst.has_method("fill_combat_slots"):
				jake_inst.fill_combat_slots(items_for_combat)

	else:
		print("World Inventory NOT Found!")

func equip_item(item_texture: Texture, item_nume : String, item_raritate:String):
	if item_texture:
		# print("Enemy equipped: ", item_nume)
		info = "[center]ITEM: %s\nRARITATE: %s[/center]" % [item_nume, item_raritate]
		
		# Simple logic to enable weapon hitbox if it looks like a weapon
		# You might want to filter by ID or type if you have that info passed more explicitly
		# For now, we assume if it equips something, it might be a weapon or tool.
		#if item_nume.to_lower().contains("sword") or item_nume.to_lower().contains("axe") or item_nume.to_lower().contains("pickaxe"):
			#arma.visible = true
			#if arma.has_node("colisiune"):
				#$arma/colisiune.disabled = false
	else:
		# print("Texture is null")
		pass

func inequip_item():
	info = ""
	arma.visible = false
	if arma.has_node("colisiune"):
		$arma/colisiune.disabled = true

var visible_items = []

func _ready():
	#healthbar_enemy.value=0
	$ChangeDirection.start()
	add_to_group("enemy_hitbox")
	#select_new_direction()
	arma.visible=false
	$arma/colisiune.disabled=true
	for player_h in hitboxex:
		player_hitbox=player_h
	#image.texture=load("res://Icons/✗ 𝐭𝐚𝐭𝐬𝐮 ✗.png")
	namae = possible_names.pick_random()
	text_rich_name.text = namae
	
	# Store default texture for Day Mode
	if image and image.texture:
		default_texture = image.texture
	
	if loadout:
		call_deferred("_populate_inventory_from_loadout")
	
	# Real-time Time Check Timer
	var time_timer = Timer.new()
	time_timer.wait_time = 1.0
	time_timer.autostart = true
	time_timer.timeout.connect(_check_day_night_cycle)
	add_child(time_timer)
	
	#nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	if detection:
		if not detection.area_entered.is_connected(_on_detection_area_entered):
			detection.area_entered.connect(_on_detection_area_entered)
		if not detection.area_exited.is_connected(_on_detection_area_exited):
			detection.area_exited.connect(_on_detection_area_exited)


func get_player():
	return get_tree().get_first_node_in_group("player")

func _on_detection_area_entered(area):
	# Assuming Item.tscn -> Area2D. Parent is the Item (Sprite2D with script)
	# Check if the parent of the area is in group "item"
	var parent = area.get_parent()
	if parent and parent.is_in_group("item"):
		if not visible_items.has(parent):
			visible_items.append(parent)
			# print("Enemy saw item: ", parent.name)

func _on_detection_area_exited(area):
	var parent = area.get_parent()
	if parent and visible_items.has(parent):
		visible_items.erase(parent)

func scavenge_items():
	# Find nearest item
	var nearest = null
	var min_dist = INF
	
	# Clean up invalid items
	for i in range(visible_items.size() - 1, -1, -1):
		if not is_instance_valid(visible_items[i]):
			visible_items.remove_at(i)
			
	for item in visible_items:
		var d = global_position.distance_to(item.global_position)
		if d < min_dist:
			min_dist = d
			nearest = item
			
	if nearest:
		var dir = (nearest.global_position - global_position).normalized()
		velocity = dir * MoveSpeed
		movement() # Updates animation
		return true
	return false

#func go_to(pos: Vector2):
	#nav_agent.target_position = pos
	#
#func has_item(item: String) -> bool:
	## Schimbă cu sistemul tău de inventar
	#return true
#
#func pick_item(item: String):
	#print("AI picked up:", item)
#
#func deliver_item(item: String):
	#print("AI delivered:", item)
#
#func _on_velocity_computed(safe_velocity):
	#velocity = safe_velocity


func _physics_process(_delta):
	if is_in_combat:
		velocity = Vector2.ZERO
		return

	#process_ai_tasks()
	#if nav_agent.is_navigation_finished():
		## Task completat sau treci la următorul
		#return
	#var next_velocity = nav_agent.get_next_path_position() - global_position
	#velocity = next_velocity.normalized() * MoveSpeed
	#movement()
	#move_and_slide()
	

	if deplasare:
		velocity=Vector2.ZERO
		animated_sprite_2d.play("idle")
		return 
		
	if is_fleeing:
		move_and_slide()
		return  
		
	if not is_attacking:
		var scavenging = false
		
		# Priority: Flee > Chase > Scavenge > Wander
		if not is_fleeing and not player_chase:
			scavenging = scavenge_items()
			
		if not scavenging:
			velocity = moveDirection * MoveSpeed
			movement()
			
		move_and_slide()

#func find_nearest_item(item_type: String) -> Node2D:
	#var nearest_item = null
	#var min_dist = INF
	#for item in get_tree().get_nodes_in_group("item"):
		## Verifică tipul
		#if item.item_type == item_type and is_instance_valid(item):
			#var dist = global_position.distance_to(item.global_position)
			#if dist < min_dist:
				#min_dist = dist
				#nearest_item = item
	#return nearest_item


	#
#func process_ai_tasks():
	#if current_task_index >= ai_tasks.size():
		#return # Toate task-urile terminate
#
	#var task = ai_tasks[current_task_index]
	#match task["type"]:
		#"pickup":
			## Dacă nu avem mărul, mergem la locația de pickup
			#if not has_item("apple"):
				#go_to(task["location"])
				#if (global_position.distance_to(task["location"]) < 10):
					#pick_item("apple")
					#task["completed"] = true
					#current_task_index += 1
			#else:
				#current_task_index += 1
		#"deliver":
			#if has_item("apple"):
				#go_to(task["location"])
				#if (global_position.distance_to(task["location"]) < 10):
					#deliver_item("apple")
					#task["completed"] = true
					#current_task_index += 1
			#else:
				#current_task_index += 1
		#"goto":
			#go_to(task["location"])
			#if (global_position.distance_to(task["location"]) < 10):
				#task["completed"] = true
				#current_task_index += 1


func select_new_direction():
	var random = RandomNumberGenerator.new()
	moveDirection = Vector2(
		random.randi_range(-1, 1), # Possible values are -1, 0, 1 for X
		random.randi_range(-1, 1)  # Possible values are -1, 0, 1 for Y
	).normalized()

func movement():

	if velocity!=Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			# Dacă mișcarea pe axa X este dominantă
			if velocity.x < 0:
				animated_sprite_2d.play("walk-stanga")
				lastPosition = Vector2(-1, 0)
			else:
				animated_sprite_2d.play("walk-dreapta")
				lastPosition = Vector2(1, 0)
		else:
			# Dacă mișcarea pe axa Y este dominantă
			if velocity.y < 0:
				animated_sprite_2d.play("walk-sus")
				lastPosition = Vector2(0, -1)
			else:
				animated_sprite_2d.play("walk-jos")
				lastPosition = Vector2(0, 1)
	else: 
		animated_sprite_2d.play("idle")


func deal_with_damage():
	if(player_inattack_range and player_current_attack==true):
		if can_take_damage==true:
			angry+=1
			#print(angry)
			health -= get_player().attack_weapon
			healthbar.value=health
			
			$healthbar.visible=true
			
			can_take_damage=false
			
			take_damage.start()
			color.start()
			apply_knockback()
			#print("enemy health: ",health)
			animated_sprite_2d.modulate=Color("red")
			if health<=0:
				self.queue_free()
			player_inattack_range = false
			player_current_attack = false


func _on_take_damage_timeout():
	can_take_damage=true


func _on_color_timeout():
	animated_sprite_2d.modulate=original_color

func apply_knockback():
	var direction = (position - get_player().position).normalized()
	velocity = direction * knockback_force
	move_and_slide()


func _on_change_direction_timeout():
	select_new_direction()
	

func _on_arma_area_entered(area):
	#print("Aria detectată:", area.name)
	if already_hit:
		return
		 
	if area.is_in_group("arma"):
		#print("Se activează arma, se redă sunetul.")
		audio_stream_player_2d.play()
		already_hit = true  
		return  # Oprește funcția aici, fără a verifica celelalte condiții.5

	elif area.is_in_group("scut"):
		#print("Scut detectat!")
		get_player().enemy_inattack_range = true
		get_player().enemy_current_attack = true
		get_player().deal_with_damage()
		already_hit = true  
		return

	elif area.is_in_group("player_hitbox"):
		#print("Jucător lovit!")
		get_player().enemy_inattack_range = true
		get_player().enemy_current_attack = true
		get_player().deal_with_damage1()

func _on_arma_area_exited(_area: Area2D) -> void:
	await get_tree().process_frame
	already_hit = false


func _on_detection_body_entered(body):
	if body.is_in_group("player")  and is_instance_valid(enemy_icon):
		enemy_icon.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/enemy.png")
		if angry>=3:
			player_chase=true
			#chase()


func _on_detection_body_exited(body):
	if body.is_in_group("player")  and is_instance_valid(enemy_icon):
		player_chase=false
		enemy_icon.texture=null
		movement()



func _on_atack_zone_area_entered(area):
	if area.is_in_group("player_hitbox"):
		player_in_zone =true
		GameState.current_ai_npc = self
		print("plin: ",GameState.current_ai_npc)
		

		
		
	if area.is_in_group("player_hitbox") and not is_attacking and not is_fleeing and angry >= 3:
		# Determină direcția către jucător
		var direction_to_player = (get_player().position - position).normalized()
		
		# Setează animația de atac în direcția jucătorului
		if abs(direction_to_player.x) > abs(direction_to_player.y):
			if direction_to_player.x < 0:
				animation_player.play("attack-right")
			else:
				animation_player.play("attack-left")
		else:
			if direction_to_player.y < 0:
				animation_player.play("attack-up")
			else:
				animation_player.play("attack-down")
		
		stare_atac = true
		is_attacking = true
		atack.start()  # Inițiază atacul



func _on_atack_timeout():
	is_attacking = false
	stare_atac = false
	atack.stop()
	initiate_doge()


func initiate_doge():
	if not get_player():
		return
	$ChangeDirection.stop()
	is_fleeing = true 
	# Direcția opusă față de jucător
	var direction_away = (position - get_player().position).normalized()
	
	var dodge_speed = MoveSpeed * 2
	
	# Aplică mișcarea de fugă
	velocity = direction_away * dodge_speed
	move_and_slide()
	# Alegerea animației în funcție de direcția fugii
	if abs(direction_away.x) > abs(direction_away.y):
		if direction_away.x < 0:
			animation_player.play("run-left")
		else:
			animation_player.play("run-right")
	else:
		if direction_away.y < 0:
			animation_player.play("run-up")
		else:
			animation_player.play("run-down")
	doge.start()


func _on_doge_timeout():
	is_fleeing = false  # Oprește fuga
	is_attacking = false
	$ChangeDirection.start()
	select_new_direction()

#func _input(_event:InputEvent):
	#if Input.is_action_just_pressed("ai_interact") and player_in_zone:
		#GameState.current_ai_npc = self
		#$CanvasLayer.visible = not $CanvasLayer.visible



func _on_atack_zone_area_exited(area):
	if area.is_in_group("player_hitbox"):
		player_in_zone =false
		$CanvasLayer.visible = false
		if GameState.current_ai_npc == self:
			GameState.current_ai_npc = null
		print("gol: ",GameState.current_ai_npc)


func send_text_to_ai():
	if textEdit.text.strip_edges() == "":
		return

	textEdit.editable = false
	var full_prompt = ai_personality + "\nPlayer: " + textEdit.text
	GameState.global_ai_chat.say(full_prompt)
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ai_interact") and player_in_zone:
		$CanvasLayer.visible = not $CanvasLayer.visible
		
		if $CanvasLayer.visible:
			get_player().can_move = false  
			deplasare=true
		else:
			deplasare=false
			get_player().can_move = true
			$CanvasLayer/Control2/PanelContainer/VBoxContainer/HBoxContainer/RichTextLabel.text=""
			

	if event.is_action("ui_text_newline") and player_in_zone and $CanvasLayer.visible:
		send_text_to_ai()

	if Input.is_key_pressed(KEY_9) and player_in_zone:
		start_combat()
	
