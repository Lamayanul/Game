extends Control

var ButtonScene: PackedScene = preload("res://Scene/tab_but.tscn")
@onready var ora = get_node("/root/world/Cycle_d_n/CanvasLayer/VBoxContainer/HBoxContainer/Hour")
@onready var zi = get_node("/root/world/Cycle_d_n/CanvasLayer/VBoxContainer/DayOfWeek")
@export var tray_path: NodePath
@onready var rich_text_label: RichTextLabel = $RichTextLabel

var tray: Control
# opțional: stocăm ferestrele ca map -> buton
var _buttons: Dictionary = {}

func _physics_process(_delta):
	rich_text_label.text = ora.text + "\n" + zi.text
	
func add_window(win: PanelContainer, title: String = "", icon: Texture2D = null) -> void:
	if _buttons.has(win):
		return
	var b: Button = _buttons.get(win)
	if b:
		# exista deja: doar il actualizam si il aratam
		b.text = title if title != "" else win.name
		if icon: b.icon = icon
		b.visible = true
		return
	await get_tree().process_frame  # asigură layout-ul
	
	b = ButtonScene.instantiate()
	
	b.text = title if title != "" else ""
	if icon:
		b.icon = icon
	b.custom_minimum_size = Vector2(64, 32)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		restore_window(win)
	)
	get_node("/root/world/CanvasLayer/Control/TaskBar/Tray").add_child(b)
	_buttons[win] = b

func restore_window(win: PanelContainer) -> void:
	#if _buttons.has(win):
		##_buttons[win].queue_free()
		#_buttons.erase(win)
	if is_instance_valid(win):
		win.visible = !win.visible
		win.move_to_front()
		if win.has_method("_clamp_inside_viewport"):
			win._clamp_inside_viewport()

func mini_tab(win: PanelContainer, title: String = "", icon: Texture2D = null) -> void:
	if _buttons.has(win):
		return
		
func remove_tab(win: PanelContainer) -> void:
	var b: Button = _buttons.get(win)
	if b:
		_buttons.erase(win)
		if is_instance_valid(b):
			b.queue_free() 
