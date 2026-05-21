extends Node

var content:Dictionary= {}

# --- ECONOMIE FOREX ---
var current_forex_price: float = 1.1000
var forex_baseline: float = 1.1000
var price_timer: float = 0.0
var price_update_interval: float = 0.2
var forex_sensitivity: float = 15.0 

# --- SISTEM EVENIMENTE ---
var forex_events: Array[Dictionary] = [] # Evenimente active/viitoare
var forex_history: Array[Dictionary] = [] # Evenimente trecute (pentru desenat)
var event_timer: float = 0.0
var next_event_in: float = 600 # Secunde până la următorul eveniment aleatoriu

# --- SISTEM PROVIDERI ȘI PIAȚĂ ---
var market_inventory: Array = [] # Ce este efectiv la vânzare pe site-ul Market
var restock_timer: float = 0.0
var restock_interval: float = 10.0 # La fiecare 10 secunde verificăm dacă un provider face restock

var providers: Dictionary = {
	"Duck's Empire": {
		"funds": 5000,
		"stock_internal": [
			{"id": "13", "qty_total": 50}, # Scuturi în depozit
			{"id": "14", "qty_total": 30},
			{"id": "25", "qty_total": 10}
		],
		"inventory": [], # Ce are afișat pe pagina proprie (active)
		"history": ["Gata de tranzacționare."]
	},
	"Bit Buyer": {
		"funds": 3000,
		"stock_internal": [
			{"id": "19", "qty_total": 100},
			{"id": "20", "qty_total": 100},
			{"id": "21", "qty_total": 100}
		],
		"inventory": [],
		"history": ["Analizez piața componentelor."]
	},
	"Factory of FOOD": {
		"funds": 1500,
		"stock_internal": [
			{"id": "1", "qty_total": 200},
			{"id": "4", "qty_total": 500},
			{"id": "7", "qty_total": 300}
		],
		"inventory": [],
		"history": ["Recolte noi în pregătire."]
	},
	"Lions Market": {
		"funds": 4500,
		"stock_internal": [
			{"id": "2", "qty_total": 40},
			{"id": "9", "qty_total": 60},
			{"id": "10", "qty_total": 30}
		],
		"inventory": [],
		"history": ["Unelte de calitate garantată."]
	}
}

func get_provider_data(p_name: String) -> Dictionary:
	for key in providers.keys():
		if key.to_lower() == p_name.to_lower():
			return providers[key]
	return {}

func _ready():
	var file = FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	content = JSON.parse_string(file.get_as_text())
	file.close()
	_generate_random_event()
	# Inițializăm piața cu câteva iteme
	for p in providers.keys():
		_process_provider_restock(p, true)

func _process(delta):
	# 1. Simulăm variația prețului
	price_timer += delta
	if price_timer >= price_update_interval:
		price_timer = 0.0
		var volatility = 0.0005 
		current_forex_price += randf_range(-volatility, volatility)
		current_forex_price = clamp(current_forex_price, 0.5000, 2.0000)
	
	# 2. Gestionăm evenimentele
	event_timer += delta
	if event_timer >= next_event_in:
		_trigger_event()
		_generate_random_event()
		
	# 3. Logica de restock provideri
	restock_timer += delta
	if restock_timer >= restock_interval:
		restock_timer = 0.0
		_check_all_providers_for_restock()
		_simulate_npc_activity() # Simulează alte tranzacții în fundal

func _check_all_providers_for_restock():
	var p_names = providers.keys()
	var random_p = p_names[randi() % p_names.size()]
	_process_provider_restock(random_p)

func _simulate_npc_activity():
	# Alegem un provider random
	var p_names = providers.keys()
	var p_name = p_names[randi() % p_names.size()]
	var p = providers[p_name]
	
	# Simulare: Un NPC cumpără ceva ce e DEJA la vânzare (dacă există)
	if not p["inventory"].is_empty() and randf() < 0.6: # 60% șansă să cumpere ceva activ
		var rand_idx = randi() % p["inventory"].size()
		var item_to_buy = p["inventory"][rand_idx]
		var buy_qty = 1
		
		# Folosim funcția de cumpărare (aceeași ca la player) pentru a sincroniza Market Global
		buy_item_from_provider(p_name, item_to_buy["id"], buy_qty)
		print("PIATA: Un NPC a cumparat %s de la %s." % [get_nume(item_to_buy["id"]), p_name])

	# Simulare: Fluctuații în depozitul intern (producție/importuri externe)
	if not p["stock_internal"].is_empty():
		var internal_item = p["stock_internal"][randi() % p["stock_internal"].size()]
		if randf() < 0.2: # 20% șansă să piardă marfă (daune în depozit)
			internal_item["qty_total"] = max(0, internal_item["qty_total"] - randi_range(1, 5))
		elif randf() < 0.4: # 40% șansă să primească marfă nouă în depozit (recepție)
			internal_item["qty_total"] += randi_range(10, 20)
			p["history"].push_front("Recepție: Am primit stoc nou în depozit.")

signal inventory_changed # Semnal pentru a anunța UI-ul să se reîmprospăteze

