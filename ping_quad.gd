extends MeshInstance3D

@export_group("Settings")
@export var ping_max_range: float = 20.0
@export var ping_time: float = 1.0

var leading_edge_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func fire_ping() -> void:
	set_max_dist(0.0)
	set_min_dist(0.0)
	set_opacity(0.2)
	set_origin_point(owner.global_position) #TODO: change to something less likely to break if node heirearchy is changed
	show()
	if leading_edge_tween:
		leading_edge_tween.kill()
	
	leading_edge_tween = create_tween()
	
	leading_edge_tween.tween_method(set_max_dist,0.0,ping_max_range,0.8)
	leading_edge_tween.parallel()
	leading_edge_tween.tween_method(set_opacity,0.2,1.0,0.6)
	leading_edge_tween.tween_interval(ping_time)
	leading_edge_tween.tween_method(set_min_dist,0.0,ping_max_range,1.2)
	leading_edge_tween.parallel()
	leading_edge_tween.tween_method(set_opacity,1.0,0.0,1.2)
	leading_edge_tween.tween_callback(hide)

func set_max_dist(val: float) -> void:
	set_instance_shader_parameter("max_dist",val)

func set_min_dist(val: float) -> void:
	set_instance_shader_parameter("min_dist",val)

func set_opacity(val: float) -> void:
	set_instance_shader_parameter("opacity",val)

func set_origin_point(val: Vector3) -> void:
	set_instance_shader_parameter("origin_point",val)
