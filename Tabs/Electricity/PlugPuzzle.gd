extends Control

@onready var socket = $Socket
@onready var plug = $Plug
@onready var cable = $Cable

@export var cable_start_pos: Vector2 = Vector2(550, 200) # Peretele din dreapta
@export var snap_distance: float = 40.0
@export var max_cable_length: float = 400.0
@export var restrict_above_socket: bool = true

var dragging = false
var offset = Vector2.ZERO # Offset relativ la centrul/poziția plug-ului
var connected = false
var connected_socket: Control = null

signal power_connected(state: bool)

# Fizică și inerție (în spațiu local)
var plug_velocity: Vector2 = Vector2.ZERO
@export var friction: float = 0.2
@export var push_force: float = 200.0

func _ready():
	# Pozitia initiala a stecherului
	plug.position = Vector2(400, 250)
	plug.mouse_filter = Control.MOUSE_FILTER_STOP
	update_cable()
	
	# Configurare coliziuni: nu blochează jucătorul
	var body = plug.get_node_or_null("CharacterBody2D")
	if body:
		body.collision_layer = 64
		body.collision_mask = 1 # Pereți

func _physics_process(delta):
	if connected:
		plug_velocity = Vector2.ZERO
		if connected_socket:
			var s_trans = connected_socket.get_global_transform()
			var s_center_global = s_trans * (connected_socket.size / 2)
			
			# Verificăm dacă mai este în raza de acțiune a cablului
			var target_local = get_global_transform().affine_inverse() * s_center_global
			if target_local.distance_to(cable_start_pos) > max_cable_length + 20.0:
				connected = false
				connected_socket = null
				emit_signal("power_connected", false)
				_update_power_indicator(false)
				return
				
			# Sincronizare rotație și poziție
			var s_rot_global = s_trans.get_rotation()
			var parent_rot = get_global_transform().get_rotation()
			var target_global = Vector2.ZERO

			# Verificăm dacă ne conectăm la un alt ștecăr (ex: prelungitor) sau la priza fixă
			var is_plug_priza = connected_socket.is_in_group("plug_priza")

			if is_plug_priza:
				# Modul "față în față" (din imagine)
				plug.rotation = s_rot_global - parent_rot + PI
		
				var join_offset = Vector2(0, -35 * plug.get_global_transform().get_scale().y).rotated(s_rot_global)
				target_global = s_center_global + join_offset - (plug.pivot_offset * plug.get_global_transform().get_scale()).rotated(s_rot_global + PI)
			else:
				# Modul "suprapunere" (inițial)
				plug.rotation = s_rot_global - parent_rot
				target_global = connected_socket.global_position

			# Limita de sus "ca la început"
			
			if restrict_above_socket and target_local.y < socket.position.y:
				target_local.y = socket.position.y
				plug.position = target_local
			else:
				plug.global_position = target_global

			update_cable()
			return
	if not dragging:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# Coordonatele jucătorului în sistemul local al PlugPuzzle
			var player_local = get_global_transform().affine_inverse() * player.global_position
			var plug_center = plug.position + plug.pivot_offset
			
			var total_push = Vector2.ZERO
			
			# 1. Împingere directă ștecher
			var d_plug = player_local.distance_to(plug_center)
			if d_plug < 35.0:
				var dir = (plug_center - player_local).normalized()
				if dir == Vector2.ZERO: dir = Vector2.DOWN
				total_push += dir * (35.0 - d_plug) * 4.0
			
			# 2. Împingere prin cablu
			if cable.points.size() > 1:
				for i in range(1, cable.points.size() - 1):
					var p1 = cable.points[i]
					var p2 = cable.points[i+1]
					var closest = _get_closest_point_on_segment(player_local, p1, p2)
					var d_cable = player_local.distance_to(closest)
					
					if d_cable < 20.0:
						var progress = float(i) / float(cable.points.size() - 1)
						var push_dir = (closest - player_local).normalized()
						if push_dir == Vector2.ZERO: push_dir = Vector2.UP
						total_push += push_dir * (20.0 - d_cable) * pow(progress, 1.5) * 6.0
			
			# 3. Impuls din mișcarea jucătorului
			if player.velocity.length() > 0:
				if d_plug < 45.0 or is_near_cable(player_local, 30.0):
					# Convertim viteza player-ului în spațiu local (fără translație)
					var inv = get_global_transform().affine_inverse()
					var player_vel_local = inv.x * player.velocity.x + inv.y * player.velocity.y
					total_push += player_vel_local.normalized() * 15.0
				
			plug_velocity += total_push * push_force * delta
			
		# Aplicare frecare
		plug_velocity *= (1.0 - friction)
		if plug_velocity.length() < 1.0:
			plug_velocity = Vector2.ZERO
		else:
			apply_plug_motion(plug_velocity * delta)
	else:
		plug_velocity = Vector2.ZERO

