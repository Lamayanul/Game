extends PanelContainer # Sau Control

# --- 1. Referințe UI (Exportate pentru a le seta din Inspector) ---
@export_group("Elemente Vizuale")
@export var texture_bg: TextureRect
@export var name_label: RichTextLabel # Folosim RichTextLabel pt formatare
@export var health_text: RichTextLabel # Sau Label, depinde ce nod ai în scenă
@export var health_bar: TextureProgressBar
@export var description_label: RichTextLabel
@onready var animation_player: AnimationPlayer = get_node_or_null("TextureRect/Panel/AnimationPlayer")
@export_group("Animații")
@export var animated_sprite: AnimatedSprite2D


@export var is_enemy: bool = false
var enemy_ai_timer: float = 0.0
var enemy_ai_interval: float = 3.0 # Schimbă la fiecare 3 secunde
var ai_synergy_goal: int = 0
var ai_target_pos_left: Vector2 = Vector2.ZERO
var ai_target_pos_right: Vector2 = Vector2.ZERO
var ai_lerp_speed: float = 3.0

# --- 2. Referințe Inventar (Opțional) ---
@export_group("Inventar")
@export var inv_panel: PanelContainer
@export var slots_container: GridContainer

# Reference to the 8 slots in TextureRect/Panel/Items
@onready var main_item_1 = $TextureRect/Panel/Items/Control/principalItem
@onready var main_item_2 = $TextureRect/Panel/Items/Control2/principalItem
@onready var slot_3 = $TextureRect/Panel/Items/Control/SlotContainer3
@onready var slot_4 = $TextureRect/Panel/Items/Control/SlotContainer4
@onready var slot_5 = $TextureRect/Panel/Items/Control/SlotContainer5
@onready var slot_6 = $TextureRect/Panel/Items/Control2/SlotContainer3
@onready var slot_7 = $TextureRect/Panel/Items/Control2/SlotContainer4
@onready var slot_8 = $TextureRect/Panel/Items/Control2/SlotContainer5

@onready var combat_slots = [main_item_1, slot_3, slot_4, slot_5, main_item_2, slot_6, slot_7, slot_8]

@onready var mana_1 = load("res://Fights/mana_1.png")
@onready var mana_2 = load("res://Fights/mana_2.png")
@onready var mana_3 = load("res://Fights/mana_3.png")
@onready var mana_4 = load("res://Fights/mana_4.png")
@onready var mana_5 = load("res://Fights/mana_5.png")
@onready var mana_6 = load("res://Fights/mana_6.png")
@onready var mana_7 = load("res://Fights/mana_7.png")
@onready var mana_8 = load("res://Fights/mana_8.png")
@onready var mana_9 = load("res://Fights/mana_9.png")


# --- 3. Date Locale ---
var dragging_node: Control = null
var drag_offset: Vector2 = Vector2.ZERO

var original_pos_1: Vector2
var original_pos_2: Vector2
var float_time: float = 0.0

var control_left: Control
var control_right: Control
var area_stanga: Area2D
var area_dreapta: Area2D

@onready var mana_textures = [
	load("res://Fights/mana_1.png"),
	load("res://Fights/mana_2.png"),
	load("res://Fights/mana_3.png"),
	load("res://Fights/mana_4.png"),
	load("res://Fights/mana_5.png"),
	load("res://Fights/mana_6.png"),
	load("res://Fights/mana_7.png"),
	load("res://Fights/mana_8.png"),
	load("res://Fights/mana_9.png")
]
var current_mana_idx_left: int = 0
var current_mana_idx_right: int = 0

var original_area_pos_left: Vector2
var original_area_pos_right: Vector2

# --- Floating Panels Variables ---
var panel_left: Panel
var panel_right: Panel
var details_left: RichTextLabel
var details_right: RichTextLabel
var dragging_panel: Control = null
var panel_drag_offset: Vector2 = Vector2.ZERO

func _setup_floating_panels(is_left: bool):
	var panel = Panel.new()
	panel.name = "FloatingPanelLeft" if is_left else "FloatingPanelRight"
	panel.custom_minimum_size = Vector2(400, 230)
	panel.size = Vector2(400, 230)
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD if is_left else Color.SKY_BLUE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var items_container = get_node_or_null("TextureRect/Panel/Items")
	if items_container:
		items_container.add_child(panel)
	
	panel.gui_input.connect(_on_panel_gui_input.bind(panel))
	
	var details = RichTextLabel.new()
	details.name = "Details"
	details.custom_minimum_size = Vector2(280, 210)
	details.size = Vector2(280, 210)
	details.position = Vector2(110, 10)
	details.bbcode_enabled = true
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE # Să nu blocheze sloturile
	details.text = "[center][color=gray]Select an item to see effects and curses[/color][/center]"
	panel.add_child(details)
	
	if is_left:
		panel_left = panel
		details_left = details
	else:
		panel_right = panel
		details_right = details
		
	var slots = sub_slots_left if is_left else sub_slots_right
	for i in range(slots.size()):
		var s = slots[i]
		if is_instance_valid(s):
			var old_parent = s.get_parent()
			if old_parent: old_parent.remove_child(s)
			panel.add_child(s)
			s.position = Vector2(20, 15 + i * 70)
			s.description = details
			s.mouse_filter = Control.MOUSE_FILTER_STOP # Slotul trebuie să consume evenimentul
			if sub_rest_positions.has(s): sub_rest_positions.erase(s)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, is_left: bool):
	if is_enemy: return # Playerul nu poate vedea panourile inamicului prin double-click pe mână

	if event is InputEventMouseButton and event.pressed and event.double_click:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var panel = panel_left if is_left else panel_right
			if panel:
				panel.visible = !panel.visible
				if panel.visible:
					# Spawnăm panoul lângă element, nu direct pe el
					var offset = Vector2(-420, -100) if is_left else Vector2(120, -100)
					panel.global_position = get_global_mouse_position() + offset
					panel.move_to_front()

