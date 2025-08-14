extends PanelContainer

@onready var title_bar: Control = $VBoxContainer/TitleBar
@onready var close_btn: Button = $VBoxContainer/TitleBar/TextureRect/CloseBtn
@onready var content: Control = $VBoxContainer/Content
@export var min_size_px := Vector2(180, 120)
@export var max_size_px := Vector2(1600, 1000)
@export var edge_thickness := 8.0
@onready var title: Label = $VBoxContainer/TitleBar/TextureRect/Title


@export var window_title := "Tab"
@export var window_icon: Texture2D

const TASKBAR_H := 48.0
const MARGIN_LEFT  := 60.0
const MARGIN_TOP   := 65.0
const MARGIN_RIGHT := 467.0   # spațiul „rezervat” în dreapta
const MARGIN_BOTTOM:= 140.0    # spațiul „rezervat” jos

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
	close_btn.pressed.connect(_on_close_pressed)
	title_bar.gui_input.connect(_on_titlebar_gui_input)
	gui_input.connect(_on_gui_input)
	# Ca să prindă input doar titlebar-ul
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	# Cursor de “move” opțional
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE


func _on_close_pressed():
	visible = false
	Taskbar.remove_tab(self)


func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		minimize()
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
	var vp := get_viewport_rect().size
	var x0 := MARGIN_LEFT
	var y0 := MARGIN_TOP
	var x1 := vp.x - MARGIN_RIGHT
	var y1 := vp.y - MARGIN_BOTTOM
	return Rect2(Vector2(x0, y0), Vector2(max(0.0, x1 - x0), max(0.0, y1 - y0)))

func _clamp_inside_viewport() -> void:
	var bounds := _viewport_bounds_rect()
	var new_pos := global_position
	new_pos.x = clamp(new_pos.x, bounds.position.x, bounds.position.x + bounds.size.x - size.x)
	new_pos.y = clamp(new_pos.y, bounds.position.y, bounds.position.y + bounds.size.y - size.y)
	global_position = new_pos

func _on_gui_input(event: InputEvent) -> void:
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

func _edge_hit(local: Vector2) -> Vector2:
	var left   := local.x <= edge_thickness
	var right  := local.x >= size.x - edge_thickness
	var top    := local.y <= edge_thickness
	var bottom := local.y >= size.y - edge_thickness
	var dir := Vector2.ZERO
	if left:  dir.x = -1
	elif right: dir.x = 1
	if top:   dir.y = -1
	elif bottom: dir.y = 1
	return dir

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
	new_size.y = clamp(new_size.y, min_size_px.y, min(max_size_px.y, max_h))

	position = new_pos
	size = new_size




var _dragging := false
var _drag_offset := Vector2.ZERO
