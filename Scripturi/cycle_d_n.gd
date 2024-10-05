extends Node2D

const DAYS=["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
@onready var animation_player = $AnimationPlayer

var day_counter=0:
	set(value):
		day_counter=value
		%Day.text="Day "+str(day_counter)
		%DayOfWeek.text=DAYS[day_counter % 7]
		
		
func next_day():
	day_counter+=1


func _physics_process(_delta):
	var current_time=animation_player.current_animation_position
	var total_time=animation_player.current_animation_length
	var minute_passed=(current_time/total_time)*(24*60)
	%Minute.text=str(int(minute_passed)%60)
	%Hour.text=str(int(minute_passed/60)%12)
	
	
func lights(value=true):
	get_tree().call_group("LightSource","enable",value)
