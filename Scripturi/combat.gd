# BattleRoot.gd
extends Control

enum State { INTRO, PLAYER_TURN, PLAYER_SELECT, RESOLVE_PLAYER, ENEMY_TURN, RESOLVE_ENEMY, WIN, LOSE, RUN_AWAY }

# ---------- UI ----------
@onready var log_player: RichTextLabel = $CanvasLayer/PanelContainer/Fundal/Panel/Player_move
@onready var log_enemy:  RichTextLabel = $CanvasLayer/PanelContainer/Fundal/Panel/Enemy_move

@onready var p_name:   RichTextLabel      = $CanvasLayer/Player_ele/RichTextLabel
@onready var p_hp_bar: TextureProgressBar = $CanvasLayer/Player_ele/TextureProgressBar
@onready var p_hp_txt: Label              = $CanvasLayer/Player_ele/Label

# Enemy UI references are now dynamic
@onready var enemy_container = $CanvasLayer/Enemy_ele
@onready var player_container = $CanvasLayer/Player_ele

# Grid 1 (Main)
@onready var main_menu:     GridContainer = $CanvasLayer/GridContainer
@onready var btn_attack:    Button        = $CanvasLayer/GridContainer/Attack
@onready var btn_defense:   Button        = $CanvasLayer/GridContainer/Defense
@onready var btn_item:      Button        = $CanvasLayer/GridContainer/Item
@onready var btn_surrender: Button        = $CanvasLayer/GridContainer/Surrender


# Grid 2 (Moves)
@onready var moves_menu: GridContainer = $CanvasLayer/GridContainer2
@onready var move_btns: Array[Button] = [
	$CanvasLayer/GridContainer2/Move1,
	$CanvasLayer/GridContainer2/Move2,
	$CanvasLayer/GridContainer2/Move3
]
@onready var btn_back: Button = $CanvasLayer/GridContainer2/Back

# Inventar UI (opțional: pune nodul în group "inventory_ui" dacă path-ul diferă)
@onready var inv_ui := get_node_or_null("/root/world/CanvasLayer/Inv")
const BLOCK_MODE := "raw"    # "raw"   -> dmg = max(0, power - block)
							 # "formula" -> dmg = formula(_calc_damage) pe (power - block)
const BLOCK_ACROSS_LANES := true  # true = block se aplică și pe linii diferite
const DEBUG_COMBAT := false
# ---------- State ----------
var state: State = State.INTRO
var selected_move_idx: int = -1


# ---------- Actori ----------
var player = {
	"name":"Le Creator-sama", "hp":100, "max_hp":100,
	"moves":[],
	"guard_lane":""
}
var enemy = {
	"name":"Enemy", "hp":100, "max_hp":100,
	"moves":[],
	"guard_lane":"",
	"heal_threshold": 0.5,
	"heal_chance": 0.5
}


# ---------- Liste pentru meniul 2 ----------
var attack_moves: Array = []
var defense_moves: Array = []
var _current_move_list: Array = []
var _current_mode: String = "" # "attack" | "defense"

