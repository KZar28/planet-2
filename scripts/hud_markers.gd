extends Control
## Draws world-space waypoints: the dropship (always) and fuel deposits that
## aren't hidden behind the asteroid.

@export var planet_radius := 40.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var dropship := get_tree().get_first_node_in_group("dropship") as Node3D
	if dropship:
		_marker(camera, dropship.global_position + dropship.global_basis.y * 7.0, Color(0.4, 0.8, 1.0), "DROPSHIP", true)
	for deposit: Node3D in get_tree().get_nodes_in_group("fuel_deposits"):
		_marker(camera, deposit.global_position + deposit.global_basis.y * 2.0, FuelDeposit.COLOR, "FUEL", false)


func _marker(camera: Camera3D, pos: Vector3, color: Color, text: String, always: bool) -> void:
	if camera.is_position_behind(pos):
		return
	var from := camera.global_position
	if not always and _blocked_by_planet(from, pos):
		return
	var screen := camera.unproject_position(pos)
	draw_circle(screen, 5.0, color)
	var label := "%s %dm" % [text, roundi(from.distance_to(pos))]
	draw_string(get_theme_default_font(), screen + Vector2(-60, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 14, color)


func _blocked_by_planet(from: Vector3, to: Vector3) -> bool:
	var d := to - from
	var r := planet_radius - 0.5
	var a := d.dot(d)
	var b := 2.0 * from.dot(d)
	var c := from.dot(from) - r * r
	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return false
	var t := (-b - sqrt(disc)) / (2.0 * a)
	return t > 0.0 and t < 1.0
