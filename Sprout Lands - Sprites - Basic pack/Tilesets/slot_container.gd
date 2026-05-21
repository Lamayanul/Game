extends PanelContainer
class_name Slot

@onready var texture_rect = $TextureHolder/TextureRect
  # Asigură-te că accesezi corect TextureRect
@onready var label = %Label
@export var is_selected: bool = false
@export var scop =""
var filled:bool=false
var item_id: String = ""  # ID-ul itemului stivuit
@onready var inv = get_node_or_null("/root/world/CanvasLayer/Inv")
@onready var water_fill = get_node_or_null("/root/world/Fantana/CanvasLayer")
@onready var player = get_node_or_null("/root/world/player")
@export var slot_type: String = "inventory"  # Valorile posibile: "inventory", "no_inv", etc.
@onready var price_text: RichTextLabel = get_node_or_null("../PanelContainer3/Price")
@onready var providers: Control = get_node_or_null("../PanelContainer2/Provider")
@onready var description = get_node_or_null("../PanelContainer/ScrollContainer/description")
@onready var buton = get_node_or_null("TextureHolder/Button")
@onready var item_zomm= get_node_or_null("../PanelContainer/ScrollContainer/ItemZomm")

@onready var trend_indicator =get_node_or_null("TextureHolder/Trend")
@export var arrow_up_tex: Texture2D   # Trage aici o săgeată VERDE (în sus)
@export var arrow_down_tex: Texture2D
var _trend_tween: Tween

var price: int = 0

# Proprietatea care definește obiectul din slot
var property_1: Dictionary = {}

const DEFAULT_ITEM := {
	"TEXTURE": null,
	"CANTITATE": 0,
	"NUMBER": 0,
	"NUME": "",
	"RARITATE": "",
	"EFFECTS": [],
	"CURSE": null,
	"DITTO":false
}

@onready var slot_container = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer")
@onready var slot_container_2 = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer2")
@onready var slot_container_3 = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer3")
@onready var slot_container_4 = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer/SlotContainer4")

signal clothes_changed(new_clothes_id)
signal slot_selected(slot)
#signal item_changed
signal request_tray_spawn(item_data)
signal browser(data)
var dragging := false
var drag_offset := Vector2.ZERO
signal request_total_money_update(delta:int)
@export var context: String = ""  # "storage" sau "fight"
signal send_to_storage(item_data: Dictionary)
signal item_activated(slot)

@export var nume: String:
	set(value):
		nume=value
		
		
@export var durability:float:
	set(value):
		durability=value
	
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

@export var ditto: bool=false:
	set(value):
		ditto=value

@onready var property: Dictionary = {"TEXTURE": null, "CANTITATE": cantitate, "NUMBER":number, "NUME":nume, "RARITATE":raritate, "CURSE":curse, "EFFECTS":effects, "TYPE":type, "DITTO":ditto, "DURABILITY":durability}:
	set(value):
		property = value 
		texture_rect.texture = property["TEXTURE"]  # Actualizează direct textura în TextureRect
		cantitate = property["CANTITATE"]
		number = property["NUMBER"]
		nume = property["NUME"]
		raritate = str(property.get("RARITATE", ""))
		curse = property.get("CURSE", null)
		effects = property.get("EFFECTS", [])
		ditto = property.get("DITTO",false)
		durability = property.get("DURABILITY",0)

@export var curse: Variant = null   # poate fi null sau Dictionary; Variant e cel mai sigur
@export var effects: Variant = null       # listă de efecte din JSON
@export var type: Variant = null  


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
		raritate = str(property.get("RARITATE", ""))
		curse = property.get("CURSE", null)
		effects = property.get("EFFECTS", [])
		type = property.get("TYPE",[])
		ditto = property.get("DITTO",false)
		durability = property.get("DURABILITY",0)
		label.text = str(cantitate)
		if cantitate > 0:
			label.text = str(cantitate)
		else:
			label.text = ""
		if data["TEXTURE"]==null:
			filled=false
		else:
			filled=true
		if slot_type=="market":
			update_description()

	
	
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
	
func get_effects() -> Variant:
	return property.get("EFFECTS", [])

func get_curse() -> Variant:
	return property.get("CURSE", null)

