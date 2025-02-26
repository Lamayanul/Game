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
@onready var player = $"../player"
var player_chase=false
@export var MoveSpeed: float = 20.0
var lastPosition=Vector2(0,1)
@onready var detection = $detection
var is_attacking = false  
@onready var player_hitbox = get_node("/root/world/player/player_hitbox")
@onready var enemy_icon = $"../player/CanvasLayer/healthbar_enemy/enemy_icon"
@onready var healthbar_enemy = $"../player/CanvasLayer/healthbar_enemy"
@export var stop_distance: float = 20
@onready var atack = $atack
var stare_atac= false
@onready var doge: Timer = $doge
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $arma/AudioStreamPlayer2D
var already_hit = false 
var is_fleeing = false 

var happy=0;
var angry=0;
var dictator=0;




func _ready():
	healthbar_enemy.value=0
	$ChangeDirection.start()
	add_to_group("enemy_hitbox")
	#select_new_direction()
	arma.visible=false
	$arma/colisiune.disabled=true




func _physics_process(_delta):
	if is_fleeing:
		move_and_slide()
		return  
		
	if not is_attacking:
		velocity = moveDirection * MoveSpeed
		move_and_slide()
		movement()

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
			print(angry)
			health-=player.attack_weapon
			healthbar.value=health
			healthbar_enemy.value=health
			$healthbar.visible=true
			
			can_take_damage=false
			
			take_damage.start()
			color.start()
			apply_knockback()
			print("enemy health: ",health)
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
	var direction = (position - get_node("/root/world/player/").position).normalized()
	velocity = direction * knockback_force
	move_and_slide()


func _on_change_direction_timeout():
	select_new_direction()
	

func _on_arma_area_entered(area):
	print("Aria detectată:", area.name)
	if already_hit:
		return
		 
	if area.is_in_group("arma"):
		print("Se activează arma, se redă sunetul.")
		audio_stream_player_2d.play()
		already_hit = true  
		return  # Oprește funcția aici, fără a verifica celelalte condiții.5

	elif area.is_in_group("scut"):
		print("Scut detectat!")
		player.enemy_inattack_range = true
		player.enemy_current_attack = true
		player.deal_with_damage()
		already_hit = true  
		return

	elif area.is_in_group("player_hitbox"):
		print("Jucător lovit!")
		player.enemy_inattack_range = true
		player.enemy_current_attack = true
		player.deal_with_damage1()

func _on_arma_area_exited(area: Area2D) -> void:
	await get_tree().process_frame
	already_hit = false


func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		enemy_icon.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/enemy.png")
		healthbar_enemy.value=health
		if angry>=3:
			player_chase=true
			#chase()


func _on_detection_body_exited(body):
	if body.is_in_group("player"):
		player_chase=false
		enemy_icon.texture=null
		healthbar_enemy.value=0
		movement()

func _on_atack_zone_area_entered(area):
	if area.is_in_group("player_hitbox") and not is_attacking and not is_fleeing and angry >= 3:
		# Determină direcția către jucător
		var direction_to_player = (player.position - position).normalized()
		
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
	if not player:
		return
	$ChangeDirection.stop()
	is_fleeing = true 
	# Direcția opusă față de jucător
	var direction_away = (position - player.position).normalized()
	
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
