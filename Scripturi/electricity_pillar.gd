extends StaticBody2D

@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var is_enabled = false  # Starea curentă a generatorului

func _ready() -> void:
	animated_sprite_2d_2.play("null")
	animated_sprite_2d.play("null")

	
func _process(delta: float) -> void:
	pass

func enable(value=true):
	# Activează/dezactivează luminile
	$PointLight2D.enabled = value
	$PointLight2D2.enabled = value

	# Redă animația corespunzătoare
	if value:
		# Dacă generatorul se activează
		$AnimatedSprite2D.play("ongoing")
		$AnimatedSprite2D2.play("ongoing")
	else:
		# Dacă generatorul se dezactivează
		$AnimatedSprite2D.play("null")
		$AnimatedSprite2D2.play("null")