func is_near_cable(local_pos: Vector2, threshold: float) -> bool:
	for i in range(cable.points.size() - 1):
		var closest = _get_closest_point_on_segment(local_pos, cable.points[i], cable.points[i+1])
		if local_pos.distance_to(closest) < threshold:
			return true
	return false

func _get_closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ab_length_sq = ab.length_squared()
	if ab_length_sq == 0: return a
	var t = (p - a).dot(ab) / ab_length_sq
	return a + ab * clamp(t, 0.0, 1.0)

func apply_plug_motion(local_motion: Vector2):
	var body = plug.get_node_or_null("CharacterBody2D")
	
	var target_local = plug.position + local_motion
	
	# Limite locale
	if restrict_above_socket and target_local.y < socket.position.y:
		target_local.y = socket.position.y
	
	var dist = target_local.distance_to(cable_start_pos)
	if dist > max_cable_length:
		target_local = cable_start_pos + (target_local - cable_start_pos).normalized() * max_cable_length
	
	var final_local_motion = target_local - plug.position

	if body and final_local_motion.length() > 0.0001:
		# Verificăm coliziunile folosind transformata globală (fără origin)
		var trans = get_global_transform()
		var global_motion = trans.x * final_local_motion.x + trans.y * final_local_motion.y
		
		if body.test_move(body.global_transform, global_motion):
			# Alunecare manuală simplă pe axe
			var step_x = Vector2(final_local_motion.x, 0)
			var step_y = Vector2(0, final_local_motion.y)
			
			var global_step_x = trans.x * step_x.x + trans.y * step_x.y
			var global_step_y = trans.x * step_y.x + trans.y * step_y.y
			
			if not body.test_move(body.global_transform, global_step_x):
				plug.position += step_x
			elif not body.test_move(body.global_transform, global_step_y):
				plug.position += step_y
		else:
			plug.position += final_local_motion
	else:
		plug.position += final_local_motion
		
	# Rotație lină
	if plug.position.distance_to(socket.position) > snap_distance:
		var target_angle = (plug.position - cable_start_pos).angle() + PI/2
		plug.rotation = lerp_angle(plug.rotation, target_angle, 0.2)
	else:
		plug.rotation = lerp_angle(plug.rotation, 0, 0.2)
		
	update_cable()

func _process(_delta):
	if dragging:
		# Calculăm poziția țintă folosind offset-ul salvat la click
		var target_local = get_local_mouse_position() - offset
		apply_plug_motion(target_local - plug.position)

func update_cable():
	var points = PackedVector2Array()
	var start = cable_start_pos
	
	var player = get_tree().get_first_node_in_group("player")
	var player_local = Vector2.ZERO
	if player:
		player_local = get_global_transform().affine_inverse() * player.global_position

	var plug_center = plug.position + plug.pivot_offset
	var end = plug_center + Vector2(0, plug.size.y / 2).rotated(plug.rotation)
	
	points.append(start)
	
	var dist = start.distance_to(end)
	var mid = (start + end) / 2
	# Sag invers proporțional cu distanța (cablu se întinde când e departe)
	var sag_amount = clamp((max_cable_length - dist) * 0.4, 0, 150.0)
	mid.y += sag_amount
	
	for i in range(1, 21):
		var t = float(i) / 20.0
		var p = start.lerp(mid, t).lerp(mid.lerp(end, t), t)
		
		# Curbare vizuală
		if player:
			var d = p.distance_to(player_local)
			if d < 22.0:
				var push = (p - player_local).normalized()
				if push == Vector2.ZERO: push = Vector2.UP
				p += push * (22.0 - d) * 0.9
		
		points.append(p)
	
	points.append(end)
	cable.points = points

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Detectare manuală click pe plug (mai robustă decât semnalele GUI)
				var p_trans = plug.get_global_transform()
				var local_mouse = p_trans.affine_inverse() * get_global_mouse_position()
				var plug_rect = Rect2(Vector2.ZERO, plug.size)
				
				if plug_rect.has_point(local_mouse):
					dragging = true
					if connected:
						connected_socket = null
						connected = false
						emit_signal("power_connected", false)
						_update_power_indicator(false)
					
					offset = get_local_mouse_position() - plug.position
					get_viewport().set_input_as_handled()
			elif dragging:
				dragging = false
				finalize_drop()
				get_viewport().set_input_as_handled()

