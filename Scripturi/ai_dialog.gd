extends Control

@onready var aiChat: NobodyWhoChat = $Sofia
@onready var aiText: RichTextLabel = $PanelContainer/VBoxContainer/HBoxContainer/RichTextLabel
@onready var textEdit: TextEdit = $PanelContainer/VBoxContainer/TextEdit
@onready var NBEmbedder: NobodyWhoEmbedding = $NobodyWhoEmbedding
@onready var peopleEmbeddings = await game_embeddings()


func match_sentence(sentence:String):
	var maxSimilarity=0
	var mostSimilar=null
	var inputEmbed=await NBEmbedder.embed(sentence)
	for people in peopleEmbeddings:
		for embedding in peopleEmbeddings[people]:
			var similarity=NBEmbedder.cosine_similarity(inputEmbed,embedding)
			if similarity>maxSimilarity:
				mostSimilar=people
				maxSimilarity=similarity
	var similarityThreshold=0.9
	if maxSimilarity>similarityThreshold:
		return mostSimilar
	return null

func game_embeddings():
	var sentences={
		"Sofia":[
			"Could i talk to Sofia?",
			"Is Sofia there?",
			"YO,WHERE'S SOFIA AT?",
		],
		"Miner":[
			"Where is the miner?",
			"Is the miner there?",
		],
		"Narrator":[
			"I would like to talk to the one who controls all",
			"I would like to speak with the narrator:",
		]}
	var embeddings={"Sofia":[],"Miner":[],"Narrator":[]}
	for person in sentences:
		for sentence in sentences[person]:
			embeddings[person].append(await NBEmbedder.embed(sentence))
		return embeddings
		
		
func send_text_to_ai():
	textEdit.editable=false
	aiChat.say(textEdit.text)
	var person = await match_sentence(textEdit.text)
	if person !=null:
		if(person=="Sofia"):
			aiChat=$Sofia
		elif(person=="Miner"):
			aiChat=$Miner
		else:
			aiChat=$Narrator
		textEdit.text="You are now talking to "+ person
	
func _input(event:InputEvent) -> void:
	if (event.is_action("ui_text_newline")):
		send_text_to_ai()

func _on_nobody_who_chat_response_updated(new_token: String) -> void:
	aiText.text += new_token


func _on_nobody_who_chat_response_finished(response: String) -> void:
	textEdit.editable=true
	textEdit.text=""
