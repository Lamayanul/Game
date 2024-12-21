extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var player_in_area = false
var is_open = false  # Stare pentru a verifica dacă ușa este deschisă
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready():
	canvas_layer.hide()

func _on_area_2d_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_area_2d_body_exited(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		canvas_layer.hide()

func _process(_delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		if not is_open:  # Deschide ușa
			animation_player.play("open")
			is_open=true
			if is_open and player_in_area:
				canvas_layer.show()
		else:
			animation_player.play("close")
			is_open=false
			canvas_layer.hide()
	if player_in_area and is_open:
		canvas_layer.show()
