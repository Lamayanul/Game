extends StaticBody2D

#@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
#@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var pow = get_node("/root/world/Power_generator")
@onready var power_node_con = get_node("/root/world/Node2D3")
#@onready var point_light_2d_2: PointLight2D = $PointLight2D2
#@onready var point_light_2d: PointLight2D = $PointLight2D

var is_enabled = false  
var connected_pillars: Array = []  
var con: Array = []

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	con = power_node_con.connected_areas.duplicate()


	update_connections()
	#animated_sprite_2d_2.play("null")
	#animated_sprite_2d.play("null")
	#point_light_2d.enabled = false
	#point_light_2d_2.enabled = false

func _process(_delta: float) -> void:
	enable()

func update_connections() -> void:
	"""Actualizează lista cu pilonii conectați la generator."""
	connected_pillars.clear()
	var power_node_area = get_tree().root.get_node_or_null("world/Node2D3")

	if power_node_area:
		for pillar in get_tree().get_nodes_in_group("pillar"):
			if pillar in power_node_area.connected_areas:
				connected_pillars.append(pillar)

func enable(value=true):
	var power_node = get_tree().root.get_node_or_null("world/Power_generator")
	var timer = power_node.get_node_or_null("Timer")



	if timer and not timer.is_stopped():
		# Parcurgem fiecare pilon și activăm/dezactivăm lumina pe baza conectării
		for pillar in get_tree().get_nodes_in_group("pillar"):
			if pillar in connected_pillars:
				# Activăm lumina și animațiile doar pentru pilonul conectat
				var point_light_2d = pillar.get_node("PointLight2D")  # Accesăm nodul de lumină al pilonului
				var point_light_2d_2 = pillar.get_node("PointLight2D2")  # Al doilea punct de lumină
				var animated_sprite_2d = pillar.get_node("AnimatedSprite2D")  # Accesăm animația pilonului
				var animated_sprite_2d_2 = pillar.get_node("AnimatedSprite2D2")  # Al doilea sprite animat

				point_light_2d.enabled = value
				point_light_2d_2.enabled = value
				animated_sprite_2d.play("ongoing")
				animated_sprite_2d_2.play("ongoing")
			else:
				# Dezactivăm lumina și animațiile pentru pilonul neconectat
				var point_light_2d = pillar.get_node("PointLight2D")
				var point_light_2d_2 = pillar.get_node("PointLight2D2")
				var animated_sprite_2d = pillar.get_node("AnimatedSprite2D")
				var animated_sprite_2d_2 = pillar.get_node("AnimatedSprite2D2")

				point_light_2d.enabled = false
				point_light_2d_2.enabled = false
				animated_sprite_2d.play("null")
				animated_sprite_2d_2.play("null")
	else:
		# Dacă timer-ul nu este pornit, dezactivăm totul
		for pillar in get_tree().get_nodes_in_group("pillar"):
			var point_light_2d = pillar.get_node("PointLight2D")
			var point_light_2d_2 = pillar.get_node("PointLight2D2")
			var animated_sprite_2d = pillar.get_node("AnimatedSprite2D")
			var animated_sprite_2d_2 = pillar.get_node("AnimatedSprite2D2")

			point_light_2d.enabled = false
			point_light_2d_2.enabled = false
			animated_sprite_2d.play("null")
			animated_sprite_2d_2.play("null")
