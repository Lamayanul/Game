extends PanelContainer

@onready var title_bar: Control = $VBoxContainer/TitleBar
@onready var close_btn: Button = $VBoxContainer/TitleBar/TextureRect/CloseBtn
#@onready var content: Control = $VBoxContainer/Content
@export var min_size_px := Vector2(180, 120)
@export var max_size_px := Vector2(1600, 1000)
@export var edge_thickness := 8.0
@onready var title: Label = $VBoxContainer/TitleBar/TextureRect/Title
@onready var pc = self.get_parent()
@export var type_tab=""
@export var slot_tab: PackedScene = preload("res://User/slot_container.tscn")
@export var window_title := "Tab"
@export var window_icon: Texture2D
@onready var ecran = self.get_parent().get_node("CanvasLayer/TextureRect2")
@onready var taskbar = self.get_parent().get_node("TaskBar")

@export var pad_left  := 0.0
@export var pad_top   := 0.0
@export var pad_right := 0.0
@export var pad_bottom:= 0.0  # spațiul „rezervat” jos

var dragging := false
var resizing := false
var resize_dir := Vector2.ZERO
var drag_offset := Vector2.ZERO

func setup_from_item(payload: Dictionary) -> void:
	# personalizează UI în funcție de itemul care a deschis tabul
	if payload.has("NUME"):
		$VBoxContainer/TitleBar/TextureRect/Title.text = "%s" % [payload["NUME"]]
		
func minimize() -> void:
	# trimite în taskbar și ascunde
	#if Engine.has_singleton("Taskbar"):
		#var tb = Engine.get_singleton("Taskbar") # dacă e autoload
		#tb.add_window(self, self.find_child("Title").text, window_icon)
	#else:
		# sau daca e o referință globală gen `Taskbar`, folosește direct:
	Taskbar.mini_tab(self, self.find_child("Title").text, window_icon)
	visible = false
	

func _ready():
	pc.storage.connect(_on_scan_slot_transmit)
	close_btn.pressed.connect(_on_close_pressed)
	title_bar.gui_input.connect(_on_titlebar_gui_input)
	gui_input.connect(_on_gui_input)

	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

	# important: re-încadrează la schimbarea rezoluției / monitorului
	get_viewport().size_changed.connect(_on_viewport_resized)
	# și chiar acum, după ce layout-ul inițial s-a stabilit
	call_deferred("_on_viewport_resized")
	print("ecran",ecran.name)
	if is_instance_valid(ecran) and ecran is Control:
		(ecran as Control).resized.connect(_on_viewport_resized)
	if is_instance_valid(taskbar) and taskbar is Control:
		(taskbar as Control).resized.connect(_on_viewport_resized)
		(taskbar as Control).visibility_changed.connect(_on_viewport_resized)
	call_deferred("_on_viewport_resized")


func _on_close_pressed():
	visible = false
	Taskbar.remove_tab(self)


func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		if type_tab!="notification":
			minimize()
		else:
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			# Offset între poziția tab-ului și mouse (în coordonate globale)
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		# Mută tab-ul după mouse, păstrând offset-ul
		global_position = get_global_mouse_position() - _drag_offset
		# (Opțional) limitează în interiorul ecranului:
		_clamp_inside_viewport()

func _viewport_bounds_rect() -> Rect2:
	# bounds = ecran (TextureRect2) minus padding și minus taskbar-ul de jos
	var r := Rect2(Vector2.ZERO, get_viewport_rect().size)
	if is_instance_valid(ecran) and ecran is Control:
		r = (ecran as Control).get_global_rect()

	# padding manual (opțional)
	r.position.x += pad_left
	r.position.y += pad_top
	r.size.x -= (pad_left + pad_right)

	# scade din înălțime ce ocupă taskbar-ul (doar dacă se suprapune pe X)
	if is_instance_valid(taskbar) and taskbar is Control:
		var tb := (taskbar as Control).get_global_rect()
		var x_overlap = max(0.0, min(r.position.x + r.size.x, tb.position.x + tb.size.x) - max(r.position.x, tb.position.x))
		if x_overlap > 0.0:
			var cut_bottom = clamp((r.position.y + r.size.y) - tb.position.y, 0.0, r.size.y)
			r.size.y -= cut_bottom  # „ridică” podeaua bounds-ului până la taskbar
	# după ce am scăzut taskbar-ul, mai aplicăm pad_bottom dacă vrei extra spațiu
	r.size.y -= pad_bottom
	return r

func _on_viewport_resized() -> void:
	# taie dimensiunea dacă depășește ecranul curent
	var b := _viewport_bounds_rect()
	var new_size := size
	new_size.x = clamp(new_size.x, min_size_px.x, min(max_size_px.x, b.size.x))
	new_size.y = clamp(new_size.y, min_size_px.y, min(max_size_px.y, b.size.y))
	size = new_size
	# apoi asigură poziția în interior
	_clamp_inside_viewport()
	#set_bottom_margin(0)
