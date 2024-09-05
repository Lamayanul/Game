extends CharacterBody2D

# Signals


# Variables
var Speed = 50
var _currentIdleAnimation = "front_idle" # Current idle animation
var is_jumping = false
var jumpDirection = Vector2.ZERO
@onready var hand_sprite = $"../CanvasLayer/PanelContainer/Sprite2D/item_mana/sprite"
@onready var info_label = $"../CanvasLayer/InfoLabel"
@onready var area_2d = $"../CanvasLayer/PanelContainer/Sprite2D/item_mana/sprite/Area2D"
@onready var color_rect = $"../CanvasLayer/ColorRect"

var info:String=""
# Nodes
var colisiune
var tilemap
var _tileMap

func _ready():
	tilemap = get_tree().current_scene.get_node("TileMap")
	_tileMap = get_node("/root/world/TileMap")
	colisiune = get_node("colisiune")
	add_to_group("player")
	color_rect.color = Color(0, 0, 0, 0.5)  # Negru cu 50% transparență
	color_rect.visible=false



func _physics_process(delta):
	if not is_jumping:
		handle_movement()
	
	if Input.is_action_just_pressed("jump") and not is_jumping:
		jump()

	if is_jumping:
		position += jumpDirection * Speed  * delta
	else:
		position += velocity * delta

func handle_movement():
	velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		velocity.x += 1
		_currentIdleAnimation = "right_idle"
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
		_currentIdleAnimation = "left_idle"
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
		_currentIdleAnimation = "front_idle"
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
		_currentIdleAnimation = "back_idle"



	var animatedSprite2D = get_node("AnimatedSprite2D")

	if velocity.length() > 0:
		velocity = velocity.normalized() * Speed
		animatedSprite2D.play()
	else:
		animatedSprite2D.animation = _currentIdleAnimation
		animatedSprite2D.play()
		
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
	is_jumping = true

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
