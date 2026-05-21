extends Control

@export var slot_scene: PackedScene = preload("res://User/slot_container.tscn")
@export var grid_size: int = 8

@onready var grid_container = $BoardContainer/GridContainer
@onready var piece_grid = $UI/PlacementStorage/VBox/Scroll/PieceGrid
@onready var phase_label = $UI/PhaseLabel
@onready var start_btn = $UI/StartBattleBtn
@onready var activate_effects_btn = $UI/ActivateEffectsBtn
@onready var selector = $Selector
@onready var placement_storage_panel = $UI/PlacementStorage

enum Phase { PLACEMENT, BATTLE }
var current_phase = Phase.PLACEMENT

var auto_trigger_effects: bool = false
var disabled_slots: Array[Slot] = []
var protected_slots: Array[Slot] = []
var PIECE_TYPES = ["queen", "rook", "bishop", "knight", "pawn"]
var turn_count: int = 0

# Texture definitions for pieces
const WHITE_PIECES = {
	"king": "res://assets/W_King.png",
	"queen": "res://assets/W_Queen.png",
	"rook": "res://assets/W_Rook.png",
	"bishop": "res://assets/W_Bishop.png",
	"knight": "res://assets/W_Knight.png",
	"pawn": "res://assets/W_Pawn.png"
}

const BLACK_PIECES = {
	"king": "res://assets/B_King.png",
	"queen": "res://assets/B_Queen.png",
	"rook": "res://assets/B_Rook.png",
	"bishop": "res://assets/B_Bishop.png",
	"knight": "res://assets/B_Knight.png",
	"pawn": "res://assets/B_Pawn.png"
}

var all_slots: Array[Slot] = []
var board_matrix: Array = [] 
var storage_slots: Array[Slot] = []

var selected_storage_slot: Slot = null
var selected_board_slot: Slot = null
var valid_moves: Array = []

class Piece:
	var type: String
	var side: String 
	var row: int
	var col: int
	var slot: Slot

var pieces: Dictionary = {} 

func _ready():
	z_index = 10
	start_btn.pressed.connect(_on_start_battle_pressed)
	if activate_effects_btn:
		activate_effects_btn.pressed.connect(_on_activate_effects_pressed)
	
	for child in grid_container.get_children(): child.queue_free()
	for child in piece_grid.get_children(): child.queue_free()
	
	await get_tree().process_frame
	_setup_board()
	_setup_placement_storage()
	_update_ui()

func _setup_board():
	all_slots.clear()
	board_matrix.clear()
	for i in range(grid_size * grid_size):
		var slot = slot_scene.instantiate() as Slot
		grid_container.add_child(slot)
		all_slots.append(slot)
		slot.slot_type = "board"
		var row = i / grid_size
		var col = i % grid_size
		var bg = slot.get_node("TextureHolder/TextureRect2")
		bg.modulate = Color(0.7, 0.7, 0.7) if (row + col) % 2 == 1 else Color(1, 1, 1)
		slot.gui_input.connect(_on_slot_gui_input.bind(slot, row, col))

	for r in range(grid_size):
		var row_data = []
		for c in range(grid_size): row_data.append(all_slots[r * grid_size + c])
		board_matrix.append(row_data)

func _setup_placement_storage():
	var player_pool = ["king", "queen", "rook", "rook", "bishop", "bishop", "knight", "knight", "pawn", "pawn", "pawn", "pawn"]
	for type in player_pool:
		_add_piece_type_to_storage(type, "player")

func _add_piece_type_to_storage(type: String, side: String):
	var slot = slot_scene.instantiate() as Slot
	piece_grid.add_child(slot)
	storage_slots.append(slot)
	slot.slot_type = "storage_piece"
	var piece_rect = slot.get_node("TextureHolder/TextureRect3")
	var tex_path = WHITE_PIECES[type] if side == "player" else BLACK_PIECES[type]
	piece_rect.texture = load(tex_path)
	piece_rect.visible = true
	piece_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.set_meta("piece_type", type)
	slot.set_meta("piece_side", side)
	slot.gui_input.connect(_on_storage_slot_input.bind(slot))

