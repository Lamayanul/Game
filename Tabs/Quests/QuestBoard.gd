extends GridContainer

# --- CONFIGURARE ---
@export var available_characters: Array[CharacterProfile] = [] 
@export var max_concurrent_quests: int = 5
@export var spawn_interval: float = 3.0

var quest_icon_scene = preload("res://Tabs/Quests/QuestIcon.tscn")

# --- DATE INTERNE ---
var items_db: Dictionary = {}
var quest_recipes: Array = []
var necromancer_skills: Array = []
var rng = RandomNumberGenerator.new()
var spawn_timer: Timer

func _ready():
	rng.randomize() 
	_load_databases()
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_tick)
	add_child(spawn_timer)
	
	spawn_quest()
	# Spawnăm itemele statice la început
	#_spawn_static_map_items()
	_spawn_necromancer_skills()

func _spawn_static_map_items():
	if items_db.is_empty(): return
	
	var board = _find_board()
	if not board: return
	
	print("[QuestBoard] Spawning static QuestIcons on map...")
	var item_ids = items_db.keys()
	var spawn_range = 3500.0 
	var total_items = 100 # Reducem puțin numărul fiindcă QuestIcon e mai "greu" decât un Sprite simplu
	
	for i in range(total_items):
		var random_id = item_ids.pick_random()
		var item_data = items_db[random_id]
		var tex_path = item_data.get("texture")
		
		if tex_path:
			var tex = _safe_load_texture(tex_path)
			if tex:
				var icon = quest_icon_scene.instantiate()
				icon.is_static = true # ESENȚIAL: nu se va mișca
				
				# Setup minimal pentru a afișa textura item-ului
				var fake_data = {
					"giver_icon": tex,
					"offer_lifetime": 99999.0 # Să nu expire niciodată
				}
				
				board.add_child(icon)
				if icon.has_method("setup"):
					icon.setup(fake_data, null) # setup va seta scale (1,1) pt static
				
				# Poziție random
				var rx = rng.randf_range(-spawn_range, spawn_range)
				var ry = rng.randf_range(-spawn_range, spawn_range)
				icon.position = Vector2(rx, ry)
				
				# Le trimitem în spate
				board.move_child(icon, 0)

func _spawn_necromancer_skills():
	if necromancer_skills.is_empty(): return
	
	var board = _find_board()
	if not board: return
	
	print("[QuestBoard] Spawning Necromancer skills on map (Grid, no overlap)...")
	var skill_icon_scene = preload("res://Scene/skill_icon.tscn")
	
	# Parametri Grid
	var cols = 5
	var spacing = 100.0
	var start_x = -((cols - 1) * spacing) / 2.0
	var start_y = -300.0 # Poziționate puțin mai sus de centru
	
	for i in range(necromancer_skills.size()):
		var skill_data = necromancer_skills[i]
		var icon = skill_icon_scene.instantiate()
		board.add_child(icon)
		
		if icon.has_method("setup"):
			icon.setup(skill_data)
		
		# Calculăm poziția în grid
		var row = i / cols
		var col = i % cols
		
		var px = start_x + (col * spacing)
		var py = start_y + (row * spacing)
		
		# Adăugăm un mic jitter (variație random) ca să nu fie perfect drepte, dar fără overlap
		var jitter = 15.0
		icon.position = Vector2(px + rng.randf_range(-jitter, jitter), py + rng.randf_range(-jitter, jitter))


func _load_databases():
	# ... (codul tău de încărcare rămâne la fel) ...
	var file_items = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file_items: items_db = JSON.parse_string(file_items.get_as_text())
	
	var file_recipes = FileAccess.open("res://Autoload/quest_recipes.json", FileAccess.READ)
	if file_recipes: quest_recipes = JSON.parse_string(file_recipes.get_as_text())
	
	var file_necro = FileAccess.open("res://Autoload/necromancer_skills.json", FileAccess.READ)
	if file_necro:
		var data = JSON.parse_string(file_necro.get_as_text())
		if data and data.has("skills"):
			necromancer_skills = data["skills"]

