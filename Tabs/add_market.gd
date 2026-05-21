extends GridContainer

@export var slot_tab: PackedScene = preload("res://Tabs/market_slot.tscn")
var rng = RandomNumberGenerator.new()

# ---- Setări ----
@export var add_random_affixes := true
@export var chance_random_curse := 0.25
@export var chance_random_effect := 0.60
@export var max_random_effects := 2
@export var amount_jitter := 0.25
@export var duration_jitter := 0.25

const OWNER_ITEMS := {
	"owner_1": ["3", "7", "10", "15"],
	"owner_2": ["4", "9", "11"],
	"owner_3": ["1", "2", "6", "8", "12"],
	"owner_4": ["13", "14", "16"]
}

@onready var zi = get_node("/root/world/Cycle_d_n")

# ---- Setări Promoții & Live ----
@export var promotion_chance := 0.25
@export var promotion_discount := 0.5
@export var enable_live_refresh := true
@export var min_slot_lifetime := 45.0
@export var max_slot_lifetime := 120.0

var items_dict: Dictionary = {}

# ... (Constantele tale pentru preț, RARITY_BASE etc. rămân aici) ...
const RARITY_BASE := {"common": 10, "uncommon": 20, "rare": 50, "epic": 120, "legendary": 300}
const CURSE_WEIGHTS := {"lock": -25, "capped": -20, "heavy": -15, "fragile": -18}
const EFFECT_WEIGHTS := {"regen": 8, "shield": 10, "buff_atk": 12, "swift": 8, "cleanse": 6, "poison": -12, "burn": -10}
const PROVIDER_MULT := {"default": 1.00, "npc": 1.00, "merchant": 1.15, "black_market": 1.30, "friend": 0.80}

# ================================================================
# 1. START: LOGICA DINAMICĂ (CITEȘTE DIN MARKET_INVENTORY)
# ================================================================

func _ready() -> void:
	rng.randomize()
	
	# Încărcăm baza de date pentru detalii tehnice (texturi, nume)
	var file := FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file == null: return
	items_dict = JSON.parse_string(file.get_as_text())
	file.close()

	# Populăm piața cu ce există în Database.gd la start
	refresh_market_view()
	
	if not zi.is_connected("day_changed", Callable(self, "_on_day_changed")):
		zi.connect("day_changed", Callable(self, "_on_day_changed"))

func refresh_market_view() -> void:
	# Curățăm sloturile vechi
	for c in get_children():
		c.queue_free()
		
	# Creăm sloturi pentru fiecare item din market_inventory global
	var items_to_show = ItemData.market_inventory
	for m_item in items_to_show:
		_create_slot_from_data(m_item)

func _create_slot_from_data(m_item: Dictionary) -> void:
	var inst := slot_tab.instantiate()
	var slot := inst.get_node_or_null("SlotContainer")
	if slot == null:
		inst.queue_free()
		return
	
	slot.slot_type = "market"
	add_child(inst)
	
	# PORNIM TIMERUL (Acesta este cel care făcea numărătoarea inversă)
	if enable_live_refresh:
		_start_slot_timer(inst)
	
	# --- SETARE PROVIDER VIZUAL ---
	var provider_node := inst.get_node_or_null("PanelContainer2/Provider")
	var p_name = m_item.get("provider", "Duck's Empire")
	
	# Mapăm numele în UID pentru visuals (duck's empire -> owner_1)
	var p_uid = "owner_1"
	match p_name:
		"Duck's Empire": p_uid = "owner_1"
		"Bit Buyer": p_uid = "owner_2"
		"Factory of FOOD": p_uid = "owner_3"
		"Lions Market": p_uid = "owner_4"
	
	if provider_node and provider_node.has_method("force_provider_visuals"):
		provider_node.force_provider_visuals(p_uid)

	# --- POPULARE DATE ITEM ---
	var item_id = str(m_item["id"])
	var item_data = items_dict.get(item_id, {})
	
	var texture_path := "res://assets/" + String(item_data.get("texture", ""))
	var data_for_slot := {
		"TEXTURE": load(texture_path), 
		"CANTITATE": 1,
		"NUMBER": m_item["qty"], # Afișăm cât are providerul pe stoc în total
		"NUME": String(item_data.get("nume", "")),
		"RARITATE": String(item_data.get("raritate", "")),
		"CURSE": item_data.get("curse", null),
		"EFFECTS": item_data.get("effects", []),
		"TYPE": item_data.get("type", []),
		"DURABILITY": float(item_data.get("durability", 20))
	}
	
	# Adăugăm affixe random (opțional, conform logicii tale)
	if add_random_affixes:
		var types = _types_from_item(item_data)
		_add_random_affixes(data_for_slot, types)

	slot.set_property(data_for_slot)
	
	# --- CALCUL PREȚ ---
	var original_price = _compute_item_price(data_for_slot, p_uid)
	slot.price = original_price
	
	_update_slot_visuals(inst, slot, original_price, original_price, false)

