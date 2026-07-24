extends Node2D

@export var cable: Line2D
@export var plug: Control

## Nodul din scenă care reprezintă punctul fix de unde începe cablul
@export var cable_start_node: Node2D
@export var max_cable_length: float = 350.0
@export var snap_distance: float = 15.0
@export var push_force: float = 200.0
@export var friction: float = 0.15

## Offset-ul vizual (față de centrul ștecherului) unde se prinde cablul. Ajustează în editor!
@export var cable_attach_offset: Vector2 = Vector2(0, 0)
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var connected: bool = false
var connected_socket: Control = null
var plug_velocity: Vector2 = Vector2.ZERO

func _get_start_pos() -> Vector2:
	if is_instance_valid(cable_start_node):
		return cable_start_node.global_position
	return global_position + Vector2(-20, 20)

func _ready() -> void:
	# Fallback dacă nu au fost setate din editor
	if cable == null:
		cable = get_node_or_null("Cable")
	if plug == null:
		plug = get_node_or_null("PlugOut")
		if plug == null:
			plug = get_node_or_null("Plug") # alt nume comun
			
	if plug == null or cable == null:
		push_error("CablePlugManager: Nu s-a găsit nodul Plug sau Cable în scena " + get_parent().name)
		set_process_input(false)
		set_physics_process(false)
		return

	# Asigurăm grupurile corecte
	if not plug.is_in_group("plug"):
		plug.add_to_group("plug")
	
	# Inițializare cablu
	update_cable()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Detectare click pe plug
			var p_trans = plug.get_global_transform()
			var local_mouse = p_trans.affine_inverse() * get_global_mouse_position()
			var plug_rect = Rect2(Vector2.ZERO, plug.size)
			
			if plug_rect.has_point(local_mouse):
				dragging = true
				if connected:
					connected = false
					connected_socket = null
				drag_offset = plug.global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
		elif dragging:
			dragging = false
			_finalize_drop()
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if connected and connected_socket:
		_handle_connected_logic()
		update_cable()
		return
		
	if dragging:
		var target_pos = get_global_mouse_position() + drag_offset
		_apply_motion_with_constraints(target_pos - plug.global_position)
		update_cable()
		return

	# Logica de împingere de către player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var player_pos = player.global_position
		var plug_center = plug.get_global_transform() * plug.pivot_offset
		
		var total_push = Vector2.ZERO
		
		# 1. Împingere directă ștecher
		var d_plug = player_pos.distance_to(plug_center)
		if d_plug < 30.0:
			var dir = (plug_center - player_pos).normalized()
			if dir == Vector2.ZERO: dir = Vector2.DOWN
			total_push += dir * (30.0 - d_plug) * 5.0
			
		# 2. Împingere prin cablu
		if cable.points.size() > 1:
			for i in range(cable.points.size() - 1):
				var p1 = to_global(cable.points[i])
				var p2 = to_global(cable.points[i+1])
				var closest = _get_closest_point_on_segment(player_pos, p1, p2)
				var d_cable = player_pos.distance_to(closest)
				
				if d_cable < 20.0:
					var progress = float(i) / float(cable.points.size() - 1)
					var push_dir = (closest - player_pos).normalized()
					if push_dir == Vector2.ZERO: push_dir = Vector2.UP
					total_push += push_dir * (20.0 - d_cable) * pow(progress, 1.2) * 6.0
					
		# 3. Impuls din viteza player
		if player.velocity.length() > 0 and (d_plug < 40.0 or _is_near_cable(player_pos, 25.0)):
			total_push += player.velocity.normalized() * 20.0
			
		plug_velocity += total_push * push_force * delta
		
	# Aplicare frecare și mișcare
	plug_velocity *= (1.0 - friction)
	if plug_velocity.length() < 1.0:
		plug_velocity = Vector2.ZERO
	else:
		_apply_motion_with_constraints(plug_velocity * delta)
	
	update_cable()

func _handle_connected_logic() -> void:
	var s_trans = connected_socket.get_global_transform()
	var s_center_global = s_trans * (connected_socket.size / 2)
	
	# Verificăm lungimea cablului
	if s_center_global.distance_to(_get_start_pos()) > max_cable_length + 20.0:
		connected = false
		connected_socket = null
		return
		
	var s_rot_global = s_trans.get_rotation()
	var parent_rot = get_global_transform().get_rotation()
	
	if connected_socket.is_in_group("plug"):
		# Conectare "cap în cap" (face-to-face)
		plug.rotation = s_rot_global - parent_rot + PI
		# Aplicăm un offset vizual pe axa Y locală a prizei, rotit global
		var join_offset = Vector2(0, -35 * s_trans.get_scale().y).rotated(s_rot_global)
		# Calculăm poziția finală a originii (top-left) astfel încât pivotul să ajungă la s_center_global + join_offset
		var desired_plug_center = s_center_global + join_offset
		plug.global_position = desired_plug_center - (plug.get_global_transform() * plug.pivot_offset - plug.global_position)
	else:
		# Conectare prin suprapunere
		plug.rotation = s_rot_global - parent_rot
		plug.global_position = connected_socket.global_position