func _ready() -> void:
	randomize()

	# Conectări UI
	btn_attack.pressed.connect(_on_btn_attack)
	btn_defense.pressed.connect(_on_btn_defense)
	btn_item.pressed.connect(_on_btn_item)
	btn_surrender.pressed.connect(_on_btn_surrender)
	btn_back.pressed.connect(_on_btn_back)

	for i in move_btns.size():
		var idx := i
		move_btns[i].pressed.connect(func(): _on_move_pressed(idx))

	# Conectare la inventar (Player)
	if is_instance_valid(inv_ui) and inv_ui.has_signal("weapon_equip_request"):
		inv_ui.weapon_equip_request.connect(func(wid): _on_weapon_from_inventory(wid, player))
	
	# --- CONNECT CREATOR UI ---
	var p_card = _get_player_card()
	if p_card and p_card.has_signal("action_selected"):
		p_card.action_selected.connect(_on_creator_action_selected)

	for n in get_tree().get_nodes_in_group("inventory_ui"):
		if n.has_signal("weapon_equip_request"):
			# Verificăm dacă inventarul aparține unui inamic
			var is_enemy_inv = false
			var p = n.get_parent()
			while p:
				if p.is_in_group("enemy"):
					is_enemy_inv = true
					break
				p = p.get_parent()
			
			if is_enemy_inv:
				if not n.is_connected("weapon_equip_request", Callable(self, "_on_enemy_weapon_request")):
					n.weapon_equip_request.connect(_on_enemy_weapon_request)
			else:
				if not n.is_connected("weapon_equip_request", Callable(self, "_on_weapon_from_inventory")):
					n.weapon_equip_request.connect(func(wid): _on_weapon_from_inventory(wid, player))
	
	# Populate Enemy UI Inventory
	call_deferred("_populate_enemy_ui_inventory")
	call_deferred("_populate_player_ui_inventory")

	# Echipări inițiale
	_equip_weapon(player, "FIST")
	
	# Auto-equip enemy based on inventory
	call_deferred("_auto_equip_enemy")
	
	_split_player_moves()
	_setup_ui()
	_player_turn()

func _on_enemy_weapon_request(weapon_id: String):
	_on_weapon_from_inventory(weapon_id, enemy)

func _on_weapon_from_inventory(weapon_id: String, actor: Dictionary = player) -> void:
	_equip_weapon(actor, weapon_id)
	if actor == player:
		_split_player_moves()
		if moves_menu.visible and _current_mode != "":
			_show_moves_menu(_current_mode)

func _auto_equip_enemy():
	var weapons = _scan_enemy_inventory_for_weapons()
	var best_weapon = "FIST"
	
	for w in weapons:
		if WeaponsBD.has_weapon(w) and w != "FIST":
			best_weapon = w
			break
	
	_equip_weapon(enemy, best_weapon)
	# Force visual update
	var card = _get_enemy_card()
	if card and card.has_method("set_weapon_ui"):
		card.set_weapon_ui(best_weapon)

func _populate_enemy_ui_inventory():
	var card = _get_enemy_card()
	if not card: return
	
	var items_for_combat = []
	var inv_data = enemy.get("inventory", [])
	
	for i in range(inv_data.size()):
		var item_def = inv_data[i]
		items_for_combat.append({
			"id": item_def["id"],
			"qty": item_def["qty"],
			"curse": item_def.get("curse", null),
			"effects": item_def.get("effects", [])
		})
	
	if card.has_method("fill_combat_slots"):
		card.fill_combat_slots(items_for_combat)
		
	# Fallback/Legacy: also fill the side inventory if it exists
	var inv_node = card.get_node_or_null("TextureRect/Inv/MarginContainer/GridContainer")
	if inv_node:
		for slot in inv_node.get_children():
			if slot.has_method("clear_item"): slot.clear_item()
		var slots = inv_node.get_children()
		for i in range(min(slots.size(), inv_data.size())):
			var item_def = inv_data[i]
			var slot = slots[i]
			if slot.has_method("add_item"):
				slot.add_item(item_def["id"], item_def["qty"])

func _populate_player_ui_inventory():
	var card = _get_player_card()
	if not card: return
	
	var items_for_combat = []
	# Find world inventory
	var world_inv = get_node_or_null("/root/world/CanvasLayer/Inv")
	if not world_inv: world_inv = get_node_or_null("/root/world/CanvasLayer3/Inv")
	
	if is_instance_valid(world_inv):
		var w_grid = world_inv.get_node_or_null("MarginContainer/GridContainer")
		if w_grid:
			for w_slot in w_grid.get_children():
				if w_slot.has_method("get_id") and w_slot.filled:
					items_for_combat.append({
						"id": w_slot.get_id(),
						"qty": w_slot.get_cantitate(),
						"curse": w_slot.get_curse(),
						"effects": w_slot.get_effects()
					})
	
	if card.has_method("fill_combat_slots"):
		card.fill_combat_slots(items_for_combat)

