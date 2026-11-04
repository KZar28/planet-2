class_name CrabRig
extends CreatureRig
## Six scuttling legs, eye stalks and two pincers that swing with the gait,
## clack while idle and snap forward on attack.

const LEG_Z := [-0.2, 0.1, 0.38]

@export var steps_per_unit := 0.9
@export var stride_length := 0.22
@export var step_height := 0.18

var body := Node3D.new()
var _legs: Array[Dictionary] = []
var _claws: Array[Dictionary] = []
var _phase := 0.0
var _time := randf() * 10.0
var _move := 0.0
var _snap := 0.0


func _ready() -> void:
	super()
	add_child(body)
	body.position.y = 0.5
	_mesh(body, _sphere(0.5), body_material, Vector3.ZERO, Vector3(1.3, 0.5, 1.0))
	_mesh(body, _sphere(0.35), body_material, Vector3(0, 0.12, 0.05), Vector3(1.0, 0.45, 0.9))
	_mesh(body, _sphere(0.45), dark_material, Vector3(0, -0.08, 0), Vector3(1.2, 0.3, 0.9))

	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.03
	stalk.bottom_radius = 0.04
	stalk.height = 0.3
	for s: float in [-1.0, 1.0]:
		var mi := _mesh(body, stalk, dark_material, Vector3(s * 0.17, 0.25, -0.34))
		mi.rotation.z = -s * 0.25
		_mesh(body, _sphere(0.09), eye_material, Vector3(s * 0.21, 0.41, -0.36))

	for s: float in [-1.0, 1.0]:
		for i in LEG_Z.size():
			_legs.append({
				"side": s, "z": LEG_Z[i],
				"offset": PI * float((i + (0 if s < 0.0 else 1)) % 2),
				"upper": _mesh(self, _segment_mesh(0.05), body_material),
				"lower": _mesh(self, _segment_mesh(0.035), dark_material),
			})

	var finger := CylinderMesh.new()
	finger.top_radius = 0.01
	finger.bottom_radius = 0.06
	finger.height = 0.3
	for s: float in [-1.0, 1.0]:
		var claw := Node3D.new()
		add_child(claw)
		_mesh(claw, _sphere(0.16), body_material, Vector3(0, 0, -0.06), Vector3(0.8, 0.7, 1.3))
		_mesh(claw, finger, body_material, Vector3(0, 0.04, -0.3)).rotation.x = -PI / 2.0
		var hinge := Node3D.new()
		hinge.position = Vector3(0, -0.04, -0.15)
		claw.add_child(hinge)
		_mesh(hinge, finger, dark_material, Vector3(0, 0, -0.13), Vector3(0.8, 0.85, 0.8)).rotation.x = -PI / 2.0
		_claws.append({"side": s, "arm": _mesh(self, _segment_mesh(0.06), body_material), "claw": claw, "hinge": hinge})
	animate(0.0, 0.0)


## `speed` is in the rig's local units per second (world speed / scale).
func animate(delta: float, speed: float) -> void:
	_time += delta
	_move = move_toward(_move, clampf(speed / 2.5, 0.0, 1.0), delta * 5.0)
	_phase = fmod(_phase + speed * delta * steps_per_unit * TAU, TAU)
	_snap = move_toward(_snap, 0.0, delta * 4.0)

	body.position.y = 0.5 + absf(sin(_phase)) * 0.04 * _move + sin(_time * 3.0) * 0.02 * (1.0 - _move)
	body.rotation.z = sin(_phase) * 0.1 * _move
	body.rotation.y = sin(_phase * 0.5) * 0.08 * _move

	for leg: Dictionary in _legs:
		var side: float = leg.side
		var z: float = leg.z
		var p := _phase + float(leg.offset)
		var hip := body.transform * Vector3(side * 0.45, -0.05, z)
		var foot := Vector3(side * 1.0, 0.0, z * 1.3 - sin(p) * stride_length * _move)
		foot.y += maxf(cos(p), 0.0) * step_height * _move
		var knee := (hip + foot) * 0.5 + Vector3(side * 0.15, 0.4, 0.0)
		_place_segment(leg.upper, hip, knee)
		_place_segment(leg.lower, knee, foot)

	var lunge := sin(_snap * PI)
	for c: Dictionary in _claws:
		var side: float = c.side
		var swing := sin(_phase + (0.0 if side < 0.0 else PI)) * _move
		var shoulder := body.transform * Vector3(side * 0.38, 0.0, -0.3)
		var claw: Node3D = c.claw
		claw.position = Vector3(side * (0.55 - 0.15 * lunge), 0.5 + 0.06 * swing + 0.1 * lunge, -0.7 - 0.12 * swing - 0.35 * lunge)
		claw.rotation = Vector3(0.25 * swing, side * 0.25, 0.0)
		_place_segment(c.arm, shoulder, claw.position)
		var clack := maxf(sin(_time * 5.0 + side * 1.3), 0.0)
		var open := (0.12 + 0.2 * clack + 0.3 * absf(swing)) * (1.0 - _snap) + 0.5 * lunge * float(_snap > 0.5)
		(c.hinge as Node3D).rotation.x = -open


func attack() -> void:
	_snap = 1.0
