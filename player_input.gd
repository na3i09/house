extends Node
class_name PlayerInput

@export var movement_action: GUIDEAction
@export var jump_action: GUIDEAction

@export var _rollback_synchronizer: RollbackSynchronizer

var input_dir_buffer: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO
var input_samples: int = 0

var is_jumping: bool = false
var is_jumping_buffer: bool = false

var confidence: float = 1.0

func _ready() -> void:
	assert(_rollback_synchronizer, "Synchronizer not assigned")
	NetworkTime.after_tick.connect(_gather_always.unbind(2))
	NetworkTime.before_tick_loop.connect(_gather)
	NetworkRollback.after_prepare_tick.connect(_predict.unbind(1))
	jump_action.just_triggered.connect(_jump)

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

func _jump() -> void:
	is_jumping_buffer = true

func _predict() -> void:
	if not _rollback_synchronizer.is_predicting():
		confidence = 1.
		return
	
	if not _rollback_synchronizer.has_input():
		confidence = 0.
		return
	
	# Decay input over a short time
	var decay_time := NetworkTime.seconds_to_ticks(0.15)
	var input_age := _rollback_synchronizer.get_input_age()
	
	confidence = input_age / float(decay_time)
	confidence = clampf(1.0 - confidence, 0.0, 1.0)
