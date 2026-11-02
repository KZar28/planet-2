extends Node3D

const HIT_MASK := 1 | 4  # world + enemies

@export var speed := 70.0
@export var lifetime := 1.5

var damage := 25.0
var _velocity := Vector3.ZERO


func launch(origin: Vector3, direction: Vector3, projectile_damage: float) -> void:
	global_position = origin
	_velocity = direction * speed
	damage = projectile_damage


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	# Raycast along this frame's travel so fast shots can't tunnel through enemies.
	var from := global_position
	var to := from + _velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, HIT_MASK)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var target: Object = hit.collider
		if target is Enemy:
			(target as Enemy).take_damage(damage)
		queue_free()
		return
	global_position = to
