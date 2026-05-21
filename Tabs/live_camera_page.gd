extends Control

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var internal_camera: Camera2D = $SubViewportContainer/SubViewport/InternalCamera
@onready var color_rect: ColorRect = $ColorRect
@onready var camera_label: Label = $CameraLabel
@onready var buttons_container: HBoxContainer = $CameraButtons

var cameras: Array = []
var current_camera_index: int = 0

func _ready() -> void:
	# Verificăm dacă suntem în interiorul unui container și forțăm expandarea
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	call_deferred("_setup_everything")

func _setup_everything() -> void:
	# Căutăm nodul principal numit "world" în rădăcina scenei active
	var world_node = get_tree().root.find_child("world", true, false)
	
	if world_node:
		viewport.world_2d = world_node.get_viewport().world_2d
		print("Camera System: Connected to 'world' via find_child.")
	else:
		# Fallback: încercăm să luăm lumea viewport-ului principal direct
		viewport.world_2d = get_tree().root.get_viewport().world_2d
		print("Camera System: 'world' node not found, using root viewport world.")
	
	# Resetăm camera internă
	internal_camera.enabled = true
	internal_camera.make_current()
	
	refresh_cameras()

func refresh_cameras() -> void:
	cameras = get_tree().get_nodes_in_group("live_camera")
	
	for child in buttons_container.get_children():
		child.queue_free()
	
	if cameras.size() > 0:
		for i in range(cameras.size()):
			var btn = Button.new()
			btn.text = " CAM " + str(i + 1) + " "
			btn.custom_minimum_size = Vector2(80, 40)
			btn.pressed.connect(func(): select_camera(i))
			buttons_container.add_child(btn)
		
		update_camera_view()
	else:
		camera_label.text = "NO CAMERAS FOUND"
		print("Camera System: No nodes found in group 'live_camera'")

func select_camera(index: int) -> void:
	current_camera_index = index
	update_camera_view()

func update_camera_view() -> void:
	if current_camera_index < 0 or current_camera_index >= cameras.size():
		return
		
	var target_cam = cameras[current_camera_index]
	if is_instance_valid(target_cam):
		# Important: folosim global_position pentru a teleporta camera în locul corect din lume
		internal_camera.global_position = target_cam.global_position
		
		if target_cam is Camera2D:
			internal_camera.zoom = target_cam.zoom
			
		camera_label.text = "LIVE: " + target_cam.name.to_upper()
		trigger_glitch()

func trigger_glitch() -> void:
	var tween = create_tween()
	color_rect.modulate.a = 0.4
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.1)

func _input(event: InputEvent) -> void:
	if cameras.size() == 0 or not is_visible_in_tree():
		return
	
	if event.is_action_pressed("ui_right"):
		select_camera((current_camera_index + 1) % cameras.size())
	elif event.is_action_pressed("ui_left"):
		select_camera((current_camera_index - 1 + cameras.size()) % cameras.size())

# Funcția apelată de browser
func refresh_cameras_from_browser() -> void:
	refresh_cameras()
	# Re-verificăm lumea la fiecare navigare
	_setup_everything()
