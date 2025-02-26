extends CharacterBody2D

var Speed = 20
var health=100
@onready var animated_sprite_2d = $AnimatedSprite2D
var original_color = Color(1, 1, 1, 1)  
var hit_color = Color(1, 0, 0, 1) 
@onready var color = $color
var moveDirection = Vector2.ZERO
@onready var healthbar = $healthbar
@onready var animation_player = $AnimationPlayer
@onready var player = $"../player"
@export var MoveSpeed: float = 20.0
var lastPosition=Vector2(0,1)
@onready var detection = $detection
@onready var player_hitbox = get_node("/root/world/player/player_hitbox")
@onready var enemy_icon = $"../player/CanvasLayer/healthbar_enemy/enemy_icon"
@onready var healthbar_enemy = $"../player/CanvasLayer/healthbar_enemy"



func _ready():
	healthbar_enemy.value=0
	$ChangeDirection.start()
	add_to_group("enemy_hitbox")
	


func _physics_process(_delta):
	velocity = moveDirection * MoveSpeed
	movement()
	move_and_slide()
		


func select_new_direction():
	var random = RandomNumberGenerator.new()
	moveDirection = Vector2(
		random.randi_range(-1, 1),
		random.randi_range(-1, 1)  
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


func _on_color_timeout():
	animated_sprite_2d.modulate=original_color



func _on_change_direction_timeout():
	select_new_direction()
	
