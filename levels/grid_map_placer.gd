@tool
extends GridMap
class_name GridMapPlacer
## [GridMap] with support for placing packed scenes into locations on the grid map
##
## Replication of grid map item configuration is handled via multiplayer spawner synchronization, 
## while replication of tile configuration is handled via rpc call.

## [Dictionary] for scenes to be places onto all cells with matching grid map items
@export var place_dict: Dictionary[int,String]

## [Dictionary] for scenes to be placed randomly with a percentage chance onto matching grid map items
@export var random_place_dict: Dictionary[int,RandomItemSelection]

## [Dictionary] for scenes to be placed only on specified grid cell locations
@export var location_place_dict: Dictionary[Vector3i,String]

## Vertical offset for placing scenes onto grid map
@export var vertical_offset: float = 0.0

@export var possible_item_resource: ItemTable

var _possible_items: Dictionary[StringName,PackedScene]:
	get:
		if possible_item_resource:
			return possible_item_resource.table
		else:
			return {}
	set(value):
		pass

@export var possible_segments: Array[GridMapConfiguration]

@export_group("Developement Functions","dev")
@export_tool_button("Generate Map") var dev_map_gen: Callable = _generate
@export_tool_button("Save Configuration") var dev_config_save: Callable = _dev_save_config_resource
@export_placeholder("Scene Name") var dev_config_save_name: String


static func generate_static_configuration_dictionary(_placer: GridMapPlacer) -> Dictionary[Vector3i,Array]:
	var serialized_dict: Dictionary[Vector3i,Array] = generate_tile_configuration_dictionary(_placer)
	
	for index: int in _placer.place_dict:
		var instance_array: Array[Vector3i] = _placer.get_used_cells_by_item(index)
		for inst: Vector3i in instance_array:
			serialized_dict[inst].append(_placer.place_dict[index])
	
	for location: Vector3i in _placer.location_place_dict:
		if serialized_dict.has(location):
			serialized_dict[location].append(_placer.location_place_dict[location])
	
	return serialized_dict


static func generate_tile_configuration_dictionary(_map: GridMap) -> Dictionary[Vector3i,Array]:
	var dict: Dictionary[Vector3i,Array]
	
	var tiles_used: Array[Vector3i] = _map.get_used_cells()
	
	for location: Vector3i in tiles_used:
		dict[location] = [_map.get_cell_item(location),_map.get_cell_item_orientation(location)]
	
	return dict


static func generate_map(_placer: GridMap, segments: Array[GridMapConfiguration], _max_instances: int, origin: Vector3i = Vector3i(0,0,0)) -> Dictionary[Vector3i,Array]:
	var generated_map: Dictionary[Vector3i,Array] = {}
	
	var first_segment: GridMapConfiguration = segments.pick_random()
	generated_map.merge(first_segment.configuration_dict)
	
	var segment_edges: Dictionary[Vector3i,int] = first_segment.edge_locations
	
	for edge in segment_edges:
		var new_segment: GridMapConfiguration = segments.pick_random()
		
		var connecting_edge: Vector3i = new_segment.edge_locations.keys().pick_random()
		var edge_basis: Basis = _placer.get_basis_with_orthogonal_index(new_segment.edge_locations[connecting_edge])
		var edge_direction: Vector3i = Vector3i(edge_basis.z)
		for loc in new_segment.configuration_dict:
			var true_loc: Vector3i = loc - connecting_edge + origin# + edge_direction
			if not generated_map.has(true_loc):
				var tile_basis: Basis = _placer.get_basis_with_orthogonal_index(new_segment.configuration_dict[loc][1])
				var new_basis: Basis = edge_basis * tile_basis
				var new_array: Array = new_segment.configuration_dict[loc].duplicate()
				#new_array[1] = _placer.get_orthogonal_index_from_basis(new_basis)
				generated_map[true_loc] = new_array
	
	return generated_map


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if is_multiplayer_authority():
		if possible_segments:
			_generate()
		for index: int in place_dict:
			var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
			for inst: Vector3i in instance_array:
				_instance_item_on_cell(place_dict[index],inst)
		
		for index: int in random_place_dict:
			var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
			for inst: Vector3i in instance_array:
				var random_scene: StringName = random_place_dict[index].pick_item()
				if random_scene:
					_instance_item_on_cell(random_scene,inst)
		
		for location: Vector3i in location_place_dict:
			_instance_item_on_cell(location_place_dict[location],location)
		
		print(_serialize_items())
	else:
		request_map_configuration.rpc_id(1)


