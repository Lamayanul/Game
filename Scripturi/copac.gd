extends Area2D

# Opacitatea când obiectul este în zona de detectare
var _darkenedColor = Color(0.7, 0.7, 0.7, 1.0)
var _transparentColor = Color(1, 1, 1, 0.5) # Semi-transparent
# Opacitatea normală când obiectul nu este în zona de detectare
var _normalColor = Color(1, 1, 1, 1) # Opac
@onready var animation_player = $StaticBody2D/AnimationPlayer
@onready var player = $"../player"
var index_taiere=0
# NodePath pentru jucător
@export var player_path : NodePath
@onready var respawn_tree = $Respawn_tree
var is_cutting=true
# Noduri
var _staticbody : StaticBody2D
var _playerSprite : CharacterBody2D
@onready var inv = $"../CanvasLayer/Inv"

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


func _on_area_2d_area_entered(area):
	if area.is_in_group("arma"):
		call_deferred("play_taiere_animation")
		
	
func play_taiere_animation():
	if not is_cutting:
		return
	animation_player.play("taiere")
	index_taiere+=1
	print("taiere ",index_taiere)
	if index_taiere==5:
		var pos=Vector2(-20,10)
		animation_player.play("gata")
		inv.drop_item_everywhere("6",3,pos)
		index_taiere=0
		is_cutting=false
		respawn_tree.start()


func _on_respawn_tree_timeout():
	animation_player.play("RESET")
	is_cutting=true
	
