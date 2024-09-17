extends Area2D


var can_interact=false:
	set(value):
		can_interact=value
		%Label.visible=value


func _on_body_entered(body):
	if body.is_in_group("player"):
		can_interact=true


func _on_body_exited(body):
	if body.is_in_group("player"):
		can_interact=false


func interaction():
	owner.interact()
	print(owner.name+" interacted.")
	
	
func _input(event):
	if event.is_action_pressed("interact") and can_interact:
		interaction()
