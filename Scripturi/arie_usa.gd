extends Area2D

@export var player_path : NodePath

# Noduri
@onready var usa = $usa


var _playerSprite : CharacterBody2D

func _ready():
	usa.texture=load("res://Sprout Lands - Sprites - Basic pack/Tilesets/usa_inchisa.png")
	if player_path:
		_playerSprite = get_node(player_path)
		
	# Conectează semnalele
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node):
	print("Body entered: " + body.name)
	if body.is_in_group("player") or body.is_in_group("gaina"):
		usa.texture=load("res://Sprout Lands - Sprites - Basic pack/Tilesets/usa_deschisa.png")
		
func _on_body_exited(body: Node):
	print("Body exited: " + body.name)
	if body.is_in_group("player") or body.is_in_group("gaina"):
		usa.texture=load("res://Sprout Lands - Sprites - Basic pack/Tilesets/usa_inchisa.png")
