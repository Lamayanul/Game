extends Area2D

@onready var bush_fructe = $StaticBody2D/Bush_fructe
@onready var bush_normal = $StaticBody2D/Bush_normal
@onready var timer_respawn = $Timer_respawn
@onready var inv = $"../CanvasLayer/Inv"
var player_in_zone = false  


func _ready():
	bush_fructe.visible = false
	bush_normal.visible = true
	timer_respawn.start()

# Funcție pentru gestionarea temporizatorului 
func _on_timer_respawn_timeout():
	bush_fructe.visible = true
	bush_normal.visible = false
	timer_respawn.stop()

# Funcție care este apelată constant în fiecare frame
func _process(_delta):
	#hue=fmod(hue+(delta*cycles_per_second),1.0)
	#bush_normal.modulate=Color.from_hsv(hue,1.0,1.0)
	if player_in_zone and Input.is_action_just_pressed("interact"):
		if bush_fructe.visible:  # Verificăm dacă fructele sunt vizibile
			bush_fructe.visible = false
			bush_normal.visible = true
			var drop_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10)) 
			var drop_position = global_position + drop_offset 
			inv.drop_item_everywhere("8", 3, drop_position)
			timer_respawn.start() 

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = true  


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_zone = false 
