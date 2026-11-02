class_name Planet
extends StaticBody3D
## The spherical world. Scatters trees, rocks and crystals over the surface so
## the player has landmarks to navigate by.

@export var radius := 30.0
@export var tree_count := 45
@export var rock_count := 35
@export var crystal_count := 60
@export var decoration_seed := 1337
## Keep the area around the player's spawn point (top of the planet) clear.
@export var spawn_clear_angle_deg := 12.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = decoration_seed
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 1.6
	trunk_mesh.material = _material(Color(0.42, 0.27, 0.15))
	var foliage_mesh := CylinderMesh.new()
	foliage_mesh.top_radius = 0.0
	foliage_mesh.bottom_radius = 1.1
	foliage_mesh.height = 2.6
	foliage_mesh.radial_segments = 8
	foliage_mesh.material = _material(Color(0.13, 0.45, 0.2))
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.9
	rock_mesh.height = 1.2
	rock_mesh.radial_segments = 7
	rock_mesh.rings = 3
	rock_mesh.material = _material(Color(0.45, 0.43, 0.42))
	var crystal_mesh := PrismMesh.new()
	crystal_mesh.size = Vector3(0.35, 1.2, 0.35)
	var crystal_mat := _material(Color(0.3, 0.8, 1.0))
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.3, 0.8, 1.0)
	crystal_mat.emission_energy_multiplier = 1.2
	crystal_mesh.material = crystal_mat

	for i in tree_count:
		var anchor := _add_anchor()
		_add_mesh(anchor, trunk_mesh, Vector3(0, 0.8, 0))
		_add_mesh(anchor, foliage_mesh, Vector3(0, 2.6, 0))
		_add_collision(anchor, _cylinder_shape(0.3, 1.6), Vector3(0, 0.8, 0))
	for i in rock_count:
		var anchor := _add_anchor()
		var s := _rng.randf_range(0.7, 1.6)
		anchor.scale = Vector3.ONE * s
		_add_mesh(anchor, rock_mesh, Vector3(0, 0.2, 0))
		var shape := SphereShape3D.new()
		shape.radius = 0.75 * s
		_add_collision(anchor, shape, Vector3(0, 0.2, 0))
	for i in crystal_count:
		var anchor := _add_anchor()
		anchor.scale = Vector3.ONE * _rng.randf_range(0.6, 1.4)
		_add_mesh(anchor, crystal_mesh, Vector3(0, 0.5, 0))


func random_surface_direction() -> Vector3:
	var dir := Vector3(_rng.randfn(), _rng.randfn(), _rng.randfn())
	return dir.normalized() if dir.length_squared() > 0.0001 else Vector3.UP


## Returns a transform on the surface facing a random direction, with Y = up.
func surface_transform(dir: Vector3, yaw: float) -> Transform3D:
	var up := dir.normalized()
	var ref := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var fwd := (ref - up * ref.dot(up)).normalized().rotated(up, yaw)
	var right := fwd.cross(up)
	return Transform3D(Basis(right, up, -fwd), up * radius)


func _add_anchor() -> Node3D:
	var dir := random_surface_direction()
	while rad_to_deg(dir.angle_to(Vector3.UP)) < spawn_clear_angle_deg:
		dir = random_surface_direction()
	var anchor := Node3D.new()
	anchor.name = "Decoration"
	anchor.transform = surface_transform(dir, _rng.randf_range(0.0, TAU))
	$Decorations.add_child(anchor)
	return anchor


func _add_mesh(parent: Node3D, mesh: Mesh, offset: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = offset
	parent.add_child(mi)


func _add_collision(anchor: Node3D, shape: Shape3D, offset: Vector3) -> void:
	# Shapes must be direct children of the body, so place them in planet space.
	var cs := CollisionShape3D.new()
	cs.shape = shape
	var t := anchor.transform
	cs.transform = Transform3D(t.basis.orthonormalized(), t * offset)
	add_child(cs)


func _cylinder_shape(r: float, h: float) -> CylinderShape3D:
	var shape := CylinderShape3D.new()
	shape.radius = r
	shape.height = h
	return shape


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat
