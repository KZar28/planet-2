class_name DayNight
extends DirectionalLight3D
## The sun orbits the asteroid to simulate its spin. Other systems call
## `light_at()` to find out how lit a point on the surface is.

@export var day_length := 480.0  ## Seconds for one full rotation.
@export var axis := Vector3(0.25, 0.0, 1.0)
## Starting sun angle from the spawn point's zenith. Negative = morning.
@export var start_angle_deg := -50.0

var angle := 0.0
var planet_center := Vector3.ZERO


func _ready() -> void:
	add_to_group("day_night")
	angle = deg_to_rad(start_angle_deg)
	_update_light()


func _process(delta: float) -> void:
	angle = fmod(angle + TAU * delta / day_length, TAU)
	_update_light()


## Unit vector from the planet center toward the sun.
func sun_direction() -> Vector3:
	var a := axis.normalized()
	var noon := (Vector3.UP - a * Vector3.UP.dot(a)).normalized()
	return noon.rotated(a, angle)


## 0 = full night, 1 = full daylight, with a soft terminator band.
func light_at(pos: Vector3) -> float:
	var up := (pos - planet_center).normalized()
	return smoothstep(-0.1, 0.2, up.dot(sun_direction()))


func _update_light() -> void:
	global_basis = Basis.looking_at(-sun_direction(), axis.normalized())
