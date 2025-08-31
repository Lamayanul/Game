# BattleRoot.gd
extends Control

enum State { INTRO, PLAYER_TURN, PLAYER_SELECT, RESOLVE_PLAYER, ENEMY_TURN, RESOLVE_ENEMY, WIN, LOSE, RUN_AWAY }

# ---------- UI ----------
@onready var log_player: RichTextLabel = $CanvasLayer/PanelContainer/Fundal/Panel/Player_move
@onready var log_enemy:  RichTextLabel = $CanvasLayer/PanelContainer/Fundal/Panel/Enemy_move

@onready var p_name:   RichTextLabel      = $CanvasLayer/Player_ele/RichTextLabel
@onready var p_hp_bar: TextureProgressBar = $CanvasLayer/Player_ele/TextureProgressBar
@onready var p_hp_txt: Label              = $CanvasLayer/Player_ele/Label

@onready var e_name:   RichTextLabel      = $CanvasLayer/Enemy_ele/RichTextLabel
@onready var e_hp_bar: TextureProgressBar = $CanvasLayer/Enemy_ele/TextureProgressBar
@onready var e_hp_txt: Label              = $CanvasLayer/Enemy_ele/Label

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
	"name":"Player", "hp":100, "max_hp":100,
	"moves":[],
	"guard_lane":""
}
var enemy = {
	"name":"Enemy", "hp":100, "max_hp":100,
	"moves":[],
	"guard_lane":""
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

	# Conectare la inventar (pe path sau prin grup)
	if is_instance_valid(inv_ui) and inv_ui.has_signal("weapon_equip_request"):
		inv_ui.weapon_equip_request.connect(_on_weapon_from_inventory)
	for n in get_tree().get_nodes_in_group("inventory_ui"):
		if n.has_signal("weapon_equip_request") and not n.is_connected("weapon_equip_request", Callable(self, "_on_weapon_from_inventory")):
			n.weapon_equip_request.connect(_on_weapon_from_inventory)

	# Echipări inițiale: player = FIST (implicita), enemy = SWORD01
	_equip_weapon(player, "FIST")
	_equip_weapon(enemy,  "SWORD01")
	_split_player_moves()
	_setup_ui()
	_player_turn()

# ---------- Weapons / Moves ----------
func _equip_weapon(ch: Dictionary, weapon_id: String) -> void:
	if not WeaponsBD.has_weapon(weapon_id):
		weapon_id = "FIST"  # fallback implicit
	ch.equipped_weapon_id = weapon_id
	ch.moves = WeaponsBD.get_weapon_moves(weapon_id)

func _on_weapon_from_inventory(weapon_id: String) -> void:
	# echipează arma pentru PLAYER, reîmparte și reafișează meniul curent
	_equip_weapon(player, weapon_id)
	_split_player_moves()
	if moves_menu.visible and _current_mode != "":
		_show_moves_menu(_current_mode)
	#else:
		#_show_main_menu()
	#_log_side(true, "[i]Echipezi: %s[/i]" % WeaponsBD.get_weapon_name(weapon_id))

func _split_player_moves() -> void:
	attack_moves.clear()
	defense_moves.clear()
	for m in player.moves:
		var t := String(m.get("type","attack")).to_lower()
		if t == "attack":  attack_moves.append(m)
		elif t == "defense": defense_moves.append(m)
	if attack_moves.size()  > 3: attack_moves  = attack_moves.slice(0,3)
	if defense_moves.size() > 3: defense_moves = defense_moves.slice(0,3)

# ---------- Setup/UI ----------
func _setup_ui() -> void:
	p_name.text = "%s" % [player.name]
	e_name.text = "%s" % [enemy.name]
	_update_hp_ui()
	_show_main_menu()

func _update_hp_ui() -> void:
	p_hp_bar.max_value = player.max_hp
	p_hp_bar.value     = player.hp
	p_hp_txt.text      = "%d/%d" % [player.hp, player.max_hp]

	e_hp_bar.max_value = enemy.max_hp
	e_hp_bar.value     = enemy.hp
	e_hp_txt.text      = "%d/%d" % [enemy.hp, enemy.max_hp]

# ---------- Meniuri ----------
func _show_main_menu():
	main_menu.visible = true
	moves_menu.visible = false
	btn_attack.disabled = false
	btn_defense.disabled = false
	btn_item.disabled = false
	btn_surrender.disabled = false

# helper mic – face textul pentru buton în funcție de tipul mișcării
func _format_move_name(m: Dictionary) -> String:
	var nm := String(m.get("name", "-"))
	var t  := _norm_type(m.get("type", "attack"))
	if t == "attack":
		nm += " (P%s)" % int(m.get("power", 0))      # puterea atacului
	elif t == "defense":
		# dacă, din greșeală, nu există "block", folosește "power" ca fallback
		nm += " (B%s)" % int(m.get("block", m.get("power", 0)))  # valoarea blocului
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
	if enemy.moves.is_empty():
		_log_side(false, "%s nu are mișcări." % enemy.name)
		_player_turn()
		return
	var idx = randi() % enemy.moves.size()
	await _do_attack(false, idx)
	if _check_end(): return
	_player_turn()

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

	# AI alege random
	if enemy.moves.is_empty():
		_log_side(false, "%s nu are mișcări." % enemy.name)
		_player_turn()
		return
	var e_idx = randi() % enemy.moves.size()
	var e_move: Dictionary = enemy.moves[e_idx]

	_show_no_menu()
	await _resolve_round(p_move, e_move)
	if _check_end(): return
	_player_turn()

# ---------- Rezolvare simultană a rundei ----------
# helper: cât blochează o mișcare de apărare
func _block_value(def_move: Dictionary) -> int:
	return int(def_move.get("block", def_move.get("power", 0))) 

func _resolve_round(p_move: Dictionary, e_move: Dictionary) -> void:
	# normalizează
	var p_type := _norm_type(p_move.get("type","attack"))
	var e_type := _norm_type(e_move.get("type","attack"))
	var p_lane := _norm_lane(p_move.get("lane","mid"))
	var e_lane := _norm_lane(e_move.get("lane","mid"))

	var p_pow  := int(p_move.get("power", 0))
	var e_pow  := int(e_move.get("power", 0))
	var p_blk  := int(p_move.get("block", 0))
	var e_blk  := int(e_move.get("block", 0))

	# log mișcări
	_log_side(true,  "Tu: %s (%s) P=%d B=%d" % [p_move.get("name","-"), p_lane, p_pow, p_blk])
	_log_side(false, "Inamic: %s (%s) P=%d B=%d" % [e_move.get("name","-"), e_lane, e_pow, e_blk])
	await get_tree().create_timer(0.15).timeout

	if DEBUG_COMBAT:
		print("[DBG] P: type=",p_type," lane=",p_lane," pow=",p_pow," blk=",p_blk)
		print("[DBG] E: type=",e_type," lane=",e_lane," pow=",e_pow," blk=",e_blk)

	# --- reguli ---
	# 1) Attack vs Attack
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

	# 2) Attack (P) vs Defense (E)
	elif p_type == "attack" and e_type == "defense":
		var effective_block := e_blk
		# dacă vrei block doar pe aceeași linie, schimbă pe false sus și păstrează testul:
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

	# 3) Defense (P) vs Attack (E)
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

	# 4) Defense vs Defense
	else:
		_log_side(true,  "Amândoi în gardă – nimic.")
		_log_side(false, "Amândoi în gardă – nimic.")

	_update_hp_ui()
	await get_tree().create_timer(0.15).timeout





# ---------- Atac simplu (folosit de AI în turul lui) ----------
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

 # fallback dacă nu ai "block"

func _damage_with_block(attacker: Dictionary, defender: Dictionary, raw_power: int, block_val: int) -> int:
	var eff := raw_power - block_val
	if eff <= 0:
		return 0
	return _calc_damage(attacker, defender, eff)

func _damage_after_block(attacker: Dictionary, defender: Dictionary, raw_power: int, block_val: int) -> int:
	var eff := raw_power - block_val
	if eff <= 0:
		return 0
	if BLOCK_MODE == "raw":
		return eff
	else:
		return _calc_damage(attacker, defender, eff)

# ---------- Utilitare ----------
#func _calc_damage(a: Dictionary, d: Dictionary, power: int) -> int:
	#if power <= 0:
		#return 0
	#var base = ((2.0 * (a.level as float) / 5.0 + 2.0) * power * (a.atk as float) / max(1.0, (d.def as float))) / 5.0
	#var variance := randf_range(0.85, 1.0)
	#return max(0, int(round(base * variance)))
func _calc_damage(_a: Dictionary, _d: Dictionary, power: int) -> int:
	return max(0, power)  # fără stats/variability


# --- helpers de normalizare ---

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

func _format_move_name_for(attacker: Dictionary, defender: Dictionary, m: Dictionary) -> String:
	var nm := String(m.get("name","-"))
	var t  := String(m.get("type","attack")).to_lower()
	if t == "attack":
		var p := int(m.get("power",0))
		var d := _calc_damage(attacker, defender, p)
		nm += " (P=%d ⇒ D≈%d)" % [p, d]
	else:
		var b := int(m.get("block", m.get("power",0)))
		nm += " (B=%d)" % b
	return nm
