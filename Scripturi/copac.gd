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
	respawn_fruits.start()  # Pornim timer-ul pentru fructe

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
		call_deferred("play_taiere_animation")

func play_taiere_animation():
	if not is_cutting:
		return  # Dacă nu se poate tăia, ieșim din funcție

	# Jucăm animația în funcție de starea fructelor
	if fructe:
		animation_player.play("taiere-fructe")
	else:
		animation_player.play("taiere")

	# Creștem indexul pentru progresul tăierii
	index_taiere += 1
	print("Index taiere: ", index_taiere)

	# Condiții pentru tăierea fructelor
	if fructe and index_taiere == 4:
		var pos = Vector2(-20, 10)
		inv.drop_item_everywhere("7", 3, pos)  # Drop fructe
		fructe = false  # Resetăm starea fructelor după ce au fost culese
		animation_player.stop()  # Oprim animația curentă (taiere-fructe)
		animation_player.play("taiere")  # Pornim animația de tăiere fără fructe
		
		return  # Ne asigurăm că animația curentă este întreruptă corect
		
		
		
	# Condiții pentru tăierea copacului complet
	if index_taiere == 8:
		var pos = Vector2(-20, 10)
		animation_player.play("gata")  # Animația finală pentru tăiere completă
		inv.drop_item_everywhere("6", 3, pos) 
		if fructe:
			inv.drop_item_everywhere("7", 3, pos)  # # Drop lemn sau alte resurse
		reset_tree_state()  # Resetăm starea copacului
		respawn_tree.start()  # Pornim respawn-ul pomului

func reset_tree_state():
	# Funcție pentru resetarea completă a stării copacului
	index_taiere = 0  # Resetăm progresul tăierii
	is_cutting = false  # Nu se mai poate tăia până la respawn
	fructe = false  # Resetăm fructele
	is_resetting = true  # Marcăm că pomul este în proces de resetare

	respawn_fruits.stop()
	respawn_tree.start()
	
	
# Funcție pentru resetarea copacului după ce este tăiat complet
func _on_respawn_tree_timeout():
	if is_resetting:  # Verificăm dacă resetarea este în curs
		animation_player.play("RESET")  # Animația de resetare a pomului
		is_cutting = true  # Permite din nou tăierea copacului
		is_resetting = false  # Resetarea este completă
		respawn_fruits.start()
# Funcție pentru apariția fructelor
func _on_respawn_fruits_timeout():
	if not fructe and not is_resetting:  # Verificăm dacă fructele nu sunt deja prezente și resetarea nu este activă
		animation_player.play("fructe")  # Animația pentru apariția fructelor
		fructe = true  # Fructele sunt disponibile pentru următoarea tăiere
