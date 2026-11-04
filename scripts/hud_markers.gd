extends Control
## Draws world-space waypoints: the dropship (always; pinned to the screen edge
## when off-screen) and fuel deposits that are on screen and not behind the asteroid.

const EDGE_MARGIN := 40.0
const TOP_MARGIN := 150.0  # Keeps edge arrows clear of the HUD panels.

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
	var from := camera.global_position
	var label := "%s %dm" % [text, roundi(from.distance_to(pos))]
	var behind := camera.is_position_behind(pos)
	var screen := Vector2.ZERO if behind else camera.unproject_position(pos)
	var bounds := Rect2(EDGE_MARGIN, TOP_MARGIN, size.x - 2.0 * EDGE_MARGIN, size.y - TOP_MARGIN - EDGE_MARGIN)
	var on_screen := not behind and (bounds if always else get_rect()).has_point(screen)
	if not always and (not on_screen or _blocked_by_planet(from, pos)):
		return
	if on_screen:
		draw_circle(screen, 5.0, color)
		draw_string(get_theme_default_font(), screen + Vector2(-60, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 14, color)
		return
	# Off-screen or behind the camera: pin an arrow to the screen edge pointing at it.
	var center := bounds.get_center()
	var local := camera.global_transform.affine_inverse() * pos
	var dir := Vector2(local.x, -local.y) if behind else screen - center
	if dir.length_squared() < 0.001:
		dir = Vector2.DOWN
	dir = dir.normalized()
	var half := bounds.size * 0.5
	var reach := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
	var tip := center + dir * reach
	var side := dir.orthogonal() * 9.0
	draw_colored_polygon(PackedVector2Array([tip + dir * 12.0, tip + side, tip - side]), color)
	draw_string(get_theme_default_font(), tip - dir * 22.0 + Vector2(-60, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 14, color)


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
