extends Line2D

@export var MAX_LENGTH: int = 25
@export var sub_viewport: SubViewport 
@export var parent: Node2D

@export var distance_at_largest_width: float = 24.0
@export var smallest_tip_width: float = 0.4
@export var largest_tip_width: float = 1.0

var length: float = 0.0
var queue: Array[Vector2] = []
var offset: Vector2i

func _ready() -> void:
	offset = Vector2i(sub_viewport.size.x / 2, sub_viewport.size.y / 2)

func _process(_delta: float) -> void:
	length = 0.0

	var pos: Vector2 = parent.global_position + Vector2(offset)
	queue.append(pos)
	if queue.size() > MAX_LENGTH and queue.size() > 2:
		queue.pop_front()

	clear_points()

	for i in range(queue.size() - 1):
		length += queue[i].distance_to(queue[i + 1])
		add_point(parent.to_local(queue[i]))
	add_point(parent.to_local(queue[queue.size() - 1]))

	var width_value: float = lerpf(
		smallest_tip_width,
		largest_tip_width,
		inverse_lerp(0, distance_at_largest_width, length)
	)
	width_curve.set_point_value(0, width_value)

func reset_line() -> void:
	clear_points()
	queue.clear()
