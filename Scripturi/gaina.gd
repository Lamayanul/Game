extends CharacterBody2D

# Variables
@export var MoveSpeed: float = 20.0
var hungry=false
var moveDirection = Vector2.ZERO
var currentState = ChicState.Idle
var animatedSprite: AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var hungry_timer: Timer = $hungry
@onready var fly_anime: AnimatedSprite2D = $fly
var fly=false
@onready var fly_timer: Timer = $fly_timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var target: Node2D = null
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D


enum ChicState {
	Idle,
	Walk,
	Fly,
	EatL,
	EatS
}

func _ready():
	call_deferred("seeker_setup")
	animatedSprite = $AnimatedSprite2D
	$directionChangeTimer.start()
	select_new_direction()
	pick_new_state()
	add_to_group("gaina")
	timer.start()
	fly_anime.hide()



func _physics_process(_delta):
	if navigation_agent_2d.is_navigation_finished():
		return

	var curent_agent_position=global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	velocity=curent_agent_position.direction_to(next_path_position)* MoveSpeed
	move_and_slide()
	
	if currentState == ChicState.Walk:
		velocity = moveDirection * MoveSpeed
		move_and_slide()

		if moveDirection != Vector2.ZERO:
			animatedSprite.play("walk")
			if moveDirection.x < 0:
				animatedSprite.flip_h = true
			elif moveDirection.x > 0:
				animatedSprite.flip_h = false
			
	elif currentState == ChicState.Idle:
		velocity = Vector2.ZERO
		if hungry == true:
			animatedSprite.play("eat-short")
		else:
			animatedSprite.play("idle")


func seeker_setup():
	await get_tree().physics_frame
	if target:
		navigation_agent_2d.target_position=target.global_position



func _on_direction_change_timer_timeout():
	select_new_direction()
	pick_new_state()

func select_new_direction():
	var random = RandomNumberGenerator.new()
	moveDirection = Vector2(
		random.randi_range(-1, 1), # Possible values are -1, 0, 1 for X
		random.randi_range(-1, 1)  # Possible values are -1, 0, 1 for Y
	).normalized()

func pick_new_state():
	#if fly:
		#return
	if currentState == ChicState.Idle:
		currentState = ChicState.Walk
	elif currentState == ChicState.Walk:
		currentState = ChicState.Idle


func _on_timer_timeout() -> void:
	hungry = true
	currentState = ChicState.Idle  # Starea devine Idle pentru a permite animația "eat-short"
	hungry_timer.start()  # Pornește al doilea timer pentru resetarea stării hungry

func _on_reset_hungry_timer_timeout() -> void:
	hungry = false  # Resetează starea hungry
	currentState = ChicState.Idle  # Revine la starea inițială
	
# Oprește găina complet și o ascunde
func stop_chicken() -> void:
	velocity = Vector2.ZERO  # Oprește mișcarea
	currentState = ChicState.Idle  # Resetează starea # Oprește al doilea timer
	$directionChangeTimer.stop()  # Oprește schimbarea direcției
	animatedSprite.hide()  # Ascunde sprite-ul
	
func start_chicken()->void:
	$directionChangeTimer.start()  # Oprește schimbarea direcției
	currentState = ChicState.Idle
	animatedSprite.show() 


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		fly_timer.start()
		fly=true



func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		fly=false
