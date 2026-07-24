extends Control

@onready var texture_button = $TextureButton
@onready var label = $Label

@export var max_connections: int = 3
var current_connections: int = 0
var connections: Array[Control] = []
var active_lines: Dictionary = {} # target (Control) -> line (Line2D)

@onready var line_pool = [$Line1, $Line2, $Line3]

var skill_name: String = ""
var skill_texture_path: String = ""

# --- DRAG LOGIC ---
var dragging = false
var drag_offset = Vector2.ZERO

# --- STATIC FOR CONNECTION ---
static var source_node: Control = null
static var preview_line: Line2D = null

func setup(data: Dictionary):
	skill_name = data.get("name", "Unknown Skill")
	skill_texture_path = data.get("path", "")
	
	if skill_texture_path != "" and ResourceLoader.exists(skill_texture_path):
		var tex = load(skill_texture_path)
		if texture_button:
			texture_button.texture_normal = tex

func _ready():
	if skill_name != "":
		tooltip_text = skill_name
	
	# Ascundem liniile inițial
	for line in line_pool:
		line.clear_points()
		line.visible = false
	
	update_label()
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	if texture_button:
		texture_button.mouse_filter = Control.MOUSE_FILTER_PASS

func update_label():
	if label:
		label.text = str(current_connections) + "/" + str(max_connections)

# --- PUBLIC API PENTRU TĂIEREA LEGĂTURILOR ---

func get_active_lines_map() -> Dictionary:
	return active_lines

func break_connection(target: Control):
	if target in connections:
		# 1. Ștergem logica locală
		var line = active_lines.get(target)
		if is_instance_valid(line):
			line.clear_points()
			line.visible = false
		
		active_lines.erase(target)
		connections.erase(target)
		current_connections -= 1
		update_label()
		
		# 2. Notificăm și ținta să se deconecteze (fără a declanșa o buclă infinită)
		if target.has_method("remove_connection_logic_only"):
			target.remove_connection_logic_only(self)
		
		print("[SkillIcon] Legătură tăiată de la ", skill_name, " către ", target.skill_name)

func remove_connection_logic_only(other: Control):
	if other in connections:
		# Dacă noi eram "proprietarul" vizual al liniei către acest 'other'
		if active_lines.has(other):
			var line = active_lines[other]
			line.clear_points()
			line.visible = false
			active_lines.erase(other)
			
		connections.erase(other)
		current_connections -= 1
		update_label()

func _process(_delta):
	# Update permanent lines
	for target in connections:
		if is_instance_valid(target) and active_lines.has(target):
			var line = active_lines[target]
			if is_instance_valid(line):
				# Punctul de start local (SUS mijloc):
				var start = Vector2(size.x / 2, 0)
				
				# Calculăm punctul de sfârșit (SUS mijloc al țintei) convertit în spațiul local al acestui nod
				var target_local_point = Vector2(target.size.x / 2, 0)
				var target_global_point = target.get_global_transform() * target_local_point
				var end = get_global_transform().affine_inverse() * target_global_point
				
				_update_curved_line(line, start, end)
	
	# Update preview line
	if source_node == self and is_instance_valid(preview_line):
		var start = Vector2(size.x / 2, 0)
		var end = get_local_mouse_position()
		_update_curved_line(preview_line, start, end)

func _update_curved_line(line: Line2D, start: Vector2, end: Vector2):
	line.clear_points()
	var distance = start.distance_to(end)
	if distance < 1: return
	
	# Calculăm punctul de control pentru bolta (Bezier pătratic)
	var mid = (start + end) / 2.0
	var height = distance * 0.4 
	# Bolta IN JOS = +height (în Godot Y crește în jos)
	var control = mid + Vector2(0, height)
	
	# Generăm punctele curbei
	var segments = 20
	for i in range(segments + 1):
		var t = i / float(segments)
		var q0 = start.lerp(control, t)
		var q1 = control.lerp(end, t)
		var pos = q0.lerp(q1, t)
		line.add_point(pos)

func _gui_input(event):
	if event is InputEventMouseButton:
		# MOVE - Left Click
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_local_mouse_position()
				get_parent().move_child(self, -1)
				accept_event()
			else:
				dragging = false
		
		# CONNECT - Right Click
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_connection()
			accept_event()
	
	if event is InputEventMouseMotion and dragging:
		position += get_local_mouse_position() - drag_offset
		accept_event()

func _handle_connection():
	# VERIFICARE LIMITĂ ÎNAINTE DE ORICE
	if current_connections >= max_connections and source_node == null:
		print("[SkillIcon] LIMITĂ ATINSĂ pentru: ", skill_name)
		return

	if source_node == null:
		# Pas 1: Selectăm primul skill (Sursa)
		source_node = self
		# Găsim prima linie liberă vizuală în pool
		preview_line = null
		for l in line_pool:
			# Verificăm dacă linia nu este deja folosită într-o conexiune activă
			var is_in_use = false
			for active_l in active_lines.values():
				if active_l == l:
					is_in_use = true
					break
			
			if not is_in_use:
				preview_line = l
				break
		
		if preview_line:
			preview_line.visible = true
			print("[SkillIcon] Start conexiune de la: ", skill_name)
		else:
			print("[SkillIcon] Eroare: Nu mai sunt linii vizuale disponibile!")
			source_node = null
			
	elif source_node == self:
		# Pas 2: Click pe același skill = Anulare
		_cleanup_preview(true)
	else:
		# Pas 3: Încercăm conectarea la al doilea skill (Ținta)
		# Verificăm din nou ambele limite
		if current_connections < max_connections and source_node.current_connections < source_node.max_connections:
			if not source_node in connections:
				# Conexiune validă!
				var line_to_pass = preview_line # Salvăm referința liniei de preview
				source_node._add_connection(self, line_to_pass) # Sursa păstrează linia vizuală
				self._add_connection(source_node, null) # Ținta doar se notează logic
				_cleanup_preview(false) # NU ascundem linia
				return
			else:
				print("[SkillIcon] Deja conectat la: ", source_node.skill_name)
		else:
			print("[SkillIcon] Conexiune eșuată: Unul dintre skill-uri a atins limita de ", max_connections)
		
		# Dacă eșuează, curățăm tot
		_cleanup_preview(true)

func _add_connection(target: Control, visual_line: Line2D):
	if target == null or target == self or target in connections or current_connections >= max_connections:
		return
	
	connections.append(target)
	
	if visual_line:
		active_lines[target] = visual_line
		visual_line.visible = true
		
		# Update imediat al punctelor liniei pentru a evita "saltul" vizual în frame-ul următor
		var start = Vector2(size.x / 2, 0)
		var target_local_point = Vector2(target.size.x / 2, 0)
		var target_global_point = target.get_global_transform() * target_local_point
		var end = get_global_transform().affine_inverse() * target_global_point
		_update_curved_line(visual_line, start, end)
	
	current_connections += 1
	update_label()
	print("[SkillIcon] ", skill_name, " conectat la ", target.skill_name, " (", current_connections, "/", max_connections, ")")

func _cleanup_preview(should_hide_visual: bool):
	if is_instance_valid(preview_line) and should_hide_visual:
		# Verificăm dacă linia chiar nu este una activă permanentă
		var is_active = false
		if is_instance_valid(source_node):
			for active_l in source_node.active_lines.values():
				if active_l == preview_line:
					is_active = true
					break
		
		if not is_active:
			preview_line.clear_points()
			preview_line.visible = false
	
	source_node = null
	preview_line = null
