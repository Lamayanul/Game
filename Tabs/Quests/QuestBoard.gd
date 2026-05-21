extends GridContainer

# --- CONFIGURARE ---
@export var available_characters: Array[CharacterProfile] = [] 
@export var max_concurrent_quests: int = 5
@export var spawn_interval: float = 3.0

# --- DATE INTERNE ---
var items_db: Dictionary = {}
var quest_recipes: Array = []
var rng = RandomNumberGenerator.new()
var spawn_timer: Timer

func _ready():
	rng.randomize() # Se apelează O SINGURĂ DATĂ, nu în loop!
	_load_databases()
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_tick)
	add_child(spawn_timer)
	
	spawn_quest()

func _load_databases():
	# ... (codul tău de încărcare rămâne la fel) ...
	var file_items = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file_items: items_db = JSON.parse_string(file_items.get_as_text())
	
	var file_recipes = FileAccess.open("res://Autoload/quest_recipes.json", FileAccess.READ)
	if file_recipes: quest_recipes = JSON.parse_string(file_recipes.get_as_text())

func _on_spawn_timer_tick():
	if get_child_count() >= max_concurrent_quests: return
	# Variem puțin timpul
	spawn_timer.wait_time = rng.randf_range(spawn_interval * 0.8, spawn_interval * 1.5)
	spawn_quest()

func spawn_quest():
	if items_db.is_empty() or quest_recipes.is_empty() or available_characters.is_empty():
		return

	# 1. Alegem un CARACTER random
	var char_profile = available_characters.pick_random()
	var char_name = char_profile.display_name # Asigură-te că ai variabila asta în Resource

	# 2. Filtrăm REȚETELE disponibile pentru acest caracter
	var valid_recipes = []
	for r in quest_recipes:
		# Dacă nu are "givers" sau lista e goală, e pentru oricine
		if not r.has("givers") or r["givers"].is_empty():
			valid_recipes.append(r)
		# Dacă are "givers", verificăm dacă numele caracterului e în listă
		elif char_name in r["givers"]:
			valid_recipes.append(r)
	
	if valid_recipes.is_empty():
		print("Nu am găsit rețete pentru caracterul: ", char_name)
		return

	# 3. Alegem o rețetă validă
	var recipe = valid_recipes.pick_random()
	
	# ... (Calcul ID-uri și Cantități - Codul tău vechi) ...
	# FIX IMPORTANT: Folosim .duplicate() ca să nu modificăm originalul
	var req_id = str(int(recipe["req"]["item_id"]))
	var rew_id = str(int(recipe["reward"]["item_id"]))
	
	if not items_db.has(req_id) or not items_db.has(rew_id): return
	
	var req_item_def = items_db[req_id].duplicate(true) # <--- FIX BUG TIMER/DATE COMUNE
	var rew_item_def = items_db[rew_id].duplicate(true)

	# Calcul cantități (codul tău)
	var min_req = int(recipe["req"].get("min_amount", 1))
	var max_req = int(recipe["req"].get("max_amount", 1))
	var amount_req = rng.randi_range(min_req, max_req)
	
	var min_rew = int(recipe["reward"].get("min_amount", 1))
	var max_rew = int(recipe["reward"].get("max_amount", 1))
	var amount_rew = rng.randi_range(min_rew, max_rew)

	# Încărcare texturi
	var req_tex = _safe_load_texture(req_item_def.get("texture"))
	var rew_tex = _safe_load_texture(rew_item_def.get("texture"))

	# Creare Pachet Date (IMPORTANT: Datele pentru Input Slot trebuie să știe ce așteaptă)
	var quest_data = {
		"id": "q_" + str(rng.randi()),
		"title": recipe.get("title", "Misiune"),
		"giver_name": char_name,
		"giver_icon": char_profile.portrait,
		"description": recipe.get("description", "Ofertă"),
		
		# CE TREBUIE ADUS (Target)
		"req_target_id": int(req_id),     # ID-ul pe care îl verificăm la final
		"req_target_amount": amount_req,  # Cantitatea cerută
		"req_display_tex": req_tex,       # Doar pentru a arăta jucătorului ce vrem (iconiță vizuală)
		
		# RECOMPENSA (Ce primește)
		"reward": {
			"TEXTURE": rew_tex,
			"CANTITATE": amount_rew,
			"NUME": rew_item_def.get("nume", "Item"),
			"RARITATE": recipe.get("rarity", "comuna"),
			"NUMBER": int(rew_id)
		}
	}
	
	# Instanțiere
	if char_profile.quest_scene:
		var card = char_profile.quest_scene.instantiate()
		add_child(card)
		if card.has_method("setup_data"):
			card.setup_data(quest_data)

func _safe_load_texture(path_str):
	var full_path = "res://assets/" + str(path_str)
	if ResourceLoader.exists(full_path):
		return load(full_path)
	return null
