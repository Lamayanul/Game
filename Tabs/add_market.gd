extends GridContainer

@export var slot_tab: PackedScene = preload("res://Tabs/market_slot.tscn")
var rng = RandomNumberGenerator.new()

# ---- Setări randomizare (poți ajusta din Inspector) ----
@export var add_random_affixes := true           # activează/dezactivează complet randomizarea
@export var chance_random_curse := 0.25          # șansa să primească un curse (0.0 – 1.0)
@export var chance_random_effect := 0.60         # șansa să primească 1..max_random_effects efecte
@export var max_random_effects := 2              # numărul maxim de efecte random

# Poți ajusta amplitudinea randomizării la amount/duration
@export var amount_jitter := 0.25               # ±25%
@export var duration_jitter := 0.25             # ±25%


const RARITY_BASE := {
	"common": 10,
	"uncommon": 20,
	"rare": 50,
	"epic": 120,
	"legendary": 300
}

const CURSE_WEIGHTS := {
	"lock": -25,
	"capped": -20,
	"heavy": -15,
	"fragile": -18
}

const EFFECT_WEIGHTS := {
	"regen": 8,
	"shield": 10,
	"buff_atk": 12,
	"swift": 8,
	"cleanse": 6,
	"poison": -12,
	"burn": -10
}

const PROVIDER_MULT := {
	"default": 1.00,      # fallback
	"npc": 1.00,
	"merchant": 1.15,
	"black_market": 1.30,
	"friend": 0.80
}

func _ready() -> void:
	rng.randomize()
	var count := rng.randi_range(1, 6)   # vrei 1..6 instanțe întregi
	for i in range(count):
		var inst  := slot_tab.instantiate()
		var slot := inst.get_node("SlotContainer")
		slot.slot_type="market"
		add_child(inst)
		inst.name = "MarketSlot_%d" % i
	generate_items_market()  # acum ai deja copiii instanțiați


#func _ready() -> void:
	#rng.randomize() 
	#var count := rng.randi_range(1, 6)
	#for i in range(count): 
		#var slot := slot_tab.instantiate() 
		#slot.slot_type="market" 
		#add_child(slot) 
		#slot.name = "MarketSlot_%d" % i 
	#generate_items_market()
		
		
func generate_items_market():
	var file := FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file == null:
		print("Nu s-a putut deschide fișierul JSON.")
		return

	var items_dict: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	for ctrl in get_children():
		if not is_instance_valid(ctrl):
			continue

		# aici căutăm copilul "Slot" din fiecare Control
		var slot := ctrl.get_node_or_null("SlotContainer")
		if slot == null or not slot.has_method("set_property"):
			continue

		# alege un item random (sărind cheia "0" dacă ai una)
		var keys := items_dict.keys()
		keys.erase("0")
		if keys.is_empty():
			continue

		var random_key = keys[rng.randi_range(0, keys.size() - 1)]
		var item_data: Dictionary = items_dict.get(random_key, {})
		if item_data.is_empty():
			continue

		# Cantitate
		var qty := 1
		var nume := String(item_data.get("nume", ""))
		if nume in ["topor","axe","backpack","Buzduganul norocului","hoe","pickaxe","scut","stropitoare"]:
			qty = 1
		else:
			qty = 1 # sau rng.randi_range(1, 10)

		# Textura
		var texture_path := "res://assets/" + String(item_data.get("texture", ""))
		var texture := load(texture_path)
		if texture == null:
			print("Textura nu a fost găsită:", texture_path)
			continue

		# Pachetul de date pentru slot
		var data_for_slot := {
			"TEXTURE": texture,
			"CANTITATE": qty,
			"NUMBER": int(item_data.get("number", 0)),
			"NUME": String(item_data.get("nume", "")),
			"RARITATE": String(item_data.get("raritate", "")),
			"CURSE": item_data.get("curse", null),
			"EFFECTS": item_data.get("effects", []),
			"TYPE": item_data.get("type", [])
		}
		var types := _types_from_item(item_data)

		# Adaugă random curse/effects peste ce vine din DB (dacă e activat)
		if add_random_affixes:
			_add_random_affixes(data_for_slot, types)

		# aici aplici datele pe slot, nu pe Control
		slot.set_property(data_for_slot)
		var provider_type := _get_provider_type_from_slot(slot)
		var price := _compute_item_price(data_for_slot, provider_type)
		_set_slot_price_label(slot, price)
		if "price" in slot:
			slot.price = price
			slot.price_text.text = str(price)+" 🍎"


