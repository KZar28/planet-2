class_name Enemy
extends SphereWalker

signal died(enemy: Enemy)

enum Type { CRAWLER, RUNNER, BRUTE }

const STATS := {
	Type.CRAWLER: {"health": 50.0, "speed": 4.5, "damage": 8.0, "size": 1.0, "score": 10, "color": Color(0.85, 0.2, 0.2)},
	Type.RUNNER: {"health": 25.0, "speed": 8.0, "damage": 6.0, "size": 0.7, "score": 15, "color": Color(0.95, 0.6, 0.1)},
	Type.BRUTE: {"health": 220.0, "speed": 2.8, "damage": 25.0, "size": 1.8, "score": 40, "color": Color(0.55, 0.2, 0.7)},
}

@export var type: Type = Type.CRAWLER
@export var turn_speed := 6.0
@export var attack_range := 1.3
@export var attack_cooldown := 1.2

var max_health := 50.0
var health := 50.0
var move_speed := 4.5
var contact_damage := 10.0
var score_value := 10

var _size := 1.0
var _health_multiplier := 1.0
var _attack_timer := 0.0
var _dying := false
var _player: Player
var _material: StandardMaterial3D

@onready var _visual: Node3D = $Visual
@onready var _body: MeshInstance3D = $Visual/Body
@onready var _collision: CollisionShape3D = $CollisionShape3D


## Call before adding to the tree.
func setup(enemy_type: Type, health_multiplier: float) -> void:
	type = enemy_type
	_health_multiplier = health_multiplier


func _ready() -> void:
	super()
	var stats: Dictionary = STATS[type]
	max_health = stats.health * _health_multiplier
	health = max_health
	move_speed = stats.speed
	contact_damage = stats.damage
	score_value = stats.score
	_size = stats.size

	_visual.scale = Vector3.ONE * _size
	var shape := (_collision.shape as SphereShape3D).duplicate() as SphereShape3D
	shape.radius *= _size
	_collision.shape = shape
	_collision.position *= _size

	_material = (_body.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_material.albedo_color = stats.color
	_body.material_override = _material
	_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if _dying:
		return
	_attack_timer -= delta
	var up := get_up()
	var horizontal := Vector3.ZERO
	if is_instance_valid(_player) and not _player.is_dead:
		var to_player := _player.global_position - global_position
		var dir := to_player - up * to_player.dot(up)
		var reach := attack_range + 0.6 * _size
		if dir.length_squared() > 0.01:
			var fwd := (-global_basis.z).lerp(dir.normalized(), clampf(turn_speed * delta, 0.0, 1.0))
			align_to_surface(fwd)
		else:
			align_to_surface(-global_basis.z)
		if dir.length() > reach * 0.8:
			horizontal = -global_basis.z * move_speed
		if to_player.length() <= reach and _attack_timer <= 0.0:
			_attack()
	else:
		align_to_surface(-global_basis.z)

	var vertical: float = split_velocity()[1]
	vertical = 0.0 if is_on_floor() else vertical - gravity_strength * delta
	move_on_surface(horizontal, vertical)


func take_damage(amount: float) -> void:
	if _dying:
		return
	health -= amount
	_material.emission_enabled = true
	_material.emission = Color.WHITE
	_material.emission_energy_multiplier = 3.0
	create_tween().tween_property(_material, "emission_energy_multiplier", 0.0, 0.15)
	if health <= 0.0:
		_die()


func _attack() -> void:
	_attack_timer = attack_cooldown
	_player.take_damage(contact_damage)
	var tween := create_tween()
	tween.tween_property(_visual, "position", Vector3(0, 0, -0.4 * _size), 0.08)
	tween.tween_property(_visual, "position", Vector3.ZERO, 0.15)


func _die() -> void:
	_dying = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
