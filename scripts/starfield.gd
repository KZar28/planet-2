extends MultiMeshInstance3D
## A shell of tiny unlit quads far from the planet to give the sky some stars.

@export var star_count := 1500
@export var distance := 600.0
@export var star_seed := 42


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 1.6
	quad.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = star_count
	for i in star_count:
		var dir := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var s := rng.randf_range(0.5, 1.8)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * s), dir * distance))
		var b := rng.randf_range(0.6, 1.0)
		mm.set_instance_color(i, Color(b, b, rng.randf_range(b, 1.0)))
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
