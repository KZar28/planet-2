class_name Player
extends SphereWalker

signal health_changed(current: float, maximum: float)
signal nova_cooldown_changed(remaining: float, total: float)
signal died
signal energy_changed(current: float, maximum: float, light: float)
signal cargo_changed(carried: float, capacity: float)
signal powerups_changed(active: Dictionary)
signal prompt_changed(text: String)
signal launch_requested

const PROJECTILE := preload("res://scenes/projectile.tscn")
const AIM_MASK := 1 | 4  # world + enemies

@export_group("Movement")
@export var move_speed := 9.0
@export var sprint_multiplier := 1.6
@export var acceleration := 12.0
@export var air_control := 0.3
@export var jump_velocity := 12.0
@export var mouse_sensitivity := 0.003

@export_group("Combat")
@export var max_health := 100.0
@export var invulnerability_time := 0.5
@export var fire_cooldown := 0.14
@export var projectile_damage := 25.0
@export var nova_cooldown := 6.0
@export var nova_radius := 9.0
@export var nova_damage := 70.0
@export var spread_angle := 0.14

@export_group("Solar Energy")
@export var max_energy := 100.0
@export var solar_charge_rate := 9.0  ## Per second in full sunlight.
@export var dark_drain_rate := 0.8  ## Per second while in darkness.
@export var sprint_energy_cost := 12.0  ## Per second.
@export var nova_energy_cost := 30.0
@export var mining_energy_cost := 5.0  ## Per second.

@export_group("Mining")
@export var cargo_capacity := 40.0
@export var mining_rate := 4.0  ## Fuel per second.
@export var mining_range := 3.2
@export var cargo_slowdown := 0.3  ## Speed lost at full cargo.

var health := 0.0
var is_dead := false
var energy := 0.0
var cargo := 0.0
var dropship: Dropship
var powerup_timers := {}  # Powerup.Type -> seconds left

var _yaw_input := 0.0
var _pitch := -0.35
var _fire_timer := 0.0
var _nova_timer := 0.0
var _invuln_timer := 0.0
var _body_material: StandardMaterial3D
var _prompt := ""
var _mining_target: FuelDeposit
var _mining_interrupted := false  # Set by damage/attacks; cleared when E is released.
var _panel_material: StandardMaterial3D
var _muzzle: Marker3D
var _shield := MeshInstance3D.new()
var _beam := MeshInstance3D.new()
var _day_night: DayNight

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _rig: CrawlerRig = $Rig


func _ready() -> void:
	super()
	health = max_health
	_body_material = _rig.hull_material
	_panel_material = _rig.panel_material
	_muzzle = _rig.muzzle
	energy = max_energy
	_day_night = get_tree().get_first_node_in_group("day_night") as DayNight
	_build_gear()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_yaw_input -= motion.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, deg_to_rad(-70.0), deg_to_rad(30.0))


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_fire_timer -= delta
	_invuln_timer -= delta
	if _nova_timer > 0.0:
		_nova_timer = maxf(_nova_timer - delta, 0.0)
		nova_cooldown_changed.emit(_nova_timer, nova_cooldown)

	var up := get_up()
	align_to_surface((-global_basis.z).rotated(up, _yaw_input))
	_yaw_input = 0.0
	_camera_pivot.rotation.x = _pitch

	_update_energy(delta)
	_update_powerups(delta)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var rooted := _mining_target != null  # Braced in the mining stance.
	if rooted:
		input = Vector2.ZERO
	var sprinting := Input.is_action_pressed("sprint") and input != Vector2.ZERO and energy > 0.0
	if sprinting:
		_spend_energy(sprint_energy_cost * delta)
	var speed := move_speed * (sprint_multiplier if sprinting else 1.0)
	speed *= 1.0 - cargo_slowdown * cargo / cargo_capacity
	if powerup_timers.has(Powerup.Type.SPEED):
		speed *= 1.5
	var target := global_basis * Vector3(input.x, 0.0, input.y) * speed
	var parts := split_velocity()
	var horizontal: Vector3 = parts[0]
	var vertical: float = parts[1]
	var accel := acceleration if is_on_floor() else acceleration * air_control
	horizontal = horizontal.lerp(target, clampf(accel * delta, 0.0, 1.0))
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not rooted:
			vertical = jump_velocity
	else:
		vertical -= gravity_strength * delta
	move_on_surface(horizontal, vertical)

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
			_fire()
		if Input.is_action_just_pressed("nova") and _nova_timer <= 0.0 and energy >= nova_energy_cost:
			_spend_energy(nova_energy_cost)
			_nova()
	_update_interaction(delta)
	var mine_point := _mining_target.global_position + _mining_target.global_basis.y * 0.6 if _mining_target else Vector3.ZERO
	_rig.animate(delta, split_velocity()[0].length() if is_on_floor() else 0.0, _mining_target != null, mine_point)


