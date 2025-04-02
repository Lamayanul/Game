extends Node2D

var count:int:
	set(value):
		count=value

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode==KEY_ENTER:
			count+=5


func save_data():
	Persistence.scor=count

func load_data():
	count=Persistence.scor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
