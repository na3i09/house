extends Node3D
class_name Tracker

@export var player: Player

@export var action: GUIDEAction

@export_group("Settings")
@export var continuous_scan: bool = false
@export var enable_scan: bool = true
@export var enable_ping: bool = false

@onready var ping_quad: MeshInstance3D = $PingQuad
@onready var scanner: Scanner = $Scanner

func _ready() -> void:
	set_multiplayer_authority(player.name.to_int())
	if continuous_scan:
		action.triggered.connect(_fire_beam)
	else:
		action.just_triggered.connect(_fire_tracker)

func _fire_tracker() -> void:
	if is_multiplayer_authority():
		if enable_scan:
			scanner.fire_scan()
		if enable_ping:
			ping_quad.fire_ping()
		get_tree().call_group("Enemies","flash_for_ping")
		player.flash_own_ping.rpc()

func _fire_beam() -> void:
	if is_multiplayer_authority():
		scanner.cast_random_beam()
