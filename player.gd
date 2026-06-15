extends CharacterBody3D

@export var mapping_context: GUIDEMappingContext

@export var movement_action: GUIDEAction
@export var jump_action: GUIDEAction

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
	GUIDE.enable_mapping_context(mapping_context)
	jump_action.just_triggered.connect(_jump)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir: Vector2 = movement_action.value_axis_2d
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP,$PlayerCamera.rotation.y + rotation.y)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
