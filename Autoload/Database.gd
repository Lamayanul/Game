extends Node

var content:Dictionary= {}

func _ready():
 var file=FileAccess.open("res://Autoload/Database.json",FileAccess.READ)
 content=JSON.parse_string(file.get_as_text())
 file.close()

func get_texture(ID="0"):
 return content[ID]["texture"]

func get_cantitate(ID="0"):
 return content[ID]["cantitate"]

func get_number(ID="0"):
 return content[ID]["number"]

#func get_id(number: int) -> String:
 #for id in content.keys():
  #if content[id]["number"] == number:
   #return id
 #return "0"
