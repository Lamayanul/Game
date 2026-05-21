# CardDropArea.gd
extends ScrollContainer

# Vom folosi un VBoxContainer pentru a aranja cardurile frumos,
# unul sub altul, atunci când le adaugi.

@onready var card_holder: VBoxContainer = $CardList

func _ready():
	# Nu mai trebuie să creăm 'card_holder' prin cod.
	# Linia 'add_child(card_holder)' trebuie ștearsă.
	pass

# Această funcție verifică DACĂ ai voie să faci drop
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Acceptăm și CardControl (carduri bancare) și Slot_Cup (cupoane)
	return data is CardControl or data is Slot_Cup

func _drop_data(at_position: Vector2, data: Variant):
	# Restul codului rămâne identic
	var card_node = data
	
	if card_node.get_parent():
		card_node.get_parent().remove_child(card_node)
		
	card_holder.add_child(card_node)
	card_holder.move_child(card_node, 0)
	
	card_node.set_compact_mode(true, 0.335  )