func get_type() -> Variant:
	var t = property.get("TYPE", [])
	if t == null:
		return []
	return t

func get_ditto() -> Variant:
	return property.get("DITTO", false)
	
func get_durability() ->float:
	return property.get("DURABILITY",0)

func set_item_crafting():
	emit_signal("item_changed")
	
	
func set_item(item_idx):
	emit_signal("clothes_changed", item_idx)
	

func _normalize_property(src: Dictionary) -> Dictionary:
	var d := DEFAULT_ITEM.duplicate(true)
	for k in src.keys():
		d[k] = src[k]
	return d
	
func _get_drag_data(_at_position):
	if slot_type == "void":
		return null
	if slot_type == "tray":
		return self
		
	var preview_texture = TextureRect.new()
	
	preview_texture.texture = texture_rect.texture
	preview_texture.expand_mode = 1
	preview_texture.size = Vector2(49, 49)
	
	var preview = Control.new()
	preview.add_child(preview_texture)
	
	set_drag_preview(preview)

	return self


func _can_drop_data(_at_position, data):
	# Permitem doar dacă data e un Slot valid
	if not is_instance_valid(data) or not (data is Slot):
		return false
		
	var se = player.get_node_or_null("StatusEffects") as StatusEffects
		
	if se and not se.can_move_slot(data):
		return false
	
	if se and self.get_texture() != null and not se.can_move_slot(self):
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
	if not is_instance_valid(data) or not (data is Slot):
		return  # Asigură-te că datele droppate provin dintr-un slot valid

	var se = player.get_node_or_null("StatusEffects") as StatusEffects

	if se and not se.can_move_slot(data):
		return
		
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
		# Stivuim DOAR dacă ID + (CURSE,EFFECTS) sunt IDENTICE
		if _can_stack_props(source_property, target_property):
			target_property["CANTITATE"] += int(source_property.get("CANTITATE", 0))
			data.clear_item()
			set_property(target_property)
		else:
	# opțional: blochează complet swap între normal și cursed
			if _is_mixed_normal_vs_cursed(source_property, target_property):
		# aici poți afișa un mesaj / sunet și pur și simplu să nu faci nimic
				return

	# altfel, swap normal
			var temp = target_property
			set_property(source_property)
			data.set_property(temp)


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		emit_signal("item_activated", self)
		return 
	# Detectează click-ul pentru a selecta slotul
	if event is InputEventMouseButton and event.pressed:
		is_selected = true
		emit_signal("slot_selected", self)
	if slot_type=="tray" or slot_type=="void":
		if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT):
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				z_index = 0
				move_to_front()
			else:
				dragging = false
			accept_event()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if cantitate>0 and slot_type=="inventory" and get_node("/root/world/CanvasLayer/Masa").visible==true:
			emit_signal("request_tray_spawn", property.duplicate())
			self.clear_item()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if slot_type=="comslot":
			if cantitate > 0:
				emit_signal("send_to_storage", property.duplicate(true))
				self.decrease_cantitate(1)

	




func _process(delta):
	if filled and "food" in get_type() and slot_type != "market":
		if decrease_durability(delta):
			pass # Food spoiled logic handled in decrease_durability (clear_item)
	if dragging:
		# Safety check: if mouse button is released outside, stop dragging
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			dragging = false
			return
			
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
	if dragging and scop=="tab":
		global_position = get_global_mouse_position() - drag_offset
		var mouse_pos = get_parent().get_local_mouse_position() - drag_offset
		var rect = get_parent().get_rect()  # Rect2(0,0,w,h)
		
		# Calculează limitele pentru ca itemul să nu iasă din parent
		var min_x = 0
		var min_y = 0
		var max_x = rect.size.x - size.x
		var max_y = rect.size.y - size.y
		
		# Clamp la limite
		position = Vector2(
			clamp(mouse_pos.x, min_x, max_x),
			clamp(mouse_pos.y, min_y, max_y)
		)

func decrease_durability(amount: float) -> bool:
	if filled:
		if _has_tag_or_id("unbreakable"):
			return false
		durability -= amount
		property["DURABILITY"] = durability
				# Optional: Update visual for durability here
		if durability <= 0:
			clear_item()
			return true # Item broke/expired
	return false