# ---------- Helper Dynamic UI ----------
func _get_enemy_card() -> Node:
	if enemy_container.get_child_count() > 0:
		# Assume last added child is the active card (or first if only one)
		return enemy_container.get_child(enemy_container.get_child_count() - 1)
	return null

func _get_player_card() -> Node:
	if player_container.get_child_count() > 0:
		return player_container.get_child(player_container.get_child_count() - 1)
	return null

# ---------- Weapons / Moves ----------
func _equip_weapon(ch: Dictionary, weapon_id: String) -> void:
	var display_id = weapon_id
	var combat_id = _get_weapon_id_from_item(weapon_id) # Map Item ID -> Weapon ID
	
	if not WeaponsBD.has_weapon(combat_id):
		combat_id = "FIST"
	
	ch.equipped_weapon_id = combat_id
	ch.moves = WeaponsBD.get_weapon_moves(combat_id)

	# Update UI Card
	var card = _get_player_card() if ch == player else _get_enemy_card()
	if card and card.has_method("set_weapon_ui"):
		card.set_weapon_ui(display_id)

func _split_player_moves() -> void:
	attack_moves.clear()
	defense_moves.clear()
	
	var p_card = _get_player_card()
	var all_moves = []
	
	if p_card and p_card.get("combat_slots"):
		# Collect from card's 8 slots
		for slot in p_card.combat_slots:
			if is_instance_valid(slot) and slot.filled:
				var id = slot.get_id()
				var weapon_id = _get_weapon_id_from_item(id)
				if WeaponsBD.has_weapon(weapon_id):
					all_moves += WeaponsBD.get_weapon_moves(weapon_id)
				elif id != "0":
					all_moves += WeaponsBD.get_weapon_moves(id)
	else:
		# Fallback to single equipped weapon
		all_moves = player.moves
		
	if all_moves.is_empty():
		all_moves = WeaponsBD.get_weapon_moves("FIST")
		
	for m in all_moves:
		var t := String(m.get("type","attack")).to_lower()
		if t == "attack":  attack_moves.append(m)
		elif t == "defense": defense_moves.append(m)
		
	# Limit to avoid UI overflow in central menu if needed
	if attack_moves.size()  > 6: attack_moves  = attack_moves.slice(0,6)
	if defense_moves.size() > 6: defense_moves = defense_moves.slice(0,6)

func _setup_ui() -> void:
	# Update Player Name dynamically
	var p_card = _get_player_card()
	if p_card:
		if "name_label" in p_card and p_card.name_label:
			p_card.name_label.text = "[center]%s[/center]" % player.name
		elif p_card.has_node("TextureRect/Nume"):
			p_card.get_node("TextureRect/Nume").text = "[center]%s[/center]" % player.name

	# Update Enemy Name dynamically
	var card = _get_enemy_card()
	if card:
		if card.has_method("setup"):
			if "name_label" in card and card.name_label:
				card.name_label.text = "[center]%s[/center]" % enemy.name
		elif card.has_node("TextureRect/Nume"):
			card.get_node("TextureRect/Nume").text = "[center]%s[/center]" % enemy.name

		# Apply Night Visuals
		if card.has_method("set_visuals"):
			var night_tex = enemy.get("texture")
			var night_bg = enemy.get("background")
			if night_tex or night_bg:
				card.set_visuals(night_tex, night_bg)

	_update_hp_ui()
	_show_main_menu()

