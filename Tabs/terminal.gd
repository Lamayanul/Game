extends "res://Scripturi/dock_tab.gd"

# Căi noduri
@onready var output_label: RichTextLabel = $VBoxContainer/TerminalContent/MarginContainer/Output
@onready var input_edit: LineEdit = $VBoxContainer/TerminalContent/HBoxContainer/Input
@onready var rainbow_border_panel: Panel = $RainbowBorder # Nodul care are shaderul de bordură

const PROMPT = "[b][color=green]user@godot[/color]:[color=blue]~$[/color][/b] "

func _ready():
	super._ready()
	
	if input_edit:
		input_edit.text_submitted.connect(_on_command_submitted)
		input_edit.grab_focus()
	
	if output_label:
		output_label.clear()
		output_label.append_text("[color=gray]Linux godot 6.5.0-generic #1 SMP PREEMPT_DYNAMIC...[/color]\n")
		output_label.append_text("[color=gray]Welcome to the game terminal. Type 'help' for available commands.[/color]\n\n")

	# Conectăm semnalul de resize pentru a actualiza shader-ul
	self.resized.connect(_on_window_resized)
	_on_window_resized() # Apelăm o dată la început

func _on_window_resized():
	# Trimitem dimensiunea curentă către shader ca bordura să rămână fixă
	if rainbow_border_panel and rainbow_border_panel.material:
		rainbow_border_panel.material.set_shader_parameter("rect_size", self.size)

func _on_command_submitted(text: String):
	if text.strip_edges() == "": 
		output_label.append_text(PROMPT + "\n\n")
		input_edit.clear()
		return
	
	output_label.append_text(PROMPT + text + "\n")
	input_edit.clear()
	
	var args = text.strip_edges().to_lower().split(" ")
	var cmd = args[0]
	
	match cmd:
		"help":
			output_label.append_text("Available: help, clear, echo, ls, version\n")
		"clear":
			output_label.clear()
			input_edit.grab_focus()
			return 
		"ls":
			output_label.append_text("[color=blue]Desktop  Documents  Downloads  Music  Pictures[/color]\n")
		"echo":
			var echo_val = text.strip_edges().substr(5)
			output_label.append_text(echo_val + "\n")
		"version":
			output_label.append_text("Terminal v2.3.0 (Fixed Border Thickness)\n")
		_:
			output_label.append_text("bash: " + cmd + ": command not found\n")
			
	output_label.append_text("\n")
	output_label.scroll_to_line(output_label.get_line_count())
	input_edit.grab_focus()

func setup_from_item(payload: Dictionary) -> void:
	super.setup_from_item(payload)
	if payload.has("NUME"):
		window_title = payload["NUME"]
		if title: title.text = window_title
