extends TextureRect
class_name CombatManager

@export var inv_player: NodePath
@export var inv_enemy: NodePath
@export var fight_button: NodePath
@export var result_slot_path: NodePath
@export var player_node_path: NodePath = ^"/root/world/player"
@export var main_game_path: NodePath = ^"../MainGame"

@onready var content = get_node_or_null("/root/world/CanvasLayer/Control/Royal_battle/Control/TextureRect2/Inv_enemy/MarginContainer/GridContainer")

var RECIPES := {
	"apple_pie": {
		"player": {"3": 1},
		"enemy":  {"7": 1},
		"result": {
			"TEXTURE": preload("res://assets/pie.png"),
			"CANTITATE": 1,
			"NUMBER": 15,
			"NUME": "apple pie",
			"RARITATE": "comuna"
		}
	}
}

@onready var _inv_p: Node = get_node_or_null(inv_player)
@onready var _inv_e: Node = get_node_or_null(inv_enemy)
@onready var _btn: Button = get_node_or_null(fight_button)
@onready var _result_slot: Slot = get_node_or_null(result_slot_path)
@onready var _player_node: Node = get_node_or_null(player_node_path)
@onready var _main_game: Node = get_node_or_null(main_game_path)

enum State { SELECT_ITEMS, SELECT_SLOTS, FIGHT }
var current_state := State.SELECT_ITEMS

var selected_player_item: Slot = null
var selected_enemy_item: Slot = null
var is_player_turn := true

# Liste de sloturi marcate
var player_marked_slots: Array[Slot] = []
var enemy_marked_slots: Array[Slot] = []

func _ready() -> void:
	await get_tree().process_frame
	_inv_p = get_node_or_null(inv_player)
	_inv_e = get_node_or_null(inv_enemy)
	_btn = get_node_or_null(fight_button)
	_result_slot = get_node_or_null(result_slot_path)
	_player_node = get_node_or_null(player_node_path)
	_main_game = get_node_or_null(main_game_path)

	if _btn and not _btn.is_connected("pressed", Callable(self, "_on_fight_pressed")):
		_btn.pressed.connect(Callable(self, "_on_fight_pressed"))

	_connect_inventory_clicks(_inv_p)
	_connect_maingame_clicks()

	_show_toast("Alege un item din inventarul tău.")

func _connect_inventory_clicks(inv_root: Node) -> void:
	if inv_root == null: return
	var grid = inv_root.get_node_or_null("MarginContainer/GridContainer")
	if grid == null: return


func _connect_maingame_clicks() -> void:
	if _main_game == null: return
	await get_tree().process_frame
	for slot in _main_game.all_slots:
		if slot is Slot:
			if not slot.gui_input.is_connected(Callable(self, "_on_maingame_slot_gui_input")):
				slot.gui_input.connect(Callable(self, "_on_maingame_slot_gui_input").bind(slot))



func _on_maingame_slot_gui_input(event: InputEvent, slot: Slot) -> void:
	if current_state != State.SELECT_SLOTS: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_player_mark(slot)



# --------------------------------------
# PASUL 2: SELECTARE SLOTURI (Toggle logic)
# --------------------------------------
func _toggle_player_mark(slot: Slot) -> void:
	# Verificăm dacă e deja marcat de inamic
	if enemy_marked_slots.has(slot):
		_show_toast("Slotul e deja marcat de enemy!")
		return

	if player_marked_slots.has(slot):
		# DEZMARCARE
		player_marked_slots.erase(slot)
		_main_game.mark_slot(slot, "") 
	else:
		# MARCARE
		player_marked_slots.append(slot)
		_main_game.mark_slot(slot, "player")



