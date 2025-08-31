## BattleRoot.gd
extends Control
#
#enum State { INTRO, PLAYER_TURN, PLAYER_SELECT, RESOLVE_PLAYER, ENEMY_TURN, RESOLVE_ENEMY, WIN, LOSE, RUN_AWAY }
#
## ---------- UI ----------
#@onready var log: RichTextLabel = $CanvasLayer/PanelContainer/Fundal/Panel/Log
#
#@onready var p_name: RichTextLabel = $CanvasLayer/Player_ele/RichTextLabel
#@onready var p_hp_bar: TextureProgressBar = $CanvasLayer/Player_ele/TextureProgressBar
#@onready var p_hp_txt: Label = $CanvasLayer/Player_ele/Label
#
#@onready var e_name: RichTextLabel = $CanvasLayer/Enemy_ele/RichTextLabel
#@onready var e_hp_bar: TextureProgressBar = $CanvasLayer/Enemy_ele/TextureProgressBar
#@onready var e_hp_txt: Label = $CanvasLayer/Enemy_ele/Label
#
## Grid 1 (Main)
#@onready var main_menu: GridContainer = $CanvasLayer/GridContainer
#@onready var btn_attack:   Button = $CanvasLayer/GridContainer/Attack
#@onready var btn_defense:  Button = $CanvasLayer/GridContainer/Defense
#@onready var btn_item:     Button = $CanvasLayer/GridContainer/Item
#@onready var btn_surrender:Button = $CanvasLayer/GridContainer/Surrender
#
## Grid 2 (Moves)
#@onready var moves_menu: GridContainer = $CanvasLayer/GridContainer2
#@onready var move_btns: Array[Button] = [
	#$CanvasLayer/GridContainer2/Move1,
	#$CanvasLayer/GridContainer2/Move2,
	#$CanvasLayer/GridContainer2/Move3
#]
#@onready var btn_back: Button = $CanvasLayer/GridContainer2/Back
#@onready var inv_ui := get_node_or_null("/root/world/CanvasLayer/Inv")
#
## ---------- State ----------
#var state: State = State.INTRO
#var selected_move_idx: int = -1
#
## ---------- Data demo (se populează din WeaponsDB) ----------
#var player = {
	#"name":"Jucător", "level":5, "hp":100, "max_hp":100, "atk":10, "def":9, "spd":8,
	#"inventory":[ {"id":"AXE01","qty":1}, {"id":"SWORD01","qty":1} ],
	#"equipped_weapon_id":"AXE01",
	#"moves":[]
#}
#
#var enemy = {
	#"name":"Inamic", "level":5, "hp":100, "max_hp":100, "atk":9, "def":10, "spd":7,
	#"inventory":[ {"id":"SWORD01","qty":1} ],
	#"equipped_weapon_id":"SWORD01",
	#"moves":[]
#}
#
## Liste fixe pentru meniul 2
#var attack_moves: Array = []   # primele 3 atacuri ale playerului (din arma echipată)
#var defense_moves: Array = []  # primele 3 apărări ale playerului
#var _current_move_list: Array = []
#var _current_mode: String = "" # "attack" | "defense"
#
#func _ready() -> void:
	#if is_instance_valid(inv_ui):
		#inv_ui.weapon_equip_request.connect(_on_weapon_from_inventory)
	## Conectează butoanele din Grid 1
	#btn_attack.pressed.connect(_on_btn_attack)
	#btn_defense.pressed.connect(_on_btn_defense)
	#btn_item.pressed.connect(_on_btn_item)
	#btn_surrender.pressed.connect(_on_btn_surrender)
#
	## Conectează butoanele din Grid 2
	#for i in move_btns.size():
		#var idx := i
		#move_btns[i].pressed.connect(func(): _on_move_pressed(idx))
	#btn_back.pressed.connect(_show_main_menu)
#
	## Echipare din WeaponsDB
	#_equip_from_inventory_or_fallback(player, "AXE01")
	#_equip_from_inventory_or_fallback(enemy,  "SWORD01")
