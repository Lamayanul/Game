extends Node2D

@onready var light_beam = $VisualBeam
@onready var environment_light = $EnvironmentLight
@onready var fireflies = $Fireflies

# Referințe către UI (CanvasLayer)
@onready var slot1 = $CanvasLayer/Control/Slots/SlotContainer
@onready var slot2 = $CanvasLayer/Control/Slots/SlotContainer2
@onready var power_button = $CanvasLayer/Control/PowerButton

var is_power_on: bool = true

# Definim culorile pentru becuri
const COLORS = {
	"19": Color(0.2, 0.4, 1.0, 1.0),   # Albastru
	"20": Color(1.0, 0.2, 0.2, 1.0),   # Roșu
	"21": Color(1.0, 0.6, 0.0, 1.0)    # Portocaliu
}

func _ready():
	if slot1: slot1.slot_type = "no_inv"
	if slot2: slot2.slot_type = "no_inv"
	
	if power_button:
		power_button.pressed.connect(_on_power_button_pressed)
		update_button_text()

func _on_power_button_pressed():
	is_power_on = !is_power_on
	update_button_text()

func update_button_text():
	if power_button:
		power_button.text = "LUMINA: ON" if is_power_on else "LUMINA: OFF"

func _process(_delta):
	update_lights()

func update_lights():
	if not slot1 or not slot2 or not light_beam or not environment_light:
		return
		
	var id1 = slot1.get_id()
	var id2 = slot2.get_id()
	
	var color1 = COLORS.get(id1, Color(0,0,0,0))
	var color2 = COLORS.get(id2, Color(0,0,0,0))
	
	var final_color = Color(0,0,0,0)
	var active_count = 0
	
	if id1 in COLORS:
		final_color += color1
		active_count += 1
	if id2 in COLORS:
		final_color += color2
		active_count += 1
		
	# Lumina se aprinde doar dacă avem becuri ȘI butonul de Power este ON
	if active_count > 0 and is_power_on:
		final_color = final_color / active_count
		
		light_beam.visible = true
		environment_light.enabled = true
		
		# Particulele apar doar când lumina e activă
		if fireflies:
			fireflies.emitting = true
			fireflies.visible = true
		
		# Aplicăm culoarea pe beam (via shader parameter)
		var beam_final = final_color
		beam_final.a = 0.5
		light_beam.material.set_shader_parameter("beam_color", beam_final)
		
		# Aplicăm pe PointLight2D
		var light_final = final_color
		light_final.a = 1.0
		environment_light.color = light_final
	else:
		# Stingem totul
		light_beam.visible = false
		environment_light.enabled = false
		if fireflies:
			fireflies.emitting = false
			fireflies.visible = false
