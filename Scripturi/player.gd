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

#-----------------------------jump/movement----------------------------------------------------------
var can_jump = true 
var is_jumping = false
var jumpDirection = Vector2.ZERO
var last_direction = Vector2(0, 1)
var knockback_force = 500

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

#----------------------------------Enemy-action/stats-------------------------------------------------
@onready var attack_timer = $attack_timer
@onready var arma =$arma
@onready var arma_colisiune = $arma/arma_colisiune
@onready var enemy = $"../enemy"
@onready var camera_enemy = $"../enemy/camera_enemy"
var colisiune

#-------------------------------------Player-stats----------------------------------------------
var Speed = 50
@export var health=100



#----------------------------------TileMap------------------------------------------------------------
var tilemap
var _tileMap


#-----------------------------------_ready()--------------------------------------------------------
func _ready():
	tilemap = get_tree().current_scene.get_node("TileMap")
	_tileMap = get_node("/root/world/TileMap")
	colisiune = get_node("colisiune")
	add_to_group("player")
	color_rect.color = Color(0, 0, 0, 0.5)  # Negru cu 50% transparență
	color_rect.visible=false
	arma_colisiune.disabled=true
	healthbar.value=health
	add_to_group("player_hitbox")


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
	if item_texture:
		print("Texture set successfully")
		hand_sprite.texture = item_texture
		hand_sprite.visible = true
		hand_sprite.scale=Vector2(0.5,0.5)
		info = "[center]ITEM : "  +item_nume+"[/center]"
		
	else:
		print("Texture is null")


func inequip_item():
	hand_sprite.texture=null
	info_label.visible=false
	info_label.clear()

func _on_area_2d_mouse_entered():
	info_label.visible=true
	color_rect.visible=true
	info_label.text=info
	print("intrare")
	

func _on_area_2d_mouse_exited():
	info_label.visible=false
	color_rect.visible=false
	print("iesire")


#-------------------------------player-attack--------------------------------------------------------
func _on_inv_attacking():
	
	
	player_current_attack=true
	if is_jumping:  
		return
	
	is_attacking = true
	current_state = "attacking"
	
	
	if last_direction.x > 0:  # Dreapta
		animation_player.play("atack-right") 
	elif last_direction.x < 0:   # Stânga
		animation_player.play("atack-left") 
	elif last_direction.y > 0:  # Jos
		animation_player.play("atack-down") 
	elif last_direction.y < 0:  # Sus
		animation_player.play("atack-up") 
	
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
	if(enemy_inattack_range and enemy_current_attack==true):
			health-=10
			healthbar_player.value=health
			apply_knockback()
			if health<=0:
				self.queue_free()
				player_icon.texture=null
				camera_enemy.make_current()
			
			enemy_inattack_range = false
			enemy_current_attack = false
			
func apply_knockback():
	var direction = (position - get_node("/root/world/enemy/").position).normalized()
	velocity = direction * knockback_force
	move_and_slide()
