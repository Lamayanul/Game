extends CanvasLayer

@onready var inventory_panel_cup: Control = $Inv2
@onready var toggle_button_cup: Button   = $Button

@onready var inventory_panel: Control    = $Inv
@onready var toggle_button: Button       = $Button2

var is_shown_cup := false
var is_shown := false
var tween_cup: Tween
var tween: Tween

const MARGIN := 10.0

func _ready():
	get_viewport().size_changed.connect(_on_viewport_resized)
	await get_tree().process_frame  # asigură layout-ul și mărimile
	# ancorați-le DOAR pe Y la bottom (nu atingem X, nici size)
	_anchor_y_bottom(inventory_panel_cup)
	_anchor_y_bottom(inventory_panel)

	_init_inventory_slide()
	toggle_button_cup.pressed.connect(_on_toggle_inventory_pressed_cup)
	toggle_button.pressed.connect(_on_toggle_inventory_pressed)

func _anchor_y_bottom(p: Control) -> void:
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	# nu schimbăm anchor_left/right → X rămâne cum e

func _canvas_h() -> float:
	# dimensiunea VIZIBILĂ a canvas-ului (corectă pentru keep/expand/scale)
	return get_viewport().get_visible_rect().size.y

func _shown_y(panel: Control) -> float:
	return _canvas_h() - panel.size.y - MARGIN

func _hidden_y(_panel: Control) -> float:
	return _canvas_h() + MARGIN

func _init_inventory_slide():
	inventory_panel_cup.position.y = _hidden_y(inventory_panel_cup)
	inventory_panel.position.y = _hidden_y(inventory_panel)
	is_shown_cup = false
	is_shown = false

func _on_toggle_inventory_pressed_cup():
	if tween_cup: tween_cup.kill()
	tween_cup = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target_y :=_hidden_y(inventory_panel_cup) if  is_shown_cup else _shown_y(inventory_panel_cup)
	tween_cup.tween_property(inventory_panel_cup, "position:y", target_y, 0.7)
	is_shown_cup = !is_shown_cup

func _on_toggle_inventory_pressed():
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target_y :=_hidden_y(inventory_panel) if is_shown else _shown_y(inventory_panel)
	tween.tween_property(inventory_panel, "position:y", target_y, 0.7)
	is_shown = !is_shown

func _on_viewport_resized():
	inventory_panel_cup.position.y = _shown_y(inventory_panel_cup) if is_shown_cup else _hidden_y(inventory_panel_cup)
	inventory_panel.position.y     = _shown_y(inventory_panel)  if is_shown    else _hidden_y(inventory_panel)
