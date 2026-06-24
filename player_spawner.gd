extends MultiplayerSpawner
class_name PlayerSpawner
## Node for handling spawning of players both on the host and on clients

## Location for players to be spawned into the world
@export var player_spawn_point: Node3D

## [PackedScene] storing the player, assigned from the first scene in the auto spawn list
var PlayerScene: PackedScene

func _ready() -> void:
	if get_spawnable_scene_count() < 1:
		push_error("No player scene set")
	
	PlayerScene = load(get_spawnable_scene(0))

## Spawns the player on the host
func spawn_player(id: int = 1) -> void:
	var player := PlayerScene.instantiate() as Player
	player.name = str(id)
	
	_place_player.call_deferred(player,player_spawn_point)

# place player at location of player spawn point
func _place_player(player: Node3D, spawn_point: Node3D) -> void:
	get_node(spawn_path).add_child(player)
	
	player.global_position = spawn_point.global_position