func _on_spawn_timer_tick():
	var board = _find_board()
	if board and board.get_child_count() >= max_concurrent_quests: 
		return
	
	print("[QuestBoard] Încercare spawn quest...")
	# Variem puțin timpul
	spawn_timer.wait_time = rng.randf_range(spawn_interval * 0.8, spawn_interval * 1.5)
	spawn_quest()

func _find_board() -> Node:
	# Căutăm nodul "board" în ierarhie
	var p = get_parent()
	while p != null:
		if p.has_node("BoardViewport/board"):
			return p.get_node("BoardViewport/board")
		if p.has_node("board"):
			return p.get_node("board")
		p = p.get_parent()
	return null

func spawn_quest():
	if items_db.is_empty() or quest_recipes.is_empty() or available_characters.is_empty():
		print("[QuestBoard] Date lipsă!")
		return

	# 1. Alegem un CARACTER random
	var char_profile = available_characters.pick_random()
	var char_name = char_profile.display_name

	# 2. Filtrăm REȚETELE
	var valid_recipes = []
	for r in quest_recipes:
		if not r.has("givers") or r["givers"].is_empty() or char_name in r["givers"]:
			valid_recipes.append(r)
	
	if valid_recipes.is_empty(): return

	# 3. Alegem o rețetă validă
	var recipe = valid_recipes.pick_random()
	
	var req_id = str(int(recipe["req"]["item_id"]))
	var rew_id = str(int(recipe["reward"]["item_id"]))
	
	if not items_db.has(req_id) or not items_db.has(rew_id): return
	
	var req_item_def = items_db[req_id].duplicate(true)
	var rew_item_def = items_db[rew_id].duplicate(true)

	var amount_req = rng.randi_range(int(recipe["req"].get("min_amount", 1)), int(recipe["req"].get("max_amount", 1)))
	var amount_rew = rng.randi_range(int(recipe["reward"].get("min_amount", 1)), int(recipe["reward"].get("max_amount", 1)))

	var req_tex = _safe_load_texture(req_item_def.get("texture"))
	var rew_tex = _safe_load_texture(rew_item_def.get("texture"))

	var quest_data = {
		"id": "q_" + str(rng.randi()),
		"title": recipe.get("title", "Misiune"),
		"giver_name": char_name,
		"giver_icon": char_profile.portrait,
		"description": recipe.get("description", "Ofertă"),
		"req_item_id": int(req_id),
		"req_amount": amount_req,
		"req_display_tex": req_tex,
		"reward": {
			"TEXTURE": rew_tex,
			"CANTITATE": amount_rew,
			"NUME": rew_item_def.get("nume", "Item"),
			"RARITARTE": recipe.get("rarity", "comuna"),
			"NUMBER": int(rew_id)
		}
	}
	
	# Instanțiere Iconiță
	var board = _find_board()
	if board and char_profile.quest_scene:
		var icon = quest_icon_scene.instantiate()
		
		# --- SPAWN RANDOM PE TOT BOARD-UL ---
		# Setăm poziția ÎNAINTE de a adăuga pe board sau de a apela setup()
		var spawn_range = 2000.0 
		var rx = rng.randf_range(-spawn_range, spawn_range)
		var ry = rng.randf_range(-spawn_range, spawn_range)
		icon.position = Vector2(rx, ry)
		
		board.add_child(icon)
		
		if icon.has_method("setup"):
			icon.setup(quest_data, char_profile.quest_scene)
		
		print("[QuestBoard] Icon spawnat la: ", icon.position, " (Locație random pe board infinit)")
	else:
		print("[QuestBoard] Nu am găsit board-ul sau scena de quest!")

func _safe_load_texture(path_str):
	var full_path = "res://assets/" + str(path_str)
	if ResourceLoader.exists(full_path):
		return load(full_path)
	return null
