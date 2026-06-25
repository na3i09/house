extends Node3D
class_name Scanner

@export_range(0.0,150.0,0.1,"or_greater","suffix:m") var scan_distance: float = 15.0
@export_range(0.0,30.0,0.01,"radians_as_degrees") var scan_angle_delta: float = deg_to_rad(1.0)
@export_range(0.0,30.0,0.01,"radians_as_degrees") var scan_angle_variation: float = deg_to_rad(1.0)


@export_range(0.0,180.0,0.1,"radians_as_degrees") var scan_angle_vert: float = deg_to_rad(90.0):
	set(value):
		scan_angle_vert = clamp(value,deg_to_rad(0.0),deg_to_rad(180.0))
@export_range(0.0,180.0,0.1,"radians_as_degrees") var scan_angle_horiz: float = deg_to_rad(90.0):
	set(value):
		scan_angle_horiz = clamp(value,deg_to_rad(0.0),deg_to_rad(180.0))

@export var instant: bool = false

## Change direction of scan from bottom to top to right to left
@export var switch_scan_direction: bool = false

@export var scan_speed: int = 5
@export_range(1,3,1) var continuous_scan_multiplier: int = 1

@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

var x_angle: float = 0
var y_angle: float = 0


func _ready() -> void:
	set_physics_process(false)

func fire_scan() -> void:
	if instant:
		_scan_loop()
	else:
		_begin_scan()

func _begin_scan() -> void:
	set_physics_process(true)
	gpu_particles_3d.restart()
	x_angle = -scan_angle_horiz/2
	y_angle = -scan_angle_vert/2

func _physics_process(_delta: float) -> void:
	if x_angle < scan_angle_horiz/2:
		if y_angle < scan_angle_vert/2:
			for i in range(scan_speed):
				_cast_beam(x_angle,y_angle)
				
				y_angle += scan_angle_delta
				if y_angle >= scan_angle_vert/2:
					break
		else:
			y_angle = -scan_angle_vert/2
			x_angle += scan_angle_delta
	else:
		_finish_loop()

func _finish_loop() -> void:
	set_physics_process(false)

func _scan_loop() -> void:
	gpu_particles_3d.restart()
	x_angle = -scan_angle_horiz/2
	while x_angle < scan_angle_horiz/2:
		y_angle = -scan_angle_vert/2
		while y_angle < scan_angle_vert/2:
			
			_cast_beam(x_angle,y_angle)
			
			y_angle += scan_angle_delta
		
		x_angle += scan_angle_delta

func _calc_ray_end(horiz_angle: float,vert_angle: float) -> Vector3:
	var end_point: Vector3 = global_transform * (basis.z.rotated(
				Vector3.UP,vert_angle + randf_range(-scan_angle_variation,scan_angle_variation)).rotated(
					Vector3.RIGHT,horiz_angle + randf_range(-scan_angle_variation,scan_angle_variation)).normalized() * -scan_distance)
	
	return end_point

func _scan(ray_start: Vector3, ray_end: Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start,ray_end)
	var result = space_state.intersect_ray(query)
	
	return result

func cast_random_beam() -> void:
	for i in range(continuous_scan_multiplier):
		_cast_beam(randf_range(-scan_angle_horiz/2,scan_angle_horiz/2),
				randf_range(-scan_angle_vert/2,scan_angle_vert/2))

func _cast_beam(horiz_angle: float,vert_angle: float) -> void:
	var end_point: Vector3 = _calc_ray_end(vert_angle,horiz_angle) if switch_scan_direction else _calc_ray_end(horiz_angle,vert_angle)
	
	var result: Dictionary = _scan(global_position,end_point)
	
	if not result.is_empty():
		gpu_particles_3d.emit_particle(Transform3D(global_basis,result["position"]),Vector3.ZERO,Color.BLUE,Color.ALICE_BLUE,GPUParticles3D.EmitFlags.EMIT_FLAG_POSITION)
