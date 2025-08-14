extends TextureRect

@export var slot_scene: PackedScene   # Asociază Slot.tscn din editor

func _can_drop_data(_pos, data):
	# Verifică dacă e drag din inventar
	if self.visible==false:
		return false
	if data is Slot and data.slot_type=="inventory":
		return false
	else:
		return true

func _drop_data(pos, data):
		if data.get_parent() != self:
			data.get_parent().remove_child(data)
			add_child(data)
		