func _on_panel_gui_input(event: InputEvent, panel: Control):
	if is_enemy: return # Securitate extra

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Verificăm dacă am dat click pe un slot înainte de a începe drag-ul panoului
			var mouse_pos = panel.get_local_mouse_position()
			for child in panel.get_children():
				if child is Slot and child.get_rect().has_point(mouse_pos):
					return # Lăsăm slotul să gestioneze evenimentul
					
			dragging_panel = panel
			panel_drag_offset = get_global_mouse_position() - panel.global_position
			panel.move_to_front()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging_panel = null

# Define offsets for each texture index (0:mana_1, 1:mana_2, 2:mana_3, 3:mana_4, 4:mana_5, 5:mana_6)
var mana_offsets = [
	Vector2(0, 0),      # mana_1
	Vector2(0, 0),      # mana_2
	Vector2(0, 0),      # mana_3
	Vector2(0,0), # mana_4
	Vector2(0, 0),      # mana_5
	Vector2(0, 0),       # mana_6
	Vector2(0, 0),       # mana_7
	Vector2(0, 0),    # mana_8
	Vector2(0, 0)       # mana_9
]

@export var atk: int = 10
@export var def: int = 10
@export var spd: int = 100
@export var max_hp: int = 100
var equipped_weapon_id: String = "FIST"
var _current_ability_type: String = "" # Tracks if we are showing attack or defense

var current_hp: int = 100:
	set(value):
		current_hp = value
		_update_ui_elements()

# Alias for StatusEffects compatibility
var health: int:
	get: return current_hp
	set(value):
		current_hp = value

var character_id = null
var is_in_combat: bool = false

# --- 4. Semnale ---
signal card_clicked(card_ref)
signal character_died(card_ref)
signal action_selected(move_data)

var sub_slots_left: Array = []
var sub_slots_right: Array = []
var sub_rest_positions: Dictionary = {} # Stochează pozițiile relative inițiale

# Define custom offsets for each hand texture and flip state
var slot_custom_offsets = [
	{ # mana_1
		"normal": Vector2(160, 220),
		"flip_h": Vector2(160, 220),
		"flip_v": Vector2(160, 420),
		"flip_hv": Vector2(160, 420)
	},
	{ # mana_2
		"normal": Vector2(180, 220),
		"flip_h": Vector2(180, 220),
		"flip_v": Vector2(180, 420),
		"flip_hv": Vector2(180, 420)
	},
	{ # mana_3
		"normal": Vector2(180, 220),
		"flip_h": Vector2(180, 220),
		"flip_v": Vector2(180, 420),
		"flip_hv": Vector2(180, 420)
	},
	{ # mana_4
		"normal": Vector2(180, 420),
		"flip_h": Vector2(110, 420),
		"flip_v": Vector2(200, 220),
		"flip_hv": Vector2(130, 220)
	},
	{ # mana_5
		"normal": Vector2(220, 240),
		"flip_h": Vector2(140, 240),
		"flip_v": Vector2(180, 360),
		"flip_hv": Vector2(140, 400)
	},
	{ # mana_6
		"normal": Vector2(240, 300), # mare -> in dreapta ||  mare -> jos
		"flip_h": Vector2(100, 260),
		"flip_v": Vector2(200 ,  380),
		"flip_hv": Vector2(100, 360)
	}
]

func _update_principal_slot_position(is_left: bool):
	var idx = current_mana_idx_left if is_left else current_mana_idx_right
	var slot = main_item_1 if is_left else main_item_2
	
	var hand = null
	if is_left and control_left: hand = control_left.get_node_or_null("mana_stanga")
	elif not is_left and control_right: hand = control_right.get_node_or_null("mana_dreapta")
	
	if not is_instance_valid(slot) or not is_instance_valid(hand): return
	
	# 1. Determinăm cheia pentru starea curentă de flip
	var state = "normal"
	if hand.flip_h and hand.flip_v: state = "flip_hv"
	elif hand.flip_h: state = "flip_h"
	elif hand.flip_v: state = "flip_v"
	
	# 2. Extragem poziția custom (sau fallback la "normal" dacă indexul sau cheia lipsește)
	var final_pos = Vector2(160, 220) # Default
	if idx < slot_custom_offsets.size():
		var hand_data = slot_custom_offsets[idx]
		final_pos = hand_data.get(state, hand_data["normal"])
	
	# 3. Aplicăm poziția finală
	slot.position = final_pos
	
	# Actualizăm poziția originală pentru animația de breathing/floating
	if is_left: original_pos_1 = final_pos
	else: original_pos_2 = final_pos

