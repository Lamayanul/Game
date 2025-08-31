extends Control

@export var target_path: NodePath = ^"SlotContainer"
@export var speed_px_s: float = 1000.0
@export var taskbar_height := 64
@export var bottom_padding := 0
@export var offset_y: float = -200.0     # deplasarea la OPEN, relativ la poziția inițială
const MARGIN := 00.0     #10.0            # doar pentru clamp (spațiu deasupra marginii)

@onready var slot_container: Slot = $SlotContainer
@onready var storage_tab = get_node_or_null("/root/world/CanvasLayer/Control/TaskBar/Tray/StorageTab")
@onready var ecran: Control = $CanvasLayer/TextureRect2
@onready var task_bar: Control = $TaskBar

var target: Control
var tw: Tween
var lock := false          # true = OPEN, false = CLOSE
var base_y: float = -50.0    # poziția inițială (locală) a target-ului

signal storage(data)

func _ready() -> void:
	target = get_node(target_path)
	await get_tree().process_frame   # așteaptă layout/mărimi
	base_y = target.position.y       # MEMOREAZĂ baza !

	get_viewport().size_changed.connect(_on_resized)
	if is_instance_valid(ecran):
		ecran.resized.connect(_on_resized)
		ecran.visibility_changed.connect(_on_resized)

	_update_taskbar_to_screen()
	_apply_state_position()          # poziționează corect în funcție de lock (inițial false)

# --- TASKBAR lipit de baza lui `ecran` ---
func _update_taskbar_to_screen() -> void:
	if !is_instance_valid(ecran) or !is_instance_valid(task_bar):
		return
	var er: Rect2 = ecran.get_global_rect()
	task_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	task_bar.size_flags_horizontal = 0
	task_bar.size_flags_vertical   = 0
	task_bar.size = Vector2(er.size.x, taskbar_height)
	var y := er.position.y + er.size.y - taskbar_height - bottom_padding
	task_bar.global_position = Vector2(er.position.x, y)

# --- ZONA SAFE (global) ---
func _safe_rect_global() -> Rect2:
	var er := ecran.get_global_rect()
	er.size.y = max(0.0, er.size.y - taskbar_height - bottom_padding)
	return er

# conv. Y global -> Y local în parent-ul lui p
func _global_y_to_local(p: Control, y_global: float) -> float:
	var parent := p.get_parent() as CanvasItem
	var inv: Transform2D = parent.get_global_transform().affine_inverse()
	var global_pt := Vector2(p.global_position.x, y_global)  # păstrează coloana curentă pe X
	return (inv * global_pt).y

# clamp pe Y local în zona safe
func _clamp_local_y(p: Control, y_local: float) -> float:
	var sr := _safe_rect_global()
	var safe_top_local: float = _global_y_to_local(p, sr.position.y)
	var safe_bot_local: float = _global_y_to_local(p, sr.position.y + sr.size.y)
	var y_min: float = safe_top_local + MARGIN
	var y_max: float = safe_bot_local - p.size.y - MARGIN
	return clamp(y_local, y_min, y_max)

# țintă OPEN/CLOSE în local (relativ la baza inițială)
func _open_y_local(p: Control) -> float:
	return _clamp_local_y(p, base_y + offset_y)

func _close_y_local(p: Control) -> float:
	return base_y



func _apply_state_position() -> void:
	if lock:
		target.position.y = _open_y_local(target)  # clamp
	else:
		target.position.y = base_y                 # fără clamp

# tween pe Y local (parametru pt. clamp)
func _slide_to_y_local(p: Control, y_local: float, do_clamp: bool) -> void:
	if tw and tw.is_running():
		tw.kill()
	var y := _clamp_local_y(p, y_local)  if do_clamp else y_local
	var dist: float = abs(y - p.position.y)
	var secs: float = dist / max(1.0, speed_px_s)
	tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(p, "position:y", y, secs)

# --- Butoane ---
func _on_btn_open_pressed() -> void:
	lock = true
	_slide_to_y_local(target, base_y + offset_y, true)  # clamp la open

func _on_btn_close_pressed() -> void:
	lock = false
	_slide_to_y_local(target, base_y, false)            # FĂRĂ clamp la close

# --- Resize ---
func _on_resized() -> void:
	_update_taskbar_to_screen()
	if lock:
		target.position.y = _open_y_local(target)  # rămâne în zona safe
	else:
		target.position.y = base_y     
		
		
# --- Scan (neatins) ---
func _on_scan_pressed() -> void:
	if not lock: return
	var src_data = slot_container.get_item()
	storage.emit(src_data)
	slot_container.clear_item()
	if src_data.is_empty(): return
