extends Node3D
class_name Tracker

@export var player: Player

@export var action: GUIDEAction

@onready var ping_quad: MeshInstance3D = $PingQuad
@onready var scanner: Scanner = $Scanner

func _ready() -> void:
	set_multiplayer_authority(player.name.to_int())
	action.triggered.connect(_fire_tracker)

func _fire_tracker() -> void:
	if is_multiplayer_authority():
		scanner.fire_scan()
		ping_quad.fire_ping()
		get_tree().call_group("Enemies","flash_for_ping")
		player.flash_own_ping.rpc()