func buy_item_from_provider(p_name: String, item_id: String, qty: int = 1):
	# 1. Scădem din Market Global
	for i in range(market_inventory.size() - 1, -1, -1):
		var m_item = market_inventory[i]
		if m_item["id"] == item_id and m_item["provider"] == p_name:
			m_item["qty"] -= qty
			if m_item["qty"] <= 0:
				market_inventory.remove_at(i)
			break
			
	# 2. Scădem din inventarul activ al providerului
	var p = providers.get(p_name)
	if p:
		for i in range(p["inventory"].size() - 1, -1, -1):
			var p_item = p["inventory"][i]
			if p_item["id"] == item_id:
				p_item["qty"] -= qty
				if p_item["qty"] <= 0:
					p["inventory"].remove_at(i)
				break
		p["history"].push_front("Vânzare: Am vândut %d unități de %s unui client." % [qty, get_nume(item_id)])
	
	# Notificăm UI-ul să facă refresh
	inventory_changed.emit()

func _process_provider_restock(p_name: String, initial := false):
	var p = providers[p_name]
	var stock = p["stock_internal"]
	if stock.is_empty(): return
	
	# Decidem ce item scoatem pe piață
	var item_index = randi() % stock.size()
	var item = stock[item_index]
	
	# Cantitate random bazată pe Forex
	# Dacă prețul e mic (sub baseline), providerul scoate MAI MULTĂ marfă pe piață
	var forex_factor = forex_baseline / current_forex_price 
	var base_qty = randi_range(1, 5)
	if initial: base_qty = randi_range(5, 15)
	
	var qty_to_list = int(base_qty * forex_factor)
	qty_to_list = clamp(qty_to_list, 1, item["qty_total"])
	
	if qty_to_list <= 0: return

	# Mutăm din depozit în inventarul activ al providerului
	item["qty_total"] -= qty_to_list
	
	# 1. Adăugăm în inventarul specific al providerului (pentru pagina lui)
	var found_in_provider = false
	for active_item in p["inventory"]:
		if active_item["id"] == item["id"]:
			active_item["qty"] += qty_to_list
			found_in_provider = true
			break
	if not found_in_provider:
		p["inventory"].append({"id": item["id"], "qty": qty_to_list})
		
	# 2. Adăugăm în MARKET GLOBAL (ce vede toată lumea pe prima pagină)
	var found_in_market = false
	for m_item in market_inventory:
		if m_item["id"] == item["id"] and m_item["provider"] == p_name:
			m_item["qty"] += qty_to_list
			found_in_market = true
			break
	if not found_in_market:
		market_inventory.append({
			"id": item["id"], 
			"qty": qty_to_list, 
			"provider": p_name,
			"price_base": int(get_number(item["id"])) # Prețul de bază din JSON
		})
		
	# Mesaj de istoric/news
	var reason = ""
	if current_forex_price < forex_baseline:
		reason = "datorită condițiilor favorabile de schimb valutar (Forex: %.4f)" % current_forex_price
	else:
		reason = "în ciuda pieței instabile"
		
	var msg = "Restock: %d unități din produsul %s au fost puse la vânzare %s." % [qty_to_list, get_nume(item["id"]), reason]
	p["history"].push_front(msg)
	if p["history"].size() > 10: p["history"].pop_back()
	
	print("ECONOMIE: ", p_name, " a scos pe piață ", qty_to_list, " bucăți.")

func _generate_random_event():
	event_timer = 0.0
	next_event_in = randf_range(400.0, 800.0) # Eveniment la fiecare 15-40 sec
	
	var types = ["🔥", "💰", "📉", "🚀", "📢", "⚖️"]
	var random_type = types[randi() % types.size()]
	
	var impact = randf_range(-0.02, 0.02) # Saltul de preț (Gap)
	
	forex_events.append({
		"type": random_type,
		"impact": impact,
		"time": Time.get_ticks_msec() + (next_event_in * 1000) # Când se va întâmpla
	})

func _trigger_event():
	if forex_events.size() > 0:
		var event = forex_events.pop_front()
		
		# Aplicăm GAP-ul (Saltul de preț)
		current_forex_price += event["impact"]
		print("📢 EVENT FOREX: ", event["type"], " Impact: ", event["impact"])
		
		# Salvăm în istoric pentru ca graficul să-l deseneze
		event["timestamp"] = Time.get_ticks_msec()
		forex_history.append(event)
		
		# Păstrăm doar ultimele 20 evenimente în istoric
		if forex_history.size() > 20:
			forex_history.pop_front()

func get_texture(ID="0"):
	return content[ID]["texture"]

func get_cantitate(ID="0"):
	return content[ID]["cantitate"]

func get_number(ID="0"):
	return content[ID]["number"]

func get_nume(ID="0"):
	return content[ID]["nume"]

func get_raritate(ID="0"):
	return content[ID]["raritate"]

func get_curse(ID="0"):     # return content.get(id, {}).get("curse", null)
	return content[ID]["curse"]

func get_effects(ID="0"):  #-> Array: return content.get(id, {}).get("effects", []) 
	return content[ID]["effects"]

func get_type(ID="0"):  #-> Array: return content.get(id, {}).get("effects", []) 
	return content[ID]["type"]

func get_ditto(ID="0"):
	return content[ID]["ditto"]

func get_durability(ID="0"):
	return content[ID]["durability"]
