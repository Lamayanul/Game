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
var following_target=false
var targets: Array = []
var current_target: Node2D = null
var hrana=0
@onready var hungry_time: Timer = $hungry_time
@onready var direction_change_timer: Timer = $directionChangeTimer



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
	timer.start()
	fly_anime.hide()
	direction_change_timer.start()
	select_new_direction()
	pick_new_state()


func _physics_process(_delta):
	if hrana==5:
		movement() 
		move_and_slide()
		return
	else:
		if targets.size() > 0:
			select_closest_target()

		if current_target and is_instance_valid(current_target):
			# 🔹 Verifică dacă am ajuns la țintă
			if global_position.distance_to(current_target.global_position) < 1:
				targets.erase(current_target)  # Elimină ținta curentă
				current_target = null  # Resetează ținta
				if targets.size() > 0:
					select_closest_target()  # Alege următoarea țintă
			
			if current_target and is_instance_valid(current_target):
				navigation_agent_2d.target_position = current_target.global_position
			var next_path_position = navigation_agent_2d.get_next_path_position()
			velocity = (next_path_position - global_position).normalized() * MoveSpeed
			move()
			
		else:
			movement() 

	move_and_slide()
	hungry_time.start()

func select_closest_target():
	# 🔹 Elimină țintele invalide
	targets = targets.filter(func(target_1): return is_instance_valid(target_1))
	if targets.is_empty():
		current_target = null
		return

	var closest_target = null
	var min_distance = INF  

	for targeta in targets:
		var distance = global_position.distance_to(targeta.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_target = targeta
	
	current_target = closest_target
	



func movement():
	if currentState == ChicState.Walk and not following_target:
		velocity = moveDirection * MoveSpeed

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

func move():
	if moveDirection != Vector2.ZERO:
		animatedSprite.play("walk")
		if moveDirection.x < 0:
			animatedSprite.flip_h = true
		elif moveDirection.x > 0:
			animatedSprite.flip_h = false

func seeker_setup():
	await get_tree().physics_frame
	if target:
		navigation_agent_2d.target_position=target.global_position



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
	direction_change_timer.stop()  # Oprește schimbarea direcției
	animatedSprite.hide()  # Ascunde sprite-ul
	
func start_chicken()->void:
	if direction_change_timer.is_inside_tree():
		direction_change_timer.start()
		currentState = ChicState.Idle
		animatedSprite.show() 
	else:
		print("Timerul nu este în scenă încă!")

 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		fly_timer.start()
		fly=true



func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		fly=false


func _on_hungry_time_timeout() -> void:
	hrana = 0  
	print("hrana")
	if targets.size() > 0:
		select_closest_target()

		if current_target and is_instance_valid(current_target):
			print("🎯 Reîncep navigarea către:", current_target)

			# Setează ținta și forțează recalcularea traseului
			navigation_agent_2d.target_position = current_target.global_position
			navigation_agent_2d.target_position = current_target.global_position

			# Actualizează mișcarea
			var next_path_position = navigation_agent_2d.get_next_path_position()
			velocity = (next_path_position - global_position).normalized() * MoveSpeed
			move()  
	else:
		print("⚠️ Nicio țintă disponibilă, stau pe loc!")
		movement()  
	
