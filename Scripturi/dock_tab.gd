extends PanelContainer

@onready var title_bar: Control = $VBoxContainer/TitleBar
@onready var close_btn: Button = $VBoxContainer/TitleBar/TextureRect/CloseBtn
#@onready var content: Control = $VBoxContainer/Content
@export var min_size_px := Vector2(180, 120)
@export var max_size_px := Vector2(1600, 1000)
@export var edge_thickness := 8.0
@onready var title: Label = $VBoxContainer/TitleBar/TextureRect/Title
@onready var pc = self.get_parent()
@export var type_tab=""
@export var slot_tab: PackedScene = preload("res://User/slot_container.tscn")
@export var window_title := "Tab"
@export var window_icon: Texture2D
@onready var ecran = self.get_parent().get_node("CanvasLayer/TextureRect2")
@onready var taskbar = self.get_parent().get_node("TaskBar")
@onready var www = get_node_or_null("VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/www")
@onready var search = get_node_or_null("VBoxContainer/Search")
@onready var market = get_node_or_null("VBoxContainer/Market")
@onready var market_grid = get_node_or_null("VBoxContainer/Market/ScrollContainer/GridContainer")
@onready var content = get_node_or_null("/root/world/CanvasLayer/Control/StorageTab/VBoxContainer/Content_storage")
@onready var total_money_text = get_node_or_null("VBoxContainer/Market/RichTextLabel/Total_money")
@onready var inv_player = self.get_node_or_null("Control/TextureRect2/Inv_player")

@onready var storage_tab_grid = get_node_or_null("/root/world/CanvasLayer/Control/StorageTab/VBoxContainer/Content_storage")

var total_money_site = 200

@export var market_grid_all_path: NodePath
@export var market_grid_product_path: NodePath



@onready var market_grid_all := get_node_or_null(market_grid_all_path)
@onready var market_grid_product := get_node_or_null(market_grid_product_path)

var _history: Array[String] = []
var _history_index := -1
var PAGES := {}  # completat în _ready()

@export var pad_left  := 0.0
@export var pad_top   := 0.0
@export var pad_right := 0.0
@export var pad_bottom:= 0.0  # spațiul „rezervat” jos

var dragging := false
var resizing := false
var resize_dir := Vector2.ZERO
var drag_offset := Vector2.ZERO


var _market_loaded_once := false

var ROUTES := [
	# www.market sau www.market/ceva
	{
		"pattern": r"^www\.market(?:/.*)?$",
		"show": ["market"],
		"title": "Market",
		"handler": "_route_market_default"
	},
	# www.search sau orice necunoscut → fallback la Search
	{
		"pattern": r"^www\.search(?:/.*)?$",
		"show": ["search"],
		"title": "Search"
	},
	# www.storage
	{
		"pattern": r"^www\.storage(?:/.*)?$",
		"show": ["storage"],
		"title": "Storage",
		"handler": "_route_storage"       # (opțional) cod rulat când intri
	},
	# www.news/<category>
	{
		"pattern": r"^www\.news/([A-Za-z_]+)$",
		"show": ["news"],
		"title": "News",
		"handler": "_route_news_with_category"  # primește grupul capturat
	},
	{
	"pattern": r"^www\.market\.([A-Za-z_]+)$",
	"show": ["market"],
	"title": "Market",
	"handler": "_route_market_product"
	},
]
func _try_bind_market_slot(n: Node) -> void:
	# caută Slot-ul real din itemul grilei
	var slot := n.get_node_or_null("SlotContainer") as Slot
	if slot == null:
		slot = n.find_child("SlotContainer", true, false) as Slot
	if slot == null:
		return

	# semnalul care îți trimite date spre browser
	if not slot.is_connected("browser", Callable(self, "_on_market_slot_transmit")):
		slot.connect("browser", Callable(self, "_on_market_slot_transmit"))

	# semnalul pentru bani (AICI era problema)
	if not slot.is_connected("request_total_money_update", Callable(self, "_on_total_money_update")):
		slot.connect("request_total_money_update", Callable(self, "_on_total_money_update"))

			
func setup_from_item(payload: Dictionary) -> void:
	# personalizează UI în funcție de itemul care a deschis tabul
	if payload.has("NUME"):
		$VBoxContainer/TitleBar/TextureRect/Title.text = "%s" % [payload["NUME"]]
		
