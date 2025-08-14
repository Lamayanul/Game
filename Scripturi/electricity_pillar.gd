extends StaticBody2D

#@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
#@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var t: float = 0

@export var orbit_radius: float = 3
@export var orbit_speed: float = 23
@onready var power_node_con = get_node("/root/world/Node2D3")
#@onready var point_light_2d_2: PointLight2D = $PointLight2D2
#@onready var point_light_2d: PointLight2D = $PointLight2D

var is_enabled = false  
var connected_pillars: Array = []  
var con: Array = []
@onready var slot_container: Slot = $CanvasLayer/GridContainer/SlotContainer
@onready var slot_container_2: Slot = $CanvasLayer/GridContainer/SlotContainer2
var pillar_area=false
var generator_active = false 
#@onready var pow_area= get_node("/root/world/Power_generator/area_interact") 
var pil_con=false
@onready var inv = get_node("/root/world/CanvasLayer/Inv")

@export var conect:bool=false
var powg = null

#@onready var power: Area2D = get_node("/root/world/Power_generator/area")
var buton: bool:
	get:
		return is_instance_valid(powg) and powg.generator_on


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var world = get_node("/root/world")
	if world and world.has_method("mark_dirty"):
		world.mark_dirty()

	await get_tree().process_frame
	await get_tree().process_frame
	
	
	assign_closest_generator()

