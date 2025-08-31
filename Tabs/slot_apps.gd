extends PanelContainer
class_name Slot_app

@onready var texture_rect = $TextureHolder/TextureRect
  # Asigură-te că accesezi corect TextureRect
@onready var label = %Label
@export var is_selected: bool = false

var filled:bool=false
var item_id: String = ""  # ID-ul itemului stivuit
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var water_fill = get_node_or_null("/root/world/Fantana/CanvasLayer")

@export var slot_type: String = "inventory"  # Valorile posibile: "inventory", "no_inv", etc.

# Proprietatea care definește obiectul din slot
var property_1: Dictionary = {}


@onready var slot_container = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer")
@onready var slot_container_2 = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer2")
@onready var slot_container_3 = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer3")
@onready var slot_container_4 = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer4")

signal clothes_changed(new_clothes_id)
signal slot_selected(slot)
#signal item_changed
signal request_tray_spawn(item_data)
signal double_clicked(slot: Slot_app)

var dragging := false
var drag_offset := Vector2.ZERO


@export var nume: String:
	set(value):
		nume=value
		
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

@export var raritate: String:
	set(value):
		raritate=value
#@export_enum("Grau:0", "Seminte:1", "Axe:2") var type: int

@onready var property: Dictionary = {"TEXTURE": null, "CANTITATE": cantitate, "NUMBER":number, "NUME":nume}:
	set(value):
		property = value 
		texture_rect.texture = property["TEXTURE"]  # Actualizează direct textura în TextureRect
		cantitate = property["CANTITATE"]
		number = property["NUMBER"]
		nume = property["NUME"]
	

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
		nume=property["NUME"]
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
	
func get_nume()->String:
	return property.get("NUME","")
	
func get_raritate()->String:
	return property.get("RARITATE","")

func set_item_crafting():
	emit_signal("item_changed")
	
func set_item(item_idx):
	emit_signal("clothes_changed", item_idx)
	
func _get_drag_data(_at_position):
	
	var preview_texture = TextureRect.new()
	
	preview_texture.texture = texture_rect.texture
	preview_texture.expand_mode = 1
	preview_texture.size = Vector2(49, 49)
	
	var preview = Control.new()
	preview.add_child(preview_texture)
	
	set_drag_preview(preview)

	return self


func _can_drop_data(_at_position, data):
	# Permitem doar dacă data e un Slot
	if not (data is Slot_app):
		return false
	if data.slot_type == "inventory" and  (self.slot_type == "helmet" or self.slot_type=="arma" or self.slot_type=="ceva" or self.slot_type == "armor") and (int(data.get_id())<=24):
		return false
	
	if data.slot_type == "inventory" and  (self.slot_type == "helmet" or self.slot_type=="arma" or self.slot_type=="ceva" )and data.get_id()=="25":
		return false
	
	if data.slot_type == "helmet" and (self.slot_type == "armor" or self.slot_type == "arma" or self.slot_type == "ceva"):
		return false
	
	if data.slot_type == "armor" and (self.slot_type == "helmet" or self.slot_type == "arma" or self.slot_type == "ceva"):
		return false
		
	if data.slot_type == "arma" and (self.slot_type == "armor" or self.slot_type == "helmet" or self.slot_type == "ceva"):
		return false
	if data.slot_type == "ceva" and (self.slot_type == "armor" or self.slot_type == "arma" or self.slot_type == "helmet"):
		return false
	
	
	# Blochează back → result
	if data.slot_type == "back" and self.slot_type == "result":
		return false
	if data.slot_type == "result" and self.slot_type == "back":
		return false
		
	if data.slot_type == "inventory" and self.slot_type == "back":
		return false
	if data.slot_type == "back" and self.slot_type == "inventory":
		return false
	
	if data.slot_type == "trader" and self.slot_type == "result":
		return false
	if data.slot_type == "result" and self.slot_type == "trader":
		return false
	
	if data.slot_type == "trader" and self.slot_type == "inventory":
		return false
	if data.slot_type == "inventory" and self.slot_type == "trader":
		return false
	
	if data.slot_type == "player" and self.slot_type == "trader":
		return false
	if data.slot_type == "trader" and self.slot_type == "player":
		return false
	
	if data.slot_type == "player" and self.slot_type == "back":
		return false
	if data.slot_type == "back" and self.slot_type == "player":
		return false
	
	if data.slot_type == "inventory" and self.slot_type == "no_inv":
		return true
	if data.slot_type == "no_inv" and self.slot_type == "inventory":
		return true

	# Default: nu permitem
	return true

