extends Node2D

@export var ID =""
@export var item_cantitate:int =1
@onready var grid_container = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer")
@onready var shadow = Sprite2D.new()
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var float_amplitude: float = 2.0  
var float_speed: float = 2.0 
var original_position: Vector2 
var time_passed: float = 0.0  
@onready var slot_container: Slot = $CanvasLayer/GridContainer/SlotContainer
var timp_ramas: int = 0
# Variabile pentru textura și cantitate
var item_texture: Texture
var last_cantitate = 0
@onready var timer: Timer = $CanvasLayer/Timer
@onready var label: Label = $CanvasLayer/Label

func _ready():
	pass

func _process(delta: float):
	# Actualizează label-ul cu timpul rămas
	pass


func lamp():
	var item_23_gasit = false
	for i in range(grid_container.get_child_count()):
			label.text = format_time(timp_ramas)
			var slot = grid_container.get_child(i)
			if slot is Slot:
				# Verifica daca slotul este plin si contine un scut
				if slot.get_id() == "23":
					item_23_gasit = true
					$CanvasLayer.visible = true
					if slot_container.get_id()=="7":
						var cantitate= slot_container.get_cantitate()
						slot_container.clear_item()
						if cantitate>=0:
							timp_ramas = cantitate * 60
							emit_signal("cere_aprinderea_luminii")
							timer.start()
	if not item_23_gasit:
		$CanvasLayer.visible = false


func _on_timer_timeout() -> void:
	if timp_ramas > 0:
		timp_ramas -= 1  # Scade o secundă din timpul rămas
		label.text = format_time(timp_ramas)  # 🔥 Actualizează UI-ul

		# Consumă 1 combustibil la fiecare 60 secunde
		if timp_ramas % 60 == 0:
			var cantitate = slot_container.get_cantitate()
			if cantitate > 0:
				slot_container.set_cantitate(cantitate - 1)  # 🔥 Consumă combustibil
				print("Cantitatea rămasă: " + str(cantitate - 1))

			if cantitate - 1 <= 0:
				print("Combustibilul s-a epuizat!")
			
	else:
		timer.stop()
		print("Timpul a expirat!")


func format_time(seconds: int) -> String:
	var minutes = seconds / 60
	var secs = seconds % 60
	return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)