func assign_closest_generator():
	var closest = null
	var min_dist = INF
	for gen in get_tree().get_nodes_in_group("pow_gen"):
		print("gggggggggggggggggggg",gen)
		var dist = global_position.distance_to(gen.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = gen
	powg = closest
	if powg:
		print("🔌 Pilon conectat la generator:", powg.name)
	update_connections()
	

func update_lights():
	var id1 = slot_container.get_id()
	var id2 = slot_container_2.get_id()
	var has_gen = is_instance_valid(powg) and powg.generator_on
	var timer =powg.get_node("Timer")
	var gen_active = has_gen and not timer.is_stopped()
	
	# --- Pentru primul slot ---
	if gen_active and id1 in ["19", "20", "21"]:
		$area/PointLight2D.enabled = true
		match id1:
			"19":
				$area/PointLight2D.color = Color(0, 0, 1)   # Albastru
			"20":
				$area/PointLight2D.color = Color(1, 0, 0)   # Roșu
			"21":
				$area/PointLight2D.color = Color(0, 1, 0)   # Verde
	else:
		$area/PointLight2D.enabled = false

	# --- Pentru al doilea slot ---
	if gen_active and id2 in ["19", "20", "21"]:
		$area/PointLight2D2.enabled = true
		match id2:
			"19":
				$area/PointLight2D2.color = Color(0, 0, 1)   # Albastru
			"20":
				$area/PointLight2D2.color = Color(1, 0, 0)   # Roșu
			"21":
				$area/PointLight2D2.color = Color(0, 1, 0)   # Verde
	else:
		$area/PointLight2D2.enabled = false


func _process(delta: float) -> void:
	if powg == null or not is_instance_valid(powg):
		assign_closest_generator()
	#var powg = self  # fiecare generator se referă la el însuși
	
	#print("daadadadadadaddadadadadad",powg )
	#enable()
	update_lights()
	$area/PointLight2D.energy = 0.5+ 0.5 * sin(t*10)
	t += delta * orbit_speed
	#$area/PointLight2D.position = Vector2(
		#cos(t+4) * orbit_radius,
		#sin(t) * orbit_radius)
	#update_connections()
	#if generator_active:  # Aprinde becurile doar dacă generatorul este activ
		#activate_lights()
	#else:
		#deactivate_lights()


#func activate_lights():
	#print("Activating lights for connected pillars...")  # Debugging
	#
	## Oprește toate luminile mai întâi
	#for pillar in get_tree().get_nodes_in_group("pillar"):
		#var light = pillar.get_node_or_null("PointLight2D")
		#var light2 = pillar.get_node_or_null("PointLight2D2")
		#if light:
			#light.enabled = false  # Oprire inițială
			#light2.enabled = false
#
	## Aprinde becurile doar la pilonii conectați
	#for pillar in con:
		#var light = pillar.get_node_or_null("PointLight2D")
		#var light2 = pillar.get_node_or_null("PointLight2D2")
		#if light:
			#light.enabled = true  # Activare bec
			#light2.enabled = true
# Returnează un array cu toți pilonii conectați la acest generator (direct sau indirect)
func get_all_connected_pillars(start_pillar, _generator, all_pillars, connect_distance):
	var result = []
	var queue = []
	var visited = {}
	
	queue.append(start_pillar)
	visited[start_pillar] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		result.append(current)
		# Caută vecinii la distanță mică (piloni legați)
		for other in all_pillars:
			if other != current and not visited.has(other):
				if current.global_position.distance_to(other.global_position) <= connect_distance:
					queue.append(other)
					visited[other] = true
	return result


func BEC():
	var _power_node_area = get_tree().root.get_node_or_null("world/Node2D3")
	var all_pillars = get_tree().get_nodes_in_group("pillar")
	var connect_distance = 130  # sau cât ai tu la conexiuni între piloni
	var timer = powg.get_node("Timer")
	for generator in get_tree().get_nodes_in_group("pow_gen"):
		if not generator.generator_on:
			continue

		# Ia toți pilonii conectați în rețea la generatorul acesta
		for pillar in all_pillars:
			if generator.global_position.distance_to(pillar.global_position) <= connect_distance:
				var connected_pillars_nou = get_all_connected_pillars(pillar, generator, all_pillars, connect_distance)
				
				# Aprinde fiecare pilon din rețea dacă are itemul corect
				for p in connected_pillars_nou:
					# Verifică dacă are itemul în slot
					if slot_container.get_id() in ["19", "20", "21"] and powg.generator_on and not timer.is_stopped():  # sau cum vrei tu
						$area/PointLight2D.enabled = true
						# poți seta culoarea aici în funcție de ID
					else:
						$area/PointLight2D.enabled = false



func update_pillar_lights():
	var all_pillars = get_tree().get_nodes_in_group("pillar")
	for pillar in all_pillars:
		if not pillar.powg or not pillar.powg.generator_on:
			# Stinge luminile pilonului
			$area/PointLight2D.enabled = false
			$area/PointLight2D2.enabled = false
			
func update_connections() -> void:
	"""Actualizează lista cu pilonii conectați la generator."""
	connected_pillars.clear()
	var power_node_area = get_tree().root.get_node_or_null("world/Node2D3")

	if power_node_area:
		for pillar in get_tree().get_nodes_in_group("pillar"):
			if pillar in power_node_area.connected_areas:
				connected_pillars.append(pillar)



#func deactivate_lights():
	#print("Deactivating lights...")  
	#for pillar in get_tree().get_nodes_in_group("pillar"):
		#var light = pillar.get_node_or_null("PointLight2D")
		#var light2 = pillar.get_node_or_null("PointLight2D2")
		#if light:
			#light.enabled = false  # Stinge toate becurile
			#light2.enabled = false
			#
#func start_generator():
	#"""Funcție apelată când butonul de start este apăsat"""
	#generator_active = true
	#activate_lights()  # Aprinde becurile doar după pornirea generatorului

#func stop_generator():
	#"""Funcție pentru oprirea generatorului"""
	#generator_active = false
	#deactivate_lights()  # Stinge becurile la oprire
#func enable(value=true):
	#var i
	#if $CanvasLayer/GridContainer/SlotContainer.get_item()==null:
		#i=0
		#return
	#if $CanvasLayer/GridContainer/SlotContainer2.get_item()==null:
		#i=0
		#return
		#
	#var power_node = get_tree().root.get_node_or_null("world/Power_generator")
	#var timer = power_node.get_node_or_null("Timer")
#
#
	#if i==0:
		#if timer and not timer.is_stopped():
			## Parcurgem fiecare pilon și activăm/dezactivăm lumina pe baza conectării
			#for pillar in get_tree().get_nodes_in_group("pillar"):
				#if pillar in connected_pillars:
					## Activăm lumina și animațiile doar pentru pilonul conectat
					#var point_light_2d = pillar.get_node("PointLight2D")  # Accesăm nodul de lumină al pilonului
					#var point_light_2d_2 = pillar.get_node("PointLight2D2")  # Al doilea punct de lumină
					#var animated_sprite_2d = pillar.get_node("AnimatedSprite2D")  # Accesăm animația pilonului
					#var animated_sprite_2d_2 = pillar.get_node("AnimatedSprite2D2")  # Al doilea sprite animat
					#point_light_2d.enabled = value
					#point_light_2d_2.enabled = value
					#animated_sprite_2d.play("ongoing")
					#animated_sprite_2d_2.play("ongoing")
					#
					#
				#else:
					## Dezactivăm lumina și animațiile pentru pilonul neconectat
					#var point_light_2d = pillar.get_node("PointLight2D")
					#var point_light_2d_2 = pillar.get_node("PointLight2D2")
					#var animated_sprite_2d = pillar.get_node("AnimatedSprite2D")
					#var animated_sprite_2d_2 = pillar.get_node("AnimatedSprite2D2")
#
					#point_light_2d.enabled = false
					#point_light_2d_2.enabled = false
					#animated_sprite_2d.play("null")
					#animated_sprite_2d_2.play("null")
					#
		#else:
			## Dacă timer-ul nu este pornit, dezactivăm totul
			#for pillar in get_tree().get_nodes_in_group("pillar"):
				#var point_light_2d = pillar.get_node("PointLight2D")
				#var point_light_2d_2 = pillar.get_node("PointLight2D2")
				#var animated_sprite_2d = pillar.get_node("AnimatedSprite2D")
				#var animated_sprite_2d_2 = pillar.get_node("AnimatedSprite2D2")
#
				#point_light_2d.enabled = false
				#point_light_2d_2.enabled = false
				#animated_sprite_2d.play("null")
				#animated_sprite_2d_2.play("null")
				


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		pillar_area=true
		$CanvasLayer.visible=true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		pillar_area=false
		$CanvasLayer.visible=false
