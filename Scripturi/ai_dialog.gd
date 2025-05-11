extends Control

@onready var aiChat: NobodyWhoChat = $Sofia
@onready var aiText: RichTextLabel = $PanelContainer/VBoxContainer/HBoxContainer/RichTextLabel
@onready var textEdit: TextEdit = $PanelContainer/VBoxContainer/TextEdit
@onready var NBEmbedder: NobodyWhoEmbedding = $NobodyWhoEmbedding
var npc_owner : Node = null


func _ready():
	npc_owner = get_parent().get_parent()
	print("NPC owner setat: ", npc_owner.name)


func send_text_to_ai():
	if GameState.current_ai_npc != npc_owner:
		print("1, 2:",GameState.current_ai_npc,npc_owner )
		return

	if not is_instance_valid(aiChat):
		return

	if textEdit.text.strip_edges() == "":
		return
		
		
	textEdit.editable = false
	aiChat.say(textEdit.text)


func _input(event: InputEvent) -> void:
	if GameState.current_ai_npc == npc_owner:
		  # Dacă nu sunt NPC-ul activ, nu procesez nimic
	
		if event.is_action("ui_text_newline"):
			print("nume: ", GameState.current_ai_npc)
			send_text_to_ai()


func _on_nobody_who_chat_response_updated(new_token: String) -> void:
	aiText.text += new_token


func _on_nobody_who_chat_response_finished(_response: String) -> void:
	textEdit.editable=true
	textEdit.text=""
	
