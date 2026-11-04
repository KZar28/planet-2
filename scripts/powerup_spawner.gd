extends Node
## While the player is on the night side, occasionally drops a powerup nearby.

@export var check_interval := 4.0
@export var spawn_chance := 0.4
@export var max_active := 3
@export var min_angle_deg := 6.0
@export var max_angle_deg := 22.0
@export var night_threshold := 0.3

var _timer := 0.0

@onready var _player := get_tree().get_first_node_in_group("player") as Player
@onready var _planet := get_tree().get_first_node_in_group("planet") as Planet
@onready var _day_night := get_tree().get_first_node_in_group("day_night") as DayNight


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = check_interval
	if _player.is_dead or _day_night.light_at(_player.global_position) > night_threshold:
		return
	if get_tree().get_nodes_in_group("powerups").size() >= max_active or randf() > spawn_chance:
		return
	var up := _player.get_up()
	var ref := Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
	var tangent := up.cross(ref).normalized().rotated(up, randf() * TAU)
	var dir := up.rotated(tangent, deg_to_rad(randf_range(min_angle_deg, max_angle_deg)))
	var powerup := Powerup.new()
	powerup.type = Powerup.Type.values().pick_random()
	powerup.process_mode = Node.PROCESS_MODE_PAUSABLE
	powerup.transform = _planet.surface_transform(dir, 0.0)
	get_parent().add_child(powerup)
