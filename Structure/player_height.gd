extends Area2D

var height = false


@onready var player = get_node_or_null("/root/world/player")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and height==false:
		body.set_collision_mask_value(2,false)
		body.set_collision_mask_value(1,true)






func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and height:
		body.set_collision_mask_value(2,true)
		body.set_collision_mask_value(1,false)



		


func _ready() -> void:
	# Ne asigurăm că semnalele sunt conectate pentru trigger-ul de înălțime
	var trigger = get_node_or_null("../../Area2D")
	if trigger:
		if not trigger.is_connected("body_exited", _on_area_2d_body_exited_trigger):
			trigger.body_exited.connect(_on_area_2d_body_exited_trigger)

func _on_area_2d_body_entered(body: Node2D) -> void:
	# La intrare nu schimbăm starea încă
	pass

func _on_area_2d_body_exited_trigger(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Găsim Area2D-ul care acționează ca trigger
		var trigger = get_node_or_null("../../Area2D")
		var reference_y = global_position.y
		if trigger:
			reference_y = trigger.global_position.y
			
		var player_y = body.global_position.y
		if body.has_node("colisiune"):
			player_y += body.get_node("colisiune").position.y
			
		# Dacă jucătorul a ieșit prin PARTEA DE SUS a zonei (Y mai mic decât centrul),
		# înseamnă că a urcat cu succes.
		if player_y < reference_y:
			height = true
		else:
			# Dacă a ieșit prin PARTEA DE JOS (Y mai mare), înseamnă că este jos (sau s-a întors)
			height = false

		actualizează_stare_jucător(body)

func actualizează_stare_jucător(body: Node2D) -> void:
	if height:
		body.set_collision_mask_value(2, true)
		body.set_collision_mask_value(1, false)
		player.z_index = 1
		player.is_high = true
	else:
		body.set_collision_mask_value(2, false)
		body.set_collision_mask_value(1, true)
		player.z_index = 0
		if has_node("../../StativBody2D/CollisionShape2D"):
			$"../../StativBody2D/CollisionShape2D".set_deferred("disabled", true)
		player.is_high = false
			


func _on_area_under_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if height:
			body.set_collision_mask_value(2,true)
			body.set_collision_mask_value(1,false)
			player.z_index=1
			player.is_high=true
			$"../../StativBody2D/CollisionShape2D".set_deferred("disabled", true)
	
			
		else:
			body.set_collision_mask_value(2,false)
			body.set_collision_mask_value(1,true)
			player.z_index=0
			player.is_high=false
			$"../../StativBody2D/CollisionShape2D".set_deferred("disabled", false)
			$"../..".modulate=Color(1, 1, 1, 0.5)
			


func _on_area_under_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if player.este_transparent==false:
			$"../..".modulate=Color(1, 1, 1, 1)
			$"../../StativBody2D/CollisionShape2D".set_deferred("disabled", true)
			
