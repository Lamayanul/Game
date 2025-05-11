extends TextureButton
class_name SkillNode

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D

var level : int = 0:
	set(value):
		level = value
		label.text = str(level) + "/3"

var initial_position_set : bool = false  # Flag pentru a adăuga punctele doar o singură dată
var last_position : Vector2  # Păstrează poziția anterioară

# Funcția _ready va adăuga linia inițial
func _ready() -> void:
	await get_tree().process_frame
	if get_parent() is SkillNode:
		# Adaugă punctele pentru prima dată
		line_2d.add_point(global_position + size / 2)
		line_2d.add_point(get_parent().global_position + size / 2)
		initial_position_set = true
		last_position = global_position  # Salvează poziția inițială

# Funcția care se apelează când butonul este apăsat
func _on_pressed() -> void:
	level = min(level + 1, 3)
	panel.show_behind_parent = true

	# Schimbă culoarea liniei la apăsare
	line_2d.default_color = Color(1.0, 0.947, 0.136)
	
	# Activează skill-urile pe baza nivelului
	var skills = get_children()
	for skill in skills:
		if skill is SkillNode and level == 1:
			skill.disabled = false

# Funcția _process va actualiza pozițiile liniei pe baza mișcării skill-urilor
func _process(_delta):
	if get_parent() is SkillNode and initial_position_set:
		# Verifică dacă poziția s-a schimbat
		if global_position != last_position:
			# Actualizează punctele liniei doar dacă s-a mișcat
			line_2d.set_point_position(0, global_position + size / 2)  # Primul punct
			line_2d.set_point_position(1, get_parent().global_position + size / 2)  # Al doilea punct
			last_position = global_position  # Actualizează poziția anterioară
