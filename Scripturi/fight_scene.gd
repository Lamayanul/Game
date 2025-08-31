# BattleRoot.gd
extends Control

enum State { INTRO, PLAYER_TURN, PLAYER_SELECT, RESOLVE_PLAYER, ENEMY_TURN, RESOLVE_ENEMY, WIN, LOSE, RUN_AWAY }

@onready var log: RichTextLabel = $CanvasLayer/PanelContainer/Fundal/Panel/Log

@onready var p_name: RichTextLabel = $CanvasLayer/Player_ele/RichTextLabel
@onready var p_hp_bar: TextureProgressBar = $CanvasLayer/Player_ele/TextureProgressBar
@onready var p_hp_txt: Label = $CanvasLayer/Player_ele/Label

@onready var e_name: RichTextLabel = $CanvasLayer/Enemy_ele/RichTextLabel
@onready var e_hp_bar: TextureProgressBar = $CanvasLayer/Enemy_ele/TextureProgressBar
@onready var e_hp_txt: Label = $CanvasLayer/Enemy_ele/Label

@onready var main_menu: GridContainer = $CanvasLayer/GridContainer
@onready var btn_fight: Button = $CanvasLayer/GridContainer/Button
@onready var btn_bag:   Button = $CanvasLayer/GridContainer/Button2
@onready var btn_party: Button = $CanvasLayer/GridContainer/Button3
@onready var btn_run:   Button = $CanvasLayer/GridContainer/Button4

@onready var fight_menu: GridContainer = $CanvasLayer/GridContainer2
@onready var move_btns: Array[Button] = [
	$CanvasLayer/GridContainer2/Button,
	$CanvasLayer/GridContainer2/Button2,
	$CanvasLayer/GridContainer2/Button3,
	$CanvasLayer/GridContainer2/Button4
]
@onready var btn_back: Button = $CanvasLayer/GridContainer2/back

var state: State = State.INTRO
var selected_move_idx: int = -1

# „Creaturi” demo (poți muta în resurse/Data mai târziu)
var player = {
	"name":"Nume_player","level":5,"hp":100,"max_hp":100,
	"atk":10,"def":9,"spd":8,
	"moves":[
		{"name":"Tackle","power":40,"pp":35},
		{"name":"Ember","power":40,"pp":25,"type":"fire"},
		{"name":"Growl","power":0,"status":"atk_down"},
		{"name":"Leer","power":0,"status":"def_down"}
	]
}
var enemy = {
	"name":"Le Bossache","level":5,"hp":100,"max_hp":100,
	"atk":9,"def":10,"spd":7,
	"moves":[
		{"name":"Scratch","power":40,"pp":35},
		{"name":"Vine Whip","power":45,"pp":25,"type":"grass"},
		{"name":"Harden","power":0,"status":"def_up"},
		{"name":"Tail Whip","power":0,"status":"def_down"}
	]
}

func _ready():
	# Hook butoane meniu principal
	btn_fight.pressed.connect(_on_btn_fight)
	btn_bag.pressed.connect(_on_btn_bag)
	btn_party.pressed.connect(_on_btn_party)
	btn_run.pressed.connect(_on_btn_run)

	# Hook butoane mișcări + back
	for i in move_btns.size():
		move_btns[i].pressed.connect(func(): _on_move_pressed(i))
	btn_back.pressed.connect(_show_main_menu)

	_setup_ui()
	await _intro()
	_player_turn()

func _setup_ui():
	p_name.text = "%s Lv.%d" % [player.name, player.level]
	e_name.text = "%s Lv.%d" % [enemy.name, enemy.level]
	_update_hp_ui()
	# Populează numele mișcărilor
	for i in move_btns.size():
		var m = player.moves[i] if i < player.moves.size() else {"name":"-","power":0}
		move_btns[i].text = str(m.name)

	_show_main_menu()

func _update_hp_ui():
	p_hp_bar.max_value = player.max_hp
	p_hp_bar.value = player.hp
	p_hp_txt.text = "%d/%d" % [player.hp, player.max_hp]

	e_hp_bar.max_value = enemy.max_hp
	e_hp_bar.value = enemy.hp
	e_hp_txt.text = "%d/%d" % [enemy.hp, enemy.max_hp]