func _ready():
	# ... (codul existent de căutare noduri) ...
	control_left = get_node_or_null("TextureRect/Panel/Items/Control")
	control_right = get_node_or_null("TextureRect/Panel/Items/Control2")
	
	# Setăm mouse_filter pe PASS pentru tot traseul ierarhic pentru a permite drop-ul la root
	var main_tex = get_node_or_null("TextureRect")
	if main_tex: main_tex.mouse_filter = Control.MOUSE_FILTER_PASS
	var sub_panel = get_node_or_null("TextureRect/Panel")
	if sub_panel: sub_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if control_left:
		area_stanga = control_left.get_node_or_null("mana_stanga/Area2D")
		var hand_left = control_left.get_node_or_null("mana_stanga")
		if hand_left: hand_left.mouse_filter = Control.MOUSE_FILTER_PASS
		if area_stanga:
			area_stanga.input_pickable = true
			if not area_stanga.input_event.is_connected(_on_area_input_event):
				area_stanga.input_event.connect(_on_area_input_event.bind(true))
		sub_slots_left = [slot_3, slot_4, slot_5]
	
	if control_right:
		area_dreapta = control_right.get_node_or_null("mana_dreapta/Area2D")
		var hand_right = control_right.get_node_or_null("mana_dreapta")
		if hand_right: hand_right.mouse_filter = Control.MOUSE_FILTER_PASS
		if area_dreapta:
			area_dreapta.input_pickable = true
			if not area_dreapta.input_event.is_connected(_on_area_input_event):
				area_dreapta.input_event.connect(_on_area_input_event.bind(false))
		sub_slots_right = [slot_6, slot_7, slot_8]
		
	# Asigurăm că întregul card poate primi drop
	mouse_filter = Control.MOUSE_FILTER_PASS
	var items_container = get_node_or_null("TextureRect/Panel/Items")
	if items_container: items_container.mouse_filter = Control.MOUSE_FILTER_PASS
	if control_left: control_left.mouse_filter = Control.MOUSE_FILTER_PASS
	if control_right: control_right.mouse_filter = Control.MOUSE_FILTER_PASS

	# Așteptăm un frame pentru stabilizare layout
	await get_tree().process_frame
	
	# Setup floating panels (reparents sub-slots)
	_setup_floating_panels(true)
	_setup_floating_panels(false)
	
	# Salvăm pozițiile finale după ce layout-ul s-a stabilizat
	if area_stanga: original_area_pos_left = area_stanga.position
	if area_dreapta: original_area_pos_right = area_dreapta.position
	
	for s in (sub_slots_left + sub_slots_right):
		if is_instance_valid(s): 
			sub_rest_positions[s] = s.position
			s.visible = s.filled
	
	# Setăm pozițiile custom pentru sloturile principale
	_update_principal_slot_position(true)
	_update_principal_slot_position(false)
	
	if is_instance_valid(main_item_1): main_item_1.visible = main_item_1.filled
	if is_instance_valid(main_item_2): main_item_2.visible = main_item_2.filled

	if animated_sprite:
		animated_sprite.visible = false

	_update_ui_elements()
	_connect_combat_slots()

func _update_mana_collision_pos(area: Area2D, idx: int, is_left: bool):
	if not is_instance_valid(area): return
	var base_pos = original_area_pos_left if is_left else original_area_pos_right
	area.position = base_pos + mana_offsets[idx]

var synergy_slot: Node = null
var synergy_detail_panel: Panel = null
var synergy_timer: float = 0.0
const SYNERGY_TIMEOUT = 0.5 # Secunde de grație înainte de a dispărea
const SLOT_SCENE = preload("res://User/slot_container.tscn")

func _process(delta: float) -> void:
	if is_enemy:
		_enemy_ai_logic(delta)
		# Mișcăm mâinile AI-ului spre ținte dacă nu sunt trase de player
		if not dragging_node:
			var card_rect = get_global_rect()
			if ai_target_pos_left != Vector2.ZERO and is_instance_valid(control_left):
				# Constrângem ținta să rămână în card
				var target = ai_target_pos_left
				target.x = clamp(target.x, card_rect.position.x + 100, card_rect.end.x - 100)
				target.y = clamp(target.y, card_rect.position.y + 100, card_rect.end.y - 100)
				
				# Lerp spre (Target Pivot - Pivot Offset) pentru a ajunge cu centrul la target
				var target_global_pos = target - control_left.pivot_offset
				control_left.global_position = control_left.global_position.lerp(target_global_pos, delta * ai_lerp_speed)
				
			if ai_target_pos_right != Vector2.ZERO and is_instance_valid(control_right):
				var target = ai_target_pos_right
				target.x = clamp(target.x, card_rect.position.x + 100, card_rect.end.x - 100)
				target.y = clamp(target.y, card_rect.position.y + 100, card_rect.end.y - 100)
				
				var target_global_pos = target - control_right.pivot_offset
				control_right.global_position = control_right.global_position.lerp(target_global_pos, delta * ai_lerp_speed)

	if dragging_panel:
		dragging_panel.global_position = get_global_mouse_position() - panel_drag_offset

	if original_pos_1 != Vector2.ZERO or original_pos_2 != Vector2.ZERO:
		_update_floating_animation(delta)
	
	_update_dynamic_slots(delta)
	_check_synergies(delta)
	
	# Update ALL slots visibility dynamically
	if synergy_slot == null:
		for slot in combat_slots:
			if is_instance_valid(slot):
				# Don't hide sub-slots if their panel is visible
				var is_sub_left = slot in sub_slots_left
				var is_sub_right = slot in sub_slots_right
				if is_sub_left or is_sub_right:
					var p = panel_left if is_sub_left else panel_right
					if p: slot.visible = p.visible
					else: slot.visible = slot.filled
				else:
					slot.visible = slot.filled