func _on_day_changed(new_day: String) -> void:
	# La fiecare zi nouă, forțăm un refresh al vizualului
	refresh_market_view()

# ================================================================
# 2. GENERATORUL MASIV (MODIFICAT SĂ PORNEASCĂ TIMERE)
# ================================================================

func generate_items_market() -> void:
	# Trecem prin fiecare slot gol creat în _ready
	for inst in get_children():
		if not is_instance_valid(inst): continue
		
		var slot = inst.get_node_or_null("SlotContainer")
		if slot == null: continue
		
		# 1. POPULĂM DATELE (Folosim funcția helper ca să nu duplicăm codul)
		_populate_slot_data(inst, slot)
		
		# 2. PORNIM TIMERUL (Asta e noutatea care face sistemul "viu")
		if enable_live_refresh:
			_start_slot_timer(inst)

# ================================================================
# 3. LOGICA DE REÎNNOIRE (CÂND EXPIRĂ UN SLOT)
# ================================================================

# Se apelează când un timer expiră
func _on_slot_timeout(old_slot: Node) -> void:
	# În loc să creăm unul random, pur și simplu dăm refresh la toată piața 
	# pentru a reflecta starea curentă a depozitelor din Database.gd
	if is_instance_valid(old_slot):
		old_slot.queue_free()
	
	# Așteptăm un cadru pentru a ne asigura că nodul e șters, apoi dăm refresh
	call_deferred("refresh_market_view")

# Funcția veche _populate_slot_data este înlocuită de _create_slot_from_data
# care este mult mai sigură deoarece primește datele direct din Database.gd

# Creează UN singur slot nou (folosit doar la timeout)
# Adăugăm argumentul opțional 'filter_criteria'
func _create_new_slot(filter_criteria: String = "") -> void:
	var inst := slot_tab.instantiate()
	var slot := inst.get_node_or_null("SlotContainer")
	if slot == null:
		inst.queue_free()
		return
	
	slot.slot_type = "market"

	# Adăugăm în scenă
	add_child(inst)
	
	# --- CONECTARE PROVIDER PAGE ---
	if inst.has_signal("request_provider_page"):
		inst.request_provider_page.connect(_on_request_provider_page)
	# -------------------------------

	# Trimitem filtrul mai departe la populare
	var success = _populate_slot_data(inst, slot, filter_criteria)
	
	if success:
		if enable_live_refresh:
			_start_slot_timer(inst)
	else:
		# Dacă nu a găsit iteme (poate filtrul e prea strict), ștergem slotul
		inst.queue_free()

# Pornește timer-ul pe o instanță
func _start_slot_timer(inst: Node) -> void:
	# Verificăm să nu aibă deja timer
	if inst.has_node("SlotLifetimeTimer"): return
	
	var timer = Timer.new()
	timer.name = "SlotLifetimeTimer"
	timer.wait_time = rng.randf_range(min_slot_lifetime, max_slot_lifetime)
	timer.one_shot = true
	timer.timeout.connect(_on_slot_timeout.bind(inst))
	inst.add_child(timer)
	timer.start()
	
	if inst.has_method("set_lifetime_timer"):
		inst.set_lifetime_timer(timer)

