extends NetworkWeaponHitscan3D
class_name Rifle

@export var fire_action: GUIDEAction

@export var player: Player
@onready var player_peer_id: int = player.name.to_int()

func _ready() -> void:
	fire_action.just_triggered.connect(fire)

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == player_peer_id

func _can_fire() -> bool:
	return multiplayer.get_unique_id() == player_peer_id

func _on_fire():
	if multiplayer.get_unique_id() == player_peer_id:
		print("bang")

func _on_hit(result: Dictionary) -> void:
	if result["collider"] is Player:
		var hit_target: Player = result["collider"]
		hit_target.die()
		if multiplayer.get_unique_id() == player_peer_id:
			print("hit " + hit_target.name)
