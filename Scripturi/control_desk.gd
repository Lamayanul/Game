extends TextureRect

@export var slot_scene: PackedScene   # Asociază Slot.tscn din editor

#func _can_drop_data(_pos, data):
	## Verifică dacă e drag din inventar
	#return typeof(data) == TYPE_DICTIONARY and data.has("from_inventory")
#
#func _drop_data(pos, data):
	#if data.has("item_data"):
		## Instanțiază slot nou
		#var tray_slot = slot_scene.instantiate()
		#tray_slot.slot_type = "tray"  # Important: setăm tipul ca să se comporte ca tray!
#
		## Poziționare - poți să îl pui unde vrei (aici centru relativ la zona de tray)
		#tray_slot.position = get_local_mouse_position()
		#tray_slot.z_index=1
		#add_child(tray_slot)

func _can_drop_data(_pos, data):
	# Verifică dacă e drag din inventar
	if data is Slot and data.slot_type=="inventory":
		return false
	else:
		return true

func _drop_data(pos, data):
		if data.get_parent() != self:
			data.get_parent().remove_child(data)
			add_child(data)
		