func _interrupt_mining() -> void:
	if _mining_target or Input.is_action_pressed("interact"):
		_mining_interrupted = true


func apply_powerup(type: Powerup.Type) -> void:
	powerup_timers[type] = Powerup.INFO[type].duration
	powerups_changed.emit(powerup_timers)
	_flash(Powerup.INFO[type].color)


func _update_energy(delta: float) -> void:
	var light := _day_night.light_at(global_position) if _day_night else 1.0
	energy += solar_charge_rate * light * delta
	if light < 0.2:
		energy -= dark_drain_rate * delta
	energy = clampf(energy, 0.0, max_energy)
	_panel_material.emission_energy_multiplier = light * 1.5
	energy_changed.emit(energy, max_energy, light)


func _spend_energy(amount: float) -> void:
	energy = maxf(energy - amount, 0.0)


func _update_powerups(delta: float) -> void:
	if powerup_timers.is_empty():
		_shield.visible = false
		return
	for type in powerup_timers.keys():
		powerup_timers[type] -= delta
		if powerup_timers[type] <= 0.0:
			powerup_timers.erase(type)
	_shield.visible = powerup_timers.has(Powerup.Type.SHIELD)
	powerups_changed.emit(powerup_timers)


## Deposits cargo at the dropship automatically; E mines nearby fuel or launches.
func _update_interaction(delta: float) -> void:
	var interact := Input.is_action_pressed("interact")
	if not interact:
		_mining_interrupted = false
	var prompt := ""
	_mining_target = null
	if dropship and dropship.is_in_range(self):
		if cargo > 0.0:
			dropship.deposit(cargo)
			cargo = 0.0
			cargo_changed.emit(cargo, cargo_capacity)
		if dropship.quota_met():
			prompt = "Press E to launch to the next asteroid"
			if Input.is_action_just_pressed("interact"):
				launch_requested.emit()
		else:
			prompt = "Dropship: need %d more fuel" % ceili(dropship.quota - dropship.stored)
	else:
		var deposit := _nearest_deposit()
		if deposit:
			if cargo >= cargo_capacity:
				prompt = "Cargo full - return to the dropship"
			elif energy <= 0.0:
				prompt = "Out of energy - get into the sunlight"
			elif interact and _mining_interrupted:
				prompt = "Interrupted - release and press E to mine again"
			elif interact:
				prompt = "Mining..."
				_mining_target = deposit
				_spend_energy(mining_energy_cost * delta)
				cargo += deposit.mine(minf(mining_rate * delta, cargo_capacity - cargo))
				if cargo_capacity - cargo < FuelDeposit.EPSILON:
					cargo = cargo_capacity
				cargo_changed.emit(cargo, cargo_capacity)
			else:
				prompt = "Hold E to mine fuel"
	_update_beam()
	if prompt != _prompt:
		_prompt = prompt
		prompt_changed.emit(prompt)


func _nearest_deposit() -> FuelDeposit:
	var best: FuelDeposit = null
	var best_dist := mining_range
	for deposit: FuelDeposit in get_tree().get_nodes_in_group("fuel_deposits"):
		var dist := deposit.global_position.distance_to(global_position)
		if dist <= best_dist:
			best = deposit
			best_dist = dist
	return best


