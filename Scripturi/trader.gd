extends Control

# ─────────────────────────────────────────────────────────────────────────────
var recipes = [
	{
		"name": "Topor",
		"cost":   [ {"id":7, "cantitate":5}, {"raritate":"rara", "cantitate":2} ],
		"reward": [ {"id":2, "cantitate":1}]
	},
	{
		"name": "Sabie",
		"cost":   [ {"id":11, "cantitate":3}, {"raritate":"rara", "cantitate":1} ],
		"reward": [ {"id":14, "cantitate":1} ]
	},
]

# ─────────────────────────────────────────────────────────────────────────────
@onready var player_trade  = $Player_trade
@onready var trader_trade  = $Trader_trade
@onready var result_trade  = $Result_trade
@onready var back_trader   = $Back_trader
@onready var btn_accept    = $Accept

func _ready():
	btn_accept.connect("pressed",Callable( self, "_on_accept_pressed"))
	generate_items_chest()

func _on_accept_pressed():
	# 1) citește ce au pus jucătorul și comerciantul
	var player_items = _gather_container(player_trade)
	var trader_items = _gather_container(trader_trade)

	# 2) găsește prima rețetă care se potrivește
	var matchi = null
	for recipe in recipes:
		if _matches(recipe.cost, player_items) \
		and _matches(recipe.reward, trader_items):
			matchi = recipe
			break

	if matchi == null:
		_show_error("Nu există niciun trade care să corespundă cu ce ai pus!")
		return

	# 3) aplică trade-ul
	#   a) cost → result_trade
	for req in matchi.cost:
		if req.has("id"):
			_transfer_exactly_id  (player_trade, back_trader,   req.id,        req.cantitate)
		else:
			_transfer_by_rarity   (player_trade, back_trader,   req.raritate,   req.cantitate)

	#   b) reward → back_trader
	for req in matchi.reward:
		if req.has("id"):
			_transfer_exactly_id  (trader_trade, result_trade,    req.id,        req.cantitate)
		else:
			_transfer_by_rarity   (trader_trade, result_trade,    req.raritate,   req.cantitate)



func _transfer_exactly_id(src:GridContainer, dst:GridContainer, id:int, amount:int) -> void:
	var rem = amount
	for slot in src.get_children():
		if rem <= 0:
			break
		var s = slot as Slot
		if s.filled and s.get_number() == id:
			var take = min(s.get_cantitate(), rem)
			s.decrease_cantitate(take)
			_add_to_slots(dst, id, take)
			rem -= take

# adună containerul într-un dictionar:
# key = id sau raritate, value = cantitate totală
func _gather_container(container:GridContainer) -> Dictionary:
	var out := {}
	for slot in container.get_children():
		var s = slot as Slot
		if not s.filled: continue
		var id = s.get_number()
		var cnt = s.get_cantitate()
		# 1) pe id
		out[id] = out.get(id, 0) + cnt
		# 2) pe raritate
		var r = ItemData.content[str(id)].raritate
		out[r] = out.get(r, 0) + cnt
	return out

# verifică o listă de req: {"id"/"raritate", cantitate}
func _matches(reqs:Array, items:Dictionary) -> bool:
	for req in reqs:
		var key =  req.id if  req.has("id") else req.raritate
		if items.get(key, 0) < req.cantitate:
			return false
	return true

# ─────────────────────────────────────────────────────────────────────────────
# Verifică dacă `container` conține cel puțin `cantitate` din fiecare `id` din reqs
# Verifică dacă există suficiente iteme de raritatea req.raritate
func _has_sufficient_by_rarity(container:GridContainer, reqs:Array) -> bool:
	for req in reqs:
		var total = 0
		for slot in container.get_children():
			var s = slot as Slot
			if s.filled:
				var id  = s.get_number()
				var r   = ItemData.content[str(id)]["raritate"]
				if r == req.raritate:
					total += s.get_cantitate()
		if total < req.cantitate:
			return false
	return true