#
	#_split_player_moves()
#
	#_setup_ui()
	#await _intro()
	#_player_turn()
#
#
#func _on_weapon_from_inventory(weapon_id: String) -> void:
	## echipează arma pentru PLAYER
	#_equip_weapon(player, weapon_id)   # ai deja funcția
	#_split_player_moves()              # reîmparte attack/defense (ai deja funcția)
#
	## dacă ești pe gridul cu mișcări, reafișează-l cu noul set;
	## altfel doar arată meniul principal
	#if moves_menu.visible and _current_mode != "":
		#_show_moves_menu(_current_mode)
	#else:
		#_show_main_menu()
#
#
## ---------- Setup/UI ----------
#func _setup_ui() -> void:
	#p_name.text = "%s Lv.%d" % [player.name, player.level]
	#e_name.text = "%s Lv.%d" % [enemy.name, enemy.level]
	#_update_hp_ui()
	#_show_main_menu()
#
#func _update_hp_ui() -> void:
	#p_hp_bar.max_value = player.max_hp
	#p_hp_bar.value = player.hp
	#p_hp_txt.text = "%d/%d" % [player.hp, player.max_hp]
#
	#e_hp_bar.max_value = enemy.max_hp
	#e_hp_bar.value = enemy.hp
	#e_hp_txt.text = "%d/%d" % [enemy.hp, enemy.max_hp]
#
#func _log(t: String) -> void:
	#log.append_text(t + "\n")
	#log.scroll_to_line(log.get_line_count())
#
## ---------- Weapons / Moves ----------
#func _equip_weapon(ch: Dictionary, weapon_id: String) -> void:
	#if not WeaponsBD.has_weapon(weapon_id):
		#push_warning("Arma %s nu există în DB; fără mișcări." % weapon_id)
		#ch.equipped_weapon_id = ""
		#ch.moves = []
		#return
	#ch.equipped_weapon_id = weapon_id
	#ch.moves = WeaponsBD.get_weapon_moves(weapon_id)
#
#func _equip_from_inventory_or_fallback(ch: Dictionary, fallback_id: String = "") -> void:
	#for e in ch.get("inventory", []):
		#var wid: String = e.get("id","")
		#if e.get("qty",0) > 0 and WeaponsBD.has_weapon(wid):
			#_equip_weapon(ch, wid)
			#return
	#if fallback_id != "":
		#_equip_weapon(ch, fallback_id)
	#else:
		#_equip_weapon(ch, "")
#
#func _split_player_moves() -> void:
	#attack_moves.clear()
	#defense_moves.clear()
	#for m in player.moves:
		#var t := String(m.get("type","attack")).to_lower()
		#if t == "attack":
			#attack_moves.append(m)
		#elif t == "defense":
			#defense_moves.append(m)
	#if attack_moves.size() > 3: attack_moves = attack_moves.slice(0,3)
	#if defense_moves.size() > 3: defense_moves = defense_moves.slice(0,3)
#
## ---------- Flow ----------
#func _intro() -> void:
	#_log("[center]%s apare![/center]" % enemy.name)
	#await get_tree().create_timer(0.6).timeout
#
#func _player_turn() -> void:
	#state = State.PLAYER_TURN
	#_show_main_menu()
	#_log("Ce va face %s?" % player.name)
#
#func _enemy_turn() -> void:
	#state = State.ENEMY_TURN
	#_show_no_menu()
	#await get_tree().create_timer(0.3).timeout
	#if enemy.moves.is_empty():
		#_log("%s nu are mișcări." % enemy.name)
		#_player_turn()
		#return
	#var idx = randi() % enemy.moves.size()
	#await _do_attack(false, idx)
	#if _check_end(): return
	#_player_turn()
#
#func _check_end() -> bool:
	#if enemy.hp <= 0:
		#state = State.WIN
		#enemy.hp = 0
		#_update_hp_ui()
		#_log("%s a învins!" % player.name)
		#return true
	#if player.hp <= 0:
		#state = State.LOSE
		#player.hp = 0
		#_update_hp_ui()
		#_log("%s a fost învins..." % player.name)
		#return true
	#return false
