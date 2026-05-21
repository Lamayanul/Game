extends Control

@onready var cable = $Cable
@onready var plug_in = $Plug
@onready var plug_out = $PlugOut

@export var max_cable_length: float = 400.0
@export var friction: float = 0.2
@export var push_force: float = 200.0
@export var restrict_above_limit: bool = true
@export var snap_distance: float = 40.0

var dragging_index: int = -1 # -1: none, 0: plug_in, 1: plug_out
var drag_offset: Vector2 = Vector2.ZERO

var velocities: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var connected_sockets: Array = [null, null]
var is_connected: Array[bool] = [false, false]

signal power_connected(index: int, state: bool)

func _ready():
	plug_in.mouse_filter = Control.MOUSE_FILTER_STOP
	plug_out.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Excludem coliziunea dintre ștecher și propriul cablu pentru a permite tragerea lor
	var body_in = plug_in.get_node_or_null("CharacterBody2D")
	if body_in and cable_collision:
		body_in.add_collision_exception_with(cable_collision)
		
	var body_out = plug_out.get_node_or_null("CharacterBody2D")
	if body_out and cable_collision:
		body_out.add_collision_exception_with(cable_collision)
		
	update_cable()

var last_click_time: float = 0.0
var double_click_threshold: float = 0.3 # secunde
var is_recovering: Array[bool] = [false, false]

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var current_time = Time.get_ticks_msec() / 1000.0
				var is_double_click = (current_time - last_click_time) < double_click_threshold
				last_click_time = current_time
				
				var plugs = [plug_in, plug_out]
				for i in range(2):
					var p = plugs[i]
					var p_trans = p.get_global_transform()
					var local_mouse = p_trans.affine_inverse() * get_global_mouse_position()
					var p_rect = Rect2(Vector2.ZERO, p.size)
					
					if p_rect.has_point(local_mouse):
						if is_double_click:
							_start_collision_recovery(i)
						
						dragging_index = i
						drag_offset = get_local_mouse_position() - p.position
						
						# Deconectare la click
						if is_connected[i]:
							is_connected[i] = false
							_update_power_indicator(i, false)
							connected_sockets[i] = null
							emit_signal("power_connected", i, false)
						
						get_viewport().set_input_as_handled()
						return
			elif dragging_index != -1:
				var released_index = dragging_index
				dragging_index = -1
				finalize_drop(released_index)
				get_viewport().set_input_as_handled()

