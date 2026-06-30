extends Node3D

const PORT: int = 1027

var peer := ENetMultiplayerPeer.new()

@export var PlayerScene: PackedScene

@export var menu_mapping: GUIDEMappingContext
@export var exit_action: GUIDEAction

@export var MapScene: PackedScene

@onready var player_spawner: PlayerSpawner = $PlayerSpawner

@onready var main_menu: CanvasLayer = $MainMenu
@onready var respawn_menu: CanvasLayer = $RespawnMenu

func _ready() -> void:
	GUIDE.enable_mapping_context(menu_mapping)
	exit_action.triggered.connect(quit_game)
	main_menu.host_connect = create_host
	main_menu.client_connect = create_client

func quit_game() -> void:
	get_tree().quit()

## Start a server instance and spawn as host
func create_host(port: int) -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(player_spawner.spawn_player)
	player_spawner.spawn_player()
	_bind_respawn_action()
	var level = MapScene.instantiate()
	add_child(level,true)

## Create a client instance and connect to server
func create_client(address: String, port: int) -> void:
	peer.create_client(address,port)
	multiplayer.multiplayer_peer = peer
	_bind_respawn_action()

func _bind_respawn_action() -> void:
	respawn_menu.respawn = respawn_player.bind(multiplayer.get_unique_id())

func show_respawn_button() -> void:
	Input.set_mouse_mode.call_deferred(Input.MOUSE_MODE_CONFINED) #TODO: fix NO GRAB error that occurs if calling while window is unfocued
	respawn_menu.show()

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player",id)

@rpc("any_peer","call_local")
func _del_player(id):
	if multiplayer.is_server():
		get_node(str(id)).queue_free()

func respawn_player(id):
	rpc_id(1,"_respawn_player",id)

@rpc("any_peer","call_local")
func _respawn_player(id):
	if multiplayer.is_server():
		get_node(str(id)).respawn()