func minimize() -> void:
	# trimite în taskbar și ascunde
	#if Engine.has_singleton("Taskbar"):
		#var tb = Engine.get_singleton("Taskbar") # dacă e autoload
		#tb.add_window(self, self.find_child("Title").text, window_icon)
	#else:
		# sau daca e o referință globală gen `Taskbar`, folosește direct:
	Taskbar.mini_tab(self, self.find_child("Title").text, window_icon)
	visible = false
	

func _ready():
	print(content)
	pc.storage.connect(_on_scan_slot_transmit)
	close_btn.pressed.connect(_on_close_pressed)
	title_bar.gui_input.connect(_on_titlebar_gui_input)
	gui_input.connect(_on_gui_input)
	if is_instance_valid(market_grid):
		for ctrl in market_grid.get_children():
			if not is_instance_valid(ctrl):
				continue

			# dacă e copil direct: "Slot"; dacă nu, folosește find_child(..., true)
			var slot := ctrl.get_node_or_null("SlotContainer") as Slot
			if slot == null:
				slot = ctrl.find_child("SlotContainer", true, false) as Slot
			if slot == null:
				continue

			# dacă `browser` e un semnal declarat în Slot: `signal browser(data)`:
			if not slot.browser.is_connected(_on_market_slot_transmit):
				slot.browser.connect(_on_market_slot_transmit)
	if is_instance_valid(total_money_text):
		total_money_text.text = "APPLE: " + str(total_money_site)
		# alternativ, varianta clasică de conectare după numele semnalului:
		# if not slot.is_connected("browser", Callable(self, "_on_market_slot_transmit")):
		#     slot.connect("browser", Callable(self, "_on_market_slot_transmit"))
	#market_grid.child_entered_tree.connect(Callable(self, "_on_market_child_entered"))
	#pc.browser.connect(_on_market_slot_transmit)
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

	# important: re-încadrează la schimbarea rezoluției / monitorului
	get_viewport().size_changed.connect(_on_viewport_resized)
	# și chiar acum, după ce layout-ul inițial s-a stabilit
	call_deferred("_on_viewport_resized")
	print("ecran",ecran.name)
	if is_instance_valid(ecran) and ecran is Control:
		(ecran as Control).resized.connect(_on_viewport_resized)
	if is_instance_valid(taskbar) and taskbar is Control:
		(taskbar as Control).resized.connect(_on_viewport_resized)
		(taskbar as Control).visibility_changed.connect(_on_viewport_resized)
	call_deferred("_on_viewport_resized")
	if is_instance_valid(www):
		(www as TextEdit).gui_input.connect(_on_www_gui_input)
		PAGES = {
		"search":  search,
		"market":  market,
		#"storage": storage,
		#"news":    news,
	}
		_navigate_to("www.search", true)
	if type_tab == "browser":
		call_deferred("_wire_market_grid")  # după ce s-a stabilit scena
	for n in get_tree().get_nodes_in_group("emits_to_storage"):
		_try_bind_slot(n)

	# 2b) orice Slot nou adăugat în scenă (după _ready) va fi legat automat
	if not get_tree().is_connected("node_added", Callable(self, "_on_node_added")):
		get_tree().node_added.connect(Callable(self, "_on_node_added"))
	_wire_existing_slots()
	# prinde și sloturile create ulterior
	if is_instance_valid(content):
		if not content.is_connected("child_entered_tree", Callable(self, "_on_storage_child_entered")):
			content.child_entered_tree.connect(Callable(self, "_on_storage_child_entered"))

func _wire_existing_slots() -> void:
	if is_instance_valid(content):
		for c in content.get_children():
			_try_bind_slot(c)
		
func _on_node_added(n: Node) -> void:
	_try_bind_slot(n)