func _on_storage_slot_input(event, slot):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if selected_storage_slot: selected_storage_slot.modulate = Color(1, 1, 1)
		selected_storage_slot = slot
		slot.modulate = Color(1, 1, 0)

func _on_slot_gui_input(event: InputEvent, slot: Slot, r: int, c: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if disabled_slots.has(slot): return
		if selected_storage_slot: 
			_handle_placement_click(slot, r, c)
		elif current_phase == Phase.PLACEMENT: 
			_handle_placement_click(slot, r, c)
		else: 
			_handle_battle_click(slot, r, c)

func _handle_placement_click(slot, r, c):
	if r < 4:
		_show_toast("Poti pune piese doar in jumatatea ta!")
		return
	if selected_storage_slot:
		if not pieces.has(slot):
			var type = selected_storage_slot.get_meta("piece_type")
			var side = selected_storage_slot.get_meta("piece_side") if selected_storage_slot.has_meta("piece_side") else "player"
			_add_piece(type, side, r, c)
			selected_storage_slot.queue_free()
			storage_slots.erase(selected_storage_slot)
			selected_storage_slot = null
			if storage_slots.is_empty() and current_phase == Phase.BATTLE:
				placement_storage_panel.visible = false
		else: _show_toast("Slot ocupat!")

func _handle_battle_click(slot, r, c):
	if selected_board_slot == null:
		if pieces.has(slot) and pieces[slot].side == "player": _select_piece(slot)
	else:
		if slot in valid_moves: _move_piece(selected_board_slot, slot)
		else:
			_deselect()
			if pieces.has(slot) and pieces[slot].side == "player": _select_piece(slot)

func _on_start_battle_pressed():
	if pieces.is_empty():
		_show_toast("Pune macar o piesa!")
		return
	current_phase = Phase.BATTLE
	placement_storage_panel.visible = false
	start_btn.visible = false
	if activate_effects_btn: activate_effects_btn.visible = true
	_enemy_auto_placement()
	_spawn_random_items(10)
	_update_ui()

func _on_activate_effects_pressed():
	auto_trigger_effects = true
	_trigger_all_active_items()
	_show_toast("Efecte activate automat pe fiecare turn!")

func _trigger_all_active_items():
	var items_to_process = []
	for slot in all_slots:
		if slot.filled and not disabled_slots.has(slot):
			var spawn_turn = slot.get_meta("spawn_turn") if slot.has_meta("spawn_turn") else -1
			if turn_count > spawn_turn:
				items_to_process.append(slot)
	
	for slot in items_to_process:
		_apply_item_effect(slot)

func _apply_item_effect(slot: Slot):
	var item_id = slot.get_id()
	var pos_idx = all_slots.find(slot)
	var r = pos_idx / grid_size
	var c = pos_idx % grid_size

	match item_id:
		"9": _disable_slot(slot)
		"19": _area_clear(r, c)
		"14": _spawn_units_around(r, c)
		"10": _line_disable_effect(r, c)
		"4": _spawn_seeds_around(r, c)
		"11": _destroy_closest_piece(r, c)
		"13": _apply_protection_random()
		"12": _restore_disabled_slots_random()

func _disable_slot(slot: Slot):
	if protected_slots.has(slot): return 
	if not disabled_slots.has(slot):
		disabled_slots.append(slot)
		slot.clear_item()
		if pieces.has(slot):
			pieces[slot].slot.get_node("TextureHolder/TextureRect3").texture = null
			pieces.erase(slot)
		slot.modulate = Color(0.2, 0.2, 0.2, 1.0)
		var bg = slot.get_node("TextureHolder/TextureRect2")
		bg.modulate = Color(0.1, 0.1, 0.1)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _area_clear(center_r: int, center_c: int):
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var nr = center_r + dr; var nc = center_c + dc
			if _is_in_board(nr, nc):
				var target_slot = board_matrix[nr][nc]
				if protected_slots.has(target_slot): continue 
				target_slot.clear_item()
				if pieces.has(target_slot):
					target_slot.get_node("TextureHolder/TextureRect3").texture = null
					pieces.erase(target_slot)
				var tw = create_tween()
				target_slot.modulate = Color(2, 2, 2)
				tw.tween_property(target_slot, "modulate", Color(1, 1, 1), 0.5)

func _spawn_units_around(center_r: int, center_c: int):
	var empty_slots = []
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var nr = center_r + dr; var nc = center_c + dc
			if _is_in_board(nr, nc):
				var slot = board_matrix[nr][nc]
				if not pieces.has(slot) and not slot.filled and not disabled_slots.has(slot):
					empty_slots.append(slot)
	
	empty_slots.shuffle()
	if empty_slots.size() >= 1:
		var type_p = PIECE_TYPES[randi() % PIECE_TYPES.size()]
		var s1 = empty_slots.pop_back()
		_add_piece(type_p, "player", all_slots.find(s1)/grid_size, all_slots.find(s1)%grid_size)
	
	if empty_slots.size() >= 1:
		var type_e = PIECE_TYPES[randi() % PIECE_TYPES.size()]
		var s2 = empty_slots.pop_back()
		_add_piece(type_e, "enemy", all_slots.find(s2)/grid_size, all_slots.find(s2)%grid_size)

func _line_disable_effect(r: int, c: int):
	var directions = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	var chosen_dir = directions[randi() % directions.size()]
	var nr = r + chosen_dir.x; var nc = c + chosen_dir.y
	while _is_in_board(nr, nc):
		_disable_slot(board_matrix[nr][nc])
		nr += chosen_dir.x; nc += chosen_dir.y

func _spawn_seeds_around(center_r: int, center_c: int):
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			if dr == 0 and dc == 0: continue
			var nr = center_r + dr; var nc = center_c + dc
			if _is_in_board(nr, nc):
				var slot = board_matrix[nr][nc]
				if not slot.filled and not pieces.has(slot) and not disabled_slots.has(slot):
					_spawn_specific_item(slot, "3")

func _destroy_closest_piece(r: int, c: int):
	var center_pos = Vector2(r, c)
	var closest_piece_slot = null
	var min_dist = 9999.0
	for slot in pieces.keys():
		if protected_slots.has(slot): continue 
		var piece = pieces[slot]
		var dist = center_pos.distance_to(Vector2(piece.row, piece.col))
		if dist > 0 and dist < min_dist:
			min_dist = dist
			closest_piece_slot = slot
	if closest_piece_slot:
		closest_piece_slot.get_node("TextureHolder/TextureRect3").texture = null
		pieces.erase(closest_piece_slot)
		var tw = create_tween()
		closest_piece_slot.modulate = Color(1, 0, 0)
		tw.tween_property(closest_piece_slot, "modulate", Color(1, 1, 1), 0.5)

func _apply_protection_random():
	var valid_candidates = []
	for slot in all_slots:
		if (slot.filled or pieces.has(slot)) and not protected_slots.has(slot) and not disabled_slots.has(slot):
			valid_candidates.append(slot)
	if not valid_candidates.is_empty():
		var target = valid_candidates[randi() % valid_candidates.size()]
		protected_slots.append(target)
		var mark = target.get_node_or_null("MarkColor")
		if not mark:
			mark = ColorRect.new(); mark.name = "MarkColor"; mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); target.add_child(mark)
		mark.color = Color(0, 0.5, 1, 0.5)
		_show_toast("Protectie activata!")

