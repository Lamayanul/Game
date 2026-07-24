extends TextureButton

var quest_data: Dictionary
var quest_scene: PackedScene
var offer_lifetime: float = 60.0
var current_offer_time: float = 0.0
var is_accepted: bool = false
var is_static: bool = false # Dacă e TRUE, nu se mișcă și nu are fizică
var opened_card: Control = null

func setup(data: Dictionary, scene: PackedScene):
	quest_data = data
	quest_scene = scene
	
	# Preluăm timpul de ofertă din date sau folosim default
	offer_lifetime = data.get("offer_lifetime", 60.0)
	current_offer_time = offer_lifetime
	
	var final_tex = null
	
	# 1. Încercăm să extragem textura din cardul de quest
	if scene:
		var temp_card = scene.instantiate()
		# Căutăm nodul Sprite2D (sau fallback la GiverIcon)
		var quest_sprite = temp_card.find_child("Sprite2D", true, false)
		if not quest_sprite:
			quest_sprite = temp_card.find_child("GiverIcon", true, false)
			
		if quest_sprite and "texture" in quest_sprite:
			final_tex = quest_sprite.texture
		
		temp_card.queue_free()
	
	# 2. Dacă nu am găsit în card, folosim giver_icon din date
	if final_tex == null and data.has("giver_icon"):
		final_tex = data["giver_icon"]
		
	# 3. Aplicăm textura găsită
	if final_tex:
		var internal_sprite = get_node_or_null("Sprite2D")
		var highlight_sprite = get_node_or_null("Highlight")
		
		# Calculăm scala: 64x64 doar pentru cele statice, restul la dimensiunea lor (1,1)
		var required_scale = Vector2(1, 1)
		if is_static:
			var tex_size = final_tex.get_size()
			var target_size = 64.0
			required_scale = Vector2(target_size / tex_size.x, target_size / tex_size.y)
		
		if highlight_sprite:
			highlight_sprite.texture = final_tex
			highlight_sprite.position = Vector2(32, 32)
			highlight_sprite.scale = required_scale
			
		if internal_sprite:
			# Punem imaginea pe Sprite2D-ul copil
			internal_sprite.texture = final_tex
			internal_sprite.position = Vector2(32, 32)
			internal_sprite.scale = required_scale
			internal_sprite.visible = true
			
			# Facem butonul transparent ca să nu acopere Sprite2D-ul
			texture_normal = null 
			print("[QuestIcon] Textura aplicata. Scale: ", required_scale, " (static: ", is_static, ")")
		else:
			# Dacă nu există Sprite2D intern, punem direct pe buton
			texture_normal = final_tex
			if is_static:
				custom_minimum_size = Vector2(64, 64)
				size = Vector2(64, 64)
			print("[QuestIcon] Textura aplicata direct pe TextureButton.")
	else:
		print("[QuestIcon] ATENTIE: Nu am gasit nicio textura valida pentru quest!")
	
	# Începem animația de spawn doar dacă NU este static
	if not is_static:
		play_spawn_animation()
	else:
		scale = Vector2(1, 1)
		#modulate.a = 0.5 # Transparență de fundal pentru cele statice

		# Cerințe specifice pentru iconițe statice:
		# 1. Ascundem Highlight-ul galben
		var highlight = get_node_or_null("Highlight")
		if highlight: highlight.visible = false

		# 2. Repoziționăm Sprite2D2 (acul/pin-ul) mai jos
		var pin = get_node_or_null("Sprite2D2")
		if pin:
			pin.position.y = 10.0 # Coborâm pin-ul (original era -19)

func play_spawn_animation():

	# Starea inițială: mai mare, invizibil și puțin mai sus
		scale = Vector2(2.5, 2.5)
		modulate.a = 0
		var target_pos = position
		position.y -= 100
		
		var tween = create_tween().set_parallel(true)
		
		# Cădere și Fade-in
		tween.tween_property(self, "position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "modulate:a", 1.0, 0.3)
		
		# Când termină căderea, adăugăm un efect de impact
		tween.chain().set_parallel(false)
		tween.tween_callback(_on_drop_impact)
		
		# Mic efect de "squash and stretch" la impact
		tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_drop_impact():
	var particles = get_node_or_null("ImpactParticles")
	if particles:
		particles.emitting = true
	
	# Poți adăuga și un mic screen shake sau sunet aici dacă dorești

func _ready():
	# Adăugăm efect de hover pentru interactivitate
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Inițializăm un drift random
	drift_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	drift_timer = randf_range(2.0, 5.0)
	floating_offset = randf() * PI * 2

func _on_mouse_entered():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD)
	set_highlight(true)

func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD)
	if not is_instance_valid(opened_card):
		set_highlight(false)

