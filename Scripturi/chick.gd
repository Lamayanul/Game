extends CharacterBody2D

# Variables
@export var MoveSpeed: float = 10.0
var hungry=false
var moveDirection = Vector2.ZERO
var currentState = ChicState.Idle
var animatedSprite: AnimatedSprite2D


enum ChicState {
	Idle,
	Walk,
}

func _ready():
	animatedSprite = $AnimatedSprite2D
	$directionChangeTimer.start()
	select_new_direction()
	pick_new_state()
	add_to_group("chick")

func _physics_process(_delta):
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
		#if hungry==true:
			#animatedSprite.play("eat-short")
		#else:
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
	if currentState == ChicState.Idle:
		currentState = ChicState.Walk
	elif currentState == ChicState.Walk:
		currentState = ChicState.Idle


#func _on_timer_timeout() -> void:
	#hungry = true
	#currentState = ChicState.Idle  # Starea devine Idle pentru a permite animația "eat-short"
	#timer_2.start()  # Pornește al doilea timer pentru resetarea stării hungry
#
#func _on_reset_hungry_timer_timeout() -> void:
	#hungry = false  # Resetează starea hungry
	#currentState = ChicState.Idle  # Revine la starea inițială
	#
## Oprește găina complet și o ascunde
#func stop_chicken() -> void:
	#velocity = Vector2.ZERO  # Oprește mișcarea
	#currentState = ChicState.Idle  # Resetează starea # Oprește al doilea timer
	#$directionChangeTimer.stop()  # Oprește schimbarea direcției
	#animatedSprite.hide()  # Ascunde sprite-ul
	#
#func start_chicken()->void:
	#$directionChangeTimer.start()  # Oprește schimbarea direcției
	#currentState = ChicState.Idle
	#animatedSprite.show() 