func _has_tag_or_id(needle: String) -> bool:
		# Check curse
	if curse is Dictionary:
		if str(curse.get("id", "")).to_lower() == needle: return true
		var tags = curse.get("tags", [])
		if tags is Array:
			for t in tags:
				if str(t).to_lower() == needle: return true
		# Check effects
	var effs = effects
	if effs is Dictionary: effs = [effs]
	if effs is Array:
			for e in effs:
				if e is Dictionary:
					if str(e.get("id", "")).to_lower() == needle: return true
					var tags = e.get("tags", [])
					if tags is Array:
						for t in tags:
							if str(t).to_lower() == needle: return true
	return false
		
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
	property = {"TEXTURE": null, "CANTITATE": 0, "NUMBER": 0, "NUME":"","RARITATE":"", "EFFECTS":[], "CURSE":null, "TYPE":[]}
	
	# Marchează slotul ca fiind gol
	filled = false  
	emit_signal("clothes_changed", "")
	
	if slot_type == "tray":
		queue_free()
	# Oprește funcționalitatea drag-and-drop
	#set_drag_preview(null)
	
	
func get_id() -> String:
	if property and property.has("NUMBER"):
		var target_number = int(property["NUMBER"])
		for key in ItemData.content.keys():
			if int(ItemData.content[key].get("number", -1)) == target_number:
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
	# dacă vrei să rămână compatibilă, întoarce tot property
	return property.duplicate(true)

# sau un nou helper:
func get_full_item() -> Dictionary:
	return property.duplicate(true)
	

# Verifică dacă există locuri libere în inventar
func has_free_slot() -> bool:
	# Lista sloturilor din inventar
	var slot_list = [slot_container, slot_container_2, slot_container_3, slot_container_4]
	
	# Verifică fiecare slot pentru a vedea dacă există loc liber
	for slot in slot_list:
		if slot.get_id() == "0":  # Presupunem că un slot gol are ID-ul "0"
			return true  # Există un loc libe
	
	return false  # Nu există locuri libere
	
# Adaugă un efect (ca Dictionary) la instanța din slot
func add_effect_dict(e: Variant) -> void:
	#var arr: Array = property.get("EFFECTS", [])
	#arr.append(e)
	property["EFFECTS"] = e
	# dacă ai UI/tooltip, emite un semnal aici

# Setează/înlocuiește blestemul (Dictionary sau null)
func set_curse_dict(c: Variant) -> void:
	# c poate fi Dictionary sau null
	property["CURSE"] = c
	# semnal pt. UI dacă e nevoie

func _normalize_effects(v) -> Array:
	if v == null: return []
	if v is Array: return v
	if v is Dictionary: return [v]
	return []

func _effect_fp(e: Dictionary) -> String:
	var id     := str(e.get("id","")).to_lower()
	var mode   := str(e.get("mode",""))
	var amount := str(e.get("amount", 0))
	var dur    := str(e.get("duration", 0))   # scoate dacă nu vrei să conteze durata
	var period := str(e.get("period", 1))
	var tags   := ""
	if e.has("tags") and e["tags"] is Array:
		var t := []
		for x in e["tags"]:
			t.append(str(x).to_lower())
		t.sort()
		tags = ",".join(t)
	return "%s|%s|%s|%s|%s|%s" % [id, mode, amount, dur, period, tags]

func _effects_sig(v) -> String:
	var arr := _normalize_effects(v)
	var sigs := []
	for e in arr:
		if e is Dictionary:
			sigs.append(_effect_fp(e))
	sigs.sort()
	return "|".join(sigs)

func _curse_sig(v) -> String:
	if v == null or not (v is Dictionary): return ""
	var id   := str(v.get("id","")).to_lower()
	var mode := str(v.get("mode",""))
	var tags := ""
	if v.has("tags") and v["tags"] is Array:
		var t := []
		for x in v["tags"]:
			t.append(str(x).to_lower())
		t.sort()
		tags = ",".join(t)
	var mods_sig := ""
	if v.has("modifiers") and v["modifiers"] is Dictionary:
		var keys = v["modifiers"].keys()
		keys.sort()
		var parts := []
		for k in keys:
			parts.append("%s=%s" % [str(k), str(v["modifiers"][k])])
		mods_sig = "|".join(parts)
	return "%s|%s|%s|%s" % [id, mode, mods_sig, tags]

