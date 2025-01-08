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

enum ChicState {
	Idle,
	Walk,
	Fly,
	EatL,
	EatS
}

func _ready():
	animatedSprite = $AnimatedSprite2D
	$directionChangeTimer.start()
	select_new_direction()
	pick_new_state()
	add_to_group("gaina")
	timer.start()
	fly_anime.hide()



func _physics_process(_delta):
	# Prioritizează starea de fly
	if fly:
		#hungry_timer.stop()
		#timer.stop()
		fly_anime.show()
		animatedSprite.hide()
		velocity = moveDirection * MoveSpeed  # Adaugă mișcare și în timpul zborului
		move_and_slide()

		# Redă animația de zbor doar dacă nu este deja redată
		if not animation_player.is_playing():
			if moveDirection.x < 0:
				animation_player.play("fly-st")
			elif moveDirection.x > 0:
				animation_player.play("fly-dr")
		return  # Ieși din funcție pentru a preveni logica altor stări
	
	# Gestionarea celorlalte stări
	elif currentState == ChicState.Walk:
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
	if fly:
		return
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

#
func _on_fly_timer_timeout() -> void:
	reset_after_fly()

#func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	#if fly and anim_name in ["fly-st", "fly-dr"]:
		#reset_after_fly()

func reset_after_fly():
	fly=false
	fly_anime.hide()  # Ascunde animația de zbor
	animatedSprite.show()  # Reafișează animația normală
	fly_anime.stop() 
	#hungry_timer.start()
	#timer.start() 
