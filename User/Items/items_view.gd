extends Control

@onready var item_info = %Item_info

func _ready():
	print("[ItemsView] Script gata. Info label: ", item_info != null)

	clear_info()

func _on_close_button_pressed():
	print("[ItemsView] Inchidere fereastra")
	$CanvasLayer.visible = false
	clear_info()

func clear_info():
	if item_info:
		item_info.text = ""

func _on_slot_selected(slot):
	print("[ItemsView] Slot selectat: ", slot.get_nume() if slot.has_method("get_nume") else "Necunoscut")
	if item_info and slot:
		var nume = slot.get_nume() if slot.has_method("get_nume") else "???"
		var raritate = slot.get_raritate() if slot.has_method("get_raritate") else "???"
		var qty = slot.get_cantitate() if slot.has_method("get_cantitate") else 0
		
		var bb_text = "[center][color=white][b]ITEM:[/b][/color] %s\n" % nume 
		bb_text += "[b][color=white]RARITATE:[/color][/b] %s\n" % raritate
		bb_text += "[b][color=white]CANTITATE:[/color][/b] %s[/center]" % str(qty) 
		
		item_info.text = bb_text
		print("[ItemsView] Text setat in Item_info")
