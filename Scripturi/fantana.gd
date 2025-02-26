extends StaticBody2D

var water=false
@onready var inventory = get_node("/root/world/CanvasLayer/Inv")
var selected_slot: Slot = null 
@onready var player = get_node("/root/world/player")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer.visible=false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if inventory.selected_slot:
		if inventory.selected_slot.get_id()=="22":
			$CanvasLayer.visible=true
		else:
			$CanvasLayer.visible=false



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if inventory.selected_slot.get_id()=="22":
			$CanvasLayer.visible=true
			water=true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		water=false
	
func _input(_event):
	if Input.is_action_just_pressed("watering"):
		if water==true:
			$CanvasLayer/ProgressBar.value=100
