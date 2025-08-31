extends Control

@export var card_size := Vector2(600,340)
@export var hover_scale := 1.4
@export var hover_duration := 0.12
@export var raise_z_on_hover := true
@onready var control_2: Control = $"../Control2"

@onready var panel: PanelContainer = $PanelContainer
@onready var tex_front: TextureRect = $PanelContainer/TextureRect
@onready var tex_back:  TextureRect = $PanelContainer/TextureRect2
var base_global_pos := Vector2.ZERO
@onready var scroll_container: ScrollContainer = $"../.."

var _tw: Tween

func _ready() -> void:
	
	# Lasă ScrollContainer să primească rotița
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Copilul vizual nu trebuie să consume input
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Dimensiune stabilă pentru HBox
	custom_minimum_size = card_size

	
	# Pivot pentru scalare la centru (după ce are mărimea finală)
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5

	# Hover
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	#set_big_step(150)
	
func _on_hover_in() -> void:
	_zoom_to(hover_scale)
	if raise_z_on_hover:
		scroll_container.clip_contents=false
		z_index = 1

func _on_hover_out() -> void:
	_zoom_to(1.0)
	if raise_z_on_hover:
		scroll_container.clip_contents=true
		z_index = 0

func _zoom_to(f: float) -> void:
	if _tw and _tw.is_running():
		_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tw.tween_property(panel, "scale", Vector2(f, f), hover_duration)

# Dublu-click pentru flip (nu blochează scroll-ul)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click and mb.pressed:
			tex_front.visible = not tex_front.visible
			tex_back.visible  = not tex_back.visible

func set_big_step(px: float = 150):
	var h = scroll_container.get_h_scroll_bar()
	h.step = px   # pasul la fiecare eveniment de scroll
