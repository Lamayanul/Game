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

func _ready():
	healthbar_enemy.value=0
	$ChangeDirection.start()
	add_to_group("enemy_hitbox")
	select_new_direction()
	arma.visible=false
	$arma/colisiune.disabled=true


func _physics_process(_delta):
	# Actualizează viteza de mișcare
	velocity = moveDirection * MoveSpeed
	
		# Verificăm dacă inamicul trebuie să urmărească jucătorul
	
	if player_chase:
		chase()
	else:
		# Altfel, mișcarea normală
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
	if area.is_in_group("player_hitbox"):
		print(area)
		player.enemy_inattack_range=true
		player.enemy_current_attack=true
		player.deal_with_damage()
		



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
		player_chase=true
		enemy_icon.texture=load("res://Sprout Lands - Sprites - Basic pack/Objects/enemy.png")
		healthbar_enemy.value=health
		chase()


func _on_detection_body_exited(body):
	if body.is_in_group("player"):
		player_chase=false
		enemy_icon.texture=null
		healthbar_enemy.value=0
		movement()

		
		
func atac_mode():
	call_deferred("activate")


func _on_atack_zone_area_entered(area):
	if area.is_in_group("player_hitbox") and  is_attacking==false:
		print(area)
		is_attacking = true
		
		atac_mode()
		atack.start()
		arma.visible=false
		
		

func activate():
	arma.visible=true
	animation_player.play("atac-right")
	move_and_slide()
	
func _on_atack_zone_area_exited(_area):
	is_attacking = false  # Dezactivează modul de atac după ce animația s-a terminat
	atack.stop()
	arma.visible=false
	

func _on_atack_timeout():

	if is_attacking:
		atac_mode()
