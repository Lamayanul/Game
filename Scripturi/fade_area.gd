extends Area2D

# Opacitatea când obiectul este în zona de detectare
var _darkenedColor = Color(0.7, 0.7, 0.7, 1.0)
var _transparentColor = Color(1, 1, 1, 0.5) # Semi-transparent
# Opacitatea normală când obiectul nu este în zona de detectare
var _normalColor = Color(1, 1, 1, 1) # Opac

# NodePath pentru jucător
@export var player_path : NodePath

# Noduri
var _staticbody : StaticBody2D
var _playerSprite : CharacterBody2D

func _ready():
	# Obține referința la nodul StaticBody2D
	_staticbody = get_node("StaticBody2D")
	
		

	# Setează playerSprite folosind NodePath
	if player_path:
		_playerSprite = get_node(player_path)


	# Conectează semnalele
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node):
	print("Body entered: " + body.name)

	if body.is_in_group("player") or body.is_in_group("gaina"):
		if _staticbody:
			_staticbody.modulate = _transparentColor

		if _playerSprite and body == _playerSprite:
			_playerSprite.modulate = _darkenedColor

func _on_body_exited(body: Node):
	print("Body exited: " + body.name)

	if body.is_in_group("player") or body.is_in_group("gaina"):
		if _staticbody:
			_staticbody.modulate = _normalColor

		if _playerSprite and body == _playerSprite:
			_playerSprite.modulate = _normalColor
