extends Node3D
class_name Tracker

enum ScanMode {
	SWEEP,
	INSTANT,
	CONTINUOUS,
}

@export var player: Player

@export var action: GUIDEAction

@export_group("Settings")
@export var enable_scan: bool = true
@export var enable_ping: bool = false
@export_enum("Sweep","Instant","Continuous") var scan_mode: int

@onready var ping_quad: MeshInstance3D = $PingQuad
@onready var scanner: Scanner = $Scanner

func _ready() -> void:
	set_multiplayer_authority(player.name.to_int())
	_set_beam_mode(scan_mode)

func _set_beam_mode(_scan_mode: ScanMode) -> void:
	if action.triggered.is_connected(_fire_beam):
		action.triggered.disconnect(_fire_beam)
	if action.just_triggered.is_connected(_fire_tracker):
		action.just_triggered.disconnect(_fire_tracker)
	match _scan_mode:
		ScanMode.SWEEP:
			action.just_triggered.connect(_fire_tracker)
			scanner.instant = false
		ScanMode.INSTANT:
			action.just_triggered.connect(_fire_tracker)
			scanner.instant = true
		ScanMode.CONTINUOUS:
			action.triggered.connect(_fire_beam)

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
