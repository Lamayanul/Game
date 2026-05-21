extends Button

# Referințe
@onready var target_slot: Slot = $"../SlotContainer"

@onready var input_slot_1: Slot = $SlotContainer
@onready var input_slot_2: Slot = $SlotContainer2
@onready var input_slot_3: Slot = $SlotContainer3

@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var req_icon: TextureRect = $ReqIcon
@onready var req_amount_label: Label = $ReqIcon/ReqAmount

# --- SETĂRI NOI PENTRU CADOU ---
@export var gift_texture: Texture2D 
@export var gift_name: String = "Resursă Bonus"

var rng = RandomNumberGenerator.new()
var current_cost = {} 
var last_seen_item_id = -1 
var items_dict: Dictionary = {}
const RARITY_COLORS = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.2, 0.8, 0.2),
	"rare": Color(0.2, 0.4, 1.0),
	"epic": Color(0.6, 0.2, 0.8),
	"legendary": Color(1.0, 0.6, 0.0)
}

const RECIPE_TABLE = {
	"common": [{"rarity": "common", "amount": 2}, {"rarity": "common", "amount": 3}],
	"uncommon": [{"rarity": "uncommon", "amount": 1}, {"rarity": "common", "amount": 5}],
	"rare": [{"rarity": "rare", "amount": 1}, {"rarity": "uncommon", "amount": 2}],
	"epic": [{"rarity": "epic", "amount": 1}, {"rarity": "rare", "amount": 2}],
	"legendary": [{"rarity": "legendary", "amount": 1}, {"rarity": "epic", "amount": 3}]
}

func _ready():
	rng.randomize()
	pressed.connect(_on_button_pressed)
	var file := FileAccess.open("res://Autoload/Database.json", FileAccess.READ)
	if file != null:
		items_dict = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		push_error("AlternativeBuy: Nu s-a putut încărca Database.json!")

func _process(delta):
	if not _is_slot_valid(target_slot):
		if last_seen_item_id != -1:
			_reset_ui()
		return

	var current_item_id = target_slot.property.get("NUMBER", 0)
	
	if current_item_id != last_seen_item_id:
		last_seen_item_id = current_item_id
		generate_recipe_for_target()

func _reset_ui():
	last_seen_item_id = -1
	current_cost = {}
	req_icon.visible = false
	rich_text_label.text = "Gol"
	# Opțional: Curățăm și sloturile de input când se golește ținta?
	# input_slot_1.clear_item()
	# input_slot_2.clear_item()
	# input_slot_3.clear_item()

func _get_random_item_data_by_rarity(target_rarity: String) -> Dictionary:
	if items_dict.is_empty(): return {}
	
	var candidates: Array = []
	target_rarity = target_rarity.to_lower()
	
	# Filtrăm itemele
	for key in items_dict:
		var item = items_dict[key]
		# Verificăm dacă raritatea se potrivește
		if str(item.get("raritate", "")).to_lower() == target_rarity:
			candidates.append(item)
	
	if candidates.is_empty():
		print("Nu am găsit niciun item în DB cu raritatea: ", target_rarity)
		return {}
		
	# Alegem unul random
	return candidates[rng.randi() % candidates.size()]
	
	

func generate_recipe_for_target():
	var target_rarity = str(target_slot.property.get("RARITATE", "common")).to_lower()
	
	if RECIPE_TABLE.has(target_rarity):
		var possible_costs = RECIPE_TABLE[target_rarity]
		current_cost = possible_costs[rng.randi() % possible_costs.size()]
	else:
		current_cost = {"rarity": "common", "amount": 5}

	_update_requirement_visuals()
	
	# --- AICI VERIFICĂM DACĂ DĂM BONUSUL ---
	_check_and_apply_helper_item()

# --- FUNCȚIA NOUĂ PENTRU BONUS ---
func _check_and_apply_helper_item():
	# 1. Verificăm dacă există ofertă vizibilă
	var offer_node = target_slot.get_node_or_null("Offer")
	if not (offer_node and offer_node.visible):
		return

	# 2. Căutăm un item real cu raritatea necesară
	var required_rarity = current_cost.rarity # Ex: "rare"
	var db_item = _get_random_item_data_by_rarity(required_rarity)
	
	if db_item.is_empty():
		return # Nu am găsit item compatibil

	# 3. Construim datele pentru slot (Convertim din format JSON în format Slot)
	var texture_path = "res://assets/" + str(db_item.get("texture", ""))
	var tex = load(texture_path)
	
	if tex == null: return

	var real_bonus_item = {
		"TEXTURE": tex,
		"CANTITATE": 1,
		"NUMBER": int(db_item.get("number", 0)),
		"NUME": str(db_item.get("nume", "Bonus")),
		"RARITATE": str(db_item.get("raritate", required_rarity)),
		"EFFECTS": db_item.get("effects", []),
		"CURSE": db_item.get("curse", null),
		"TYPE": db_item.get("type", [])
	}
	
	print("🎁 Bonus acordat: ", real_bonus_item["NUME"])

	# 4. Căutăm primul slot GOL și îl punem acolo
	# (Nu suprascriem iteme existente!)
	if not _is_slot_valid(input_slot_1):
		input_slot_1.set_property(real_bonus_item)
	elif not _is_slot_valid(input_slot_2):
		input_slot_2.set_property(real_bonus_item)
	elif not _is_slot_valid(input_slot_3):
		input_slot_3.set_property(real_bonus_item)