func _restore_disabled_slots_random():
	if disabled_slots.is_empty(): return
	var count = randi_range(1, 3)
	disabled_slots.shuffle()
	for i in range(min(count, disabled_slots.size())):
		var slot = disabled_slots.pop_back()
		slot.modulate = Color(1, 1, 1)
		var bg = slot.get_node("TextureHolder/TextureRect2")
		var row = all_slots.find(slot) / grid_size
		var col = all_slots.find(slot) % grid_size
		bg.modulate = Color(0.7, 0.7, 0.7) if (row + col) % 2 == 1 else Color(1, 1, 1)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
	_show_toast("Sloturi restaurate!")

func _enemy_auto_placement():
	var enemy_pool = ["king", "queen", "rook", "rook", "bishop", "bishop", "knight", "knight", "pawn", "pawn", "pawn", "pawn"]
	var available_slots = []
	for r in range(0, 4):
		for c in range(8): available_slots.append(Vector2i(r, c))
	available_slots.shuffle()
	for i in range(min(enemy_pool.size(), available_slots.size())):
		_add_piece(enemy_pool[i], "enemy", available_slots[i].x, available_slots[i].y)

func _update_ui():
	if current_phase == Phase.PLACEMENT: phase_label.text = "Faza 1: Pune piesele pe tabla"
	else: phase_label.text = "Faza 2: Lupta si colecteaza iteme!"