#
## ---------- Meniuri ----------
#func _show_main_menu() -> void:
	#main_menu.visible = true
	#moves_menu.visible = false
#
#func _show_moves_menu(mode: String) -> void:
	#_current_mode = mode
	#_current_move_list = attack_moves if mode == "attack" else defense_moves
	#for i in move_btns.size():
		#if i < _current_move_list.size():
			#move_btns[i].text = String(_current_move_list[i].get("name","-"))
			#move_btns[i].disabled = false
			#move_btns[i].visible = true
		#else:
			#move_btns[i].text = "-"
			#move_btns[i].disabled = true
			#move_btns[i].visible = true
	#main_menu.visible = false
	#moves_menu.visible = true
#
#func _show_no_menu() -> void:
	#main_menu.visible = false
	#moves_menu.visible = false
#
## ---------- Handlers Grid 1 ----------
#func _on_btn_attack() -> void:
	#if state != State.PLAYER_TURN: return
	#state = State.PLAYER_SELECT
	#_show_moves_menu("attack")
#
#func _on_btn_defense() -> void:
	#if state != State.PLAYER_TURN: return
	#state = State.PLAYER_SELECT
	#_show_moves_menu("defense")
#
#func _on_btn_item() -> void:
	#if state != State.PLAYER_TURN: return
	#_log("(Item) – neimplementat.")
	#_enemy_turn()
#
#func _on_btn_surrender() -> void:
	#if state != State.PLAYER_TURN: return
	#state = State.RUN_AWAY
	#_show_no_menu()
	#_log("%s s-a predat." % player.name)
#
## ---------- Handlers Grid 2 ----------
#func _on_move_pressed(i: int) -> void:
	#if state != State.PLAYER_SELECT: return
	#if i >= _current_move_list.size(): return
#
	#var chosen: Dictionary = _current_move_list[i]
	#var idx_in_player = player.moves.find(chosen)
	#if idx_in_player == -1:
		#idx_in_player = 0  # fallback
#
	#_show_no_menu()
	#await _do_attack(true, idx_in_player)
	#if _check_end(): return
	#_enemy_turn()
#
## ---------- Combat ----------
#func _do_attack(is_player: bool, move_idx: int) -> void:
	#var atk = player if is_player else enemy
	#var def = enemy if is_player else player
#
	#if atk.moves.is_empty():
		#_log("%s nu are mișcări." % atk.name)
		#await get_tree().create_timer(0.3).timeout
		#return
#
	#move_idx = clamp(move_idx, 0, atk.moves.size()-1)
	#var mover: Dictionary = atk.moves[move_idx]
	#var name: String = String(mover.get("name","(gol)"))
	#var mtype := String(mover.get("type","attack")).to_lower()
#
	#_log("%s folosește %s!" % [atk.name, name])
	#await get_tree().create_timer(0.35).timeout
#
	#match mtype:
		#"attack":
			#var power: int = int(mover.get("power", 0))
			#if power > 0:
				#var dmg := _calc_damage(atk, def, power)
				#def.hp = max(0, def.hp - dmg)
				#_update_hp_ui()
				#_log("Eficacitate: %d dmg." % dmg)
			#else:
				#_log("Lovitură slabă.")
		#"defense":
			#_log("%s intră în gardă (%s)." % [atk.name, String(mover.get("lane","-"))])
		#_:
			#_log("Mișcare necunoscută.")
	#await get_tree().create_timer(0.3).timeout
#
#func _calc_damage(a: Dictionary, d: Dictionary, power: int) -> int:
	#var base = ((2.0 * (a.level as float) / 5.0 + 2.0) * power * (a.atk as float) / max(1.0, (d.def as float))) / 5.0
	#var variance := randf_range(0.85, 1.0)
	#return max(1, int(round(base * variance)))
