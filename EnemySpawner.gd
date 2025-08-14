# EnemySpawner.gd
extends Node2D
@export var enemy_scene: PackedScene
@export var spawn_position: Vector2 = Vector2.ZERO
@export var min_delay: float = 3.0
@export var max_delay: float = 8.0
@export var add_to_current_scene: bool = true  # dacă vrei să adaugi enemy la root scene

var _timer: Timer
var _current_enemy: Node = null

func _ready() -> void:
	randomize()
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	_schedule_next()

func start_spawning(at_position: Vector2) -> void:
	spawn_position = at_position
	if _current_enemy == null and _timer.is_stopped():
		_schedule_next()

func stop_spawning() -> void:
	if is_instance_valid(_timer):
		_timer.stop()

func _schedule_next() -> void:
	if _current_enemy != null:
		return
	var wait := randf_range(min_delay, max_delay)
	_timer.start(wait)

func _on_timer_timeout() -> void:
	_spawn_enemy()

func _spawn_enemy() -> void:
	if _current_enemy != null or enemy_scene == null:
		return
	var enemy = enemy_scene.instantiate()
	# poziționare
	if enemy is Node2D:
		enemy.global_position = spawn_position
	elif enemy.has_method("set_position"):
		enemy.call("set_position", spawn_position)

	# parent
	if add_to_current_scene:
		get_tree().current_scene.add_child(enemy)
	else:
		add_child(enemy)

	_current_enemy = enemy
	_timer.stop()  # cât timp există enemy-ul, timerul e oprit

	# când dispare enemy-ul din arbore, reluăm spawn-ul
	enemy.connect("tree_exited", Callable(self, "_on_enemy_gone"), CONNECT_ONE_SHOT)

	# dacă ai un semnal custom "died" pe enemy, poți conecta și acela:
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_gone"), CONNECT_ONE_SHOT)

func _on_enemy_gone() -> void:
	_current_enemy = null
	_schedule_next()