func _update_requirement_visuals():
	if current_cost.is_empty(): return
	
	req_icon.visible = true
	req_amount_label.text = "x%d" % current_cost.amount
	
	var needed_rarity = current_cost.rarity.to_lower()
	
	if RARITY_COLORS.has(needed_rarity):
		req_icon.modulate = RARITY_COLORS[needed_rarity]
	else:
		req_icon.modulate = Color.WHITE
	
	rich_text_label.text = "Cere: %s" % needed_rarity.capitalize()

func _on_button_pressed():
	if current_cost.is_empty(): return

	if try_pay_cost(current_cost.rarity, current_cost.amount):
		print("✅ Tranzacție OK")
		
		# LOGICA TA DE CUMPĂRARE AICI
		# inventory.add_item(target_slot.property)
		# target_slot.clear_item()
		
		# După cumpărare, dacă vrei să cureți itemele bonus rămase (opțional):
		# if input_slot_1.property.get("NUMBER") == 9999: input_slot_1.clear_item()
		# ...
		
	else:
		print("❌ Lipsă materiale")
		flash_error()

func flash_error():
	rich_text_label.text = "Nu sunt suficiente iteme"
	req_icon.modulate = Color.RED
	await get_tree().create_timer(0.5).timeout
	_update_requirement_visuals()


# --- Logica de plată (neschimbată) ---
func try_pay_cost(required_rarity: String, required_amount: int) -> bool:
	var total_available = 0
	var needed = required_amount
	
	# Calculăm totalul din TOATE sloturile înainte să decidem
	var qty1 = _get_valid_quantity(input_slot_1, required_rarity)
	var qty2 = _get_valid_quantity(input_slot_2, required_rarity)
	var qty3 = _get_valid_quantity(input_slot_3, required_rarity)
	
	total_available = qty1 + qty2 + qty3
	
	print("💰 TOTAL GĂSIT: ", total_available, " / NECESAR: ", needed)
	
	if total_available < needed: 
		return false 
		
	# ... (urmează partea de consum/decrease_cantitate care e ok) ...
	# Consum slot 1
	if qty1 > 0:
		var take = min(qty1, needed)
		input_slot_1.decrease_cantitate(take)
		needed -= take
	# Consum slot 2
	if needed > 0 and qty2 > 0:
		var take = min(qty2, needed)
		input_slot_2.decrease_cantitate(take)
		needed -= take
	# Consum slot 3
	if needed > 0 and qty3 > 0:
		var take = min(qty3, needed)
		input_slot_3.decrease_cantitate(take)
		needed -= take
		
	return true

func _get_valid_quantity(slot: Slot, req_rarity: String) -> int:
	if not _is_slot_valid(slot): return 0
	
	# 1. Extragem raritatea din slot
	var raw_rarity = slot.property.get("RARITATE")
	if raw_rarity == null: raw_rarity = slot.property.get("raritate", "")
	
	var slot_str = str(raw_rarity).strip_edges().to_lower()
	var req_str = str(req_rarity).strip_edges().to_lower()

	# --- 2. DICTONAR DE TRADUCERE (Fixul) ---
	# Dacă găsim termenul în română, îl transformăm în engleză pentru verificare
	var translations = {
		"comuna": "common",
		"neobisnuita": "uncommon",
		"rara": "rare",
		"epica": "epic",
		"legendara": "legendary"
	}
	
	# Dacă itemul are raritatea "comuna", o schimbăm în "common"
	if translations.has(slot_str):
		slot_str = translations[slot_str]
	# ----------------------------------------

	# 3. Comparăm
	# Acum comparăm "common" (tradus) cu "common" (cerut)
	if slot_str == req_str:
		return int(slot.property.get("CANTITATE", 0))
		
	return 0

func _is_slot_valid(slot: Slot) -> bool:
	if slot == null: return false
	if slot.property == null: return false
	if slot.property.get("TEXTURE") == null: return false
	if slot.property.get("CANTITATE", 0) <= 0: return false
	return true
