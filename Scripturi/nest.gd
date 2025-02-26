extends StaticBody2D
@onready var gaina = get_node("/root/world/gaina")
var is_clocit = false
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
var clocit_times=0
@onready var timer_2: Timer = $Timer2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var scene_resource = preload("res://Scene/chick.tscn")
var instance = scene_resource.instantiate()
@onready var world = get_node("/root/world")
var harv_egg=false
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
var can_interact=false
@onready var fly_anime: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var timer_3: Timer = $Timer3

func _ready() -> void:
	animated_sprite_2d.hide()

func _process(_delta: float) -> void:
	if is_clocit:
		animated_sprite_2d.show()

		animation_player.play("clocit")
		
		

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("gaina") and is_clocit==false:
		gaina.stop_chicken()
		is_clocit = true  # Setează starea ca adevărat
		timer.start()
		clocit_times+=1
	if body.is_in_group("player"):
		can_interact=true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("gaina")and is_clocit:
		is_clocit = false  # Setează starea ca fals
		gaina.start_chicken()
	if body.is_in_group("player"):
		can_interact=false
		
func _input(event):
	if harv_egg and event.is_action_pressed("interact") and can_interact:
		inv.add_item("1", 1)
		animation_player.play("mt")
		harv_egg = false
		clocit_times=0

func _on_timer_timeout() -> void:
	is_clocit=false
	gaina.start_chicken()
	if clocit_times==3:
			egg_move()
	else:
		animation_player.play("ou")
		harv_egg=true
	
func egg_move():
	animation_player.play("ou_move")
	timer_2.start()
	

func _on_timer_2_timeout() -> void:
	animation_player.play("eclozare")
	clocit_times=0
	timer_3.start()


func _on_timer_3_timeout() -> void:
	instance.position=area_2d.global_position;
	world.add_child(instance)
	timer_3.stop()
