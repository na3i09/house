extends CharacterBody3D
class_name Player

@export var mapping_context: GUIDEMappingContext
@export var debug_context: GUIDEMappingContext
@export var GhostScene: PackedScene

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var player_input: PlayerInput = $PlayerInput
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var temperature: Temperature = $Temperature
@onready var player_camera: Camera3D = $PlayerCamera


@onready var player_hud: CanvasLayer = $PlayerHud

var alive: bool = true

func _ready() -> void:
	_initialize_multiplayer.call_deferred()

func _initialize_multiplayer() -> void:
	await get_tree().process_frame
	set_multiplayer_authority(1)
	player_input.set_multiplayer_authority(name.to_int())
	player_camera.set_multiplayer_authority(name.to_int())
	$PlayerLocationUpdater.set_multiplayer_authority(name.to_int())
	player_camera.set_camera_active()
	if multiplayer.get_unique_id() != name.to_int():
		player_hud.queue_free()
		add_to_group("Enemies")
		$PlayerCamera/RiflePivot.hide()
		$NonPlayerRiflePivot.show()
	rollback_synchronizer.process_settings()
	tick_interpolator.process_settings()
	if player_input.is_multiplayer_authority():
		GUIDE.enable_mapping_context(mapping_context)
		GUIDE.enable_mapping_context(debug_context)

func _rollback_tick(delta: float, _tick, _is_fresh):
	if is_multiplayer_authority() and alive:
		var speed: float = SPEED
		
		if temperature.temperature < temperature.very_cold_limit:
			speed *= 0.6
		
		# Add the gravity.
		_force_update_is_on_floor()
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Handle jump.
		if player_input.is_jumping:
			_jump()
			player_input.is_jumping = false
		
		$NonPlayerRiflePivot.transform = player_camera.transform
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := (transform.basis * Vector3(player_input.input_dir.x, 0, player_input.input_dir.y)).normalized()
		direction = direction.rotated(Vector3.UP,player_camera.rotation.y + rotation.y)
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

		velocity *= NetworkTime.physics_factor
		move_and_slide()
		velocity /= NetworkTime.physics_factor
	elif is_multiplayer_authority():
		global_position = Vector3(0,20,0)

func _force_update_is_on_floor() -> void:
	var old_velocity: Vector3 = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity

func _jump() -> void:
	velocity.y = JUMP_VELOCITY

func die() -> void:
	rpc("kill_player")

@rpc("any_peer","call_local")
func kill_player() -> void:
	if multiplayer.get_unique_id() == name.to_int():
		print(name + " you are dead")
		$"../".show_respawn_button()
	
	alive = false
	hide()

func respawn() -> void:
	rpc("respawn_player")

@rpc("authority","call_local")
func respawn_player() -> void:
	player_camera.set_camera_active()
	temperature.reset()
	alive = true
	show()

func flash_for_ping() -> void:
	var ghost = GhostScene.instantiate()
	
	get_tree().get_root().add_child(ghost)
	
	ghost.global_position = $MeshInstance3D.global_position

@rpc("any_peer","call_remote")
func flash_own_ping() -> void:
	flash_for_ping()
