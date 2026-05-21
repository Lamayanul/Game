
extends Control

signal rail_updated

var CardScene = preload("res://User/slot_container_cuppon.tscn")
var rng = RandomNumberGenerator.new()

func clear_rail():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func add_coupon_card(data: Dictionary):
	if data.is_empty() or data.get("TEXTURE") == null:
		return
	var card = CardScene.instantiate()
	card.card_efect = false
	add_child(card)
	card.set_property(data)
	
	# Mărim cardul (factor de 2.0 pentru un echilibru mai bun)
	var scale_factor = 2.0
	card.scale = Vector2(scale_factor, scale_factor)
	
	# Poziționare random în interiorul rail-ului pentru a permite suprapunerea
	rng.randomize()
	# Folosim custom_minimum_size pentru a asigura limite valide chiar și la pornire
	var area_w = custom_minimum_size.x - (64 * scale_factor)
	var area_h = custom_minimum_size.y - (128 * scale_factor)
	
	# Ne asigurăm că limitele sunt pozitive
	area_w = max(50, area_w)
	area_h = max(50, area_h)
	
	card.position = Vector2(rng.randf_range(0, area_w), rng.randf_range(0, area_h))
	
	# Activăm posibilitatea de a trage cardul cu mouse-ul (Drag & Drop intern)
	card.slot_type = "tray" # Reutilizăm logica de dragging existentă în slot_container_cuppon.gd
	
	# Rotație la 90 de grade
	var holder = card.get_node("TextureHolder")
	if holder:
		holder.rotation_degrees = 90
		holder.position.x = 128 # Ajustăm poziția după rotație

	# Fixăm label-ul să nu se mai depărteze
	var label = card.get_node_or_null("TextureHolder/TextureRect/Label")
	if label:
		# Îl rotim invers față de holder ca să fie lizibil
		label.rotation_degrees = -90
		# Îl punem într-o poziție fixă relativă la cardul rotit
		label.position = Vector2(20, 20)
	
	# Conectăm semnalele pentru selecție și deschidere (via dublu click / buton_apasat)
	if not card.is_connected("slot_selected", Callable(self, "_on_card_selected")):
		card.connect("slot_selected", Callable(self, "_on_card_selected"))
	if not card.is_connected("buton_apasat", Callable(self, "_on_coupon_open")):
		card.connect("buton_apasat", Callable(self, "_on_coupon_open"))

func _on_card_selected(card_node):
	# Deselectăm toate celelalte carduri/sloturi
	for child in get_children():
		if child.has_method("deselect"):
			child.deselect()
	# Selectăm cardul curent (asta va face butonul Open vizibil)
	if card_node.has_method("select"):
		card_node.select()

func _on_coupon_open(card_node: Slot_Cup):
	var id = card_node.get_id()
	var drops = DatabaseCuppon.get_random_drops(id)
	
	# 1. Ștergem cuponul (se va șterge și din inv2 prin sync)
	card_node.clear_item()
	
	# 2. Spawnăm itemele ca sloturi NORMALE în Rail
	for drop in drops:
		add_normal_item(drop.id, drop.qty)

func add_normal_item(item_id: String, qty: int):
	var NormalSlotScene = preload("res://User/slot_container.tscn")
	var slot = NormalSlotScene.instantiate()
	slot.slot_type = "tray" # Permite drag-and-drop
	add_child(slot)
	
	# Ascundem fundalul (TextureRect2)
	var tr2 = slot.get_node_or_null("TextureHolder/TextureRect2")
	if tr2: tr2.visible = false
	
	# Încărcăm datele din baza de date normală
	var tex = load("res://assets/" + ItemData.get_texture(item_id))
	var nume = ItemData.get_nume(item_id)
	slot.set_property({
		"TEXTURE": tex,
		"CANTITATE": qty,
		"NUMBER": int(ItemData.get_number(item_id)),
		"NUME": nume,
		"TYPE": ItemData.get_type(item_id)
	})
	
	slot.scale = Vector2(2.0, 2.0)
	# Poziție random
	rng.randomize()
	slot.position = Vector2(rng.randf_range(0, size.x - 100), rng.randf_range(0, 400))

func _on_child_order_changed():
	emit_signal("rail_updated")

func _ready():
	child_order_changed.connect(_on_child_order_changed)

# Funcția care verifică DACĂ putem face drop
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Acceptăm și CardControl și Slot_Cup
	return data is CardControl or data is Slot_Cup

# Funcția care execută logica de drop
func _drop_data(at_position: Vector2, data: Variant):
	var card_node = data
	
	# 1. Scoatem cardul din părintele vechi
	if card_node.get_parent():
		card_node.get_parent().remove_child(card_node)

	# 2. Adăugăm cardul în acest container (Rail)
	add_child(card_node)
	
	# 3. Aplicăm logica de formatare pentru Rail
	if card_node is Slot_Cup:
		card_node.card_efect = false
		card_node.slot_type = "tray"
		
		var scale_factor = 2.0
		card_node.scale = Vector2(scale_factor, scale_factor)
		
		# Repoziționăm la locul drop-ului (relativ la Rail)
		card_node.position = at_position - (card_node.size * 0.5 * scale_factor)
		
		# Rotație la 90 de grade
		var holder = card_node.get_node_or_null("TextureHolder")
		if holder:
			holder.rotation_degrees = 90
			holder.position.x = 128

		# Fix label
		var label = card_node.get_node_or_null("TextureHolder/TextureRect/Label")
		if label:
			label.rotation_degrees = -90
			label.position = Vector2(20, 20)
		
		# Conectăm semnalele pentru selecție și deschidere
		if not card_node.is_connected("slot_selected", Callable(self, "_on_card_selected")):
			card_node.connect("slot_selected", Callable(self, "_on_card_selected"))
		if not card_node.is_connected("buton_apasat", Callable(self, "_on_coupon_open")):
			card_node.connect("buton_apasat", Callable(self, "_on_coupon_open"))
	
	elif card_node is CardControl:
		# Restaurăm cardul normal dacă e CardControl
		card_node.set_compact_mode(false)
		card_node.position = at_position - (card_node.size * 0.5)