#
#func _on_bounds_changed() -> void:
	#var b := _viewport_bounds_rect()
	#var s := size
	#s.x = clamp(s.x, min_size_px.x, min(max_size_px.x, b.size.x))
	#s.y = clamp(s.y, min_size_px.y, min(max_size_px.y, b.size.y))
	#size = s
	#_clamp_inside_viewport()



func _clamp_inside_viewport() -> void:
	var bounds := _viewport_bounds_rect()
	var new_pos := global_position
	new_pos.x = clamp(new_pos.x, bounds.position.x, bounds.position.x + bounds.size.x - size.x)
	new_pos.y = clamp(new_pos.y, bounds.position.y, bounds.position.y + bounds.size.y - size.y-20)
	global_position = new_pos

func _on_gui_input(event: InputEvent) -> void:
	if dragging:
		var b := _viewport_bounds_rect()
		var p := get_global_mouse_position() - drag_offset
		p.x = clamp(p.x, b.position.x, b.position.x + b.size.x - size.x)
		p.y = clamp(p.y, b.position.y, b.position.y + b.size.y - size.y)
		global_position = p
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			move_to_front()  # Godot 4 replacement for raise()
			var local := get_local_mouse_position()  # for Control in Godot 4
			var edge := _edge_hit(local)
			if edge != Vector2.ZERO:
				resizing = true
				resize_dir = edge
			elif title_bar.get_rect().has_point(local):
				dragging = true
				drag_offset = local
		else:
			dragging = false
			resizing = false
			resize_dir = Vector2.ZERO

	elif event is InputEventMouseMotion:
		var local := get_local_mouse_position()

		# resize cursors
		#if not dragging and not resizing:
			#_update_cursor(local)

		# drag
		if dragging:
			var vp := get_viewport_rect().size
			position = (get_global_mouse_position() - drag_offset).clamp(Vector2.ZERO, vp - size)

		# resize
		if resizing:
			_do_resize(local)

#func set_bottom_margin(px: float) -> void:
	#pad_bottom = max(0.0, px)
	#_on_bounds_changed()  

func _edge_hit(local: Vector2) -> Vector2:
	var right  := local.x >= size.x - edge_thickness
	var bottom := local.y >= size.y - edge_thickness


	if right and bottom:
		return Vector2(1, 1)   # colț dreapta-jos
	elif right:
		return Vector2(1, 0)   # marginea dreaptă
	elif bottom:
		return Vector2(0, 1)   # marginea de jos
	return Vector2.ZERO        # toate celelalte margini sunt dezactivate



#func _update_cursor(local: Vector2) -> void:
	#var e := _edge_hit(local)
	#if e.x != 0 and e.y != 0:
		#Input.set_default_cursor_shape(
			#Input.CURSOR_FDIAGSIZE if e == Vector2(1,1) or e == Vector2(-1,-1)
			#else Input.CURSOR_BDIAGSIZE
		#)
	#elif e.x != 0:
		#Input.set_default_cursor_shape(Input.CURSOR_HSIZE)
	#elif e.y != 0:
		#Input.set_default_cursor_shape(Input.CURSOR_VSIZE)
	#else:
		#Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _do_resize(local: Vector2) -> void:
	var new_pos := position
	var new_size := size

	# -- calculează propunerea de resize --
	# left/right
	if resize_dir.x < 0:
		var dx = clamp(local.x, 0.0, new_size.x - min_size_px.x)
		new_pos.x += dx
		new_size.x -= dx
	elif resize_dir.x > 0:
		new_size.x = clamp(local.x, min_size_px.x, max_size_px.x)

	# top/bottom
	if resize_dir.y < 0:
		var dy = clamp(local.y, 0.0, new_size.y - min_size_px.y)
		new_pos.y += dy
		new_size.y -= dy
	elif resize_dir.y > 0:
		new_size.y = clamp(local.y, min_size_px.y, max_size_px.y)

	# -- aplică limitele viewportului (aceleași ca la drag) --
	var bounds := _viewport_bounds_rect()

	# Nu lăsa poziția să urce peste stânga/susul bounds
	new_pos.x = max(new_pos.x, bounds.position.x)
	new_pos.y = max(new_pos.y, bounds.position.y)

	# Nu lăsa dimensiunile să depășească bounds la dreapta/jos
	var max_w := bounds.position.x + bounds.size.x - new_pos.x
	var max_h := bounds.position.y + bounds.size.y - new_pos.y

	new_size.x = clamp(new_size.x, min_size_px.x, min(max_size_px.x, max_w))
	new_size.y = clamp(new_size.y, min_size_px.y, min(max_size_px.y, max_h-20))

	position = new_pos
	size = new_size




var _dragging := false
var _drag_offset := Vector2.ZERO

func _on_scan_slot_transmit(data):
	if type_tab=="storage":
		var slot = slot_tab.instantiate()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size = slot.custom_minimum_size
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
		slot.scop="tab"
		$VBoxContainer/Content.add_child(slot)   
		slot.get_node("TextureHolder/TextureRect2").texture=null 
		slot.slot_type="tray"
		slot.set_property(data)
		


func _on_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			accept_event() # oprește comportamentul default (nu mai adaugă rând nou)
