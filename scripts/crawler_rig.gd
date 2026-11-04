class_name CrawlerRig
extends Node3D
## Procedural six-legged crawler body for the player. Tripod gait while moving,
## a gentle bob while idle, and a crouched, splayed stance while mining.

const HIPS := [
	Vector3(-0.42, -0.05, -0.38), Vector3(0.42, -0.05, 0.0), Vector3(-0.42, -0.05, 0.38),
	Vector3(0.42, -0.05, -0.38), Vector3(-0.42, -0.05, 0.0), Vector3(0.42, -0.05, 0.38),
]  # First three legs form one tripod, last three the other.

@export var ride_height := 0.75
@export var stance_height := 0.45
@export var upper_length := 0.85
@export var lower_length := 1.0
@export var foot_spread := 1.45
@export var stance_spread := 1.75
@export var stride_length := 0.35
@export var step_height := 0.28
@export var steps_per_unit := 0.55  ## Gait cycles per metre travelled.

var hull_material := StandardMaterial3D.new()
var panel_material := StandardMaterial3D.new()
var hull := Node3D.new()
var turret := Node3D.new()
var muzzle := Marker3D.new()
var _barrels := Node3D.new()
var _dark_material: StandardMaterial3D
var _glow_material: StandardMaterial3D

var _legs: Array[Dictionary] = []
var _phase := 0.0
var _time := 0.0
var _move := 0.0
var _stance := 0.0


func _ready() -> void:
	hull_material.albedo_color = Color(0.78, 0.8, 0.84)
	hull_material.metallic = 0.6
	hull_material.roughness = 0.35
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.17, 0.2)
	dark.metallic = 0.7
	dark.roughness = 0.4
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(1.0, 0.55, 0.15)
	accent.roughness = 0.5
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.05, 0.05, 0.1)
	glow.emission_enabled = true
	glow.emission = Color(0.3, 0.9, 1.0)
	glow.emission_energy_multiplier = 2.0
	panel_material.albedo_color = Color(0.1, 0.15, 0.4)
	panel_material.metallic = 0.8
	panel_material.roughness = 0.2
	panel_material.emission_enabled = true
	panel_material.emission = Color(0.3, 0.6, 1.0)

	hull.position.y = ride_height
	add_child(hull)
	var dome := SphereMesh.new()
	dome.radius = 0.6
	dome.height = 1.2
	_mesh(hull, dome, hull_material, Vector3.ZERO, Vector3(1.0, 0.5, 1.25))
	var belly := CylinderMesh.new()
	belly.top_radius = 0.55
	belly.bottom_radius = 0.4
	belly.height = 0.18
	_mesh(hull, belly, dark, Vector3(0, -0.12, 0), Vector3(1.0, 1.0, 1.2))
	var stripe := BoxMesh.new()
	stripe.size = Vector3(0.08, 0.04, 1.2)
	_mesh(hull, stripe, accent, Vector3(0, 0.29, 0))
	var visor := BoxMesh.new()
	visor.size = Vector3(0.5, 0.1, 0.12)
	_mesh(hull, visor, glow, Vector3(0, 0.08, -0.68))
	var panel := BoxMesh.new()
	panel.size = Vector3(0.9, 0.05, 0.6)
	var panel_mi := _mesh(hull, panel, panel_material, Vector3(0, 0.36, 0.25))
	panel_mi.rotation.x = deg_to_rad(-15.0)

	turret.position = Vector3(0, 0.22, -0.5)
	hull.add_child(turret)
	var mount := SphereMesh.new()
	mount.radius = 0.16
	mount.height = 0.32
	_mesh(turret, mount, dark, Vector3.ZERO)
	_dark_material = dark
	_glow_material = glow
	turret.add_child(_barrels)
	set_gun_count(1)
	muzzle.position = Vector3(0, 0, -0.68)
	turret.add_child(muzzle)

	var upper := CylinderMesh.new()
	upper.top_radius = 0.07
	upper.bottom_radius = 0.05
	upper.height = 1.0
	var lower := CylinderMesh.new()
	lower.top_radius = 0.045
	lower.bottom_radius = 0.025
	lower.height = 1.0
	var joint := SphereMesh.new()
	joint.radius = 0.08
	joint.height = 0.16
	for i in HIPS.size():
		var leg := {
			"hip": HIPS[i],
			"side": signf(HIPS[i].x),
			"offset": 0.0 if i < 3 else PI,
			"upper": _mesh(self, upper, hull_material, Vector3.ZERO),
			"lower": _mesh(self, lower, dark, Vector3.ZERO),
			"knee": _mesh(self, joint, accent, Vector3.ZERO),
		}
		_legs.append(leg)
	animate(0.0, 0.0, false, Vector3.ZERO)


