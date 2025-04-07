extends Node2D
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
var count:int:
	set(value):
		count=value

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode==KEY_ENTER:
			count+=5
	if Input.is_action_just_pressed("toggle_grid"):
		inv.instantiate_pillar()

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
