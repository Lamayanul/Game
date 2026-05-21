extends Node2D
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var inv2 = $CanvasLayer/Inv2
@onready var rail = $CanvasLayer/Control/Control2/ScrollContainer/Rail
@onready var world: Node2D = $"."
var pc = false

var _is_syncing = false

func _on_inv2_updated():
	if _is_syncing: return
	_is_syncing = true
	
	# Ștergem DOAR cupoanele vechi, păstrăm itemele "despachetate"
	for child in rail.get_children():
		if child is Slot_Cup:
			rail.remove_child(child)
			child.queue_free()
			
	var items = inv2.get_all_items()
	for item in items:
		if not item.is_empty() and item.get("TEXTURE") != null:
			rail.add_coupon_card(item)
	_is_syncing = false

func _on_rail_updated():
	if _is_syncing: return
	_is_syncing = true
	
	var rail_items = []
	for child in rail.get_children():
		if child is Slot_Cup and child.has_method("get_item"):
			var data = child.get_item()
			if not data.is_empty() and data.get("TEXTURE") != null:
				rail_items.append(data)
	
	# Clear inv2 slots
	for child in inv2.grid_container.get_children():
		if child is Slot_Cup:
			child.clear_item()
	
	# Fill inv2 slots
	var slot_index = 0
	var slots = inv2.grid_container.get_children()
	for item_data in rail_items:
		while slot_index < slots.size() and not (slots[slot_index] is Slot_Cup):
			slot_index += 1
		if slot_index < slots.size():
			slots[slot_index].set_property(item_data)
			slot_index += 1
			
	_is_syncing = false

#@onready var trader = get_node("/root/world/CanvasLayer2")
var count:int:
	set(value):
		count=value


var needs_update := false

func mark_dirty() -> void:
	await get_tree().process_frame
	needs_update = true
	
func _input(event):
	#if event is InputEventKey:
		#if event.pressed and event.keycode==KEY_ENTER:
			#inv.instantiate_pillar()
		#
	#if Input.is_action_just_pressed("toggle_grid"):
		#inv.instantiate_generator()
	if event is InputEventKey:
		if event.pressed and event.keycode==KEY_TAB:
			pass
			#trader.visible=!trader.visible
	if Input.is_action_just_pressed("interact") and pc:
		$CanvasLayer/Control.visible = not $CanvasLayer/Control.visible
		var layer := $"CanvasLayer/Control/CanvasLayer"
		layer.visible = !layer.visible
		
			

#func save_data():
	#Persistence.scor=count
#
#func load_data():
	#count=Persistence.scor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	auto_detect_refresh_rate()
	
	if inv2:
		inv2.inventory_updated.connect(_on_inv2_updated)
	if rail:
		rail.rail_updated.connect(_on_rail_updated)
	
	# Initial sync
	_on_inv2_updated()
	
	#var spawner := preload("res://EnemySpawner.gd").new()
	#spawner.enemy_scene = preload("res://Scene/enemy.tscn")
	#world.add_child(spawner)

# pornește cu poziție specifică
	#spawner.start_spawning(Vector2(-582, 934))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func auto_detect_refresh_rate():
	await get_tree().create_timer(2.0).timeout  # așteaptă câteva secunde
	var fps = Engine.get_frames_per_second()
	if fps <= 62:
		Engine.max_fps = 60
	elif fps <= 102:
		Engine.max_fps = 100
	else:
		Engine.max_fps = 144


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		pc=true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		pc=false
