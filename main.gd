extends Node3D

const PORT: int = 1027

var peer = ENetMultiplayerPeer.new()

@export var Player: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	_spawn_player()


func _spawn_player(id: int = 1) -> void:
	var player = Player.instantiate()
	player.peer_id = id
	add_child(player)
	
	player.global_position = $PlayerSpawnPoint.global_position