func _enemy_ai_logic(delta: float):
	enemy_ai_timer -= delta
	if enemy_ai_timer <= 0:
		# 40% șansă să încerce o sinergie, 60% mișcare random
		if randf() < 0.4:
			_apply_ai_synergy()
			enemy_ai_timer = randf_range(5.0, 7.0) # Sinergia stă mai mult
		else:
			ai_synergy_goal = 0
			_apply_ai_random_move()
			enemy_ai_timer = randf_range(1.5, 3.5)

func _apply_ai_random_move():
	var choice = randi() % 5
	match choice:
		0: # Schimbăm textura stânga
			current_mana_idx_left = randi() % mana_textures.size()
			var tex = control_left.get_node_or_null("mana_stanga") if control_left else null
			if tex: tex.texture = mana_textures[current_mana_idx_left]
			if is_instance_valid(area_stanga): _update_mana_collision_pos(area_stanga, current_mana_idx_left, true)
			_update_principal_slot_position(true)
		1: # Schimbăm textura dreapta
			current_mana_idx_right = randi() % mana_textures.size()
			var tex = control_right.get_node_or_null("mana_dreapta") if control_right else null
			if tex: tex.texture = mana_textures[current_mana_idx_right]
			if is_instance_valid(area_dreapta): _update_mana_collision_pos(area_dreapta, current_mana_idx_right, false)
			_update_principal_slot_position(false)
		2: # Flip H random ambele
			var tex_l = control_left.get_node_or_null("mana_stanga") if control_left else null
			var tex_r = control_right.get_node_or_null("mana_dreapta") if control_right else null
			if tex_l: tex_l.flip_h = (randi() % 2 == 0)
			if tex_r: tex_r.flip_h = (randi() % 2 == 0)
			_update_principal_slot_position(true)
			_update_principal_slot_position(false)
		3: # Flip V random ambele
			var tex_l = control_left.get_node_or_null("mana_stanga") if control_left else null
			var tex_r = control_right.get_node_or_null("mana_dreapta") if control_right else null
			if tex_l: tex_l.flip_v = (randi() % 2 == 0)
			if tex_r: tex_r.flip_v = (randi() % 2 == 0)
			_update_principal_slot_position(true)
			_update_principal_slot_position(false)
		4: # Schimbăm poziția țintă a mâinilor (mișcare pe ecran)
			var card_rect = get_global_rect()
			var center = card_rect.get_center()
			ai_target_pos_left = center + Vector2(randf_range(-180, -40), randf_range(-120, 120))
			ai_target_pos_right = center + Vector2(randf_range(40, 180), randf_range(-120, 120))

func _apply_ai_synergy():
	var card_rect = get_global_rect()
	var center = card_rect.get_center()
	ai_synergy_goal = (randi() % 3) + 1 # Alegem una din cele 3 sinergii existente
	
	var tex_l = control_left.get_node_or_null("mana_stanga") if control_left else null
	var tex_r = control_right.get_node_or_null("mana_dreapta") if control_right else null
	
	match ai_synergy_goal:
		1: # Sinergia 1: Mana 3 + Mana 0, left above right
			current_mana_idx_left = 3
			current_mana_idx_right = 0
			ai_target_pos_left = center + Vector2(-100, -80)
			ai_target_pos_right = center + Vector2(80, 40)
			if tex_l: tex_l.flip_h = false; tex_l.flip_v = false
			if tex_r: tex_r.flip_h = false; tex_r.flip_v = false
		2: # Sinergia 2: Mana 5 + Mana 5, left flip_h, right flip_v
			current_mana_idx_left = 5
			current_mana_idx_right = 5
			ai_target_pos_left = center + Vector2(-60, 0)
			ai_target_pos_right = center + Vector2(60, 0)
			if tex_l: tex_l.flip_h = true
			if tex_r: tex_r.flip_v = true
		3: # Sinergia 3: Mana 0 + Mana 3, left below right
			current_mana_idx_left = 0
			current_mana_idx_right = 3
			ai_target_pos_left = center + Vector2(-100, 40)
			ai_target_pos_right = center + Vector2(80, -80)
			if tex_l: tex_l.flip_h = false; tex_l.flip_v = false
			if tex_r: tex_r.flip_h = false; tex_r.flip_v = false
	
	# Aplicăm texturile și coliziunile corespunzătoare
	if tex_l: tex_l.texture = mana_textures[current_mana_idx_left]
	if tex_r: tex_r.texture = mana_textures[current_mana_idx_right]
	if is_instance_valid(area_stanga): _update_mana_collision_pos(area_stanga, current_mana_idx_left, true)
	if is_instance_valid(area_dreapta): _update_mana_collision_pos(area_dreapta, current_mana_idx_right, false)
	_update_principal_slot_position(true)
	_update_principal_slot_position(false)

func _can_drop_data(_at_position, data):
	return is_instance_valid(data) and data is Slot