func _log(t: String) -> void:
	log.append_text(t + "\n")
	log.scroll_to_line(log.get_line_count())

# ---------- STATE FLOW ----------
func _intro() -> void:
	_log("[center]%s apare![/center]" % enemy.name)
	await get_tree().create_timer(0.6).timeout

func _player_turn():
	state = State.PLAYER_TURN
	_show_main_menu()
	_log("Ce va face %s?" % player.name)

func _enemy_turn():
	state = State.ENEMY_TURN
	_show_no_menu()
	await get_tree().create_timer(0.3).timeout
	var idx = randi() % enemy.moves.size()
	await _do_attack(false, idx)
	if _check_end(): return
	_player_turn()

func _check_end() -> bool:
	if enemy.hp <= 0:
		state = State.WIN
		enemy.hp = 0
		_update_hp_ui()
		_log("%s a învins!" % player.name)
		return true
	if player.hp <= 0:
		state = State.LOSE
		player.hp = 0
		_update_hp_ui()
		_log("%s a fost învins..." % player.name)
		return true
	return false

# ---------- MENIURI ----------
func _show_main_menu():
	main_menu.visible = true
	fight_menu.visible = false

func _show_fight_menu():
	main_menu.visible = false
	fight_menu.visible = true

func _show_no_menu():
	main_menu.visible = false
	fight_menu.visible = false

# ---------- HANDLERS ----------
func _on_btn_fight():
	if state != State.PLAYER_TURN: return
	state = State.PLAYER_SELECT
	_show_fight_menu()

func _on_move_pressed(i: int):
	if state != State.PLAYER_SELECT: return
	selected_move_idx = i
	await _do_attack(true, selected_move_idx)
	if _check_end(): return
	_enemy_turn()

func _on_btn_bag():
	if state != State.PLAYER_TURN: return
	_log("(Bag) – neimplementat.")
	# exemplu: poți vindeca 10 HP ca demo
	# player.hp = clamp(player.hp + 10, 0, player.max_hp)
	# _update_hp_ui()
	_enemy_turn()

func _on_btn_party():
	if state != State.PLAYER_TURN: return
	_log("(Party) – neimplementat.")
	_enemy_turn()

func _on_btn_run():
	if state != State.PLAYER_TURN: return
	var ok := randf() < 0.6
	if ok:
		state = State.RUN_AWAY
		_log("Ai reușit să fugi!")
		_show_no_menu()
	else:
		_log("Nu ai reușit să fugi!")
		_enemy_turn()

# ---------- COMBAT CORE ----------
func _do_attack(is_player: bool, move_idx: int) -> void:
	_show_no_menu()
	var atk = player if is_player else enemy
	var def = enemy if  is_player else player
	var mover = atk.moves[move_idx]
	var name: String = mover.name

	_log("%s folosește %s!" % [atk.name, name])
	await get_tree().create_timer(0.4).timeout

	var dmg := 0
	if mover.get("power", 0) > 0:
		dmg = _calc_damage(atk, def, mover.power)
		def.hp = max(0, def.hp - dmg)
		_update_hp_ui()
		_log("Eficacitate: %d dmg." % dmg)
	else:
		# status simplificat
		var st := str(mover.get("status",""))
		match st:
			"atk_down":
				def.atk = max(1, def.atk - 1)
				_log("%s scade ATK-ul lui %s!" % [atk.name, def.name])
			"def_down":
				def.def = max(1, def.def - 1)
				_log("%s scade DEF-ul lui %s!" % [atk.name, def.name])
			"def_up":
				atk.def += 1
				_log("%s își crește DEF-ul!" % atk.name)
			_:
				_log("Dar nu se întâmplă nimic...")
	await get_tree().create_timer(0.35).timeout

func _calc_damage(a, d, power: int) -> int:
	# formulă simplificată, cu mică variație
	var base = ((2.0 * a.level / 5.0 + 2.0) * power * (a.atk as float) / max(1.0, d.def)) / 5.0
	var variance := randf_range(0.85, 1.0)
	return max(1, int(round(base * variance)))