func _update_hp_ui() -> void:
	# Dynamic Player UI
	var p_card = _get_player_card()
	if p_card:
		if p_card.has_method("update_hp"):
			p_card.update_hp(player.hp)
		else:
			var p_bar = p_card.get_node_or_null("TextureRect/TextureProgressBar")
			var p_txt = p_card.get_node_or_null("TextureRect/Health")
			if p_bar:
				p_bar.max_value = player.max_hp
				p_bar.value = player.hp
			if p_txt:
				p_txt.text = "%d/%d" % [player.hp, player.max_hp]

	# Dynamic Enemy UI
	var card = _get_enemy_card()
	if card:
		if card.has_method("update_hp"):
			card.update_hp(enemy.hp)
		else:
			var e_bar = card.get_node_or_null("TextureRect/TextureProgressBar")
			var e_txt = card.get_node_or_null("TextureRect/Health")
			if e_bar:
				e_bar.max_value = enemy.max_hp
				e_bar.value = enemy.hp
			if e_txt:
				e_txt.text = "%d/%d" % [enemy.hp, enemy.max_hp]


# ---------- Meniuri ----------
func _show_main_menu():
	var p_card = _get_player_card()
	# If we have a creator card, we might want to hide the central combat menu
	# but the user said "incat sa nu mai foloseasca abilitarile din combat"
	# specifically referring to the MOVE buttons. 
	# If the creator card handles EVERYTHING (Attack, Defense buttons too),
	# we hide the main_menu entirely.
	if p_card and p_card.has_node("TextureRect/Panel/Control/HBoxContainer/ContinutTab/Panel2/GridContainer"):
		main_menu.visible = false
	else:
		main_menu.visible = true
		
	moves_menu.visible = false
	btn_attack.disabled = false
	btn_defense.disabled = false
	btn_item.disabled = false
	btn_surrender.disabled = false

func _on_creator_action_selected(p_move: Dictionary):
	if state != State.PLAYER_TURN and state != State.PLAYER_SELECT: return
	
	# Select Enemy Move
	var card = _get_enemy_card()
	if card and card.inv_panel and card.inv_panel.selected_slot:
		var item_id = card.inv_panel.selected_slot.get_id()
		_equip_weapon(enemy, item_id)

	if enemy.moves.is_empty():
		_equip_weapon(enemy, "FIST")
		
	var e_idx = randi() % enemy.moves.size()
	var e_move: Dictionary = enemy.moves[e_idx]

	_show_no_menu()
	state = State.RESOLVE_PLAYER
	await _resolve_round(p_move, e_move)
	if _check_end(): return
	_player_turn()

func _format_move_name(m: Dictionary) -> String:
	var nm := String(m.get("name", "-"))
	var t  := _norm_type(m.get("type", "attack"))
	if t == "attack":
		nm += " (P%s)" % int(m.get("power", 0))      
	elif t == "defense":
		nm += " (B%s)" % int(m.get("block", m.get("power", 0)))  
	return nm

func _show_moves_menu(mode: String) -> void:
	_current_mode = mode
	_current_move_list = attack_moves if mode == "attack" else defense_moves
	for i in move_btns.size():
		if i < _current_move_list.size():
			move_btns[i].text = _format_move_name(_current_move_list[i])
			move_btns[i].disabled = false
		else:
			move_btns[i].text = "-"
			move_btns[i].disabled = true
		move_btns[i].visible = true
	main_menu.visible = false
	moves_menu.visible = true

func _show_no_menu() -> void:
	main_menu.visible = false
	moves_menu.visible = false

