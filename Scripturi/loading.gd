extends Control

@onready var progress_bar = $ProgressBar
@onready var status_label = $Label

var image_paths = [
	"res://User/Loading/batran.png",
	 "res://User/Loading/baiat.png",
	 "res://User/Loading/femeie.png",
	 "res://User/Loading/brothers.png",
	"res://User/Loading/vanzator.png",
	"res://User/Loading/business.png",
]

@onready var texture_rect: TextureRect = $TextureRect

var last_path: String = ""

func pick_random_image():
	if image_paths.is_empty():
		return

	var path = image_paths.pick_random()

	# Evită să fie aceeași imagine ca înainte
	while path == last_path and image_paths.size() > 1:
		path = image_paths.pick_random()

	last_path = path

	# IMPORTANT: goliți imaginea întâi
	texture_rect.texture = null
	await get_tree().process_frame  # forțează refresh UI

	var texture = load(path)
	if texture:
		texture_rect.texture = texture
	else:
		print("⚠️ Imaginea nu s-a putut încărca:", path)



func _ready():
	randomize()


#func show_loading():
	#visible = true
	#progress_bar.value = 0
	#status_label.text = "Se încarcă..."

#func update_progress(current: int, total: int, label_text: String = ""):
	#var percent = float(current) / total * 100.0
	#progress_bar.value = percent
	#status_label.text = label_text + " (" + str(round(percent)) + "%)"


#func hide_loading():
	#visible = false