func _try_bind_slot(n: Node) -> void:
	if n is Slot and n.is_in_group("comslot"):
		var s := n as Slot
		if not s.is_connected("send_to_storage", Callable(self, "_on_send_to_storage")):
			s.send_to_storage.connect(Callable(self, "_on_send_to_storage"))
	if n is Slot:
		# fie conectezi direct gui_input...
		if not n.is_connected("gui_input", Callable(self, "_on_slot_gui_input")):
			n.gui_input.connect(Callable(self, "_on_slot_gui_input").bind(n))
		# ...sau, preferabil, un semnal custom emis de Slot (vezi mai jos)
		#if n.has_signal("right_click") and not n.is_connected("right_click", Callable(self, "_on_slot_right_click")):
			#n.connect("right_click", Callable(self, "_on_slot_right_click").bind(n))
			
func _on_slot_gui_input(event: InputEvent, slot: Slot) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_MIDDLE \
	and event.pressed:

		if type_tab == "storage" and is_instance_valid(slot) and slot.get_cantitate() > 0:
			var inv = _get_active_inv()
			if inv == null:
				return

			# NU mai crește manual plin; lasă inv.add_item să decidă.
			# (Dar păstrează verificarea ta de capacitate, dacă nu e deja în add_item)
			if inv.plin > 4:
				return

			var id := slot.get_id()
			var ok = inv.add_item(id, 1)
			if ok:
				slot.decrease_cantitate(1)






func _on_send_to_storage(data: Dictionary) -> void:
	if type_tab=="storage":
		var slot = slot_tab.instantiate()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size = slot.custom_minimum_size
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
		slot.scop="tab"
		$VBoxContainer/Content_storage.add_child(slot)   
		slot.get_node("TextureHolder/TextureRect2").texture=null 
		slot.slot_type="tray"
		slot.set_property(data)
		var payload := data.duplicate(true)
		payload["CANTITATE"] = 1
		
		var tex2 := slot.get_node_or_null("TextureHolder/TextureRect2")
		if tex2 is TextureRect:
			(tex2 as TextureRect).texture = null
		slot.slot_type = "tray"
		slot.set_property(payload)
		

		


func _wire_market_grid() -> void:
	if not is_instance_valid(market_grid):
		return
	# conectează sloturile deja prezente
	for c in market_grid.get_children():
		_try_bind_market_slot(c)
	# conectează automat sloturile create ulterior
	if not market_grid.is_connected("child_entered_tree", Callable(self, "_on_market_child_entered")):
		market_grid.child_entered_tree.connect(Callable(self, "_on_market_child_entered"))
	_wire_one_grid(market_grid_all)
	_wire_one_grid(market_grid_product)

func _on_market_child_entered(n: Node) -> void:
	_try_bind_market_slot(n)



func _on_www_submitted(text: String) -> void:
	_navigate_to(text, true)

func _on_close_pressed():
	visible = false
	Taskbar.remove_tab(self)
	#if type_tab=="fight":
		#inv_player._set_active(false)


func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		if type_tab!="notification" and type_tab!="fight":
			minimize()

		else:
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			move_to_front()
			_dragging = true
			# Offset între poziția tab-ului și mouse (în coordonate globale)
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		# Mută tab-ul după mouse, păstrând offset-ul
		global_position = get_global_mouse_position() - _drag_offset
		# (Opțional) limitează în interiorul ecranului:
		_clamp_inside_viewport()

func _on_total_money_update(delta: int) -> void:
	# Dacă delta < 0 (cumpărare), verifică mai întâi dacă am destui bani
	if delta < 0 and total_money_site + delta < 0:
		print("Nu ai destui bani pentru această achiziție!")
		return  # blochează tranzacția

	# Dacă e ok, actualizează suma
	total_money_site += delta

	# Actualizează UI
	if is_instance_valid(total_money_text):
		total_money_text.text = "APPLE: " + str(total_money_site)
		
func _viewport_bounds_rect() -> Rect2:
	# bounds = ecran (TextureRect2) minus padding și minus taskbar-ul de jos
	var r := Rect2(Vector2.ZERO, get_viewport_rect().size)
	if is_instance_valid(ecran) and ecran is Control:
		r = (ecran as Control).get_global_rect()

	# padding manual (opțional)
	r.position.x += pad_left
	r.position.y += pad_top
	r.size.x -= (pad_left + pad_right)

	# scade din înălțime ce ocupă taskbar-ul (doar dacă se suprapune pe X)
	if is_instance_valid(taskbar) and taskbar is Control:
		var tb := (taskbar as Control).get_global_rect()
		var x_overlap = max(0.0, min(r.position.x + r.size.x, tb.position.x + tb.size.x) - max(r.position.x, tb.position.x))
		if x_overlap > 0.0:
			var cut_bottom = clamp((r.position.y + r.size.y) - tb.position.y, 0.0, r.size.y)
			r.size.y -= cut_bottom  # „ridică” podeaua bounds-ului până la taskbar
	# după ce am scăzut taskbar-ul, mai aplicăm pad_bottom dacă vrei extra spațiu
	r.size.y -= pad_bottom
	return r

