extends Node2D
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
var count:int:
	set(value):
		count=value


var needs_update := false

func mark_dirty() -> void:
	await get_tree().process_frame
	needs_update = true
	
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode==KEY_ENTER:
			inv.instantiate_pillar()
		
	if Input.is_action_just_pressed("toggle_grid"):
		inv.instantiate_generator()

func save_data():
	Persistence.scor=count

func load_data():
	count=Persistence.scor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	auto_detect_refresh_rate()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func auto_detect_refresh_rate():
	await get_tree().create_timer(2.0).timeout  # așteaptă câteva secunde
	var fps = Engine.get_frames_per_second()
	if fps <= 62:
		Engine.max_fps = 60
	elif fps <= 102:
		Engine.max_fps = 100
	else:
		Engine.max_fps = 144
