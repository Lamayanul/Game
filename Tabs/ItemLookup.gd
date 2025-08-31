# res://ui/ItemLookup.gd
extends Control

@onready var te: TextEdit = $"../PanelContainer/HBoxContainer/TextEdit"
@onready var lb: Label   = $"../Label"

func _ready() -> void:
	te.text_changed.connect(_on_text_changed)
	_on_text_changed()

func _on_text_changed() -> void:
	var q := te.text.strip_edges()
	if q.is_empty():
		lb.text = ""
		return

	var desc := ItemsDB.get_desc_by_name(q)
	lb.text = desc if desc != "" else "Nu există un item cu acest nume."
