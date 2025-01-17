extends CharacterBody2D

#---------------------------enemy-player-health-control---------------------------------------------------
var enemy_inattack_range=false
var enemy_attack_cooldown=true
var enemy_current_attack=false
var player_alive=true
var player_current_attack=false
@onready var healthbar = $CanvasLayer/healthbar
@onready var healthbar_player = $CanvasLayer/healthbar_player
var is_attacking = false
var scut_used=0
#-----------------------------jump/movement----------------------------------------------------------
var can_jump = true 
var is_jumping = false
var jumpDirection = Vector2.ZERO
var last_direction = Vector2(0, 1)
var knockback_force = 500
@onready var camera_2d: Camera2D = $Camera2D

#--------------------------------Animation-start---------------------------------------------------
var _currentIdleAnimation="down"
@onready var animation_player = $AnimationPlayer
var current_state = "idle"
@onready var animatedSprite2D = $AnimatedSprite2D

#-------------------------------------Info-hand-sprite------------------------------------------
@onready var hand_sprite = $"../CanvasLayer/PanelContainer/Sprite2D/item_mana/sprite"
@onready var info_label = $"../CanvasLayer/InfoLabel"

@onready var area_2d = $"../CanvasLayer/PanelContainer/Sprite2D/item_mana/sprite/Area2D"
@onready var color_rect = $"../CanvasLayer/ColorRect"
var info:String=""
@onready var player_icon = $CanvasLayer/healthbar_player/player_icon
var attack_weapon=0;
#----------------------------------Enemy-action/stats-------------------------------------------------
@onready var attack_timer = $attack_timer
@onready var arma =$arma
@onready var arma_colisiune = $arma/arma_colisiune
@onready var enemy = $"../enemy"
@onready var camera_enemy = $"../enemy/camera_enemy"
var colisiune
@onready var camera_boat: Camera2D = $"../boat/camera_boat"


#-------------------------------------Player-stats----------------------------------------------
var Speed = 50
@export var health=100
@onready var scut: Area2D =$StaticBody2D/Scut
@onready var scut_sprite: Sprite2D =$StaticBody2D/Scut/Sprite2D
@onready var shield_touch: CollisionShape2D =$"StaticBody2D/shield-touch"
@export var max_shield_durability =100;
var shield_durability = max_shield_durability 
var shield_damage_resistance = 1.0

#----------------------------------TileMap------------------------------------------------------------
var tile_map
var _tileMap
@onready var inv: PanelContainer = $"../CanvasLayer/Inv"


#-----------------------------------_ready()--------------------------------------------------------
func _ready():
	tile_map = get_tree().current_scene.get_node("TileMap")
	_tileMap = get_node("/root/world/TileMap")
	colisiune = get_node("colisiune")
	add_to_group("player")
	color_rect.color = Color(0, 0, 0, 0.5)  # Negru cu 50% transparență
	color_rect.visible=false
	arma_colisiune.disabled=true
	healthbar.value=health
	add_to_group("player_hitbox")
	info_label.text=""
	info_label.visible=false
	scut.visible=false
	shield_touch.disabled=true
	scut.add_to_group("scut")
	scut.monitoring = true





#------------------------------_physics_process()------------------------------------------------------
func _physics_process(delta):
	
	if health<=0:
		health=0
		player_alive=false
		print("player killed")
		self.queue_free()
		
	#var global_mouse_position = get_global_mouse_position()
	#print("Mouse position: ", global_mouse_position)
	
	if is_attacking:
		return  
		
	if not is_jumping:
		handle_movement()
	
	if Input.is_action_just_pressed("jump") and not is_jumping and can_jump:
		jump()

	if is_jumping:
		position += jumpDirection * Speed  * delta
	else:
		position += velocity * delta
		
	if scut.visible:
		update_shield_position()
	if inv.has_shield and scut_used>0:
		scut.visible=true
		shield_touch.disabled=false
		position_shield_opposite()
	

#----------------------------------player-movement------------------------------------------------------
func handle_movement():
	if is_jumping or is_attacking:
		return

	velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		velocity.x += 1
		_currentIdleAnimation = "right"
		last_direction = Vector2(1, 0)
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
		_currentIdleAnimation = "left"
		last_direction = Vector2(-1, 0)
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
		_currentIdleAnimation = "down"
		last_direction = Vector2(0, 1)
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
		_currentIdleAnimation = "up"
		last_direction = Vector2(0, -1)

	
	if velocity.length() > 0:
		velocity = velocity.normalized() * Speed
		if velocity.x != 0:
			if velocity.x < 0:
				animation_player.play("walk-left")
			else:
				animation_player.play("walk-right")
		elif velocity.y != 0:
			if velocity.y < 0:
				animation_player.play("walk-up")
			else:
				animation_player.play("walk-down")
		current_state = "walking"
	else:
		animation_player.play("idle-" + _currentIdleAnimation)
		current_state = "idle"

	move_and_slide()


