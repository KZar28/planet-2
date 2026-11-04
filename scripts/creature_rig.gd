class_name CreatureRig
extends Node3D
## Base for procedural enemy visuals. The owner assigns `body_material` (used
## for hit flashes) and `eye_material` (day/night glow) before adding the rig.

var body_material: StandardMaterial3D
var eye_material: StandardMaterial3D
var dark_material := StandardMaterial3D.new()


func _ready() -> void:
	dark_material.albedo_color = body_material.albedo_color.darkened(0.6)
	dark_material.roughness = 0.7


func attack() -> void:
	pass


func _segment_mesh(radius: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	mesh.radial_segments = 8
	return mesh


func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


## Stretches a unit-height Y cylinder between two points in this rig's space.
func _place_segment(mi: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var span := to - from
	var y := span.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(x, y * span.length(), x.cross(y)), from + span * 0.5)


func _mesh(parent: Node3D, mesh: Mesh, material: Material, offset := Vector3.ZERO, scale_by := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = offset
	mi.scale = scale_by
	parent.add_child(mi)
	return mi
