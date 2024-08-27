extends PanelContainer

@onready var grid_container = $MarginContainer/GridContainer
# Eliminăm această linie, deoarece nu este necesară referința directă la SlotContainer.
# @onready var slot = $MarginContainer/GridContainer/SlotContainer


	

func add_item(ID="0"):
	var item_texture = load("res://assets/" + ItemData.get_texture(ID))
	var item_cantitate = ItemData.get_cantitate(ID)
	
	# Verifică dacă texturile sunt încărcate corect
	var item_data = {"TEXTURE": item_texture, "CANTITATE": item_cantitate}
	
	var start_index = 0
	var index = start_index

	for i in range(start_index, grid_container.get_child_count()):
		var child = grid_container.get_child(i)
		if child != null and child.has_method("set_property"):
			if child.filled == false:
				index = i
				break
	
	# Verifică dacă slotul este valid înainte de a apela set_property
	var slot = grid_container.get_child(index)
	if slot != null and slot.has_method("set_property"):
		slot.set_property(item_data)
	else:
		print("Eroare: Slotul este null sau nu are metoda set_property.")