#-----------------------------------player-jump--------------------------------------------------------
func jump():
	if is_attacking:  # Blochează săritura în timpul atacului
		return

	is_jumping = true
	current_state = "jumping"
	jumpDirection = velocity.normalized()
	if jumpDirection.x > 0:
		animation_player.play("jump-right") 
	elif jumpDirection.x < 0:
		animation_player.play("jump-left") 
	elif jumpDirection.y < 0:
		animation_player.play("jump-up") 
	elif jumpDirection.y > 0:
		animation_player.play("jump-down") 
	elif jumpDirection.y == 0 or jumpDirection.x==0:

		animation_player.play("jump-down") 
	
	
	disable_collision_for_2_seconds()


func _on_timer_timeout():

	colisiune.disabled = false
	is_jumping = false
	
func disable_collision_for_2_seconds():

	colisiune.disabled = true

	get_node("Timer").start()



#-------------------------------On-hill-zoom---------------------------------------------------------
func _on_area_2d_body_entered(body):
	var camera=get_node("Camera2D")
	if body.is_in_group("player"):
		camera.zoom=Vector2(3,3)


func _on_area_2d_body_exited(body):
	var camera=get_node("Camera2D")
	if body.is_in_group("player"):
		camera.zoom=Vector2(4,4)

func _on_body_entered(_body):
	Speed = 25


func _on_body_exited(_body):
	Speed =50
	
	

#----------------------------------equip_item/inequip_item---------------------------------------------
func equip_item(item_texture: Texture, item_nume : String):
	if scut.visible and inv.selected_slot.get_id() != "13":
		scut.visible = false
		shield_touch.disabled = true
	if item_texture:
		print("Texture set successfully")
		hand_sprite.texture = item_texture
		hand_sprite.visible = true
		hand_sprite.scale=Vector2(0.5,0.5)
		info = "[center]ITEM : "  +item_nume+"[/center]"
		
	else:
		print("Texture is null")
	


func inequip_item():
	scut.visible = false
	scut_used=0
	shield_touch.call_deferred("set_disabled", true)
	
	hand_sprite.texture=null
	info_label.visible=false
	info_label.clear()
	info = "" 
	info_label.text = ""

func _on_area_2d_mouse_entered():
	info_label.visible=true
	color_rect.visible=true
	info_label.text=info
	print("intrare")
	

func _on_area_2d_mouse_exited():
	info_label.visible=false
	info_label.text=""
	color_rect.visible=false
	print("iesire")


#-------------------------------player-attack--------------------------------------------------------
func _on_inv_attacking(ID):
	
	
	player_current_attack=true
	if is_jumping:  
		return
	
	is_attacking = true
	current_state = "attacking"
	
	if ID=="2":
		scut.visible=false
		shield_touch.disabled=true
		attack_weapon=10;
		if last_direction.x > 0:  # Dreapta
			animation_player.play("axe-right") 
		elif last_direction.x < 0:   # Stânga
			animation_player.play("axe-left") 
		elif last_direction.y > 0:  # Jos
			animation_player.play("axe-down") 
		elif last_direction.y < 0:  # Sus
			animation_player.play("axe-up") 
	if ID=="9":
		scut.visible=false
		shield_touch.disabled=true
		attack_weapon=5;
		if last_direction.x > 0:  # Dreapta
			animation_player.play("hoe-right") 
		elif last_direction.x < 0:   # Stânga
			animation_player.play("hoe-left") 
		elif last_direction.y > 0:  # Jos
			animation_player.play("hoe-down") 
		elif last_direction.y < 0:  # Sus
			animation_player.play("hoe-up") 
	if ID=="10":
		scut.visible=false
		shield_touch.disabled=true
		attack_weapon=5;
		if last_direction.x > 0:  # Dreapta
			animation_player.play("pickaxe-right") 
		elif last_direction.x < 0:   # Stânga
			animation_player.play("pickaxe-left") 
		elif last_direction.y > 0:  # Jos
			animation_player.play("pickaxe-down") 
		elif last_direction.y < 0:  # Sus
			animation_player.play("pickaxe-up") 
	if ID=="13":
		scut.visible=true
		shield_touch.disabled=false
		attack_weapon=0;
		scut_used=1
		if last_direction.x > 0:  # Dreapta
			animation_player.play("shield-right") 
		elif last_direction.x < 0:   # Stânga
			animation_player.play("shield-left") 
		elif last_direction.y > 0:  # Jos
			animation_player.play("shield-down") 
		elif last_direction.y < 0:  # Sus
			animation_player.play("shield-up") 
	
	attack_timer.start(0.5)
	
