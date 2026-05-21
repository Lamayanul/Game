extends Control

# --- CONFIGURARE ---
@export var slot_scene: PackedScene 
@export var total_items: int = 60   
@export var winner_index: int = 45  
@export var spin_time: float = 6.0  

# --- LISTA CU ITEME POSIBILE (LOOT TABLE) ---
@export var reward_pool_ids: Array[int] = [1,2,3,4,5,6,7,8,9,10] 

# --- REFERINȚE ---
@onready var moving_strip = $WindowMask/MovingStrip
@onready var spin_button = $SpinButton
@onready var window_mask = $WindowMask
@onready var reward_label = get_node_or_null("RewardLabel")

# --- DATE INTERNE ---
var rng = RandomNumberGenerator.new()
var items_db: Dictionary = {}
var real_slot_width: float = 0.0
var current_winner_data: Dictionary = {} 

func _ready():
	rng.randomize()
	spin_button.pressed.connect(_on_spin_pressed)
	_load_database()
	moving_strip.add_theme_constant_override("separation", 5) 

func _load_database():
	var file = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file:
		items_db = JSON.parse_string(file.get_as_text())
		file.close()

func _on_spin_pressed():
	if items_db.is_empty():
		print("Baza de date e goală!")
		return
	
	if reward_pool_ids.is_empty():
		print("EROARE: Lista de premii e goală!")
		return

	# --- MODIFICARE 1: FILTRĂM ID-ul 0 ---
	# Creăm o listă temporară doar cu ID-uri valide (diferite de 0)
	var valid_pool = []
	for id in reward_pool_ids:
		if id != 0:
			valid_pool.append(id)
	
	if valid_pool.is_empty():
		print("EROARE: Toate ID-urile din listă sunt 0 sau lista e goală!")
		return
		
	spin_button.disabled = true
	
	# Alegem un ID random DOAR din lista validă
	var chosen_id = valid_pool.pick_random()
	
	# Căutăm datele acelui ID
	var winner_data = _get_item_by_id(str(chosen_id))
	
	if winner_data.is_empty():
		print("EROARE: ID-ul ", chosen_id, " nu există în Database.json!")
		spin_button.disabled = false
		return
		
	current_winner_data = winner_data
	
	# Continuăm logica
	setup_roulette(winner_data)
	await get_tree().process_frame
	animate_spin()

func setup_roulette(winner_data: Dictionary):
	for child in moving_strip.get_children(): child.queue_free()
	moving_strip.position.x = 0
	
	for i in range(total_items):
		var slot = slot_scene.instantiate()
		
		moving_strip.add_child(slot)
		
		if "slot_type" in slot: slot.slot_type = "display_only"
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if i == winner_index:
			# CÂȘTIGĂTORUL
			slot.set_property(winner_data)
			# --- MODIFICARE 2: AM SCOS HIGHLIGHT-UL DE AICI ---
			# (slot.modulate nu se mai setează acum)
		else:
			# FILLER
			slot.set_property(_get_random_item_from_db()) 

func animate_spin():
	var first_slot = moving_strip.get_child(0)
	var separation = moving_strip.get_theme_constant("separation")
	real_slot_width = first_slot.size.x + separation
	
	var move_to_winner = -(winner_index * real_slot_width)
	var center_screen = window_mask.size.x / 2.0
	var center_slot = first_slot.size.x / 2.0
	var safe_margin = first_slot.size.x * 0.4 
	var random_offset = rng.randf_range(-safe_margin, safe_margin)
	
	var final_target_x = move_to_winner + center_screen - center_slot + random_offset
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(moving_strip, "position:x", final_target_x, spin_time)
	tween.tween_callback(_on_spin_finished)

func _on_spin_finished():
	spin_button.disabled = false
	print("Ai câștigat: ", current_winner_data["NUME"])
	
	if reward_label:
		reward_label.text = "Ai primit: " + str(current_winner_data["NUME"])
	
	# --- MODIFICARE 3: HIGHLIGHT DOAR LA FINAL ---
	# Găsim slotul câștigător folosind indexul cunoscut
	var winner_slot = moving_strip.get_child(winner_index)
	
	if winner_slot:
		# Facem un efect de pulsare / strălucire
		var glow_tween = create_tween()
		glow_tween.tween_property(winner_slot, "modulate", Color(1.5, 1.5, 1.5), 0.5) # Strălucește
		glow_tween.tween_property(winner_slot, "modulate", Color(1.0, 1.0, 1.0), 0.5) # Revine la normal (opțional)
		
	# Adăugare în inventar
	var inv = get_node_or_null("/root/world/CanvasLayer/Inv")
	if inv and inv.has_method("add_item"):
		inv.add_item(str(current_winner_data["NUMBER"]), 1)

func _get_item_by_id(target_id: String) -> Dictionary:
	if not items_db.has(target_id):
		return {}
		
	var data = items_db[target_id]
	var tex_name = str(data.get("texture", ""))
	var full_path = "res://assets/" + tex_name
	var final_tex = null
	if tex_name != "" and ResourceLoader.exists(full_path):
		final_tex = load(full_path)
	
	return {
		"TEXTURE": final_tex,
		"CANTITATE": 1,
		"NUME": data.get("nume", "Item"),
		"RARITATE": data.get("raritate", "comuna"),
		"NUMBER": int(data.get("number", 0))
	}

# Funcție pentru iteme de umplutură (random din TOATĂ baza, FĂRĂ 0)
func _get_random_item_from_db() -> Dictionary:
	if items_db.is_empty(): return {}
	
	# Obținem toate cheile
	var keys = items_db.keys()
	
	# --- MODIFICARE 4: Ștergem "0" din lista de posibilități ---
	if keys.has("0"):
		keys.erase("0")
		
	if keys.is_empty(): return {}
	
	var rand_key = keys.pick_random()
	return _get_item_by_id(rand_key)
