extends Control

@export var button_scene: PackedScene        # scena cu butonul tău
@export var button_count: int = 10            # câte instanțe pui pe bandă
@export var speed_angular: float = 0.3       # viteză mai lentă (radiani/s)
@export var radius_scale: Vector2 = Vector2(100.0, 0.4) # relativ la mărime
@export var orbit_radius: Vector2 = Vector2.ZERO   # lungime/înălțime absolută în pixeli (dacă e > 0, ignoră scale)
@export var orbit_offset: Vector2 = Vector2.ZERO # deplasare manuală a centrului
@export var hide_back_delay: float = 115.0          # secunde până dispare în spate
@export var enable_back_hiding: bool = true       # activează/dezactivează dispariția
@export var use_clip: bool = false            # de obicei la cerc nu vrei clip dacă ies butoanele
@export var button_names: PackedStringArray = []   # numele dorite (opțional)
@export var cycle_names: bool = true               # dacă sunt mai puține nume decât butoane, se ciclizează

var _buttons: Array[Control] = []
var _time: float = 0.0
var _back_timers: Array[float] = []
var _initial_z_index: int = 0

func _ready() -> void:
	clip_contents = use_clip
	mouse_filter = Control.MOUSE_FILTER_PASS
	_back_timers.resize(button_count)
	_back_timers.fill(0.0)

	if button_scene == null:
		push_error("Setează 'button_scene' în Inspector!")
		return
	apply_names(["Visa", "Mastercard", "Amex"])
	# instanțiază și denumește
	for i in button_count:
		var b := button_scene.instantiate() as Control
		add_child(b)
		_buttons.append(b)
		_set_button_text_for(b, _name_for(i))
		if i == 0:
			_initial_z_index = b.z_index

func _process(delta: float) -> void:
	if _buttons.is_empty():
		return

	_time += delta
	var center = (size / 2.0) + orbit_offset

	# Dacă radius este între 0 și 1, îl tratăm ca procent din size (0.5 = 50%)
	# Dacă este > 1, îl tratăm ca pixeli absoluți.
	var rx = 0.0
	if orbit_radius.x > 0:
		rx = (size.x / 2.0) * orbit_radius.x if orbit_radius.x <= 1.0 else orbit_radius.x
	else:
		rx = (size.x / 2.0) * radius_scale.x

	var ry = 0.0
	if orbit_radius.y > 0:
		ry = (size.y / 2.0) * orbit_radius.y if orbit_radius.y <= 1.0 else orbit_radius.y
	else:
		ry = (size.y / 2.0) * radius_scale.y
	var total = _buttons.size()
	for i in total:
		var b = _buttons[i]
		var angle = (float(i) / total) * TAU + _time * speed_angular
		angle = fposmod(angle, TAU) # Normalizăm unghiul între 0 și TAU
		
		var target_x = center.x + cos(angle) * rx
		var target_y = center.y + sin(angle) * ry
		
		b.position = Vector2(target_x, target_y) - b.size / 2.0
		
		var sin_a = sin(angle)
		var is_front = sin_a > 0
		var depth = (sin_a + 1.0) / 2.0
		
		b.scale = Vector2.ONE * lerp(0.7, 1.0, depth)
		b.modulate.a = lerp(0.5, 1.0, depth)
		
		# Z-index: 0 (față) sau -1 (spate) relativ la _initial_z_index
		b.z_index = _initial_z_index if is_front else _initial_z_index - 1
		
		# Logica de dispariție
		if enable_back_hiding:
			if not is_front:
				_back_timers[i] += delta
				if _back_timers[i] >= hide_back_delay:
					b.visible = false
				else:
					b.visible = true # Încă în delay, rămâne vizibil
			else:
				_back_timers[i] = 0.0
				b.visible = true
		else:
			b.visible = true # Dacă feature-ul e oprit, forțăm vizibilitatea
				

func _name_for(i: int) -> String:
	if button_names.is_empty():
		return "Buton %d" % (i + 1)
	if i < button_names.size():
		return button_names[i]
	return button_names[i % button_names.size()] if cycle_names else "Buton %d" % (i + 1)

func _set_button_text_for(node: Node, text: String) -> void:
	var target := _find_button_or_label(node)
	if target is Button:
		(target as Button).text = text
	elif target is Label:
		(target as Label).text = text

func _find_button_or_label(n: Node) -> Node:
	if n is Button or n is Label:
		return n
	for c in n.get_children():
		var found := _find_button_or_label(c)
		if found != null:
			return found
	return null

# Poți schimba numele la runtime:
func apply_names(names: PackedStringArray) -> void:
	button_names = names.duplicate()
	for i in _buttons.size():
		_set_button_text_for(_buttons[i], _name_for(i))
