extends PanelContainer
class_name Slot

@onready var texture_rect = $TextureHolder/TextureRect  # Asigură-te că accesezi corect TextureRect
@onready var label = %Label

var filled:bool=false

@export var cantitate: int = 0:
	set(value):
		cantitate = value
		label.text = str(cantitate)
		if cantitate > 0:
			label.text = str(cantitate)
		else:
			label.text = ""

@export_enum("Grau:0", "Seminte:1", "Axe:2") var type: int

@onready var property: Dictionary = {"TEXTURE": null, "CANTITATE": cantitate}:
	set(value):
		property = value 
		texture_rect.texture = property["TEXTURE"]  # Actualizează direct textura în TextureRect
		cantitate = property["CANTITATE"]

# Metoda pentru setarea texturii și cantității
func set_property(data):
	property = data
	texture_rect.texture = property["TEXTURE"]
	cantitate = property["CANTITATE"]
	label.text = str(cantitate)
	if cantitate > 0:
		label.text = str(cantitate)
	else:
		label.text = ""
	if data["TEXTURE"]==null:
		filled=false
	else:
		filled=true

func _get_drag_data(_at_position):
	
	var preview_texture = TextureRect.new()
	
	preview_texture.texture = texture_rect.texture
	preview_texture.expand_mode = 1
	preview_texture.size = Vector2(49, 49)
	
	var preview = Control.new()
	preview.add_child(preview_texture)
	
	set_drag_preview(preview)
	
	return self

func _can_drop_data(_at_position, _data):
	return _data is Slot

func _drop_data(_pos, data):
	var temp = property
	property = data.property
	data.property = temp
	set_property(property)  # Actualizează textura și cantitatea după drop
