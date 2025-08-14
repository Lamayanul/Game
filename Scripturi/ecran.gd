extends CanvasLayer

@onready var inventory_panel_cup = $Inv2 # sau calea ta!
@onready var toggle_button_cup = $Button

@onready var inventory_panel = $Inv 
@onready var toggle_button = $Button2

var is_shown_cup = false
var is_shown = false
var tween_cup : Tween = null
var tween : Tween = null

func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resized"))
	call_deferred("_init_inventory_slide")
	toggle_button_cup.connect("pressed", Callable(self, "_on_toggle_inventory_pressed_cup"))
	toggle_button.connect("pressed", Callable(self, "_on_toggle_inventory_pressed"))

func _init_inventory_slide():
	# Inițializează panel-urile pe poziție ascunsă, la baza ecranului
	inventory_panel_cup.position.y = get_hidden_y(inventory_panel_cup)
	inventory_panel.position.y = get_hidden_y(inventory_panel)
	is_shown_cup = false
	is_shown = false

func get_shown_y(panel: Control) -> float:
	# Poziția pentru slide “la vedere” (lipit de jos, dar cât să fie perfect vizibil)
	return get_viewport().size.y - panel.size.y - 10 # -10 ca să fie 10px peste margine, schimbă după preferință

func get_hidden_y(_panel: Control) -> float:
	# Poziția de ascuns, sub ecran complet
	return get_viewport().size.y + 30 # +30 ca să fie cu 30px sub margine, sau poți face +panel.size.y

func _on_toggle_inventory_pressed_cup():
	if tween_cup: tween_cup.kill()
	tween_cup = create_tween()
	var show_y = get_shown_y(inventory_panel_cup)
	var hide_y = get_hidden_y(inventory_panel_cup)
	var target_y = show_y if !is_shown_cup else hide_y
	tween_cup.tween_property(inventory_panel_cup, "position:y", target_y, 0.7).set_trans(Tween.TRANS_SINE)
	is_shown_cup = !is_shown_cup

func _on_toggle_inventory_pressed():
	if tween: tween.kill()
	tween = create_tween()
	var show_y = get_shown_y(inventory_panel)
	var hide_y = get_hidden_y(inventory_panel)
	var target_y = show_y if !is_shown else hide_y
	tween.tween_property(inventory_panel, "position:y", target_y, 0.7).set_trans(Tween.TRANS_SINE)
	is_shown = !is_shown

func _on_viewport_resized():
	# La resize, repoziționează inventarele dacă sunt ascunse
	if !is_shown_cup:
		inventory_panel_cup.position.y = get_hidden_y(inventory_panel_cup)
	else:
		inventory_panel_cup.position.y = get_shown_y(inventory_panel_cup)
	if !is_shown:
		inventory_panel.position.y = get_hidden_y(inventory_panel)
	else:
		inventory_panel.position.y = get_shown_y(inventory_panel)
