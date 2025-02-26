extends Area2D
class_name hide
@onready var grid_land: Sprite2D = $"../TileMap/Grid_land"
@onready var tile_map: TileMap = $"../TileMap"

# Opacitatea când obiectul este în zona de detectare
#var _darkenedColor = Color(0.7, 0.7, 0.7, 1.0)
#var _transparentColor = Color(1, 1, 1, 0.5) # Semi-transparent
# Opacitatea normală când obiectul nu este în zona de detectare
var _normalColor = Color(1, 1, 1, 1) # Opac
var _transparent=Color(0,0,0,0)
var can_plant = true

# NodePath pentru jucător
@export var player_path : NodePath

@onready var player = $"../player"
@onready var colisiune = player.get_node("colisiune")


@onready var acoperis = $acoperis

var _playerSprite : CharacterBody2D

func _ready():
	

	if player_path:
		_playerSprite = get_node(player_path)


	# Conectează semnalele
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node):
	print("Body entered: " + body.name)
	
	if body.is_in_group("player") or body.is_in_group("gaina"):
		if acoperis:
			acoperis.modulate = _transparent
			body.can_jump = false
			can_plant = false
			tile_map.planting_mode=false
			grid_land.visible=false
			
			
			

		

func _on_body_exited(body: Node):
	print("Body exited: " + body.name)
	grid_land.visible=true
	if body.is_in_group("player") or body.is_in_group("gaina"):
		if acoperis:
			acoperis.modulate = _normalColor
			body.can_jump = true
			tile_map.planting_mode=true
			grid_land.visible=true
			can_plant = true
			
