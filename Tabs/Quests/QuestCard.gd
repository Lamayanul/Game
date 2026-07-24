extends PanelContainer
class_name QuestCard

# --- REFERINȚE UI ---
@onready var title_lbl: Label = $MainLayout/Header/InfoBox/TitleLabel
@onready var giver_lbl: Label = $MainLayout/Header/InfoBox/MetaInfo/GiverLabel
@onready var giver_icon: TextureRect = $MainLayout/Header/GiverIcon
@onready var difficulty_container: HBoxContainer = $MainLayout/Header/InfoBox/MetaInfo/DifficultyStars


@onready var desc_lbl: RichTextLabel = $MainLayout/DescriptionLabel
@onready var time_bar: ProgressBar = $MainLayout/TimeBar
@onready var time_text: Label = $MainLayout/TimeBar/TimeText

@onready var input_slot: Slot = $MainLayout/ActionArea/Input/InputSlotHolder/Slot
@onready var progress_lbl: Label = $MainLayout/ActionArea/Input/ProgressLabel
@onready var reward_slot: Slot = $MainLayout/ActionArea/Output/RewardSlotHolder/Slot
@onready var submit_btn: Button = $MainLayout/SubmitButton
@export var hide_btn: Button # Butonul "-" adăugat de tine

# --- CONFIGURARE & RESURSE ---
@export var star_texture: Texture2D # Trage o iconiță cu o stea aici în Inspector
@export var pin_icon_normal: Texture2D
@export var pin_icon_active: Texture2D
@onready var offer_bar: ProgressBar = $MainLayout/TimeBar # Refolosim bara de timp
@export var offer_lifetime: float = 15.0 # Cât timp stă pe panou (secunde)
var current_offer_time: float = 0.0
var is_accepted: bool = false # Starea misiunii
var quest_scene_resource: PackedScene
var origin_icon: Control

# --- DATE INTERNE ---
var quest_id: String = ""
var req_item_id: int = 0
var req_amount: int = 1
var reward_data: Dictionary = {}

# Timer
var time_limit_seconds: float = 0.0
var current_time: float = 0.0
var is_timed: bool = false
var is_failed: bool = false

# Semnale
signal quest_completed(q_id, reward)
signal quest_failed(q_id)
signal quest_tracked(q_id, is_tracking)

func _ready():
	set_process(false) # Oprim procesarea până primim date
	submit_btn.pressed.connect(_on_submit_pressed)

	# Configurare vizuală pentru TimeText (să fie centrat pe bară)
	if time_text:
		time_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		time_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_text.add_theme_color_override("font_color", Color.WHITE)
		time_text.add_theme_color_override("font_outline_color", Color.BLACK)
		time_text.add_theme_constant_override("outline_size", 4)
	
	if time_bar:
		time_bar.custom_minimum_size.y = 24
		time_bar.show_percentage = false # Ascundem procentajul implicit ca să nu se suprapună
	
	# Asigurăm că slotul de recompensă nu poate fi furat
	# (Presupunând că Slot.gd are o variabilă sau mod de a bloca drag-ul)
	reward_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	current_offer_time = offer_lifetime
	
	# Inițial, butonul de acțiune este "ACCEPTĂ"
	submit_btn.text = "ACCEPTĂ MISIUNEA"
	submit_btn.pressed.disconnect(_on_submit_pressed) # Deconectăm logica veche temporar
	submit_btn.pressed.connect(_on_accept_pressed)    # Conectăm logica de acceptare
	
	if hide_btn:
		hide_btn.pressed.connect(_on_hide_pressed)

	# Ascundem sloturile de input până se acceptă misiunea (Opțional, pentru curățenie)
	input_slot.visible = false
	reward_slot.visible = false

func set_card_highlight(active: bool):
	if active:
		# Un efect vizual de highlight puternic
		modulate = Color(1.3, 1.3, 0.9)
		var sb = get_theme_stylebox("panel")
		if sb:
			var new_sb = sb.duplicate()
			if new_sb is StyleBoxFlat:
				new_sb.border_color = Color.YELLOW
				new_sb.set_border_width_all(6)
				add_theme_stylebox_override("panel", new_sb)
	else:
		modulate = Color.WHITE
		remove_theme_stylebox_override("panel")

# ============================================================
# 1. SETUP (Inițializare)
# ============================================================
func setup_quest(data: Dictionary):
	quest_id = data.get("id", "q_unknown")
	title_lbl.text = data.get("title", "Misiune")
	giver_lbl.text = data.get("giver_name", "Anonim")
	desc_lbl.text = data.get("description", "...")
	
		
	# --- 1. Dificultate (Stele) ---
	var difficulty = data.get("difficulty", 1) # 1-5
	_generate_stars(difficulty)
	
	# --- 2. Cerințe ---
	req_item_id = data.get("req_item_id", 0)
	req_amount = data.get("req_amount", 1)
	_update_progress_visuals(0) # Inițial e 0
	
	# --- 3. Recompensă ---
	reward_data = data.get("reward", {})
	if not reward_data.is_empty():
		reward_slot.set_property(reward_data)
	
	# --- 4. Timer (Opțional) ---
	if data.has("time_limit"):
		is_timed = true
		time_limit_seconds = float(data["time_limit"])
		current_time = time_limit_seconds
		time_bar.max_value = time_limit_seconds
		time_bar.value = current_time
		time_bar.visible = true
		set_process(true) # Pornim cronometrul
	else:
		is_timed = false
		time_bar.visible = false
		set_process(true) # Pornim oricum pentru a verifica slotul de input

