extends Node
class_name CombatManager

# === Asignează din Inspector ===
@export var inv_player: NodePath
@export var inv_enemy:  NodePath
@export var fight_button: NodePath         # butonul care declanșează craft/fight
@export var result_slot_path: NodePath     # slotul unde pui rezultatul (opțional)

# (opțional) dacă vrei și UX (toast)
@export var player_node_path: NodePath = ^"/root/world/player"

# ---- Rețete (exemple) ----
# Folosește ID-urile ca STRING (chei din DB) sau numărul "NUMBER" convertit în string.
var RECIPES := {
	"apple_pie": {
		# player trebuie să aibă 1x id "3", enemy 1x id "7" (sau invers)
		"player": {"3": 1},
		"enemy":  {"7": 1},
		"result": {
			"TEXTURE": preload("res://assets/pie.png"),
			"CANTITATE": 1,
			"NUMBER": 15,
			"NUME": "apple pie",
			"RARITATE": "comuna",
			"CURSE": null,
			"EFFECTS": []
		}
	},
	"bread": {
		"player": {"6": 1},
		"enemy":  {"11": 1},
		"result": {
			"TEXTURE": preload("res://assets/pickaxe.png"),
			"CANTITATE": 1,
			"NUMBER": 10,
			"NUME": "bread",
			"RARITATE": "comuna",
			"CURSE": null,
			"EFFECTS": []
		}
	}
}

# ---- cache noduri ----
@onready var _inv_p: Node = get_node_or_null(inv_player)
@onready var _inv_e: Node = get_node_or_null(inv_enemy)
@onready var _btn: Button = get_node_or_null(fight_button)
@onready var _result_slot: Slot = get_node_or_null(result_slot_path)
@onready var _player_node: Node = get_node_or_null(player_node_path)

func _ready() -> void:
	if _btn and not _btn.is_connected("pressed", Callable(self, "_on_fight_pressed")):
		_btn.pressed.connect(Callable(self, "_on_fight_pressed"))
	

# ===================== LOGICĂ PRINCIPALĂ =====================

func _on_fight_pressed() -> void:
	if _inv_p == null or _inv_e == null:
		_show_toast("Lipsește un inventar (player/enemy)!")
		return

	# Inventare agregate (hărți ID->cantitate)
	var counts_p := _inventory_counts(_inv_p) # Dictionary<String,int>
	var counts_e := _inventory_counts(_inv_e)

	# Încearcă pe rând rețetele; găsește prima satisfăcută (normal sau invers)
	for key in RECIPES.keys():
		var rec: Dictionary = RECIPES[key]
		var need_p: Dictionary = rec.get("player", {})
		var need_e: Dictionary = rec.get("enemy", {})
		var res: Dictionary = rec.get("result", {})

		# orientarea normală: player trebuie să aibă need_p, enemy need_e
		var ok_normal := _has_required(counts_p, need_p) and _has_required(counts_e, need_e)
		# orientarea inversă: player -> need_e, enemy -> need_p
		var ok_inverse := _has_required(counts_p, need_e) and _has_required(counts_e, need_p)

		if ok_normal or ok_inverse:
			# consumă
			if ok_normal:
				if not _consume_from_inventory(_inv_p, need_p): 
					continue
				if not _consume_from_inventory(_inv_e, need_e): 
					# rollback minim (nu mai adaug înapoi – simplificare)
					continue
			else:
				# invers
				if not _consume_from_inventory(_inv_p, need_e): 
					continue
				if not _consume_from_inventory(_inv_e, need_p): 
					continue

			# pune rezultatul
			if _place_result(res):
				_show_toast("Ai craftuit: %s" % String(res.get("NUME", "item")))
			else:
				_show_toast("Nu am unde să pun rezultatul.")
			return

	# dacă nu s-a găsit nicio potrivire
	_show_toast("Nu există rețetă valabilă (player+enemy) pentru ce ai acum.")

# ======================= INVENTAR: UTILITARE =======================

# Agregă cantitățile dintr-un inventar (toți copiii Slot)
func _inventory_counts(inv_root: Node) -> Dictionary:
	var counts := {}
	for c in inv_root.get_node("MarginContainer/GridContainer").get_children():
		if c is Slot:
			var s := c as Slot
			if s.filled and s.get_number() != 0 and s.get_texture() != null:
				var id := str(s.get_number())  # folosim NUMBER ca ID
				counts[id] = int(counts.get(id, 0)) + int(s.get_cantitate())
	return counts

