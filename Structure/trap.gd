extends Area2D

var player_in_zone_trap: bool = false
var este_activat: bool = false 
var interact_hold_time: float = 0.0
const HOLD_DURATION: float = 1.0
@onready var spawn_location = get_node_or_null("/root/world/Dungeon/Spawn/Spawn_col")
@export var harta_tile: TileMapLayer 

# Referință la playerul existent în world
@onready var player_ref = get_node_or_null("/root/world/player")

func _process(delta: float) -> void:
	if player_in_zone_trap:
		if Input.is_action_pressed("interact"):
			interact_hold_time += delta
			if interact_hold_time >= HOLD_DURATION:
				_intra_in_dungeon()
				interact_hold_time = 0.0 
		else:
			if interact_hold_time > 0 and interact_hold_time < 0.3: 
				_schimba_cele_patru_tileuri()
			
			interact_hold_time = 0.0

func _schimba_cele_patru_tileuri() -> void:
	if not is_instance_valid(harta_tile): return
	
	var source_id = 4
			
	if not este_activat:
		harta_tile.set_cell(Vector2i(-32, 52), source_id, Vector2i(2, 0))
		harta_tile.set_cell(Vector2i(-31, 52), source_id, Vector2i(3, 0))
		harta_tile.set_cell(Vector2i(-32, 53), source_id, Vector2i(2, 1))
		harta_tile.set_cell(Vector2i(-31, 53), source_id, Vector2i(3, 1))
		este_activat = true
	else:
		harta_tile.set_cell(Vector2i(-32, 52), source_id, Vector2i(0, 0))
		harta_tile.set_cell(Vector2i(-31, 52), source_id, Vector2i(1, 0))
		harta_tile.set_cell(Vector2i(-32, 53), source_id, Vector2i(0, 1))
		harta_tile.set_cell(Vector2i(-31, 53), source_id, Vector2i(1, 1))
		este_activat = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone_trap = true
		print("Jucător în zonă. Ține apăsat 'interact' 3 secunde pentru Dungeon.")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone_trap = false
		interact_hold_time = 0.0

func _intra_in_dungeon() -> void:
	# Gestionăm nodurile din world
	var world_node = get_node_or_null("/root/world")
	if world_node:
		var dungeon_node = world_node.get_node_or_null("Dungeon")

		# Nu ascundem world direct, ci copiii lui care nu sunt necesari
		for child in world_node.get_children():
			var nume = child.name
			# Păstrăm active: player, CanvasLayer și Dungeon
			if nume == "player" or nume == "CanvasLayer" or nume == "Dungeon":
				child.visible = true
				child.process_mode = Node.PROCESS_MODE_ALWAYS

				# Dacă e CanvasLayer, ne asigurăm că doar Inv și Inv2 sunt vizibile
				if nume == "CanvasLayer":
					for ui_child in child.get_children():
						if ui_child.name == "Inv" or ui_child.name == "Inv2":
							ui_child.visible = true
							ui_child.process_mode = Node.PROCESS_MODE_ALWAYS
			else:
				# Orice altceva (TileMap, Background, NPC-uri, inamici) se ascunde și se dezactivează
				child.visible = false
				child.process_mode = Node.PROCESS_MODE_DISABLED

		# Repoziționăm jucătorul și configurăm coliziunile
		if player_ref:
			if dungeon_node:
				var spawn_node = dungeon_node.get_node_or_null("Spawn")
				if spawn_node:
					# Folosim global_position pentru a asigura poziționarea corectă
					player_ref.global_position = spawn_node.global_position
					print("Player spawnat la: ", spawn_node.global_position)


			# Setăm atât Layer cât și Mask pe 5
			player_ref.set_collision_layer_value(5, true)
			player_ref.set_collision_mask_value(5, true)

			# Dezactivăm restul straturilor pentru a nu interacționa cu lumea de afară
			for i in range(1, 5):
				player_ref.set_collision_layer_value(i, false)
				player_ref.set_collision_mask_value(i, false)

		print("Dungeon activat. TileMap ascuns, player spawnează pe layer 5.")
	else:
		print("Eroare: Nodul 'world' nu a fost găsit!")
