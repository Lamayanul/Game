# res://db/ItemsDB.gd
extends Node

var _by_name: Dictionary = {}   # "nume" (lower) -> {nume, descriere, ...}

@export var json_path := "res://Tabs/Database_Internet.json"

func _ready() -> void:
	var txt := FileAccess.get_file_as_string(json_path)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("items.json trebuie să fie un Dictionary: {\"1\":{...}, ...}")
		return
	for id in parsed.keys():
		var it = parsed[id]
		if typeof(it) == TYPE_DICTIONARY and it.has("nume"):
			var key := String(it.nume).to_lower().strip_edges()
			_by_name[key] = it

func get_desc_by_name(name: String) -> String:
	var key = name.to_lower().strip_edges()
	if _by_name.has(key):
		return String(_by_name[key].get("descriere",""))
	# opțional: potrivire parțială (prefix / conține)
	return ""