func _on_attack_timer_timeout():
	is_attacking = false
	current_state = "idle"  
	if last_direction.x > 0:
		_currentIdleAnimation = "right"
	elif last_direction.x < 0:
		_currentIdleAnimation = "left"
	elif last_direction.y > 0:
		_currentIdleAnimation ="down"
	elif last_direction.y < 0:
		_currentIdleAnimation = "up"
	player_current_attack=false


#
#func _on_arma_body_entered(body):
	#if body.is_in_group("enemy"):
		#body.player_inattack_range=true
		#body.player_current_attack=true
		#body.deal_with_damage()
	#

func _on_arma_area_entered(area):
	if area.is_in_group("enemy_hitbox"):
		enemy.player_inattack_range=true
		enemy.player_current_attack=true
		enemy.deal_with_damage()
	else:
		print("nu este enemy_hitbox")
		
func deal_with_damage():
	if enemy_inattack_range and enemy_current_attack == true:
		var base_damage = 10
		var final_damage = apply_damage_with_shield(base_damage)  # Daune ajustate după calculul scutului

		# Aplică daunele finale la viața jucătorului
		health -= final_damage
		healthbar_player.value = health

		apply_knockback()  # Efect opțional de recul
		if health <= 0:
			self.queue_free()  # Jucătorul moare
			player_icon.texture = null
			$"../TileMap/Grid_gard".visible = false
			$"../TileMap/Grid_land".visible = false
			$"../TileMap/Grid_ogor".visible = false
			camera_enemy.make_current()

		enemy_inattack_range = false
		enemy_current_attack = false

func deal_with_damage1():
	if enemy_inattack_range and enemy_current_attack == true:
		var base_damage = 10
		 

		# Aplică daunele finale la viața jucătorului
		health -= base_damage
		healthbar_player.value = health
		print("player health: " ,health)
		apply_knockback()  # Efect opțional de recul
		if health <= 0:
			self.queue_free()  # Jucătorul moare
			player_icon.texture = null
			$"../TileMap/Grid_gard".visible = false
			$"../TileMap/Grid_land".visible = false
			$"../TileMap/Grid_ogor".visible = false
			camera_enemy.make_current()

		enemy_inattack_range = false
		enemy_current_attack = false

func apply_knockback():
	var direction = (position - get_node("/root/world/enemy/").position).normalized()
	velocity = direction * knockback_force
	move_and_slide()

func apply_damage_with_shield(base_damage: float) -> float:
	var damage_taken = base_damage  # Daunele inițiale
   
	if shield_durability > 0 and shield_touch.disabled==false: #inv.selected_slot.get_id() == "13":
		# Eficiența scutului, bazată pe durabilitate
		var shield_effectiveness = float(shield_durability) / max_shield_durability
		# Limităm eficiența la 0.5 pentru a reduce daunele la jumătate în loc să le eliminăm
		var adjusted_effectiveness = min(0.8, shield_effectiveness)
		
		# Calculăm daunele, limitând reducerea
		damage_taken = base_damage * (1 - (shield_damage_resistance * adjusted_effectiveness))
		damage_taken = max(damage_taken, base_damage * 0.1)  # Daunele nu scad sub 10% din valoarea de bază
		
		# Reducem durabilitatea scutului
		shield_durability -= base_damage * 0.3 # Durabilitatea scade mai lent, ajustabil în funcție de nevoi
		 # Ne asigurăm că durabilitatea nu scade sub zero

		# Dezactivăm scutul când durabilitatea ajunge la zero
		if shield_durability <= 0:
			scut.visible = false
			
			inv.selected_slot.clear_item()
			inequip_item()
			print("Scutul s-a rupt!")

	print("Durabilitatea scutului:", shield_durability)  # Pentru debugging
	print("Daune calculate:", damage_taken)  # Pentru debugging
	
	return damage_taken
	