# ================================================================
# 4. CREIERUL (POPULATE DATA - CU OWNER RANDOM FIXAT)
# ================================================================

# Adăugăm argumentul opțional 'filter_crit'
func _populate_slot_data(inst: Node, slot: Node, filter_crit: String = "") -> bool:
	if items_dict.is_empty(): return false
	
	var provider_node := inst.get_node_or_null("PanelContainer2/Provider")
	if provider_node == null: return false

	# --- ALEGERE PROVIDER ---
	var all_owner_ids: Array = OWNER_ITEMS.keys()
	var owner_id: String = all_owner_ids[rng.randi_range(0, all_owner_ids.size() - 1)]
	
	if provider_node.has_method("force_provider_visuals"):
		provider_node.force_provider_visuals(owner_id)
	else:
		# Fallback vechi (doar date, fără vizual corect)
		if "provider_uid" in provider_node:
			provider_node.provider_uid = owner_id

	if not OWNER_ITEMS.has(owner_id): return false

	# --- FILTRARE ITEME ---
	var allowed_ids: Array = OWNER_ITEMS[owner_id]
	var valid_items: Array = []
	
	for id in allowed_ids:
		# 1. Verificăm dacă există în baza de date
		if not items_dict.has(id): continue
		
		var item_data = items_dict[id]
		
		# 2. APLICĂM FILTRUL ZILNIC (Dacă există)
		if filter_crit != "":
			# Verificăm tipul (food, weapon etc.)
			var types = _types_from_item(item_data)
			var rarity = String(item_data.get("raritate", "")).to_lower()
			
			# Verificăm dacă filtrul se potrivește cu tipul SAU cu raritatea
			# (ex: "rare" se potrivește cu raritatea, "food" cu tipul)
			var match_found = false
			
			if filter_crit == rarity: 
				match_found = true
			elif filter_crit in types: 
				match_found = true
			
			# Dacă nu se potrivește, sărim peste acest item
			if not match_found:
				continue
		
		# Dacă a trecut de filtre, îl adăugăm
		valid_items.append(id)
	
	# --- VERIFICARE FINALĂ ---
	if valid_items.is_empty():
		# Nu am găsit niciun item la acest provider care să respecte filtrul
		# (Ex: Providerul 1 nu are mâncare, dar e Duminică)
		# Putem returna false (slotul nu se creează) SAU putem încerca alt provider (necesită buclă while)
		print("⚠️ Restock eșuat pentru filtrul '%s' la providerul %s" % [filter_crit, owner_id])
		return false
	# --- ALEGERE ITEM DIN DEPOZIT (Dacă există) ---
	var p_data = ItemData.get_provider_data(owner_id)
	var final_id = ""
	var final_qty = 1

	if not p_data.is_empty() and p_data["inventory"].size() > 0:
		# Alegem un item random din inventarul lui real
		var rand_idx = rng.randi_range(0, p_data["inventory"].size() - 1)
		var p_item = p_data["inventory"][rand_idx]
		final_id = str(p_item["id"])
		final_qty = p_item["qty"]
		print("📦 Providerul %s vinde %s din stocul propriu." % [owner_id, final_id])
	else:
		# Fallback pe generația random dacă providerul nu are inventar definit
		final_id = valid_items[rng.randi_range(0, valid_items.size() - 1)]

	var item_data: Dictionary = items_dict.get(final_id, {})

	# ... restul codului de populare ...
	# Folosim final_id în loc de random_key
	var texture_path := "res://assets/" + String(item_data.get("texture", ""))
	var texture := load(texture_path)
	if texture == null: return false

	var data_for_slot := {
		"TEXTURE": texture, 
		"CANTITATE": 1,
		"NUMBER": final_qty, # Cantitatea din depozit
		"NUME": String(item_data.get("nume", "")),
		"RARITATE": String(item_data.get("raritate", "")),
		"CURSE": item_data.get("curse", null),
		"EFFECTS": item_data.get("effects", []),
		"TYPE": item_data.get("type", []),
		"DURABILITY": float(item_data.get("durability", 20))
	}


	
	
	var types := _types_from_item(item_data)
	if add_random_affixes:
		_add_random_affixes(data_for_slot, types)

	slot.set_property(data_for_slot)
	
	var provider_type := _get_provider_type_from_slot(inst)
	var original_price := _compute_item_price(data_for_slot, provider_type)
	var final_price := original_price
	var is_on_sale := false

	if rng.randf() < promotion_chance:
		is_on_sale = true
		final_price = int(round(original_price * (1.0 - promotion_discount)))
		final_price = max(1, final_price) 

	if "price" in slot:
		slot.price = final_price 
		
	_update_slot_visuals(inst, slot, original_price, final_price, is_on_sale)
	
	return true