func _props_sig(p: Dictionary) -> String:
	return "%s||%s" % [_curse_sig(p.get("CURSE", null)), _effects_sig(p.get("EFFECTS", null))]

func _can_stack_props(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("NUMBER", -1)) != int(b.get("NUMBER", -2)):
		return false
	return _props_sig(a) == _props_sig(b)

# opțional: dacă vrei să BLOCHEZI swap între normal și cursed
func _is_mixed_normal_vs_cursed(a: Dictionary, b: Dictionary) -> bool:
	var sa := _props_sig(a)
	var sb := _props_sig(b)
	var empty_a := sa == "||"
	var empty_b := sb == "||"
	return empty_a != empty_b

func _bb(s) -> String:
	# escape minim pentru BBCode (dacă ai nume cu [ ] )
	return str(s).replace("[", "\\[").replace("]", "\\]")

func _arr_to_str(a) -> String:
	if a is Array and not a.is_empty():
		var out := []
		for v in a:
			out.append(str(v))
		return ", ".join(out)
	return ""

func _mods_lines(d: Dictionary, indent := "    ") -> Array:
	var lines: Array = []
	if not (d.has("modifiers") and d["modifiers"] is Dictionary):
		return lines
	var keys = d["modifiers"].keys()
	keys.sort()
	for k in keys:
		lines.append("%s- %s: %s" % [indent, String(k), str(d["modifiers"][k])])
	return lines

func _human_mode(m) -> String:
	var s := str(m)
	if s == "" or s.to_lower() == "holding":
		return "holding"
	if s.to_lower() == "consumable" or s.to_lower() == "comsumable":
		return "consumable"
	return s

func _human_dur(d) -> String:
	if typeof(d) in [TYPE_NIL, TYPE_BOOL] or float(d) == 0:
		return "instant"
	var fd = float(d)
	return "permanent" if fd < 0 else "%d" % fd

func update_description() -> void:
	if description == null:
		return

	var p := property if property is Dictionary else {}
	var lines: Array = []

	# HEAD
	var name := _bb(p.get("NUME",""))
	var rar  := str(p.get("RARITATE","")).to_lower()
	var qty  := int(p.get("CANTITATE", 0))
	var idn  := int(p.get("NUMBER", 0))

	# culoare raritate (opțional)
	var rar_color = {
		"common": "#B0B0B0",
		"uncommon": "#34c759",
		"rare": "#3399ff",
		"epic": "#a335ee",
		"legendary": "#ff8000",
	}.get(rar, "#ffffff")

	lines.append("[b]%s[/b]" % name)
	if rar != "":
		lines.append("[color=%s][i]%s[/i][/color]" % [rar_color, rar])
	lines.append("Cantitate: %d" % qty)
	lines.append("ID produs: %d" % idn)

	# CURSE
	var c = p.get("CURSE", null)
	if c is Dictionary and not c.is_empty():
		#lines.append("") # spațiu
		lines.append("[b]Curse[/b]")
		lines.append(" • id: %s" % _bb(c.get("id","")))
		lines.append(" • mode: %s" % _human_mode(c.get("mode","holding")))
		lines.append(" • duration: %s" % _human_dur(c.get("duration", -1)))
		var tags = c.get("tags", [])
		if tags is Array and not tags.is_empty():
			lines.append(" • tags: %s" % _arr_to_str(tags))
		# modifiers (atk_add, max_hp_cap, *_mult etc.)
		lines += _mods_lines(c)
		# lock (dacă există)
		if c.has("lock"):
			lines.append(" • lock: %s" % str(c.get("lock")))
		# orice alte câmpuri extra utile
		if c.has("extra"):
			lines.append(" • extra: %s" % str(c.get("extra")))

	# EFFECTS (poate fi dicționar sau array)
	var eff_raw = p.get("EFFECTS", null)
	var effs: Array = []
	if eff_raw is Array:
		effs = eff_raw
	elif eff_raw is Dictionary:
		effs = [eff_raw]
	if not effs.is_empty():
		lines.append("")
		lines.append("[b]Efecte[/b]")
		for e in effs:
			if not (e is Dictionary): 
				continue
			var eid := _bb(e.get("id",""))
			var mode := _human_mode(e.get("mode",""))
			var amount = e.get("amount", null)
			var dur    = e.get("duration", null)
			var period = e.get("period", null)
			var etags  = e.get("tags", [])

			lines.append(" • %s%s" % [eid, " (%s)" % mode if mode != "" else ""])
			var sub := []
			if amount != null: sub.append("amount=%s" % str(amount))
			if dur    != null: sub.append("duration=%s" % _human_dur(dur))
			if period != null: sub.append("period=%s" % float(period))
			if etags is Array and not etags.is_empty():
				sub.append("tags=%s" % _arr_to_str(etags))
			if not sub.is_empty():
				lines.append("    " + "; ".join(sub))
			# modifiers în efect temporar (dacă ai astfel de efecte-buff)
			lines += _mods_lines(e)

	# SCRIE în RichTextLabel
	description.bbcode_enabled = true
	description.bbcode_text = "\n".join(lines)
	description.visible = true


