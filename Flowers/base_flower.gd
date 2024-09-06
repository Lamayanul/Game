extends Node2D
class_name Flower

@export var harvest_ready:bool=false

var index=0

func _ready():
	$AnimationPlayer.play(str(index))
	
func _on_timer_timeout():
	index+=1
	$AnimationPlayer.play(str(index))
	if index == 3:  # Cand planta ajunge la index 3, o consideram matura
		harvest_ready = true  # Planta este gata de recoltat
		print("Plant is now harvestable")

func harvest()->void:
	queue_free()
	
