extends CharacterBody3D
class_name Player

@export var mapping_context: GUIDEMappingContext

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var player_input: Node = $PlayerInput
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer

func _ready() -> void:
	_initialize_multiplayer.call_deferred()

func _initialize_multiplayer() -> void:
	await get_tree().process_frame
	set_multiplayer_authority(1)
	player_input.set_multiplayer_authority(name.to_int())
	$PlayerCamera.set_multiplayer_authority(name.to_int())
	$PlayerCamera.set_camera_active()
	rollback_synchronizer.process_settings()
	if player_input.is_multiplayer_authority():
		GUIDE.enable_mapping_context(mapping_context)

func _rollback_tick(delta: float, _tick, _is_fresh):
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Handle jump.
		if player_input.is_jumping:
			_jump()
			player_input.is_jumping = false
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := (transform.basis * Vector3(player_input.input_dir.x, 0, player_input.input_dir.y)).normalized()
		direction = direction.rotated(Vector3.UP,$PlayerCamera.rotation.y + rotation.y)
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		velocity *= NetworkTime.physics_factor
		move_and_slide()
		velocity /= NetworkTime.physics_factor

func _jump() -> void:
	velocity.y = JUMP_VELOCITY

func _fire() -> void:
	$PlayerCamera/RayCast3D.force_raycast_update()
	
	if $PlayerCamera/RayCast3D.is_colliding():
		print("hit")
