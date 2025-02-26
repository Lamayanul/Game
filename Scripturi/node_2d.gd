extends Node2D

@onready var power: Area2D = get_node("/root/world/Power_generator/area")  # Generatorul principal
@onready var power_interact: Area2D = get_node("/root/world/Power_generator/area_interact") 
@onready var powg= get_node("/root/world/Power_generator") 
@onready var pow_area= get_node("/root/world/Power_generator/area_interact") 

var connected_areas: Array = []  
var used_areas: Array = []  
var control_point_offset = Vector2(0, 30)  
var lines: Array = []  
var aprins=false

func _ready() -> void:
	pass



func update_connections() -> void:
	connected_areas.clear()  

	for node in get_tree().get_nodes_in_group("pillar"):
		if node is Area2D and node != power:
			if pow_area.overlaps_area(node):
				
				connected_areas.append(node)
	var electric_pillars = get_tree().get_nodes_in_group("LightSource")
	for pillar in electric_pillars:
		var area_node = pillar.get_node("area")  # Accesează nodul Area2D asociat fiecărui LightSource
		if area_node and pow_area.overlaps_area(area_node):  # Verifică suprapunerea între pow_area și area_node
			pillar.conect = true  # Setează conectarea pentru pilonul respectiv
		else:
			pillar.conect = false  # Asigură-te că pilonii neconectați nu sunt marcați



	lines.clear()
	for area in connected_areas:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = Color(0, 0, 0, 1)
		line.z_index = 2
		add_child(line)
		lines.append(line)


func _process(_delta: float) -> void:

	if powg.legat == true and connected_areas.is_empty():
		update_connections()
	update_curves()

	
	
func update_curves() -> void:

	for i in range(connected_areas.size()):
		var area_2d = connected_areas[i]
		var line_2d = lines[i]


		if used_areas.has(area_2d):
			continue

		if area_2d != null:
			draw_bezier_curve(line_2d, power.global_position, area_2d.global_position)
			used_areas.append(area_2d) 

		else:
			line_2d.clear_points()

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
