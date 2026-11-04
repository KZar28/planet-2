class_name FrogRig
extends CreatureRig
## Squat body, big face with a hinged jaw and bulging eyes, and powerful hind
## legs that fold while crouched and kick out behind during a leap.

var body := Node3D.new()
var head := Node3D.new()
var jaw := Node3D.new()
var _belly_material := StandardMaterial3D.new()
var _throat: MeshInstance3D
var _back: Array[Dictionary] = []
var _front: Array[Dictionary] = []
var _time := randf() * 10.0
var _crouch := 0.0
var _air := 0.0
var _land := 0.0
var _snap := 0.0
var _was_airborne := false


func _ready() -> void:
	super()
	_belly_material.albedo_color = body_material.albedo_color.lightened(0.45)
	_belly_material.roughness = 0.8
	add_child(body)
	body.position = Vector3(0, 0.55, 0.1)
	_mesh(body, _sphere(0.55), body_material, Vector3.ZERO, Vector3(1.1, 0.8, 1.15))
	_mesh(body, _sphere(0.5), _belly_material, Vector3(0, -0.15, -0.05), Vector3(0.95, 0.6, 1.0))
	for wart: Vector3 in [Vector3(-0.2, 0.38, 0.1), Vector3(0.22, 0.36, 0.2), Vector3(0.0, 0.42, -0.1), Vector3(0.1, 0.3, 0.4)]:
		_mesh(body, _sphere(0.07), dark_material, wart)

	head.position = Vector3(0, 0.2, -0.45)
	body.add_child(head)
	_mesh(head, _sphere(0.5), body_material, Vector3(0, 0.08, -0.2), Vector3(1.35, 0.6, 1.0))
	_mesh(head, _sphere(0.5), dark_material, Vector3(0, 0.0, -0.24), Vector3(1.25, 0.22, 0.88))
	jaw.position = Vector3(0, 0.0, 0.1)
	head.add_child(jaw)
	_mesh(jaw, _sphere(0.5), _belly_material, Vector3(0, -0.06, -0.3), Vector3(1.3, 0.32, 0.95))
	_throat = _mesh(jaw, _sphere(0.28), _belly_material, Vector3(0, -0.16, -0.38))
	for s: float in [-1.0, 1.0]:
		_mesh(head, _sphere(0.2), body_material, Vector3(s * 0.32, 0.3, -0.25))
		_mesh(head, _sphere(0.16), eye_material, Vector3(s * 0.34, 0.38, -0.32))
		_mesh(head, _sphere(0.07), dark_material, Vector3(s * 0.37, 0.4, -0.46), Vector3(1.0, 0.5, 0.6))

	for s: float in [-1.0, 1.0]:
		_back.append({
			"side": s,
			"thigh": _mesh(self, _segment_mesh(0.17), body_material),
			"shin": _mesh(self, _segment_mesh(0.1), body_material),
			"foot": _mesh(self, _segment_mesh(0.08), dark_material),
			"toes": _mesh(self, _sphere(0.14), dark_material, Vector3.ZERO, Vector3(1.3, 0.35, 1.0)),
		})
		_front.append({
			"side": s,
			"upper": _mesh(self, _segment_mesh(0.07), body_material),
			"lower": _mesh(self, _segment_mesh(0.06), body_material),
			"hand": _mesh(self, _sphere(0.09), dark_material, Vector3.ZERO, Vector3(1.4, 0.4, 1.2)),
		})
	animate(0.0, 0.0, false)


## `crouch` is 0..1 anticipation before a hop; `airborne` is true mid-leap.
func animate(delta: float, crouch: float, airborne: bool) -> void:
	_time += delta
	if _was_airborne and not airborne:
		_land = 1.0
	_was_airborne = airborne
	_crouch = move_toward(_crouch, crouch, delta * 6.0)
	_air = move_toward(_air, 1.0 if airborne else 0.0, delta * 10.0)
	_land = move_toward(_land, 0.0, delta * 4.0)
	_snap = move_toward(_snap, 0.0, delta * 3.0)

	body.position.y = 0.55 - _crouch * 0.18 - _land * 0.12
	body.rotation.x = 0.15 + 0.35 * _air - 0.12 * _crouch
	body.scale = Vector3(1.0 + 0.08 * _land, 1.0 - 0.1 * _land, 1.0)
	head.rotation.x = -0.1 * _crouch + 0.25 * sin(_snap * PI)
	jaw.rotation.x = -0.7 * sin(_snap * PI)
	_throat.scale = Vector3.ONE * (1.0 + 0.15 * sin(_time * 4.0)) * (1.0 - 0.4 * _air)

	for leg: Dictionary in _back:
		var s: float = leg.side
		var hip := body.transform * Vector3(s * 0.45, -0.1, 0.4)
		var knee := Vector3(s * (0.85 + 0.08 * _crouch), 0.5 - 0.12 * _crouch, 0.05).lerp(Vector3(s * 0.55, 0.4, 0.85), _air)
		var ankle := Vector3(s * 0.75, 0.12, 0.65).lerp(Vector3(s * 0.45, 0.25, 1.35), _air)
		var toe := Vector3(s * 0.8, 0.03, 0.1).lerp(Vector3(s * 0.45, 0.2, 1.75), _air)
		_place_segment(leg.thigh, hip, knee)
		_place_segment(leg.shin, knee, ankle)
		_place_segment(leg.foot, ankle, toe)
		(leg.toes as Node3D).position = toe

	for arm: Dictionary in _front:
		var s: float = arm.side
		var shoulder := body.transform * Vector3(s * 0.35, -0.25, -0.4)
		var hand := Vector3(s * 0.5, 0.02, -0.75).lerp(Vector3(s * 0.45, 0.3, -1.0), _air)
		var elbow := (shoulder + hand) * 0.5 + Vector3(s * 0.12, 0.08, 0.05)
		_place_segment(arm.upper, shoulder, elbow)
		_place_segment(arm.lower, elbow, hand)
		(arm.hand as Node3D).position = hand


func attack() -> void:
	_snap = 1.0