# ─────────────────────────────────────────────────────────────────────────────
# Mută exact `amount` din ID-ul `id` din src → dst, folosind stivuire + slot gol
func _transfer_by_rarity(src:GridContainer, dst:GridContainer, rarity:String, amount:int) -> void:
	var rem = amount
	for slot in src.get_children():
		if rem <= 0:
			break
		var s = slot as Slot
		if not s.filled:
			continue
		var id  = s.get_number()
		var r   = ItemData.content[str(id)]["raritate"]
		if r != rarity:
			continue
		var take = min(s.get_cantitate(), rem)
		s.decrease_cantitate(take)
		_add_to_slots(dst, id, take)
		rem -= take

# condivizat cu tine deja:
func _add_to_slots(dst:GridContainer, id:int, qty:int) -> void:
	# 1) stivuire
	for slot in dst.get_children():
		var s = slot as Slot
		if s.filled and s.get_number() == id:
			s.increase_cantitate(qty)
			return
	# 2) slot gol
	for slot in dst.get_children():
		var s = slot as Slot
		if not s.filled:
			s.set_property(_make_item_data(id, qty))
			return
	
func generate_items_chest():
	# Încarcă JSON-ul dintr-un fișier
	var file = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file == null:
		print("Nu s-a putut deschide fișierul JSON.")
		return

	# Parseaază JSON-ul
	var json_text = file.get_as_text()
	file.close()

	var json_data = JSON.parse_string(json_text)

	# Verifică dacă parsing-ul a avut succes


	# Obține datele din JSON - accesează direct dicționarul principal
	var items_dict = json_data  # Modificăm aceasta pentru a lucra direct cu datele JSON

	# Verifică structura JSON-ului
	#print("Structura JSON-ului:", items_dict)

	# Randomizează numărul de sloturi care primesc iteme
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var num_slots_to_fill = rng.randi_range(1, 15)  # De exemplu, între 1 și 4 sloturi
	var slot_list = []
	# Lista sloturilor unde generăm iteme
	for i in $Back_trader.get_children():
		if i is Slot:
			slot_list.append(i)
	slot_list.shuffle()  # Amestecă sloturile pentru aleatorizare

	# Adaugă iteme în sloturile selectate
	for i in range(num_slots_to_fill):
		var slot = slot_list[i]

		# Alege un item aleatoriu din JSON
		var random_index = rng.randi_range(1, items_dict.size() - 1)  # Sărim peste cheia "0"
		var item_data = items_dict[str(random_index)]

		# Verifică dacă itemul există
		if item_data == null:
			print("Itemul nu a fost găsit pentru indexul:", random_index)
			continue
		
		
		# Generează o cantitate aleatorie între 1 și 10 (sau alt interval dorit)
		var random_quantity = rng.randi_range(1, 20)
		
		
		# Încarcă textura folosind load()
		var texture_path = "res://assets/" + item_data["texture"]
		var texture = load(texture_path)

		# Verifică dacă textura a fost încărcată cu succes
		if texture == null:
			print("Textura nu a fost găsită la calea:", texture_path)
			continue

		# Setează proprietățile itemului în slot
		slot.set_property({
			"TEXTURE": texture,
			"CANTITATE": random_quantity,
			"NUMBER": item_data["number"],
			"NUME": item_data["nume"]
		})

# ─────────────────────────────────────────────────────────────────────────────
# Construcție Dictionary pentru Slot.set_property()
func _make_item_data(id:int, cant:int) -> Dictionary:
	var j = ItemData.content[str(id)]
	return {
		"TEXTURE": load("res://assets/" + j.texture),
		"CANTITATE": cant,
		"NUMBER": id,
		"NUME": j.nume,
		"raritate": j.raritate
	}

func _show_error(msg:String):
	print("[ERROR] " + msg)

func _show_message(msg:String):
	print("[OK] " + msg)
