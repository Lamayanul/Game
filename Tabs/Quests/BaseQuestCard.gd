extends PanelContainer
class_name BaseQuestCard

# --- NODURI UI (Leagă-le în Inspector) ---
@export_group("UI References")
@export var title_label: RichTextLabel
@export var giver_label: RichTextLabel
@export var description_label: RichTextLabel
@export var icon_texture: TextureRect
@export var time_bar: ProgressBar
@export var time_label: Label
@export var submit_btn: Button
@export var hide_btn: Button # Buton pentru a transforma inapoi in icon
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
var quest_scene_resource: PackedScene 
var origin_icon: Control # Referinta catre iconita de pe board
var is_accepted: bool = false

# Resursa pentru stea (asigură-te că calea e corectă)
var star_texture = preload("res://Tabs/Quests/star.png")

signal quest_completed(quest_data)
signal quest_expired()

func _ready():
	# Inițializare butoane
	submit_btn.text = "ACCEPTĂ"
	submit_btn.pressed.connect(_on_submit_pressed)
	
	if hide_btn:
		hide_btn.pressed.connect(_on_hide_pressed)
	
	# Inițializare panouri extra (ascunse la început)
	if panel_stanga: panel_stanga.visible = false
	if panel_dreapta: panel_dreapta.visible = false
	
	# Conectare click pe descriere
	if description_label:
		description_label.mouse_filter = Control.MOUSE_FILTER_STOP
		description_label.gui_input.connect(_on_description_gui_input)
	
	# Nu mai avem nevoie de set_process(true) aici pentru timer, 
	# dar s-ar putea să ai nevoie de el pentru altceva.
	set_process(false)

func update_offer_time(current: float, max_val: float):
	if is_accepted: return
	
	if time_bar:
		time_bar.max_value = max_val
		time_bar.value = current
	
	if time_label:
		var mins = int(current / 60)
		var secs = int(current) % 60
		time_label.text = "%02d:%02d" % [mins, secs]

func _process(_delta):
	pass

func set_card_highlight(active: bool):
	if active:
		# Efect de stralucire si bordura galbena
		modulate = Color(1.2, 1.2, 0.8)
		var sb = get_theme_stylebox("panel")
		if sb:
			var new_sb = sb.duplicate()
			if new_sb is StyleBoxFlat:
				new_sb.border_color = Color(1, 0.9, 0, 1)
				new_sb.set_border_width_all(5)
				add_theme_stylebox_override("panel", new_sb)
	else:
		modulate = Color.WHITE
		remove_theme_stylebox_override("panel")

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

func _on_hide_pressed():
	# Stingem highlight-ul iconitei la inchidere
	if origin_icon and origin_icon.has_method("set_highlight"):
		origin_icon.set_highlight(false)
		
	# Doar închidem cardul, deoarece iconița originală a rămas pe board
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _find_board() -> Node:
	# Căutăm nodul "board" urcând în ierarhie
	var p = get_parent()
	while p != null:
		if p.has_node("board"):
			return p.get_node("board")
		var b = p.find_child("board", true, false)
		if b: return b
		p = p.get_parent()
	return null

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
	for child in input_slot_container.get_children(): 
		child.queue_free()
	
	var input_slot = slot_scene.instantiate()
	input_slot_container.add_child(input_slot)
	
	if input_slot.has_method("clear_item"):
		input_slot.clear_item()
		
	input_slot.slot_type = "quest_input" 
	
	if input_slot.texture_rect.texture:
		input_slot.texture_rect.texture = quest_data.get("req_display_tex", null)
		input_slot.texture_rect.modulate.a = 0.5
		input_slot.label.text = str(quest_data["req_target_amount"])

	
	# --- 2. CONFIGURARE SLOT RECOMPENSĂ (REWARD) ---
	for child in reward_slot_container.get_children(): 
		child.queue_free()
	
	var reward_slot = slot_scene.instantiate()
	reward_slot_container.add_child(reward_slot)
	
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
		star.custom_minimum_size = Vector2(16, 16)
		stars_container.add_child(star)

func _on_submit_pressed():
	if not is_accepted:
		_accept_quest()
	else:
		_complete_quest()

func _accept_quest():
	is_accepted = true
	set_process(false)
	
	if origin_icon and "is_accepted" in origin_icon:
		origin_icon.is_accepted = true
	
	if time_bar: time_bar.value = time_bar.max_value
	if time_label: time_label.text = ""
	submit_btn.text = "VERIFICĂ"

func _complete_quest():
	_finish_animation()

func _finish_animation():
	submit_btn.disabled = true
	submit_btn.text = "FINALIZAT!"
	emit_signal("quest_completed", quest_data)
	
	if origin_icon and origin_icon.has_method("set_highlight"):
		origin_icon.set_highlight(false)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
