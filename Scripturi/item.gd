extends Sprite2D

@export var ID =""
@export var item_cantitate:int =1

@onready var shadow = Sprite2D.new()

var float_amplitude: float = 2.0  
var float_speed: float = 2.0 
var original_position: Vector2 
var time_passed: float = 0.0  
# Variabile pentru textura și cantitate
var item_texture: Texture
@onready var grid_container = get_node("/root/world/Inventar/Inv/MarginContainer/GridContainer")
@onready var player_light = get_node("/root/world/player/PointLight2D")




func _ready():
	# Setează textura folosind ID-ul
	set_texture1(load("res://assets/" + ItemData.get_texture(ID)) as Texture)
	original_position = position  
	custom_scale()


func _on_body_entered(body):
	if body.name == "player":
		var inventory = get_parent().find_child("Inv")
		
		print("Jucătorul a atins obiectul. ID:", ID, " Cantitate:", item_cantitate)
		print("Inventar plin:", inventory.plin)

		# 1. Încearcă să adauge itemul în inventar
		var added = inventory.add_item(ID, self.get_cantiti())

		# 2. Dacă s-a adăugat cu succes, elimină obiectul din scenă
		if added:
			queue_free()
			print("Obiect colectat și șters.")
		else:
			print("Inventarul este plin! Nu pot adăuga obiectul.")

	

func custom_scale():
	if ID=="15" || ID=="23":
		scale=Vector2(0.65,0.65)

func _process(delta: float):

	time_passed += delta
	position.y = original_position.y + sin(time_passed * float_speed) * float_amplitude
	#lamp()
	

# Metodă pentru a seta textura pe obiect
func set_texture1(texture_drop: Texture):
	item_texture = texture_drop

	self.texture = item_texture  # Asigură-te că setezi textura pe Sprite2D

# Metodă pentru a seta cantitatea pe obiect
func set_cantitate(cantitate: int):
	if cantitate==0:
		
		return
	item_cantitate = cantitate

func get_cantiti():
	return item_cantitate
	
func set_lumina(ID):
	if ID=="23":
		$PointLight2D.visible=true
		$PointLight2D.enabled=true
		print("Aprind lumina!")
		
		