func _instance_item_on_cell(item_name: String, location: Vector3i) -> void:
	var scene: PackedScene = _possible_items[item_name]
	assert(scene.can_instantiate())
	if find_child(str(location) + "*"):
		push_warning("Item overlap")
		return
	var inst_scene := scene.instantiate() as Node3D
	assert(inst_scene, "Scene to be instantiated was not derived from Node3D")
	_place_item_on_map(inst_scene,location)
	inst_scene.name = _name_item(item_name,location)
	add_child(inst_scene)


func generate_live_configuration_dictionary() -> Dictionary[Vector3i,Array]:
	var dict := generate_tile_configuration_dictionary(self)
	var item_dict := _serialize_items()
	
	for location: Vector3i in dict:
		if item_dict.has(location):
			dict[location].append_array(item_dict[location])
	
	return dict

func generate_configuration_resource() -> GridMapConfiguration:
	var config_resource: GridMapConfiguration = GridMapConfiguration.new()
	
	config_resource.configuration_dict = GridMapPlacer.generate_static_configuration_dictionary(self)
	
	var edge_id: int = mesh_library.find_item_by_name("Edge")
	if edge_id != -1:
		var edge_locs := get_used_cells_by_item(edge_id)
		for edge in edge_locs:
			config_resource.edge_locations[edge] = get_cell_item_orientation(edge)
			config_resource.configuration_dict.erase(edge)
	
	return config_resource

func _dev_save_config_resource() -> void:
	var save_name: String
	if dev_config_save_name:
		save_name = owner.scene_file_path.get_base_dir().path_join(dev_config_save_name + ".tres")
	else:
		save_name = owner.scene_file_path.replace(".tscn",".tres")
	
	var map_config: GridMapConfiguration = generate_configuration_resource()
	ResourceSaver.save(map_config,save_name)

func _generate() -> void:
	clear()
	_apply_map_configuration(generate_map(self,possible_segments,4))

func _serialize_items() -> Dictionary[Vector3i,Array]:
	var serialized_dict: Dictionary[Vector3i,Array]
	
	var children: Array[Node] = get_children()
	
	for child: Node in children:
		if child.name.begins_with("("):
			var name_split: PackedStringArray = child.name.split("_")
			var location: Vector3i = Helpers.string_to_vector3i(name_split[0])
			
			serialized_dict.get_or_add(location,[]).append("_".join(name_split.slice(1)))
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
			_instance_item_on_cell(_possible_items.keys()[item],true_location) #TODO: ensure this will actually work from serializing key index position


func _apply_item_configuration(node: Node) -> void:
	if node.name.begins_with("("):
		var name_split: PackedStringArray = node.name.split("_")
		var location: Vector3i = Helpers.string_to_vector3i(name_split[0])
		_place_item_on_map(node,location)
	else:
		push_error("Spawned node with invalid name for item configuration: " + node.name)


func _name_item(item_name: String, location: Vector3i) -> String:
	return str(location) + "_" + item_name


func _place_item_on_map(item: Node3D, location: Vector3i) -> void:
	var inst_location: Vector3 = map_to_local(location)
	inst_location.y += vertical_offset
	item.position = inst_location


@rpc("any_peer","reliable","call_remote")
func request_map_configuration() -> void:
	_recieve_map_configuration.rpc_id(multiplayer.get_remote_sender_id(),generate_tile_configuration_dictionary(self))


@rpc("authority","reliable","call_remote")
func _recieve_map_configuration(configuration: Dictionary[Vector3i,Array]) -> void:
	_apply_map_configuration(configuration)
