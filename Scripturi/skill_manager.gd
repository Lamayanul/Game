extends Node2D

@export var skill_root: NodePath  # ex: path spre `SkillMap` (unde sunt nodurile)
var lines := []

func _ready():
	update_connections()
	set_process(true)

func _process(_delta):
	update_connections()

func update_connections():
	# Șterge liniile vechi
	for line in lines:
		if is_instance_valid(line):
			line.queue_free()
	lines.clear()

	var container = get_node(skill_root)
	if container == null:
		return

	for skill in container.get_children():
		if skill is SkillNode:
			var points = skill.get_connection_points()
			if points.has("from") and points.has("to"):
				var line = Line2D.new()
				line.default_color = Color.YELLOW
				line.width = 2.0
				line.add_point(points["from"] - global_position)
				line.add_point(points["to"] - global_position)
				add_child(line)
				lines.append(line)