# Funcție helper care verifică dacă un punct (mouse) este peste mână (folosind Area2D sau TextureRect)
func _is_point_in_hand(pos: Vector2, is_left: bool) -> bool:
	var area = area_stanga if is_left else area_dreapta
	if is_instance_valid(area):
		return _is_point_in_collision(area, pos)
	
	# Fallback la rect-ul TextureRect dacă Area2D lipsește (cazul Jake)
	var hand = null
	if is_left and control_left: hand = control_left.get_node_or_null("mana_stanga")
	elif not is_left and control_right: hand = control_right.get_node_or_null("mana_dreapta")
	
	if is_instance_valid(hand):
		return hand.get_global_rect().has_point(pos)
	
	return false

func _drop_data(_at_position, data):
	if is_enemy: return # Playerul nu poate pune iteme pe mâinile inamicului

	if not is_instance_valid(data) or not (data is Slot):
		return

	var mouse_pos = get_global_mouse_position()
	var item_types = data.get_type()
	var is_weapon = "weapon" in item_types
	
	# Drop pe mana stanga
	if _is_point_in_hand(mouse_pos, true):
		# Prioritate slot principal
		if is_instance_valid(main_item_1) and not main_item_1.filled:
			main_item_1.set_property(data.property)
			data.clear_item()
			return
			
		if is_weapon:
			print("Armele nu pot fi puse in sloturi secundare!")
			return
			
		for slot in sub_slots_left:
			if is_instance_valid(slot) and not slot.filled:
				slot.set_property(data.property)
				data.clear_item()
				if panel_left: panel_left.visible = true
				return
			
	# Drop pe mana dreapta
	elif _is_point_in_hand(mouse_pos, false):
		# Prioritate slot principal
		if is_instance_valid(main_item_2) and not main_item_2.filled:
			main_item_2.set_property(data.property)
			data.clear_item()
			return
			
		if is_weapon:
			print("Armele nu pot fi puse in sloturi secundare!")
			return
			
		for slot in sub_slots_right:
			if is_instance_valid(slot) and not slot.filled:
				slot.set_property(data.property)
				data.clear_item()
				if panel_right: panel_right.visible = true
				return

# Obținem centrul real (pivotul) în spațiu global.
func _get_control_center(control: Control) -> Vector2:
	if not is_instance_valid(control): return Vector2.ZERO
	# Deoarece controlul este într-un container care îi gestionează poziția, 
	# global_position + pivot_offset ne dă centrul fix în spațiul ecranului.
	return control.global_position + control.pivot_offset

func _check_synergies(delta: float):
	if not control_left or not control_right or not area_stanga or not area_dreapta: return
	
	# Centrele bazate pe pivot sunt imune la animația de breathing
	var center_l = _get_control_center(control_left)
	var center_r = _get_control_center(control_right)
	var current_midpoint = (center_l + center_r) / 2.0
	
	var tex_left = area_stanga.get_parent() as TextureRect
	var tex_right = area_dreapta.get_parent() as TextureRect
	
	# --- 1. Condiții Sinergie ---
	var cond_1_types = (current_mana_idx_left == 3 and current_mana_idx_right == 0)
	var dist_x_1 = abs(center_l.x - center_r.x)
	var left_above_1 = center_l.y < (center_r.y + 120.0)
	var synergy_1_met = cond_1_types and dist_x_1 < 250.0 and left_above_1
	
	var cond_2_types = (current_mana_idx_left == 5 and current_mana_idx_right == 5)
	var dist_total = center_l.distance_to(center_r)
	var left_h = tex_left
	var right_v = tex_right.flip_v if tex_right else false
	var synergy_2_met = cond_2_types and dist_total < 320.0 and left_h and right_v
	
	var cond_3_types = (current_mana_idx_left == 0 and current_mana_idx_right == 3)
	var dist_x_3 = abs(center_l.x - center_r.x)
	var left_below_3 = center_l.y > (center_r.y - 120.0)
	var synergy_3_met = cond_3_types and dist_x_3 < 250.0 and left_below_3
	
	var any_synergy = synergy_1_met or synergy_2_met or synergy_3_met
	
	if any_synergy:
		synergy_timer = SYNERGY_TIMEOUT
		
		# Calculăm poziția țintă (mijlocul curent + offset vertical)
		var target_pos = current_midpoint
		if synergy_1_met or synergy_3_met:
			target_pos += Vector2(-180, -60)
		elif synergy_2_met:
			target_pos += Vector2(-170, -60)
			
		if synergy_slot == null:
			_spawn_synergy_slot()
			# SNAP INSTANT: La spawn, poziționăm direct fără lerp
			synergy_slot.global_position = target_pos
		else:
			# Urmărire fluidă a mâinilor în timpul mișcării (dragging)
			synergy_slot.global_position = synergy_slot.global_position.lerp(target_pos, delta * 8.0)
			synergy_slot.scale = synergy_slot.scale.lerp(Vector2(1.5, 1.5), delta * 4.0)
			
			# Actualizăm conținutul panoului de detalii în timp real
			if not is_enemy:
				_update_synergy_panel_content()
		
		# Activăm animația de acumulare și o mărim
		if animated_sprite:
			if not animated_sprite.visible:
				animated_sprite.visible = true
				animated_sprite.top_level = true
				animated_sprite.z_index = 100

			if animated_sprite.animation != "acumulare" or not animated_sprite.is_playing():
				animated_sprite.play("acumulare")

			# Ajustăm poziția animației pentru a fi centrată pe slotul nou spawnat
			# target_pos este global, animated_sprite fiind top_level acceptă global_position direct
			animated_sprite.global_position = target_pos + Vector2(45, 45)
			animated_sprite.scale = Vector2(4.5, 4.5)
	else:
		if animated_sprite and animated_sprite.visible:
			_remove_synergy_slot()


