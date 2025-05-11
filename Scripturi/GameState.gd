extends Node

var current_ai_npc: Node = null
var global_ai_chat: NobodyWhoChat = null

func _ready():
	
	global_ai_chat = NobodyWhoChat.new()
	add_child(global_ai_chat)

	global_ai_chat.model_node = NobodyWhoModel.new()
	global_ai_chat.model_node.model_path = "res://gemma-2-2b-it-Q4_K_M.gguf"

	global_ai_chat.start_worker()

	global_ai_chat.response_updated.connect(_on_response_updated)
	global_ai_chat.response_finished.connect(_on_response_finished)
	
	# Legi semnalele

func _on_response_updated(new_token: String) -> void:
	if current_ai_npc != null:
		var richtext = current_ai_npc.get_node("CanvasLayer/Control2/PanelContainer/VBoxContainer/HBoxContainer/RichTextLabel")
		richtext.text += new_token

func _on_response_finished(_response: String) -> void:
	if current_ai_npc != null:
		var text_edit = current_ai_npc.get_node("CanvasLayer/Control2/PanelContainer/VBoxContainer/TextEdit")
		text_edit.editable = true
		text_edit.text = ""
