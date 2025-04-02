extends Node2D

var texte = ""
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
var toggle = false
@onready var line_edit: LineEdit = %LineEdit
@onready var vbox: VBoxContainer = $CanvasLayer/Panel/VBoxContainer

func _ready() -> void:
	# Conectează semnalul Enter pentru LineEdit
	line_edit.connect("text_submitted", Callable(self, "cons_edit"))

# Funcția care se apelează când apesi Enter
func cons_edit(new_text: String):
	texte = new_text.strip_edges()  # Ia textul fără spații la început și sfârșit
	var str = texte.split(" ")  # Împarte textul în cuvinte
	
	# Verifică dacă sunt cel puțin două cuvinte
	if str.size() >= 2:
		var first_word = str[0]
		var second_word = str[1]

		var new_label = Label.new()
		new_label.text = "drop_item( "+first_word + " " + second_word+ " )"
		vbox.add_child(new_label)  # Adaugă eticheta (fără să ștergem cele vechi)

		# Apelează funcția din inventar
		inv.drop_item(str[0], int(str[1]))

		# Golește inputul după apăsarea Enter
		line_edit.text = ""
	else:
		print("Textul nu conține două cuvinte!")

# Comută vizibilitatea consolei
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("consola"):
		toggle = !toggle
		$CanvasLayer.visible = toggle  # Comută vizibilitatea mai simplu
