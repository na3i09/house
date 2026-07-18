@tool
extends MinosMap
class_name NetworkMinosMap
## [MinosMap] with automatic networking support.


@onready var spawner: MultiplayerSpawner = _initialize_multiplayer_support()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if is_multiplayer_authority():
		if possible_segments and auto_generate:
			_dev_clear_map()
			generate(auto_generation_segments)
		
		var item_dict := generate_item_configuration_dictionary()
		
		for location in item_dict:
			_instance_item_array(location,get_cell_item_orientation(location),item_dict[location])
		
		var random_item_dict := generate_random_item_configuration_dictionary()
		
		for location in random_item_dict:
			_instance_item_array(location,get_cell_item_orientation(location),random_item_dict[location])
		
		if OS.has_feature("editor"):
			print(_serialize_items())
	else:
		_request_map_configuration.rpc_id(1)


func _initialize_multiplayer_support() -> MultiplayerSpawner:
	var _spawner: MultiplayerSpawner = _create_multiplayer_spawner()
	if _spawner:
		_spawner.spawn_function = _spawn_item
		_spawn_function = _spawner.spawn
		_spawner.spawned.connect(_post_spawn_item_processing)
	
	return _spawner


func _create_multiplayer_spawner() -> MultiplayerSpawner:
	var spawner := MultiplayerSpawner.new()
	
	spawner.spawn_path = ^".."
	spawner.name = "PlacerSpawner"
	add_child(spawner)
	
	return spawner


@rpc("any_peer","reliable","call_remote")
func _request_map_configuration() -> void:
	_recieve_map_configuration.rpc_id(multiplayer.get_remote_sender_id(),generate_tile_configuration_dictionary(self))


@rpc("authority","reliable","call_remote")
func _recieve_map_configuration(configuration: Dictionary[Vector3i,Array]) -> void:
	_apply_map_configuration(configuration)