func _spawn_synergy_slot():
	if synergy_slot != null: return
	synergy_slot = SLOT_SCENE.instantiate()
	var items_container = control_left.get_parent()
	if items_container:
		items_container.add_child(synergy_slot)
	
	synergy_slot.z_index = 5
	synergy_slot.modulate = Color(1.5, 1.5, 1.5)
	_set_slots_visibility(false)
	
	if not is_enemy:
		_show_synergy_detail_panel()

func _show_synergy_detail_panel():
	if synergy_detail_panel == null:
		synergy_detail_panel = Panel.new()
		synergy_detail_panel.name = "SynergyHypePanel"
		synergy_detail_panel.custom_minimum_size = Vector2(400, 230)
		synergy_detail_panel.size = Vector2(400, 230)
		
		var items_container = get_node_or_null("TextureRect/Panel/Items")
		if items_container:
			items_container.add_child(synergy_detail_panel)
		else:
			add_child(synergy_detail_panel)
			
		synergy_detail_panel.position = Vector2(size.x/2 - 200, -140)
		synergy_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		synergy_detail_panel.gui_input.connect(_on_panel_gui_input.bind(synergy_detail_panel))
		
		var mat = ShaderMaterial.new()
		mat.shader = load("res://Shaders/rainbow_border.gdshader")
		mat.set_shader_parameter("width", 0.015) 
		mat.set_shader_parameter("speed", 2.0)
		synergy_detail_panel.material = mat
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.GOLD
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_right = 10
		style.corner_radius_bottom_left = 10
		synergy_detail_panel.add_theme_stylebox_override("panel", style)
		
		synergy_detail_panel.z_index = 200
		synergy_detail_panel.pivot_offset = synergy_detail_panel.size / 2
		
		var title = RichTextLabel.new()
		title.name = "Title"
		title.bbcode_enabled = true
		title.custom_minimum_size = Vector2(280, 40)
		title.size = Vector2(280, 40)
		title.position = Vector2(110, 10)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.text = "[center][b][color=gold]SINERGIE ACTIVĂ![/color][/b][/center]"
		synergy_detail_panel.add_child(title)
		
		var desc = RichTextLabel.new()
		desc.name = "Desc"
		desc.bbcode_enabled = true
		desc.custom_minimum_size = Vector2(280, 170)
		desc.size = Vector2(280, 170)
		desc.position = Vector2(110, 50)
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc.text = "[center][color=cyan]Slot deblocat[/color][/center]"
		synergy_detail_panel.add_child(desc)
		
		var d_slot = SLOT_SCENE.instantiate()
		d_slot.name = "DisplaySlot"
		synergy_detail_panel.add_child(d_slot)
		d_slot.position = Vector2(20, 20)
		d_slot.scale = Vector2(1.2, 1.2)
		d_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	synergy_detail_panel.visible = true
	_update_synergy_panel_content()
	
	synergy_detail_panel.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(synergy_detail_panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_synergy_panel_content():
	if not is_instance_valid(synergy_detail_panel) or not synergy_detail_panel.visible: return
	
	var d_title = synergy_detail_panel.get_node_or_null("Title")
	var d_label = synergy_detail_panel.get_node_or_null("Desc")
	var d_slot = synergy_detail_panel.get_node_or_null("DisplaySlot")
	
	if is_instance_valid(synergy_slot) and synergy_slot.filled:
		#if d_title: d_title.text = "[center][b][color=gold]" + synergy_slot.get_nume() + "[/color][/b][/center]"
		if d_slot: 
			d_slot.set_property(synergy_slot.property)
			d_slot.description = d_label # Setăm ținta pentru descriere
			d_slot.update_description()   # Populăm d_label cu descrierea completă
	else:
		if d_title: d_title.text = "[center][b][color=gold]SINERGIE ACTIVĂ![/color][/b][/center]"
		if d_label: d_label.text = "[center][color=cyan]Slot deblocat[/color][/center]"
		if d_slot: d_slot.clear_item()

func _remove_synergy_slot():
	if synergy_slot:
		synergy_slot.queue_free()
		synergy_slot = null
	
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.top_level = false
		animated_sprite.stop()
	
	if synergy_detail_panel:
		synergy_detail_panel.visible = false
	
	_set_slots_visibility(true)


func _set_slots_visibility(is_visible: bool):
	# combat_slots conține main_item_1, 2 și slot_3..8
	for slot in combat_slots:
		if is_instance_valid(slot):
			slot.visible = is_visible
			# De asemenea, dezactivăm procesarea lor pentru a nu interfera
			slot.set_process(is_visible)

func _update_floating_animation(delta: float):
	float_time += delta
	
	# --- 1. Parametri Animație ---
	var breathe_speed = 1.4
	var rot_amp = 1.8       # Rotație maximă în grade
	var stretch_amp = 0.02  # Cât de mult se "întinde" (2%)
	var float_amp = 6.0     # Amplitudinea plutirii itemelor
	
	# --- 2. Animație Mâna Stângă (Control) ---
	if is_instance_valid(control_left):
		# Setăm pivotul în centru pentru o rotație naturală
		control_left.pivot_offset = control_left.size / 2
		
		# Rotație sinusoidală
		control_left.rotation_degrees = sin(float_time * breathe_speed) * rot_amp
		
		# Squash & Stretch (când se lungește pe Y, se îngustează pe X)
		var s_offset = sin(float_time * breathe_speed * 1.2) * stretch_amp
		control_left.scale.x = 1.0 - s_offset
		control_left.scale.y = 1.0 + s_offset
		
	# --- 3. Animație Mâna Dreaptă (Control) ---
	if is_instance_valid(control_right):
		control_right.pivot_offset = control_right.size / 2
		
		# Adăugăm un defazaj (offset de timp) pentru a nu se mișca identic cu stânga
		var phase_shift = 0.7
		control_right.rotation_degrees = sin((float_time + phase_shift) * breathe_speed) * -rot_amp
		
		var s_offset_r = sin((float_time + phase_shift) * breathe_speed * 1.2) * stretch_amp
		control_right.scale.x = 1.0 - s_offset_r
		control_right.scale.y = 1.0 + s_offset_r

	# --- 4. Plutire Sloturi Principale (Independente) ---
	if is_instance_valid(main_item_1):
		# Plutire ușor mai rapidă decât respirația pentru contrast
		main_item_1.position.y = original_pos_1.y + sin(float_time * 2.0) * float_amp
		
	if is_instance_valid(main_item_2):
		main_item_2.position.y = original_pos_2.y + sin((float_time + 1.2) * 2.0) * float_amp

func _update_dynamic_slots(delta: float):
	# Mișcăm sloturile secundare cu un efect de "lag" față de mână
	var target_slots = sub_slots_left + sub_slots_right
	var lerp_speed = 10.0 # Viteza de revenire la locul lor
	
	for s in target_slots:
		if is_instance_valid(s) and sub_rest_positions.has(s):
			# Dacă tragem de mână, adăugăm un pic de offset dinamic (opțional, aici doar lerp pentru smooth)
			s.position = s.position.lerp(sub_rest_positions[s], delta * lerp_speed)

func _input(event):
	if event is InputEventMouseButton:
		var mouse_pos = get_global_mouse_position()
		
		# Logica pentru Click Stânga (Dragging)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Jucătorul poate trage de mâini DOAR dacă nu este inamic
				if not is_enemy:
					if _is_point_in_hand(mouse_pos, true):
						dragging_node = control_left
						drag_offset = mouse_pos - control_left.global_position
					elif _is_point_in_hand(mouse_pos, false):
						dragging_node = control_right
						drag_offset = mouse_pos - control_right.global_position
			else:
				dragging_node = null
		
		# Logica pentru Click Dreapta (Schimbare Textură) - Doar pentru Player
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not is_enemy:
			if _is_point_in_hand(mouse_pos, true):
				current_mana_idx_left = (current_mana_idx_left + 1) % mana_textures.size()
				var tex_rect = area_stanga.get_parent() if is_instance_valid(area_stanga) else control_left.get_node_or_null("mana_stanga")
				if tex_rect: tex_rect.texture = mana_textures[current_mana_idx_left]
				if is_instance_valid(area_stanga): _update_mana_collision_pos(area_stanga, current_mana_idx_left, true)
				_update_principal_slot_position(true)
				
			elif _is_point_in_hand(mouse_pos, false):
				current_mana_idx_right = (current_mana_idx_right + 1) % mana_textures.size()
				var tex_rect = area_dreapta.get_parent() if is_instance_valid(area_dreapta) else control_right.get_node_or_null("mana_dreapta")
				if tex_rect: tex_rect.texture = mana_textures[current_mana_idx_right]
				if is_instance_valid(area_dreapta): _update_mana_collision_pos(area_dreapta, current_mana_idx_right, false)
				_update_principal_slot_position(false)
		
		# Logica pentru Rotita Mouse (Flip V) - Doar pentru Player
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and not is_enemy:
			if _is_point_in_hand(mouse_pos, true):
				var tex_rect = area_stanga.get_parent() if is_instance_valid(area_stanga) else control_left.get_node_or_null("mana_stanga")
				if tex_rect: 
					tex_rect.flip_v = !tex_rect.flip_v
					_update_principal_slot_position(true)
			elif _is_point_in_hand(mouse_pos, false):
				var tex_rect = area_dreapta.get_parent() if is_instance_valid(area_dreapta) else control_right.get_node_or_null("mana_dreapta")
				if tex_rect: 
					tex_rect.flip_v = !tex_rect.flip_v
					_update_principal_slot_position(false)
			
	if dragging_node and event is InputEventMouseMotion and not is_enemy:
		# Efect de inerție (inertia): sloturile secundare "rămân în urmă"
		var velocity = event.relative * 0.2
		var target_subs = sub_slots_left if dragging_node == control_left else sub_slots_right
		for s in target_subs:
			if is_instance_valid(s):
				s.position -= velocity
		
		var new_pos = event.global_position - drag_offset
		var card_rect = get_global_rect()
		
		# Folosim pivotul (centrul mâinii) pentru a limita mișcarea
		var pivot_global_pos = new_pos + dragging_node.pivot_offset
		
		pivot_global_pos.x = clamp(pivot_global_pos.x, card_rect.position.x+200, card_rect.end.x+50)
		pivot_global_pos.y = clamp(pivot_global_pos.y, card_rect.position.y+150, card_rect.end.y+200)
		
		dragging_node.global_position = pivot_global_pos - dragging_node.pivot_offset

# Funcție helper care verifică dacă un punct (mouse) este în interiorul formei de coliziune
func _is_point_in_collision(area: Area2D, pos: Vector2) -> bool:
	if not is_instance_valid(area): return false
	
	for child in area.get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is CircleShape2D:
				# Calculăm distanța dintre mouse și centrul global al coliziunii
				var dist = pos.distance_to(child.global_position)
				if dist <= child.shape.radius:
					return true
			elif child.shape is RectangleShape2D:
				# Verificare pentru dreptunghi dacă vei schimba forma ulterior
				var local_pos = child.to_local(pos)
				var rect = Rect2(-child.shape.size / 2, child.shape.size)
				if rect.has_point(local_pos):
					return true
	return false

func _connect_combat_slots():
	for slot in combat_slots:
		if is_instance_valid(slot):
			if not slot.slot_selected.is_connected(_on_combat_slot_selected):
				slot.slot_selected.connect(_on_combat_slot_selected)

func _on_combat_slot_selected(slot):
	# When a slot is clicked, we might want to show its specific abilities or just highlight it
	print("Combat slot selected: ", slot.get_nume())
	
	if slot.has_method("update_description"):
		slot.update_description()
	
	# Determine if this slot belongs to the first group (Attack) or second group (Defense)
	var first_group = [main_item_1, slot_3, slot_4, slot_5]


func fill_combat_slots(items_array: Array):
	# Clear all slots first
	for slot in combat_slots:
		if is_instance_valid(slot) and slot.has_method("clear_item"):
			slot.clear_item()
	
	# Fill them
	for i in range(min(items_array.size(), combat_slots.size())):
		var item = items_array[i]
		var slot = combat_slots[i]
		if is_instance_valid(slot) and slot.has_method("add_item"):
			slot.add_item(
				item.get("id", "0"),
				item.get("qty", 1),
				#item.get("curse", null),
				#item.get("effects", [])
			)



func _format_move_name(m: Dictionary) -> String:
	var nm := String(m.get("name", "-"))
	var lane := String(m.get("lane", "mid")).to_upper()
	var t := String(m.get("type", "attack")).to_lower()
	if t == "attack":
		nm += " [%s] (P%d)" % [lane, int(m.get("power", 0))]
	else:
		nm += " [%s] (B%d)" % [lane, int(m.get("block", 0))]
	return nm



func set_visuals(char_tex: Texture2D, bg_tex: Texture2D):
	if char_tex and texture_bg:
		texture_bg.texture = char_tex
	if bg_tex and texture_bg:
		var parent = texture_bg.get_parent()
		if parent:
			var bg_node = parent.get_child(0)
			if bg_node is TextureRect:
				bg_node.texture = bg_tex

func setup(id_primit, nume_primit: String, hp_maxim: int, hp_curent: int):
	character_id = id_primit
	max_hp = hp_maxim
	current_hp = hp_curent
	if name_label:
		name_label.text = "[center]" + nume_primit + "[/center]" 
	_update_ui_elements()
	self.modulate = Color.WHITE

func update_hp(new_hp: int):
	var old_hp = current_hp
	current_hp = new_hp
	current_hp = clamp(current_hp, 0, max_hp)
	_update_ui_elements()
	if current_hp < old_hp:
		play_animation("hit")
	elif current_hp > old_hp:
		play_animation("heal")
	if current_hp <= 0:
		_on_death()

func _update_ui_elements():
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	if health_text:
		health_text.text = str(current_hp) + " / " + str(max_hp)

func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	elif animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)

