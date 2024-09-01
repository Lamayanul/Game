extends PanelContainer
class_name Slot

@onready var texture_rect = $TextureHolder/TextureRect
  # Asigură-te că accesezi corect TextureRect
@onready var label = %Label
@export var is_selected: bool = false
var filled:bool=false
var item_id: String = ""  # ID-ul itemului stivuit




signal slot_selected(slot)


@export var number : int = 0:
	set(value):
		number = value
		item_id = get_id()


@export var cantitate: int = 0:
	set(value):
		cantitate = value
		label.text = str(cantitate)
		if cantitate > 0:
			label.text = str(cantitate)
		else:
			label.text = ""

#@export_enum("Grau:0", "Seminte:1", "Axe:2") var type: int

@onready var property: Dictionary = {"TEXTURE": null, "CANTITATE": cantitate, "NUMBER":number}:
	set(value):
		property = value 
		texture_rect.texture = property["TEXTURE"]  # Actualizează direct textura în TextureRect
		cantitate = property["CANTITATE"]
		number = property["NUMBER"]
	

# Metoda pentru setarea texturii și cantității
func set_property(data):
	#if item_id != "" and item_id ==str( data["NUMBER"]):
		#cantitate+=property["CANTITATE"]
		#
	#else:
		property = data
		texture_rect.texture = property["TEXTURE"]
		cantitate = property["CANTITATE"]
		number = property["NUMBER"]
		label.text = str(cantitate)
		if cantitate > 0:
			label.text = str(cantitate)
		else:
			label.text = ""
		if data["TEXTURE"]==null:
			filled=false
		else:
			filled=true
	
	
func get_texture() -> Texture:
	return property.get("TEXTURE", null)  # Returnează textura din dictionary, sau null dacă nu există

func get_cantitate() -> int:
	return property.get("CANTITATE", 0)
	
func get_number()->int:
	return property.get("NUMBER",0)
	
	
	
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
	


func _ready():
	# Conectează semnalul de selecție
	connect("gui_input",Callable( self, "_on_gui_input"))
	

func _on_gui_input(event):
	# Detectează click-ul pentru a selecta slotul
	if event is InputEventMouseButton and event.pressed:
		is_selected = true
		emit_signal("slot_selected", self)

func select():
	is_selected = true
	
	

func deselect():
	is_selected = false
	
func clear_item():

	 # Resetează textura la null
	$TextureHolder/TextureRect.texture = null  
	
	# Resetează textul etichetei la gol
	%Label.text = ""
	
	# Resetează cantitatea
	cantitate = 0

	# Resetează ID-ul sau alte proprietăți relevante
	property = {"TEXTURE": null, "CANTITATE": 0, "NUMBER": 0}

	# Marchează slotul ca fiind gol
	filled = false  
	
	# Oprește funcționalitatea drag-and-drop
	#set_drag_preview(null)
	
func get_id() -> String:
	if property and property.has("Number") != null:
		for key in ItemData.content.keys():
			if ItemData.content[key]["number"] == number:
				return key
	return "0"
	
	
