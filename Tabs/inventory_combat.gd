extends Control

@export var db_path := "res://Autoload/Database.json"
@export var slot_scene: PackedScene                         # (optional) if you want to instance slots
@export var create_slots_if_empty := false                  # set true if Inv_enemy has no children
@export var slots_to_create := 12                           # how many slots to instance, if needed

@export var min_items := 1                                 # how many enemy items to roll (min..max)
@export var max_items := 4

@onready var inv_enemy := $"TextureRect2/Inv_enemy"

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	ensure_enemy_slots()
	var items_db := _load_db()
	if items_db.is_empty():
		push_warning("Database.json is empty or missing.")
		return
	_populate_enemy_inventory(items_db)

# --- ensure slots exist (if you want this node to also create them) ---
func ensure_enemy_slots() -> void:
	if not is_instance_valid(inv_enemy):
		push_error("Inv_enemy not found at 'TextureRect2/Inv_enemy'. Check the scene path.")
		return
	if inv_enemy.get_child_count() == 0 and create_slots_if_empty:
		if slot_scene == null:
			push_error("create_slots_if_empty is true but slot_scene is null.")
			return
		#for i in range(slots_to_create):
			#var s = slot_scene.instantiate()
			## optional: size/setup
			#if s is Control:
				#(s as Control).custom_minimum_size = Vector2(64, 64)
			#inv_enemy.add_child(s)

# --- load database ---
func _load_db() -> Dictionary:
	var d := {}
	if not FileAccess.file_exists(db_path):
		return d
	var f := FileAccess.open(db_path, FileAccess.READ)
	if f == null:
		return d
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		d = parsed
	return d

# --- choose random item keys, skipping "0" if used as empty ---
func _random_item_key(keys: Array) -> String:
	# remove "0" placeholder if present
	if keys.has("0"):
		keys.erase("0")
	if keys.is_empty():
		return ""
	return String(keys[_rng.randi_range(0, keys.size() - 1)])

# --- core populate ---
func _populate_enemy_inventory(db: Dictionary) -> void:
	# collect available slots (children that are Slot and are empty, or just any Slot)
	var slots: Array = []
	for c in inv_enemy.get_node("MarginContainer/GridContainer").get_children():
		if c is Slot:
			slots.append(c)

	if slots.is_empty():
		push_warning("Inv_enemy has no Slot children.")
		return

	# how many items we’ll place
	var count = clamp(_rng.randi_range(min_items, max_items), 0, slots.size())

	# shuffle slots so we fill random positions
	slots.shuffle()

	var filled := 0
	var keys := db.keys()

	for s in slots:
		if filled >= count:
			break

		# pick an item from DB
		var k := _random_item_key(keys)
		if k == "" or not db.has(k):
			continue
		var it: Dictionary = db[k]

		# build slot property
		var tex_path := "res://assets/" + String(it.get("texture", ""))
		var tex: Texture2D = load(tex_path)
		if tex == null:
			continue

		# quantity rules (you can adapt these)
		var qty := 1
		var nume := String(it.get("nume",""))
		var singletons := ["topor","axe","backpack","Buzduganul norocului","hoe","pickaxe","scut","stropitoare"]
		if nume in singletons:
			qty = 1
		else:
			qty = _rng.randi_range(1, 5)

		var data_for_slot := {
			"TEXTURE":  tex,
			"CANTITATE": qty,
			"NUMBER":   int(it.get("number", 0)),
			"NUME":     nume,
			"RARITATE": String(it.get("raritate","")),
			"CURSE":    it.get("curse", null),
			"EFFECTS":  it.get("effects", [])
		}

		# set item into the slot
		(s as Slot).set_property(data_for_slot)
		filled += 1
