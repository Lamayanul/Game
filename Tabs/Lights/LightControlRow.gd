extends HBoxContainer

@onready var slot1 = $Slot1
@onready var slot2 = $Slot2
@onready var power_btn = $PowerButton
@onready var label = $Label

var target_light: Node2D = null

# Mapăm culorile după numele obiectului pentru a evita erorile de ID/Number
const NAME_COLORS = {
	"bec albastru": Color(0.2, 0.4, 1.0),
	"bec rosu": Color(1.0, 0.2, 0.2),
	"bec portocaliu": Color(1.0, 0.6, 0.0)
}

func setup(light_node: Node2D, light_name: String):
	target_light = light_node
	label.text = light_name
	
	if slot1: slot1.slot_type = "no_inv"
	if slot2: slot2.slot_type = "no_inv"

func _ready():
	power_btn.toggled.connect(_on_power_toggled)
	_on_power_toggled(power_btn.button_pressed)

func _on_power_toggled(is_on: bool):
	power_btn.text = "ON" if is_on else "OFF"
	power_btn.modulate = Color.GREEN if is_on else Color.RED

func _process(_delta):
	if not is_instance_valid(target_light):
		return
	update_light_logic()

func update_light_logic():
	if not is_instance_valid(target_light):
		return

	var prop1 = slot1.property if slot1.property is Dictionary else {}
	var prop2 = slot2.property if slot2.property is Dictionary else {}
	
	var n1 = str(prop1.get("NUME", "")).to_lower()
	var n2 = str(prop2.get("NUME", "")).to_lower()
	var is_on = power_btn.button_pressed

	var bulbs_count = 0
	var color_accumulator = Color(0, 0, 0, 0)

	# Sistem nou de detectare bazat pe continut (contains)
	for name_str in [n1, n2]:
		if name_str == "": continue
		
		if name_str.contains("bec"):
			if name_str.contains("albastru"):
				color_accumulator += Color(0.2, 0.4, 1.0,0.5)
				bulbs_count += 1
			elif name_str.contains("rosu"):
				color_accumulator += Color(1.0, 0.2, 0.2,0.5)
				bulbs_count += 1
			elif name_str.contains("portocaliu"):
				color_accumulator += Color(1.0, 0.6, 0.0,0.5)
				bulbs_count += 1

	var lights_found = _get_all_point_lights(target_light)

	if bulbs_count > 0 and is_on:
		var final_color = color_accumulator / bulbs_count
		final_color.a = 1.0

		# Forțăm părintele să fie vizibil în caz că a fost stins din editor
		if is_instance_valid(target_light):
			target_light.visible = true

		if lights_found.is_empty():
			target_light.modulate = final_color
		else:
			for pl in lights_found:
				pl.enabled = true
				pl.visible = true
				pl.color = final_color
				#pl.energy = 1.2
				# Ne asiguram ca lumina trece prin toate straturile
				pl.range_z_min = -1024
				pl.range_z_max = 1024
	else:
		# Stingem luminile
		for pl in lights_found:
			pl.enabled = false
		
		# Nu stingem vizibilitatea părintelui, doar a becurilor
		if is_instance_valid(target_light):
			target_light.modulate = Color(1, 1, 1, 1)


func _get_all_point_lights(node: Node) -> Array:
	var result = []
	if node is PointLight2D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_get_all_point_lights(child))
	return result
