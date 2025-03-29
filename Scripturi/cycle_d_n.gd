extends Node2D

const DAYS=["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
@onready var animation_player = $AnimationPlayer
@onready var ora: LineEdit = $CanvasLayer/Ora
@onready var minut: LineEdit = $CanvasLayer/Minut



var day_counter = 0:
	set(value):
		day_counter = value
		%Day.text = "Day " + str(day_counter)
		%DayOfWeek.text = DAYS[day_counter % 7]

var target_time = null  # Ora aleasă pentru skip (ex: 15:30 → 15*60 + 30 = 930 minute)
var skipping = false  # Indică dacă trebuie să avansăm timpul

func next_day():
	day_counter += 1

func _physics_process(_delta):
	var current_time = animation_player.current_animation_position
	var total_time = animation_player.current_animation_length
	var minute_passed = (current_time / total_time) * (24 * 60)

	%Minute.text = str(int(minute_passed) % 60).pad_zeros(2)
	%Hour.text = str(int(minute_passed / 60) % 12).pad_zeros(2)

	# 🔹 Dacă suntem în modul skip, avansăm timpul gradual
	if skipping:
		if int(minute_passed) < target_time:
			animation_player.advance(2.0)  # 🔥 Crește viteza avansării timpului
		else:
			skipping = false  # Oprim avansarea automată >= target_time:
		skipping = false  # Oprim skip-ul

func lights(value=true):
	get_tree().call_group("LightSource", "enable", value)

# 📌 Funcție pentru a seta ora dorită (ex: skip la 18:15)
func set_target_time(hour: int, minute: int):
	target_time = hour * 60 + minute
	skipping = true  # Activăm modul de skip


func skip_to_time(hour: int, minute: int):
	target_time = hour * 60 + minute  # Convertim ora în minute
	
	var total_time = animation_player.current_animation_length
	var new_animation_position = (target_time / (24.0 * 60.0)) * total_time  # Calculăm poziția exactă în animație

	# ⚠️ Asigură-te că animația este setată să NU fie pe loop (sau ajustează manual loop-ul)
	animation_player.play()  # Asigură-te că animația rulează
	await get_tree().process_frame  # Așteptăm un frame ca să evităm reset-ul
	animation_player.seek(new_animation_position, true)  # Skip la ora dorită




func _on_button_pressed():
	var hour = ora.text.to_int()
	var minute = minut.text.to_int()
	if hour >= 0 and hour < 24 and minute >= 0 and minute < 60:
		skip_to_time(hour, minute) 
	else:
		print("Oră invalidă! Introduceți valori corecte.") 