# Verifică dacă counts conține toate cerințele req (ID->cant)
func _has_required(counts: Dictionary, req: Dictionary) -> bool:
	for id in req.keys():
		if int(counts.get(id, 0)) < int(req[id]):
			return false
	return true

# Consumă din sloturi cantitățile cerute (req) – merge peste mai multe sloturi
func _consume_from_inventory(inv_root: Node, req: Dictionary) -> bool:
	if inv_root == null:
		return false
	# Copie a cerințelor care scade spre 0
	var remaining := {}
	for k in req.keys():
		remaining[k] = int(req[k])

	# Trec prin sloturi și scad
	for c in inv_root.get_node("MarginContainer/GridContainer").get_children():
		if c is Slot:
			var s := c as Slot
			if not s.filled or s.get_number() == 0:
				continue
			var id := str(s.get_number())
			if not remaining.has(id):
				continue
			var need := int(remaining[id])
			if need <= 0:
				continue
			var have := int(s.get_cantitate())
			if have <= 0:
				continue

			var take = min(have, need)
			var emptied := s.decrease_cantitate(take)  # true dacă a ajuns la 0 și a curățat slotul
			remaining[id] = need - take

	# verifică dacă am consumat tot
	for k in remaining.keys():
		if int(remaining[k]) > 0:
			return false
	return true

# ===================== PLASARE REZULTAT =====================

func _place_result(result: Dictionary) -> bool:
	# normalizează payload-ul minim așteptat de Slot
	var payload := {
		"TEXTURE": result.get("TEXTURE", null),
		"CANTITATE": int(result.get("CANTITATE", 1)),
		"NUMBER": int(result.get("NUMBER", 0)),
		"NUME": String(result.get("NUME", "")),
		"RARITATE": String(result.get("RARITATE", "")),
		"CURSE": result.get("CURSE", null),
		"EFFECTS": result.get("EFFECTS", [])
	}

	# 1) încearcă în result_slot (dacă există)
	if _result_slot and _place_in_slot_or_stack(_result_slot, payload):
		return true

	# 2) încearcă să stivuiască într-un slot existent din inventarul playerului
	if _inv_p and _stack_into_inventory(_inv_p, payload):
		return true

	# 3) pune în primul slot liber din inventarul playerului
	if _inv_p and _add_to_first_free_slot(_inv_p, payload):
		return true

	return false

func _place_in_slot_or_stack(slot: Slot, payload: Dictionary) -> bool:
	if slot == null:
		return false
	# Slot gol
	if not slot.filled or slot.get_number() == 0 or slot.get_texture() == null:
		slot.set_property(payload)
		slot.filled = true
		return true
	# Slot ocupat – stivuire doar dacă e IDENTIC (NUMBER + CURSE + EFFECTS)
	var same_number := slot.get_number() == int(payload["NUMBER"])
	var same_curse  := str(slot.get_curse()) == str(payload.get("CURSE", null))
	var same_effects:= str(slot.get_effects()) == str(payload.get("EFFECTS", []))
	if same_number and same_curse and same_effects:
		slot.increase_cantitate(int(payload["CANTITATE"]))
		return true
	return false

func _stack_into_inventory(inv_root: Node, payload: Dictionary) -> bool:
	for c in inv_root.get_node("MarginContainer/GridContainer").get_children():
		if c is Slot:
			var s := c as Slot
			if not s.filled: continue
			if s.get_number() != int(payload["NUMBER"]): continue
			if str(s.get_curse()) != str(payload.get("CURSE", null)): continue
			if str(s.get_effects()) != str(payload.get("EFFECTS", [])): continue
			s.increase_cantitate(int(payload["CANTITATE"]))
			return true
	return false

func _add_to_first_free_slot(inv_root: Node, payload: Dictionary) -> bool:
	for c in inv_root.get_node("MarginContainer/GridContainer").get_children():
		if c is Slot:
			var s := c as Slot
			if not s.filled or s.get_number() == 0 or s.get_texture() == null:
				s.set_property(payload)
				s.filled = true
				return true
	return false

# ====================== UX MIC (opțional) ======================

func _show_toast(msg: String) -> void:
	if _player_node and _player_node.has_method("show_toast"):
		_player_node.show_toast(msg)
	else:
		print(msg)