# ---------- Flow ----------
func _player_turn() -> void:
	state = State.PLAYER_TURN
	_show_main_menu()

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	_show_no_menu()
	await get_tree().create_timer(0.3).timeout
	
	# --- AI LOGIC: Survival (Eat) ---
	var hp_val = float(enemy.get("hp", 100))
	var max_hp_val = float(enemy.get("max_hp", 100))
	var current_hp_pct = hp_val / max_hp_val
	
	var heal_threshold = enemy.get("heal_threshold", 0.5)
	var heal_chance = enemy.get("heal_chance", 0.5)
	
	print("[Combat AI] Logic Check -> HP%: ", current_hp_pct, " (", hp_val, "/", max_hp_val, ") Thresh: ", heal_threshold, " Chance: ", heal_chance)
	
	if current_hp_pct < heal_threshold and randf() < heal_chance:
		if await _try_enemy_eat():
			if _check_end(): return
			_player_turn()
			return
	
	# --- AI LOGIC: Force Weapon Sync ---
	# Dacă viața e OK sau nu a mâncat, ne asigurăm că are o armă selectată pentru atac
	var card = _get_enemy_card()
	if card and card.inv_panel and card.inv_panel.selected_slot:
		var item_id = card.inv_panel.selected_slot.get_id()
		_equip_weapon(enemy, item_id)
	
	if enemy.moves.is_empty():
		_equip_weapon(enemy, "FIST")
	
	# Delay to show selection
	await get_tree().create_timer(0.5).timeout
	
	var idx = randi() % enemy.moves.size()
	await _do_attack(false, idx)
	if _check_end(): return
	_player_turn()

func _scan_enemy_inventory_for_weapons() -> Array:
	var list: Array = []
	var card = _get_enemy_card()
	if not card: return list
	
	var inv_node = card.get_node_or_null("TextureRect/Inv/MarginContainer/GridContainer")
	if not inv_node: return list
	
	for slot in inv_node.get_children():
		if slot.has_method("get_id") and slot.filled:
			var id = slot.get_id()
			var weapon_id = _get_weapon_id_from_item(id)
			if weapon_id != "FIST":
				list.append(id)
	return list

func _get_weapon_id_from_item(item_id: String) -> String:
	match item_id:
		"2": return "AXE01"
		"9": return "SWORD01"
		"10": return "PICKAXE"
		"13": return "SWORD01" 
		"14": return "SWORD01" 
		"22": return "AXE01"   
		"25": return "AXE01"   
	if WeaponsBD.has_weapon(item_id):
		return item_id
	return "FIST"

func _try_enemy_eat() -> bool:
	var card = _get_enemy_card()
	if not card: return false
	var inv_panel = card.inv_panel
	if not inv_panel: return false
	
	var grid = inv_panel.get_node_or_null("MarginContainer/GridContainer")
	if not grid: return false
	
	var food_slot = null
	var slot_idx = -1
	
	for i in range(grid.get_child_count()):
		var slot = grid.get_child(i)
		if slot.has_method("get_id") and slot.filled:
			var types = slot.get_type()
			if (types and "food" in types) or slot.get_id() in ["1", "3", "4", "5", "7", "8", "15", "24"]:
				food_slot = slot
				slot_idx = i
				break
	
	if not food_slot: 
		print("[Combat AI] No food found in inventory.")
		return false
	
	# 1. Selectăm vizual slotul
	if inv_panel.has_method("select_slot_by_index"):
		inv_panel.select_slot_by_index(slot_idx)
	
	await get_tree().create_timer(0.5).timeout
	
	# 2. Mâncăm folosind logica inventarului (care face și heal și clear)
	var old_hp = enemy.hp
	if inv_panel.has_method("eat"):
		inv_panel.eat()
	
	# 3. Sincronizăm HP-ul logic din combat cu ce a făcut inventarul
	# (Inventarul vindecă direct Jake.gd, deci citim de acolo)
	if "current_hp" in card:
		enemy.hp = card.current_hp
	
	var heal_diff = enemy.hp - old_hp
	if heal_diff > 0:
		_log_side(false, "%s mănâncă %s (+%d HP)!" % [enemy.name, food_slot.get_nume(), heal_diff])
		_update_hp_ui()
		return true
		
	return false

func _get_item_name(id: String) -> String:
	if ItemData.content.has(id):
		return ItemData.get_nume(id)
	return WeaponsBD.get_weapon_name(id)

