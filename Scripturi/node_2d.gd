extends Node2D

@onready var power: Area2D = get_node("/root/world/Power_generator/area")  # Generatorul principal
@onready var power_interact: Area2D = get_node("/root/world/Power_generator/area_interact") 
@onready var pow= get_node("/root/world/Power_generator") 
@onready var pow_area= get_node("/root/world/Power_generator/area_interact") 

var connected_areas: Array = []  # Listă de `pillar` conectate
var used_areas: Array = []  # Listă de `pillar` deja folosite
var control_point_offset = Vector2(0, 30)  # Ajustează offset-ul curbei Bezier
var lines: Array = []  # Stocăm liniile `Line2D`

func _ready() -> void:
	pass
	# Verificăm pilonii care sunt în interiorul ariei generatorului
func update_connections() -> void:
	connected_areas.clear()  # Resetăm lista
	# Verificăm din nou pilonii
	for node in get_tree().get_nodes_in_group("pillar"):
		if node is Area2D and node != power:
			if pow_area.overlaps_area(node):
				connected_areas.append(node)


	# Inițializăm liniile pentru fiecare zonă conectată
	lines.clear()
	for area in connected_areas:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = Color(0, 0, 0, 1)
		line.z_index = 2
		add_child(line)
		lines.append(line)

	# Actualizăm liniile
	#update_curves()

func _process(_delta: float) -> void:
	# Dacă generatorul este legat și nu am actualizat conexiunile încă
	if pow.legat == true and connected_areas.is_empty():
		update_connections()
	update_curves()

func update_curves() -> void:
	# Curățăm liniile și reconectăm doar pilonii nefolosiți
	for i in range(connected_areas.size()):
		var area_2d = connected_areas[i]
		var line_2d = lines[i]

		# Sărim peste `pillar`-urile deja conectate
		if used_areas.has(area_2d):
			continue

		# Conectăm linia și marcăm `pillar`-ul ca folosit
		if area_2d != null:
			draw_bezier_curve(line_2d, power.global_position, area_2d.global_position)
			used_areas.append(area_2d)  # Marcare ca utilizat

		# Opriți linia pentru `pillar` nevalide
		else:
			line_2d.clear_points()

func draw_bezier_curve(line: Line2D, start_point: Vector2, end_point: Vector2) -> void:
	# Curățăm punctele liniei
	line.clear_points()

	# Punct de control în mijloc, cu offset
	var control_point = (start_point + end_point) / 2 + control_point_offset

	# Generează punctele curbei Bezier
	var steps = 50
	for i in range(steps + 1):
		var t = i / float(steps)
		var bezier_point = bezier(start_point, control_point, end_point, t)
		line.add_point(bezier_point)

func bezier(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	# Funcția Bezier quadratică
	return (1 - t) * (1 - t) * start + 2 * (1 - t) * t * control + t * t * end
