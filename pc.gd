extends Control

@export var target_path: NodePath = ^"SlotContainer"
@export var offset_y: float = -200.0
@export var duration: float = 0.75
@export var speed_px_s: float = 1000.0
var target: Control
var base_y: float
var tw: Tween

func _ready() -> void:
	target = get_node(target_path)
	await get_tree().process_frame   # așteaptă layout-ul
	base_y = target.position.y       # poziția finală inițială

func _on_btn_open_pressed() -> void:
	_slide_to(base_y + offset_y)     # urcă

func _on_btn_close_pressed() -> void:
	_slide_to(base_y)                # revine

func _slide_to(y: float) -> void:
	if tw and tw.is_running():
		tw.kill()
	var dist = abs(y - target.position.y)
	var secs = dist / max(1.0, speed_px_s)
	tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(target, "position:y", y, secs)