func _drop_data(_pos, data):
	
	if not (data is Slot_app):
		return  # Asigură-te că datele droppate provin dintr-un slot valid

	if self == data:
		#print("Itemul este deja în acest slot. Nu se face nicio acțiune.")
		return  # Nu facem nimic dacă sloturile sunt identice

	var source_property = data.property  # Proprietatea itemului din slotul sursă
	var target_property = property       # Proprietatea itemului din slotul țintă
	#var EMPTY_ITEM = {"texture" : "","cantitate":0,"number":0,"nume":""}
	if source_property != null and target_property.has("NUMBER") and target_property.has("CANTITATE") and target_property["NUMBER"] == 0 and target_property["CANTITATE"] == 0:

		# Mutăm itemul într-un slot gol
		#print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		set_property(source_property)
		data.clear_item()
		
		
		if data.slot_type == "back" and self.slot_type == "result":
			return
			
			
		# Ajustează `inv.plin` în funcție de tipurile de sloturi
		if data.slot_type == "inventory" and self.slot_type == "no_inv":
			inv.plin -= 1  # Mutare din inventar în no_inv
			#print("Mutat1 din inventar în no_inv. Inv plin:", inv.plin)
			
		elif data.slot_type == "no_inv" and self.slot_type == "inventory":
			inv.plin += 1  # Mutare din no_inv în inventar
			#print("Mutat1 din no_inv în inventar. Inv plin:", inv.plin)
	

	elif source_property != null and target_property != null:
		
		if data.slot_type == "back" and self.slot_type == "result":
			return
			
		# Dacă itemele sunt de același tip, adunăm cantitățile
		if source_property.has("NUMBER") and target_property.has("NUMBER") and source_property["NUMBER"] == target_property["NUMBER"]:
			target_property["CANTITATE"] += source_property["CANTITATE"]
			data.clear_item()
			set_property(target_property)
			#print("Cantitățile au fost combinate.")
		else:
			# Schimbăm itemele între sloturile inventory și no_inv
			# Verificăm că tipurile de sloturi sunt diferite (inventory și no_inv)
			if data.slot_type == "inventory" and self.slot_type == "no_inv":
				# Actualizăm inv.plin corespunzător
				
				print("Mutat item din inventory în no_inv. Inv plin:", inv.plin)
			elif data.slot_type == "no_inv" and self.slot_type == "inventory":
				
				print("Mutat item din no_inv în inventory. Inv plin:", inv.plin)

			# Acum schimbăm efectiv itemele între sloturi
			var temp = target_property
			set_property(source_property)
			data.set_property(temp)
			print("Itemele au fost schimbate între sloturi.")

	#else:
		#print("Nu s-a putut face drop-ul.")
	if self.slot_type == "armor":
		emit_signal("clothes_changed", get_id())
	
	
	
	## Actualizează cantitatea pentru ambele sloturi
	#cantitate = property["CANTITATE"]
	#label.text = str(cantitate)
	#if cantitate <= 0:
		#label.text = ""

func _ready():
	# Conectează semnalul de selecție
	connect("gui_input",Callable( self, "_on_gui_input"))


	