func _start_collision_recovery(index: int):
	if is_recovering[index]: return
	
	is_recovering[index] = true
	var objects = [plug_in, plug_out]
	var obj = objects[index]
	var body = obj.get_node_or_null("CharacterBody2D")
	
	# Culori și Z-Index originale pentru feedback vizual
	var random_color = Color(randf(), randf(), randf(), 1.0)
	var original_plug_in_mod = plug_in.modulate
	var original_plug_out_mod = plug_out.modulate
	var original_cable_color = cable.default_color
	
	var original_plug_in_z = plug_in.z_index
	var original_plug_out_z = plug_out.z_index
	var original_cable_z = cable.z_index
	
	# Aplicăm modificările pe elementele sistemului
	plug_in.modulate = random_color
	plug_out.modulate = random_color
	cable.default_color = random_color
	
	plug_in.z_index = 1
	plug_out.z_index = 1
	cable.z_index = 1
	
	if body:
		body.collision_layer = 0
		obj.modulate.a = 0.5 # Îl facem puțin mai transparent pe cel pe care îl tragem
		
		# Timer pentru reset
		await get_tree().create_timer(0.5).timeout
		
		# Resetăm culorile și Z-Index-ul originale
		if is_instance_valid(plug_in):
			plug_in.modulate = original_plug_in_mod
			plug_in.z_index = original_plug_in_z
		if is_instance_valid(plug_out):
			plug_out.modulate = original_plug_out_mod
			plug_out.z_index = original_plug_out_z
		if is_instance_valid(cable):
			cable.default_color = original_cable_color
			cable.z_index = original_cable_z
			
		if is_instance_valid(body):
			body.collision_layer = 64
			
		is_recovering[index] = false

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	var inv_transform = get_global_transform().affine_inverse()
	var player_local = Vector2.ZERO
	if player:
		player_local = inv_transform * player.global_position
	
	var objects = [plug_in, plug_out]
	
	for i in range(2):
		var obj = objects[i]
		if is_connected[i]:
			velocities[i] = Vector2.ZERO
			if connected_sockets[i]:
				var s = connected_sockets[i]
				var s_trans = s.get_global_transform()
				var s_center_global = s_trans * (s.size / 2)
				var other = objects[1 - i]
				var other_center_global = other.get_global_transform() * (other.size / 2)
				
				# Verificăm dacă mai este în raza de acțiune a cablului
				if s_center_global.distance_to(other_center_global) > max_cable_length * get_global_transform().get_scale().x + 20.0:
					is_connected[i] = false
					_update_power_indicator(i, false)
					connected_sockets[i] = null
					emit_signal("power_connected", i, false)
					continue
					
				# Sincronizare poziție și rotație
				var s_rot_global = s_trans.get_rotation()
				var parent_rot = get_global_transform().get_rotation()
				var target_global = Vector2.ZERO
				var is_plug_priza = s.is_in_group("plug_priza")
				
				if is_plug_priza:
					obj.rotation = s_rot_global - parent_rot + PI
					var join_offset = Vector2(0, -35 * obj.get_global_transform().get_scale().y).rotated(s_rot_global)
					target_global = s_center_global + join_offset - (obj.pivot_offset * obj.get_global_transform().get_scale()).rotated(s_rot_global + PI)
				else:
					obj.rotation = s_rot_global - parent_rot
					target_global = s.global_position
				
				# Aplicare restricție limită
				if restrict_above_limit:
					var limit_nodes = get_tree().get_nodes_in_group("priza_limita")
					if not limit_nodes.is_empty():
						var min_global_y = INF
						for node in limit_nodes:
							if node is CanvasItem:
								min_global_y = min(min_global_y, node.global_position.y-5)
						
						if min_global_y != INF:
							if target_global.y < min_global_y:
								target_global.y = min_global_y
					
				obj.global_position = target_global
				update_cable()
			continue

		if dragging_index == i:
			velocities[i] = Vector2.ZERO
			continue
			
	
		var obj_center = obj.position + obj.pivot_offset
		var total_push = Vector2.ZERO
		
		# 1. Împingere directă
		if player:
			var d = player_local.distance_to(obj_center)
			if d < 35.0:
				var dir = (obj_center - player_local).normalized()
				if dir == Vector2.ZERO: dir = Vector2.DOWN
				total_push += dir * (35.0 - d) * 4.0
				
			# Impuls din viteza player
			if player.velocity.length() > 0 and d < 45.0:
				var player_vel_local = inv_transform.x * player.velocity.x + inv_transform.y * player.velocity.y
				total_push += player_vel_local.normalized() * 15.0
		
		# 2. Împingere prin cablu (simplificat: dacă calci pe cablu, ambele capete sunt influențate)
		if player and cable.points.size() > 1:
			for j in range(cable.points.size() - 1):
				var p1 = cable.points[j]
				var p2 = cable.points[j+1]
				var closest = _get_closest_point_on_segment(player_local, p1, p2)
				var d_cable = player_local.distance_to(closest)
				
				if d_cable < 20.0:
					var progress = float(j) / float(cable.points.size() - 1)
					# Dacă calci mai aproape de i, primești mai multă forță
					var weight = progress if i == 1 else (1.0 - progress)
					var push_dir = (closest - player_local).normalized()
					if push_dir == Vector2.ZERO: push_dir = Vector2.UP
					total_push += push_dir * (20.0 - d_cable) * pow(weight, 1.5) * 6.0
					
		velocities[i] += total_push * push_force * delta
		velocities[i] *= (1.0 - friction)
		
		if velocities[i].length() < 1.0:
			velocities[i] = Vector2.ZERO
		else:
			_apply_motion(i, velocities[i] * delta)

func _process(_delta):
	if dragging_index != -1:
		var target_local = get_local_mouse_position() - drag_offset
		var obj = plug_in if dragging_index == 0 else plug_out
		_apply_motion(dragging_index, target_local - obj.position)

