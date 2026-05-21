# Script atașat la RichTextLabel
extends RichTextLabel

func _gui_input(event: InputEvent):
	# Verificăm dacă e un eveniment de scroll (rotiță)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			
			# Verificăm dacă scrollbar-ul vertical este vizibil
			var scroll_bar = get_v_scroll_bar()
			
			# Dacă scrollbar-ul este vizibil, înseamnă că NOI
			# ar trebui să gestionăm acest scroll, nu părintele.
			if scroll_bar and scroll_bar.visible:
				
				# Spunem sistemului că am gestionat evenimentul.
				# Asta va lăsa RichTextLabel-ul să facă scroll,
				# dar va opri propagarea către ScrollContainer-ul părinte.
				get_viewport().set_input_as_handled()
