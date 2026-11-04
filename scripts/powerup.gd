class_name Powerup
extends Area3D
## A temporary buff that appears on the night side.

enum Type { SHIELD, SPEED, DAMAGE, SPREAD }

const INFO := {
	Type.SHIELD: {"name": "Shield", "color": Color(0.3, 0.7, 1.0), "duration": 8.0},
	Type.SPEED: {"name": "Speed Boost", "color": Color(0.3, 1.0, 0.45), "duration": 10.0},
	Type.DAMAGE: {"name": "Double Damage", "color": Color(1.0, 0.3, 0.3), "duration": 10.0},
	Type.SPREAD: {"name": "Spread Shot", "color": Color(1.0, 0.85, 0.2), "duration": 12.0},
}

@export var type: Type = Type.SHIELD
@export var lifetime := 30.0

var _visual := MeshInstance3D.new()
var _t := 0.0


func _ready() -> void:
	add_to_group("powerups")
	collision_layer = 0
	collision_mask = 2  # player
	var shape := SphereShape3D.new()
	shape.radius = 1.3
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 1, 0)
	add_child(cs)

	var color: Color = INFO[type].color
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.6
	mesh.material = mat
	_visual.mesh = mesh
	_visual.rotation = Vector3(PI / 4, 0, PI / 4)
	add_child(_visual)
	var glow := OmniLight3D.new()
	glow.light_color = color
	glow.omni_range = 3.5
	glow.position = Vector3(0, 1, 0)
	add_child(glow)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	_visual.rotate_y(2.0 * delta)
	_visual.position.y = 1.0 + sin(_t * 3.0) * 0.2
	_visual.visible = lifetime > 5.0 or fmod(_t, 0.4) < 0.25


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).apply_powerup(type)
		queue_free()