func _on_viewport_resized() -> void:
	# taie dimensiunea dacă depășește ecranul curent
	var b := _viewport_bounds_rect()
	var new_size := size
	new_size.x = clamp(new_size.x, min_size_px.x, min(max_size_px.x, b.size.x))
	new_size.y = clamp(new_size.y, min_size_px.y, min(max_size_px.y, b.size.y))
	size = new_size
	# apoi asigură poziția în interior
	_clamp_inside_viewport()
	#set_bottom_margin(0)
#
#func _on_bounds_changed() -> void:
	#var b := _viewport_bounds_rect()
	#var s := size
	#s.x = clamp(s.x, min_size_px.x, min(max_size_px.x, b.size.x))
	#s.y = clamp(s.y, min_size_px.y, min(max_size_px.y, b.size.y))
	#size = s
	#_clamp_inside_viewport()

func _input(event: InputEvent) -> void:
	# mouse back/forward (butonele laterale)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_XBUTTON1:
			_go_back()
		elif event.button_index == MOUSE_BUTTON_XBUTTON2:
			_go_forward()

func _clamp_inside_viewport() -> void:
	var bounds := _viewport_bounds_rect()
	var new_pos := global_position
	new_pos.x = clamp(new_pos.x, bounds.position.x, bounds.position.x + bounds.size.x - size.x)
	new_pos.y = clamp(new_pos.y, bounds.position.y, bounds.position.y + bounds.size.y - size.y-20)
	global_position = new_pos


func _on_gui_input(event: InputEvent) -> void:


	if dragging:
		var b := _viewport_bounds_rect()
		var p := get_global_mouse_position() - drag_offset
		p.x = clamp(p.x, b.position.x, b.position.x + b.size.x - size.x)
		p.y = clamp(p.y, b.position.y, b.position.y + b.size.y - size.y)
		global_position = p
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			move_to_front()  # Godot 4 replacement for raise()
			var local := get_local_mouse_position()  # for Control in Godot 4
			var edge := _edge_hit(local)
			if edge != Vector2.ZERO:
				resizing = true
				resize_dir = edge
			elif title_bar.get_rect().has_point(local):
				dragging = true
				drag_offset = local
		else:
			dragging = false
			resizing = false
			resize_dir = Vector2.ZERO

	elif event is InputEventMouseMotion:
		var local := get_local_mouse_position()
		
		# resize cursors
		#if not dragging and not resizing:
			#_update_cursor(local)

		# drag
		if dragging:
			
			var vp := get_viewport_rect().size
			position = (get_global_mouse_position() - drag_offset).clamp(Vector2.ZERO, vp - size)
			
		# resize
		if resizing:
			_do_resize(local)


						
#func set_bottom_margin(px: float) -> void:
	#pad_bottom = max(0.0, px)
	#_on_bounds_changed()  




func _edge_hit(local: Vector2) -> Vector2:
	var right  := local.x >= size.x - edge_thickness
	var bottom := local.y >= size.y - edge_thickness


	if right and bottom:
		return Vector2(1, 1)   # colț dreapta-jos
	elif right:
		return Vector2(1, 0)   # marginea dreaptă
	elif bottom:
		return Vector2(0, 1)   # marginea de jos
	return Vector2.ZERO        # toate celelalte margini sunt dezactivate



