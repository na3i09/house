extends Node3D
class_name Temperature

@export var max_temperature: float = 100.0

@export var stationary_drain_rate: float = 1.0
@export var moving_drain_rate: float = 0.3

@onready var temperature: float = max_temperature:
	set(value):
		temperature = clamp(value,0.0,max_temperature)

@onready var player: Player = owner if owner is Player else null

@onready var temp_monitoring_area: Area3D = $TempMonitoringArea


func _rollback_tick(delta: float, _tick, _is_fresh):
	if is_multiplayer_authority() and player.alive:
		if temp_monitoring_area.has_overlapping_areas():
			for area in temp_monitoring_area.get_overlapping_areas():
				if area is HeatingArea:
					temperature += area.heat_level * delta
			return
		
		
		if player.velocity.length() < 0.1:
			temperature -= stationary_drain_rate * delta
		else:
			temperature -= moving_drain_rate * delta
		
		if temperature < 10.0:
			if player:
				_cold_message.rpc_id(player.name.to_int())
			temperature = 90.0

@rpc("authority","call_local")
func _cold_message() -> void:
	print("you are very cold")
