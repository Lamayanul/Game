extends Control

@onready var slot_container: Slot = $RichTextLabel/SlotContainer

func _ready() -> void:
	var item_de_start = {
		"TEXTURE": load("res://assets/mar.png"),
		"CANTITATE": 200,
		"NUMBER": 7,
		"NUME": "mar",
		"RARITATE": "comuna",
		"EFFECTS": [],
		"CURSE": null,
		"type":["food"],}
	slot_container.set_property(item_de_start)
