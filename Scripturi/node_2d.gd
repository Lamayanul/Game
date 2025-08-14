extends Node2D

@onready var world = get_node("/root/world")


var connected_areas: Array = []  
var used_areas: Array = []  
var control_point_offset = Vector2(0, 30)  
var lines: Array = []  
var generators: Array = []
var pillars: Array =[]


var pillar_connections: Array = []
var pillar_lines: Array = []
var pillar_connect_distance = 120  # Sau cât vrei tu



func _ready() -> void:
	update_generators()

func update_generators() -> void:
	generators = get_tree().get_nodes_in_group("pow_gen")
	pillars= get_tree().get_nodes_in_group("LightSource")

func update_connections() -> void:
	connected_areas.clear()
	lines.clear()
	used_areas.clear()

	update_generators()
	
	for gen in generators:
		var gen_area = gen.get_node("area_interact")
		
		for node in get_tree().get_nodes_in_group("pillar"):
			if node is Area2D and gen_area.overlaps_area(node):
				connected_areas.append(node)

		for pillar in get_tree().get_nodes_in_group("LightSource"):
			var area_node = pillar.get_node("area")
			if area_node and gen_area.overlaps_area(area_node) and gen.legat:
				pillar.conect = true
			else:
				pillar.conect = false

	for area in connected_areas:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = Color(0, 0, 0, 1)
		line.z_index = 2
		add_child(line)
		lines.append(line)

func update_pillar_connections():
	pillar_connections.clear()
	pillar_lines.clear()
	
	# Pentru fiecare pilon, vezi dacă are alt pilon aproape
	for i in range(pillars.size()):
		var p1 = pillars[i]
		for j in range(i+1, pillars.size()):
			var p2 = pillars[j]
			if p1.global_position.distance_to(p2.global_position) < pillar_connect_distance:
				pillar_connections.append([p1, p2])
				var line = Line2D.new()
				line.width = 0.5
				line.default_color = Color(0, 0, 0, 1) # Portocaliu semi-transparent
				line.z_index = 2
				add_child(line)
				pillar_lines.append(line)

	
func _process(_delta):
	if world.needs_update:
		update_connections()
		update_pillar_connections()
		world.needs_update = false
	update_curves()
	update_pillar_curves()


func update_curves() -> void:
	for i in range(connected_areas.size()):
		var area_2d = connected_areas[i]
		var line_2d = lines[i]


		if area_2d != null:
			var closest_gen = get_closest_generator(area_2d.global_position)
			if closest_gen and closest_gen.has_node("area"):
				draw_bezier_curve(line_2d, closest_gen.get_node("area").global_position, area_2d.global_position+Vector2(-4,-10))

		else:
			line_2d.clear_points()
####################################ASTERIX######################################################
func get_closest_generator(pos: Vector2) -> Node:
	var closest_gen = null
	var min_dist = INF
	for gen in generators:
		if is_instance_valid(gen):
			var gen_pos = gen.global_position
			var dist = pos.distance_to(gen_pos)
			if dist < min_dist:
				min_dist = dist
				closest_gen = gen
	return closest_gen

func draw_bezier_curve(line: Line2D, start_point: Vector2, end_point: Vector2) -> void:
	line.clear_points()
	var control_point = (start_point + end_point) / 2 + control_point_offset
	var steps = 50
	for i in range(steps + 1):
		var t = i / float(steps)
		var bezier_point = bezier(start_point, control_point, end_point, t)
		line.add_point(bezier_point)

func bezier(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	return (1 - t) * (1 - t) * start + 2 * (1 - t) * t * control + t * t * end

func update_pillar_curves():
	var pillar_top_offset = -40  # sau cât vrei tu (minus ca să fie mai sus)
	for i in range(pillar_connections.size()):
		var pair = pillar_connections[i]
		var line = pillar_lines[i]
		var p1 = pair[0].global_position + Vector2(0, pillar_top_offset)
		var p2 = pair[1].global_position + Vector2(0, pillar_top_offset)

		line.clear_points()
		var mid = (p1 + p2) / 2
		var dir = (p2 - p1).normalized().orthogonal()
		var control = mid + dir * -40  # sau ce valoare aveai tu

		var steps = 32
		for j in range(steps + 1):
			var t = j / float(steps)
			var pt = (1 - t) * (1 - t) * p1 + 2 * (1 - t) * t * control + t * t * p2
			line.add_point(pt)
