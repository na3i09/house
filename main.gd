extends Node3D

const PORT: int = 1027

var peer = ENetMultiplayerPeer.new()

@export var Player: PackedScene

@export var menu_mapping: GUIDEMappingContext
@export var exit_action: GUIDEAction

func _ready() -> void:
	GUIDE.enable_mapping_context(menu_mapping)
	exit_action.triggered.connect(quit_game)

func _spawn_player(id: int = 1) -> void:
	var player = Player.instantiate()
	player.name = str(id)
	
	_place_player.call_deferred(player,$PlayerSpawnPoint)

func _place_player(player: Node3D, spawn_point: Node3D) -> void:
	add_child(player)
	
	player.global_position = spawn_point.global_position

func quit_game() -> void:
	get_tree().quit()

func _on_host_button_pressed() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_spawn_player)
	_spawn_player()
	
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
	rpc("_respawn_player",id)

@rpc("any_peer","call_local")
func _respawn_player(id):
	if multiplayer.is_server():
		_spawn_player(id)

func _on_line_edit_text_submitted(new_text: String) -> void:
	peer.create_client(new_text,PORT)
	multiplayer.multiplayer_peer = peer
	
	$MainMenu.hide()

func _on_respawn_pressed() -> void:
	$RespawnMenu.hide()
	respawn_player(multiplayer.get_unique_id())
