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
@export var scan_mode: ScanMode = ScanMode.SWEEP

@export_group("Debug")
@export var debug_beam_adjust: GUIDEAction
@export var debug_beam_mode: GUIDEAction
@export_range(0.5,10.0,0.5,"radians_as_degrees") var debug_beam_adjust_speed: float = deg_to_rad(3.0)

@onready var ping_quad: MeshInstance3D = $PingQuad
@onready var scanner: Scanner = $Scanner

func _ready() -> void:
	set_multiplayer_authority(player.name.to_int())
	if is_multiplayer_authority():
		debug_beam_adjust.triggered.connect(_on_beam_adjust_trigger)
		debug_beam_mode.triggered.connect(_on_beam_mode_cycle)
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

func _on_beam_adjust_trigger() -> void:
	var adjust_value: Vector2 = debug_beam_adjust.value_axis_2d
	scanner.scan_angle_horiz += sign(adjust_value.x) * debug_beam_adjust_speed
	scanner.scan_angle_vert += sign(adjust_value.y) * debug_beam_adjust_speed
	
	print(Vector2(scanner.scan_angle_horiz,scanner.scan_angle_vert))

func _on_beam_mode_cycle() -> void:
	scan_mode = (scan_mode + 1) % 3 as ScanMode
	_set_beam_mode(scan_mode)
	print(scan_mode)
