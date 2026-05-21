extends GridContainer

# Cât de des se întâmplă o schimbare (secunde)
@export var tick_speed: float = 0.1 

# Șansa ca o modificare să fie SCĂDERE
@export var depletion_chance: float = 0.6 

# --- MODIFICARE 1: Vectorul de iteme permise ---
# Aici vei pune ID-urile itemelor (ex: "1", "3", "apple") din Inspector.
# Dacă lista e goală, va alege din TOATE itemele.
@onready var allowed_item_ids: Array[String] = ["1","2","3","4","5","6","7","8","9"] 
# -----------------------------------------------

# Baza de date
var items_db: Dictionary = {}
var rng = RandomNumberGenerator.new()
var timer: Timer

func _ready():
	rng.randomize()
	
	var file := FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file != null:
		items_db = JSON.parse_string(file.get_as_text())
		file.close()
	
	timer = Timer.new()
	timer.wait_time = tick_speed
	timer.one_shot = false
	timer.timeout.connect(_on_market_tick)
	add_child(timer)
	timer.start()

func _on_market_tick():
	timer.wait_time = rng.randf_range(0.05, 0.5)
	var changes_count = rng.randi_range(1, 3)
	
	for i in range(changes_count):
		_process_random_change()

func _process_random_change():
	var valid_slots: Array = []
	for child in get_children():
		if child is Slot:
			valid_slots.append(child)
	
	if valid_slots.is_empty(): return
	
	var slot = valid_slots[rng.randi() % valid_slots.size()]
	
	# --- LOGICA DE MODIFICARE ---
	if slot.cantitate > 0:
		# SCĂDERE SAU CREȘTERE (Logica existentă)
		if rng.randf() < depletion_chance:
			# Scădere
			var current_qty = slot.cantitate
			var drop_amount = 0
			var panic_roll = rng.randf()
			
			if panic_roll < 0.6: drop_amount = 1 
			elif panic_roll < 0.9: drop_amount = rng.randi_range(2, 10) 
			else: drop_amount = current_qty 
			
			var new_qty = current_qty - drop_amount
			
			if new_qty <= 0:
				slot.clear_item()
				slot.show_trend(false) 
			else:
				slot.cantitate = new_qty
				if slot.property: slot.property["CANTITATE"] = new_qty
				slot.show_trend(false) 
		else:
			# Creștere
			var add_amount = rng.randi_range(1, 5)
			slot.cantitate += add_amount
			if slot.property: slot.property["CANTITATE"] = slot.cantitate
			slot.show_trend(true) 

	else:
		# APARIȚIE (Spawn)
		if rng.randf() < 0.3:
			_spawn_new_item(slot)

func _spawn_new_item(slot: Slot):
	if items_db.is_empty(): return
	
	var random_key = ""
	
	# --- MODIFICARE 2: Alegem din Vectorul tău (dacă există) ---
	if not allowed_item_ids.is_empty():
		# Alegem un ID random din lista ta specifică
		random_key = allowed_item_ids[rng.randi() % allowed_item_ids.size()]
		
		# Verificăm dacă ID-ul pe care l-ai scris greșit există în DB
		if not items_db.has(random_key):
			print("⚠️ Eroare: ID-ul '%s' din Allowed Item Ids nu există în JSON!" % random_key)
			return
	else:
		# Dacă vectorul e gol, alegem orice item din toată baza de date
		var keys = items_db.keys()
		random_key = keys[rng.randi() % keys.size()]
	# -----------------------------------------------------------

	var item_data = items_db[random_key]
	
	var texture_filename = str(item_data.get("texture", ""))
	if texture_filename == "" or texture_filename == "null": return 

	var tex_path = "res://assets/" + texture_filename
	if not ResourceLoader.exists(tex_path): return

	var tex = load(tex_path)
	if tex == null: return
	
	var start_qty = rng.randi_range(10, 100)
	
	var prop = {
		"TEXTURE": tex,
		"CANTITATE": start_qty,
		"NUMBER": int(item_data.get("number", 0)),
		"NUME": str(item_data.get("nume", "")),
		"RARITATE": str(item_data.get("raritate", "comuna")),
		"EFFECTS": item_data.get("effects", []),
		"CURSE": item_data.get("curse", null),
		"TYPE": item_data.get("type", [])
	}
	
	slot.set_property(prop)
	slot.show_trend(true)
