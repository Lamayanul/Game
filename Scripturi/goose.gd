extends CharacterBody2D

# Variables
@export var Speed: float = 20.0
var moveDirection = Vector2.ZERO
var currentState = ChicState.Idle
var animatedSprite: AnimatedSprite2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var direction_change_timer: Timer = $directionChangeTimer
@onready var animation_player_2: AnimationPlayer = $AnimationPlayer2
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2



enum ChicState {
	Idle,
	Walk,
	Fly,
	EatL,
	EatS
}

func _ready():
	animatedSprite = $AnimatedSprite2D
	direction_change_timer.start()
	select_new_direction()
	pick_new_state()
	


func _physics_process(_delta):
	movement()
	move_and_slide()




func movement():
	if currentState == ChicState.Walk :
		velocity = moveDirection * Speed

				
	if velocity.length() > 0:
		velocity = velocity.normalized() * Speed
		if velocity.x != 0:
			if velocity.x < 0:
				animatedSprite.flip_h = true
				animated_sprite_2d_2.flip_h = true
				animation_player_2.play("walk_corp")
				animation_player.play("walk_cioc_sabie")

			else:
				animatedSprite.flip_h = false
				animated_sprite_2d_2.flip_h = false
				animation_player_2.play("walk_corp")
				animation_player.play("walk_cioc_sabie")

				
		elif velocity.y != 0:
			if velocity.y < 0:
				animation_player_2.play("walk_corp")
				animation_player.play("walk_cioc_sabie")

			else:
				animation_player_2.play("walk_corp")
				animation_player.play("walk_cioc_sabie")




func _on_direction_change_timer_timeout():
	select_new_direction()
	pick_new_state()
	direction_change_timer.wait_time = randi_range(2, 3)  # Setează timpul de așteptare aleatoriu
	direction_change_timer.start()  # Pornește timerul

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
