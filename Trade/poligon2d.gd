extends Polygon2D

@export var border_color: Color = Color.WHITE
@export var border_width: float = 1.0

func _ready():
	var outline = Line2D.new()
	add_child(outline)
	
	# Îi dăm aceleași puncte pe care le are poligonul
	outline.points = polygon
	
	# Setări pentru aspectul bordurii
	outline.width = border_width
	outline.default_color = border_color
	
	# În Godot 4, Line2D are opțiunea de a închide conturul automat
	outline.closed = true 
	
	# Opțional: să facă îmbinările colțurilor ascuțite/frumoase
	outline.joint_mode = Line2D.LINE_JOINT_SHARP