var dragging := false
var was_dragged := false
var drag_offset := Vector2.ZERO
var drag_start_mouse_pos := Vector2.ZERO
var drag_threshold := 10.0 # Creștem puțin pragul pentru siguranță
var drag_margin := 40.0   
var drag_margin_top := 100.0 

# --- PHYSICS & MOVEMENT ---
var velocity := Vector2.ZERO
var friction := 0.97        # Mai alunecos (aproape de 1.0 = alunecă mult)
var floating_offset := 0.0  
var repulsion_force := 250.0 # Împingere mai puternică
var repulsion_radius := 100.0 

# --- AUTONOMOUS DRIFT ---
var drift_direction := Vector2.ZERO
var drift_timer := 0.0
var drift_speed := 50.0 # Viteza de deplasare autonomă

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# DETECTĂM DUBLU CLICK PENTRU DESCHIDERE
			if event.double_click:
				print("[QuestIcon] DUBLU CLICK DETECTAT")
				dragging = false
				_on_actual_click()
				return
				
			move_to_front()
			dragging = true
			was_dragged = false
			drag_offset = get_local_mouse_position()
			drag_start_mouse_pos = get_global_mouse_position()
			# Oprim viteza când o prindem
			velocity = Vector2.ZERO
		else:
			dragging = false
	
	if event is InputEventMouseMotion and dragging:
		if get_global_mouse_position().distance_to(drag_start_mouse_pos) > drag_threshold:
			was_dragged = true

func _process(delta):
	if is_static: return # NU facem nimic dacă e static

	# --- VERIFICARE COLIZIUNE CU LINIILE DE SKILL ---
	if velocity.length() > 5.0 or dragging:
		_check_line_collisions()

	if not is_accepted:
		current_offer_time -= delta
		
		# Sincronizăm timpul cu cardul dacă acesta este deschis
		if is_instance_valid(opened_card) and opened_card.has_method("update_offer_time"):
			opened_card.update_offer_time(current_offer_time, offer_lifetime)
		
		if current_offer_time <= 0:
			if is_instance_valid(opened_card):
				opened_card.queue_free()
			queue_free()
			return

	if dragging:
		var board = get_parent()
		if not board: return

		var target_pos = board.get_local_mouse_position() - drag_offset
		# Calculăm viteza mai agresiv pentru aruncări rapide
		velocity = (target_pos - position) / (delta * 5.0) 
		position = target_pos
	else:
		# 1. MIȘCARE AUTONOMĂ (Drift/Wander)
		_update_autonomous_movement(delta)
		
		# 2. Aplicăm Inerția
		position += velocity * delta
		velocity *= friction
		
		# 3. Aplicăm Repulsia
		_apply_repulsion(delta)
		
		# 4. Efect de plutire (mic bobbing vizual)
		floating_offset += delta * 2.0
		var bobbing = sin(floating_offset) * 0.1
		var s1 = get_node_or_null("Sprite2D")
		var s2 = get_node_or_null("Sprite2D2")
		if s1: s1.position.y = 32 + (bobbing * 15.0)
		if s2: s2.position.y = -19 + (bobbing * 10.0)
		
		# 5. Balăngănit (Wobble & Sway)
		var speed = velocity.length()
		if speed > 10.0:
			# Se înclină în direcția mersului (Sway)
			var target_tilt = clamp(velocity.x * 0.003, -0.3, 0.3)
			# Adăugăm un balăngănit sinusoidal proportional cu viteza (Wobble)
			var wobble = sin(floating_offset * 5.0) * (speed * 0.0008)
			rotation = lerp(rotation, target_tilt + wobble, delta * 8.0)
		else:
			rotation = lerp(rotation, 0.0, delta * 4.0)

func _update_autonomous_movement(delta: float):
	drift_timer -= delta
	if drift_timer <= 0:
		# Schimbăm direcția de deplasare random la fiecare câteva secunde
		var random_angle = randf_range(0, PI * 2)
		drift_direction = Vector2.from_angle(random_angle)
		drift_timer = randf_range(3.0, 7.0)
	
	# Aplicăm forța de drift la velocity (o facem lină)
	velocity = velocity.lerp(drift_direction * drift_speed, delta * 0.5)

func _apply_repulsion(delta: float):
	var board = get_parent()
	if not board: return
	
	for other in board.get_children():
		if other == self or not (other is TextureButton): continue
		
		var dist = position.distance_to(other.position)
		if dist < repulsion_radius and dist > 0.1:
			# Direcția de împingere
			var push_dir = (position - other.position).normalized()
			# Forța este mai mare cu cât sunt mai aproape
			var force_mult = (repulsion_radius - dist) / repulsion_radius
			velocity += push_dir * repulsion_force * force_mult * delta

# --- LOGICA DE TĂIERE A LEGĂTURILOR ---

