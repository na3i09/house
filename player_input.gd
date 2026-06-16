extends Node
class_name PlayerInput

@export var movement_action: GUIDEAction
@export var jump_action: GUIDEAction
@export var fire_action: GUIDEAction

var input_dir_buffer: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var input_samples: int = 0

var is_jumping: bool = false
var is_jumping_buffer: bool = false

var fire_buffer: bool = false
var fire: bool = false

func _ready() -> void:
	NetworkTime.after_tick.connect(_gather_always.unbind(2))
	NetworkTime.before_tick_loop.connect(_gather)
	jump_action.just_triggered.connect(_jump)
	fire_action.triggered.connect(_fire)

func _process(_delta: float) -> void:
	input_dir_buffer += movement_action.value_axis_2d
	input_samples += 1

func _gather():
	if not is_multiplayer_authority():
		return
	
	if input_samples > 0:
		input_dir = input_dir_buffer / input_samples
	else:
		input_dir = Vector2.ZERO
	
	input_dir_buffer = Vector2.ZERO
	input_samples = 0

func _gather_always() -> void:
	if not is_multiplayer_authority():
		return
	
	is_jumping = is_jumping_buffer
	is_jumping_buffer = false
	
	fire = fire_buffer
	fire_buffer = false

func _jump() -> void:
	is_jumping_buffer = true

func _fire() -> void:
	fire_buffer = true
