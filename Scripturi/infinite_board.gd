extends Control

var panning = false
var last_mouse_pos = Vector2.ZERO
var current_offset = Vector2.ZERO

# --- ZOOM CONFIG ---
var min_zoom = 0.3
var max_zoom = 2.0
var zoom_speed = 0.1
var current_zoom = 1.0

@onready var background = $background_tex
@onready var icons_container = $board

func _ready():
	# Asigurăm că fundalul are shader-ul setat
	if background and background.material == null:
		var mat = ShaderMaterial.new()
		mat.shader = load("res://Shaders/tiled_background.gdshader")
		background.material = mat
	
	# Acest nod (BoardViewport) va prinde tot input-ul de panning
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		# PANNING
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				panning = true
				last_mouse_pos = get_global_mouse_position()
			else:
				panning = false
		
		# ZOOM
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(zoom_speed, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-zoom_speed, event.position)
	
	if event is InputEventMouseMotion and panning:
		var delta = get_global_mouse_position() - last_mouse_pos
		current_offset += delta
		
		# Mișcăm containerul de iconițe
		if icons_container:
			icons_container.position += delta
		
		_update_background_shader()
		last_mouse_pos = get_global_mouse_position()

func _adjust_zoom(delta: float, mouse_pos: Vector2):
	var old_zoom = current_zoom
	current_zoom = clamp(current_zoom + delta, min_zoom, max_zoom)
	
	if icons_container:
		# Zoom spre poziția mouse-ului
		var zoom_factor = current_zoom / old_zoom
		icons_container.scale = Vector2(current_zoom, current_zoom)
		
		# Ajustăm poziția pentru a menține punctul de sub mouse fix
		icons_container.position = mouse_pos + (icons_container.position - mouse_pos) * zoom_factor
	
	_update_background_shader()

func _update_background_shader():
	if background and background.material:
		var tex = background.texture
		if tex:
			var tex_size = tex.get_size()
			# Offset-ul trebuie ajustat și cu zoom-ul pentru a rămâne aliniat
			var shader_offset = -icons_container.position / (tex_size * current_zoom)
			background.material.set_shader_parameter("offset", shader_offset)
			background.material.set_shader_parameter("zoom", 1.0 / current_zoom)