# ... (Păstrează restul funcțiilor tale helper: _update_slot_visuals, _compute_item_price, etc. la fel ca înainte) ...

func _update_slot_visuals(inst: Node, slot: Node, original_price: int, final_price: int, is_on_sale: bool) -> void:
	var offer_node = slot.get_node_or_null("Offer")
	if offer_node and offer_node is TextureRect:
		offer_node.visible = is_on_sale
	var price_label := inst.get_node_or_null("PanelContainer3/Price")
	if price_label and price_label is RichTextLabel:
		price_label.bbcode_enabled = true
		if is_on_sale:
			price_label.text = "[s]%d[/s] [color=green]%d[/color] 🍎" % [original_price, final_price]
		else:
			price_label.text = "%d 🍎" % final_price
		if "price_text" in slot and slot.price_text != price_label:
			slot.price_text.text = price_label.text

func _types_from_item(item_data: Dictionary) -> Array:
	var t = item_data.get("type", [])
	if t is String: t = [t]
	var out: Array = []
	if t is Array:
		for x in t: out.append(String(x).to_lower())
	return out
	
# ... (Asigură-te că ai și restul funcțiilor helper: _add_random_affixes, _get_provider_type_from_slot etc. în josul fișierului) ...
func _on_request_provider_page(p_name: String):
	# Găsim browserul în grupul global
	var browser = get_tree().get_first_node_in_group("browser")
	if browser and browser.has_method("open_provider_page"):
		browser.open_provider_page(p_name)
	else:
		print("add_market: Nu s-a găsit browserul în grupul 'browser' sau metoda lipsește.")

func _get_provider_type_from_slot(inst: Node) -> String:
	var p := inst.get_node_or_null("PanelContainer2/Provider")
	if p != null:
		if "provider_type" in p: return String(p.provider_type)
		if p.has_method("get_text"): return String(p.call("get_text"))
		if "text" in p: return String(p.text)
		return String(p.name)
	return "default"
	
func _compute_item_price(data: Dictionary, provider_type: String) -> int:
	var rarity := String(data.get("RARITATE","")).to_lower()
	var base = RARITY_BASE.get(rarity, 10)
	
	# --- INFLUENȚĂ FOREX AMPLFICATĂ ---
	var forex_mult: float = 1.0
	var diff = ItemData.current_forex_price - ItemData.forex_baseline
	forex_mult = 1.0 + (diff * ItemData.forex_sensitivity)
	forex_mult = max(0.1, forex_mult) # Prețul nu scade sub 10% din baza lui
	# ----------------------------------

	var effs = data.get("EFFECTS", [])
	if effs is Dictionary: effs = [effs]
	if effs is Array:
		for e in effs:
			if e is Dictionary:
				var id := String(e.get("id","")).to_lower()
				base += EFFECT_WEIGHTS.get(id, 0)
	var curse = data.get("CURSE", null)
	if curse is Dictionary:
		var cid := String(curse.get("id","")).to_lower()
		base += CURSE_WEIGHTS.get(cid, 0)
	var ptype := provider_type.to_lower()
	var mult = PROVIDER_MULT.get(ptype, PROVIDER_MULT["default"])
	var qty = max(1, int(data.get("CANTITATE", 1)))
	
	# Aplicăm și multiplicatorul forex global
	var price = int(round(max(1.0, float(base) * mult * forex_mult))) * qty
	return max(0, price)

