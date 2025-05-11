extends Node2D

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
@onready var animation_player = $AnimationPlayer
@onready var ora: LineEdit = $CanvasLayer/Ora
@onready var minut: LineEdit = $CanvasLayer/Minut
@onready var Hour: Label = %Hour
@onready var Minute: Label = %Minute

var day_counter = 0:
	set(value):
		day_counter = value
		%Day.text = "Day " + str(day_counter)
		%DayOfWeek.text = DAYS[day_counter % 7]

var target_time = null  # Ora aleasă pentru skip (ex: 15:30 → 15*60 + 30 = 930 minute)
var skipping = false  # Indică dacă trebuie să avansăm timpul

# Setează ora la 12:00 PM (12:00 PM în formatul de 24h este 12:00)
var start_time = 12 * 60  # 12:00 PM este 12 ore în formatul de 24h (adică 720 minute)

func next_day():
	day_counter += 1

func _ready():
	# Setăm poziția animației pentru a începe de la 12:00 PM (720 minute)
	animation_player.seek(start_time / (24 * 60) * animation_player.current_animation_length, true)

func _physics_process(_delta):
	var current_time = animation_player.current_animation_position
	var total_time = animation_player.current_animation_length
	var minute_passed = (int)((current_time / total_time) * (24 * 60) + 720) % (24 * 60)


	var hour_24 = int(minute_passed / 60) % 24
	var minute = int(minute_passed) % 60

	# Conversie în 12h și etichetă AM/PM
	var hour_12 = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	var period = "AM" if hour_24 < 12 else "PM"

	Hour.text = str(hour_12).pad_zeros(2) + " " + period
	Minute.text = str(minute).pad_zeros(2)

	# Zi / Noapte
	lights(hour_24 >= 6 and hour_24 < 18)

	# Skip automat
	if skipping:
		if int(minute_passed) < target_time:
			animation_player.advance(2.0)
		else:
			skipping = false


func lights(value=true):
	get_tree().call_group("LightSource", "enable", value)

# Funcție pentru a seta ora dorită (ex: skip la 18:15)
func set_target_time(hour: int, minute: int):
	# Convertim ora în minute
	target_time = hour * 60 + minute
	skipping = true  # Activăm modul de skip

func skip_to_time(hour: int, minute: int):
	


	# Convertim ora în minute
	target_time = hour * 60 + minute
	
	var total_time = animation_player.current_animation_length
	# Calculăm poziția exactă în animație, unde 0 minute reprezintă 12:00 PM
	var shifted_target_time = (target_time - 720 + 1440) % 1440
	var new_animation_position = (shifted_target_time / (24.0 * 60.0)) * total_time

	# Asigură-te că animația nu este setată pe loop sau ajustează manual loop-ul
	animation_player.play()  # Asigură-te că animația rulează
	await get_tree().process_frame  # Așteptăm un frame pentru a evita reset-ul
	animation_player.seek(new_animation_position, true)  # Salt la ora dorită

func _on_button_pressed():
	var hour_input = ora.text.to_int()
	var minute = minut.text.to_int()

	# Valori valide
	if hour_input < 0 or hour_input >= 24 or minute < 0 or minute >= 60:
		print("Oră invalidă! Introduceți valori corecte.")
		return

	# Nu mai încercăm să deducem AM/PM din text — presupunem că ora introdusă e în format 24h
	# Ex: 13 = 1 PM, 0 = 12 AM, 12 = 12 PM

	skip_to_time(hour_input, minute)
