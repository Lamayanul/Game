# CardDropArea.gd
extends PanelContainer

# Vom folosi un VBoxContainer pentru a aranja cardurile frumos,
# unul sub altul, atunci când le adaugi.
@onready var card_holder: VBoxContainer = VBoxContainer.new()

func _ready():
	# Adăugăm VBoxContainer-ul ca un copil
	add_child(card_holder)

# Această funcție verifică DACĂ ai voie să faci drop
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Acceptăm drop-ul DOAR dacă datele pe care le tragem
	# sunt de tipul 'CardControl' (pe care l-am definit în Pasul 1)
	return data is CardControl

# Această funcție execută logica atunci CÂND faci drop
func _drop_data(at_position: Vector2, data: Variant):
	
	var card_node = data as CardControl
	print("Am primit cardul: ", card_node.name)
	
	if card_node.get_parent():
		card_node.get_parent().remove_child(card_node)
		
	card_holder.add_child(card_node)
	card_holder.move_child(card_node, 0) # Îl punem sus
	
	# --- AICI ESTE SCHIMBAREA ---
	
	# Apelăm noua funcție și îi dăm factorul de scalare dorit (ex: 0.2 pentru 20%)
	card_node.set_compact_mode(true, 0.2)