func _add_random_affixes(data_for_slot: Dictionary, types: Array) -> void:
	# CURSE
	var curse_pool := _curse_pool_for_types(types)
	if curse_pool.size() > 0 and rng.randf() < chance_random_curse:
		if not (data_for_slot.get("CURSE", null) is Dictionary):
			data_for_slot["CURSE"] = _make_random_curse_from(curse_pool)

	# EFFECTS
	var eff_pool := _effect_pool_for_types(types)
	if eff_pool.size() > 0 and rng.randf() < chance_random_effect:
		var existing = data_for_slot.get("EFFECTS", null)
		var arr: Array = []
		if existing is Array:
			arr = existing.duplicate(true)
		elif existing is Dictionary:
			arr = [existing]

		var n := rng.randi_range(1, max(1, max_random_effects))
		for _i in range(n):
			arr.append(_make_random_effect_from(eff_pool))
		data_for_slot["EFFECTS"] = arr

# Creează 1 efect random, ajustând amount/duration/period când există
func _make_random_effect_from(pool: Array) -> Dictionary:
	var tpl: Dictionary = _dup(pool[rng.randi_range(0, pool.size() - 1)])
	if tpl.has("amount"):
		tpl["amount"] = _jitter(float(tpl["amount"]), amount_jitter)
	if tpl.has("duration"):
		var dur := float(tpl["duration"])
		if dur > 0.0:
			tpl["duration"] = _jitter(dur, duration_jitter)
		else:
			tpl["duration"] = _round1(dur)
	if tpl.has("period"):
		var per := float(tpl["period"])
		tpl["period"] = _round1(max(0.1, _jitter(per, duration_jitter)))
	return tpl

func _make_random_curse_from(pool: Array) -> Dictionary:
	var tpl: Dictionary = _dup(pool[rng.randi_range(0, pool.size() - 1)])
	if tpl.has("modifiers") and tpl["modifiers"] is Dictionary:
		var mods = tpl["modifiers"]
		for k in mods.keys():
			var v = float(mods[k])
			var nv = _jitter(v, amount_jitter)
			if String(k).ends_with("_mult"):
				nv = max(0.1, nv)
			mods[k] = _round1(nv)
		tpl["modifiers"] = mods
	return tpl

func _dup(d):
	return d.duplicate(true)

func _jitter(val: float, jitter: float) -> float:
	if jitter <= 0.0:
		return val
	var f := 1.0 + rng.randf_range(-jitter, jitter)
	return _round1(max(0.0, val * f))
	
func _round1(x: float) -> float:
	return floor(x * 10.0 + 0.5) / 10.0
	# alternativ: return snapped(x, 0.1)

func _round_if_float(v):
	return _round1(float(v)) if typeof(v) == TYPE_FLOAT else v

func _effect_pool_for_types(types: Array) -> Array:
	var all = _effect_pool()
	if "special" in types:
		return all

	var out: Array = []
	for tpl in all:
		var id = String(tpl.get("id","")).to_lower()
		var mode = String(tpl.get("mode","")).to_lower()
		var ok := false

		if "food" in types:
			# FOOD: poison, regen, buff-uri, swift, cleanse(consumable)
			if id in ["poison","regen","buff_atk","swift"]:
				ok = true
			elif id == "cleanse" and mode == "consumable":
				ok = true

		elif "weapon" in types:
			# WEAPON: poison, burn, buff-uri, cleanse(holding)
			if id in ["poison","burn","buff_atk"]:
				ok = true
			elif id == "cleanse" and mode == "holding":
				ok = true

		elif "cloth" in types:
			# CLOTH: regen, cleanse(holding)
			if id == "regen":
				ok = true
			elif id == "cleanse" and mode == "holding":
				ok = true

		elif "tool" in types:
			# TOOL: ceva safe – swift + cleanse(holding)
			if id == "swift":
				ok = true
			elif id == "cleanse" and mode == "holding":
				ok = true

		else:
			# fallback: orice
			ok = true

		if ok:
			out.append(tpl)
	return out


