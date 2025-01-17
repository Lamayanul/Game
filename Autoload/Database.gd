extends Node

var content:Dictionary= {}

func _ready():
 var file=FileAccess.open("res://Autoload/Database.json",FileAccess.READ)
 content=JSON.parse_string(file.get_as_text())
 file.close()
 print("Content:", content)
 for key in content.keys():
  print("Key:", key, "Value:", content[key])


func get_texture(ID="0"):
 return content[ID]["texture"]

func get_cantitate(ID="0"):
 return content[ID]["cantitate"]

func get_number(ID="0"):
 return content[ID]["number"]

func get_nume(ID="0"):
 return content[ID]["nume"]
