extends StaticBody2D

var open_fuel = false
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var label_2: Label = $CanvasLayer/Label2
@onready var label: Label = $CanvasLayer/Label
@onready var slot_container: Slot = $CanvasLayer/SlotContainer
@onready var timer: Timer = $Timer
@onready var inv = get_node("/root/world/Inventar/Inv")
@onready var progress_bar: ProgressBar = $CanvasLayer/ProgressBar
var generator_on = false 
var legat=false
var fuel_capacity = 100
var timp_ramas: int = 0  # Timpul total rămas în secunde



func _ready() -> void:
	canvas_layer.visible = false
	progress_bar.min_value = 0  # Minimul valorii (0%)
	progress_bar.max_value = fuel_capacity
	progress_bar.value = 0  # Inițializarea valorii la 0

func _process(_delta: float) -> void:
	if open_fuel:
		canvas_layer.visible = true
		label_2.text = format_time(timp_ramas)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		open_fuel = true
		canvas_layer.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		open_fuel = false
		canvas_layer.visible = false

func add_fuel() -> void:
	if slot_container.get_id() == "7":  # Verificăm ID-ul slotului
		var cantitate = slot_container.get_cantitate()
		slot_container.clear_item()
		if cantitate > 0:  # Verificăm dacă există combustibil
			print("În slot sunt " + str(cantitate) + " bucăți")
			timp_ramas += cantitate * 60  # Adaugă timp în funcție de cantitate

			# Configurează Timerul să ticăie la fiecare secundă
			progress_bar.value=timp_ramas/60
			timer.wait_time = 1
			generator_on=true
			timer.start()
		

func _on_timer_timeout() -> void:
	if timp_ramas > 0:
		timp_ramas -= 1  # Scade o secundă din timpul rămas
		label_2.text = format_time(timp_ramas)  # Actualizează eticheta
		progress_bar.value = timp_ramas/60
		# Decrementăm cantitatea din slot la fiecare minut consumat
		if timp_ramas % 60 == 0:
			var cantitate = slot_container.get_cantitate()
			
			if cantitate > 0:
				
				print("Cantitatea rămasă: " + str(cantitate - 1))

			if cantitate - 1 <= 0:
				print("Combustibilul din slot s-a epuizat!")
			
	else:
		timer.stop()  # Oprește timerul când timpul se termină
		print("Timpul a expirat!")

func format_time(seconds: int) -> String:
	var minutes = seconds / 60
	var secs = seconds % 60
	return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)


func _on_button_pressed() -> void:
	if slot_container.get_cantitate()>0 and slot_container.get_id()=="7":
		add_fuel()
	elif generator_on == false and timp_ramas > 0:
		print("Generator pornit.")
		generator_on = true
		timer.start()


func _on_button_3_pressed() -> void:
	# Oprește sau pornește generatorul
	if generator_on:
		print("Generator oprit.")
		generator_on = false
		timer.stop()

func _on_area_interact_area_entered(area: Area2D) -> void:
	# Verifică dacă zona care a intrat în aria de interacțiune face parte din grupul "pillar"
	if area.is_in_group("pillar"):
		legat=true