func _check_end() -> bool:
	if enemy.hp <= 0:
		state = State.WIN
		enemy.hp = 0
		_update_hp_ui()
		_log_side(true, "%s a învins!" % player.name)
		return true
	if player.hp <= 0:
		state = State.LOSE
		player.hp = 0
		_update_hp_ui()
		_log_side(false, "%s a fost învins..." % player.name)
		return true
	return false

# ---------- Handlers Grid 1 ----------
func _on_btn_attack() -> void:
	if state != State.PLAYER_TURN: return
	state = State.PLAYER_SELECT
	_show_moves_menu("attack")

func _on_btn_defense() -> void:
	if state != State.PLAYER_TURN: return
	state = State.PLAYER_SELECT
	_show_moves_menu("defense")

func _on_btn_item() -> void:
	if state != State.PLAYER_TURN: return
	_log_side(true, "(Item) – neimplementat.")
	_enemy_turn()

func _on_btn_surrender() -> void:
	if state != State.PLAYER_TURN: return
	state = State.RUN_AWAY
	_show_no_menu()
	_log_side(true, "%s s-a predat." % player.name)

# ---------- Handlers Grid 2 ----------
func _on_btn_back() -> void:
	state = State.PLAYER_TURN
	_current_mode = ""
	_show_main_menu()

func _on_move_pressed(i: int) -> void:
	if state != State.PLAYER_SELECT: return
	if i >= _current_move_list.size(): return

	var p_move: Dictionary = _current_move_list[i]

	var card = _get_enemy_card()
	if card and card.inv_panel and card.inv_panel.selected_slot:
		var item_id = card.inv_panel.selected_slot.get_id()
		_equip_weapon(enemy, item_id)

	if enemy.moves.is_empty():
		_equip_weapon(enemy, "FIST")
		
	var e_idx = randi() % enemy.moves.size()
	var e_move: Dictionary = enemy.moves[e_idx]

	_show_no_menu()
	await _resolve_round(p_move, e_move)
	if _check_end(): return
	_player_turn()

func _resolve_round(p_move: Dictionary, e_move: Dictionary) -> void:
	var p_type := _norm_type(p_move.get("type","attack"))
	var e_type := _norm_type(e_move.get("type","attack"))
	var p_lane := _norm_lane(p_move.get("lane","mid"))
	var e_lane := _norm_lane(e_move.get("lane","mid"))

	var p_pow  := int(p_move.get("power", 0))
	var e_pow  := int(e_move.get("power", 0))
	var p_blk  := int(p_move.get("block", 0))
	var e_blk  := int(e_move.get("block", 0))

	_log_side(true,  "Tu: %s (%s) P=%d B=%d" % [p_move.get("name","-"), p_lane, p_pow, p_blk])
	_log_side(false, "Inamic: %s (%s) P=%d B=%d" % [e_move.get("name","-"), e_lane, e_pow, e_blk])

	var p_card = _get_player_card()
	if p_card and p_card.has_method("set_weapon_ui"):
		p_card.set_weapon_ui(player.get("equipped_weapon_id", "FIST"))
	var e_card = _get_enemy_card()
	if e_card and e_card.has_method("set_weapon_ui"):
		e_card.set_weapon_ui(enemy.get("equipped_weapon_id", "FIST"))

	await get_tree().create_timer(0.15).timeout

	if p_type == "attack" and e_type == "attack":
		if p_lane == e_lane:
			_log_side(true,  "Clash pe aceeași linie – 0 dmg.")
			_log_side(false, "Clash pe aceeași linie – 0 dmg.")
		else:
			var dmg_e := _calc_damage(player, enemy, p_pow)
			var dmg_p := _calc_damage(enemy, player, e_pow)
			enemy.hp = max(0, enemy.hp - dmg_e)
			player.hp = max(0, player.hp - dmg_p)
			_log_side(true,  "Îi dai %d dmg." % dmg_e)
			_log_side(false, "Îți dă %d dmg." % dmg_p)

	elif p_type == "attack" and e_type == "defense":
		var effective_block := e_blk
		if not BLOCK_ACROSS_LANES and p_lane != e_lane:
			effective_block = 0
		var eff_dmg := _dmg_after_block(player, enemy, p_pow, effective_block)
		if effective_block > 0:
			_log_side(false, "Blochează %d." % effective_block)
		if eff_dmg == 0:
			_log_side(true, "Bloc total.")
		else:
			enemy.hp = max(0, enemy.hp - eff_dmg)
			_log_side(true, "Treci de gardă: %d dmg." % eff_dmg)

	elif p_type == "defense" and e_type == "attack":
		var effective_block := p_blk
		if not BLOCK_ACROSS_LANES and e_lane != p_lane:
			effective_block = 0
		var eff_dmg := _dmg_after_block(enemy, player, e_pow, effective_block)
		if effective_block > 0:
			_log_side(true, "Blochezi %d." % effective_block)
		if eff_dmg == 0:
			_log_side(false, "Bloc total.")
		else:
			player.hp = max(0, player.hp - eff_dmg)
			_log_side(false, "Trece de gardă: %d dmg." % eff_dmg)

	else:
		_log_side(true,  "Amândoi în gardă – nimic.")
		_log_side(false, "Amândoi în gardă – nimic.")

	_update_hp_ui()
	await get_tree().create_timer(0.15).timeout