#func _update_cursor(local: Vector2) -> void:
	#var e := _edge_hit(local)
	#if e.x != 0 and e.y != 0:
		#Input.set_default_cursor_shape(
			#Input.CURSOR_FDIAGSIZE if e == Vector2(1,1) or e == Vector2(-1,-1)
			#else Input.CURSOR_BDIAGSIZE
		#)
	#elif e.x != 0:
		#Input.set_default_cursor_shape(Input.CURSOR_HSIZE)
	#elif e.y != 0:
		#Input.set_default_cursor_shape(Input.CURSOR_VSIZE)
	#else:
		#Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _do_resize(local: Vector2) -> void:
	var new_pos := position
	var new_size := size

	# -- calculează propunerea de resize --
	# left/right
	if resize_dir.x < 0:
		var dx = clamp(local.x, 0.0, new_size.x - min_size_px.x)
		new_pos.x += dx
		new_size.x -= dx
	elif resize_dir.x > 0:
		new_size.x = clamp(local.x, min_size_px.x, max_size_px.x)

	# top/bottom
	if resize_dir.y < 0:
		var dy = clamp(local.y, 0.0, new_size.y - min_size_px.y)
		new_pos.y += dy
		new_size.y -= dy
	elif resize_dir.y > 0:
		new_size.y = clamp(local.y, min_size_px.y, max_size_px.y)

	# -- aplică limitele viewportului (aceleași ca la drag) --
	var bounds := _viewport_bounds_rect()

	# Nu lăsa poziția să urce peste stânga/susul bounds
	new_pos.x = max(new_pos.x, bounds.position.x)
	new_pos.y = max(new_pos.y, bounds.position.y)

	# Nu lăsa dimensiunile să depășească bounds la dreapta/jos
	var max_w := bounds.position.x + bounds.size.x - new_pos.x
	var max_h := bounds.position.y + bounds.size.y - new_pos.y

	new_size.x = clamp(new_size.x, min_size_px.x, min(max_size_px.x, max_w))
	new_size.y = clamp(new_size.y, min_size_px.y, min(max_size_px.y, max_h-20))

	position = new_pos
	size = new_size




var _dragging := false
var _drag_offset := Vector2.ZERO

func _on_scan_slot_transmit(data):
	if type_tab=="storage":
		var slot = slot_tab.instantiate()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size = slot.custom_minimum_size
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
		slot.scop="tab"
		$VBoxContainer/Content_storage.add_child(slot)   
		slot.get_node("TextureHolder/TextureRect2").texture=null 
		slot.slot_type="tray"
		slot.set_property(data)
		
func _on_market_slot_transmit(data: Dictionary) -> void:
	if type_tab != "browser":
		return
	if not is_instance_valid(content):
		push_warning("Browser tab: 'content' e null. Verifică calea: VBoxContainer/Content")
		return

	var slot = slot_tab.instantiate()

	slot.custom_minimum_size = Vector2(64, 64)
	slot.size = slot.custom_minimum_size
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
	slot.scop = "tab"
	content.add_child(slot)
	var tex2 := slot.get_node_or_null("TextureHolder/TextureRect2")
	if tex2 is TextureRect:
		(tex2 as TextureRect).texture = null

	slot.slot_type = "tray"
	slot.set_property(data)





func _on_text_edit_gui_input(event: InputEvent) -> void:
	# dacă nu e LineEdit și prinzi Enter aici
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			accept_event()
			

func _on_www_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# SHIFT+Enter → permite linie nouă dacă vrei
			if event.shift_pressed:
				return
			accept_event()  # oprește inserarea newline-ului în TextEdit
			var text := (www as TextEdit).text.strip_edges()
			if not text.is_empty():
				_navigate_to(text, true)
				# (opțional) scoate focusul ca într-un browser
				(www as TextEdit).release_focus()



func _navigate_to(input_text: String, push_history := true) -> void:
	var url := input_text.strip_edges()
	if url.is_empty():
		return

	# normalizare minimală
	var url_l := url.to_lower()
	if not (url_l.begins_with("www.") or url_l.begins_with("http")):
		url_l = "www." + url_l

	# hist
	if push_history:
		if _history_index < _history.size() - 1:
			_history = _history.slice(0, _history_index + 1)
		_history.append(url_l)
		_history_index = _history.size() - 1

	# reflectă în bară
	if www is TextEdit:
		(www as TextEdit).text = url_l

	_apply_route(url_l)

