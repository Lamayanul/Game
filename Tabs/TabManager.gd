# TabManager.gd (pune-l ca Autoload dacă vrei să-l chemi de oriunde)
extends Node

# Unde montăm ferestrele (setat din scenă sau în _ready)
@export var ui_root_path: NodePath = ^"/root/world/CanvasLayer/Control"

var ui_root: Node

# Mapare ID item -> scene, titlu, icon, (opțional) setup method
const TAB_REGISTRY := {
	"30": {
		"scene": preload("res://Scene/dock_tab.tscn"),
		"title": "Folder",
		"icon":  preload("res://assets/folder.png")
	},
	"31": {
		"scene": preload("res://Tabs/storage_tab.tscn"),
		"title": "Storage",
		"icon":  preload("res://assets/storage.png")
	},
	"32": {
		"scene": preload("res://Tabs/Quests/quest_tab.tscn"),
		"title": "Quest",
		"icon":  preload("res://assets/quest.png")
	},
	"33": {
		"scene": preload("res://Tabs/browser.tscn"),
		"title": "Browser",
		"icon":  preload("res://assets/browser.png")
	},
	"46":{
		"scene": preload("res://Tabs/terminal.tscn"),
		"title": "Terminal",
		"icon":  preload("res://assets/terminal.png")
	},
	"47":{
		"scene": preload("res://Tabs/house.tscn"),
		"title": "House",
		"icon":  preload("res://assets/house.png")
	}
}

# Ținem o singură instanță per ID
var _open_tabs: Dictionary = {}   # id -> Control/PanelContainer
var _window_menu: PanelContainer

func _ready():
	ui_root = get_node(ui_root_path)
	_setup_window_menu()
	Taskbar.add_window(null, "", preload("res://assets/windows.png"), Callable(self, "_toggle_window_menu"))

func _setup_window_menu():
	_window_menu = PanelContainer.new()
	_window_menu.visible = false
	_window_menu.z_index = 5
	
	var vbox = VBoxContainer.new()
	_window_menu.add_child(vbox)
	
	for id in TAB_REGISTRY:
		var cfg = TAB_REGISTRY[id]
		var btn = Button.new()
		btn.text = cfg["title"]
		if cfg.has("icon"):
			btn.icon = cfg["icon"]
			btn.expand_icon = true
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(func():
			open_tab_for_id(id)
			_window_menu.visible = false
		)
		vbox.add_child(btn)
	
	ui_root.add_child(_window_menu)
	# Poziționăm meniul deasupra taskbar-ului
	_window_menu.anchor_top = 1.0
	_window_menu.anchor_bottom = 1.0

	var menu_height = vbox.get_child_count() * 42 + 10 # 42px per buton + margini
	var taskbar_height = 150 # Spațiul rezervat pentru taskbar

	_window_menu.offset_left = 60
	_window_menu.offset_right = 40 # Lățime fixă pentru meniu
	_window_menu.offset_bottom = -taskbar_height
	_window_menu.offset_top = -taskbar_height - menu_height

func _toggle_window_menu():
	if _window_menu:
		_window_menu.visible = !_window_menu.visible
		if _window_menu.visible:
			_window_menu.move_to_front()

func pre_instantiate_tab(id: String) -> Control:
	if not TAB_REGISTRY.has(id): return null
	if _open_tabs.has(id) and is_instance_valid(_open_tabs[id]):
		return _open_tabs[id]

	var cfg = TAB_REGISTRY[id]
	var scene: PackedScene = cfg["scene"]
	var win: Control = scene.instantiate()
	
	if "window_title" in win: win.window_title = cfg["title"]
	if "window_icon" in win and cfg.has("icon"): win.window_icon = cfg["icon"]
	
	# Încercăm să setăm titlul vizual dacă există un nod Title (Label)
	var title_label = win.find_child("Title", true, false)
	if title_label and "text" in title_label:
		title_label.text = cfg["title"]

	ui_root.add_child(win)
	_open_tabs[id] = win
	
	# Forțăm invizibilitatea totală la început
	win.visible = false
	win.modulate.a = 0.0 # Extra siguranță: îl facem complet transparent
	
	# Centrare
	var vp := ui_root.get_viewport().get_visible_rect().size
	win.position = (vp - win.size) * 0.5
	
	Taskbar.add_window(win, cfg["title"], cfg.get("icon", null))
	
	# Resetăm transparența după un frame (pentru când va fi făcut vizibil ulterior)
	await get_tree().process_frame
	win.modulate.a = 1.0
	
	return win

func open_tab_for_id(id: String, payload: Dictionary = {}) -> void:
	if not TAB_REGISTRY.has(id): return
	var cfg = TAB_REGISTRY[id]

	var win: Control
	if _open_tabs.has(id) and is_instance_valid(_open_tabs[id]):
		win = _open_tabs[id]
		win.visible = true
		win.move_to_front()
	else:
		# creare prima data
		var scene: PackedScene = cfg["scene"]
		win = scene.instantiate()
		ui_root.add_child(win)
		_open_tabs[id] = win
		
		var vp := ui_root.get_viewport().get_visible_rect().size
		win.position = (vp - win.size) * 0.5

	# Aplicăm titlul și iconița
	if "window_title" in win: win.window_title = cfg["title"]
	if "window_icon" in win and cfg.has("icon"): win.window_icon = cfg["icon"]
	
	# Încercăm să setăm titlul vizual dacă există un nod Title (Label)
	var title_label = win.find_child("Title", true, false)
	if title_label and "text" in title_label:
		title_label.text = cfg["title"]

	if win.has_method("setup_from_item"): 
		win.setup_from_item(payload)

	Taskbar.add_window(win, cfg["title"], cfg.get("icon", null))

		

	
