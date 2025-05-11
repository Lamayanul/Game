extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var player_in_area = false
var is_open = false  # Stare pentru a verifica dacă ușa este deschisă
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")

@onready var slot_container_4: Slot = $CanvasLayer/GridContainer/SlotContainer4
@onready var slot_container_3: Slot = $CanvasLayer/GridContainer/SlotContainer3
@onready var slot_container: Slot = $CanvasLayer/GridContainer/SlotContainer
@onready var slot_container_2: Slot = $CanvasLayer/GridContainer/SlotContainer2

#func _input(event):
	#if event is InputEventMouseButton and player_in_area == true:
		#if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			#if selected_slot.get_item() != null:
				## Obține detaliile itemului din slotul selectat
				#var item_data = selected_slot.get_item()
#
				## Încearcă să transferi itemul în slotul 6
				#if transfer_item_to_slot(item_data, slot_container_6):
					## Dacă transferul este reușit, curăță itemul din slotul selectat
					#selected_slot.clear_item()
					#plin -= 1
					#print("Item transferat cu succes în slotul de crafting 6.")
#
				## Dacă transferul în slotul 6 a eșuat, încearcă în slotul 7
				#elif transfer_item_to_slot(item_data, slot_container_7):
					## Dacă transferul este reușit, curăță itemul din slotul selectat
					#selected_slot.clear_item()
					#plin -= 1
					#print("Item transferat cu succes în slotul de crafting 7.")
#
				## Dacă niciun slot nu este disponibil, afișează un mesaj
				#else:
					#print("Ambele sloturi de crafting sunt deja pline. Nu mai există locuri libere.")
			#else:
				#print("Nu este niciun item selectat pentru transfer.")

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

func _input(_event):
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
	# Încarcă JSON-ul dintr-un fișier
	var file = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file == null:
		print("Nu s-a putut deschide fișierul JSON.")
		return

	# Parseaază JSON-ul
	var json_text = file.get_as_text()
	file.close()

	var json_data = JSON.parse_string(json_text)

	# Verifică dacă parsing-ul a avut succes


	# Obține datele din JSON - accesează direct dicționarul principal
	var items_dict = json_data  # Modificăm aceasta pentru a lucra direct cu datele JSON

	# Verifică structura JSON-ului
	#print("Structura JSON-ului:", items_dict)

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
		if item_data["nume"] == "axe":  # De exemplu, pentru ou
			random_quantity = 1
		if item_data["nume"] == "backpack":  # De exemplu, pentru ou
			random_quantity = 1
		if item_data["nume"] == "Buzduganul norocului":  # De exemplu, pentru ou
			random_quantity = 1
		if item_data["nume"] == "hoe":  # De exemplu, pentru ou
			random_quantity = 1
		if item_data["nume"] == "pickaxe":  # De exemplu, pentru ou
			random_quantity = 1
		if item_data["nume"] == "scut":  # De exemplu, pentru ou
			random_quantity = 1
		if item_data["nume"] == "stropitoare":  # De exemplu, pentru ou
			random_quantity = 1
		
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

		#print("Generat:", item_data["nume"], "Cantitate:", random_quantity, "în slot.")
		
#func _input(event: InputEvent) -> void:
	## Verifică dacă evenimentul este un click dreapta
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		#print("intra in click")
		#
		## Lista celor 4 sloturi
		#var slot_list = [slot_container, slot_container_2, slot_container_3, slot_container_4]
		#
		## Iterează prin fiecare slot
		#for slot in slot_list:
			#if slot.get_cantitate() > 0:  # Verifică dacă slotul conține iteme
				#var item_id = str(slot.get_number())  # ID-ul itemului
				#var item_cantitate = slot.get_cantitate()  # Cantitatea itemului
				#
				## Adaugă itemul în inventar
				#inventory.add_item(item_id, item_cantitate)
				#
				## Golește slotul după transfer
				#slot.clear_item()
				#print("Itemul a fost transferat în inventar din slot:", slot.name, "ID:", item_id, "Cantitate:", item_cantitate)
			#else:
				#print("Slotul", slot.name, "este gol.")
