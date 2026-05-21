extends Node2D

# Intensitatea mișcării pentru cutie (nodurile din grupul "fig")
@export var box_intensity: float = 10.0
# Intensitatea mișcării pentru figurine (Sprite2D sau alte noduri)
@export var figurine_intensity: float = 20.0

# Viteza de interpolare (netezire)
@export var lerp_speed: float = 5.0
# Unghiul maxim de înclinare (skew)
@export var max_skew: float = 0.04

# Salvăm pozițiile inițiale ale copiilor
var initial_positions: Dictionary = {}

func _ready() -> void:
	# Memorăm unde se află fiecare element la început
	for child in get_children():
		initial_positions[child] = child.position

func _process(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	if viewport_size.x == 0 or viewport_size.y == 0: return
	
	var mouse_pos = get_global_mouse_position()
	# Distanța față de centrul ecranului
	var center = viewport_size / 2
	var offset = (mouse_pos - center) / (viewport_size / 2)
	
	# Clamp offset-ul pentru a preveni mișcări exagerate
	offset.x = clamp(offset.x, -1.0, 1.0)
	offset.y = clamp(offset.y, -1.0, 1.0)
	
	# 1. Înclinare subtilă pentru perspectiva 3D
	skew = lerp(skew, offset.x * max_skew, lerp_speed * delta)
	
	# 2. Mișcăm fiecare copil cu un factor de adâncime diferit
	for child in get_children():
		if not initial_positions.has(child): continue
		
		var current_intensity = figurine_intensity
		var depth_factor = 1.0
		
		# Verificăm dacă nodul aparține cutiei (grupul "fig")
		if child.is_in_group("fig"):
			current_intensity = box_intensity
			# Pentru cutie, putem folosi indexul în ierarhie pentru un micro-parallax intern
			depth_factor = 1.0 + (float(child.get_index()) / get_child_count()) * 0.5
		else:
			# Figurina (în afara grupului fig) se mișcă mult mai mult
			current_intensity = figurine_intensity
			depth_factor = 2.0
			
			# Dacă este Sprite2D (figurina propriu-zisă), simulăm și o mică apropiere
			if child is Sprite2D:
				var target_scale = Vector2(9.875, 9.875) * (1.0 + abs(offset.x + offset.y) * 0.05)
				child.scale = child.scale.lerp(target_scale, lerp_speed * delta)
		
		var original_pos = initial_positions[child]
		var target_pos = original_pos + (offset * current_intensity * depth_factor)
		
		child.position = child.position.lerp(target_pos, lerp_speed * delta)