func _check_line_collisions():
	var board = get_parent()
	if not board: return
	
	# Centrul iconiței noastre în coordonate globale
	var my_center_global = global_position + (size * scale / 2.0)
	var threshold = 30.0 # Distanța de la care "taie" linia
	
	for child in board.get_children():
		# Verificăm dacă obiectul este un SkillIcon (are metoda de mapare a liniilor)
		if child.has_method("get_active_lines_map"):
			var lines_map = child.get_active_lines_map()
			for target in lines_map.keys():
				var line = lines_map[target]
				if is_instance_valid(line) and line.visible:
					if _is_colliding_with_line(my_center_global, child, line, threshold):
						child.break_connection(target)
						# Putem adăuga un mic efect vizual sau sunet aici
						print("[QuestIcon] Coliziune detectată! Legătură tăiată.")

func _is_colliding_with_line(global_p: Vector2, skill_node: Control, line: Line2D, dist_threshold: float) -> bool:
	if line.points.size() < 2: return false
	
	# Convertim punctul nostru global în spațiul local al SkillIcon-ului (unde trăiesc punctele Line2D)
	# Folosim transformarea inversă deoarece Control nu are 'to_local' (doar Node2D are)
	var local_p = skill_node.get_global_transform().affine_inverse() * global_p
	
	# Verificăm distanța față de fiecare segment al curbei Line2D
	for i in range(line.points.size() - 1):
		var A = line.points[i]
		var B = line.points[i+1]
		
		var dist = _dist_to_segment(local_p, A, B)
		if dist < dist_threshold:
			return true
	return false

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var length_sq = ab.length_squared()
	if length_sq == 0: return p.distance_to(a)
	
	var t = ap.dot(ab) / length_sq
	t = clamp(t, 0.0, 1.0)
	var closest_point = a + ab * t
	return p.distance_to(closest_point)


var highlight_tween: Tween

func set_highlight(active: bool):
	if is_static: return # NU afișăm highlight dacă e static
	
	var highlight = get_node_or_null("Highlight")
	if highlight:
		if highlight_tween:
			highlight_tween.kill()
			
		highlight.visible = active
		if active:
			# Efect de pulsatie pentru highlight
			highlight_tween = create_tween().set_loops()
			highlight_tween.tween_property(highlight, "scale", Vector2(1.1, 1.1), 0.5)
			highlight_tween.tween_property(highlight, "scale", Vector2(1.0, 1.0), 0.5)
		else:
			highlight.scale = Vector2(1.0, 1.0)

func _on_actual_click():
	print("[QuestIcon] Incepere deschidere quest card...")

	# Curățăm highlight-ul de pe toate celelalte iconițe
	var board = get_parent()
	if board:
		for icon in board.get_children():
			if icon.has_method("set_highlight"):
				icon.set_highlight(false)

	# Activăm highlight-ul pe această iconiță
	set_highlight(true)

	if not quest_scene:
		print("[QuestIcon] EROARE: quest_scene este NULL!")
		return

	# Găsim rădăcina tab-ului (DockTab)
	var dock_tab = board.get_parent() 
	
	if not dock_tab or not (dock_tab.name == "DockTab" or dock_tab.name == "quest_tab"):
		var p = board
		while p != null:
			if p.name == "DockTab" or p.name == "quest_tab" or p is PanelContainer:
				dock_tab = p
				break
			p = p.get_parent()

	if not dock_tab:
		print("[QuestIcon] EROARE: Nu am găsit DockTab!")
		return

	# Căutăm quest_panel
	var quest_panel = dock_tab.get_node_or_null("VBoxContainer/quest_panel")
	if not quest_panel:
		quest_panel = dock_tab.find_child("quest_panel", true, false)
	
	if not quest_panel:
		print("[QuestIcon] EROARE: Nu am găsit quest_panel!")
		return

	# Curățăm quest-urile vechi
	for child in quest_panel.get_children():
		child.queue_free()

	# Instanțiem cardul
	var card = quest_scene.instantiate()
	quest_panel.add_child(card)
	opened_card = card

	# Transmitem referința iconiței către card
	if "origin_icon" in card:
		card.origin_icon = self
	
	# Inițializăm timpul pe card imediat
	if card.has_method("update_offer_time"):
		card.update_offer_time(current_offer_time, offer_lifetime)

	# Activăm highlight și pe card
	if card.has_method("set_card_highlight"):
		card.set_card_highlight(true)
		
	# SETĂRI PENTRU DIMENSIUNE
	card.visible = true



	if card.has_method("setup_data"):
		card.setup_data(quest_data)
		if "quest_scene_resource" in card:
			card.quest_scene_resource = quest_scene
	elif card.has_method("setup_quest"):
		card.setup_quest(quest_data)

	# Animație de Pop Out
	await get_tree().process_frame
	var card_size = card.size



	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1, 1), 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	print("[QuestIcon] Quest deschis, iconita ramane pe board.")
