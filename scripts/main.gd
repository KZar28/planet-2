extends Node3D

const SAVE_PATH := "user://save.cfg"

var score := 0
var high_score := 0
var game_over := false

@onready var _player: Player = $Player
@onready var _waves: Node = $WaveManager
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	high_score = _load_high_score()
	_player.health_changed.connect(_hud.set_health)
	_player.nova_cooldown_changed.connect(_hud.set_nova_cooldown)
	_player.died.connect(_on_player_died)
	_waves.wave_started.connect(_on_wave_started)
	_waves.wave_cleared.connect(_on_wave_cleared)
	_waves.enemies_remaining_changed.connect(_hud.set_enemies_remaining)
	_waves.intermission_tick.connect(_hud.set_intermission)
	_waves.enemy_killed.connect(_on_enemy_killed)
	_hud.set_health(_player.health, _player.max_health)
	_hud.set_score(score, high_score)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("restart"):
			get_tree().reload_current_scene()
		return
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not get_tree().paused)
	elif event is InputEventMouseButton and event.pressed:
		if get_tree().paused:
			_set_paused(false)
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	_hud.show_paused(paused)


func _on_wave_started(wave: int, _count: int) -> void:
	_hud.set_wave(wave)
	_hud.show_message("WAVE %d" % wave)


func _on_wave_cleared(_wave: int) -> void:
	_player.heal(25.0)


func _on_enemy_killed(value: int) -> void:
	score += value
	_hud.set_score(score, maxi(score, high_score))


func _on_player_died() -> void:
	game_over = true
	_waves.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var previous_best := high_score
	high_score = maxi(score, high_score)
	if high_score > previous_best:
		_save_high_score()
	_hud.show_game_over(_waves.wave, score, high_score)


func _load_high_score() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value("scores", "high_score", 0))


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)
