extends Node2D
class_name Flower

@export var harvest_ready:bool=false

var index=0

func _ready():
	$AnimationPlayer.play(str(index))
	
func _on_timer_timeout():
	index+=1
	$AnimationPlayer.play(str(index))