func _apply_motion(index: int, motion: Vector2):
	var obj = plug_in if index == 0 else plug_out
	var other = plug_out if index == 0 else plug_in
	var body = obj.get_node_or_null("CharacterBody2D")
	
	var target_pos = obj.position + motion
	
	# DACĂ SUNTEM ÎN MODUL RECUPERARE, IGNORĂM TOATE RESTRICȚIILE (LUNGIME, LIMITE, COLIZIUNI)
	if is_recovering[index]:
		obj.position = target_pos
		if body:
			body.position = obj.pivot_offset
		update_cable()
		return

	# Restricție "priza_limita" (să nu meargă mai sus de elementele din grup)
	if restrict_above_limit:
		var limit_nodes = get_tree().get_nodes_in_group("priza_limita")
		if not limit_nodes.is_empty():
			var min_global_y = INF
			for node in limit_nodes:
				if node is CanvasItem:
					min_global_y = min(min_global_y, node.global_position.y-5)
			
			if min_global_y != INF:
				var inv_trans = get_global_transform().affine_inverse()
				var limit_local_y = (inv_trans * Vector2(0, min_global_y)).y
				if target_pos.y < limit_local_y:
					target_pos.y = limit_local_y

	# Restricție lungime cablu față de celălalt capăt
	var other_center = other.position + other.pivot_offset
	var target_center = target_pos + obj.pivot_offset
	
	if target_center.distance_to(other_center) > max_cable_length:
		target_center = other_center + (target_center - other_center).normalized() * max_cable_length
		target_pos = target_center - obj.pivot_offset
		
	var final_motion = target_pos - obj.position
	
	if body and final_motion.length() > 0.0001:
		var trans = get_global_transform()
		var global_motion = trans.x * final_motion.x + trans.y * final_motion.y
		
		if body.test_move(body.global_transform, global_motion):
			var step_x = Vector2(final_motion.x, 0)
			var step_y = Vector2(0, final_motion.y)
			var g_x = trans.x * step_x.x + trans.y * step_x.y
			var g_y = trans.x * step_y.x + trans.y * step_y.y
			
			if not body.test_move(body.global_transform, g_x):
				obj.position += step_x
			elif not body.test_move(body.global_transform, g_y):
				obj.position += step_y
		else:
			obj.position += final_motion
	else:
		obj.position += final_motion
		
	# Rotatie pentru ambele capete pentru a se uita în direcția opusă cablului (la fel ca în PlugPuzzle)
	var dir_from_cable_to_obj = (obj.position + obj.pivot_offset) - (other.position + other.pivot_offset)
	obj.rotation = lerp_angle(obj.rotation, dir_from_cable_to_obj.angle() + PI/2, 0.2)
	
	var dir_from_cable_to_other = (other.position + other.pivot_offset) - (obj.position + obj.pivot_offset)
	other.rotation = lerp_angle(other.rotation, dir_from_cable_to_other.angle() + PI/2, 0.2)
	
	update_cable()

@onready var cable_collision = $Cable/CableCollision

func update_cable():
	var points = PackedVector2Array()
	var player = get_tree().get_first_node_in_group("player")
	var player_local = Vector2.ZERO
	if player:
		player_local = get_global_transform().affine_inverse() * player.global_position

	var start = plug_in.position + plug_in.pivot_offset
	var end = plug_out.position + plug_out.pivot_offset
	
	# Adăugăm mici offset-uri pentru a ieși din "baza" ștecherului
	var start_tip = start + Vector2(0, 20).rotated(plug_in.rotation)
	var end_tip = end + Vector2(0, 20).rotated(plug_out.rotation)
	
	var dist = start_tip.distance_to(end_tip)
	var mid = (start_tip + end_tip) / 2
	# Sag invers proporțional cu distanța
	var sag_amount = clamp((max_cable_length - dist) * 0.4, 0, 150.0)
	mid.y += sag_amount
	
	for i in range(31):
		var t = float(i) / 30.0
		var p = start_tip.lerp(mid, t).lerp(mid.lerp(end_tip, t), t)
		
		if player:
			var d = p.distance_to(player_local)
			if d < 22.0:
				var push = (p - player_local).normalized()
				if push == Vector2.ZERO: push = Vector2.UP
				p += push * (22.0 - d) * 0.9
		points.append(p)
		
	cable.points = points
	#_update_cable_collision()

