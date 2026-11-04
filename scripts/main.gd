extends Node3D

const SAVE_PATH := "user://save.cfg"

var score := 0
var high_score := 0
var game_over := false
enum Phase { TITLE, LANDING, PLAYING, LAUNCHING }

const DESCENT_HEIGHT := 45.0

var phase := Phase.PLAYING
var _sequence: Tween
var _title_angle := 0.0

@onready var _player: Player = $Player
@onready var _waves: Node = $WaveManager
@onready var _hud: CanvasLayer = $HUD
@onready var _dropship: Dropship = $Dropship
@onready var _cine_cam: Camera3D = $CinematicCamera
@onready var _player_cam: Camera3D = $Player/CameraPivot/SpringArm3D/Camera3D
@onready var _enemies: Node3D = $Enemies
@onready var _sun: DayNight = $Sun
@onready var _powerups: Node = $PowerupSpawner


func _ready() -> void:
	high_score = _load_high_score()
	score = GameState.score
	_dropship.quota = GameState.fuel_quota()
	GameState.ensure_shop_offers()
	_player.dropship = _dropship
	_player.energy_changed.connect(_hud.set_energy)
	_player.cargo_changed.connect(_hud.set_cargo)
	_player.powerups_changed.connect(_hud.set_powerups)
	_player.prompt_changed.connect(_hud.set_prompt)
	_player.launch_requested.connect(_launch)
	_player.shop_requested.connect(_open_shop)
	_player.shield_changed.connect(_hud.set_shield)
	_hud.shop.purchased.connect(_on_shop_purchased)
	_hud.shop.closed.connect(_close_shop)
	_hud.set_credits(GameState.credits)
	_hud.set_shield(_player.shield, _player.shield_max)
	_hud.set_nova(1, _player.nova_max_charges, 0.0)
	_dropship.fuel_changed.connect(_on_fuel_changed)
	_hud.set_asteroid(GameState.level)
	_hud.set_fuel(0.0, _dropship.quota)
	_hud.set_cargo(0.0, _player.cargo_capacity)
	_player.health_changed.connect(_hud.set_health)
	_player.nova_changed.connect(_hud.set_nova)
	_player.died.connect(_on_player_died)
	_waves.wave_started.connect(_on_wave_started)
	_waves.wave_cleared.connect(_on_wave_cleared)
	_waves.enemies_remaining_changed.connect(_hud.set_enemies_remaining)
	_waves.intermission_tick.connect(_hud.set_intermission)
	_waves.enemy_killed.connect(_on_enemy_killed)
	_hud.set_health(_player.health, _player.max_health)
	_hud.set_score(score, high_score)
	_hud.set_fade_text("")
	_set_gameplay_active(false)
	if GameState.show_title:
		_show_title()
	else:
		_hud.set_fade_alpha(1.0)
		_start_landing()


func _process(delta: float) -> void:
	match phase:
		Phase.TITLE:
			_title_angle += delta * 0.08
			_cine_cam.global_position = Vector3(sin(_title_angle), 0.35, cos(_title_angle)).normalized() * 95.0
			_cine_cam.look_at(Vector3.ZERO, Vector3.UP)
		Phase.LANDING, Phase.LAUNCHING:
			var up := _dropship.global_basis.y
			var ship := _dropship.global_position + up * 3.0
			_cine_cam.look_at(ship.lerp(_dropship.rest_position, 0.6), up)


func _set_gameplay_active(active: bool) -> void:
	for node: Node in [_player, _waves, _powerups, _enemies, _sun]:
		node.process_mode = Node.PROCESS_MODE_PAUSABLE if active else Node.PROCESS_MODE_DISABLED
	_player.visible = active
	_hud.set_gameplay_visible(active)
	(_player_cam if active else _cine_cam).make_current()


func _place_cinematic_camera() -> void:
	var b := _dropship.global_basis
	_cine_cam.global_position = _dropship.rest_position + b.y * 6.0 + b.x * 36.0 + b.z * 28.0


