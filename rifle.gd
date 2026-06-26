extends NetworkWeaponHitscan3D
class_name Rifle

@export var fire_action: GUIDEAction
@export var reload_action: GUIDEAction

@export var player: Player
@onready var player_peer_id: int = player.name.to_int()

var get_ammo: Callable
var consume_ammo: Callable
var reload_ammo: Callable

var current_ammo: int = 4:
	get = get_current_ammo

func get_current_ammo() -> int:
	return current_ammo

@export_group("Settings")
@export var ammo_type: AmmoType

@export var magazine_size: int = 4
@export_range(0.1,10.0,0.1) var fire_rate: float = 1.5:
	set(value):
		fire_rate = clampf(value,0.1,10.0)
		firing_cycle_time = 1.0/fire_rate
@onready var firing_cycle_time: float = 1.0/fire_rate

func _ready() -> void:
	fire_action.just_triggered.connect(fire)
	reload_action.just_triggered.connect(player_reload)

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == player_peer_id

func _can_fire() -> bool:
	if $Timer.is_stopped() and $ReloadTimer.is_stopped():
		if get_current_ammo.call() > 0:
			return multiplayer.get_unique_id() == player_peer_id
		else:
			return false
	else:
		return false

func _on_fire():
	if multiplayer.get_unique_id() == player_peer_id:
		print("bang")
		#consume_ammo.call(1)
		$AnimationPlayer.play("fire")
		$Timer.start(firing_cycle_time)
		if current_ammo > 0:
			current_ammo -= 1
		if current_ammo == 0:
			auto_reload.call_deferred()

func _on_hit(result: Dictionary) -> void:
	if result["collider"] is Player:
		var hit_target: Player = result["collider"]
		if multiplayer.is_server():
			hit_target.die()
		if multiplayer.get_unique_id() == player_peer_id:
			print("hit " + hit_target.name)

func fire() -> bool:
	if not can_fire():
		return false
	
	reproduce_fire.rpc()
	return true

func player_reload() -> void:
	if multiplayer.get_unique_id() == player_peer_id:
		reload()

@rpc("any_peer","reliable","call_local")
func reproduce_fire() -> void:
	_apply_data(_get_data())
	_after_fire()
	pass

func auto_reload() -> void:
	await $Timer.timeout
	reload()

func reload() -> void:
	$AnimationPlayer.play("reload")
	$ReloadTimer.start()
	current_ammo += reload_ammo.call(magazine_size - current_ammo)