func _update_cable_collision():
	if not cable_collision: return
	
	var points = cable.points
	if points.size() < 2: return
	
	# Ajustăm numărul de CollisionShape2D pentru a se potrivi cu segmentele
	var segment_count = points.size() - 1
	var current_shapes = cable_collision.get_children()
	
	# Adăugăm shape-uri dacă lipsesc
	while current_shapes.size() < segment_count:
		var new_shape = CollisionShape2D.new()
		new_shape.shape = SegmentShape2D.new()
		cable_collision.add_child(new_shape)
		current_shapes.append(new_shape)
		
	# Eliminăm shape-urile în plus
	while current_shapes.size() > segment_count:
		var extra = current_shapes.pop_back()
		extra.queue_free()
		
	# Actualizăm fiecare segment
	for i in range(segment_count):
		var shape_node = current_shapes[i]
		var segment: SegmentShape2D = shape_node.shape
		segment.a = points[i]
		segment.b = points[i+1]

func _on_plug_gui_input(_event, _index):
	pass # Folosim _input

func finalize_drop(index: int):
	var objects = [plug_in, plug_out]
	var obj = objects[index]
	
	# Doar obiectele din grupul "plug" se pot conecta la ceva
	if not obj.is_in_group("plug"):
		connected_sockets[index] = null
		is_connected[index] = false
		update_cable()
		return

	var p_trans = obj.get_global_transform()
	var p_scale = p_trans.get_scale()
	var plug_center_global = p_trans * (obj.size / 2)
	
	# Căutăm în ambele grupuri permise
	var sockets = get_tree().get_nodes_in_group("electrical_sockets")
	sockets.append_array(get_tree().get_nodes_in_group("plug_priza"))
	
	var closest_socket: Control = null
	var min_dist = snap_distance * p_scale.x

	for s in sockets:
		if s == obj or not s is Control: continue
		
		var s_trans = s.get_global_transform()
		var s_center_global = s_trans * (s.size / 2)
		var d = plug_center_global.distance_to(s_center_global)
		
		if d < min_dist:
			min_dist = d
			closest_socket = s

	if closest_socket:
		connected_sockets[index] = closest_socket
		is_connected[index] = true
		
		var s_trans = closest_socket.get_global_transform()
		var s_rot_global = s_trans.get_rotation()
		var parent_rot = get_global_transform().get_rotation()
		var target_global = Vector2.ZERO
		
		# Verificăm dacă e plug_priza (pentru orientare)
		var is_plug_priza = closest_socket.is_in_group("plug_priza")
		
		if is_plug_priza:
			obj.rotation = s_rot_global - parent_rot + PI
			var s_center_global = s_trans * (closest_socket.size / 2)
			var join_offset = Vector2(0, -35 * obj.get_global_transform().get_scale().y).rotated(s_rot_global)
			target_global = s_center_global + join_offset - (obj.pivot_offset * obj.get_global_transform().get_scale()).rotated(s_rot_global + PI)
		else:
			obj.rotation = s_rot_global - parent_rot
			target_global = closest_socket.global_position
		
		# Aplicare restricție limită
		if restrict_above_limit:
			var limit_nodes = get_tree().get_nodes_in_group("priza_limita")
			if not limit_nodes.is_empty():
				var min_global_y = INF
				for node in limit_nodes:
					if node is CanvasItem:
						min_global_y = min(min_global_y, node.global_position.y-5)
				
				if min_global_y != INF:
					if target_global.y < min_global_y:
						target_global.y = min_global_y

		obj.global_position = target_global
		emit_signal("power_connected", index, true)
		_update_power_indicator(index, true)
	else:
		var prev_socket = connected_sockets[index]
		connected_sockets[index] = null
		is_connected[index] = false
		
		if prev_socket:
			var indicator = prev_socket.get_node_or_null("Indicator")
			if indicator:
				indicator.color = Color.RED
				
		emit_signal("power_connected", index, false)
		_update_power_indicator(index, false)

	update_cable()

func _update_power_indicator(index: int, state: bool):
	var socket = connected_sockets[index]
	if socket:
		var indicator = socket.get_node_or_null("Indicator")
		if indicator:
			indicator.color = Color.GREEN if state else Color.RED

func _get_closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ab_length_sq = ab.length_squared()
	if ab_length_sq == 0: return a
	var t = (p - a).dot(ab) / ab_length_sq
	return a + ab * clamp(t, 0.0, 1.0)
