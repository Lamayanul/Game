extends CharacterBody2D

var movement = 10
@export var target: Node2D = null
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var sprite_2d = $Sprite2D
var map_ready = false
@onready var animation_player = $AnimationPlayer
@onready var ancorare = $ancorare
@onready var player = $"../player"
var is_anchored = false  
var player_in_proximity = false  
@onready var area_ancorare = $"area-ancorare"
var moveDirection = Vector2.ZERO
var random_move_active = false 
@onready var change_direction_timer = $change_direction_timer
var miscare=false
var player_in_boat=false
var player_near_boat=false
@onready var animated_sprite_2d = $AnimatedSprite2D
var moveDirectionHandlerBoat=Vector2.ZERO
@onready var camera_boat: Camera2D = $camera_boat
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

#-----------------------------------ready----------------------------------------------------

func _ready():
	NavigationServer2D.connect("map_changed", Callable(self, "_on_map_changed"))
	call_deferred("seeker_setup")
	is_anchored=true
	change_direction_timer.stop()
	player_in_boat=false


	

#----------------------------urmarire----------------------------------------------------------
func seeker_setup():
	await get_tree().physics_frame
	if target and map_ready:
		navigation_agent_2d.target_position = target.global_position


#---------------------------miscare barca + animatii--------------------------------------------
func _physics_process(_delta):
	if player_in_proximity and Input.is_action_just_pressed("ancorare"):
		if not is_anchored:
			# Barca este ancorată
			is_anchored = true 
			velocity = Vector2.ZERO 
			random_move_active = false
			ancorare.stop() 
			animation_player.play("idle") 
			print("Barca a fost ancorată")
			change_direction_timer.stop()
			
		else:
			# Dezancorăm barca
			is_anchored = false
			random_move_active = true  
			velocity = Vector2.ZERO
			ancorare.start() 
			animation_player.play("idle-dez") 
			print("Barca a fost dezancorată")
			miscare=false
	
	if player_near_boat and Input.is_action_just_pressed("barca") and is_anchored==false:
		
		if player_in_boat==true:
		
			exit_boat()
		else:
			
			enter_boat()
			
	
	# Control barcă dacă jucătorul este în ea
	if player_in_boat:
		if is_anchored==true:
			return
		change_direction_timer.stop()
		handle_boat_control(_delta)
		return
		
	if is_anchored:
		animation_player.play("idle") 
		return  
	


		
	if not random_move_active:
		return

	# Aplicăm mișcarea doar dacă direcția este validă
	if random_move_active and moveDirection != Vector2.ZERO and miscare==true:
		velocity = moveDirection * movement 
		move_and_slide() 
		

	if not map_ready:
		return
		
	
	# Logica de navigare
	if target and not is_anchored:
		navigation_agent_2d.target_position = target.global_position
	
	
	# Verificăm dacă navigația s-a terminat
	if navigation_agent_2d.is_navigation_finished() and not player_in_boat:
		if not is_anchored:
			animation_player.play("idle-dez")  
			return

	# Calculăm direcția și mișcarea
	var current_agent_position = global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	velocity = current_agent_position.direction_to(next_path_position) * movement
	animation_player.play("sail")  
	

	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = true
		$dreapta.visible = true
		$stanga.visible = false
	else:
		$AnimatedSprite2D.flip_h = false
		$dreapta.visible = false
		$stanga.visible = true
	move_and_slide()



#--------------------------------------atingere destinatie------------------------------------------

func _on_navigation_agent_2d_path_changed():
	map_ready = true

func _on_map_changed(_arg = null):
	map_ready = true

func _on_navigation_agent_2d_target_reached():
	target = null
	if not is_anchored:
		animation_player.play("idle-dez")

func _on_ancorare_timeout():
	if not is_anchored:
		miscare=true
		random_move_active = true
		change_direction_timer.start()  



#------------------------------schimbare directie barca-----------------------------------------------
func _on_change_direction_timeout():
	if random_move_active:
		select_new_direction()

func is_vector_approx_equal(v1: Vector2, v2: Vector2, epsilon: float) -> bool:
	return abs(v1.x - v2.x) <= epsilon and abs(v1.y - v2.y) <= epsilon