func _on_death():
	play_animation("dead")
	emit_signal("character_died", self)
	self.modulate = Color(0.5, 0.5, 0.5, 0.8)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_clicked", self)

func equip_item(_tex: Texture2D, _nume: String, _raritate: String):
	if inv_panel and inv_panel.selected_slot:
		var id = inv_panel.selected_slot.get_id()


func animate_action_visual(item_id: String, mode: String):
	if not inv_panel: return
	var float_icon = TextureRect.new()
	inv_panel.add_child(float_icon)
	var tex_path = ItemData.get_texture(item_id)
	if tex_path == null or tex_path == "":
		float_icon.queue_free()
		return
	var tex = load("res://assets/" + tex_path)
	if not tex:
		float_icon.queue_free()
		return
	float_icon.texture = tex
	float_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	float_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	float_icon.custom_minimum_size = Vector2(40, 40)
	float_icon.size = Vector2(40, 40)
	float_icon.visible = true
	float_icon.modulate = Color.WHITE
	float_icon.pivot_offset = float_icon.size / 2
	float_icon.global_position = inv_panel.global_position + (inv_panel.size / 2) - (float_icon.size / 2)
	float_icon.z_index = 10
	var tween = create_tween()
	if mode == "eat":
		tween.set_parallel(true)
		tween.tween_property(float_icon, "global_position:y", float_icon.global_position.y - 60, 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(float_icon, "modulate:a", 0.0, 1.0)
	elif mode == "equip":
		tween.tween_property(float_icon, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.3)
		tween.tween_property(float_icon, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(float_icon.queue_free)
