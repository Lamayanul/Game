extends Resource
class_name CharacterProfile

@export var id: String = "char_id"
@export var display_name: String = "Nume"
@export var portrait: Texture2D

# AICI ESTE CHEIA: Fiecare caracter are propria SCENĂ de quest
@export var quest_scene: PackedScene 

@export_multiline var flavor_texts: Array[String] = []
