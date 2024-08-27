extends Sprite2D

@export var ID="0"
func _ready():
	texture=load("res://assets/" + ItemData.get_texture(ID))

func _on_body_entered(body):
	get_parent().find_child("Inv").add_item(ID)
	queue_free()
