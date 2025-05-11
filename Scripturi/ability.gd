extends Resource

class_name ability

@export var name: String
@export var cooldown: float
@export var damage: int
@export var description: String = ""
@export var applies_effect: Resource = null # Link către un Effect dacă există