func _types_from_item(item_data: Dictionary) -> Array:
	var t = item_data.get("type", [])
	if t is String: t = [t]
	var out: Array = []
	if t is Array:
		for x in t:
			out.append(String(x).to_lower())
	return out

# ----------------- Random Pools & Helpers -----------------

# Efecte posibile (compatibile cu StatusEffects.add_effect)
# ---- efecte de bază (nu șterge ce aveai, doar adaugă burn + cleanse(consumable)) ----
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


func _dup(d):
	return d.duplicate(true)

func _jitter(val: float, jitter: float) -> float:
	if jitter <= 0.0:
		return val
	var f := 1.0 + rng.randf_range(-jitter, jitter)
	return _round1(max(0.0, val * f))

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
			var nv := _jitter(v, amount_jitter)
			if String(k).ends_with("_mult"):
				nv = max(0.1, nv)
			mods[k] = _round1(nv)
		tpl["modifiers"] = mods
	return tpl


# Adaugă (probabilistic) 1 curse și 1..N effects random peste datele itemului
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

func _compute_item_price(data: Dictionary, provider_type: String) -> int:
	var rarity := String(data.get("RARITATE","")).to_lower()
	var base = RARITY_BASE.get(rarity, 10)

	# + efecte (array de dict-uri)
	var effs = data.get("EFFECTS", [])
	if effs is Dictionary:
		effs = [effs]
	if effs is Array:
		for e in effs:
			if e is Dictionary:
				var id := String(e.get("id","")).to_lower()
				var w = EFFECT_WEIGHTS.get(id, 0)
				# opțional: ține cont și de amount/duration dacă există
				if e.has("amount"):
					w += int(signi(e.get("amount")) * 0)  # simplu; poți crește dacă vrei
				if e.has("duration") and float(e.get("duration")) > 0.0:
					w += 0  # adaugă ponderi dacă dorești
				base += w

	# - curse (un singur curse dict sau nimic)
	var curse = data.get("CURSE", null)
	if curse is Dictionary:
		var cid := String(curse.get("id","")).to_lower()
		base += CURSE_WEIGHTS.get(cid, 0)

	# multiplicator provider
	var ptype := provider_type.to_lower()
	var mult = PROVIDER_MULT.get(ptype, PROVIDER_MULT["default"])

	# cantitatea
	var qty := int(data.get("CANTITATE", 1))
	qty = max(1, qty)

	var price := int(round(max(1.0, float(base) * mult))) * qty
	return max(0, price)  # niciodată negativ

# ==== NEW: citește provider type din slot (robust) ====
func _get_provider_type_from_slot(slot: Node) -> String:
	# Căutăm un nod numit "Provider" în slot sau copii și extragem either:
	#  - o proprietate `provider_type`
	#  - sau `.text`/`.name`
	var p := slot.get_node_or_null("Provider")
	if p == null:
		p = slot.find_child("Provider", true, false)
	if p != null:
		if p.has_method("get_text"):     # ex. Label/LineEdit/… în Godot 3
			return String(p.call("get_text"))
		if "text" in p:                  # Godot 4 property
			return String(p.text)
		if "provider_type" in p:
			return String(p.provider_type)
		return String(p.name)
	return "default"

# ==== NEW: setează vizual prețul pe RichTextLabel din slot ====
func _set_slot_price_label(slot: Node, price: int) -> void:
	var price_label := slot.get_node_or_null("Price")
	if price_label == null:
		price_label = slot.find_child("Price", true, false)
	if price_label and price_label is RichTextLabel:
		(price_label as RichTextLabel).bbcode_enabled = true
		(price_label as RichTextLabel).text = "[b]%d[/b]" % price
