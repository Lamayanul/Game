extends Control

# Provider_page.gd - Gestionează propria afișare și datele (Structură în Scroll continuu)
@onready var lbl_name: Label = $ScrollContainer/VBoxContent/Header/Name
@onready var lbl_funds: Label = $ScrollContainer/VBoxContent/Header/Funds
@onready var lbl_history: RichTextLabel = $ScrollContainer/VBoxContent/History/Text
@onready var grid_inventory: GridContainer = $ScrollContainer/VBoxContent/GridContainer
@onready var banner_node: TextureRect = $ScrollContainer/VBoxContent/Banner

var slot_scene = preload("res://Tabs/provider_slot.tscn")
var current_p_name = ""

func _ready():
	add_to_group("provider_page_group")
	if grid_inventory:
		grid_inventory.columns = 2 
	
	if ItemData.has_signal("inventory_changed"):
		ItemData.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed():
	if visible and current_p_name != "":
		load_provider(current_p_name)

func open_provider_page(p_name: String):
	open_page(p_name)

func open_page(p_name: String):
	print("ProviderPage: open_page called for ", p_name)
	show()
	
	# Gestionăm vizibilitatea celorlalte elemente din părinte
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child != self and child is Control:
				if child.name == "TitleBar" or child.name == "HBoxContainer" or child.name == "BrowserBar":
					child.show()
					continue
				child.hide()
	
	load_provider(p_name)

func load_provider(p_name: String):
	current_p_name = p_name
	
	# 1. SETARE BANNER
	if banner_node:
		var banner_path = _get_banner_path(p_name)
		if ResourceLoader.exists(banner_path):
			banner_node.texture = load(banner_path)
			banner_node.show()
		else:
			banner_node.texture = null
			banner_node.hide()

	# 2. ÎNCĂRCARE DATE
	var data = ItemData.get_provider_data(p_name)
	if data.is_empty(): 
		lbl_name.text = "Eroare: " + p_name
		return
	
	lbl_name.text = p_name
	lbl_funds.text = "Bani disponibili: %d 🍎" % data.get("funds", 0)
	
	lbl_history.clear()
	for line in data.get("history", []):
		lbl_history.add_text("- " + line + "\n")
	
	# 3. CURĂȚARE ȘI POPULARE GRID
	for child in grid_inventory.get_children():
		grid_inventory.remove_child(child)
		child.queue_free()
	
	var inv_list = data.get("inventory", [])
	for item in inv_list:
		if not slot_scene: break
		var inst = slot_scene.instantiate()
		grid_inventory.add_child(inst)
		inst.custom_minimum_size = Vector2(480, 220)
		_populate_provider_slot_advanced(inst, item["id"], item["qty"])

func _get_banner_path(p_name: String) -> String:
	var name_l = p_name.to_lower()
	if "duck" in name_l: return "res://Tabs/header.png"
	if "bit" in name_l: return "res://Tabs/owner_2.png"
	if "food" in name_l: return "res://Tabs/owner_3.png"
	if "lion" in name_l: return "res://Tabs/owner_4.png"
	return ""


func _populate_provider_slot_advanced(inst, item_id, qty):
	var item_data = ItemData.content.get(str(item_id), {})
	if item_data.is_empty(): return

	var lbl_principal = inst.find_child("Principal", true, false)
	if not lbl_principal: lbl_principal = inst.get_node_or_null("RichTextLabel")
	
	var lbl_secundar = inst.find_child("Secundar", true, false)
	if not lbl_secundar: lbl_secundar = inst.get_node_or_null("RichTextLabel2")
	
	var slot_container = inst.find_child("SlotContainer", true, false)
	
	if slot_container:
		var tex_path = "res://assets/" + str(item_data.get("texture", ""))
		var prop = {
			"ID": str(item_id),
			"TEXTURE": load(tex_path) if ResourceLoader.exists(tex_path) else null,
			"CANTITATE": qty,
			"NUMBER": item_data.get("number", 0),
			"NUME": item_data.get("nume", ""),
			"RARITATE": item_data.get("raritate", "comuna")
		}
		if slot_container.has_method("set_property"):
			slot_container.set_property(prop)
		
		if "slot_type" in slot_container:
			slot_container.slot_type = "provider_view"

	if lbl_principal and lbl_principal is RichTextLabel:
		lbl_principal.bbcode_enabled = true
		lbl_principal.text = "[center][color=gray]Stoc disponibil[/color][/center]\n[center][b][font_size=32]%d[/font_size][/b][/center]" % qty

	if lbl_secundar and lbl_secundar is RichTextLabel:
		lbl_secundar.bbcode_enabled = true
		var titlu = str(item_data.get("nume", "Produs Necunoscut")).to_upper()
		var raritate = str(item_data.get("raritate", "comuna")).to_upper()
		var desc = item_data.get("descriere", "Nu există o descriere disponibilă.")
		
		var tipuri = ""
		if item_data.has("type"):
			tipuri = "\n[color=cyan]Categorie: " + ", ".join(item_data["type"]) + "[/color]"
			
		lbl_secundar.text = "[b][font_size=20]%s[/font_size][/b]\n[color=yellow]RARITATE: %s[/color]\n\n[i]%s[/i]%s" % [titlu, raritate, desc, tipuri]
