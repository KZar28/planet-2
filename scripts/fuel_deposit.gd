class_name FuelDeposit
extends StaticBody3D
## A minable cluster of fuel crystals. Shrinks as it is mined.

signal depleted(deposit: FuelDeposit)

const COLOR := Color(1.0, 0.55, 0.1)

const EPSILON := 0.01

@export var amount := 20.0

var remaining := 0.0
var _visual := Node3D.new()


func _ready() -> void:
	add_to_group("fuel_deposits")
	remaining = amount
	collision_mask = 0
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.4, 0)
	add_child(cs)
	add_child(_visual)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR
	mat.emission_enabled = true
	mat.emission = COLOR
	mat.emission_energy_multiplier = 1.6
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position)
	for i in 6:
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.35, rng.randf_range(0.8, 1.7), 0.35)
		mesh.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(rng.randf_range(-0.5, 0.5), mesh.size.y * 0.4, rng.randf_range(-0.5, 0.5))
		mi.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0, TAU), rng.randf_range(-0.5, 0.5))
		_visual.add_child(mi)
	var glow := OmniLight3D.new()
	glow.light_color = COLOR
	glow.omni_range = 4.0
	glow.light_energy = 0.8
	glow.position = Vector3(0, 1, 0)
	add_child(glow)


## Removes up to `requested` fuel and returns how much was actually taken.
func mine(requested: float) -> float:
	var taken := minf(requested, remaining)
	if remaining - taken < EPSILON:
		taken = remaining  # Don't strand float dust that would never be mined.
	remaining -= taken
	_visual.scale = Vector3.ONE * lerpf(0.35, 1.0, remaining / amount)
	if remaining <= 0.0:
		remove_from_group("fuel_deposits")
		depleted.emit(self)
		queue_free()
	return taken
