extends VBoxContainer

@export var row_scene: PackedScene = preload("res://Tabs/Lights/LightControlRow.tscn")

func _ready():
	# Așteptăm un cadru pentru a ne asigura că arborele scenei este complet încărcat
	await get_tree().process_frame
	populate_lights()

func populate_lights():
	print("[LightPanel] Populating lights...")
	# Curățăm copiii existenți
	for child in get_children():
		child.queue_free()
	
	var lights = get_tree().get_nodes_in_group("light")
	print("[LightPanel] Found ", lights.size(), " lights in group 'light'")
	
	if lights.is_empty():
		var label = Label.new()
		label.text = "Nu s-au găsit lumini (grup 'light')."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		return

	for i in range(lights.size()):
		var light = lights[i]
		var row = row_scene.instantiate()
		add_child(row)
		row.setup(light, "Lumina " + str(i + 1))
