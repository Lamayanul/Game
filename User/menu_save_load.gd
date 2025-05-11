extends CanvasLayer
 
@onready var save_list = %Save_list
@onready var manual_save_slot : PackedScene = preload("res://User/save_slot.tscn")
@onready var option = $Option
@onready var save_and_load = $SaveLoadPanel
@onready var file_dialog = $FileDialog
@onready var textureRect = $Option/VBoxContainer/TextureRect  # sau TextureRect, etc. 
@onready var add: Button = $Option/Add
@onready var rich_text_label: RichTextLabel = $Option/VBoxContainer/RichTextLabel
@onready var info: Panel = $info
@onready var grid_container: GridContainer = $info/VBoxContainer/HBoxContainer/GridContainer
#@onready var data: String = ""
#@onready var ora:String = ""
@onready var Control_imag = Persistence.get_node("CanvasLayer/Control")



enum MODE {SAVE, LOAD}
var mode : MODE:
	set(value):
		mode = value
		if mode == MODE.SAVE:
			%CreateNew.show()
			%Load.hide()
		elif  mode == MODE.LOAD:
			%CreateNew.hide()
		save_and_load.show()
		if save_and_load not in ui_stack:
			ui_stack.append(save_and_load)
 
var selected_slot = null
var ui_stack = []
var path = "user://Saves/"
 
func _ready():
	save_and_load.hide()
	option.hide()
	info.hide()
	rich_text_label.text = "[center]"+rich_text_label.text
	dir_contents()
	




func set_centered_text(text: String) -> void:
	rich_text_label.text = "[center]" + text + "[/center]"
 
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if ui_stack.size() == 0:
			ui_stack.append(option)
			option.show()
			info.show()

		elif ui_stack.size() > 0:
			var removed = ui_stack.pop_back()
			if is_instance_valid(removed):
				removed.hide()
				if removed == option:
					info.hide()  # ascundem și info când option dispare

			if ui_stack.size() > 0:
				var next = ui_stack[-1]
				if is_instance_valid(next):
					next.show()
					if next == option:
						info.show()  # dacă revine option, revine și info


 
 
func _on_save_pressed():
	mode = MODE.SAVE
	option.hide()
	info.hide()

 
 
func _on_load_pressed():
	mode = MODE.LOAD
	option.hide()
	info.hide()
	dir_contents()



 
 
func _on_create_new_pressed():
	var manual_save = manual_save_slot.instantiate()
	save_list.add_child(manual_save)
	
	var data_dir = manual_save.get_node("data")
	var ora_dir = manual_save.get_node("ora")
	data_dir.text=Time.get_date_string_from_system()
	ora_dir.text=Time.get_time_string_from_system()
	
	manual_save.connect("pressed", selected)
 
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
 
	var file_name = "SaveData" + str(save_list.get_child_count()) + ".tres"
	if file_name in DirAccess.get_files_at("user://Saves/"):
		file_name = "SaveData" + str(save_list.get_child_count()) + "_1" + ".tres"
		
	
	
	Persistence.save()
 
	var save_data : SaveData = Persistence.get_save_data()
	save_data.title = "SaveData" + str(save_list.get_child_count())
	manual_save.save_data = save_data
	

	
	ResourceSaver.save(save_data , path + file_name)
 
 
func selected(panel):
	selected_slot = panel
	match mode:
		MODE.SAVE:
			%SaveSelected.show()
			if %SaveSelected not in ui_stack:
				ui_stack.append(%SaveSelected)
		MODE.LOAD:
			%Load.show()
 
 
func _on_delete_pressed():
	if is_instance_valid(selected_slot):
		DirAccess.remove_absolute(selected_slot.save_data.resource_path)
		selected_slot.queue_free()
		ui_stack.pop_back().hide()
 
 
func _on_save_slot_pressed(_panel):
	if mode == MODE.LOAD:
		%Load.show()
 
func dir_contents():
	
	for node in save_list.get_children():
		node.queue_free()

	var list_of_files = DirAccess.get_files_at("user://Saves/")
	for file_name in list_of_files:
		if file_name.get_extension() != "tres":
			continue  # Skip .png or other non-save files

		var save_resource = ResourceLoader.load(path + file_name, "", ResourceLoader.CacheMode.CACHE_MODE_IGNORE)
		if save_resource == null:
			print("Eroare la încărcarea:", file_name)
			continue

		var save = manual_save_slot.instantiate()
		save.save_data = save_resource
		save.pressed.connect(selected)
		
		
		var data_dir = save.get_node("data")
		var ora_dir = save.get_node("ora")
		data_dir.text=save_resource.data
		ora_dir.text=save_resource.ora
		print("menu data :",data_dir.text)
		
		
		save_list.add_child(save)
		

 

func _on_load_resource_pressed():
	Persistence.show_loading()
	await Persistence.load_data(selected_slot.save_data)
	
	await get_tree().process_frame
	await get_tree().create_timer(2).timeout
	Persistence.hide_loading()


	#clean_unused_images()
 
 
func _on_overwrite_pressed():
	
	if selected_slot:
		var data_dir = selected_slot.get_node("data")
		var ora_dir = selected_slot.get_node("ora")
		data_dir.text=Time.get_date_string_from_system()
		ora_dir.text=Time.get_time_string_from_system()

	
	Persistence.save()
 
	var save_data : SaveData = Persistence.get_save_data()
	save_data.title = selected_slot.save_data.title
 
	ResourceSaver.save(save_data, selected_slot.save_data.resource_path)
	ui_stack.pop_back().hide()


func clean_unused_images():
	var used_image_paths := []
	var save_files := DirAccess.get_files_at("user://Saves/")
	
	for file in save_files:
		if file.ends_with(".tres"):
			var save_data = ResourceLoader.load("user://Saves/" + file)
			if save_data and save_data.textura_path != "":
				used_image_paths.append(save_data.textura_path)

	for file in save_files:
		if file.ends_with(".png"):
			var image_path = "user://Saves/" + file
			if image_path not in used_image_paths:
				var result = DirAccess.remove_absolute(image_path)
				if result == OK:
					print("Șters:", image_path)
				else:
					print("Eroare la ștergere:", image_path)






func _on_button_pressed() -> void:
	var downloads_path = ""

	match OS.get_name():
		"Windows":
			downloads_path = OS.get_environment("USERPROFILE") + "\\Downloads"
		"Linux", "FreeBSD":
			downloads_path = OS.get_environment("HOME") + "/Downloads"
		"macOS":
			downloads_path = OS.get_environment("HOME") + "/Downloads"

	file_dialog.current_dir = downloads_path
	file_dialog.popup_centered()


func _on_file_dialog_file_selected(path_image: String) -> void:
	var image = Image.new()
	var error = image.load(path_image)
	if error == OK:
		var texture = ImageTexture.create_from_image(image)
		textureRect.texture = texture
		Persistence.textura = texture
		Persistence.textura_path = ""  # NU folosim calea
		Persistence.image_bytes = image.save_png_to_buffer()
	else:
		print("❌ Eroare la încărcarea imaginii:", path_image)


func _on_skills_pressed() -> void:
	$SkillTree.visible = true
	$Option.visible=false
	$info.visible=false
	
	if $SkillTree not in ui_stack:
		ui_stack.append($SkillTree)