func _on_button_pressed() -> void:

	
	# verifică dacă există referință validă la total_money_text
	var browser_tab = get_tree().get_first_node_in_group("browser")
	
	if browser_tab == null:
		return
	
	var royal_tab : PackedScene = load("res://Tabs/tab_fight.tscn")
	var pc_tab = get_tree().get_first_node_in_group("pc")
	if is_instance_valid(pc_tab):
		var fight = royal_tab.instantiate()
		pc_tab.add_child(fight)
		
	if pc_tab==null:
		pass
		
		
	#var royal_fight = get_node("/root/world/CanvasLayer/Control/Royal_battle")
	#royal_fight.visible=true

	# verificare bani
	if browser_tab.slot_container.cantitate < price:  #browser_tab.total_money_site < price
		print("Nu ai destui bani pentru acest item!")
		return  # oprește achiziția

	# ai destui bani → scade prețul
	emit_signal("request_total_money_update", -price)

	# --- SINCRONIZARE CU DEPOZITUL ---
	if slot_type == "market":
		# Căutăm cine este providerul acestui slot
		var p_node = get_node_or_null("../PanelContainer2/Provider")
		if p_node and "name_label" in p_node:
			var p_name = p_node.name_label.text
			ItemData.buy_item_from_provider(p_name, get_id(), 1)
	# ---------------------------------

	# logica existentă
	if self.cantitate > 0:
		var src_data = property.duplicate(true)
		browser.emit(src_data)
		self.clear_item()
		if src_data.is_empty(): return
		if self.cantitate == 0:
			$TextureHolder/Button.disabled = true
			$"../PanelContainer/ScrollContainer/description".text = ""
			$"../PanelContainer3/Price".text = ""


func _on_button_2_pressed() -> void:
	item_zomm.visible = !item_zomm.visible
	description.visible = !description.visible
	

func show_trend(is_increase: bool):
	if not trend_indicator: return
	
	# 1. Setăm textura și culoarea
	if is_increase:
		trend_indicator.texture = arrow_up_tex
		trend_indicator.modulate = Color.GREEN # Sau alb, dacă textura e deja verde
	else:
		trend_indicator.texture = arrow_down_tex
		trend_indicator.modulate = Color.RED # Sau alb, dacă textura e deja roșie
		
	# 2. Animația (Apare -> Stă -> Dispare)
	if _trend_tween: _trend_tween.kill()
	_trend_tween = create_tween()
	
	# Resetăm starea
	trend_indicator.scale = Vector2(0.5, 0.5)
	trend_indicator.modulate.a = 0.0
	trend_indicator.visible = true
	
	# Pop in
	_trend_tween.tween_property(trend_indicator, "modulate:a", 1.0, 0.2)
	_trend_tween.parallel().tween_property(trend_indicator, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Așteaptă
	_trend_tween.tween_interval(0.5)
	
	# Fade out
	_trend_tween.tween_property(trend_indicator, "modulate:a", 0.0, 0.3)
