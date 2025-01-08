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


var fugi=false
var happy=0;
var angry=0;
var dictator=0;




func _ready():
	healthbar_enemy.value=0
	$ChangeDirection.start()
	add_to_group("enemy_hitbox")
	select_new_direction()
	arma.visible=false
	$arma/colisiune.disabled=true


func _physics_process(_delta):
	
	#if stare_atac==true:
		#initiate_attack()
	#
	#
	#velocity = moveDirection * MoveSpeed
	#
	#
	#if player_chase and angry >= 3:
		#chase()
	#
	#else:
		## Altfel, mișcarea normală
		#velocity = moveDirection * MoveSpeed
		#move_and_slide()
		#movement()
	#if fugi:
		#initiate_doge()
		#move_and_slide()
		
	if stare_atac and not is_attacking:
		initiate_attack()

	# Continuă cu logica de mișcare și alte comportamente
	if not is_attacking:
		velocity = moveDirection * MoveSpeed
		if player_chase and angry >= 3:
			chase()
		else:
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
	
#
func _on_arma_area_entered(area):
	if area.is_in_group("scut"):
		print("---------------------------------------------------------")
		player.enemy_inattack_range=true
		player.enemy_current_attack=true
		player.deal_with_damage()
	elif area.is_in_group("player_hitbox"):
		#print(area)
		player.enemy_inattack_range=true
		player.enemy_current_attack=true
		player.deal_with_damage1()
	




func chase():
	
	if player_chase:
		# Calcul distanță dintre inamic și jucător
		var direction = (player.position - position).normalized()
		var distance_to_player = position.distance_to(player.position)
		# Mișcarea inamicului spre jucător
		if distance_to_player > stop_distance:
			position += direction * Speed * 0.02
			velocity = direction * Speed
		
	
			move_and_slide()
			# Determină direcția de mișcare dominantă pentru a seta animația
			if abs(direction.x) > abs(direction.y):  # Mișcare pe X
				if direction.x < 0:
					animated_sprite_2d.play("walk-stanga")
					lastPosition = Vector2(-1, 0)
				else:
					animated_sprite_2d.play("walk-dreapta")
					lastPosition = Vector2(1, 0)
			else:  # Mișcare pe Y
				if direction.y < 0:
					animated_sprite_2d.play("walk-sus")
					lastPosition = Vector2(0, -1)
				else:
					animated_sprite_2d.play("walk-jos")
					lastPosition = Vector2(0, 1)
		else:
			animated_sprite_2d.play("idle")
	

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		enemy_icon.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/enemy.png")
		healthbar_enemy.value=health
		if angry>=3:
			player_chase=true
			chase()


func _on_detection_body_exited(body):
	if body.is_in_group("player"):
		player_chase=false
		enemy_icon.texture=null
		healthbar_enemy.value=0
		movement()

		
		
func initiate_attack():
	is_attacking = true

	# Select animation based on direction
	match lastPosition:
		Vector2(-1, 0):
			animation_player.play("attack-right")
		Vector2(1, 0):
			animation_player.play("attack-left")
		Vector2(0, -1):
			animation_player.play("attack-up")
		Vector2(0, 1):
			animation_player.play("attack-down")
	fugi=true

func initiate_doge():

	is_attacking = true

	# Select animation based on direction
	match lastPosition:
		Vector2(1, 0):
			animation_player.play("run-left")
			velocity = Vector2(1, 0) * MoveSpeed
		Vector2(-1, 0):
			velocity = Vector2(-1, 0) * MoveSpeed
			animation_player.play("run-right")
		Vector2(0, 1):
			animation_player.play("run-up")
			velocity = Vector2(0, 1) * MoveSpeed
		Vector2(0, -1):
			animation_player.play("run-down")
			velocity = Vector2(0, -1) * MoveSpeed
	move_and_slide()  
	fugi=false
	
	
#func _on_AnimationPlayer_animation_finished(anim_name):
	#match anim_name:
		#"attack-down":
			#is_attacking = false
			#stare_atac=false
		#"attack-up":
			#is_attacking = false
			#stare_atac=false
		#"attack-left":
			#is_attacking = false
			#stare_atac=false
		#"attack-right":
			#is_attacking = false
			#stare_atac=false



func _on_atack_zone_area_entered(area):
	if area.is_in_group("player_hitbox") and  is_attacking==false and angry>=3:
		stare_atac=true
		atack.start()
		doge.start()



		
		
#func _on_atack_zone_area_exited(_area):
#
	#atack.stop()
	


func _on_atack_timeout() -> void:
	is_attacking = false
	stare_atac=false
	#if fugi:
		#initiate_doge()
	


func _on_doge_timeout() -> void:
	initiate_doge()
