extends TextureProgressBar
@onready var poster = $"../Poster"

func _ready():
	poster.visible=false;

func _on_mouse_entered():
	poster.visible=true;


func _on_mouse_exited():
	poster.visible=false;
