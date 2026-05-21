extends Node2D

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
@onready var animation_player = $AnimationPlayer
@onready var ora: LineEdit = $CanvasLayer/Ora
@onready var minut: LineEdit = $CanvasLayer/Minut
@onready var Hour: Label = %Hour
@onready var Minute: Label = %Minute
signal day_changed(new_day: String)

var current_hour: int = 0 # Public variable for other scripts

var day_counter = 0:
	set(value):
		day_counter = value
		%Day.text = "Day " + str(day_counter)
		%DayOfWeek.text = DAYS[day_counter % 7]
		emit_signal("day_changed", DAYS[day_counter % 7])

var target_time = null 
var skipping = false 

# Păstrăm variabila start_time așa cum ai cerut, deși în 24h startul logic e adesea 00:00.
# Aici 12*60 (720) înseamnă că animația ta pornește vizual de la prânz.
var start_time = 00 * 60 

func next_day():
	day_counter += 1

func _ready():
	# Seek-ul rămâne la fel, poziționează animația relativ la start_time
	if animation_player.current_animation_length > 0:
		animation_player.seek(float(start_time) / (24.0 * 60.0) * animation_player.current_animation_length, true)

func _physics_process(_delta):
	var current_time = animation_player.current_animation_position
	var total_time = animation_player.current_animation_length
	
	# Calculăm minutele trecute. Offset-ul de 720 (12 ore) rămâne dacă animația ta începe vizual la prânz.
	var minute_passed = (int)((current_time / total_time) * (24 * 60) + 720) % (24 * 60)

	# Extragem ora în format 0-23
	var hour_24 = int(minute_passed / 60) % 24
	var minute = int(minute_passed) % 60
	
	current_hour = hour_24

	# --- MODIFICARE AICI: Afișare directă în format 24h ---
	# Am eliminat logica de hour_12 și AM/PM
	
	Hour.text = str(hour_24).pad_zeros(2) # Va afișa "00", "13", "23" etc.
	Minute.text = str(minute).pad_zeros(2)

	# Zi / Noapte (Intervalul 06:00 - 18:00 rămâne neschimbat)
	lights(hour_24 >= 6 and hour_24 < 18)

	# Skip automat
	if skipping:
		# Verificăm distanța până la target. 
		# Notă: Dacă target_time e 2:00 (120 min) și suntem la 23:00 (1380 min),
		# logica simplă < s-ar putea să nu funcționeze la trecerea peste miezul nopții,
		# dar pentru funcționalitatea curentă o lăsăm așa cum ai cerut (doar 24h display).
		if int(minute_passed) != target_time:
			# Folosim o toleranță mică pentru a opri skip-ul când ajunge aproape
			if abs(int(minute_passed) - target_time) < 5: 
				skipping = false
			else:
				animation_player.advance(2.0) # Viteza de skip
		else:
			skipping = false

func lights(value=true):
	get_tree().call_group("LightSource", "enable", value)

# Funcția primește acum ora direct în format 0-23
func set_target_time(hour: int, minute: int):
	target_time = hour * 60 + minute
	skipping = true

func skip_to_time(hour: int, minute: int):
	# Convertim ora în minute (format 0-23)
	target_time = hour * 60 + minute
	
	var total_time = animation_player.current_animation_length
	
	# Calculăm poziția în animație.
	# Deoarece animația începe la 12:00 (720 min), trebuie să decalam timpul țintă.
	# Exemplu: Vrei ora 13:00 (780 min). 780 - 720 = 60. Poziția e la 60 minute de la start.
	# Exemplu: Vrei ora 01:00 (60 min). 60 - 720 = -660. +1440 = 780. Poziția e după miezul nopții.
	var shifted_target_time = (target_time - 720 + 1440) % 1440
	
	var new_animation_position = (float(shifted_target_time) / (24.0 * 60.0)) * total_time

	if not animation_player.is_playing():
		animation_player.play()
	
	# Așteptăm procesarea pentru siguranță
	await get_tree().process_frame 
	animation_player.seek(new_animation_position, true)
	
	# Actualizăm UI-ul instantaneu
	var hour_24 = int(target_time / 60) % 24
	var min_display = int(target_time) % 60
	Hour.text = str(hour_24).pad_zeros(2)
	Minute.text = str(min_display).pad_zeros(2)

func _on_button_pressed():
	var hour_input = ora.text.to_int()
	var minute_input = minut.text.to_int()

	# Validare simplă pentru 24h
	if hour_input < 0 or hour_input > 23 or minute_input < 0 or minute_input > 59:
		print("Oră invalidă! Introduceți valori între 00:00 și 23:59.")
		return

	# Apelăm funcția cu valorile introduse (care sunt deja considerate 24h)
	skip_to_time(hour_input, minute_input)
