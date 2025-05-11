extends GridContainer

@onready var player_reference = get_tree().get_first_node_in_group("player")
var stat_labels = {}  # Dicționar: stat_name -> valoare_label
var previous_values = {}

func _ready():
	setup_stats()

func setup_stats():
	if player_reference == null:
		return

	# Încarcă scena stats.tscn o singură dată
	var stats_scene = load("res://Scene/stats.tscn")

	# Creezi câte un "stats" pentru fiecare atribut
	add_stat_entry(stats_scene, "Health", "health")
	add_stat_entry(stats_scene, "Speed", "speed")
	# add_stat_entry(stats_scene, "Attack", "attack")
	# add_stat_entry(stats_scene, "Defense", "defense")
	# add_stat_entry(stats_scene, "Mana", "mana")

func add_stat_entry(stats_scene, label_text: String, stat_key: String):
	var container = stats_scene.instantiate()

	var icon = container.get_node("CenterContainer/HBoxContainer/Icon") as TextureRect
	var denumire_label = container.get_node("CenterContainer/HBoxContainer/Denumire") as RichTextLabel
	var valoare_label = container.get_node("CenterContainer/HBoxContainer/Valoare") as RichTextLabel
	
	# Setează icon-ul dinamic
	var image_path = get_image_for_stat(stat_key)
	var texture = load(image_path)
	icon.texture = texture

	# Text
	denumire_label.text = "[center]" + label_text + "[/center]"
	valoare_label.text = ""
	stat_labels[stat_key] = valoare_label

	add_child(container)


func _process(_delta):
	update_stats()

func update_stats():
	if player_reference == null:
		return

	check_and_update_stat("health", player_reference.health)
	check_and_update_stat("speed", player_reference.speed)
	#check_and_update_stat("attack", player_reference.attack)
	#check_and_update_stat("mana", player_reference.mana)


func get_image_for_stat(stat_key: String) -> String:
	match stat_key:
		"health":
			return "res://Icons/heart_icon.png"
		"speed":
			return "res://Icons/speed_icon.png"
		#"attack":
			#return "res://assets/icons/attack.png"
		#"defense":
			#return "res://assets/icons/defense.png"
		_:
			return "res://Icons/default.png"

func check_and_update_stat(stat_key: String, current_value):
	if previous_values.has(stat_key) and previous_values[stat_key] == current_value:
		return  # Nu s-a schimbat, nu mai face nimic

	previous_values[stat_key] = current_value

	if stat_labels.has(stat_key):
		stat_labels[stat_key].text = "[center]" + str(current_value) + "[/center]"
