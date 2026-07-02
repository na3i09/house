extends GridMap
class_name GridMapPlacer
## [GridMap] with support for placing packed scenes into locations on the grid map

## [Dictionary] for scenes to be places onto all cells with matching grid map items
@export var place_dict: Dictionary[int,PackedScene]

## [Dictionary] for scenes to be placed randomly with a percentage chance onto matching grid map items
@export var random_place_dict: Dictionary[int,RandomItemSelection]

## [Dictionary] for scenes to be placed only on specified grid cell locations
@export var location_place_dict: Dictionary[Vector3i,PackedScene]

## Vertical offset for placing scenes onto grid map
@export var vertical_offset: float = 0.0

@export var possible_items: Array[PackedScene]

func _ready() -> void:
	if is_multiplayer_authority():
		for index: int in place_dict:
			var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
			for inst: Vector3i in instance_array:
				_instance_item_on_cell(place_dict[index],inst)
		
		for index: int in random_place_dict:
			var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
			for inst: Vector3i in instance_array:
				var random_scene: PackedScene = random_place_dict[index].pick_item()
				if random_scene:
					_instance_item_on_cell(random_scene,inst)
		
		for location: Vector3i in location_place_dict:
			_instance_item_on_cell(location_place_dict[location],location)
		
		print(_serialize_items())


func _instance_item_on_cell(scene: PackedScene, location: Vector3i) -> void:
	assert(scene.can_instantiate())
	if find_child(str(location) + "*"):
		push_warning("Item overlap")
		return
	var inst_scene := scene.instantiate() as Node3D
	assert(inst_scene, "Scene to be instantiated was not derived from Node3D")
	_place_item_on_map(inst_scene,location)
	inst_scene.name = _name_item(scene,location)
	add_child(inst_scene)


func _serialize_items() -> Dictionary:
	var serialized_dict: Dictionary[Vector3i,Array]
	
	var children: Array[Node] = get_children()
	
	for child: Node in children:
		if child.name.begins_with("("):
			var name_split: PackedStringArray = child.name.split("_")
			var location: Vector3i = _string_to_vector3i(name_split[0])
			
			serialized_dict.get_or_add(location,[]).append(name_split[1].to_int())
	return serialized_dict


func apply_map_configuration_resource(config: GridMapConfiguration, offset: Vector3i = Vector3i(0,0,0)) -> void:
	_apply_map_configuration(config.configuration_dict,offset)


func _apply_map_configuration(config: Dictionary[Vector3i,Array], offset: Vector3i = Vector3i(0,0,0)) -> void:
	for location: Vector3i in config:
		var tile_type: int = config[location][0]
		var tile_orientation: int = config[location][1]
		var items: Array = config[location].slice(2)
		
		var true_location: Vector3i = location + offset
		
		set_cell_item(true_location,tile_type,tile_orientation)
		
		for item: int in items:
			_instance_item_on_cell(possible_items[item],true_location)


func _apply_item_configurations() -> void:
	var children: Array[Node] = get_children()
	
	for child: Node in children:
		_apply_item_configuration(child)


func _apply_item_configuration(node: Node) -> void:
	if node.name.begins_with("("):
		var name_split: PackedStringArray = node.name.split("_")
		var location: Vector3i = _string_to_vector3i(name_split[0])
		_place_item_on_map(node,location)
	else:
		push_error("Spawned node with invalid name for item configuration: " + node.name)


func _string_to_vector3i(string: String) -> Vector3i:
	var location_string: String = string.remove_chars("()")
	var location_elements: PackedStringArray = location_string.split(",")
	var location: Vector3i = Vector3i(location_elements[0].to_int(),location_elements[1].to_int(),location_elements[2].to_int())
	
	return location


func _name_item(item_scene: PackedScene, location: Vector3i) -> String:
	var item_index: int = possible_items.find(item_scene)
	
	return str(location) + "_" + str(item_index)


func _place_item_on_map(item: Node3D, location: Vector3i) -> void:
	var inst_location: Vector3 = map_to_local(location)
	inst_location.y += vertical_offset
	item.position = inst_location


@rpc("any_peer","reliable","call_remote")
func request_map_configuration() -> void:
	_recieve_map_configuration.rpc_id(multiplayer.get_remote_sender_id(),_serialize_items())


@rpc("authority","reliable","call_remote")
func _recieve_map_configuration(configuration: Dictionary[Vector3i,Array]) -> void:
	for location: Vector3i in configuration:
		for item in configuration[location]:
			_instance_item_on_cell(possible_items[item],location)
