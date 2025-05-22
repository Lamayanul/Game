extends Control

@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var rich_text_label_2: RichTextLabel = $VBoxContainer/RichTextLabel2

@onready var parent_image = get_parent().get_parent().get_node("CanvasLayer/Control2/PanelContainer/VBoxContainer/HBoxContainer/TextureRect")
func _ready():
	# parent_image.texture e deja încărcată în parent
	texture_rect.texture = parent_image.texture 
