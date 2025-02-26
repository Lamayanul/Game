extends CharacterBody2D

#---------------------------enemy-player-health-control---------------------------------------------------
var player_alive=true
@onready var healthbar = $CanvasLayer/healthbar
@onready var healthbar_player = $CanvasLayer/healthbar_player
#-----------------------------jump/movement----------------------------------------------------------
var can_jump = true 
var is_jumping = false
var jumpDirection = Vector2.ZERO
var last_direction = Vector2(0, 1)
@onready var camera_2d: Camera2D = $Camera2D
#--------------------------------Animation-start---------------------------------------------------
var _currentIdleAnimation="down"
@onready var animation_player = $AnimationPlayer
var current_state = "idle"
@onready var animatedSprite2D = $AnimatedSprite2D
@onready var colisiune: CollisionShape2D = $colisiune

#-------------------------------------Info-hand-sprite------------------------------------------
@onready var hand_sprite = $"../Inventar/PanelContainer/Sprite2D/item_mana/sprite"
@onready var info_label = $"../Inventar/InfoLabel"

@onready var area_2d = $"../Inventar/PanelContainer/Sprite2D/item_mana/sprite/Area2D"
@onready var color_rect = $"../Inventar/ColorRect"
var info:String=""
@onready var player_icon = $CanvasLayer/healthbar_player/player_icon

#-------------------------------------Player-stats----------------------------------------------
var Speed = 50
@export var health=100
#@onready var scut: Area2D =$StaticBody2D/Scut
#@onready var scut_sprite: Sprite2D =$StaticBody2D/Scut/Sprite2D
#@onready var shield_touch: CollisionShape2D =$"StaticBody2D/shield-touch"

var selected_slot: Slot = null 
#----------------------------------TileMap------------------------------------------------------------

@onready var inv: PanelContainer = $"../Inventar/Inv"

#-----------------------------------_ready()--------------------------------------------------------
func _ready():
	add_to_group("player")
	color_rect.color = Color(0, 0, 0, 0.5)  # Negru cu 50% transparență
	color_rect.visible=false
	healthbar.value=health
	add_to_group("player_hitbox")
	info_label.text=""
	info_label.visible=false


#------------------------------_physics_process()------------------------------------------------------
func _physics_process(delta):
	if health<=0:
		health=0
		player_alive=false
		self.queue_free()
		
	#var global_mouse_position = get_global_mouse_position()
	#print("Mouse position: ", global_mouse_position)
		
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
	if is_jumping:
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




func _on_body_entered(body):
	if body.is_in_group("player"):
		Speed = 25


func _on_body_exited(body):
	if body.is_in_group("player"):
		Speed = 50
	
	

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
	info = "" 
	info_label.text = ""

func _on_area_2d_mouse_entered():
	info_label.visible=true
	color_rect.visible=true
	info_label.text=info
	

func _on_area_2d_mouse_exited():
	info_label.visible=false
	info_label.text=""
	color_rect.visible=false
