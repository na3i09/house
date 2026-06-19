extends Node3D
class_name Temperature

@export var max_temperature: float = 100.0

@export var stationary_drain_rate: float = 1.0
@export var moving_drain_rate: float = 0.3

@onready var temperature: float = max_temperature

@onready var player: Player = owner if owner is Player else null

@onready var last_position: Vector3 = global_position

func _rollback_tick(delta: float, _tick, _is_fresh):
	if is_multiplayer_authority():
		if last_position.distance_to(global_position) < 0.5:
			temperature -= stationary_drain_rate * delta
		else:
			temperature -= moving_drain_rate * delta
		
		last_position = global_position
		
		if temperature < 10.0:
			if player:
				_cold_message.rpc_id(player.name.to_int())
			temperature = 90.0

@rpc("authority","call_local")
func _cold_message() -> void:
	print("you are very cold")