func _add_piece(type: String, side: String, r: int, c: int):
	var slot = board_matrix[r][c]
	var p = Piece.new()
	p.type = type; p.side = side; p.row = r; p.col = c; p.slot = slot
	pieces[slot] = p
	_update_piece_visual(p)

func _update_piece_visual(p: Piece):
	var tex_path = WHITE_PIECES.get(p.type) if p.side == "player" else BLACK_PIECES.get(p.type)
	var piece_rect = p.slot.get_node("TextureHolder/TextureRect3")
	piece_rect.texture = load(tex_path); piece_rect.visible = true; piece_rect.modulate = Color(1, 1, 1)

func _select_piece(slot: Slot):
	_deselect()
	selected_board_slot = slot
	var p = pieces[slot]
	valid_moves = _get_valid_moves(p)
	for s in valid_moves:
		if protected_slots.has(s): continue 
		var mark = s.get_node_or_null("MarkColor")
		if not mark:
			mark = ColorRect.new(); mark.name = "MarkColor"; mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); s.add_child(mark)
		mark.color = Color(0, 1, 0, 0.3)
	selector.visible = true; selector.global_position = slot.global_position; selector.size = slot.size

func _deselect():
	for slot in all_slots:
		if protected_slots.has(slot): continue 
		var mark = slot.get_node_or_null("MarkColor")
		if mark: mark.color = Color(1, 1, 1, 0)
	selected_board_slot = null; valid_moves.clear(); selector.visible = false

func _is_valid_target(r, c) -> bool:
	if not _is_in_board(r, c): return false
	return not disabled_slots.has(board_matrix[r][c])

func _get_valid_moves(p: Piece) -> Array:
	var moves = []
	var dirs = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	match p.type:
		"pawn", "king":
			for d in dirs:
				if _is_valid_target(p.row + d.x, p.col + d.y): moves.append(board_matrix[p.row + d.x][p.col + d.y])
		"rook": moves.append_array(_get_linear_moves(p, [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]))
		"bishop": moves.append_array(_get_linear_moves(p, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]))
		"queen": moves.append_array(_get_linear_moves(p, dirs))
		"knight":
			var km = [Vector2i(1, 2), Vector2i(1, -2), Vector2i(-1, 2), Vector2i(-1, -2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(-2, 1), Vector2i(-2, -1)]
			for d in km:
				if _is_valid_target(p.row + d.x, p.col + d.y): moves.append(board_matrix[p.row + d.x][p.col + d.y])
	var filtered = []
	for m in moves:
		if pieces.has(m):
			if pieces[m].side != p.side: filtered.append(m)
		else: filtered.append(m)
	return filtered

func _get_linear_moves(p: Piece, dirs: Array) -> Array:
	var moves = []
	for d in dirs:
		var cr = p.row + d.x; var cc = p.col + d.y
		while _is_valid_target(cr, cc):
			var slot = board_matrix[cr][cc]; moves.append(slot)
			if pieces.has(slot): break
			cr += d.x; cc += d.y
	return moves

func _is_in_board(r, c): return r >= 0 and r < grid_size and c >= 0 and c < grid_size

func _move_piece(from_slot: Slot, to_slot: Slot):
	var p = pieces[from_slot]
	if to_slot.filled: _collect_item(to_slot, p.side)
	if pieces.has(to_slot):
		if not protected_slots.has(to_slot):
			to_slot.get_node("TextureHolder/TextureRect3").texture = null
			pieces.erase(to_slot)
		else:
			_show_toast("Tinta este protejata!"); return
	
	pieces.erase(from_slot); from_slot.get_node("TextureHolder/TextureRect3").texture = null
	if protected_slots.has(from_slot):
		protected_slots.erase(from_slot); var old_mark = from_slot.get_node_or_null("MarkColor")
		if old_mark: old_mark.color = Color(1, 1, 1, 0)
		protected_slots.append(to_slot); var new_mark = to_slot.get_node_or_null("MarkColor")
		if not new_mark:
			new_mark = ColorRect.new(); new_mark.name = "MarkColor"; new_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			new_mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); to_slot.add_child(new_mark)
		new_mark.color = Color(0, 0.5, 1, 0.5)

	p.slot = to_slot; p.row = all_slots.find(to_slot) / grid_size; p.col = all_slots.find(to_slot) % grid_size
	pieces[to_slot] = p; _update_piece_visual(p)
	_deselect(); turn_count += 1; _spawn_random_items(1)
	if auto_trigger_effects: _trigger_all_active_items()
	if p.side == "player":
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()