func _apply_route(url: String) -> void:
	# ascunde tot
	for k in PAGES.keys():
		PAGES[k].visible = false

	for route in ROUTES:
		var re := RegEx.new()
		re.compile(route["pattern"])
		var m := re.search(url)
		if m:
			# arată paginile cerute
			for key in route["show"]:
				if PAGES.has(key) and is_instance_valid(PAGES[key]):
					PAGES[key].visible = true
			# titlu
			if route.has("title"):
				title.text = String(route["title"])
			# handler opțional (ex: pentru parametri)
			if route.has("handler") and has_method(String(route["handler"])):
				# treci url + capturi RegEx
				var captures := []
				for i in range(1, m.get_group_count() + 1):
					captures.append(m.get_string(i))
				call(String(route["handler"]), url, captures)
			return

	# Fallback 404 → Search
	if PAGES.has("search"):
		PAGES["search"].visible = true
	title.text = "Search"


func _go_back() -> void:
	if _history_index > 0:
		_history_index -= 1
		_navigate_to(_history[_history_index], false)


func _go_forward() -> void:
	if _history_index >= 0 and _history_index < _history.size() - 1:
		_history_index += 1
		_navigate_to(_history[_history_index], false)

func _route_storage(url: String, groups: Array) -> void:
	# reîncarcă listă, filtre, etc.
	# ex: dacă ai query: www.storage?filter=weapons
	var q = _parse_query(url)
	#if q.has("filter"):
		#storage.call("apply_filter", q["filter"])

func _route_news_with_category(url: String, groups: Array) -> void:
	var category = String(groups[0]) if groups.size() > 0 else"general"
	#news.call("show_category", category)


func _parse_query(url: String) -> Dictionary:
	var d := {}
	var qm := url.find("?")
	if qm == -1:
		return d
	var q := url.substr(qm + 1)
	for part in q.split("&"):
		var kv := part.split("=", false, 1)
		if kv.size() == 2:
			d[kv[0]] = kv[1]
		elif kv.size() == 1 and kv[0] != "":
			d[kv[0]] = true
	return d
	
func _route_market_product(_url: String, groups: Array) -> void:
	if groups.is_empty():
		# nu avem produs -> fallback la market normal
		if is_instance_valid(market_grid_all): market_grid_all.visible = true
		if is_instance_valid(market_grid_product): market_grid_product.visible = false
		return

	var raw_token := String(groups[0])
	var product := _normalize_product_token(raw_token)

	# RNG pentru câte iteme vrei în PRODUCT
	var rr := RandomNumberGenerator.new()
	rr.randomize()
	var how_many := rr.randi_range(1, 4)  # ajustează intervalul cum vrei

	var populated := false
	if is_instance_valid(market_grid_product) and market_grid_product.has_method("populate_market"):
		populated = market_grid_product.populate_market(product, how_many, true)

	# TOGGLE: dacă a populat ceva pe produs => arată PRODUCT, altfel MARKET normal
	if populated:
		if is_instance_valid(market_grid_product): market_grid_product.visible = true
		if is_instance_valid(market_grid_all):     market_grid_all.visible = false
	else:
		if is_instance_valid(market_grid_product): market_grid_product.visible = false
		if is_instance_valid(market_grid_all):     market_grid_all.visible = true


func _normalize_product_token(s: String) -> String:
	var t := s.strip_edges().to_lower()
	t = t.replace("_", " ").replace("-", " ").replace(".", " ")
	# compactează spațiile duble (fără RegEx, sigur în runtime):
	while t.find("  ") != -1:
		t = t.replace("  ", " ")
	return t
	
	
func _route_market_default(_url: String, _groups: Array) -> void:
	if is_instance_valid(market_grid_all):     market_grid_all.visible = true
	if is_instance_valid(market_grid_product): market_grid_product.visible = false
	
func _wire_one_grid(g: Node) -> void:
	if not is_instance_valid(g): return
	for c in g.get_children():
		_try_bind_market_slot(c)
	if not g.is_connected("child_entered_tree", Callable(self, "_on_market_child_entered")):
		g.child_entered_tree.connect(Callable(self, "_on_market_child_entered"))

func _get_active_inv():
	var list := get_tree().get_nodes_in_group("inv_player_active")
	if list.is_empty():
		return null
	# ia-l pe ultimul (cel mai recent activat)
	return list[list.size() - 1]
