extends Node2D
#
#var item_pool: Array = []  # Lista de obiecte reutilizabile
#var item_scene: PackedScene  # Scena pentru obiectul item
#var item_data  # Instanța pentru Database
#
#func _ready():
	## Instanțiază clasa Database
	#item_data = load("res://Autoload/Database.gd").new()
#
	#item_scene = preload("res://User/item.tscn")  # Încarcă scena obiectului item
	#if item_scene == null:
		#print("Eroare: Scena item.tscn nu a fost încărcată.")
		#return
	#
	## Inițializăm pool-ul cu 10 obiecte
	#for i in range(10):
		#var item = item_scene.instantiate()  # Instanțiem un obiect
		#item.visible = false  # Ascundem obiectul și îl facem inactiv
		#add_child(item)
		#item_pool.append(item)  # Adăugăm obiectul în pool
#
	#print("Pool inițializat:", item_pool.size(), "obiecte disponibile.")
#
#func get_item(item_id: String) -> Sprite2D:
	#var item: Sprite2D
#
	## Verificăm dacă există obiecte disponibile în pool
	#if item_pool.size() > 0:
		#item = item_pool.pop_back()  # Extragem un obiect din pool
	#else:
		#item = item_scene.instantiate()  # Instanțiem un nou obiect dacă pool-ul e gol
		#add_child(item)
#
	## Configurăm obiectul cu ID-ul și textura corespunzătoare
	#setup_item(item, item_id)
	#return item
#
#func return_item_to_pool(item: Sprite2D):
	## Resetează proprietățile obiectului și îl ascunde
	#item.visible = false
	#item.position = Vector2.ZERO
	#if item.has_node("CollisionShape2D"):  # Dezactivează coliziunea dacă există
		#item.get_node("CollisionShape2D").disabled = true
	#item_pool.append(item)  # Returnează obiectul în pool
#
#func setup_item(item: Sprite2D, item_id: String):
	## Configurează textura și alte proprietăți ale obiectului pe baza ID-ului
	#var texture_path = item_data.get_texture(item_id)
	#if texture_path != null and texture_path != "":
		#item.texture = load("res://assets/" + texture_path)
		#print("Textura pentru item", item_id, "setată:", texture_path)
	#else:
		#print("Eroare: Textura pentru ID-ul", item_id, "nu a fost găsită.")
	#
	## Dacă ai alte proprietăți care trebuie configurate, le adaugi aici
	#item.position = Vector2.ZERO
	#item.visible = true
	#if item.has_node("CollisionShape2D"):
		#item.get_node("CollisionShape2D").disabled = false
