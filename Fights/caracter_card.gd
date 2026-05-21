extends PanelContainer # Sau Control, depinde ce tip de nod este CaracterCard

# --- Referințe UI (Bazate pe structura din imaginea ta) ---
@export var texture_bg : TextureRect
@export var nume_label :RichTextLabel
@export var health_text :RichTextLabel
@export var health_bar :TextureProgressBar
@export var animated_sprite :AnimatedSprite2D
@export var animation_player :AnimationPlayer
@export var description_label: RichTextLabel

# --- Referințe Inventar ---
@export var inv_panel : PanelContainer
@export var slots_container :GridContainer


# --- Date Locale ---
var max_hp: int = 100
var current_hp: int = 100
var character_id = 1

func _ready():
	health_bar.max_value= max_hp
	health_bar.value = current_hp
