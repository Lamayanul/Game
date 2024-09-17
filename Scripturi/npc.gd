extends CharacterBody2D


@export var dialogue:Dialogue

func interact():
	DialogueManager.dialogue=dialogue
	DialogueManager.show_dialogue()
