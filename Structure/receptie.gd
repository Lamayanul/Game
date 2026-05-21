extends Area2D

var player_in_zone: bool = false

# Aceasta este variabila care ține minte starea (toggle-ul)
var este_activat: bool = false 

@export var harta_tile: TileMapLayer 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false

func _process(_delta: float) -> void:
	if player_in_zone and Input.is_action_just_pressed("interact"):
		_schimba_cele_patru_tileuri()

func _schimba_cele_patru_tileuri() -> void:
	if not is_instance_valid(harta_tile): return
	
	var source_id = 1 
	
	if not este_activat:
		# --- STAREA 2 (ex: Ușă deschisă / Buton apăsat) ---
		harta_tile.set_cell(Vector2i(1, 1), source_id, Vector2i(6, 4))
		harta_tile.set_cell(Vector2i(2, 1), source_id, Vector2i(7, 4))
		harta_tile.set_cell(Vector2i(1, 2), source_id, Vector2i(6, 5))
		harta_tile.set_cell(Vector2i(2, 2), source_id, Vector2i(7, 5))
		
		print("Activat! (Tile-uri noi)")
		este_activat = true # Schimbăm starea
		
	else:
		# --- STAREA 1 (Înapoi la normal) ---
		# ATENȚIE: Aici trebuie să pui coordonatele din atlas ale tile-urilor VECHI (originale).
		# Eu am pus (0, 0), (1, 0) etc. ca exemplu, trebuie să le înlocuiești tu cu cele corecte!
	
		harta_tile.set_cell(Vector2i(1, 1), source_id, Vector2i(4, 4)) # Stânga-sus (original)
		harta_tile.set_cell(Vector2i(2, 1), source_id, Vector2i(5, 4)) # Dreapta-sus (original)
		harta_tile.set_cell(Vector2i(1, 2), source_id, Vector2i(4, 5)) # Stânga-jos (original)
		harta_tile.set_cell(Vector2i(2, 2), source_id, Vector2i(5, 5)) # Dreapta-jos (original)
		
		print("Dezactivat! (Tile-uri originale)")
		este_activat = false # Schimbăm starea la loc
