extends CanvasLayer

var _message_token := 0

@onready var _health_bar: ProgressBar = $Stats/HealthBar
@onready var _health_label: Label = $Stats/HealthBar/HealthLabel
@onready var _nova_label: Label = $Stats/NovaLabel
@onready var _wave_label: Label = $WaveInfo/WaveLabel
@onready var _enemies_label: Label = $WaveInfo/EnemiesLabel
@onready var _score_label: Label = $WaveInfo/ScoreLabel
@onready var _message: Label = $Message
@onready var _energy_bar: ProgressBar = $Stats/EnergyBar
@onready var _energy_label: Label = $Stats/EnergyBar/EnergyLabel
@onready var _cargo_label: Label = $Stats/CargoLabel
@onready var _powerup_label: Label = $Stats/PowerupLabel
@onready var _asteroid_label: Label = $WaveInfo/AsteroidLabel
@onready var _fuel_label: Label = $WaveInfo/FuelLabel
@onready var _prompt: Label = $Prompt
@onready var fade_rect: ColorRect = $Fade
@onready var _fade_label: Label = $Fade/FadeLabel
@onready var _overlay: Control = $Overlay
@onready var _overlay_title: Label = $Overlay/Center/Box/Title
@onready var _overlay_body: Label = $Overlay/Center/Box/Body


func _ready() -> void:
	_overlay.hide()
	_message.text = ""
	set_wave(0)
	set_enemies_remaining(0)
	set_nova_cooldown(0.0, 1.0)
	_prompt.text = ""
	_powerup_label.text = ""


func set_energy(current: float, maximum: float, light: float) -> void:
	_energy_bar.max_value = maximum
	_energy_bar.value = current
	var state := "charging" if light > 0.05 else "dark"
	_energy_label.text = "Solar %d%% (%s)" % [roundi(100.0 * current / maximum), state]


func set_cargo(carried: float, capacity: float) -> void:
	_cargo_label.text = "Cargo: %d / %d fuel" % [floori(carried), roundi(capacity)]


func set_powerups(active: Dictionary) -> void:
	var lines: PackedStringArray = []
	for type in active:
		lines.append("%s %.0fs" % [Powerup.INFO[type].name, ceilf(active[type])])
	_powerup_label.text = "\n".join(lines)


func set_gameplay_visible(visible_now: bool) -> void:
	for node: CanvasItem in [$Stats, $WaveInfo, $Crosshair, $Markers, _prompt]:
		node.visible = visible_now


func fade(to_alpha: float, duration: float) -> void:
	create_tween().tween_property(fade_rect, "color:a", to_alpha, duration)


func set_fade_alpha(alpha: float) -> void:
	fade_rect.color.a = alpha


func set_fade_text(text: String) -> void:
	_fade_label.text = text


func show_title(best: int) -> void:
	_overlay.show()
	_overlay.color.a = 0.3
	_overlay_title.text = "PLANET 2"
	_overlay_body.text = "Mine fuel. Survive the dark side. Reach the next asteroid.\n\nWASD move   Mouse aim   LMB shoot   F Nova\nShift sprint   E mine / launch   Esc pause\n\nBest score: %d\n\nClick to start" % best


func hide_overlay() -> void:
	_overlay.hide()


func set_prompt(text: String) -> void:
	_prompt.text = text


func set_asteroid(level: int) -> void:
	_asteroid_label.text = "Asteroid %d" % level


func set_fuel(stored: float, quota: float) -> void:
	_fuel_label.text = "Dropship fuel: %d / %d" % [floori(stored), roundi(quota)]


func set_health(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "HP %d / %d" % [ceili(current), roundi(maximum)]


func set_nova_cooldown(remaining: float, _total: float) -> void:
	_nova_label.text = "Nova [F / RMB]: READY" if remaining <= 0.0 else "Nova [F / RMB]: %.1fs" % remaining


func set_wave(wave: int) -> void:
	_wave_label.text = "Wave %d" % wave if wave > 0 else "Get ready"


func set_enemies_remaining(count: int) -> void:
	_enemies_label.text = "Monsters left: %d" % count


func set_score(score: int, high_score: int) -> void:
	_score_label.text = "Score: %d   Best: %d" % [score, high_score]


func set_intermission(seconds_left: float, next_wave: int) -> void:
	var header := "MINE FUEL AND SURVIVE" if next_wave == 1 else "WAVE %d CLEARED" % (next_wave - 1)
	_message_token += 1
	_message.text = "%s\nWave %d in %d" % [header, next_wave, ceili(seconds_left)]


func show_message(text: String, duration := 2.0) -> void:
	_message_token += 1
	var token := _message_token
	_message.text = text
	await get_tree().create_timer(duration).timeout
	if token == _message_token:
		_message.text = ""


func show_paused(paused: bool) -> void:
	_overlay.visible = paused
	_overlay.color.a = 0.6
	_overlay_title.text = "PAUSED"
	_overlay_body.text = "Press Esc or click to resume"


func show_game_over(level: int, wave: int, score: int, high_score: int) -> void:
	_message.text = ""
	_overlay.show()
	_overlay.color.a = 0.6
	_overlay_title.text = "YOU WERE OVERRUN"
	var best := "New best!" if score >= high_score and score > 0 else "Best: %d" % high_score
	_overlay_body.text = "Reached asteroid %d, wave %d\nScore: %d   %s\n\nPress R or Enter to try again" % [level, wave, score, best]
