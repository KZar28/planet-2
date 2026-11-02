class_name SphereWalker
extends CharacterBody3D
## Base for any body that walks on the planet: gravity pulls toward the planet
## center and the body's local Y axis is kept pointing "up" from the surface.

@export var gravity_strength := 30.0

var planet_center := Vector3.ZERO
var planet_radius := 30.0


func _ready() -> void:
	var planet := get_tree().get_first_node_in_group("planet") as Planet
	if planet:
		planet_center = planet.global_position
		planet_radius = planet.radius
	align_to_surface(-global_basis.z)


func get_up() -> Vector3:
	return (global_position - planet_center).normalized()


## Orients the body so local Y points away from the planet while facing as
## close to `forward` as possible.
func align_to_surface(forward: Vector3) -> void:
	var up := get_up()
	var fwd := forward - up * forward.dot(up)
	if fwd.length_squared() < 0.0001:
		fwd = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
		fwd -= up * fwd.dot(up)
	fwd = fwd.normalized()
	var right := fwd.cross(up).normalized()
	global_basis = Basis(right, up, -fwd)
	up_direction = up


## Moves with a velocity tangent to the surface plus a speed along "up".
func move_on_surface(horizontal: Vector3, vertical_speed: float) -> void:
	velocity = horizontal + up_direction * vertical_speed
	move_and_slide()


## Splits the current velocity into (tangential velocity, speed along up).
func split_velocity() -> Array:
	var up := get_up()
	var vertical := velocity.dot(up)
	return [velocity - up * vertical, vertical]
