extends Line2D

## Distanța la care firul începe să se miște
@export var detection_radius: float = 5.0
## Cât de tare este împins firul
@export var push_force: float = 10.0
## Viteza de revenire la forma originală (0.0 - 1.0)
@export var return_speed: float = 0.1

var original_points: PackedVector2Array
var current_offsets: Array[Vector2] = []

func _ready() -> void:
	# Salvăm punctele inițiale
	original_points = points.duplicate()
	# Inițializăm offset-urile cu zero
	for i in range(original_points.size()):
		current_offsets.append(Vector2.ZERO)

func _process(_delta: float) -> void:
	# Căutăm player-ul (asigură-te că player-ul tău e în grupul "player")
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Poziția player-ului în coordonatele locale ale Line2D
	var player_pos = to_local(player.global_position)

	for i in range(original_points.size()):
		var target_pos = original_points[i]
		var dist = player_pos.distance_to(target_pos)

		if dist < detection_radius:
			# Calculăm direcția de la player către punct pentru a-l împinge
			var dir = (target_pos - player_pos).normalized()
			# Intensitatea împingerii (mai mare dacă ești mai aproape)
			var intensity = (1.0 - (dist / detection_radius)) * push_force
			# Aplicăm offset-ul țintă
			var target_offset = dir * intensity
			# Interpolăm offset-ul actual către cel țintă pentru fluiditate
			current_offsets[i] = current_offsets[i].lerp(target_offset, 0.5)
		else:
			# Revenire lentă la zero dacă player-ul s-a îndepărtat
			current_offsets[i] = current_offsets[i].lerp(Vector2.ZERO, return_speed)

		# Actualizăm punctul în Line2D
		points[i] = original_points[i] + current_offsets[i]