func update_shield_position():
	
	# Alinierea scutului cu direcția playerului
	if last_direction.x > 0:  # Dreapta
		scut.position=Vector2(9,-9)
		$"StaticBody2D/shield-touch".position=Vector2(10,3)
		scut_sprite.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-right.png" )# Ajustați valorile după necesitate
		$"StaticBody2D/shield-touch".shape = RectangleShape2D.new()
		$"StaticBody2D/shield-touch".shape.extents = Vector2(2, 7)
		
		
	elif last_direction.x < 0:  # Stânga
		scut.position=Vector2(-7.5,-9)
		$"StaticBody2D/shield-touch".position=Vector2(-8.5,3)
		scut_sprite.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-left.png" )
		$"StaticBody2D/shield-touch".shape = RectangleShape2D.new()
		$"StaticBody2D/shield-touch".shape.extents = Vector2(2, 7)
		
	
	elif last_direction.y > 0:  # Jos
		scut.position=Vector2(0,-4)
		$"StaticBody2D/shield-touch".position=Vector2(0,8)
		scut_sprite.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-temp.png" )
		$"StaticBody2D/shield-touch".shape = CircleShape2D.new()
		$"StaticBody2D/shield-touch".shape.radius=6.5
		
		
	elif last_direction.y < 0:  # Sus
		scut.position=Vector2(1,-16)
		$"StaticBody2D/shield-touch".position=Vector2(1,-4)
		scut_sprite.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-up.png" )
		$"StaticBody2D/shield-touch".shape = CircleShape2D.new()
		$"StaticBody2D/shield-touch".shape.radius=6.5
		
		
		
func position_shield_opposite():
	
	if last_direction.x > 0:  # Dreapta
		scut.position=Vector2(-7.5,-9)
		$"StaticBody2D/shield-touch".position=Vector2(-8.5,3)
		scut_sprite.texture = load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-left.png")
		$"StaticBody2D/shield-touch".shape = RectangleShape2D.new()
		$"StaticBody2D/shield-touch".shape.extents = Vector2(2, 7)
	elif last_direction.x < 0:  # Stânga
		scut.position=Vector2(9,-9)
		$"StaticBody2D/shield-touch".position=Vector2(10,3)
		scut_sprite.texture = load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-right.png")
		$"StaticBody2D/shield-touch".shape = RectangleShape2D.new()
		$"StaticBody2D/shield-touch".shape.extents = Vector2(2, 7)
	elif last_direction.y > 0:  # Jos
		scut.position=Vector2(1,-16)
		$"StaticBody2D/shield-touch".position=Vector2(1,-4)
		scut_sprite.texture = load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-up.png")
		$"StaticBody2D/shield-touch".shape = CircleShape2D.new()
		$"StaticBody2D/shield-touch".shape.radius=6.5
	elif last_direction.y < 0:  # Sus
		scut.position=Vector2(0,-4)
		$"StaticBody2D/shield-touch".position=Vector2(0,8)
		scut_sprite.texture = load("res://Sprout Lands - Sprites - Basic pack/Objects/shield-temp.png")
		$"StaticBody2D/shield-touch".shape = CircleShape2D.new()
		$"StaticBody2D/shield-touch".shape.radius=6.5
		
func _on_arma_body_entered_gard(body):
	if body is TileMap:
		
		# Obține punctul de coliziune și poziția tile-ului
		var collision_point = arma_colisiune.global_position
		var tile_position = body.local_to_map(collision_point)

		# Verifică și obține datele de pe stratul gard (3)
		var tile_data = body.get_cell_tile_data(3, tile_position)

		# Verifică și obține datele de pe stratul cliff-gard (4)
		var tile_data_cliff_gard = body.get_cell_tile_data(5, tile_position)
		
		# Condiții pentru gardul de pe stratul 3
		if tile_data and tile_data.get_custom_data("gard") and inv.selected_slot and inv.selected_slot.get_id() == "2" and not arma_colisiune.disabled:
			# Șterge gardul de pe stratul 3
			body.set_cell(3, tile_position, -1)
			
			# Creează un drop pentru gard
			var drop_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))  # Offset aleatoriu
			var drop_position = global_position + drop_offset
			inv.call_deferred("drop_item_everywhere","6", 1, drop_position)

		# Condiții pentru gardul de pe stratul 4
		if tile_data_cliff_gard and tile_data_cliff_gard.get_custom_data("cliff-gard") and inv.selected_slot and inv.selected_slot.get_id() == "2" and not arma_colisiune.disabled:
			# Șterge gardul de pe stratul 4
			print("stratul 4")
			body.set_cell(5, tile_position, -1)


			# Creează un drop pentru gard (poate reutiliza același logică ca stratul 3)
			var drop_offset_cliff = Vector2(randf_range(-10, 10), randf_range(-10, 10))  # Offset aleatoriu
			var drop_position_cliff = global_position + drop_offset_cliff
			inv.call_deferred("drop_item_everywhere","6", 1, drop_position_cliff)

		print("Gardurile au fost eliminate de la poziția:", tile_position)
