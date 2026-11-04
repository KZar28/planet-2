extends Node
## Spawns escalating waves of enemies away from the player, then waits for the
## wave to be cleared before a short intermission.

signal wave_started(wave: int, enemy_count: int)
signal wave_cleared(wave: int)
signal enemies_remaining_changed(count: int)
signal intermission_tick(seconds_left: float, next_wave: int)
signal enemy_killed(score_value: int, credits: int)

const ENEMY := preload("res://scenes/enemy.tscn")

@export var enemies_root: Node3D
@export var first_wave_delay := 4.0
@export var intermission := 10.0
@export var spawn_interval := 0.5
## Enemies spawn at least this far (as an angle around the planet) from the player.
@export var min_spawn_angle_deg := 50.0
@export var spawn_height := 4.0
@export var health_growth_per_wave := 0.12
@export var health_growth_per_asteroid := 0.25
## Chance to accept a spawn point in daylight; monsters prefer the dark side.
@export var daylight_spawn_chance := 0.25

var wave := 0
var _queue: Array[Enemy.Type] = []
var _remaining := 0
var _spawn_timer := 0.0
var _intermission_timer := 0.0
var _in_intermission := true
var _active := true

@onready var _player := get_tree().get_first_node_in_group("player") as Player
@onready var _planet := get_tree().get_first_node_in_group("planet") as Planet


func _ready() -> void:
	_intermission_timer = first_wave_delay


func stop() -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active:
		return
	if _in_intermission:
		_intermission_timer -= delta
		intermission_tick.emit(maxf(_intermission_timer, 0.0), wave + 1)
		if _intermission_timer <= 0.0:
			_start_next_wave()
		return
	if not _queue.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = spawn_interval
			_spawn_enemy(_queue.pop_back())


static func build_wave(n: int) -> Array[Enemy.Type]:
	var list: Array[Enemy.Type] = []
	for i in 5 + n * 3:
		list.append(Enemy.Type.CRAWLER)
	for i in maxi(n - 1, 0) * 3:
		list.append(Enemy.Type.RUNNER)
	for i in ceili(maxi(n - 2, 0) * 1.5):
		list.append(Enemy.Type.BRUTE)
	list.shuffle()
	return list


func _start_next_wave() -> void:
	wave += 1
	_in_intermission = false
	_queue = build_wave(wave)
	for i in (GameState.level - 1) * 3:
		_queue.append(Enemy.Type.CRAWLER if i % 3 else Enemy.Type.RUNNER)
	_queue.shuffle()
	_remaining = _queue.size()
	_spawn_timer = 0.0
	wave_started.emit(wave, _remaining)
	enemies_remaining_changed.emit(_remaining)


func _spawn_enemy(enemy_type: Enemy.Type) -> void:
	var enemy := ENEMY.instantiate() as Enemy
	enemy.setup(enemy_type, 1.0 + health_growth_per_wave * (wave - 1) + health_growth_per_asteroid * (GameState.level - 1))
	enemy.position = _random_spawn_position()
	enemy.died.connect(_on_enemy_died)
	enemies_root.add_child(enemy)


func _random_spawn_position() -> Vector3:
	var center := _planet.global_position
	var player_up := (_player.global_position - center).normalized()
	var dir := -player_up
	var day_night := get_tree().get_first_node_in_group("day_night") as DayNight
	for i in 40:
		var candidate := Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()
		if rad_to_deg(candidate.angle_to(player_up)) < min_spawn_angle_deg:
			continue
		dir = candidate
		if day_night == null or day_night.light_at(center + candidate) < 0.5 or randf() < daylight_spawn_chance:
			break
	return center + dir * (_planet.radius + spawn_height)


func _on_enemy_died(enemy: Enemy) -> void:
	_remaining -= 1
	enemy_killed.emit(enemy.score_value, enemy.credits_earned())
	enemies_remaining_changed.emit(_remaining)
	if _remaining <= 0 and _queue.is_empty() and _active:
		_in_intermission = true
		_intermission_timer = intermission
		wave_cleared.emit(wave)
