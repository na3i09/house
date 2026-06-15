extends Camera3D

var rot: Vector3 = Vector3.ZERO

@export var camera_action: GUIDEAction


func _ready() -> void:
	Input.set_mouse_mode.call_deferred(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	rot -= camera_action.value_axis_3d
	rot.x = clampf(rot.x,deg_to_rad(-89),deg_to_rad(89))
	
	rotation = rot