func _show_title() -> void:
	phase = Phase.TITLE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_dropship.position = _dropship.rest_position + _dropship.global_basis.y * DESCENT_HEIGHT
	_hud.show_title(high_score)


func _start_landing() -> void:
	phase = Phase.LANDING
	GameState.show_title = false
	_hud.hide_overlay()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_place_cinematic_camera()
	_dropship.position = _dropship.rest_position + _dropship.global_basis.y * DESCENT_HEIGHT
	_dropship.set_thrusters(true)
	_hud.fade(0.0, 1.2)
	_hud.show_message("ASTEROID %d\nCollect %d fuel" % [GameState.level, roundi(_dropship.quota)], 4.0)
	_sequence = create_tween()
	_sequence.tween_property(_dropship, "position", _dropship.rest_position, 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_sequence.tween_callback(_dropship.set_thrusters.bind(false))
	_sequence.tween_interval(0.7)
	_sequence.tween_callback(_finish_landing)


func _finish_landing() -> void:
	if phase != Phase.LANDING:
		return
	_sequence.kill()
	_dropship.position = _dropship.rest_position
	_dropship.set_thrusters(false)
	_hud.set_fade_alpha(0.0)
	phase = Phase.PLAYING
	_set_gameplay_active(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _is_skip(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed)


func _unhandled_input(event: InputEvent) -> void:
	match phase:
		Phase.TITLE:
			if (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("ui_accept"):
				_start_landing()
			return
		Phase.LANDING:
			if _is_skip(event):
				_finish_landing()
			return
		Phase.LAUNCHING:
			if _is_skip(event):
				get_tree().reload_current_scene()
			return
	if _hud.shop.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			_close_shop()
		return
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


func _on_fuel_changed(stored: float, quota: float) -> void:
	_hud.set_fuel(stored, quota)
	if _dropship.quota_met():
		_hud.show_message("FUEL QUOTA MET\nReturn to the dropship and press E to launch", 4.0)


func _launch() -> void:
	if phase != Phase.PLAYING or game_over:
		return
	phase = Phase.LAUNCHING
	_waves.stop()
	_set_gameplay_active(false)
	_place_cinematic_camera()
	_on_enemy_killed(100 * GameState.level)
	GameState.level += 1
	GameState.score = score
	_sequence = create_tween()
	for n in [3, 2, 1]:
		_sequence.tween_callback(_hud.show_message.bind(str(n), 0.8))
		_sequence.tween_interval(0.8)
	_sequence.tween_callback(_dropship.set_thrusters.bind(true))
	_sequence.tween_callback(_hud.show_message.bind("LIFTOFF", 1.5))
	var target := _dropship.rest_position + _dropship.global_basis.y * DESCENT_HEIGHT
	_sequence.tween_property(_dropship, "position", target, 3.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_sequence.parallel().tween_property(_hud.fade_rect, "color:a", 1.0, 1.0).set_delay(2.5)
	_sequence.tween_callback(_hud.set_fade_text.bind("TRAVELING TO ASTEROID %d" % GameState.level))
	_sequence.tween_interval(1.8)
	_sequence.tween_callback(get_tree().reload_current_scene)


func _on_enemy_killed(value: int, credits := 0) -> void:
	if game_over:
		return
	GameState.credits += credits
	_hud.set_credits(GameState.credits)
	score += value
	_hud.set_score(score, maxi(score, high_score))


func _open_shop() -> void:
	if phase != Phase.PLAYING or game_over:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.shop.open()


func _close_shop() -> void:
	_hud.shop.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_player.lock_interact()


func _on_shop_purchased(id: String) -> void:
	if GameState.buy(id):
		_player.apply_upgrades()
		_hud.set_credits(GameState.credits)
		_hud.shop.refresh()


func _on_player_died() -> void:
	game_over = true
	var level := GameState.level
	GameState.reset()
	_waves.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var previous_best := high_score
	high_score = maxi(score, high_score)
	if high_score > previous_best:
		_save_high_score()
	_hud.show_game_over(level, _waves.wave, score, high_score)


func _load_high_score() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value("scores", "high_score", 0))


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)
