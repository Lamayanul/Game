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
		"scene": preload("res://Scene/dock_tab.tscn"),
		"title": "Quest",
		"icon":  preload("res://assets/quest.png")
	},
	"33": {
		"scene": preload("res://Tabs/browser.tscn"),
		"title": "Browser",
		"icon":  preload("res://assets/browser.png")
	},
}

# Ținem o singură instanță per ID
var _open_tabs: Dictionary = {}   # id -> Control/PanelContainer

func _ready():
	ui_root = get_node(ui_root_path)
	Taskbar.add_window(null,"",preload("res://assets/windows.png"))

func open_tab_for_id(id: String, payload: Dictionary = {}) -> void:
	if not TAB_REGISTRY.has(id): return
	var cfg = TAB_REGISTRY[id]

	if _open_tabs.has(id) and is_instance_valid(_open_tabs[id]):
		var win: Control = _open_tabs[id]
		win.visible = true
		win.move_to_front()
		# re-adauga / re-afiseaza butonul
		var title = win.window_title if ("window_title" in win) else cfg["title"]
		var icon  = win.window_icon  if ("window_icon"  in win) else cfg.get("icon", null)
		Taskbar.add_window(win, title, icon)
		return

	# creare prima data
	var scene: PackedScene = cfg["scene"]
	var win: Control = scene.instantiate()
	if "window_title" in win: win.window_title = cfg["title"]
	if "window_icon" in win and cfg.has("icon"): win.window_icon = cfg["icon"]
	if win.has_method("setup_from_item"): win.setup_from_item(payload)
	ui_root.add_child(win)
	_open_tabs[id] = win

	var vp := ui_root.get_viewport().get_visible_rect().size
	win.position = (vp - win.size) * 0.5

	Taskbar.add_window(win, cfg["title"], cfg.get("icon", null))
		

	
