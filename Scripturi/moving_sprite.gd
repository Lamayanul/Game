extends Sprite2D

## Script pentru mișcarea elementelor de fundal (Sprite2D).
## Poți activa/dezactiva diferite tipuri de mișcare din Inspector.

@export_group("Floating (Oscilație)")
@export var float_enabled: bool = true
@export var float_linear: bool = false                 # Dacă e TRUE, se mișcă în linie dreaptă (diagonala)
@export var float_amplitude: Vector2 = Vector2(15, 15) # Câți pixeli se mișcă stânga-dreapta / sus-jos
@export var float_speed: float = 1.0                   # Viteza oscilației

@export_group("Rotation (Rotație)")
@export var rotate_enabled: bool = true
@export var rotation_speed: float = 0.2                # Viteza de rotație (radiani/s)

@export_group("Pulsing (Scalare)")
@export var pulse_enabled: bool = false
@export var pulse_amplitude: float = 0.1               # Cât de mult crește/scade (0.1 = 10%)
@export var pulse_speed: float = 2.0                   # Viteza pulsului

@export_group("Drifting (Deplasare Constantă)")
@export var drift_enabled: bool = false
@export var drift_velocity: Vector2 = Vector2(10, 5)   # Pixeli pe secundă

@export_group("Orbital (Orbitare)")
@export var orbit_enabled: bool = false
@export var orbit_center_offset: Vector2 = Vector2.ZERO # Centrul orbitei față de poziția de start
@export var orbit_radius: Vector2 = Vector2(100, 50)    # Raza elipsei (X, Y)
@export var orbit_speed: float = 1.0                  # Viteza orbitei (radiani/s)
@export var orbit_depth_effect: bool = false           # Schimbă Z-index și scalare pentru efect 3D

var _initial_pos: Vector2
var _initial_scale: Vector2
var _time: float = 0.0

func _ready() -> void:
	_initial_pos = position
	_initial_scale = scale
	_time = randf() * TAU 

func _process(delta: float) -> void:
	_time += delta
	
	# 1. Deplasare constantă (Drift)
	if drift_enabled:
		_initial_pos += drift_velocity * delta
	
	# 2. Baza poziției (Orbită sau Poziție inițială)
	var base_pos = _initial_pos
	var sin_a = sin(_time * orbit_speed)
	
	if orbit_enabled:
		var center = _initial_pos + orbit_center_offset
		base_pos.x = center.x + cos(_time * orbit_speed) * orbit_radius.x
		base_pos.y = center.y + sin_a * orbit_radius.y
		
		if orbit_depth_effect:
			var depth = (sin_a + 1.0) / 2.0
			scale = _initial_scale * lerp(0.8, 1.2, depth)
			z_index = -1 if sin_a < 0 else 0
	
	# 3. Oscilație (Floating) adăugată peste baza poziției
	var current_pos = base_pos
	if float_enabled:
		var wave = sin(_time * float_speed)
		if float_linear:
			# Mișcare în linie dreaptă pe diagonală (aceeași funcție sin pentru ambele axe)
			current_pos.x += wave * float_amplitude.x
			current_pos.y += wave * float_amplitude.y
		else:
			# Mișcare circulară/elipsă (sin pentru X, cos pentru Y)
			current_pos.x += wave * float_amplitude.x
			current_pos.y += cos(_time * float_speed * 0.9) * float_amplitude.y
	
	position = current_pos
	
	# 4. Rotație (Spin)
	if rotate_enabled:
		rotation += rotation_speed * delta
		
	# 5. Puls (Mărire/Micșorare) - se aplică dacă nu e deja setată de orbit_depth
	if pulse_enabled and not orbit_depth_effect:
		var s = 1.0 + sin(_time * pulse_speed) * pulse_amplitude
		scale = _initial_scale * s
