extends Area2D

# Opacitatea când obiectul este în zona de detectare
var _darkenedColor = Color(0.7, 0.7, 0.7, 1.0)
var _transparentColor = Color(1, 1, 1, 0.5) # Semi-transparent
# Opacitatea normală când obiectul nu este în zona de detectare
var _normalColor = Color(1, 1, 1, 1) # Opac

@onready var animation_player = $StaticBody2D/AnimationPlayer
@onready var player = $"../player"
@onready var respawn_tree = $Respawn_tree
@onready var respawn_fruits = $Respawn_fruits
@onready var inv = $"../CanvasLayer/Inv"
var _staticbody : StaticBody2D
var _playerSprite : CharacterBody2D
var index_taiere = 0
var is_cutting = true
var fructe = false
var is_resetting = false
@export var player_path : NodePath
func _ready():
	_staticbody = get_node("StaticBody2D")
	respawn_fruits.start()  

	if player_path:
		_playerSprite = get_node(player_path)

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node):
	if body.is_in_group("player") or body.is_in_group("gaina"):
		if _staticbody:
			_staticbody.modulate = _transparentColor
		if _playerSprite and body == _playerSprite:
			_playerSprite.modulate = _darkenedColor

func _on_body_exited(body: Node):
	if body.is_in_group("player") or body.is_in_group("gaina"):
		if _staticbody:
			_staticbody.modulate = _normalColor
		if _playerSprite and body == _playerSprite:
			_playerSprite.modulate = _normalColor

func _on_area_2d_area_entered(area):
	if area.is_in_group("arma"):
		if inv.selected_slot.get_id()=="2":
			call_deferred("play_taiere_animation")

func play_taiere_animation():
	if not is_cutting:
		return 

	
	if fructe:
		animation_player.play("taiere-fructe")
	else:
		animation_player.play("taiere")

	# Creștem indexul pentru progresul tăierii
	index_taiere += 1
	print("Index taiere: ", index_taiere)


	if fructe and index_taiere == 4:
		var drop_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10)) 
		var drop_position = global_position + drop_offset 
		inv.drop_item_everywhere("7", 3, drop_position) 
		fructe = false 
		animation_player.stop() 
		animation_player.play("taiere")  
		return 
		
		
		

	if index_taiere == 8:

		var pos = Vector2(-20, 10)
		animation_player.stop() 
		animation_player.play("gata") 
		var drop_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var drop_position = global_position + drop_offset 
		inv.drop_item_everywhere("6", 3, drop_position) 
		if fructe:
			inv.drop_item_everywhere("7", 3, pos) 
		#reset_tree_state() 
		#respawn_tree.start()   
		queue_free()
		var radacina_mare_scene = load("res://Scene/radacina_mare.tscn")
		var radacina_mare_instance = radacina_mare_scene.instantiate()
		radacina_mare_instance.global_position = global_position + Vector2(3,11)
		get_parent().add_child(radacina_mare_instance)


func reset_tree_state():

	index_taiere = 0  
	is_cutting = false 
	fructe = false 
	is_resetting = true 

	respawn_fruits.stop()
	respawn_tree.start()
	

func _on_respawn_tree_timeout():
	if is_resetting:  
		animation_player.play("RESET")  
		is_cutting = true  
		is_resetting = false 
		respawn_fruits.start()
# Funcție pentru apariția fructelor
func _on_respawn_fruits_timeout():
	if not fructe and not is_resetting:  
		animation_player.play("fructe") 
		fructe = true  
