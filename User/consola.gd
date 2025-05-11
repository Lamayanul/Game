extends Node2D

var texte = ""
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
var toggle = false
@onready var line_edit: LineEdit = %LineEdit
@onready var vbox: VBoxContainer = $CanvasLayer/Panel/VBoxContainer
@onready var panel: Panel = $CanvasLayer/Panel
@onready var players = get_tree().get_nodes_in_group("player")

func _ready() -> void:
	# Conectează semnalul Enter pentru LineEdit
	line_edit.connect("text_submitted", Callable(self, "cons_edit"))
	
func get_player():
	return get_tree().get_first_node_in_group("player")

# Funcția care se apelează când apesi Enter
func cons_edit(new_text: String):
	texte = new_text.strip_edges()
	var tokens = texte.split(" ")
	if tokens.size() == 1:
		var command = tokens[0]
		match command:
			"kill":
					if is_instance_valid(players[0]):
						players[0].suicide()
						
		var new_label = Label.new()
		new_label.text = command
		vbox.add_child(new_label)
		line_edit.text = ""


	if tokens.size() >= 3:
		var command = tokens[0]
		var arg1 = tokens[1]  # Ex: "12"
		var arg2 = tokens[2].to_int()  # Ex: 5
		var arg3: Vector2 = Vector2.ZERO

		# Dacă există un al treilea argument ca "(x,y)"
		if tokens.size() >= 4:
			var vec_str = tokens[3].replace("(", "").replace(")", "")  # elimină paranteze
			var parts = vec_str.split(",")
			if parts.size() == 2:
				arg3 = Vector2(parts[0].to_float(), parts[1].to_float())

		# Execută comanda (exemplu: drop_item)
		match command:
			"drop_item":
					inv.drop_item(arg1, arg2)
			"add_item":
					inv.add_item(arg1,arg2)
			"drop_item_everywhere":
					inv.drop_item_everywhere(arg1,arg2,arg3)
			"kill":
					players[0].suicide()
			
		
		# Afișează în consolă
		# Afișează comanda executată
		var new_label = Label.new()
		new_label.text = command + "(" + arg1 + ", " + str(arg2) + ", " + str(arg3) + ")"
		vbox.add_child(new_label)
		line_edit.text = ""
	else:
		print("⚠️ Comandă invalidă.")



# Comută vizibilitatea consolei
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("consola"):
		toggle = !toggle
		$CanvasLayer.visible = toggle
		if $CanvasLayer.visible:
			get_player().can_move = false
		else:
			get_player().can_move = true