func _do_attack(is_player: bool, move_idx: int) -> void:
	var atk = player if is_player else enemy
	var def = enemy if is_player else player

	if atk.moves.is_empty():
		_log_side(is_player, "%s nu are mișcări." % atk.name)
		await get_tree().create_timer(0.3).timeout
		return

	move_idx = clamp(move_idx, 0, atk.moves.size()-1)
	var mover: Dictionary = atk.moves[move_idx]
	var name: String = String(mover.get("name","(gol)"))
	var mtype := String(mover.get("type","attack")).to_lower()
	var lane  := String(mover.get("lane","mid")).to_lower()

	_log_side(is_player, "%s folosește %s!" % [atk.name, name])
	
	var card = _get_player_card() if is_player else _get_enemy_card()
	if card and card.has_method("set_weapon_ui"):
		card.set_weapon_ui(atk.get("equipped_weapon_id", "FIST"))
		
	await get_tree().create_timer(0.35).timeout

	match mtype:
		"attack":
			var power: int = int(mover.get("power", 0))
			if power > 0:
				var dmg := _calc_damage(atk, def, power)
				def.hp = max(0, def.hp - dmg)
				_update_hp_ui()
				_log_side(is_player, "Eficacitate: %d dmg." % dmg)
			else:
				_log_side(is_player, "Lovitură slabă.")
		"defense":
			atk.guard_lane = lane
			_log_side(is_player, "%s intră în gardă (%s)." % [atk.name, lane])
		_:
			_log_side(is_player, "Mișcare necunoscută.")

	await get_tree().create_timer(0.3).timeout

func _calc_damage(_a: Dictionary, _d: Dictionary, power: int) -> int:
	return max(0, power)  

func _norm_type(x:String) -> String:
	return String(x).strip_edges().to_lower()

func _norm_lane(x:String) -> String:
	var s := String(x).strip_edges().to_lower()
	if s == "low": s = "down"
	if s in ["top","high"]: s = "up"
	if s in ["middle","centre","center","med"]: s = "mid"
	return s

func _dmg_after_block(attacker: Dictionary, defender: Dictionary, power:int, block_val:int) -> int:
	var eff := power - block_val
	if eff <= 0:
		return 0
	if BLOCK_MODE == "raw":
		return eff
	return _calc_damage(attacker, defender, eff)

func _log_side(is_player: bool, t: String) -> void:
	var rl := (log_player if is_player else log_enemy)
	if is_instance_valid(rl):
		rl.append_text(t + "\n")
		rl.scroll_to_line(rl.get_line_count())
