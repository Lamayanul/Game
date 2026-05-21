extends Control
class_name CardControl
@export var card_size := Vector2(600,340)
@export var hover_scale := 1.1
@export var hover_duration := 0.12
@export var raise_z_on_hover := true



@onready var panel: PanelContainer = $PanelContainer
@onready var tex_front: TextureRect = $PanelContainer/TextureRect
@onready var tex_back:  TextureRect = $PanelContainer/TextureRect2
var base_global_pos := Vector2.ZERO
@onready var scroll_container: ScrollContainer = $"../.."
var base_scale := 1.0 # <-- 1. ADAUGĂ ACEASTĂ LINIE
var is_in_drop_area := false
var _tw: Tween

var coupon_data: Dictionary = {}

func set_coupon_data(data: Dictionary):
	coupon_data = data
	if tex_front:
		tex_front.texture = data.get("TEXTURE")
	
	var label = get_node_or_null("PanelContainer/Label")
	if label:
		var qty = data.get("CANTITATE", 0)
		if qty > 0:
			label.text = str(qty)
		else:
			label.text = ""

func get_coupon_data() -> Dictionary:
	return coupon_data

func _ready() -> void:
	
	# Lasă ScrollContainer să primeacă rotița
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Copilul vizual nu trebuie să consume input
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Dimensiune stabilă pentru HBox
	custom_minimum_size = card_size

	
	# Pivot pentru scalare la centru (după ce are mărimea finală)
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5

	# Hover
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	#set_big_step(150)
	
func _get_drag_data(at_position: Vector2) -> Variant:
	
	# 1. Creăm o previzualizare (un "preview")
	var preview = TextureRect.new()
	# Poți folosi ce textură vrei. O folosim pe cea a cardului.
	preview.texture = tex_front.texture 
	preview.expand_mode = 1 # Să-și păstreze mărimea
	preview.size = card_size * 0.5 # O facem mai mică pentru preview
	set_drag_preview(preview)
	
	# 2. Trimitem datele
	# Aici trimitem nodul "Card" însuși. 
	# Când vom face "drop", vom primi acest nod.
	return self
	
func _on_hover_in() -> void:
	if is_in_drop_area: return # Verificăm flag-ul
	_zoom_to(hover_scale) # Presupunem că scala de bază e 1
	if raise_z_on_hover:
		scroll_container.clip_contents=false
		z_index = 1

func _on_hover_out() -> void:
	if is_in_drop_area: return # Verificăm flag-ul
	_zoom_to(1.0)
	if raise_z_on_hover:
		scroll_container.clip_contents=true
		z_index = 0
func _zoom_to(f: float) -> void:
	if _tw and _tw.is_running():
		_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 4. MODIFICĂ ACEASTĂ LINIE (e subtilă)
	_tw.tween_property(panel, "scale", Vector2.ONE * f, hover_duration) # În loc de Vector2(f, f)

# ... (funcția ta _gui_input) ...
# ... (funcția ta _get_drag_data) ...

# 5. ADAUGĂ ACEASTĂ FUNCȚIE NOUĂ
# Aceasta ne permite să setăm noua scală din exterior
func set_base_scale(new_scale: float):
	if is_in_drop_area: return # Nu lăsa această funcție să ruleze
	base_scale = new_scale
	if _tw and _tw.is_running():
		_tw.kill()
	panel.scale = Vector2.ONE * base_scale

# Dublu-click pentru flip (nu blochează scroll-ul)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click and mb.pressed:
			tex_front.visible = not tex_front.visible
			tex_back.visible  = not tex_back.visible

func set_big_step(px: float = 150):
	var h = scroll_container.get_h_scroll_bar()
	h.step = px   # pasul la fiecare eveniment de scroll

func set_compact_mode(compact: bool, scale_factor: float = 0.2):
	is_in_drop_area = compact
	
	if _tw and _tw.is_running():
		_tw.kill()

	if compact:
		# 1. Micșorăm VIZUAL panoul intern
		panel.scale = Vector2.ONE * scale_factor
		
		# 2. Aliniem panoul la stânga-sus
		panel.pivot_offset = Vector2.ZERO 
		
		# 3. Calculăm noua înălțime VIZUALĂ
		var new_min_height = card_size.y * scale_factor
		
		# 4. Setăm mărimea MINIMĂ
		custom_minimum_size.y = new_min_height
		
		# 5. --- AICI E MODIFICAREA ---
		# Setăm pe PASS ca să putem iniția un nou drag
		mouse_filter = MOUSE_FILTER_PASS 
		z_index = 0
		
	else:
		# (Codul de restaurare)
		panel.scale = Vector2.ONE
		
		# Restaurăm înălțimea originală
		custom_minimum_size.y = card_size.y 
		
		mouse_filter = MOUSE_FILTER_PASS # Rămâne PASS
		
		# Așteptăm un frame
		await get_tree().process_frame 
		panel.pivot_offset = panel.size * 0.5