## speed: ground speed in m/s. mine_target: global point the laser hits.
const GUN_SPACING := 0.2


## Lateral offset of barrel `index` out of `count`, centred on the turret.
static func gun_offset(index: int, count: int) -> float:
	return (index - (count - 1) * 0.5) * GUN_SPACING


func set_gun_count(count: int) -> void:
	for child in _barrels.get_children():
		child.queue_free()
	for i in count:
		var x := gun_offset(i, count)
		var barrel := CylinderMesh.new()
		barrel.top_radius = 0.05
		barrel.bottom_radius = 0.07
		barrel.height = 0.6
		var barrel_mi := _mesh(_barrels, barrel, _dark_material, Vector3(x, 0, -0.3))
		barrel_mi.rotation.x = deg_to_rad(90.0)
		var tip := SphereMesh.new()
		tip.radius = 0.06
		tip.height = 0.12
		_mesh(_barrels, tip, _glow_material, Vector3(x, 0, -0.6))


func animate(delta: float, speed: float, mining: bool, mine_target: Vector3) -> void:
	_time += delta
	_move = move_toward(_move, clampf(speed / 3.0, 0.0, 1.0), delta * 4.0)
	_stance = move_toward(_stance, 1.0 if mining else 0.0, delta * 5.0)
	_phase = fmod(_phase + speed * delta * steps_per_unit * TAU, TAU)

	var idle_bob := sin(_time * 2.6) * 0.035 * (1.0 - _move) * (1.0 - _stance)
	var walk_bob := absf(sin(_phase)) * 0.05 * _move
	var mining_shake := sin(_time * 55.0) * 0.012 * _stance
	hull.position.y = lerpf(ride_height, stance_height, _stance) + idle_bob + walk_bob + mining_shake
	hull.rotation.x = lerpf(sin(_phase * 2.0) * 0.03 * _move, -0.12, _stance)
	hull.rotation.z = sin(_phase) * 0.04 * _move

	if mining:
		turret.look_at(mine_target, global_basis.y)
	else:
		turret.rotation = turret.rotation.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))

	var spread := lerpf(foot_spread, stance_spread, _stance)
	for leg: Dictionary in _legs:
		var hip_local: Vector3 = leg.hip
		var side: float = leg.side
		var p := _phase + float(leg.offset)
		var foot := Vector3(side * spread, 0.0, hip_local.z * lerpf(1.4, 1.6, _stance))
		foot.z -= sin(p) * stride_length * _move
		foot.y += maxf(cos(p), 0.0) * step_height * _move
		var hip := hull.transform * hip_local
		_solve_leg(leg, hip, foot)


func _solve_leg(leg: Dictionary, hip: Vector3, foot: Vector3) -> void:
	var to_foot := foot - hip
	var d := clampf(to_foot.length(), 0.05, upper_length + lower_length - 0.01)
	var dir := to_foot.normalized()
	var along := (upper_length * upper_length - lower_length * lower_length + d * d) / (2.0 * d)
	var lift := sqrt(maxf(upper_length * upper_length - along * along, 0.0))
	var bend := Vector3.UP + Vector3(float(leg.side) * 0.8, 0.0, 0.0)
	bend = (bend - dir * bend.dot(dir)).normalized()
	var knee := hip + dir * along + bend * lift
	var end := hip + dir * d
	_place_segment(leg.upper, hip, knee)
	_place_segment(leg.lower, knee, end)
	(leg.knee as Node3D).position = knee


func _place_segment(mi: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var span := to - from
	var y := span.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(x, y * span.length(), y.cross(x)), from + span * 0.5)


func _mesh(parent: Node3D, mesh: Mesh, material: Material, offset: Vector3, scale_by := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = offset
	mi.scale = scale_by
	parent.add_child(mi)
	return mi