func _enemy_turn():
	var enemy_pieces = []
	for p in pieces.values(): if p.side == "enemy": enemy_pieces.append(p)
	if enemy_pieces.is_empty(): return
	enemy_pieces.shuffle()
	for ep in enemy_pieces:
		var moves = _get_valid_moves(ep)
		if not moves.is_empty():
			_move_piece(ep.slot, moves[randi() % moves.size()]); break

func _collect_item(slot: Slot, collector_side: String):
	var item_data = slot.get_full_item(); var item_id = slot.get_id()
	var id_int = item_id.to_int()
	
	if id_int >= 34 and id_int <= 45:
		if collector_side == "player":
			var p_name = item_data["NUME"].to_lower()
			var p_type = "pawn"
			if "king" in p_name: p_type = "king"
			elif "queen" in p_name: p_type = "queen"
			elif "rook" in p_name: p_type = "rook"
			elif "bishop" in p_name: p_type = "bishop"
			elif "knight" in p_name: p_type = "knight"
			_add_piece_type_to_storage(p_type, "player")
			placement_storage_panel.visible = true
			_show_toast("Piesa noua adaugata in storage!")
	else:
		_show_toast("%s colectat %s" % [collector_side.capitalize(), item_data["NUME"]])
		var inv_to_add = get_node_or_null("../TextureRect2/Inv_player") if collector_side == "player" else get_node_or_null("../TextureRect2/Inv_enemy")
		if not inv_to_add and collector_side == "player": inv_to_add = get_node_or_null("/root/world/CanvasLayer/Inv")
		if inv_to_add and inv_to_add.has_method("add_item"): inv_to_add.add_item(item_id, 1)
	
	if protected_slots.has(slot):
		protected_slots.erase(slot); var mark = slot.get_node_or_null("MarkColor")
		if mark: mark.color = Color(1, 1, 1, 0)
	slot.set_meta("spawn_turn", -1); slot.clear_item()

func _spawn_random_items(count: int):
	if ItemData.content.is_empty(): return
	var excluded = ["26", "27", "28", "29", "30", "31", "32", "33"]
	var item_ids = ItemData.content.keys().filter(func(id): return str(id) != "0" and not str(id) in excluded)
	for i in range(count):
		var r = randi() % grid_size; var c = randi() % grid_size; var slot = board_matrix[r][c]
		if not slot.filled and not pieces.has(slot) and not disabled_slots.has(slot):
			_spawn_specific_item(slot, str(item_ids[randi() % item_ids.size()]))

func _spawn_specific_item(slot: Slot, item_id: String):
	slot.set_property({"TEXTURE": load("res://assets/" + ItemData.get_texture(item_id)), "CANTITATE": 1, "NUMBER": ItemData.get_number(item_id), "NUME": ItemData.get_nume(item_id), "RARITATE": ItemData.get_raritate(item_id)})
	slot.filled = true; slot.set_meta("spawn_turn", turn_count)

func _show_toast(msg: String):
	var player_node = get_node_or_null("/root/world/player")
	if player_node and player_node.has_method("show_toast"): player_node.show_toast(msg)
	else: print(msg)

func get_slot_owner(slot: Slot) -> String: return pieces[slot].side if pieces.has(slot) else ""
func get_random_slot() -> Slot: return all_slots[randi() % all_slots.size()] if not all_slots.is_empty() else null
