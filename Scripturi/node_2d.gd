extends Node2D

@onready var line_2d: Line2D = $Line2D
@onready var power:Area2D = get_node("/root/world/Power_generator/area")  # Referință la primul Area2D
@onready var area_2d:Area2D = get_node("/root/world/Electricity_pillar/area")  # Referință la al doilea Area2D (dintr-o altă scenă)
#var center1 = get_area_center(power)
#var center2 = get_area_center(area_2d)
# Punctul de control pentru curba Bezier
var control_point_offset = Vector2(0, 30)  # Ajustează offset-ul după cum dorești
var points: Array = []  # Lista pentru stocarea pozițiilor punctelor

func _ready() -> void:
	# Curăță punctele existente
	line_2d.clear_points()
	update_curve()

# Actualizează linia în fiecare cadru pentru a reflecta mișcările și curba
func _process(_delta: float) -> void:
	update_curve()

func update_curve() -> void:
	# Curăță punctele existente
	line_2d.clear_points()
	
	# Obține pozițiile globale ale celor două puncte
	var start_point = power.global_position
	var end_point = area_2d.global_position
	
	# Definește punctul de control în mijlocul liniei, cu un offset
	var control_point = (start_point + end_point) / 2 + control_point_offset
	
	# Generează punctele curbei Bezier
	var steps = 50  # Numărul de puncte pentru curba
	for i in range(steps + 1):
		var t = i / float(steps)
		var bezier_point = bezier(start_point, control_point, end_point, t)
		line_2d.add_point(bezier_point)

func bezier(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	# Funcția Bezier quadratică
	return (1 - t) * (1 - t) * start + 2 * (1 - t) * t * control + t * t * end

#func get_area_center(area: Area2D) -> Vector2:
	#var collision = area.get_node("CollisionShape2D")
	#if collision:
		#return area.global_position + collision.position
	#return area.global_position
