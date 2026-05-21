extends PanelContainer
class_name BaseQuestCard

# --- NODURI UI (Leagă-le în Inspector) ---
@export_group("UI References")
@export var title_label: RichTextLabel
@export var giver_label: RichTextLabel
@export var description_label: RichTextLabel
@export var icon_texture: TextureRect
@export var time_bar: ProgressBar
@export var submit_btn: Button
@export var stars_container: Container # Container orizontal pentru stele

@export_group("Extra Panels")
@export var panel_stanga: Control
@export var panel_dreapta: Control

@export_group("Slots & Containers")
@export var input_slot_container: Control
@export var reward_slot_container: Control
@export var slot_scene: PackedScene # TRAGE AICI SCENA SLOTULUI (tscn)


# --- DATE INTERNE ---
var quest_data: Dictionary = {}
@export var offer_lifetime: float = 15.0
var current_offer_time: float = 0.0
var is_accepted: bool = false

# Resursa pentru stea (asigură-te că calea e corectă)
var star_texture = preload("res://Tabs/Quests/star.png")

signal quest_completed(quest_data)
signal quest_expired()

func _ready():
	current_offer_time = offer_lifetime
	
	# Inițializare buton
	submit_btn.text = "ACCEPTĂ"
	submit_btn.pressed.connect(_on_submit_pressed)
	
	# Inițializare panouri extra (ascunse la început)
	if panel_stanga: panel_stanga.visible = false
	if panel_dreapta: panel_dreapta.visible = false
	
	# Conectare click pe descriere
	if description_label:
		description_label.mouse_filter = Control.MOUSE_FILTER_STOP
		description_label.gui_input.connect(_on_description_gui_input)
	
	# Pornim timer-ul de expirare ofertă
	set_process(true)

func _on_description_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_panels()

func _toggle_panels():
	if not panel_stanga or not panel_dreapta: return
	
	var is_visible = not panel_stanga.visible
	panel_stanga.visible = is_visible
	panel_dreapta.visible = is_visible
	
	# Ascunde/Afișează celelalte quest-uri (siblings)
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child != self and child is CanvasItem:
				child.visible = not is_visible

# Această funcție este apelată de Spawner
func setup_data(data: Dictionary):
	quest_data = data
	
	# 1. Populare Texte
	if title_label: title_label.text = "[center]" + data.get("title", "Misiune") + "[/center]"
	if description_label: description_label.text = data.get("description", "")
	if giver_label: giver_label.text = data.get("giver_name", "Necunoscut")
	if icon_texture and data.has("giver_icon"): icon_texture.texture = data["giver_icon"]
	
	# 2. Generare Sloturi (Input și Reward)
	_spawn_slots()
	
	# 3. Generare Stele
	var raritate = data["reward"].get("RARITATE", "comuna")
	_generate_stars(raritate)

func _spawn_slots():
	if slot_scene == null:
		print("EROARE: 'slot_scene' nu este setat în Inspector la QuestCard!")
		return

	# --- 1. CONFIGURARE SLOT CERINȚĂ (INPUT) ---
	# --- 1. CONFIGURARE SLOT CERINȚĂ (INPUT) ---
	for child in input_slot_container.get_children(): 
		child.queue_free()
	
	var input_slot = slot_scene.instantiate()
	# 1. Adăugăm copilul ca să se inițializeze variabilele (@onready)
	input_slot_container.add_child(input_slot)
	
	# 2. GOLIM slotul logic
	# Asta setează filled = false și resetează datele, permițând drop-ul
	if input_slot.has_method("clear_item"):
		input_slot.clear_item()
		
	# 3. Setăm tipul pentru a permite drop-ul (verifică logica ta din _can_drop_data)
	input_slot.slot_type = "quest_input" 
	
	# 4. TRUCUL VIZUAL: Punem imaginea manual, fără să umplem datele
	# Accesăm direct variabila 'texture_rect' din Slot.gd
	if input_slot.texture_rect.texture:
		input_slot.texture_rect.texture = quest_data.get("req_display_tex", null)
		
		# Opțional: O facem semi-transparentă ca să arate a "fantomă" (ceea ce se cere)
		input_slot.texture_rect.modulate.a = 0.5
		input_slot.label.text = str(quest_data["req_target_amount"])

	
	# --- 2. CONFIGURARE SLOT RECOMPENSĂ (REWARD) ---
	for child in reward_slot_container.get_children(): 
		child.queue_free()
	
	var reward_slot = slot_scene.instantiate()
	reward_slot_container.add_child(reward_slot)
	
	# Datele de recompensă sunt deja în formatul corect în quest_data["reward"]
	if reward_slot.has_method("set_property"):
		reward_slot.set_property(quest_data["reward"])
		reward_slot.slot_type = "display_only"

func _generate_stars(raritate: String):
	if stars_container == null: return
	
	# Curățăm stelele vechi
	for child in stars_container.get_children():
		child.queue_free()
	
	var num_stars = 1
	match raritate:
		"comuna": num_stars = 1
		"rara": num_stars = 2
		"epica": num_stars = 3
		"legendara": num_stars = 5
	
	for i in range(num_stars):
		var star = TextureRect.new()
		star.texture = star_texture
		star.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		star.custom_minimum_size = Vector2(16, 16) # Ajustează mărimea
		stars_container.add_child(star)

func _process(delta):
	# Timer-ul merge DOAR dacă misiunea NU e acceptată încă
	if not is_accepted:
		current_offer_time -= delta
		
		if time_bar:
			time_bar.max_value = offer_lifetime
			time_bar.value = current_offer_time
		
		# Dacă timpul expiră, ștergem cardul
		if current_offer_time <= 0:
			emit_signal("quest_expired")
			queue_free()

func _on_submit_pressed():
	if not is_accepted:
		_accept_quest()
	else:
		_complete_quest()

func _accept_quest():
	is_accepted = true
	set_process(false) # Oprim timer-ul de expirare, misiunea e a noastră acum
	
	# Actualizăm UI-ul
	if time_bar: time_bar.value = time_bar.max_value # Plin, sau îl ascunzi
	submit_btn.text = "VERIFICĂ"
	
	print("Misiune acceptată! Ai tot timpul să o faci.")

func _complete_quest():
	# Aici verificăm Inventarul Player-ului

	var req_id = quest_data["req_item_id"]
	var req_amount = quest_data["req_amount"]
	
	print("Verific inventar: ID ", req_id, " Cantitate ", req_amount)
	
	# --- EXEMPLU LOGICĂ INVENTAR ---
	# if Inventory.has_item(req_id, req_amount):
	#     Inventory.remove_item(req_id, req_amount)
	#     Inventory.add_item(quest_data["reward"]["NUMBER"], quest_data["reward"]["CANTITATE"])
	#     _finish_animation()
	# else:
	#     submit_btn.text = "LIPSA ITEME"
	#     await get_tree().create_timer(1.0).timeout
	#     submit_btn.text = "VERIFICĂ"
	
	# PENTRU TEST, considerăm că e gata:
	_finish_animation()

func _finish_animation():
	submit_btn.disabled = true
	submit_btn.text = "FINALIZAT!"
	emit_signal("quest_completed", quest_data)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
