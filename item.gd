extends Sprite2D

@export var ID =""

@onready var shadow = Sprite2D.new()

var float_amplitude: float = 2.0  
var float_speed: float = 2.0 
var original_position: Vector2 
var time_passed: float = 0.0  

# Variabile pentru textura și cantitate
var item_texture: Texture
var item_cantitate: int=1

func _ready():
	# Setează textura folosind ID-ul
	set_texture1(load("res://assets/" + ItemData.get_texture(ID)) as Texture)
	original_position = position  



func _on_body_entered(body):
	if body.name == "player":
		var inventory=get_parent().find_child("Inv") #get_parent().find_child("Inv")
		
		if inventory.plin < 4:
			get_parent().find_child("Inv").add_item(ID,self.get_cantiti())
			#inventory.plin+=1
			queue_free()
			print(inventory.plin)
			#print("cantitate: ",item_cantitate)
		else:
			print("Inventarul este plin")

func _process(delta: float):
	time_passed += delta
	position.y = original_position.y + sin(time_passed * float_speed) * float_amplitude

# Metodă pentru a seta textura pe obiect
func set_texture1(texture: Texture):
	item_texture = texture
	self.texture = item_texture  # Asigură-te că setezi textura pe Sprite2D

# Metodă pentru a seta cantitatea pe obiect
func set_cantitate(cantitate: int):
	item_cantitate = cantitate
	# Dacă ai un Label pentru a afișa cantitatea, îl poți seta aici
	# Exemplu: label.text = str(item_cantitate)
func get_cantiti():
	return item_cantitate