func _on_gui_input(event):

	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("double_clicked", self)

	
	if event is InputEventMouseButton and event.pressed:
		is_selected = true
		emit_signal("slot_selected", self)
		
	if slot_type=="tray":
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				#raise()  # Aduce panelul în față
			else:
				dragging = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if cantitate>0 and slot_type=="inventory" and get_node("/root/world/CanvasLayer/Masa").visible==true:
			emit_signal("request_tray_spawn", property.duplicate())
			self.clear_item()
		

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position() - drag_offset
		var mouse_pos = get_parent().get_local_mouse_position() - drag_offset
		var rect = get_parent().get_rect()  # Rect2(0,0,w,h)
		
		# Calculează limitele pentru ca itemul să nu iasă din parent
		var min_x = 0
		var min_y = -25
		var max_x = rect.size.x - size.x
		var max_y = rect.size.y - size.y
		
		# Clamp la limite
		position = Vector2(
			clamp(mouse_pos.x, min_x, max_x),
			clamp(mouse_pos.y, min_y, max_y)
		)

		
func select():
	is_selected = true
	

func deselect():
	is_selected = false
	
func clear_item():

	 # Resetează textura la null
	$TextureHolder/TextureRect.texture = null  
	# Resetează textul etichetei la gol
	label.text = ""
	#water_fill.visible=false
	
	# Resetează cantitatea
	cantitate = 0

	# Resetează ID-ul sau alte proprietăți relevante
	property = {"TEXTURE": null, "CANTITATE": 0, "NUMBER": 0, "NUME":""}

	# Marchează slotul ca fiind gol
	filled = false  
	emit_signal("clothes_changed", "")
	
	if slot_type == "tray":
		queue_free()
	# Oprește funcționalitatea drag-and-drop
	#set_drag_preview(null)
	
	
func get_id() -> String:
	if property and property.has("Number") != null:
		for key in ItemData.content.keys():
			if ItemData.content[key]["number"] == number:
				return key
	return "0"
	

func decrease_cantitate(amount: int) -> bool:
	if cantitate > 0:
		cantitate -= amount  # Scade cantitatea
		property["CANTITATE"]=cantitate
		if cantitate <= 0:
			cantitate = 0  # Asigură-te că nu e negativă
			clear_item()  # Curăță slotul dacă cantitatea ajunge la 0
			return true  # Itemul trebuie eliminat
			
		else:
			label.text = str(cantitate)  # Actualizează eticheta
		return false  # Itemul încă are cantitate, deci nu trebuie eliminat
	return true  # Itemul deja nu are cantitate, deci trebuie eliminat


func increase_cantitate(amount: int):
	cantitate += amount
	property["CANTITATE"] = cantitate
	if cantitate > 0:
		# Actualizează cantitatea afișată în UI
		label.text = str(cantitate)
		
	else:
		label.text = ""
		
func add_item(new_item_id: String, amount: int):
	self.set_property({
		"TEXTURE": load("res://assets/" + ItemData.get_texture(new_item_id)),
		"CANTITATE": amount,
		"NUMBER": ItemData.get_number(new_item_id),
		"NUME": ItemData.get_nume(new_item_id)
	})
	self.filled = true
	
func get_item() -> Dictionary:
	# Verificăm dacă slotul conține un item valid
	if filled:
		return {
			"TEXTURE": property["TEXTURE"],  # Textura itemului
			"CANTITATE": property["CANTITATE"],  # Cantitatea
			"NUMBER": property["NUMBER"],  # Numărul/ID-ul itemului
			"NUME": property["NUME"]}
	else:
		return {}  # Returnează un dicționar gol dacă nu există un item
# Verifică dacă există locuri libere în inventar
func has_free_slot() -> bool:
	# Lista sloturilor din inventar
	var slot_list = [slot_container, slot_container_2, slot_container_3, slot_container_4]
	
	# Verifică fiecare slot pentru a vedea dacă există loc liber
	for slot in slot_list:
		if slot.get_id() == "0":  # Presupunem că un slot gol are ID-ul "0"
			return true  # Există un loc libe
	
	return false  # Nu există locuri libere
	
