extends StaticBody2D


@onready var power_node_con = get_node("/root/world/Node2D")
#@onready var point_light_2d_2: PointLight2D = $PointLight2D2
#@onready var point_light_2d: PointLight2D = $PointLight2D

var is_enabled = false  
var connected_pillars: Array = []  
var con: Array = []
@onready var slot_container: Slot = $CanvasLayer/GridContainer/SlotContainer
@onready var slot_container_2: Slot = $CanvasLayer/GridContainer/SlotContainer2
var pillar_area=false
var generator_active = false 
@onready var pow_area= get_node("/root/world/Power_generator/area_interact") 
var pil_con=false

@export var conect:bool=false
@onready var powg = get_node("/root/world/Power_generator")
@onready var power: Area2D = get_node("/root/world/Power_generator/area")
var buton: bool:
	get:
		return powg.generator_on

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	con = power_node_con.connected_areas.duplicate()
	

	update_connections()

func _process(_delta: float) -> void:
	BEC()
	update_connections()


func BEC():
	var power_node_area = get_tree().root.get_node_or_null("world/Node2D")
	for pillar in get_tree().get_nodes_in_group("pillar"):
		if pillar in power_node_area.connected_areas:
			var power_node = get_tree().root.get_node_or_null("world/Power_generator")
			var timer = power_node.get_node_or_null("Timer")
			# Verificăm slot_container
			if slot_container.get_id() == "21" and not timer.is_stopped() and buton and conect:
				$area/PointLight2D.enabled = true
				#$area/PointLight2D.color = Color(1, 0, 0)  # Roșu pentru ID 21
			elif slot_container.get_id() == "20" and not timer.is_stopped() and buton and conect:
				$area/PointLight2D.enabled = true
				$area/PointLight2D.color = Color(1, 0, 0)  # Verde pentru ID 20
			elif slot_container.get_id() == "19" and not timer.is_stopped() and buton and conect:
				$area/PointLight2D.enabled = true
				$area/PointLight2D.color = Color(0, 0, 1)  # Albastru pentru ID 19
			else:
				$area/PointLight2D.enabled = false
			
			# Verificăm slot_container_2
			if slot_container_2.get_id() == "21" and not timer.is_stopped() and buton and conect:
				$area/PointLight2D2.enabled = true
				#$area/PointLight2D2.color = Color(1, 0, 0)  # Roșu pentru ID 21
			elif slot_container_2.get_id() == "20" and not timer.is_stopped()  and buton and conect:
				$area/PointLight2D2.enabled = true
				$area/PointLight2D2.color = Color(1, 0, 0)  # Verde pentru ID 20
			elif slot_container_2.get_id() == "19" and not timer.is_stopped() and buton and conect:
				$area/PointLight2D2.enabled = true
				$area/PointLight2D2.color = Color(0, 0, 1)  # Albastru pentru ID 19
			else:
				$area/PointLight2D2.enabled = false



func update_connections() -> void:
	"""Actualizează lista cu pilonii conectați la generator."""
	connected_pillars.clear()
	var power_node_area = get_tree().root.get_node_or_null("world/Node2D3")

	if power_node_area:
		for pillar in get_tree().get_nodes_in_group("pillar"):
			if pillar in power_node_area.connected_areas:
				connected_pillars.append(pillar)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		pillar_area=true
		$CanvasLayer.visible=true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		pillar_area=false
		$CanvasLayer.visible=false
