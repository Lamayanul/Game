extends CharacterBody2D

var Speed = 50
var player_chase = false
var player = null
var health=100
var player_inattack_range=false
@onready var animated_sprite_2d = $AnimatedSprite2D
var can_take_damage=true
@onready var take_damage = $take_damage

func _physics_process(delta):
	move_and_slide()
	deal_with_damage()

	if player_chase:
		# Calcul distanță dintre inamic și jucător
		var direction = (player.position - position).normalized()

		# Mișcarea inamicului spre jucător
		position += direction * Speed * delta
		
		# Determină direcția de mișcare dominantă pentru a seta animația
		if abs(direction.x) > abs(direction.y):  # Mișcare pe X
			if direction.x < 0:
				animated_sprite_2d.play("walk-stanga")
			else:
				animated_sprite_2d.play("walk-dreapta")
		else:  # Mișcare pe Y
			if direction.y < 0:
				animated_sprite_2d.play("walk-sus")
			else:
				animated_sprite_2d.play("walk-jos")
	else:
		animated_sprite_2d.play("idle")

# Funcție pentru a detecta când jucătorul intră în aria de urmărire
func _on_detection_body_entered(body):
	player = body
	player_chase = true

# Funcție pentru a detecta când jucătorul iese din aria de urmărire
func _on_detection_body_exited(body):
	player = null
	player_chase = false

func enemy():
	pass


func _on_enemy_hitbox_body_entered(body):
	if body.has_method("player"):
		player_inattack_range=true


func _on_enemy_hitbox_body_exited(body):
	if body.has_method("player"):
		player_inattack_range=false

func deal_with_damage():
	if(player_inattack_range and Global.player_current_attack==true):
		if can_take_damage==true:
			health-=10
			take_damage.start()
			can_take_damage=false
			print("enemy health: ",health)
			if health<=0:
				self.queue_free()


func _on_take_damage_timeout():
	can_take_damage=true
