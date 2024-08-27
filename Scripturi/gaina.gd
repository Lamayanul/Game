extends CharacterBody2D

# Variables
@export var MoveSpeed: float = 20.0
var moveDirection = Vector2.ZERO
var currentState = ChicState.Idle
var animatedSprite: AnimatedSprite2D

enum ChicState {
	Idle,
	Walk
}

func _ready():
	animatedSprite = $AnimatedSprite2D
	$directionChangeTimer.start()
	select_new_direction()
	pick_new_state()
	add_to_group("gaina")

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