func _on_plug_gui_input(_event):
	pass # Folosim _input acum

func finalize_drop():
	# Folosim coordonate globale pentru a detecta prize din alte scene (ex: PlugConnector)
	var p_trans = plug.get_global_transform()
	var p_scale = p_trans.get_scale()
	var plug_center_global = p_trans * (plug.size / 2)
	
	var sockets = get_tree().get_nodes_in_group("electrical_sockets")
	sockets.append_array(get_tree().get_nodes_in_group("plug_priza"))

	var closest_socket: Control = null
	var min_dist = snap_distance * p_scale.x

	for s in sockets:
		if s == plug or not s is Control: continue
		var s_trans = s.get_global_transform()
		var s_center_global = s_trans * (s.size / 2)
		var d = plug_center_global.distance_to(s_center_global)
		
		if d < min_dist:
			min_dist = d
			closest_socket = s

	if closest_socket:
		connected_socket = closest_socket
		
		var s_trans = closest_socket.get_global_transform()
		var s_rot_global = s_trans.get_rotation()
		var parent_rot = get_global_transform().get_rotation()
		var target_global = Vector2.ZERO
		var is_plug_priza = closest_socket.is_in_group("plug_priza")
		
		if is_plug_priza:
			# Modul "față în față" (din imagine)
			plug.rotation = s_rot_global - parent_rot + PI
			var s_center_global = s_trans * (closest_socket.size / 2)
			var join_offset = Vector2(0, -35 * plug.get_global_transform().get_scale().y).rotated(s_rot_global)
			target_global = s_center_global + join_offset - (plug.pivot_offset * plug.get_global_transform().get_scale()).rotated(s_rot_global + PI)
		else:
			# Modul "suprapunere" (inițial)
			plug.rotation = s_rot_global - parent_rot
			target_global = closest_socket.global_position
		
		var target_local = get_global_transform().affine_inverse() * target_global
		if restrict_above_socket and target_local.y < socket.position.y:
			target_local.y = socket.position.y
			plug.position = target_local
		else:
			plug.global_position = target_global
		
		connected = true
		emit_signal("power_connected", true)
		_update_power_indicator(true)
	else:
		var prev_socket = connected_socket
		connected_socket = null
		connected = false
		emit_signal("power_connected", false)
		
		# Stingem indicatorul prizei de care tocmai ne-am deconectat
		if prev_socket:
			var indicator = prev_socket.get_node_or_null("Indicator")
			if indicator:
				indicator.color = Color.RED
		
		_update_power_indicator(false)

	update_cable()

func _update_power_indicator(state: bool):
	# Update indicatorul local al puzzle-ului (priza proprie)
	var local_indicator = socket.get_node_or_null("Indicator")
	
	if state and connected_socket:
		# Dacă suntem conectați, aprindem indicatorul prizei la care suntem conectați
		var ext_indicator = connected_socket.get_node_or_null("Indicator")
		if ext_indicator:
			ext_indicator.color = Color.GREEN
	else:
		# Dacă ne-am deconectat, încercăm să stingem indicatorul ultimei prize la care am fost conectați
		# (Notă: În PlugPuzzle, connected_socket este setat pe null înainte de apelul acesta la deconectare în finalize_drop, 
		# deci trebuie să fim atenți la logica de apel)
		if local_indicator:
			local_indicator.color = Color.RED

func reset_plug():
	connected = false
	connected_socket = null
	dragging = false
	plug.position = Vector2(300, 250)
	plug.rotation = 0
	update_cable()
	emit_signal("power_connected", false)
	_update_power_indicator(false)

func _on_dezactivare_area_entered(area: Area2D) -> void:
	if area.is_in_group("plug") or area.get_parent().is_in_group("plug"):
		var target_plug = area.get_parent()
		if target_plug:
			var body = target_plug.get_node_or_null("CharacterBody2D")
			if body:
				var col = body.get_node_or_null("CollisionShape2D")
				if col:
					col.set_deferred("disabled", true)
			
			var sprite = target_plug.get_node_or_null("Sprite2D")
			if sprite:
				sprite.z_index = 0

func _on_dezactivare_area_exited(area: Area2D) -> void:
	if area.is_in_group("plug") or area.get_parent().is_in_group("plug"):
		var target_plug = area.get_parent()
		if target_plug:
			var body = target_plug.get_node_or_null("CharacterBody2D")
			if body:
				var col = body.get_node_or_null("CollisionShape2D")
				if col:
					col.set_deferred("disabled", false)
			
			var sprite = target_plug.get_node_or_null("Sprite2D")
			if sprite:
				sprite.z_index = -1
