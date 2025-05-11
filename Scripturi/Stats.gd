extends Resource

class_name Stats

@export var health: int = 100
@export var max_health: int = 100
@export var mana: int = 50
@export var max_mana: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var speed: float = 100.0

func apply_changes(changes: Dictionary):
	for key in changes.keys():
		if self.get_script().has_property(key):
			self.set(key, self.get(key) + changes[key])