func _effect_pool() -> Array:
	return [
		{"id":"regen","mode":"consumable","amount":3,"duration":10.0,"period":1.0,"tags":["heal","over_time"]},
		{"id":"poison","mode":"consumable","amount":1,"duration":8.0,"period":1.0,"tags":["poison","dot"]},
		{"id":"burn","mode":"consumable","amount":2,"duration":6.0,"period":1.0,"tags":["burn","dot"]}, # NOU
		{"id":"shield","mode":"consumable","amount":20,"duration":10.0,"tags":["shield"]},
		{"id":"buff_atk","mode":"consumable","duration":15.0,"modifiers":{"atk_add":5},"tags":["buff","atk"]},
		{"id":"swift","mode":"consumable","duration":12.0,"modifiers":{"spd_mult":1.2},"tags":["buff","spd"]},

		# Cleanse consumable – instant/foarte scurt, curăță DOT (poison/burn)
		{"id":"cleanse","mode":"consumable","duration":0.0,"remove":{"effects":{"tags":["poison","burn"]},"curses":{}},"tags":["cleanse"]},

		# Cleanse holding – permanent cât timp ții itemul (blochează viitoare DOT)
		{"id":"cleanse","mode":"holding","duration":-1.0,"remove":{"effects":{"tags":["poison","burn"]},"curses":{}},"tags":["cleanse"]}
	]


# Curse posibile (compatibile cu StatusEffects.add_curse)
func _curse_pool() -> Array:
	return [
		{"id":"lock","mode":"holding","duration":-1.0,"lock":{"move":true,"drop":true,"unequip":true},"tags":["lock"]},
		{"id":"capped","mode":"holding","duration":-1.0,"modifiers":{"max_hp_cap":60},"tags":["hp","cap"]},
		{"id":"heavy","mode":"holding","duration":-1.0,"modifiers":{"spd_mult":0.8},"tags":["heavy"]},
		{"id":"fragile","mode":"holding","duration":-1.0,"modifiers":{"def_mult":0.7},"tags":["fragile"]}
	]


func _curse_pool_for_types(types: Array) -> Array:
	var all = _curse_pool()
	if "special" in types:
		return all

	# FOOD: nu dăm curse by default (poți schimba dacă vrei)
	if "food" in types:
		return []

	var allowed_ids: Array = []
	if "weapon" in types:
		allowed_ids += ["heavy","fragile","lock"]
	if "cloth" in types:
		allowed_ids += ["fragile","heavy","capped","lock"]
	if "tool" in types:
		allowed_ids += ["heavy"]

	# dacă nu s-a potrivit nimic, fallback pe toate
	if allowed_ids.is_empty():
		return all

	var out: Array = []
	for c in all:
		var id = String(c.get("id","")).to_lower()
		if id in allowed_ids:
			out.append(c)
	return out


# ==== NEW: citește provider type din slot (robust) ====
# ==== FIXAT: citește provider type din `inst` (root-ul scenei) ====


# ==== NEW: setează vizual prețul pe RichTextLabel din slot ====
func _set_slot_price_label(slot: Node, price: int) -> void:
	var price_label := slot.get_node_or_null("Price")
	if price_label == null:
		price_label = slot.find_child("Price", true, false)
	if price_label and price_label is RichTextLabel:
		(price_label as RichTextLabel).bbcode_enabled = true
		(price_label as RichTextLabel).text = "[b]%d[/b]" % price
