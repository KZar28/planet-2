extends CanvasLayer

var _message_token := 0

@onready var _health_bar: ProgressBar = $Stats/HealthBar
@onready var _health_label: Label = $Stats/HealthBar/HealthLabel
@onready var _nova_label: Label = $Stats/NovaLabel
@onready var _wave_label: Label = $WaveInfo/WaveLabel
@onready var _enemies_label: Label = $WaveInfo/EnemiesLabel
@onready var _score_label: Label = $WaveInfo/ScoreLabel
@onready var _message: Label = $Message
@onready var _overlay: Control = $Overlay
@onready var _overlay_title: Label = $Overlay/Center/Box/Title
@onready var _overlay_body: Label = $Overlay/Center/Box/Body


func _ready() -> void:
	_overlay.hide()
	_message.text = ""
	set_wave(0)
	set_enemies_remaining(0)
	set_nova_cooldown(0.0, 1.0)


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
	var header := "DEFEND THE PLANET" if next_wave == 1 else "WAVE %d CLEARED" % (next_wave - 1)
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
	_overlay_title.text = "PAUSED"
	_overlay_body.text = "Press Esc or click to resume"


func show_game_over(wave: int, score: int, high_score: int) -> void:
	_message.text = ""
	_overlay.show()
	_overlay_title.text = "YOU WERE OVERRUN"
	var best := "New best!" if score >= high_score and score > 0 else "Best: %d" % high_score
	_overlay_body.text = "Survived to wave %d\nScore: %d   %s\n\nPress R or Enter to try again" % [wave, score, best]
