extends Node2D

@onready var world = get_node("/root/world")

var connected_areas: Array = []  
var used_areas: Array = []  
var control_point_offset = Vector2(0, 30)  
var lines: Array = []  
var generators: Array = []
var pillars: Array =[]

func _ready() -> void:
	update_generators()

func update_generators() -> void:
	generators = get_tree().get_nodes_in_group("pow_gen")
	pillars= get_tree().get_nodes_in_group("LightSource")
	#print("powerrrrrr",generators)

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


	
func _process(_delta: float) -> void:
	if world.needs_update:
		update_connections()
		world.needs_update = false
	update_curves()

func update_curves() -> void:
	for i in range(connected_areas.size()):
		var area_2d = connected_areas[i]
		var line_2d = lines[i]


		if area_2d != null:
			var closest_gen = get_closest_generator(area_2d.global_position)
			if closest_gen and closest_gen.has_node("area"):
				draw_bezier_curve(line_2d, closest_gen.get_node("area").global_position, area_2d.global_position)

		else:
			line_2d.clear_points()

func get_closest_generator(pos: Vector2) -> Node:
	var closest_gen = null
	var min_dist = INF
	for gen in generators:
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