func select_new_direction():
	# Alegem o direcție aleatorie pentru barcă
	var random = RandomNumberGenerator.new()
	moveDirection = Vector2(
		random.randi_range(-1, 1), 
		random.randi_range(-1, 1)
	).normalized() 
	var epsilon = 0.001

	# Comparăm vectorii cu toleranță
	if is_vector_approx_equal(moveDirection, Vector2(-1, 0), epsilon) || is_vector_approx_equal(moveDirection, Vector2(1, 0), epsilon):
		moveDirection = Vector2(0, 0)
	elif is_vector_approx_equal(moveDirection, Vector2(-0.707107, 0.707107), epsilon) ||  is_vector_approx_equal(moveDirection, Vector2(0, 1), epsilon) ||  is_vector_approx_equal(moveDirection, Vector2(0.707107, 0.707107), epsilon):
		moveDirection = Vector2(-0.707107, -0.707107)
	print("Noua direcție aleasă: ", moveDirection)

#----------------------------in apropierea barcii--------------------------------------------------------
func _on_areaancorare_body_entered(body):
	if body.is_in_group("player"):  
		player_in_proximity = true
		print("Jucătorul este în apropierea bărcii")
		
		

func _on_areaancorare_body_exited(body):
	if body.is_in_group("player"): 
		player_in_proximity = false


#--------------------------------in barca-------------------------------------------------------------------


func enter_boat():
	# Jucătorul intră în barcă
	player_in_boat=true
	#player.visible=false
	player.is_jumping=false
	player.can_jump=false
	 # Ascundem jucătorul
	player.set_process(false)
	player.set_physics_process(false)  # Dezactivăm procesarea jucătorului
	miscare = false  # Oprim mișcarea aleatorie cât timp controlăm barca manual
	movement=50
	camera_boat.make_current()
	player.reparent(self)  # Reatașează jucătorul ca „child” al bărcii
	player.global_position = global_position + Vector2(0,3) 
	change_direction_timer.stop()  # Oprim schimbarea direcției aleatorii
	print("Jucătorul a intrat în barcă")
	

func exit_boat():
	# Jucătorul iese din barcă
	player_in_boat=false
	player.visible=true
	miscare = false #
	player.is_jumping=false
	player.can_jump=true
	player.set_process(true)
	player.set_physics_process(true)  
	player.reparent(get_tree().get_root().get_node("world")) 
	player.camera_2d.make_current()
	movement=10
	change_direction_timer.stop()  # Repornim timer-ul pentru schimbarea direcției aleatorii
	print("Jucătorul a ieșit din barcă")
	
	
	
func _on_in_boat_body_entered(body):
	if body.is_in_group("player"):
		player_near_boat=true
		player.is_jumping=false
		player.Speed=10
		



func _on_in_boat_body_exited(body):
	if body.is_in_group("player"):
		player_near_boat=false
		player.is_jumping=true
		player.Speed=50
		
	


#---------------------------------handl-ere-----------------------------------------------------------------

func handle_boat_control(_delta):
	
	# Control manual pentru barcă
	if Input.is_action_pressed("move_left"):
		moveDirectionHandlerBoat = Vector2.LEFT
		animated_sprite_2d.flip_h=false
		#animated_sprite_2d.rotation_degrees=0
	elif Input.is_action_pressed("move_right"):
		animated_sprite_2d.flip_h=true
		moveDirectionHandlerBoat = Vector2.RIGHT
		
	elif Input.is_action_pressed("move_up"):
		#animated_sprite_2d.rotation_degrees=90
		moveDirectionHandlerBoat = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		#animated_sprite_2d.rotation_degrees = -90
		moveDirectionHandlerBoat = Vector2.DOWN
	else:
		moveDirectionHandlerBoat = Vector2.ZERO
		
	

	if moveDirectionHandlerBoat != Vector2.ZERO:
		
		velocity = moveDirectionHandlerBoat.normalized() * movement
		animated_sprite_2d.play("sail")
		move_and_slide()
		
	else:
		
		animated_sprite_2d.play("idle_dez")
	
		
func handle_player_control(_delta):
	
	pass