func _apply_motion_with_constraints(motion: Vector2) -> void:
	var target_global = plug.global_position + motion
	var start_pos = _get_start_pos()
	
	# Limitare lungime cablu
	if target_global.distance_to(start_pos) > max_cable_length:
		target_global = start_pos + (target_global - start_pos).normalized() * max_cable_length
		
	# Verificare coliziuni (dacă are CharacterBody2D)
	var body = plug.get_node_or_null("CharacterBody2D")
	if body and motion.length() > 0.001:
		if body.test_move(body.global_transform, target_global - plug.global_position):
			# Alunecare simplă
			var slide_motion = target_global - plug.global_position
			var step_x = Vector2(slide_motion.x, 0)
			var step_y = Vector2(0, slide_motion.y)
			
			if not body.test_move(body.global_transform, step_x):
				plug.global_position += step_x
			elif not body.test_move(body.global_transform, step_y):
				plug.global_position += step_y
		else:
			plug.global_position = target_global
	else:
		plug.global_position = target_global
		
	# Rotație dinamică
	var target_angle = plug.rotation
	
	if dragging:
		# Când îl tragem, se rotește în direcția mișcării (mouse-ului)
		if motion.length_squared() > 1.0:
			target_angle = motion.angle() + PI/2
	else:
		# Când e aruncat/împins liber
		if motion.length_squared() > 2.0:
			target_angle = motion.angle() + PI/2
		else:
			# Stă pe loc: revine la a privi opus față de bază
			var dir_away = (plug.global_position - start_pos).normalized()
			if dir_away.length_squared() > 0.001:
				target_angle = dir_away.angle() + PI/2
				
	plug.rotation = lerp_angle(plug.rotation, target_angle, 0.10)

func update_cable() -> void:
	if not cable: return
	
	var points = PackedVector2Array()
	var start_local = to_local(_get_start_pos())
	
	# Punctul global exact unde se atașează cablul
	var attach_point_global = plug.get_global_transform() * (plug.pivot_offset + cable_attach_offset)
	var end_local = to_local(attach_point_global)
	
	points.append(start_local)
	
	var dist = start_local.distance_to(end_local)
	var mid = (start_local + end_local) / 2.0
	var sag = clamp((max_cable_length - dist) * 0.4, 0, 100.0)
	mid.y += sag
	
	var player = get_tree().get_first_node_in_group("player")
	var player_local = to_local(player.global_position) if player else Vector2.ZERO
	
	for i in range(1, 21):
		var t = float(i) / 20.0
		var p = start_local.lerp(mid, t).lerp(mid.lerp(end_local, t), t)
		
		# Interacțiune player cu firul (curbare vizuală)
		if player:
			var d = p.distance_to(player_local)
			if d < 15.0:
				var push = (p - player_local).normalized()
				if push == Vector2.ZERO: push = Vector2.UP
				p += push * (15.0 - d) * 0.8
		
		points.append(p)
		
	points.append(end_local)
	cable.points = points

func _finalize_drop() -> void:
	# Căutăm doar elemente cu care ne putem conecta corect
	var sockets = get_tree().get_nodes_in_group("plug")
	sockets.append_array(get_tree().get_nodes_in_group("electrical_sockets"))
	
	var closest: Control = null
	var min_dist = snap_distance
	var plug_center = plug.get_global_transform() * plug.pivot_offset

	for s in sockets:
		if s == plug or not s is Control: continue
		
		# Un plug_out (mamă) nu se unește cu alt plug_out
		if s.is_in_group("plug_priza"): continue
		
		var s_trans = s.get_global_transform()
		var s_center = s_trans * (s.size / 2)
		var d = plug_center.distance_to(s_center)
		
		if d < min_dist:
			min_dist = d
			closest = s
			
	if closest:
		connected_socket = closest
		connected = true
		_handle_connected_logic() # Snap imediat
	else:
		connected = false
		connected_socket = null

func _get_closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0: return a
	var t = (p - a).dot(ab) / ab_len_sq
	return a + ab * clamp(t, 0.0, 1.0)

func _is_near_cable(global_pos: Vector2, threshold: float) -> bool:
	for i in range(cable.points.size() - 1):
		var p1 = to_global(cable.points[i])
		var p2 = to_global(cable.points[i+1])
		if global_pos.distance_to(_get_closest_point_on_segment(global_pos, p1, p2)) < threshold:
			return true
	return false
