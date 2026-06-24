extends Node3D

const PORT: int = 1027

var peer = ENetMultiplayerPeer.new()

@export var PlayerScene: PackedScene

@export var menu_mapping: GUIDEMappingContext
@export var exit_action: GUIDEAction

@onready var player_spawner: PlayerSpawner = $PlayerSpawner


func _ready() -> void:
	GUIDE.enable_mapping_context(menu_mapping)
	exit_action.triggered.connect(quit_game)

func quit_game() -> void:
	get_tree().quit()

## Start a server instance and spawn as host
func create_host(port: int) -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(player_spawner.spawn_player)
	player_spawner.spawn_player()

## Create a client instance and connect to server
func create_client(address: String, port: int) -> void:
	peer.create_client(address,port)
	multiplayer.multiplayer_peer = peer

func _on_host_button_pressed() -> void:
	create_host(PORT)
	
	$MainMenu.hide()

func _on_client_button_pressed() -> void:
	show_ip_address_input()

func show_ip_address_input() -> void:
	$MainMenu/LineEdit.visible = true
	$MainMenu/LineEdit.grab_focus()

func show_respawn_button() -> void:
	Input.set_mouse_mode.call_deferred(Input.MOUSE_MODE_CONFINED) #TODO: fix NO GRAB error that occurs if calling while window is unfocued
	$RespawnMenu.show()

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

func _on_line_edit_text_submitted(new_text: String) -> void:
	create_client(new_text,PORT)
	
	$MainMenu.hide()

func _on_respawn_pressed() -> void:
	$RespawnMenu.hide()
	respawn_player(multiplayer.get_unique_id())
