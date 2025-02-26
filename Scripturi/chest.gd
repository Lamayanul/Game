extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var player_in_area = false
var is_open = false  
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var inventory = get_node("/root/world/Inventar/Inv")

@onready var slot_container_4: Slot = $CanvasLayer/GridContainer/SlotContainer4
@onready var slot_container_3: Slot = $CanvasLayer/GridContainer/SlotContainer3
@onready var slot_container: Slot = $CanvasLayer/GridContainer/SlotContainer
@onready var slot_container_2: Slot = $CanvasLayer/GridContainer/SlotContainer2


func _ready():
	canvas_layer.hide()
	generate_items_chest()

func _on_area_2d_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_area_2d_body_exited(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		canvas_layer.hide()

func _process(_delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		if not is_open:  
			animation_player.play("open")
			is_open=true
			if is_open and player_in_area:
				canvas_layer.show()
		else:
			animation_player.play("close")
			is_open=false
			canvas_layer.hide()
	if player_in_area and is_open:
		canvas_layer.show()

func generate_items_chest():
	var file = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file == null:
		print("Nu s-a putut deschide fișierul JSON.")
		return
	var json_text = file.get_as_text()
	file.close()

	var json_data = JSON.parse_string(json_text)

	# Obține datele din JSON - accesează direct dicționarul principal
	var items_dict = json_data  # Modificăm aceasta pentru a lucra direct cu datele JSON

	# Verifică structura JSON-ului
	print("Structura JSON-ului:", items_dict)

	# Randomizează numărul de sloturi care primesc iteme
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var num_slots_to_fill = rng.randi_range(1, 4)  # De exemplu, între 1 și 4 sloturi

	# Lista sloturilor unde generăm iteme
	var slot_list = [slot_container, slot_container_2, slot_container_3, slot_container_4]
	slot_list.shuffle()  # Amestecă sloturile pentru aleatorizare

	# Adaugă iteme în sloturile selectate
	for i in range(num_slots_to_fill):
		var slot = slot_list[i]

		# Alege un item aleatoriu din JSON
		var random_index = rng.randi_range(1, items_dict.size() - 1)  # Sărim peste cheia "0"
		var item_data = items_dict[str(random_index)]

		# Verifică dacă itemul există
		if item_data == null:
			print("Itemul nu a fost găsit pentru indexul:", random_index)
			continue
		
		
		# Generează o cantitate aleatorie între 1 și 10 (sau alt interval dorit)
		var random_quantity = rng.randi_range(1, 10)
		
		if item_data["nume"] == "topor":  # De exemplu, pentru ou
			random_quantity = 1  # Setăm o cantitate specifică
			
		# Încarcă textura folosind load()
		var texture_path = "res://assets/" + item_data["texture"]
		var texture = load(texture_path)

		# Verifică dacă textura a fost încărcată cu succes
		if texture == null:
			print("Textura nu a fost găsită la calea:", texture_path)
			continue

		# Setează proprietățile itemului în slot
		slot.set_property({
			"TEXTURE": texture,
			"CANTITATE": random_quantity,
			"NUMBER": item_data["number"],
			"NUME": item_data["nume"]
		})

		print("Generat:", item_data["nume"], "Cantitate:", random_quantity, "în slot.")
