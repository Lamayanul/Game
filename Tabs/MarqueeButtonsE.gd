extends Control

@export var button_scene: PackedScene        # scena cu butonul tău
@export var button_count: int = 10            # câte instanțe pui pe bandă
@export var speed_px_s: float = 30        # viteză spre stânga (px/s)
@export var spacing: float = 15         # spațiu între butoane
@export var center_vertically: bool = true   # centrează pe Y în înălțimea benzii
@export var use_clip: bool = true            # taie desenul în afara benzii
@export var button_names: PackedStringArray = []   # numele dorite (opțional)
@export var cycle_names: bool = true               # dacă sunt mai puține nume decât butoane, se ciclizează

var _buttons: Array[Control] = []

func _ready() -> void:
	clip_contents = use_clip
	mouse_filter = Control.MOUSE_FILTER_PASS

	if button_scene == null:
		push_error("Setează 'button_scene' în Inspector!")
		return
	apply_names(["Visa", "Mastercard", "Amex"])
	# instanțiază și denumește
	for i in button_count:
		var b := button_scene.instantiate() as Control
		add_child(b)
		_buttons.append(b)
		_set_button_text_for(b, _name_for(i))

	await get_tree().process_frame
	_layout_horiz()
	resized.connect(_layout_horiz)

func _layout_horiz() -> void:
	if _buttons.is_empty():
		return

	var x := 0.0
	for b in _buttons:
		# dacă vrei ca fiecare să-și păstreze dimensiunea minimă
		var bw = max(b.size.x, b.get_combined_minimum_size().x)
		var bh = max(b.size.y, b.get_combined_minimum_size().y)

		if center_vertically:
			b.position.y = (size.y - bh) * 0.5
		else:
			b.position.y = 0.0

		b.position.x = x
		# dacă e buton nativ, îi poți fixa size-ul după nevoie:
		# b.custom_minimum_size = Vector2(bw, bh)
		x += bw + spacing

func _process(delta: float) -> void:
	if _buttons.is_empty():
		return

	# mută toate spre stânga
	for b in _buttons:
		b.position.x -= speed_px_s * delta

	# află cel mai din dreapta capăt
	var rightmost_edge := -INF
	for b in _buttons:
		rightmost_edge = max(rightmost_edge, b.position.x + b.size.x)

	# butoanele complet ieșite în stânga se repoziționează după dreapta
	for b in _buttons:
		if b.position.x + b.size.x < 0.0:
			b.position.x = rightmost_edge + spacing
			rightmost_edge = b.position.x + b.size.x

func _name_for(i: int) -> String:
	if button_names.is_empty():
		return "Buton %d" % (i + 1)
	if i < button_names.size():
		return button_names[i]
	return button_names[i % button_names.size()] if cycle_names else "Buton %d" % (i + 1)

func _set_button_text_for(node: Node, text: String) -> void:
	var target := _find_button_or_label(node)
	if target is Button:
		(target as Button).text = text
	elif target is Label:
		(target as Label).text = text

func _find_button_or_label(n: Node) -> Node:
	if n is Button or n is Label:
		return n
	for c in n.get_children():
		var found := _find_button_or_label(c)
		if found != null:
			return found
	return null

# Poți schimba numele la runtime:
func apply_names(names: PackedStringArray) -> void:
	button_names = names.duplicate()
	for i in _buttons.size():
		_set_button_text_for(_buttons[i], _name_for(i))