func _update_beam() -> void:
	_beam.visible = _mining_target != null
	if not _beam.visible:
		return
	var from := _muzzle.global_position
	var to := _mining_target.global_position + _mining_target.global_basis.y * 0.6
	var dir := to - from
	var y := dir.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
	var pulse := 1.0 + 0.4 * sin(Time.get_ticks_msec() * 0.03)
	_beam.global_transform = Transform3D(Basis(x * pulse, y * dir.length(), y.cross(x) * pulse), from + dir * 0.5)


func _build_gear() -> void:
	var shield_mat := StandardMaterial3D.new()
	shield_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.25)
	var shield_mesh := SphereMesh.new()
	shield_mesh.radius = 1.7
	shield_mesh.height = 3.4
	shield_mesh.material = shield_mat
	_shield.mesh = shield_mesh
	_shield.position = Vector3(0, 0.7, 0)
	_shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield.visible = false
	add_child(_shield)

	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.albedo_color = FuelDeposit.COLOR
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.06
	beam_mesh.bottom_radius = 0.06
	beam_mesh.height = 1.0
	beam_mesh.material = beam_mat
	_beam.mesh = beam_mesh
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.top_level = true
	_beam.visible = false
	add_child(_beam)


func take_damage(amount: float) -> void:
	if is_dead or _invuln_timer > 0.0:
		return
	_interrupt_mining()
	if powerup_timers.has(Powerup.Type.SHIELD):
		_flash(Powerup.INFO[Powerup.Type.SHIELD].color)
		return
	health = maxf(health - amount, 0.0)
	_invuln_timer = invulnerability_time
	health_changed.emit(health, max_health)
	_flash(Color(1, 0.2, 0.2))
	if health <= 0.0:
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if is_dead:
		return
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	_flash(Color(0.3, 1, 0.4))


func _fire() -> void:
	_interrupt_mining()
	_fire_timer = fire_cooldown
	var origin := _muzzle.global_position
	var dir := (_get_aim_point() - origin).normalized()
	var damage := projectile_damage * (2.0 if powerup_timers.has(Powerup.Type.DAMAGE) else 1.0)
	var angles := [0.0]
	if powerup_timers.has(Powerup.Type.SPREAD):
		angles = [-spread_angle, 0.0, spread_angle]
	for angle: float in angles:
		var projectile := PROJECTILE.instantiate()
		projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
		get_parent().add_child(projectile)
		projectile.launch(origin, dir.rotated(get_up(), angle), damage)


## The point under the crosshair. The ray starts level with the player so
## terrain between the camera and the player is ignored.
func _get_aim_point() -> Vector3:
	var dir := -_camera.global_basis.z
	var from := _camera.global_position + dir * _camera.global_position.distance_to(global_position)
	var to := from + dir * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to, AIM_MASK, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if hit else to


func _nova() -> void:
	_interrupt_mining()
	_nova_timer = nova_cooldown
	nova_cooldown_changed.emit(_nova_timer, nova_cooldown)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if (enemy as Node3D).global_position.distance_to(global_position) <= nova_radius:
			enemy.take_damage(nova_damage * (2.0 if powerup_timers.has(Powerup.Type.DAMAGE) else 1.0))
	_spawn_nova_effect()


func _spawn_nova_effect() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.4, 0.9, 1.0, 0.5)
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.material = mat
	var effect := MeshInstance3D.new()
	effect.mesh = mesh
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effect.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_parent().add_child(effect)
	effect.global_position = global_position + get_up() * 0.8
	effect.scale = Vector3.ONE * 0.5
	var tween := effect.create_tween().set_parallel()
	tween.tween_property(effect, "scale", Vector3.ONE * nova_radius, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(effect.queue_free)


func _flash(color: Color) -> void:
	_body_material.emission_enabled = true
	_body_material.emission = color
	_body_material.emission_energy_multiplier = 2.0
	create_tween().tween_property(_body_material, "emission_energy_multiplier", 0.0, 0.3)
