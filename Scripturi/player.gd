extends CharacterBody2D


var enemy_inattack_range=false
var enemy_attack_cooldown=true
var health=100
var player_alive=true

# Variables
var Speed = 50
var _currentIdleAnimation = "front_idle" # Current idle animation
var is_jumping = false
var jumpDirection = Vector2.ZERO
@onready var hand_sprite = $"../CanvasLayer/PanelContainer/Sprite2D/item_mana/sprite"
@onready var info_label = $"../CanvasLayer/InfoLabel"
@onready var area_2d = $"../CanvasLayer/PanelContainer/Sprite2D/item_mana/sprite/Area2D"
@onready var color_rect = $"../CanvasLayer/ColorRect"
var current_state = "idle"
var last_direction = Vector2(0, 1)
var info:String=""
@onready var animatedSprite2D = get_node("AnimatedSprite2D")
@onready var attack_timer = $attack_timer
@onready var attack_cooldown = $attack_cooldown

# Nodes
var colisiune
var tilemap
var _tileMap
var is_attacking = false
func _ready():
	tilemap = get_tree().current_scene.get_node("TileMap")
	_tileMap = get_node("/root/world/TileMap")
	colisiune = get_node("colisiune")
	add_to_group("player")
	color_rect.color = Color(0, 0, 0, 0.5)  # Negru cu 50% transparență
	color_rect.visible=false



func _physics_process(delta):
	if health<=0:
		health=0
		player_alive=false
		print("player killed")
		self.queue_free()
		
		
	enemy_attack()
	if is_attacking:
		return  
		
	if not is_jumping:
		handle_movement()
	
	if Input.is_action_just_pressed("jump") and not is_jumping:
		jump()

	if is_jumping:
		position += jumpDirection * Speed  * delta
	else:
		position += velocity * delta

func handle_movement():
	if is_jumping or is_attacking:
		return
		
	velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		velocity.x += 1
		_currentIdleAnimation = "right_idle"
		last_direction = Vector2(1, 0) 
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
		_currentIdleAnimation = "left_idle"
		last_direction = Vector2(-1, 0) 
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
		_currentIdleAnimation = "front_idle"
		last_direction = Vector2(0, 1)
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
		_currentIdleAnimation = "back_idle"
		last_direction = Vector2(0, -1)



	var animatedSprite2D = get_node("AnimatedSprite2D")

	if velocity.length() > 0:
		velocity = velocity.normalized() * Speed
		animatedSprite2D.play()
		current_state = "walking"
	else:
		animatedSprite2D.animation = _currentIdleAnimation
		animatedSprite2D.play()
		current_state = "idle"
		
	if velocity.x != 0:
		if velocity.x < 0:
			animatedSprite2D.animation = "left_walk"
		else:
			animatedSprite2D.animation = "right_walk"
		animatedSprite2D.flip_v = false
	if velocity.y != 0:
		if velocity.y < 0:
			animatedSprite2D.animation = "back_walk"
		else:
			animatedSprite2D.animation = "front_walk"
		animatedSprite2D.flip_h = false

	move_and_slide()

func jump():
	if is_attacking:  # Blochează săritura în timpul atacului
		return

	is_jumping = true
	current_state = "jumping"
	# Save the jump direction based on current movement direction
	jumpDirection = velocity.normalized()

	var animatedSprite2D = get_node("AnimatedSprite2D")

	# Choose jump animation based on movement direction
	if jumpDirection.x > 0:
		animatedSprite2D.animation = "right_jump" # Jump animation to the right
	elif jumpDirection.x < 0:
		animatedSprite2D.animation = "left_jump" # Jump animation to the left
	elif jumpDirection.y < 0:
		animatedSprite2D.animation = "up_jump" # Jump animation upwards
	elif jumpDirection.y > 0:
		animatedSprite2D.animation = "down_jump" # Jump animation downwards
	elif jumpDirection.y == 0:
		animatedSprite2D.animation = "down_jump"
	
	animatedSprite2D.play()
	
	disable_collision_for_2_seconds()

func _on_timer_timeout():

	colisiune.disabled = false
	is_jumping = false
	
func disable_collision_for_2_seconds():

	colisiune.disabled = true

	get_node("Timer").start()


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
	
	

# Funcția pentru echiparea unui item
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


func _on_inv_attacking():
	Global.player_current_attack=true
	if is_jumping:  # Nu permite atacul dacă jucătorul sare
		return
		
	is_attacking = true
	current_state = "attacking"
	
	# Alege animația de atac în funcție de ultima direcție
	if last_direction.x > 0:  # Dreapta
		_currentIdleAnimation = "right_attack"
		animatedSprite2D.animation = "right_attack"
	elif last_direction.x < 0:  # Stânga
		_currentIdleAnimation = "left_attack"
		animatedSprite2D.animation = "left_attack"
	elif last_direction.y > 0:  # Jos
		_currentIdleAnimation = "down_attack"
		animatedSprite2D.animation = "down_attack"
	elif last_direction.y < 0:  # Sus
		_currentIdleAnimation = "up_attack"
		animatedSprite2D.animation = "up_attack"
	
	animatedSprite2D.play()
	attack_timer.start(0.5)
	
func _on_attack_timer_timeout():
	is_attacking = false
	current_state = "idle"  # Sau starea corespunzătoare după atac
	if last_direction.x > 0:
		_currentIdleAnimation = "right_idle"
	elif last_direction.x < 0:
		_currentIdleAnimation = "left_idle"
	elif last_direction.y > 0:
		_currentIdleAnimation = "front_idle"
	elif last_direction.y < 0:
		_currentIdleAnimation = "back_idle"
	Global.player_current_attack=false

	
func player():
	pass

func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		enemy_inattack_range=true


func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		enemy_inattack_range=false
		
func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown==true:
		health-=10
		enemy_attack_cooldown=false
		attack_cooldown.start()
		print(health)


func _on_attack_cooldown_timeout():
	enemy_attack_cooldown=true
