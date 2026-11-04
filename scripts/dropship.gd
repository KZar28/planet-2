class_name Dropship
extends StaticBody3D
## Spawn point. The player brings fuel back here; once the quota is met they
## can launch to the next asteroid.

signal fuel_changed(stored: float, quota: float)

@export var interact_radius := 7.0

var quota := 100.0
var stored := 0.0
var rest_position := Vector3.ZERO
var thrusters_on := false
var _flame := MeshInstance3D.new()
var _flame_light := OmniLight3D.new()
var _beacon: OmniLight3D
var _t := 0.0


func _ready() -> void:
	add_to_group("dropship")
	rest_position = position
	collision_mask = 0
	var hull := _material(Color(0.75, 0.77, 0.8), 0.7)
	var dark := _material(Color(0.2, 0.22, 0.25), 0.3)
	var glass := _material(Color(0.2, 0.6, 1.0), 0.0)
	glass.emission_enabled = true
	glass.emission = Color(0.3, 0.7, 1.0)

	var pad := CylinderMesh.new()
	pad.top_radius = 4.0
	pad.bottom_radius = 4.2
	pad.height = 0.15
	pad.material = dark
	var pad_instance := _add_mesh(pad, Vector3(0, 0.05, 0))
	# The pad stays on the ground when the ship lifts off.
	pad_instance.top_level = true
	pad_instance.global_transform = global_transform * Transform3D(Basis(), Vector3(0, 0.05, 0))
	var body := CylinderMesh.new()
	body.top_radius = 0.9
	body.bottom_radius = 1.6
	body.height = 4.0
	body.material = hull
	_add_mesh(body, Vector3(0, 2.6, 0))
	var nose := CylinderMesh.new()
	nose.top_radius = 0.0
	nose.bottom_radius = 0.9
	nose.height = 1.6
	nose.material = hull
	_add_mesh(nose, Vector3(0, 5.4, 0))
	var window := BoxMesh.new()
	window.size = Vector3(0.9, 0.35, 0.2)
	window.material = glass
	_add_mesh(window, Vector3(0, 3.8, 1.05))
	for i in 3:
		var leg := CylinderMesh.new()
		leg.top_radius = 0.12
		leg.bottom_radius = 0.18
		leg.height = 1.4
		leg.material = dark
		var a := TAU * i / 3.0
		_add_mesh(leg, Vector3(cos(a) * 1.7, 0.7, sin(a) * 1.7))

	var shape := CylinderShape3D.new()
	shape.radius = 1.6
	shape.height = 6.0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 3.0, 0)
	add_child(cs)

	_beacon = OmniLight3D.new()
	_beacon.light_color = Color(0.4, 0.8, 1.0)
	_beacon.omni_range = 10.0
	_beacon.position = Vector3(0, 6.5, 0)
	add_child(_beacon)

	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.albedo_color = Color(1.0, 0.6, 0.2, 0.85)
	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 1.1
	flame_mesh.bottom_radius = 0.0
	flame_mesh.height = 3.5
	flame_mesh.material = flame_mat
	_flame.mesh = flame_mesh
	_flame.position = Vector3(0, -1.1, 0)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)
	_flame_light.light_color = Color(1.0, 0.6, 0.25)
	_flame_light.omni_range = 14.0
	_flame_light.position = Vector3(0, -0.5, 0)
	add_child(_flame_light)
	set_thrusters(false)


func _process(delta: float) -> void:
	_t += delta
	var speed := 6.0 if quota_met() else 2.0
	_beacon.light_energy = 1.0 + sin(_t * speed) * 0.8
	if thrusters_on:
		_flame.scale = Vector3(1.0, randf_range(0.8, 1.25), 1.0)
		_flame_light.light_energy = randf_range(2.0, 4.0)


func set_thrusters(on: bool) -> void:
	thrusters_on = on
	_flame.visible = on
	_flame_light.visible = on


func is_in_range(node: Node3D) -> bool:
	return node.global_position.distance_to(global_position) <= interact_radius


func deposit(amount: float) -> void:
	stored += amount
	fuel_changed.emit(stored, quota)


func quota_met() -> bool:
	return stored >= quota - FuelDeposit.EPSILON


func _add_mesh(mesh: Mesh, offset: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = offset
	add_child(mi)
	return mi


func _material(color: Color, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.4
	return mat
