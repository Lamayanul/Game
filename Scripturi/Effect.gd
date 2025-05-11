extends Resource

class_name Effect

@export var name: String
@export var duration: float = 5.0
@export var stat_changes: Dictionary = {} # ex: { "speed": -20, "attack": +5 }
@export var periodic_damage: int = 0
@export var periodic_interval: float = 1.0