# --------------------------------------
# PASUL 3: FIGHT
# --------------------------------------
func _on_fight_pressed() -> void:
	if current_state != State.SELECT_SLOTS:
		_show_toast("Alege iteme mai întâi!")
		return

	if player_marked_slots.is_empty():
		_show_toast("Marchează măcar un slot!")
		return

	# 1. Colectăm itemele de pe TOATE sloturile marcate
	_collect_all_board_items()

	# 2. Rețetă
	var id_p = str(selected_player_item.get_number())
	var id_e = str(selected_enemy_item.get_number())
	
	var data_p = selected_player_item.get_full_item()
	var data_e = selected_enemy_item.get_full_item()
	data_p["CANTITATE"] = 1
	data_e["CANTITATE"] = 1

	selected_player_item.decrease_cantitate(1)
	selected_enemy_item.decrease_cantitate(1)

	var recipe_found = null
	for key in RECIPES.keys():
		var rec = RECIPES[key]
		if (rec["player"].has(id_p) and rec["enemy"].has(id_e)) or (rec["player"].has(id_e) and rec["enemy"].has(id_p)):
			recipe_found = rec
			break

	if recipe_found:
		var target_slot = _main_game.get_random_slot()
		var res_data = recipe_found["result"].duplicate(true)
		
		# Food unbreakable
		var item_real_id = _get_id_from_number(res_data.get("NUMBER", 0))
		if "food" in ItemData.get_type(item_real_id):
			var effects = res_data.get("EFFECTS", [])
			effects.append({"id": "unbreakable"})
			res_data["EFFECTS"] = effects
		
		target_slot.set_property(res_data)
		target_slot.filled = true
		
		_show_toast("Rețetă găsită! Rezultatul a picat pe tablă.")
		await get_tree().create_timer(1.5).timeout
		
		var owner = _main_game.get_slot_owner(target_slot)
		if owner == "player":
			_add_to_inv(_inv_p, res_data)
			_show_toast("Ai câștigat itemul!")
			target_slot.clear_item()
		elif owner == "enemy":
			_add_to_inv(_inv_e, res_data)
			_show_toast("Enemy a câștigat itemul!")
			target_slot.clear_item()
	else:
		_show_toast("Fără rețetă! Itemele tale apar pe tablă.")
		if not player_marked_slots.is_empty():
			var s = player_marked_slots[randi() % player_marked_slots.size()]
			s.set_property(data_p); s.filled = true
		if not enemy_marked_slots.is_empty():
			var s = enemy_marked_slots[randi() % enemy_marked_slots.size()]
			s.set_property(data_e); s.filled = true

	_reset_game()

func _collect_all_board_items():
	for s in player_marked_slots:
		if is_instance_valid(s) and s.filled:
			_add_to_inv(_inv_p, s.get_full_item())
			s.clear_item()
	for s in enemy_marked_slots:
		if is_instance_valid(s) and s.filled:
			_add_to_inv(_inv_e, s.get_full_item())
			s.clear_item()

func _reset_game() -> void:
	selected_player_item = null
	selected_enemy_item = null
	player_marked_slots.clear()
	enemy_marked_slots.clear()
	current_state = State.SELECT_ITEMS
	is_player_turn = true
	if _main_game: _main_game.clear_marks()
	_show_toast("Rundă nouă. Alege un item.")

func _add_to_inv(inv_node: Node, data: Dictionary) -> void:
	var grid = inv_node.get_node_or_null("MarginContainer/GridContainer")
	if grid:
		for c in grid.get_children():
			if c is Slot and not c.filled:
				c.set_property(data)
				c.filled = true
				return
	if inv_node.has_method("add_item"):
		inv_node.add_item(str(data.get("NUMBER", 0)), data.get("CANTITATE", 1))

func _show_toast(msg: String) -> void:
	if _player_node and _player_node.has_method("show_toast"):
		_player_node.show_toast(msg)
	else:
		print(msg)

func _get_id_from_number(target_number: int) -> String:
	for key in ItemData.content.keys():
		if int(ItemData.content[key].get("number", -1)) == target_number:
			return key
	return "0"