# ============================================================
# 2. LOGICĂ PER FRAME (Timer & Validare)
# ============================================================
func _process(delta):
	if is_failed: return

	# --- A. Gestionare Timp ---
	if not is_accepted:
		current_offer_time -= delta
		
		# Actualizăm bara vizuală și textul (scade rapid)
		if offer_bar:
			offer_bar.visible = true
			offer_bar.max_value = offer_lifetime
			offer_bar.value = current_offer_time
			offer_bar.modulate = Color.ORANGE # Culoare de "urgență"
		
		if time_text:
			var o_mins = int(current_offer_time / 60)
			var o_secs = int(current_offer_time) % 60
			time_text.text = "Expiră în: %02d:%02d" % [o_mins, o_secs]
		
		# Dacă timpul a expirat, distrugem cardul
		if current_offer_time <= 0:
			_expire_offer()
		return # Nu rulăm logica de misiune încă

	if is_timed:
		current_time -= delta
		if offer_bar: # Refolosim bara pentru timpul misiunii
			offer_bar.value = current_time
			offer_bar.modulate = Color.GREEN
		time_bar.value = current_time
		
		# Formatăm timpul MM:SS
		if time_text:
			var mins = int(current_time / 60)
			var secs = int(current_time) % 60
			time_text.text = "Timp rămas: %02d:%02d" % [mins, secs]
		
		# Schimbăm culoarea barei dacă e critic (sub 20%)
		if current_time < time_limit_seconds * 0.2:
			time_bar.modulate = Color.RED
		else:
			time_bar.modulate = Color.GREEN
			
		if current_time <= 0:
			_fail_quest()
			return

	# --- B. Gestionare Input (Verificăm ce pune playerul) ---
	_check_input_slot()

func _on_accept_pressed():
	is_accepted = true
	
	# Schimbăm UI-ul în modul "Activ"
	input_slot.visible = true
	reward_slot.visible = true
	submit_btn.text = "Aștept iteme..."
	
	# Reconectăm butonul la funcția de finalizare
	submit_btn.pressed.disconnect(_on_accept_pressed)
	submit_btn.pressed.connect(_on_submit_pressed)
	
	# Resetăm bara pentru timer-ul misiunii (dacă există)
	if is_timed:
		current_time = time_limit_seconds
		if offer_bar: offer_bar.max_value = time_limit_seconds
	else:
		if offer_bar: offer_bar.visible = false # Ascundem bara dacă nu e misiune cronometrată

func _expire_offer():
	# Animație de dispariție și ștergere
	if origin_icon and origin_icon.has_method("set_highlight"):
		origin_icon.set_highlight(false)

	set_process(false)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # Fade out
	tween.tween_callback(queue_free)

func _on_hide_pressed():
	if origin_icon and origin_icon.has_method("set_highlight"):
		origin_icon.set_highlight(false)
		
	# Doar închidem cardul, deoarece iconița originală a rămas pe board
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _find_board() -> Node:
	var p = get_parent()
	while p != null:
		if p.has_node("board"):
			return p.get_node("board")
		var b = p.find_child("board", true, false)
		if b: return b
		p = p.get_parent()
	return null

	
func _check_input_slot():
	# Citim ce e în slotul de input
	var current_qty = input_slot.property.get("CANTITATE", 0)
	var current_id = input_slot.property.get("NUMBER", -1)
	
	# Actualizăm textul de progres (ex: "3/10")
	_update_progress_visuals(current_qty)
	
	# Validăm condițiile
	if current_id == req_item_id and current_qty >= req_amount:
		submit_btn.disabled = false
		submit_btn.text = "RECLAMĂ RECOMPENSA"
		submit_btn.modulate = Color.GREEN
	else:
		submit_btn.disabled = true
		submit_btn.text = "În așteptare..."
		submit_btn.modulate = Color.WHITE

func _update_progress_visuals(current: int):
	# Facem textul verde dacă e gata, roșu dacă nu
	var color_tag = "[color=green]" if current >= req_amount else "[color=red]"

	progress_lbl.text = "%d / %d" % [current, req_amount]
	
	if current >= req_amount:
		progress_lbl.modulate = Color.GREEN
	else:
		progress_lbl.modulate = Color.WHITE

# ============================================================
# 3. FINALIZARE & UTILITARE
# ============================================================
func _on_submit_pressed():
	# Consumăm itemele
	input_slot.decrease_cantitate(req_amount)
	
	if origin_icon and origin_icon.has_method("set_highlight"):
		origin_icon.set_highlight(false)

	# Animăm și finalizăm
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "scale", Vector2(0,0), 0.3)
	tween.tween_callback(func():
		emit_signal("quest_completed", quest_id, reward_data)
		queue_free()
	)

func _fail_quest():
	is_failed = true
	submit_btn.disabled = true
	submit_btn.text = "EXPIRAT"
	modulate = Color(0.5, 0.5, 0.5, 0.8) # Facem cardul gri
	emit_signal("quest_failed", quest_id)

	if origin_icon and origin_icon.has_method("set_highlight"):
		origin_icon.set_highlight(false)



func _generate_stars(count: int):
	# Curățăm stelele vechi (dacă refolosim cardul)
	for child in difficulty_container.get_children():
		child.queue_free()
		
	# Adăugăm stele noi
	for i in range(count):
		var tex = TextureRect.new()
		tex.texture = star_texture
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tex.custom_minimum_size = Vector2(16, 16)
		difficulty_container.add_child(tex)
