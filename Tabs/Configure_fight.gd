extends TextureRect
class_name CombatManager

@export var inv_player: NodePath
@export var inv_enemy: NodePath
@export var fight_button: NodePath
@export var result_slot_path: NodePath
@export var player_node_path: NodePath = ^"/root/world/player"
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

# --------------------------------------
# VARIABILE DE STARE
# --------------------------------------
var selected_player_item: Slot = null
var selected_enemy_item: Slot = null
var is_player_turn := true

func _ready() -> void:
	await get_tree().process_frame
	_inv_p = get_node_or_null(inv_player)
	_inv_e = get_node_or_null(inv_enemy)
	_btn = get_node_or_null(fight_button)
	_result_slot = get_node_or_null(result_slot_path)
	_player_node = get_node_or_null(player_node_path)

	if _btn and not _btn.is_connected("pressed", Callable(self, "_on_fight_pressed")):
		_btn.pressed.connect(Callable(self, "_on_fight_pressed"))

	# 🔹 Conectează click-urile din inventarul playerului
	_connect_inventory_clicks(_inv_p)

	_show_toast("Alege un item din inventarul tău pentru luptă.")

func _connect_inventory_clicks(inv_root: Node) -> void:
	if inv_root == null:
		push_warning("Inventarul playerului nu există!")
		return

	var grid := inv_root.get_node_or_null("MarginContainer/GridContainer")
	if grid == null:
		push_warning("Inventarul playerului nu are GridContainer!")
		return

	for c in grid.get_children():
		if c is Slot:
			c.gui_input.connect(Callable(self, "_on_slot_gui_input").bind(c))
		else:
			# Dacă Slot e în interiorul unui container
			for child in c.get_children():
				if child is Slot:
					child.gui_input.connect(Callable(self, "_on_slot_gui_input").bind(child))

func _on_slot_gui_input(event: InputEvent, slot: Slot) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		select_player_item(slot)


# --------------------------------------
# PLAYER SELECTEAZĂ MANUAL
# --------------------------------------
func select_player_item(slot: Slot) -> void:
	if not is_player_turn:
		_show_toast("Așteaptă rândul inamicului.")
		return
	if slot == null or not slot.filled:
		_show_toast("Slot gol!")
		return


	selected_player_item = slot

	print("DEBUG: select_player_item a fost apelat pentru", slot.get_nume())
	_show_toast("Ai ales: %s" % slot.get_nume())
	is_player_turn = false
	await get_tree().process_frame
	await get_tree().process_frame
	enemy_choose_item()
	# apel direct fără await

# --------------------------------------
# ENEMY ALEGE AUTOMAT
# --------------------------------------
func enemy_choose_item() -> void:
	var inv_enemy_node = get_node_or_null(inv_enemy)
	if inv_enemy_node == null:
		_show_toast("Inventarul inamicului lipsește!")
		return

	var grid = inv_enemy_node.get_node_or_null("MarginContainer/GridContainer")
	if grid == null:
		_show_toast("Structura inventarului inamicului nu e corectă!")
		return

	var available: Array = []
	for c in grid.get_children():
		if c is Slot and c.filled:
			available.append(c)

	if available.is_empty():
		_show_toast("Enemy nu are iteme!")
		return

	var choice = available[randi() % available.size()]
	selected_enemy_item = choice


	_show_toast("Enemy a ales: %s" % choice.get_nume())

	# ✅ După ce enemy alege, e iar rândul playerului
	is_player_turn = true
	_show_toast("E rândul tău. Alege un nou item!")


# --------------------------------------
# CÂND SE APASĂ FIGHT
# --------------------------------------
func _on_fight_pressed() -> void:

	if selected_player_item == null:
		_show_toast("Alege un item pentru tine!")
		return
	if selected_enemy_item == null:
		_show_toast("Enemy nu a ales încă un item!")
		return

	var id_p = str(selected_player_item.get_number())
	var id_e = str(selected_enemy_item.get_number())

	for key in RECIPES.keys():
		var rec = RECIPES[key]
		var need_p = rec["player"]
		var need_e = rec["enemy"]
		var res = rec["result"]

		var match_normal = need_p.has(id_p) and need_e.has(id_e)
		var match_inverse = need_p.has(id_e) and need_e.has(id_p)

		if match_normal or match_inverse:
			selected_player_item.decrease_cantitate(1)
			selected_enemy_item.decrease_cantitate(1)
			_place_result(res)
			_show_toast("Ai craftuit: %s" % res.get("NUME", "item"))

			_reset_turns()
			return

	_show_toast("Nu există rețetă pentru combinația aleasă!")

# --------------------------------------
# HELPER: RESET
# --------------------------------------
func _reset_turns() -> void:

	selected_player_item = null
	selected_enemy_item = null
	is_player_turn = true
	_show_toast("Runda următoare! Alege un nou item.")

# --------------------------------------
# VIZUAL (highlight)
# --------------------------------------




# --------------------------------------
# RESULT & TOAST
# --------------------------------------
func _place_result(result: Dictionary) -> bool:
	var payload := {
		"TEXTURE": result.get("TEXTURE", null),
		"CANTITATE": int(result.get("CANTITATE", 1)),
		"NUMBER": int(result.get("NUMBER", 0)),
		"NUME": String(result.get("NUME", "")),
	}
	if _result_slot and _place_in_slot_or_stack(_result_slot, payload):
		return true
	if _inv_p and _add_to_first_free_slot(_inv_p, payload):
		return true
	return false

func _place_in_slot_or_stack(slot: Slot, payload: Dictionary) -> bool:
	if not slot.filled:
		slot.set_property(payload)
		slot.filled = true
		return true
	elif slot.get_number() == payload["NUMBER"]:
		slot.increase_cantitate(payload["CANTITATE"])
		return true
	return false

func _add_to_first_free_slot(inv_root: Node, payload: Dictionary) -> bool:
	for c in inv_root.get_node("MarginContainer/GridContainer").get_children():
		if c is Slot and (not c.filled or c.get_number() == 0):
			c.set_property(payload)
			c.filled = true
			return true
	return false

func _show_toast(msg: String) -> void:
	if _player_node and _player_node.has_method("show_toast"):
		_player_node.show_toast(msg)
	else:
		print(msg)
